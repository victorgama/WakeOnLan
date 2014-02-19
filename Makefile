current_dir = $(shell pwd)

all:
	chmod +x ./bin/wake
	ln -s $(current_dir)/bin/wake /usr/bin/wake