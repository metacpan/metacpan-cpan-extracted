/*
 * API.xs file for WiringPi::API Perl distribution
 *
 * Copyright (c) 2017-2026 by Steve Bertrand
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the same terms as Perl itself, either Perl version 5.18.2 or, at your option,
 * any later version of Perl 5 you may have available.
 *
 */

#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <unistd.h>
#include <fcntl.h>

#define PERL_NO_GET_CONTEXT

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
#include <softTone.h>
#include <sr595.h>

// Used for interrupts (self-pipe: the wiringPi ISR thread write()s a fixed
// event record to a pipe and never touches Perl; the Perl side reads
// + dispatches)

#define MAX_PINS 40

/* Fixed-size event record. Stays well under PIPE_BUF, so each write() is atomic
 * even if several per-pin ISR threads fire concurrently. */

typedef struct {
    int          pin;      /* the caller's pin (from userdata, NOT wfiStatus.pinBCM) */
    unsigned int pin_bcm;  /* wfiStatus.pinBCM - the BCM gpio that fired */
    int          edge;
    int          status;   /* wfiStatus.statusOK (1 = real irq on this path) */
    long long    ts_us;
} isr_event_t;

static int           interrupt_pipe[2] = { -1, -1 };  /* [0] read, [1] write */
static unsigned long interrupts_dropped = 0;          /* events lost to a full pipe */

/* Runs in wiringPi's per-pin ISR thread. Async-safe: only a write() and an
 * atomic counter bump - it never enters the Perl interpreter. The caller's pin
 * arrives via userdata (keyed to the user's numbering scheme); wfiStatus.pinBCM
 * is always BCM and would mis-key callbacks under setup() (wiringPi numbering).
 */

static void isr2_writer(struct WPIWfiStatus wfiStatus, void *userdata){
    isr_event_t rec;

    rec.pin     = (int)(intptr_t)userdata;
    rec.pin_bcm = wfiStatus.pinBCM;
    rec.edge    = wfiStatus.edge;
    rec.status  = wfiStatus.statusOK;
    rec.ts_us   = wfiStatus.timeStamp_us;

    if (interrupt_pipe[1] < 0){
        return;
    }

    if (write(interrupt_pipe[1], &rec, sizeof(rec)) != (ssize_t)sizeof(rec)){
        __sync_fetch_and_add(&interrupts_dropped, 1);
    }
}

/* Lazily create the self-pipe, both ends non-blocking. Returns 0 on success. */

static int ensure_interrupt_pipe(void){
    int i;

    if (interrupt_pipe[0] >= 0){
        return 0;
    }

    if (pipe(interrupt_pipe) != 0){
        return -1;
    }

    for (i = 0; i < 2; i++){
        int flags = fcntl(interrupt_pipe[i], F_GETFL, 0);
        fcntl(interrupt_pipe[i], F_SETFL, flags | O_NONBLOCK);
    }

    return 0;
}

/* Arm (or re-arm) an interrupt on pin via wiringPiISR2, carrying the caller's
 * pin as userdata. Always stops any existing listener first, so re-arming can
 * never stack a second wiringPi thread on the pin. */

int _arm_interrupt(int pin, int edge, unsigned long debounce){
    if (pin < 0 || pin >= MAX_PINS){
        croak("pin out of range\n");
    }

    if (ensure_interrupt_pipe() != 0){
        croak("could not create interrupt pipe\n");
    }

    wiringPiISRStop(pin);

    return wiringPiISR2(pin, edge, isr2_writer, debounce, (void *)(intptr_t)pin);
}

/* Read end of the self-pipe; -1 until the first arm creates the pipe. */

int interrupt_fd(void){
    return interrupt_pipe[0];
}

/* Count of interrupt events dropped because the pipe was full (F24). */

unsigned long interrupt_dropped(void){
    return interrupts_dropped;
}

/* Close both ends of the self-pipe and reset interrupt state. The Perl side
 * stops the wiringPi ISR threads (wiringPiISRStop) and closes its own read dup
 * before calling this, so no writer or reader is left referencing these fds. */

void _close_interrupt_pipe(void){
    if (interrupt_pipe[0] >= 0){
        close(interrupt_pipe[0]);
        interrupt_pipe[0] = -1;
    }
    if (interrupt_pipe[1] >= 0){
        close(interrupt_pipe[1]);
        interrupt_pipe[1] = -1;
    }
    interrupts_dropped = 0;
}

