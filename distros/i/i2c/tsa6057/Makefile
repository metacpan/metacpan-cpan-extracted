# Linkt die LIB aus ../lib
CC=gcc
LINK = $(CC)
CFLAGS = -O2 -pipe -m386 -Wall 
LDFLAGS = -s -li2c_lpt -L /home/ingo/c/i2c/lib


test_sda:	test_tsa.o tsa6057.o 
		$(LINK) -o test_tsa test_tsa.o tsa6057.o $(CFLAGS) $(LDFLAGS)

clean:
	rm *.a *.o *~ core > /dev/null 2>&1

