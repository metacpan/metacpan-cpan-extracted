WARNING_FLAGS= -Wall -Wstrict-prototypes -Wmissing-prototypes -Winline -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -Wconversion -Waggregate-return -Winline -W -Wno-unused -Wsign-compare

DEBUG_FLAGS= -g # -DSHISHI_DEBUG

C_FILES=shishi.c node.c decision.c
O_FILES=shishi.o node.o decision.o
H_FILES=shishi.h shishi_prot.h
LD=$(CC)

.c.o :
	gcc $(DEBUG_FLAGS) $(WARNING_FLAGS) -o $@ -c $<

libshishi.a: $(O_FILES)
	ar cr libshishi.a $(O_FILES)

test: libshishi.a test.o
	gcc $(DEBUG_FLAGS) $(WARNING_FLAGS) -o test test.o libshishi.a
	./test

test.o: test.c $(H_FILES)
shishi.o: shishi.c $(H_FILES)
node.o: node.c $(H_FILES)
decision.o: decision.c $(H_FILES)


shishi_prot.h: $(C_FILES)
	perl -ne 'print if s|\s*{\s*.*/\*\*/|;|;' *.c > shishi_prot.h

clean:
	rm -rf $(O_FILES) shishi_prot.h shishi libshishi.a test test.o
