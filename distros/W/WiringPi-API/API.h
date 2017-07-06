/*
 * API.h file for WiringPi::API Perl distribution
 *
 * Copyright (c) 2017 by Steve Bertrand
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the same terms as Perl itself, either Perl version 5.18.2 or, at your option,
 * any later version of Perl 5 you may have available.
 *
 */

// BMP-180 barometric pressure sensor
int bmp180Setup(int pin_base);
int bmp180Pressure(int pin);
int bmp180Temp(int pin);

// threads
int initThread(char * callback);

// interrupts
int setInterrupt(int pin, int edge, char* callback);
void interruptHandler();

// setup routines
int wiringPiI2CSetup (int devId);
int wiringPiI2CSetupInterface (char* device, int devId);

// I2C
int wiringPiI2CRead (int fd);
int wiringPiI2CReadReg8 (int fd, int reg);
int wiringPiI2CReadReg16 (int fd, int reg);
int wiringPiI2CWrite (int fd, int data);
int wiringPiI2CWriteReg8 (int fd, int reg, int data);
int wiringPiI2CWriteReg16 (int fd, int reg, int data);

// GPIO pin specific
int physPinToWpi(int wpi_pin);
void pinModeAlt(int pin, int mode);

// read functions
unsigned int digitalReadByte();
unsigned int digitalReadByte2();

// write functions
void digitalWriteByte(int value);
void digitalWriteByte2(int value);

// ADS1115 ADC
int ads1115Setup(int pin_base, int addr);

// pseudo pins
int pseudoPinsSetup(int pin_base);

int   serialOpen(const char *device, const int baud) ;
void  serialClose(const int fd) ;
void  serialFlush(const int fd) ;
void  serialPutchar(const int fd, const unsigned char c) ;
void  serialPuts(const int fd, const char *s) ;
void  serialPrintf(const int fd, const char *message, ...) ;
int   serialDataAvail(const int fd) ;
int   serialGetchar(const int fd) ;

// typedefs
static int phys_wpi_map[64] =
{
  -1, // pin 0 doesn't exist
  -1, -1,
   8, -1,
   9, -1,
   7, 15,
  -1, 16,
   0,  1,
   2, -1,
   3,  4,
  -1,  5,
  12, -1,
  13,  6,
  14, 10,
  -1, 11,
  30, 31,
  21, -1,
  22, 26,
  23, -1,
  24, 27,
  25, 28,
  -1, 29,
  -1, -1,
  -1, -1,
  -1, -1,
  -1, -1,
  -1, -1,
  17, 18,
  19, 20,
  -1, -1,
  -1, -1,
  -1, -1,
  -1, -1,
  -1
};

