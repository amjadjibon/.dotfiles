FROM fedora:41

ENV HOME=/root

RUN dnf install -y \
    python3 \
    python3-pip \
    git \
    curl \
    sudo \
    ca-certificates \
    && dnf clean all

RUN pip3 install ansible

WORKDIR /dotfiles
COPY . .

RUN ansible-galaxy collection install -r ansible/requirements.yml

CMD ["bash", "docker/test.sh"]
