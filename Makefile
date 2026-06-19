.PHONY: test test-ubuntu test-fedora test-arch clean

test: test-ubuntu test-fedora test-arch

test-ubuntu:
	docker compose -f docker/docker-compose.yml build ubuntu
	docker compose -f docker/docker-compose.yml run --rm ubuntu

test-fedora:
	docker compose -f docker/docker-compose.yml build fedora
	docker compose -f docker/docker-compose.yml run --rm fedora

test-arch:
	docker compose -f docker/docker-compose.yml build arch
	docker compose -f docker/docker-compose.yml run --rm arch

clean:
	docker compose -f docker/docker-compose.yml down --rmi all --volumes
