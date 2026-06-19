FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    git \
    curl \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages ansible

WORKDIR /dotfiles
COPY . .

RUN ansible-galaxy collection install -r ansible/requirements.yml

CMD ["bash", "docker/test.sh"]
