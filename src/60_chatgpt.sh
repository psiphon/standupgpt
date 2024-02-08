
get_chatgpt_message() {
  local standupRequestText="$1"
  local gptStyle=${2:-$GPT_STYLE}
  local openAiApiKey=${3:-$OPEN_AI_API_KEY}

  if [ -z "$standupRequestText" ]; then
      echo "No standup request text provided" >&2
      exit 1
  fi

  $VERBOSE && echo "Request text:" >&2
  $VERBOSE && echo $standupRequestText >&2
  $VERBOSE && echo "" >&2

  standupRequestText=`echo $standupRequestText | sed 's/\"/\\\"/g'`
  local jsonData='{
      "model": "gpt-3.5-turbo",
      "messages": [
          {
              "role": "user",
              "content": "Write a standup paragraph in the style of '$gptStyle' that mentions the following: '$standupRequestText'"
          }
      ]
  }'

  echo "Fetching standup from ChatGPT..." >&2
  curl -sf -X POST -H "Authorization: Bearer $OPEN_AI_API_KEY" -H "Content-Type: application/json" \
  -d "$jsonData" https://api.openai.com/v1/chat/completions > .chatgpt
  if [ $? -ne 0 ]; then
      echo "Failed to fetch data from ChatGPT" >&2
      rm -f .chatgpt
      exit 1
  fi
  
  local gptContent=`cat .chatgpt | jq -r '.choices[].message.content'`
  if [ $? -ne 0 ]; then
      echo "Failed to parse ChatGPT response" >&2
      rm -f .chatgpt
      exit 1
  fi

  rm -f .chatgpt

  if [ -z "$gptContent" ]; then
      echo "ChatGPT response is empty" >&2
      exit 1
  fi

  echo "$gptContent"
}

