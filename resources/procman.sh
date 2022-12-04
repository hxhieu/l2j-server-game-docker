#!/bin/sh
PROCMAN_CHILDREN=

procman_launch() {
  echo "procman.sh: Launching '$1'..."

  $1 &
  PROCMAN_LAUNCHED_CHILD=$!
  if [ -z $PROCMAN_CHILDREN ]; then
    PROCMAN_CHILDREN="$PROCMAN_LAUNCHED_CHILD"
  else
    PROCMAN_CHILDREN="$PROCMAN_CHILDREN:$PROCMAN_LAUNCHED_CHILD"
  fi
  return $PROCMAN_LAUNCHED_CHILD
}

procman_signal_int() {
  echo "procman.sh: Handling SIGINT..."

  for i in $(echo "$PROCMAN_CHILDREN" | sed "s/:/ /g"); do
    kill -INT "$i"
  done
}

procman_signal_term() {
  echo "procman.sh: Handling SIGTERM..."

  for i in $(echo "$PROCMAN_CHILDREN" | sed "s/:/ /g"); do
    kill -TERM "$i"
  done
}

procman_signal_kill() {
  echo "procman.sh: Handling SIGKILL..."

  for i in $(echo "$PROCMAN_CHILDREN" | sed "s/:/ /g"); do
    kill -KILL "$i"
  done
}

procman_show_children() {
  for i in $(echo "$PROCMAN_CHILDREN" | sed "s/:/ /g"); do
    echo "$i"
  done
}

procman_wait() {
  echo "procman.sh: Waiting for children to terminate..."

  for i in $(echo "$PROCMAN_CHILDREN" | sed "s/:/ /g"); do
    wait "$i"
  done

  echo "procman.sh: Finished waiting for children."
}

trap procman_signal_int INT
trap procman_signal_term TERM
