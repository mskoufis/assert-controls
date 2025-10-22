all: build  

clean:
	docker rmi -f assert_dev_image:$(shell git branch --show-current)
	docker image prune -a -f

cleanall:
	docker system prune

build:
	docker build -t assert_dev_image:$(shell git branch --show-current) . --build-arg user=$(USER) --build-arg uid=$(shell id -u) --build-arg gid=$(shell id -g)

run:
	docker run -it -e DISPLAY=$(DISPLAY) -v /tmp/.X11-unix:/tmp/.X11-unix -v $(HOME)/.Xauthority:/home/$(USER)/.Xauthority --net=host -v /dev/input:/dev/input --device=/dev/datadev_0:/dev/datadev_0 assert_dev_image:$(shell git branch --show-current)

.PHONY: all clean cleanall build run
