# Use latest stable channel SDK.
FROM dart:3.6.0 AS build

# Create working directory
WORKDIR /tmp

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .

# Resolve app dependencies.
RUN dart pub get

# Load env variables
ARG PATH_TIBIA_DATA
ARG PATH_TIBIA_DATA_SELFHOSTED
ARG DATABASE_KEY

# compile API
RUN dart compile exe --define=PATH_TIBIA_DATA=${PATH_TIBIA_DATA} --define=PATH_TIBIA_DATA_SELFHOSTED=${PATH_TIBIA_DATA_SELFHOSTED} --define=DATABASE_KEY=${DATABASE_KEY} bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /tmp/bin/server /tmp/bin/

# Start API.
EXPOSE 8080
CMD ["/tmp/bin/server"]
