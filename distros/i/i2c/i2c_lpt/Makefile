CC=gcc
LINK = $(CC)
CFLAGS = -O2 -pipe -m386 -Wall 
LDFLAGS = -s


cpumon:		cpumon.o i2c_lpt.o ../lcd/lcd.o ../pcf8574/pcf8574.o
		$(LINK) -o cpumon cpumon.o i2c_lpt.o ../lcd/lcd.o ../pcf8574/pcf8574.o $(CFLAGS) 

clean:
	rm *.a *.o *~ core > /dev/null 2>&1

