/***********************************************************************/
/*  IIC-Interface  Testprogramm f. TSA6057		               */
/*  V0.1  erstellt am  : 06.11.2000                                    */
/*  Dateiname          : test_tsa.c				       */
/*                                     				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 					                               */
/* *********************************************************************/


#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "../i2c_lpt/i2c_lpt.h" 		// i2c Funktionen
#include "pcf8591.h"



int main(int argc, char *argv[]) {

 int test;
 float ubval;

 printf("*** i²c-PCF8591 Test (c) Ingo Gerlach 11/2000 *** \n");
 set_port_delay(6);		// Portdelay 0-255 
 test = init_iic(0);		// Init ii2c 0, automatisch suchen
 printf("Suche i2c-Interface...");
 if (test) 
 {
  printf(" gefunden an Port 0x%03xh! \n",test);
 } else {
    printf("Interface nicht gefunden.\n");
    exit (0);
  }
  set_strobe(1);			// Für den Seriellen Port nur dummy, Parport 
  io_disable();				// 8 Bit I/O disablen
 
  
  test = pcf8591_init(&adda,PCF8591_C4S,4.0000000); // Daten initialisieren Datenstruktur, ChanMode , REFub

  printf(" chan_mode : %d \n",adda.chan_mode);
  printf(" REF       : %3.3f\n",adda.REF);
  
  test  = pcf8591_readchan(&adda,0);
  test  = pcf8591_readchan(&adda,1);
  test  = pcf8591_readchan(&adda,2);
  test  = pcf8591_readchan(&adda,3);
  printf(" Kanal       Wert   UB\n");
  printf("----------------------\n");
  printf(" data 0    : %d \t    %2.3fV\n",adda.data[0],pcf8591_aout(&adda,0));
  printf(" data 1    : %d \t    %2.3fV\n",adda.data[1],pcf8591_aout(&adda,1));
  printf(" data 2    : %d \t    %2.3fV\n",adda.data[2],pcf8591_aout(&adda,2));
  printf(" data 3    : %d \t    %2.3fV\n\n",adda.data[3],pcf8591_aout(&adda,3));
  printf(" Kanal       Wert   UB\n");
  printf("----------------------\n");
  printf(" data 0    : %d \t    %2.3fV\n",adda.data[0],pcf8591_aout(&adda,0));
  printf(" data 1    : %d \t    %2.3fV\n",adda.data[1],pcf8591_aout(&adda,1));
  printf(" data 2    : %d \t    %2.3fV\n",adda.data[2],pcf8591_aout(&adda,2));
  printf(" data 3    : %d \t    %2.3fV\n",adda.data[3],pcf8591_aout(&adda,3));

  test  = pcf8591_read4chan(&adda);
  ubval = 1.8000;  
  test  = pcf8591_setda(&adda,ubval);
  printf(" Da_OUT  %2.2fV / %d \n",ubval,adda.da_val);
  deinit_iic();
  return 0;
}
