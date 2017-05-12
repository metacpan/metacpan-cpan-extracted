
LIBS = -lyaz -lxml2 -lssl	# Ubuntu Linux 6.06

setrlimit: setrlimit.c
	$(CC) -g -O0 -Wall -ansi -pedantic -o $@ $?

test-zoom-c: test-zoom-c.c
	$(CC) -g -O0 -Wall -o $@ $? $(LIBS)

clean:
	rm -f test-zoom-c

