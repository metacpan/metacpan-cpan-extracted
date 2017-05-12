/*
 * header file for WiringPi::API.xs
 */

int bmp180Pressure(int pin);
int bmp180Temp(int pin);
int initThread(char * callback);
void interruptHandler();
int physPinToWpi(int wpi_pin);
int setInterrupt(int pin, int edge, char* callback);
int wiringPiI2CSetup (int devId);
int wiringPiI2CSetupInterface (char* device, int devId);
int wiringPiI2CRead (int fd);
int wiringPiI2CReadReg8 (int fd, int reg);
int wiringPiI2CReadReg16 (int fd, int reg);
int wiringPiI2CWrite (int fd, int data);
int wiringPiI2CWriteReg8 (int fd, int reg, int data);
int wiringPiI2CWriteReg16 (int fd, int reg, int data);
unsigned int digitalReadByte();
unsigned int digitalReadByte2();
void digitalWriteByte(int value);
void digitalWriteByte2(int value);
int ads1115Setup(int pin_base, int addr);
int pseudoPinsSetup(int pin_base);
void pinModeAlt(int pin, int mode);
int bmp180Setup(int pin_base);
int bmp180Pressure(int pin);
int bmp180Temp(int pin);

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

