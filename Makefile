current_dir = $(shell pwd)

all:
	chmod +x ./bin/wake
	bundle install
	ln -s $(current_dir)/bin/wake /usr/local/bin/wake

