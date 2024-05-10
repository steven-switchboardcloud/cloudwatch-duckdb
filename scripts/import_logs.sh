#!/usr/bin/env bash

cd $(dirname $0)/..
mkdir -p "data"

logs_dir="formatted_logs"

for file_path in "$logs_dir"/*; do
    if [ -f "$file_path" ]; then
        file_name=$(basename "$file_path" .log)
        echo "Moving $file_name to DuckDB"
        duckdb data/database.db -c "DROP TABLE IF EXISTS ${file_name}; CREATE TABLE ${file_name} AS SELECT * FROM read_json('${file_path}')"
    fi
done

