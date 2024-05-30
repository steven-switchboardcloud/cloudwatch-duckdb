#!/usr/bin/env bash

cd $(dirname $0)/..
dir="formatted_logs"
mkdir -p "$dir"

to_include_log_groups=$(aws logs describe-log-groups --query "logGroups[?starts_with(logGroupName, ('/aws/codebuild' && '/aws/eks/sbc-app/cluster')) == \`false\`].logGroupName" --output text)

function download_logs() {
  printf "Starting from %s\n" "$(date -d @$(($1 / 1000)))"
  for group in ${to_include_log_groups[@]}
  do
    printf "Downloading %s\n" "$group"
    group_name_log_file_name=$(echo "$group" | tr -cd "[:alnum:]")

    aws logs filter-log-events --start-time "$1" --end-time "$2" --log-group-name "$group" --query 'events[?contains(message, `{`) && contains(message, `}`)].message' --output json \
      | jq -r '.[]' \
      | tac \
      > "$dir/temp.log"

    if [ -f "$dir/$group_name_log_file_name.log" ]; then
      cat "$dir/$group_name_log_file_name.log" >> "$dir/temp.log"
    fi

    mv "$dir/temp.log" "$dir/$group_name_log_file_name.log"
  done
}

function cleanup_logs() {
  current_time=$1
  seven_days_ago=$(($current_time - 7*24*60*60*1000))
  for log_file in "$dir"/*.log; do
    temp_file=$(mktemp)
    initial_count=$(wc -l < "$log_file")
    printf "Initial line count in %s: %d\n" "$log_file" "$initial_count"
    while read -r line; do
      log_time=$(echo "$line" | jq -r '.time')
      if [[ -n "$log_time" && "$log_time" -ge $seven_days_ago ]]; then
        echo "$line" >> "$temp_file"
      fi
    done < "$log_file"
    mv "$temp_file" "$log_file"

    final_count=$(wc -l < "$log_file")
    printf "Final line count in %s: %d\n" "$log_file" "$final_count"
  done
}

start_time=$(jq -r '.start_time' config.json)
end_time=$(date +%s)000
download_logs "$start_time" "$end_time"
jq --arg new_start_time "$end_time" '.start_time = $new_start_time' config.json \
  > tmp.json && mv tmp.json config.json
cleanup_logs "$start_time"
