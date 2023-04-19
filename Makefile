ID := $(shell basename $(CURDIR))
IMAGE_ID := $(addsuffix _image, $(ID))
CONTAINER_ID := $(addsuffix _container, $(ID))

build: stop
	docker build -t $(IMAGE_ID) .

stop:
	docker stop `docker ps -a -q --filter label=juneway-nginx` || true

start: stop
ifeq ([], $(shell docker inspect $(IMAGE_ID) 2> /dev/null))
	@ echo "Please, run 'make build' before 'make start'" >&2; exit 1;
else
	docker run -d -t --rm \
		--label juneway-nginx \
		--memory=500m \
		--memory-swap=500m \
		-v /tmp \
		-v /var/tmp \
		-v $(CURDIR)/nginx.conf:/usr/local/nginx/conf/nginx.conf \
		-v $(CURDIR)/data:/usr/share/nginx/data \
		-p 8000:80 --name $(CONTAINER_ID) $(IMAGE_ID)
endif
