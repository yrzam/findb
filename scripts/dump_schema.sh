#!/bin/bash

DB_PATH=$(realpath "$1")
DUMP_PATH=$(realpath "$2")
SQL=$( cat <<SQL
select
	m.sql||';
	'
from
	sqlite_master m
	left join sqlite_master ptbl on ptbl.name=m.tbl_name
where
	m.sql is not null
order by
	m.type='table' desc,
	m.type='index' desc,
	m.type='trigger' and ptbl.type is not 'view' desc,
	m.type='view' desc,
	m.type='trigger' desc,
	m.name;
SQL
)

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
rm -f "$TEST_DB_PATH"
cat "$DUMP_PATH" | sqlite3 "$TEST_DB_PATH"
echo 'pragma foreign_key_check;' | sqlite3 "$TEST_DB_PATH"
rm -f "$TEST_DB_PATH"
