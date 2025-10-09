all: build  

clean:
	docker image prune
	docker rmi -f assert_dev_image:$(shell git branch --show-current)

build:
	docker build -t assert_dev_image:$(shell git branch --show-current) .

run:
	docker run -it -e DISPLAY=$(DISPLAY) -v /tmp/.X11-unix:/tmp/.X11-unix --device=/dev/datadev_0:/dev/datadev_0 assert_dev_image:$(shell git branch --show-current)

.PHONY: clean build all run
