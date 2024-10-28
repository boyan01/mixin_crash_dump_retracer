#!/bin/bash

MINIDUMP_PATH=$1
SYMBOL_PATH=$2

if [ -z "$MINIDUMP_PATH" ]; then
  echo "Error: MINIDUMP_PATH is not set"
  exit 1
fi

if [ -z "$SYMBOL_PATH" ]; then
  echo "Error: SYMBOL_PATH is not set"
  exit 1
fi

prepare_symbol_files() {
  dir_path="$1"
  symbols_dir=$(mktemp -d symbols.XXXXXX)

  for file in "$dir_path"/*.sym; do
    if [[ -f "$file" ]]; then
      read -r first_line < "$file"
      first_line=$(echo -e "$first_line" | tr -d '\r')
      if [[ -z "$first_line" ]]; then
        continue
      fi
      IFS=' ' read -r _ _ _ uuid pdb_file_name <<< "$first_line"
      target_dir="$symbols_dir/$pdb_file_name/$uuid"
      mkdir -p "$target_dir"
      cp "$file" "$target_dir/$(basename "$file")"
    fi
  done
  echo "$symbols_dir"
}

# if symbol is zip, unzip it
if [[ $SYMBOL_PATH == *.zip ]]; then
  unzip -o $SYMBOL_PATH -d /tmp/symbols > /dev/null
  SYMBOL_PATH=$(prepare_symbol_files /tmp/symbols)
fi

echo "./breakpad/mac_arm64/minidump_stackwalk $MINIDUMP_PATH $SYMBOL_PATH"
./breakpad/mac_arm64/minidump_stackwalk $MINIDUMP_PATH $SYMBOL_PATH
