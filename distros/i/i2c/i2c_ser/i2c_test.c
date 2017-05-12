/***********************************************************************/
/*  IIC-Seriell-Interface  I2C				               */
/*  V0.1  erstellt am  : 04.11.2000                                    */
/*  Dateiname          : i2c_test.c				       */
/*                                     				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 26.10.00 , Test für i2c_ser.c                                       */
/* *********************************************************************/

#include <stdio.h>

#include "../src/i2c_ser.h" 		// i2c Funktionen
#include "../src/lcd.h"

int COM;

int main(void) {

 int test;
 unsigned char byte;
// PCF_ADRESS = 0;	// Adresse des PCF'S 
 
 printf("*** i²c-LCD Test (c) Ingo Gerlach 10/2000 *** \n");
 COM  = 0; 			// Vorbelegung Ser - Port, 0 Automatisch suchen
 set_port_delay(15);		// Portdelay 0-255 
 test = init_iic(COM);		// Init ii2c 
 printf("Suche i2c-Interface...");
 if (test) 
 {
  printf(" gefunden an Port 0x%03xh! \n",test);
 } else {
    printf("Interface nicht gefunden.\n");
    exit (0);
  }
/*
 set_strobe(1);			// Für den Seriellen Port nur dummy
 io_disable(0);
*/
 sda_high();
 scl_high();
 printf("read_sda %d \n",read_sda());
 printf("read_scl %d \n",read_scl());
 iic_start();
 byte =getchar();
 iic_stop();
 sda_low();
 scl_low();
 printf("read_sda %d \n",read_sda());
printf("read_scl %d \n",read_scl());    
lcd_backlight(0); 
byte = getchar();
 printf("deinit %d\n",deinit_iic()); 
 return 0;
}
