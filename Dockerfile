FROM alpine:3.19 as base-image

ENV L2JCLI_URI=https://git@bitbucket.org/l2jserver/l2j-server-cli.git
ENV L2JGAME_URI=https://git@bitbucket.org/l2jserver/l2j-server-game.git
ENV L2JDP_URI=https://git@bitbucket.org/l2jserver/l2j-server-datapack.git

ENV L2J_DIR=/opt/l2j
ENV L2J_SOURCE_DIR="$L2J_DIR/source"

ENV L2JCLI_DIR=cli
ENV L2JGAME_DIR=game
ENV L2JDP_DIR=datapack


FROM base-image AS build

ARG L2JCLI_BRANCH=master
ARG L2JGAME_BRANCH=develop
ARG L2JDP_BRANCH=develop

RUN \
  apk update && apk --no-cache add git openjdk21-jdk && \
  mkdir -p "$L2J_SOURCE_DIR" && \
  git clone --branch "$L2JCLI_BRANCH" --single-branch "$L2JCLI_URI" "$L2J_SOURCE_DIR/$L2JCLI_DIR" && \
  git clone --branch "$L2JGAME_BRANCH" --single-branch "$L2JGAME_URI" "$L2J_SOURCE_DIR/$L2JGAME_DIR" && \
  git clone --branch "$L2JDP_BRANCH" --single-branch "$L2JDP_URI" "$L2J_SOURCE_DIR/$L2JDP_DIR" && \
  cd "$L2J_SOURCE_DIR/$L2JCLI_DIR" && chmod +x mvnw && ./mvnw package -DskipTests && \
  cd "$L2J_SOURCE_DIR/$L2JGAME_DIR" && chmod +x mvnw && ./mvnw install -DskipTests && \
  cd "$L2J_SOURCE_DIR/$L2JDP_DIR" && chmod +x mvnw && ./mvnw package -DskipTests


FROM base-image AS deploy
LABEL maintainer="l2j-server" website="l2jserver.com"

ENV L2J_DEPLOY_DIR="$L2J_DIR/deploy"
ENV L2J_CUSTOM_DIR="$L2J_DIR/custom"
ENV L2J_HOME="$L2J_DIR"

WORKDIR "$L2J_DEPLOY_DIR"

COPY --from=build "$L2J_SOURCE_DIR/$L2JCLI_DIR/target/*.zip" "$L2J_SOURCE_DIR/$L2JGAME_DIR/target/*.zip" "$L2J_SOURCE_DIR/$L2JDP_DIR/target/*.zip" "$L2J_DEPLOY_DIR/"
RUN \
  apk update && apk --no-cache add unzip openjdk21-jre mariadb-client && \
  mkdir -p "$L2J_CUSTOM_DIR/game/config" "$L2J_DEPLOY_DIR/$L2JCLI_DIR/logs" "$L2J_DEPLOY_DIR/$L2JGAME_DIR/logs" && \
  unzip "$L2J_DEPLOY_DIR/*cli*.zip" -d "$L2J_DEPLOY_DIR/$L2JCLI_DIR" && \
  unzip "$L2J_DEPLOY_DIR/*game*.zip" -d "$L2J_DEPLOY_DIR/$L2JGAME_DIR" && \
  unzip "$L2J_DEPLOY_DIR/*datapack*.zip" -d "$L2J_DEPLOY_DIR/$L2JGAME_DIR" && \
  cd "$L2J_DEPLOY_DIR" && rm *.zip && apk del unzip
COPY resources/ /
RUN chmod +x "/entrypoint.sh" "/init_database.sh"

ENTRYPOINT ["/entrypoint.sh"]
