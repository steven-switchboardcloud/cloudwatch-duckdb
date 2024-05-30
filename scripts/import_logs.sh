#!/usr/bin/env bash

cd $(dirname $0)/..
mkdir -p "data"

logs_dir="formatted_logs"

for file_path in "$logs_dir"/*; do
    if [ -f "$file_path" ]; then
        file_name=$(basename "$file_path" .log)
        echo "Moving $file_name to DuckDB"
	sql_query="DROP TABLE IF EXISTS ${file_name}; CREATE TABLE ${file_name} AS SELECT * FROM read_json('/home/ec2-user/cloudwatch-duckdb/${file_path}');"
	curl -X POST \
	    -H "Content-Type: application/json" \
        # insert metabase api key here
	    -H "x-api-key: "METABASE_API_KEY" \
	    -d "{\"database\": 3, \"native\": {\"query\": \"$sql_query\"}, \"type\": \"native\"}" \
	    https://metrics.switchboardcloud.com/api/dataset
			
    fi
done
