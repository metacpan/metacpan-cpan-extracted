/*
 * API.xs file for WiringPi::API Perl distribution
 *
 * Copyright (c) 2017 by Steve Bertrand
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the same terms as Perl itself, either Perl version 5.18.2 or, at your option,
 * any later version of Perl 5 you may have available.
 *
 */

#include <stdlib.h>
#include <stdint.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "INLINE.h"

#include "API.h"
#include <wiringPi.h>
#include <wiringPiSPI.h>
#include <lcd.h>
#include <sys/mman.h>
#include <softPwm.h>
#include <sr595.h>

#define PERL_NO_GET_CONTEXT

char* serialGets(int fd, char* buf, int nbytes){
    int bytes_read = 0;

    while (bytes_read < nbytes){
        int result = read(fd, buf + bytes_read, nbytes - bytes_read);
        
        if (0 >= result){
            if (0 > result){
                exit(-1);
            }
            break;
        }
        bytes_read += result;
    }

    return buf;
}

void spiDataRW(int channel, SV* byte_ref, int len){

     /*
      * Custom wrapper for wiringPiSPIDataRW() as we
      * need to translate an aref into an unsigned char *,
      * and then send back an array containing the bytes
      * read from the device
      */ 

    if (channel != 0 && channel != 1){
        croak("channel param must be 0 or 1\n");
    }

    if (! SvROK(byte_ref) || SvTYPE(SvRV(byte_ref)) != SVt_PVAV){
        croak("data param must be an array reference\n");
    }

    AV* bytes = (AV*)SvRV(byte_ref);

    int num_bytes = av_len(bytes) + 1;

    if (len != num_bytes){
        croak("len param doesn't match element count in data\n");
    }

    unsigned char buf[num_bytes];

    int i;

    for (i=0; i<len; i++){
        SV** elem = av_fetch(bytes, i, 0);

        int elem_int = (int)SvNV(*elem);
        
        if (elem_int < 0 || elem_int > 255){
            printf("byte %d in data param out of range: (%d)\n", i, elem_int);
            exit(1);
        }

        buf[i] = (unsigned char)SvNV(*elem);
    }
    
    if (wiringPiSPIDataRW(channel, buf, len) < 0){
        croak("failed to write to the SPI bus\n");
    }

    inline_stack_vars;
    inline_stack_reset;

    int x;
    for (x=0; x<len; x++){
        inline_stack_push(sv_2mortal(newSViv(buf[x])));
    } 

    inline_stack_done;
}

char * perl_callback; // dynamically set perl callback for interrupt handler
PerlInterpreter * mine;

void interruptHandler(){
    PERL_SET_CONTEXT(mine);

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;

    call_pv(perl_callback, G_DISCARD|G_NOARGS);

    FREETMPS;
    LEAVE;
}

int setInterrupt(int pin, int edge, char * callback){
    mine = Perl_get_context();
    perl_callback = callback;
    int interrupt = wiringPiISR(pin, edge, &interruptHandler);
    return interrupt;
}

int initThread(char * callback){
    mine = Perl_get_context();

    PI_THREAD (myThread){
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;

        call_pv(callback, G_DISCARD|G_NOARGS);

        FREETMPS;
        LEAVE;
    }

    return piThreadCreate(myThread);
}

int physPinToWpi(int wpi_pin){
    return phys_wpi_map[wpi_pin];
}

int bmp180Pressure(int pin){
    return analogRead(pin);
}

int bmp180Temp(int pin){
    return analogRead(pin);
}

/*
    not yet implemented

    extern          void setPadDrive         (int group, int value) ;
    extern          void pwmToneWrite        (int pin, int freq) ;
    extern          void pwmSetMode          (int mode) ;
    extern          void pwmSetClock         (int divisor) ;
    extern          void gpioClockSet        (int pin, int freq) ;

*/

MODULE = WiringPi::API  PACKAGE = WiringPi::API PREFIX = XS_

#
# core
#

int
wiringPiSetup()

int
wiringPiSetupSys()

int
wiringPiSetupGpio()

int wiringPiSetupPhys()

void
pinMode(pin, mode)
    int pin
    int mode

void
pullUpDnControl(pin, pud)
    int pin
    int pud

