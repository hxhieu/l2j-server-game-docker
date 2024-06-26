#!/bin/sh

PARSE_OPTS_CURRENT_NAME=""

for arg in "$@"; do
  case "$arg" in
    -*)
      PARSE_OPTS_CURRENT_NAME="$arg"
      eval "OPT_${arg#-}"='1'
      ;;
    *)
      if [ -z "$PARSE_OPTS_CURRENT_NAME" ]; then
        echo "warning, argument without option"
      else
        eval "OPT_${PARSE_OPTS_CURRENT_NAME#-}"='$arg'
        PARSE_OPTS_CURRENT_NAME=""
      fi
      ;;
  esac
done

PARSE_OPTS_CURRENT_NAME=""