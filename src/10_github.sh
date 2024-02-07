
get_github_info() {
    local sinceTime=${1:-$YESTERDAY_DAY}
    local githubUsername="${GITHUB_USERNAME}"
    local githubToken="${GITHUB_TOKEN}"
    local githubCommitMessage="\"I commited to \(.repository.full_name) with message: \(.commit.message). \""

    local githubUrl="https://api.github.com/search/commits?q=author:${GITHUB_USERNAME}+committer-date:$YESTERDAY_DAY..$CURRENT_DAY"
    
    echo "Fetching commits from GitHub..." >&2
    curl -sf -H "Authorization: token $GITHUB_TOKEN" "$githubUrl" > .commits
    if [ $? -ne 0 ]; then
        local statusCode=$(curl -s -I -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" "$githubUrl" -o .commits)
        echo -n "  Failed to fetch commits from GitHub. " >&2
        echo "Status code: $statusCode" >&2
        rm -f .commits
        exit 1
    fi

    local commitCount=`cat .commits | jq -r '.total_count'`
    if [ -z "$commitCount" ]; then
        echo "Commit count empty." >&2
        rm -f .commits
        exit 1
    fi

    if [ "$commitCount" -eq 0 ]; then
        echo "No commits in the last 24 hours" >&2
        rm -f .commits
        exit 0
    fi

    $VERBOSE && echo "  Found $commitCount commits" >&2
    $VERBOSE && echo ""

    cat .commits | jq -r ".items | .[] | $githubCommitMessage"
    rm -f .commits
}