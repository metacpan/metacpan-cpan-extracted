# Linkt die LIB aus ../lib
CC=gcc
LINK = $(CC)
CFLAGS = -O2 -pipe -m386 -Wall 
LDFLAGS = -s -li2c_ser -L /home/ingo/c/i2c/lib


i2c_test:	i2c_test.o ../i2c_ser/i2c_ser.o 
		$(LINK) -o i2c_test i2c_test.o ../i2c_ser/i2c_ser.o  $(CFLAGS) $(LDFLAGS)

cpumon:		cpumon.o ../i2c_ser/i2c_ser.o
		$(LINK) -o cpumon cpumon.o $(LDFLAGS)

clean:
	rm *.a *.o *~ core > /dev/null 2>&1

