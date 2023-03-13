#!/usr/bin/env bash

set -eu

image="ms-teams"
tag="latest"

dockerfile=$(mktemp)
trap "rm $dockerfile" EXIT
cat << EOF > $dockerfile
FROM ubuntu:bionic
ENV UBUNUTU_RELEASE=18.04
RUN apt-get update && apt-get install -y wget gnupg2
# https://clients.amazonworkspaces.com/linux-install.html
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/teams.gpg
# RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/ms-teams/dist stable main" > /etc/apt/sources.list.d/teams.list
RUN echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/\${UBUNUTU_RELEASE}/prod bionic  main" > /etc/apt/sources.list.d/teams.list

RUN apt-get update
RUN ACCEPT_EULA=Y apt install -y teams || { wget "https://web.archive.org/web/20221130115842/https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.5.00.23861_amd64.deb" && apt install -y ./teams_1.5.00.23861_amd64.deb;}
CMD teams
EOF

if [[ "$(docker images -q '${image}:${tag}' 2> /dev/null)" == "" ]]; then
  echo "building image ${image}:${tag}"
  docker build -t "${image}:${tag}" - < $dockerfile
else
  echo "image ${image}:${tag} already exists"
fi

xhost +
docker run -it --rm --name ms-teams \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$HOME/.aws-workspaces":"/root/.local/share/Amazon Web Services" \
  -e DISPLAY=$DISPLAY \
  -e NO_AT_BRIDGE=1 \
  ${image}:${tag}
