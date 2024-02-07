
get_linear_userid() {
  local linearUserEmail=$1
  local linearToken=${2:-$LINEAR_TOKEN}

  echo "Fetching user id from Linear..." >&2
  curl -sf -H "Authorization: $linearToken" \
    -H "Content-Type: application/json" \
    -d '{ "query": "query UserQuery($filter: UserFilter) {  users(filter: $filter) { nodes { id }  }  }",
          "variables": {   "filter": {
            "email": {
              "eq": "'$linearUserEmail'"
            }
           }
          }
        }' \
    https://api.linear.app/graphql > .linear
  if [ $? -ne 0 ]; then
    echo "Failed to fetch data from Linear" >&2
    exit 1
  fi

  local linearResponse=$(cat .linear)
  rm -f .linear
  if [ -z "$linearResponse" ]; then
    echo "Linear response was empty." >&2
    exit 1
  fi

  local userId=$(echo $linearResponse | jq -r '.data.users.nodes.[0].id')
  if [ -z "$userId" ]; then
    echo "Linear user id is empty." >&2
    exit 1
  fi
  
  $VERBOSE && echo "  User id: $userId" >&2
  echo $userId
}

get_linear_info() {
    local standupText=""
    local userId=$LINEAR_USER_ID

    if [ -z "$userId" ]; then
        userId=`get_linear_userid "$LINEAR_USER_EMAIL"`
        if [ $? -ne 0 ]; then
            echo "Failed to fetch user id with user name from Linear" >&2
            exit 1
        fi

        if [ -z "$userId" ]; then
            echo "Linear user Id is empty" >&2
            exit 1
        fi
    fi
    
    echo "Fetching data from Linear..." >&2
    local linearData=$(curl -sf -H "Authorization: $LINEAR_TOKEN" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{
            "query": "query ActivityQuery($userId: String!, $filter: IssueFilter, $assignedIssuesFilter2: IssueFilter, $commentsFilter2: CommentFilter) { user(id: $userId) { createdIssues(filter: $filter) { nodes { identifier title state { name type } updatedAt triagedAt startedTriageAt startedAt createdAt completedAt canceledAt } } assignedIssues(filter: $assignedIssuesFilter2) { nodes { identifier title state { name type } updatedAt triagedAt startedTriageAt startedAt createdAt completedAt canceledAt } } } comments(filter: $commentsFilter2) { nodes { updatedAt issue { title identifier } createdAt editedAt resolvedAt } } }",
            "variables":{
                "userId": "'$userId'",
                "filter": {
                    "createdAt": {
                        "gt": "'$YESTERDAY_DATE'"
                    }
                },
                "assignedIssuesFilter2": {
                    "updatedAt": {
                        "gt": "'$YESTERDAY_DATE'"
                    }
                },
                "commentsFilter2": {
                    "and": [
                        {
                            "createdAt": {
                                "gt": "'$YESTERDAY_DATE'"
                            },
                            "user": {
                                "id": {
                                    "eq": "'$userId'"
                                }
                            }
                        }
                    ]
                }
            }    
        }' \
        https://api.linear.app/graphql
    )
    if [ $? -ne 0 ]; then
        echo "Failed to fetch data from Linear" >&2
        exit 1
    fi

    local commentCount=$(echo $linearData | jq '.data.comments.nodes | length')
    local issueCount=$(echo $linearData | jq '.data.user.createdIssues.nodes | length')
    local assignedIssueCount=$(echo $linearData | jq '.data.user.assignedIssues.nodes | length')

    local commentIssues=$(echo $linearData | jq -c '.data.comments.nodes.[].issue.identifier')
    local issueIdentifiers=$(echo $linearData | jq -c '.data.user.createdIssues.nodes.[].identifier')
    local assignedIssueIdentifiers=$(echo $linearData | jq -c '.data.user.assignedIssues.nodes.[].identifier')

    local commentIssues=$(echo $commentIssues | sed 's/\"//g' |tr -d '\n')
    local issueIdentifiers=$(echo $issueIdentifiers | sed 's/\"//g' |tr -d '\n')
    local assignedIssueIdentifiers=$(echo $assignedIssueIdentifiers | sed 's/\"//g' |tr -d '\n')

    $VERBOSE && echo "  Comment count: $commentCount" >&2
    $VERBOSE && echo "  Issue count: $issueCount" >&2
    $VERBOSE && echo "  Assigned issue count: $assignedIssueCount" >&2
    $VERBOSE && echo "" >&2

    if [ "$commentCount" -gt 0 ]; then
        standupText+=$(echo -n "I commented on $commentIssues. ")
    fi

    if [ "$issueCount" -gt 0 ]; then
        standupText+=$(echo -n "I created $issueIdentifiers. ")
    fi

    if [ "$assignedIssueCount" -gt 0 ]; then
        standupText+=$(echo -n "I was assigned $assignedIssueIdentifiers. ")
    fi

    if [ "$commentCount" -eq 0 ] && [ $issueCount -eq 0 ] && [ $assignedIssueCount -eq 0 ]; then
        standupText+=$(echo -n "I did not comment, create, or get assigned any issues today. ")
    fi

    echo $standupText
}
