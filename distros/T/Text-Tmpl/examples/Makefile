CFLAGS= -g -Wall -I..
LFLAGS= -L.. -ltmpl

all: tmpl-eg-cc tmpl-eg-c

tmpl-eg-cc: tmpl-eg.cc
	g++ ${CFLAGS} -o $@ tmpl-eg.cc ${LFLAGS}

tmpl-eg-c: tmpl-eg.c
	gcc ${CFLAGS} -o $@ tmpl-eg.c ${LFLAGS}

clean:
	rm -f tmpl-eg-cc tmpl-eg-c
