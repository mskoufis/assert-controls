all: build  

clean:
	docker image prune
	docker rmi -f assert_dev_image:$(shell git branch --show-current)

build:
	docker build -t assert_dev_image:$(shell git branch --show-current) .

.PHONY: clean build all
