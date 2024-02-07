
get_standup_message() {
    local githubStandup=`get_github_info`
    local linearStandup=`get_linear_info`
    local standupRequestText=$(printf "Over the last 24 hours,\n%s\n%s" "$githubStandup" "$linearStandup")

    standupMessage=`get_chatgpt_message "$standupRequestText"`
    if [ $? -ne 0 ]; then
        echo "Failed to generate standup message" >&2
        exit 1
    fi

    echo $standupMessage

}; get_standup_message

