FROM jenkins/jenkins:lts-jdk17

USER root

# Docker CLI (to build/run containers through the host's Docker) and Node.js (for unit tests)
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg nodejs npm \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce-cli \
 && rm -rf /var/lib/apt/lists/*

# Runs as root so Jenkins can use the mounted Docker socket (acceptable for a local lab only)
USER root
