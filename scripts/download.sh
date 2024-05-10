#!/usr/bin/env bash

cd $(dirname $0)/..
dir="formatted_logs"
mkdir -p "$dir"

to_include_log_groups=$(aws logs describe-log-groups --query "logGroups[?starts_with(logGroupName, '/aws/codebuild') == \`false\`].logGroupName" --output text)

function download_logs() {
  printf "Starting from %s\n" "$(date +%c)"
  for group in ${to_include_log_groups[@]}
  do
    printf "Downloading %s\n" "$group"
    group_name_log_file_name=$(echo "$group" | tr -cd "[:alnum:]")

    aws logs filter-log-events --start-time "$1" --end-time "$2" --log-group-name "$group" --query 'events[?contains(message, `{`) && contains(message, `}`)].message' --output json \
      | jq -r '.[]' \
      >> "$dir/$group_name_log_file_name.log"
  done
}

start_time=$(jq -r '.start_time' config.json)
end_time=$(date +%s)000
download_logs "$start_time" "$end_time"
jq --arg new_start_time "$end_time" '.start_time = $new_start_time' config.json \
  > tmp.json && mv tmp.json config.json


