#!/bin/bash
set -e

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

MIME=$(file -b --mime-type "$DB_PATH")
if [ "$MIME" = "application/vnd.sqlite3" ]; then 
	BIN_PATH=sqlite3
else
	BIN_PATH=sqlcipher
	read -srp "Password: " PASS; echo '';
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
sqlite3 "$TEST_DB_PATH" < "$DUMP_PATH"
echo 'pragma foreign_key_check;' | sqlite3 "$TEST_DB_PATH"
rm -f "$TEST_DB_PATH"
