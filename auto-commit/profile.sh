function git() {
    if [[ "$1" == "add" && "$2" == "." ]]; then
        command git add .
        command git status
    elif [[ "$1" == "cm" ]]; then
        shift
        gcm-chatgpt "$@"
    elif [[ "$1" == "ach" ]]; then
        echo "------- ADD files in . ---------"
        command git add .
        command git status
        echo "-------- COMMIT MESSAGE --------"
              gcm-chatgpt
        echo "--------------------------------"
    elif [[ "$1" == "ac" ]]; then
        echo "------- ADD files in . ---------"
        command git add .
        command git status
        echo "-------- COMMIT MESSAGE --------"
              gcm-claude
        echo "--------------------------------"
    elif [[ "$1" == "pusho" ]]; then
      command git status
      echo "--------------------------------"
      command git push origin HEAD
    elif [[ "$1" == "revert"  ]]; then
  command git reset --soft HEAD~1
    else
        command git "$@"
    fi
}

function gcm() {
  git commit -m "$*"
}

function gcm-chatgpt() {
  diff=$(git diff --cached)

  if [ -z "$diff" ]; then
    echo "❌ No staged changes."
    return 1
  fi

  # Create the JSON body with `jq` to handle escaping
  json_body=$(jq -n \
    --arg diff "$diff" \
    '{
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant that writes concise Git commit messages."
        },
        {
          role: "user",
          content: "Write a Git commit message for the following diff:\n\n\($diff)"
        }
      ],
      temperature: 0.8
    }')

  # Send the request
  response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "$json_body")

  # Optional: Debug raw response
  # echo "$response" | jq

  # Extract commit message
  commit_msg=$(echo "$response" | jq -r '.choices[0].message.content')

  if [ -z "$commit_msg" ] || [ "$commit_msg" == "null" ]; then
    echo "❌ Failed to generate commit message."
    return 1
  fi

  echo "✅ $commit_msg"
  echo "\n"
  git commit -m "$commit_msg"
}

function gcm-claude() {
  
  diff=$(git diff --cached)

  if [ -z "$diff" ]; then
    echo "❌ No staged changes."
    return 1
  fi

  #echo "DEBUG: About to run jq command..."
  #echo "$diff"
  # Test the jq command step by step
  #echo "DEBUG: Testing jq basic functionality..."
  #echo '{"test": "value"}' | jq '.'
  
  #echo "DEBUG: Creating JSON body with jq..."
  # Save diff to a temporary file to avoid all escaping issues
  temp_diff_file=$(mktemp)
  echo "$diff" > "$temp_diff_file"
  
  # Create the JSON body using --rawfile to safely handle any characters
  json_body=$(jq -n \
    --rawfile diff "$temp_diff_file" \
    '{
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: ("Write a concise Git commit message for the following diff. Return only the commit message with some explanation, no quotes:\n\n" + $diff)
        }
      ]
    }')
  
  # Clean up temp file
  rm "$temp_diff_file"
  
  #echo "DEBUG: json_body first 200 chars: ${json_body:0:200}"
  #echo "DEBUG: Send to claude..."
  # Send the request to Claude
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "$json_body")

  #echo "DEBUG: Raw response:"
  #echo "$response"
  #echo "DEBUG: End of raw response"
  
  # Extract commit message from Claude's response with error handling
  commit_msg=$(echo "$response" | jq -r '.content[0].text' 2>&1)
  jq_exit_code=$?
  
  #echo "DEBUG: jq exit code: $jq_exit_code"
  #echo "DEBUG: commit_msg value: '$commit_msg'"
  #echo "DEBUG: commit_msg length: ${#commit_msg}"

  if [[ $jq_exit_code -ne 0 ]]; then
    echo "❌ jq parsing failed: $commit_msg"
    return 1
  fi

  #if [ -z "$commit_msg" ] || [ "$commit_msg" == "null" ]; then
  #  echo "❌ Failed to generate commit message."
  #  echo "Response: $response"
  #  return 1
  #fi

  echo "✅ $commit_msg"
  echo "\n"
  git commit -m "$commit_msg"
}
