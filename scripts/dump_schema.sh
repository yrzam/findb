#!/bin/bash

DB_PATH=$(realpath "$1")
DUMP_PATH=$(realpath "$2")
SQL="select sql||';' from sqlite_master where sql is not null order by type='table' desc, type='index' desc, type='view' desc, type='trigger' desc, name;"

read -s -p "Password (if any): " PASS; echo '';
if [ -z "$PASS" ]; then 
	BIN_PATH=sqlite3
else
	BIN_PATH=sqlcipher
fi

# dump
$BIN_PATH "$DB_PATH" <<EOF
pragma key='$PASS';
.output '$DUMP_PATH'
$SQL
.output 'stdout'
EOF

# test
TEST_DB_PATH="$DUMP_PATH.test.db"
cat "$DUMP_PATH" | sqlite3 "$TEST_DB_PATH"
echo 'pragma foreign_key_check;' | sqlite3 "$TEST_DB_PATH"
rm "$TEST_DB_PATH"
