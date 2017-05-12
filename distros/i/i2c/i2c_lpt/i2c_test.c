/***********************************************************************/
/*  IIC-Parallel-Interface  I2C				               */
/*  V0.1  erstellt am  : 26.10.2000                                    */
/*  Dateiname          : i2c_test.c				       */
/*                                     				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 26.10.00 , Test für i2c_lpt.c                                       */
/* *********************************************************************/

#include <stdio.h>

#include "i2c_lpt.h" 		// i2c Funktionen
#include "../lcd/lcd.h"		// lcd  
#include "../pcf8574/pcf8574.h"	// PCF8574


int LPT;

int main(void) {

 int test;
 unsigned char byte;
 PCF_ADRESS = 0;	// Adresse des PCF'S 
 
 printf("*** i²c-LCD Test (c) Ingo Gerlach 10/2000 *** \n");
 LPT  = 0; 			// Vorbelegung LPT - Port, 0 Automatisch suchen
 set_port_delay(15);		// Portdelay 0-255 
 test = init_iic(LPT);		// Init ii2c 
 printf("Suche i2c-Interface...");
 if (test) 
 {
  printf(" gefunden an Port 0x%03xh! \n",test);
 } else {
    printf("Interface nicht gefunden.\n");
    exit (0);
  }
 set_strobe(1);			
 io_disable();
 test=lcd_init();
 //iic_tx_pcf8574(0,PCF_ADRESS);
 lcd_backlight(0); // Ausschalten (gibt 1 zurück wenn, OK)
 printf("rückgabe lcd_bl: %d \n",lcd_BACKLIGHT);
 printf("Rückgabe init %d \n",test);
 printf("Light off !!!\nPress Enter to turn on...");
 // test=getchar();
 // iic_tx_pcf8574(8,PCF_ADRESS);
 // test=iic_rx_pcf8574(&dum,PCF_ADRESS); // Ret 1 = OK
 printf("rückgabe lcd_bl: %d \n",lcd_BACKLIGHT); 
 lcd_BACKLIGHT=lcd_backlight(1);
 printf("VAR lcd_BACKLIGHT : %d \n",lcd_BACKLIGHT);
// Text Schreiben 
 lcd_wchar('H');
 lcd_wchar('a');
 lcd_wchar('l');
 lcd_wchar('l');
 lcd_wchar('o');
 lcd_ADRESS=lcd_get_adress();
 lcd_instr(LCD_ADR+lcd_ADRESS+1);
 lcd_wchar('M');
 lcd_wchar('a');
 lcd_wchar('u');
 lcd_wchar('s');
 // 2. Zeile 
 lcd_instr(LCD_ADR+64);
 lcd_wchar('H');
 lcd_wchar('a');
 lcd_wchar('l');
 lcd_wchar('l');
 lcd_wchar('o');
 lcd_ADRESS=lcd_get_adress();
 lcd_instr(LCD_ADR+lcd_ADRESS+1);
 lcd_wchar('M');
 lcd_wchar('a');
 lcd_wchar('u');
 lcd_wchar('s');

 lcd_instr(LCD_ADR+2);
 lcd_ADRESS=lcd_get_adress(); 
 lcd_rchar(&byte);
 printf("Return Char %c an Adresse %d\n",byte,lcd_ADRESS);
 printf("\n\nDisplay wird gelöscht....(Enter)\n");
 test=getchar();
 lcd_instr(LCD_CLR);
 lcd_write_str("Hallo DISPLAY!!");
 lcd_instr(LCD_ADR+0x40);
 lcd_write_str("2. Zeile");
 lcd_instr(LCD_ADR+0);    
 lcd_read_str(15);
 printf("GetString %s\n",lcd_STRING);
 printf("deinit %d\n",deinit_iic()); 
 return 0;
}
