# Build the Image

Use the `make_docker_image.sh` utility to build the docker image:

`sudo ./make_docker_image.sh`

This will build `l2j-server-game:latest` with a fresh checkout from the develop branches of the gameserver and datapack. For more options call `./make_docker_image.sh -h`.

# Quickstart

If you are familar with `docker-compose` you can take a quick look into the example `docker-compose.yml`. It provides all the basic configurations required to get started.

# Internal Structure

The container has the following l2j specific directories inside:

- `/opt/l2j/deploy/`: Clean l2j files, extracted from a build of the l2j repositories.
- `/opt/l2j/custom/`: Custom files, overwriting or extending clean l2j files (does not work on Interlude)
    - `/opt/l2j/custom/game/config/*.properties`: Overwrite properties from clean l2j files.
    - `/opt/l2j/custom/game/config/ipconfig.xml`: Overwrite the ipconfig.xml from clean l2j files.

# Database Initialization

> :warning: **The database initialization destroys your database if it already exists!**

If you do not have a gameserver database yet, you need to perform database initialization.

Specify `L2JGAME_DB_INIT=1` to tell the container to perform database initialization. After database initialization, the container automatically stops.

Additionally to `L2JGAME_DB_INIT` the following environment variables are required for the initialization to succeed:

- `L2JGAME_DB_HOST`: db server host
- `L2JGAME_DB_PORT`: db server port
- `L2JGAME_DB_USER`: db user created for the loginserver db
- `L2JGAME_DB_PASS`: password for the db user created for the loginserver db
- `L2JGAME_DB_NAME`: db name for the loginserver db
- `L2JGAME_DB_INSTALL_USER`: db user used to install the loginserver db
- `L2JGAME_DB_INSTALL_PASS`: password of the db user to install the loginserver db

When the database initialization is done, you have to remove the environment variables as the database is destroyed every time the intitialization is performed.

# Environment Variables

- `L2JGAME_JAVA_ARGS`: defaults to `-Xms1g -Xmx2g`
    - Arguments to be added to the invokation of the java virtual machine. Additional to the arguments specified here, only the `-jar` argument is added.
- `L2JGAME_APP_ARGS`: by default empty
    - Arguments passed to the l2j server application.
- `L2JGAME_<propertiesFileName>_<propertyName>`
    - Overwrite a property of a properties file from l2j's config folder. See the next section `Modifying Server Configuration` for more details.

# Modifying Server Configuration

You have two possibilities to overwrite server configuration properties:

1. Environment Variables: Name the environment variables `L2JGAME_<propertiesFileName>_<propertyName>`. Example:
    - `L2JGAME_server_LoginHost`: Overwrites the `LoginHost` property of the `server.properties` file.
1. .properties files (does not work on Interlude):
    1. Map the custom config directory to your host or a named volume.
    1. Create a .properties file with the same name as a clean l2j .properties file in the mapped directory.
    1. Only specify the properties which you want to change.

The later possibility overwrites the previous possibility.

# Important Server Configurations

- `database.properties URL`: jdbc db url `jdbc:mariadb://<dbHost>:<dbPort>/<dbName>`
- `database.properties User`: db user
- `database.properties Password`: password of db user
- `server.properties LoginHost`: loginserver host
- `server.properties LoginPort`: loginserver port

When you are using an image based on an older branch like Interlude, the database properties are as follows:

- `server.properties URL`: jdbc db url `jdbc:mariadb://<dbHost>:<dbPort>/<dbName>`
- `server.properties Login`: db user
- `server.properties Password`: password of db user

For more server configurations, consult L2Js documentation.

# Directories to Map

Some of the data is required to be mapped for the server to function correctly while other data is optional.

- `/opt/l2j/game/custom/game/config/hexid.txt`: required, needs readwrite access, does not work on Interlude
- `/opt/l2j/game/custom/game`: optional, needs read access, does not work on Interlude
- `/opt/l2j/deploy/game/logs`: optional, requires readwrite access

In our example `docker-compose.yml`, we simply map the whole custom game folder `/opt/l2j/game/custom/game` with readwrite access. That gives us quick access to all gameserver related custom data while being able to preserve server generated files like `hexid.txt`. A proper configuration would only map files with readwrite access which are actually written by the gameserver and everything else readonly.

When you are using an image based on an older branch like Interlude, the following directories can be mapped:

- `/opt/l2j/game/deploy/game/config/hexid.txt`: required, needs readwrite access
- `/opt/l2j/game/deploy/game/config`: optional, needs read access
- `/opt/l2j/game/deploy/game/data/crests`: required, needs readwrite access
- `/opt/l2j/game/deploy/game/data`: optional, needs read access
- `/opt/l2j/game/deploy/game/geodata`: optional, needs read access
- `/opt/l2j/game/deploy/game/pathnode`: optional, needs read access
- `/opt/l2j/deploy/game/logs`: optional, requires readwrite access

In our example `docker-compose.yml`, we simply map `/opt/l2j/deploy/game/config` and `/opt/l2j/deploy/game/data` with readwrite access. That gives us quick access to all configurations and data while being able to preserve server generated files like `hexid.txt` and crests. A proper configuration would only map files with readwrite access which are actually written by the gameserver and everything else readonly.
