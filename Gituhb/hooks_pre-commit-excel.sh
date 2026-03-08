#!/usr/bin/env bash
# Place in .git/hooks/pre-commit and make executable: chmod +x
# Enforce EXCEL_CHANGELOG.csv update when Excel files change

STAGED=$(git diff --cached --name-only)

if echo "$STAGED" | grep -E '\.xlsx$' >/dev/null; then
  echo "Detected staged .xlsx files:"
  echo "$STAGED" | grep -E '\.xlsx$'
  
  if ! echo "$STAGED" | grep -q 'configs/EXCEL_CHANGELOG.csv'; then
    echo ""
    echo "ERROR: configs/EXCEL_CHANGELOG.csv must be updated when Excel files change."
    echo "Please update EXCEL_CHANGELOG.csv with the change details and try again."
    exit 1
  fi
fi

exit 0