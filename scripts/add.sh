#!/bin/bash

DB_PATH=$(realpath "$1")

print_help() {
	echo -e "add.sh - convenience script to quickly add some things without details. Usage:\n"
	echo -e "tx\t<amt> <asset type name> <asset code> <storage name> <category name> [<datetime>]"
	echo -e "bal\t<amt> <asset type name> <asset code> <storage name>"
	echo -e "rate\t<amt> <asset type name> <asset code>\n"
}

num_arg() {
	ARG="${1//[^A-Za-z0-9-\.]/}"
	if [ -z "$ARG" ]; then
		echo NULL
	else
		echo "$ARG"
	fi
}
text_arg() {
	ARG="${1//\'/\'\'}"
	if [ -z "$ARG" ]; then
		echo NULL
	else
		echo "'$ARG'"
	fi
}
make_query() {
	TARGET="$1"
	shift 1

	case "$TARGET" in
		"tx")
			echo "insert into latest_fin_transactions(amount,asset_type,asset_code,storage,category,datetime) values($(num_arg "$1"),$(text_arg "$2"),$(text_arg "$3"),$(text_arg "$4"),$(text_arg "$5"),$(text_arg "$6"));";;
		"bal")
			echo "insert into current_balances(balance,asset_type,asset_code,storage) values($(num_arg "$1"),$(text_arg "$2"),$(text_arg "$3"),$(text_arg "$4"));";;
		"rate")
			echo "insert into current_fin_asset_rates(rate,asset_type,asset) values($(num_arg "$1"),$(text_arg "$2"),$(text_arg "$3"))";;
	esac
}

print_help
MIME=$(file -b --mime-type "$DB_PATH")
if [ "$MIME" = "application/vnd.sqlite3" ]; then 
	BIN_PATH=sqlite3
else
	BIN_PATH=sqlcipher
	read -srp "Password: " PASS; echo '';
fi

while read -rp '> ' ARGS_STR; do
	eval "ARGS=($ARGS_STR)"
	SQL=$(make_query "${ARGS[@]}")
	if [ -z "$SQL" ]; then
		echo -e "Error: unknown command\n" 
		print_help
		continue
	fi
	$BIN_PATH "$DB_PATH" <<EOF
.output '/dev/null'
pragma key='$PASS';
pragma foreign_keys=ON;
.output 'stdout'
$SQL
EOF
done
