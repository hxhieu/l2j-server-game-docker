#!/bin/sh

L2JGAME_DB_INIT=${L2JGAME_DB_INIT:-0}
L2JGAME_DB_HOST=${L2JGAME_DB_HOST:-localhost}
L2JGAME_DB_PORT=${L2JGAME_DB_PORT:-3306}
L2JGAME_DB_NAME=${L2JGAME_DB_NAME:-l2jls}
L2JGAME_DB_USER=${L2JGAME_DB_USER:-l2jls}
L2JGAME_DB_PASS=${L2JGAME_DB_PASS:-l2jls}
L2JGAME_DB_INSTALL_USER=${L2JGAME_DB_INSTALL_USER:-root}
L2JGAME_DB_INSTALL_PASS=${L2JGAME_DB_INSTALL_PASS:-root}

sleep 5

. /procman.sh

if [ $L2JGAME_DB_INIT -eq 1 ]; then
  echo "Initializing database..."
  /init_database.sh "$L2JGAME_DB_HOST" "$L2JGAME_DB_PORT" "$L2JGAME_DB_NAME" "$L2JGAME_DB_USER" "$L2JGAME_DB_PASS" "$L2JGAME_DB_INSTALL_USER" "$L2JGAME_DB_INSTALL_PASS" "$L2JGAME_DIR" "GAME"
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to initialize database '$L2JGAME_DB_NAME'! Quitting..."
    return 1
  fi
else
  # Modify default configuration by environment variables
  echo "Processing environment variable configs..."
  env -0 | while IFS='=' read -r -d '' key value; do
    #echo "$key"
    if [[ $key == L2J* ]]; then
      # Get first part of key
      serverComponent="$(echo $key | cut -d'_' -f1)"
      # Get second part of key
      propertiesFile="$(echo $key | cut -d'_' -f2)"
      # Get third part of key
      property="$(echo $key | cut -d'_' -f3)"

      # extract actual server component (L2JGAME becomes game)
      serverComponent="$(echo $serverComponent | cut -c4-)"
      serverComponent="$(echo $serverComponent | tr '[A-Z]' '[a-z]')"

      propertiesDir="$L2J_DEPLOY_DIR/$serverComponent/config"
      propertiesFile="$propertiesFile.properties"

      if [ -f "$propertiesDir/$propertiesFile" ]; then
        #echo "-> $serverComponent $propertiesFile: $property = $value"
        sed -i -e "s&^$property.*&$property=$value&" "$propertiesDir/$propertiesFile"
      fi
    fi
  done

  # todo - database upgrade - L2JGAME_DB_AUTO_UPDATE

  # launch Gameserver
  L2JGAME_JAVA_ARGS=${L2JGAME_JAVA_ARGS:-"-Xms1g -Xmx2g"}
  L2JGAME_APP_ARGS=${L2JGAME_APP_ARGS:-""}

  LOGDIR=logs

  echo "Changing directory to: '$L2J_DEPLOY_DIR/$L2JGAME_DIR/'"
  cd "$L2J_DEPLOY_DIR/$L2JGAME_DIR/"

  err=2
  while [ $err -eq 2 ]; do

    # Delete old *.lck files and archive old logs
    [ -f "$LOGDIR/*.lck" ] && rm "$LOGDIR/*.lck"
    for LOGFILE in "$LOGDIR/*"; do
      [ "$LOGFILE" == "$LOGDIR/*" ] && continue
      LOGFILE_NAME="${LOGFILE#*/}"
      [[ "$LOGFILE_NAME" == [0-9]* ]] && continue
      mv "$LOGFILE" "$LOGDIR/`date +%Y-%m-%d_%H-%M-%S`_$LOGFILE_NAME"
    done

    procman_launch "java $L2JGAME_JAVA_ARGS -jar l2jserver.jar $L2JGAME_APP_ARGS"
    server_pid=$?
    echo "Gameserver started with PID $server_pid."
    wait "$server_pid"
    err=$?
    echo "Gameserver terminated with exit code $err."
  done

fi
