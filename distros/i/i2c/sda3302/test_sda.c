/***********************************************************************/
/*  IIC-Interface  Testprogramm f. SDA3302		               */
/*  V0.1  erstellt am  : 06.11.2000                                    */
/*  Dateiname          : test_sda.c				       */
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
//#include "../src/lcd.h"
#include "sda3302.h"

// Datentructur f. SDA3302


int main(int argc, char *argv[]) {

 int test;
 int opt;

   long f = 439250000;
  // long f = 92100000;
  
   while((opt=getopt(argc, argv, ":f:")) != EOF)
    switch(opt)
   {
 
    case 'f':
     f=atol(optarg);
     break;
   }  
       
 printf("*** i²c-LCD Test (c) Ingo Gerlach 11/2000 *** \n");
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
 
  test = sda3302_init(&sda,SDA3302_PLL); // Daten initialisieren Datenstruktur, 
  						  // ZF (in HZ) , Mode SDA3302_PLL/SDA3302_DIV

  printf(" Init %d \n",sda.cnt1);  						  
  test  = sda3302_calc(&sda,f);
  printf("Freq: %ld , Teiler n %d , Fres: %d\n",f,test,((test*SDA3302_STEP)-SDA3302_ZF));
  printf(" Div 1 : %d \n",sda.div1);
  printf(" Div 2 : %d \n",sda.div2);
  printf(" Cont1 : %d \n",sda.cnt1);
  printf(" Cont2 : %d \n",sda.cnt2);
  printf("Ret: %d \n",sda3302_send(&sda,0));
  printf("deinit %d\n",deinit_iic()); 
 return 0;
}
