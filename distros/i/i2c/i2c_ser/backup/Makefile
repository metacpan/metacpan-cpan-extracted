CC=gcc
LINK = $(CC)
CFLAGS = -O2 -pipe -m386 -Wall 
LDFLAGS = -s


i2c_test:	i2c_test.o i2c_ser.o 
		$(LINK) -o i2c_test i2c_test.o i2c_ser.o  $(CFLAGS) 


clean:
	rm *.a *.o *~ core > /dev/null 2>&1

