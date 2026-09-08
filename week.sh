#!/usr/bin/env bash

for dir in */; do
  if git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    log=$(git -C "$dir" --no-pager log --since="10 days ago" --format=format:"%ch %s")
    #log=$(git -C "$dir" --no-pager log --since="1 week ago" --format=format:"%ch %s")
    if [[ -n "$log" ]]; then
      echo "## $dir"
      echo "$log"
      echo
    fi
  fi
done