int physPinToWpi(int wpi_pin){
    /* phys_wpi_map has 64 entries (physical header positions); -1 means
       "no such pin". Guard out-of-range input to avoid an OOB read. */
    if (wpi_pin < 0 || wpi_pin >= (int)(sizeof(phys_wpi_map) / sizeof(phys_wpi_map[0]))){
        return -1;
    }
    return phys_wpi_map[wpi_pin];
}

int bmp180Pressure(int pin){
    return analogRead(pin);
}

int bmp180Temp(int pin){
    return analogRead(pin);
}

MODULE = WiringPi::API  PACKAGE = WiringPi::API PREFIX = XS_

PROTOTYPES: DISABLE

#
# core
#

int
wiringPiSetup()

int
wiringPiSetupGpio()

int
wiringPiSetupPinType(pinType)
    int pinType

int
wiringPiSetupGpioDevice(pinType)
    int pinType

int
wiringPiGpioDeviceGetFd()

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

char *
wiringPiVersion()
    CODE:
        int major;
        int minor;
        char ver[16];
        wiringPiVersion(&major, &minor);
        snprintf(ver, sizeof(ver), "%d.%d", major, minor);
        RETVAL = ver;
    OUTPUT:
        RETVAL

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

void
pwmSetClock(divisor)
    int divisor

void pwmSetMode(mode)
    int mode

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
    unsigned char command

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

# soft tone

int
softToneCreate(pin)
    int pin

void
softToneStop(pin)
    int pin

void
softToneWrite(pin, freq)
    int pin
    int freq

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

# timing / scheduling

void
delay(ms)
    unsigned int ms

void
delayMicroseconds(us)
    unsigned int us

unsigned int
millis()

unsigned int
micros()

uint64_t
piMicros64()

int
piHiPri(pri)
    int pri

# pad drive / pwm tone / gpio clock

void
setPadDrive(group, value)
    int group
    int value

void
setPadDrivePin(pin, value)
    int pin
    int value

void
pwmToneWrite(pin, freq)
    int pin
    int freq

void
gpioClockSet(pin, freq)
    int pin
    int freq

# board / identity

int
wiringPiGlobalMemoryAccess()

int
wiringPiUserLevelAccess()

int
getPinModeAlt(pin)
    int pin

int
piBoard40Pin()

int
piRP1Model()

void
piBoardId()
    PPCODE:
        int model, rev, mem, maker, overVolted;
        piBoardId(&model, &rev, &mem, &maker, &overVolted);
        EXTEND(SP, 5);
        mPUSHi(model);
        mPUSHi(rev);
        mPUSHi(mem);
        mPUSHi(maker);
        mPUSHi(overVolted);

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
wiringPiISRStop(pin)
    int pin

int
_arm_interrupt(pin, edge, debounce)
    int pin
    int edge
    unsigned long debounce

int
interrupt_fd()

unsigned long
interrupt_dropped()

void
_close_interrupt_pipe()

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

unsigned int
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
    int channel
    SV *byte_ref
    int len
    PREINIT:
        AV *bytes;
        unsigned char *buf;
        int i;
        int num_bytes;
    PPCODE:
        if (channel != 0 && channel != 1)
            croak("spiDataRW: channel param must be 0 or 1");
        if (! SvROK(byte_ref) || SvTYPE(SvRV(byte_ref)) != SVt_PVAV)
            croak("spiDataRW: data param must be an array reference");
        bytes = (AV*)SvRV(byte_ref);
        num_bytes = av_len(bytes) + 1;
        if (len != num_bytes)
            croak("spiDataRW: len param does not match element count in data");
        Newx(buf, len > 0 ? len : 1, unsigned char);
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(bytes, i, 0);
            int val;
            if (elem == NULL || ! SvOK(*elem)) {
                Safefree(buf);
                croak("spiDataRW: byte %d in data param is undefined", i);
            }
            val = (int)SvNV(*elem);
            if (val < 0 || val > 255) {
                Safefree(buf);
                croak("spiDataRW: byte %d in data param out of range: (%d)", i, val);
            }
            buf[i] = (unsigned char)val;
        }
        if (wiringPiSPIDataRW(channel, buf, len) < 0) {
            Safefree(buf);
            croak("spiDataRW: failed to write to the SPI bus");
        }
        EXTEND(SP, (SSize_t)len);
        for (i = 0; i < len; i++)
            PUSHs(sv_2mortal(newSViv(buf[i])));
        Safefree(buf);


