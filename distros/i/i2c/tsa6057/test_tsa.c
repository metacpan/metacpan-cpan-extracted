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
#include "tsa6057.h"



int main(int argc, char *argv[]) {

 int test;
 int opt;

   long f = 58750000;
// long f = 92100000;
  
   while((opt=getopt(argc, argv, ":f:")) != EOF)
    switch(opt)
   {
 
    case 'f':
     f=atol(optarg);
     break;
   }  
       
 printf("*** i²c-TSA6057 Test (c) Ingo Gerlach 11/2000 *** \n");
 set_port_delay(5);		// Portdelay 0-255 
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
 
  test = tsa6057_init(&tsa,TSA6057_FM,TSA6057_R01); // Daten initialisieren Datenstruktur, 
  test  = tsa6057_calc(&tsa,f);

  printf(" db0 : %d \n",tsa.db0);
  printf(" db1 : %d \n",tsa.db1);
  printf(" db2 : %d \n",tsa.db2);
  printf(" db3 : %d \n",tsa.db3);
  printf(" Raster: %d \n",tsa.raster);
  
  printf(" n   : %d \n",test);
  printf("Ret: %d \n",tsa6057_send(&tsa,0));
  printf("deinit %d\n",deinit_iic()); 
 return 0;
}
