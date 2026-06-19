FROM archlinux:latest

ENV HOME=/root

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    python \
    python-pip \
    git \
    curl \
    sudo \
    ca-certificates \
    && pacman -Scc --noconfirm

RUN pip install --break-system-packages ansible

WORKDIR /dotfiles
COPY . .

RUN ansible-galaxy collection install -r ansible/requirements.yml

CMD ["ansible-playbook", "-i", "ansible/inventory.ini", "ansible/setup.yml", \
     "--extra-vars", "in_docker=true", \
     "-e", "ansible_python_interpreter=/usr/bin/python3"]