int
wiringPiSPIGetFd(channel)
    int channel

int
wiringPiSPISetupMode(channel, speed, mode)
    int channel
    int speed
    int mode

int
wiringPiSPIClose(channel)
    int channel

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

void
wiringPiI2CReadBlockData(fd, reg, size)
    int fd
    int reg
    int size
    PREINIT:
        uint8_t buf[256];
        int n, i;
    PPCODE:
        if (size < 0 || size > 255)
            croak("wiringPiI2CReadBlockData: size must be 0-255");
        n = wiringPiI2CReadBlockData(fd, reg, buf, (uint8_t)size);
        if (n < 0)
            croak("wiringPiI2CReadBlockData: read failed");
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHu(buf[i]);

void
wiringPiI2CRawRead(fd, size)
    int fd
    int size
    PREINIT:
        uint8_t buf[256];
        int n, i;
    PPCODE:
        if (size < 0 || size > 255)
            croak("wiringPiI2CRawRead: size must be 0-255");
        n = wiringPiI2CRawRead(fd, buf, (uint8_t)size);
        if (n < 0)
            croak("wiringPiI2CRawRead: read failed");
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHu(buf[i]);

int
wiringPiI2CWriteBlockData(fd, reg, values)
    int fd
    int reg
    SV * values
    PREINIT:
        uint8_t buf[256];
        AV *av;
        int len, i;
        SV **elem;
    CODE:
        if (! SvROK(values) || SvTYPE(SvRV(values)) != SVt_PVAV)
            croak("wiringPiI2CWriteBlockData: values must be an array reference");
        av = (AV *)SvRV(values);
        len = av_len(av) + 1;
        if (len < 0 || len > 255)
            croak("wiringPiI2CWriteBlockData: 0-255 values allowed");
        for (i = 0; i < len; i++) {
            elem = av_fetch(av, i, 0);
            buf[i] = (uint8_t)(elem ? SvUV(*elem) : 0);
        }
        RETVAL = wiringPiI2CWriteBlockData(fd, reg, buf, (uint8_t)len);
    OUTPUT:
        RETVAL

int
wiringPiI2CRawWrite(fd, values)
    int fd
    SV * values
    PREINIT:
        uint8_t buf[256];
        AV *av;
        int len, i;
        SV **elem;
    CODE:
        if (! SvROK(values) || SvTYPE(SvRV(values)) != SVt_PVAV)
            croak("wiringPiI2CRawWrite: values must be an array reference");
        av = (AV *)SvRV(values);
        len = av_len(av) + 1;
        if (len < 0 || len > 255)
            croak("wiringPiI2CRawWrite: 0-255 values allowed");
        for (i = 0; i < len; i++) {
            elem = av_fetch(av, i, 0);
            buf[i] = (uint8_t)(elem ? SvUV(*elem) : 0);
        }
        RETVAL = wiringPiI2CRawWrite(fd, buf, (uint8_t)len);
    OUTPUT:
        RETVAL

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

void
serialGets(fd, nbytes)
    int fd
    int nbytes
    PREINIT:
        char *buf;
        int got = 0;
        int flags;
        int result;
    PPCODE:
        if (nbytes < 0)
            croak("serialGets: nbytes must be a non-negative integer");
        /* wiringPi's serialOpen() sets O_NONBLOCK, which defeats the port's
           VMIN/VTIME read timeout. Clear it so a read blocks up to that
           timeout instead of returning EAGAIN immediately. */
        flags = fcntl(fd, F_GETFL, 0);
        if (flags != -1 && (flags & O_NONBLOCK))
            fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
        Newx(buf, nbytes > 0 ? nbytes : 1, char);
        while (got < nbytes) {
            result = read(fd, buf + got, nbytes - got);
            if (result > 0) {
                got += result;
                continue;
            }
            if (result == 0)
                break;                  /* VTIME timeout or EOF */
            if (errno == EINTR)
                continue;               /* interrupted by a signal; retry */
            Safefree(buf);
            croak("serialGets: read error: %s", strerror(errno));
        }
        ST(0) = sv_2mortal(newSVpvn(buf, got));
        Safefree(buf);
        XSRETURN(1);
