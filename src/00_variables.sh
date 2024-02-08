SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
HOURS=24
GPT_STYLE="a humble and wise coder that wants to just tell colleagues about his day"
VERBOSE=false

usage() {
    echo "Usage: $0 [-d hours] [-s style] [-o openai key] [-g github token] [-u github username] [-l linear token] [-i linear user id]" 1>&2
    echo
    echo "Options:"
    echo "  -d hours: number of hours to fetch data for (default: 24)"
    echo "  -s style: GPT-3 style (default: $GPT_STYLE)"
    echo "  -o openai key: OpenAI API"
    echo "  -g github token: GitHub API token"
    echo "  -u github username: GitHub username"
    echo "  -l linear token: Linear"
    echo "  -i linear user id: Linear user ID"
    echo "  -e linear user email: Linear user email"
    echo "  -v: verbose"
    echo 
    echo "The preferred way to set environment variables is to create a .env file in the root of the project"
    echo "with the following variables:"
    echo "  GITHUB_TOKEN=your_github_token"
    echo "  GITHUB_USERNAME=your_github_username"
    echo "  LINEAR_TOKEN=your_linear_token"
    echo "  LINEAR_USER_ID=your_linear_user_id   [optonal]" 
    echo "  LINEAR_USER_EMAIL=your_linear_user_email [optional]"
    echo "  OPEN_AI_API_KEY=your_openai_api_key"
    echo "  GPT_STYLE=your_gpt_style"
    echo 
    echo "If you provide your Linear email then you don't need "
    echo "to provide LINEAR_USER_ID or vice versa."
    echo "Then you can run the script without any arguments."
    exit 1
}

# if .env file exists, source it
if [ -f ".env" ]; then
    source ".env"
fi

# getopts for hours, style, openai key, github token, github username, linear token, linear user id
while getopts "vhd:s:o:g:e:u:l:i:" opt; do
    case $opt in
        d) HOURS="$OPTARG"
        ;;
        s) GPT_STYLE="$OPTARG"
        ;;
        o) OPEN_AI_API_KEY="$OPTARG"
        ;;
        g) GITHUB_TOKEN="$OPTARG"
        ;;
        u) GITHUB_USERNAME="$OPTARG"
        ;;
        l) LINEAR_TOKEN="$OPTARG"
        ;;
        i) LINEAR_USER_ID="$OPTARG"
        ;;
        e) LINEAR_USER_EMAIL="$OPTARG"
        ;;
        v) VERBOSE=true
        ;;
        h) usage
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
done

# if LINEAR_TOKEN, GITHUB_USERNAME, GITHUB_TOKEN, LINEAR_USER_ID, OPEN_AI_API_KEY are empty, exit
if [ -z "$LINEAR_TOKEN" ] || [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$OPEN_AI_API_KEY" ]; then
    echo "Missing required environment variables" >&2
    usage
    exit 1
fi

if [ -z "$LINEAR_USER_ID" ] && [ -z "$LINEAR_USER_EMAIL" ]; then
    echo "Missing required environment variables" >&2
    usage
    exit 1
fi

CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ $(uname) = "Darwin" ]; then
    YESTERDAY_DATE=$(date -j -v-${HOURS}H  +"%Y-%m-%dT%H:%M:%SZ")
else
    YESTERDAY_DATE=$(date -u -d "${HOURS} hours ago" +"%Y-%m-%dT%H:%M:%SZ")
fi

CURRENT_DAY=$(date -u +"%Y-%m-%d")
if [ $(uname) = "Darwin" ]; then
    YESTERDAY_DAY=$(date -j -v-${HOURS}H  +"%Y-%m-%d")
else
    YESTERDAY_DAY=$(date -u -d "${HOURS} hours ago" +"%Y-%m-%d")
fi

print_configuration() {
  echo "Configuration:"
  printf "  %-20s %-40s\n" "HOURS:" "$HOURS"
  printf "  %-20s %-40s\n" "GPT_STYLE:" "$GPT_STYLE"
  printf "  %-20s %-40s\n" "OPEN_AI_API_KEY:" "$OPEN_AI_API_KEY"
  printf "  %-20s %-40s\n" "GITHUB_TOKEN:" "$GITHUB_TOKEN"
  printf "  %-20s %-40s\n" "GITHUB_USERNAME:" "$GITHUB_USERNAME"
  printf "  %-20s %-40s\n" "LINEAR_TOKEN:" "$LINEAR_TOKEN"
  printf "  %-20s %-40s\n" "LINEAR_USER_ID:" "$LINEAR_USER_ID"
  printf "  %-20s %-40s\n" "LINEAR_USER_EMAIL:" "$LINEAR_USER_EMAIL"
  printf "  %-20s %-40s\n" "VERBOSE:" "$VERBOSE"
  printf "  %-20s %-40s\n" "CURRENT_DATE:" "$CURRENT_DATE"
  printf "  %-20s %-40s\n" "YESTERDAY_DATE:" "$YESTERDAY_DATE"
  printf "  %-20s %-40s\n" "CURRENT_DAY:" "$CURRENT_DAY"
  printf "  %-20s %-40s\n" "YESTERDAY_DAY:" "$YESTERDAY_DAY"
  echo ""
}
$VERBOSE && print_configuration