int
digitalRead(pin)
    int pin

void
digitalWrite(pin, value)
    int pin
    int value

void
pwmWrite(pin, value)
    int pin
    int value

int
getAlt(pin)
    int pin

int
analogRead(pin)
    int pin

void
analogWrite(pin, value)
    int pin
    int value

#
# board
#

int
piGpioLayout()

int 
wpiPinToGpio(wpiPin)
    int wpiPin

int 
physPinToGpio(physPin)
    int physPin

void
pwmSetRange(range)
    unsigned int range

#
# lcd
#

int
lcdInit(rows, cols, bits, rs, strb, d0, d1, d2, d3, d4, d5, d6, d7)
    int rows
    int cols
    int bits
    int rs
    int strb
    int d0
    int d1
    int d2
    int d3
    int d4
    int d5
    int d6
    int d7

void
lcdHome(fd)
    int fd

void
lcdClear(fd)
    int fd

void
lcdDisplay(fd, state)
    int fd
    int state

void
lcdCursor(fd, state)
    int fd
    int state

void
lcdCursorBlink(fd, state)
    int fd
    int state

void
lcdSendCommand(fd, command)
    int fd
    char command

void
lcdPosition(fd, x, y)
    int fd
    int x
    int y

void
lcdCharDef(fd, index, data)
    int fd
    int index
    unsigned char * data

void
lcdPutchar(fd, data)
    int fd
    unsigned char data

void
lcdPuts(fd, string)
    int fd
    char * string

# soft pwm

int
softPwmCreate(pin, value, range)
    int pin
    int value
    int range

void
softPwmWrite(pin, value)
    int pin
    int value

void softPwmStop(pin)
    int pin

# SR74HC595 shift register

int
sr595Setup(pin_base, num_pins, data_pin, clock_pin, latch_pin)
    int pin_base
    int num_pins
    int data_pin
    int clock_pin
    int latch_pin

void
piLock(keyNum)
    int keyNum

void piUnlock(keyNum)
    int keyNum

# bmp180 pressure sensor

int
bmp180Setup(pin_base)
    int pin_base

int
bmp180Pressure(pin)
    int pin

int
bmp180Temp(pin)
    int pin

# custom

int
setInterrupt(pin, edge, callback)
    int pin
    int edge
    char * callback

void
interruptHandler()

int
initThread(callback)
    char * callback

int
physPinToWpi(wpi_pin)
    int wpi_pin

int
ads1115Setup(pin_base, addr)
    int pin_base
    int addr

int
pseudoPinsSetup(pin_base)
    int pin_base

void
pinModeAlt(pin, mode)
    int pin
    int mode

int
digitalReadByte()

unsigned int
digitalReadByte2()

void
digitalWriteByte(value)
    int value

void
digitalWriteByte2(value)
    int value

# SPI

int
wiringPiSPISetup(channel, speed)
    int channel
    int speed

void
spiDataRW (channel, byte_ref, len)
	int	channel
	SV *	byte_ref
	int	len
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        spiDataRW(channel, byte_ref, len);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;

# I2C

int wiringPiI2CSetup (devId)
    int devId

int wiringPiI2CSetupInterface (device, devId)
    char* device
    int devId

int wiringPiI2CRead (fd)
    int fd

int wiringPiI2CReadReg8 (fd, reg)
    int fd
    int reg

int wiringPiI2CReadReg16 (fd, reg)
    int fd
    int reg

int wiringPiI2CWrite (fd, data)
    int fd
    int data

int wiringPiI2CWriteReg8 (fd, reg, data)
     int fd
     int reg
     int data

int wiringPiI2CWriteReg16 (fd, reg, data)
    int fd
    int reg
    int data

# serial interface

int serialOpen (device, baud)
    char* device
    int baud

void serialClose (fd)
    int fd

void serialFlush (fd)
    int fd

void serialPutchar (fd, c)
    int fd
    unsigned char c

void serialPuts (fd, s)
    int fd
    char* s

int serialDataAvail (fd)
    int fd

int serialGetchar (fd)
    int fd

char* serialGets(fd, buf, nbytes)
    int fd
    char* buf
    int nbytes
