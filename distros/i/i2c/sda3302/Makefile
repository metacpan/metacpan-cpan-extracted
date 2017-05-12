# Linkt die LIB aus ../lib
CC=gcc
LINK = $(CC)
CFLAGS = -O2 -pipe -m386 -Wall 
LDFLAGS = -s -li2c_lpt -L /home/ingo/c/i2c/lib


test_sda:	test_sda.o sda3302.o 
		$(LINK) -o test_sda test_sda.o sda3302.o $(CFLAGS) $(LDFLAGS)

clean:
	rm *.a *.o *~ core > /dev/null 2>&1

