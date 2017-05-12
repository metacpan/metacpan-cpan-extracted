/***********************************************************************/
/*  LCD Funktionen						       */	
/*  fuer i2c-Parallel-Interface 			               */
/*                                                                     */
/*  0.2              : 25.11.2000  unsigned char durch int ersetzt     */
/*  0.1 erstellt am  : 26.10.2000                                      */
/*  Dateiname          : lcd.c					       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 26.10.00 , Start  					               */
/*                                                                     */
/***********************************************************************/

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "lcd.h"
#include "../pcf8574/pcf8574.h"
#include "../src/i2c_fncs.h"

// aktuelle CursorAdresse , wird in lcd_busy gesetzt //
int static lcadr;

/* ext. Funktionen */

/* Initialisierung des Display's 4-BIT , 2 Zeilen */
int lcd_init(void)
{
 int ret;
 ret = iic_tx_pcf8574(8,PCF_ADRESS); // BL EIN RS/RW 0
 usleep(15000);
 ret=lcd_write_nibble(LCD_IR,0x03);
 usleep(5000);
 ret=lcd_write_nibble(LCD_IR,0x03);
 usleep(200);
 ret=lcd_write_nibble(LCD_IR,0x03);
 usleep(50);
 ret=lcd_write_nibble(LCD_IR,0x02);
 ret=lcd_instr(0x28); 		// 4 BIT-Mode , 2 Zeilen
 ret=lcd_instr(LCD_OFF);	// LCD_Off
 ret=lcd_instr(LCD_CLR);	// LCD_Clear
 ret=lcd_instr(0x02);		// Cursor an 1. Stelle
 ret=lcd_instr(0x06);		// Cursor Richtung +1 
 ret=lcd_instr(0x0E);		// Display an , Cursor klein , kein Blinken
 lcd_ADRESS=0; 			// Aktuelle Adresse = 0
 lcd_BACKLIGHT=1;		// Licht ein	
 lcadr=0;
 return ret;
}

/* Schreibt ein Char auf das Display */
int lcd_wchar(int data)
{
 int ret,temp;
 ret=0;
 if(!lcd_busy()) {
  temp = data >> 4;
  ret = lcd_write_nibble(LCD_DR,temp);
  temp = data & 0xf;
  ret = lcd_write_nibble(LCD_DR,temp);
 }
 return ret;
}

/* Liest ein Char vom Display */
int lcd_rchar(int *data,int adr)
{
 int ret;
 int data_l,data_h;
 ret=1;
 ret=lcd_instr(0x80+adr);		// Adresse setzen
 if(!lcd_busy()) {
  data_h = lcd_read_nibble(LCD_DR);
  data_l = lcd_read_nibble(LCD_DR);
  *data = (data_l >> 4) | data_h;
 }
 return ret;
}

/* Schreibt ein String auf das Display 		*/
/* Adresse muss vorher gesetzt sein, was nicht 	*/
/* in eine Zeile passt wird abgeschnitten.  	*/
int lcd_write_str(char *lstr)
{
 int ret,n,i;
 ret = 1;
 i = strlen(lstr);
 if (i>LCD_CHR) i = LCD_CHR-1;
 for (n=0;n<i;n++) lcd_wchar(lstr[n]);
 return ret;
}

/* Liest einen String in lcd_STRING ab Adresse adr , mit Anzahl len */
int lcd_read_str(int len,int adr)
{
 int ret,n,i,c;
 int ch;
 ret = 1;
 c =0;
 i = adr ; /* lcd_get_adress(); */
 // printf("getadr %d,len %d \n",i,len);
 for (n=i;n<(i+len);n++) {
  lcd_rchar(&ch,(i+c));
  lcd_STRING[c] = ch;
  c++;
  lcd_instr(0x80+adr+c);
 } 
  lcd_STRING[c] = '\0';
 return ret;
}

/* Schaltet beleuchtung ein / aus */
int lcd_backlight(int bl_cmd) 	  // 0 Licht aus, 1 Licht an 
{
  int ret;
  lcd_BACKLIGHT=bl_cmd; // Variable setzen
  if (lcd_BACKLIGHT) 
   ret = iic_tx_pcf8574(LCD_BL,PCF_ADRESS);
  else 
   ret=iic_tx_pcf8574(0,PCF_ADRESS);
 return(ret);
}

/* Schickt ein Commando zum Display */
int lcd_instr(int data)
{
 int ret,temp;
 ret = 0;
 if(!lcd_busy()) {
   temp = data >> 4;
   ret  = lcd_write_nibble(LCD_IR,temp);
   temp = data & 0xf;
   ret  = lcd_write_nibble(LCD_IR,temp);
 } 
 return(ret);
}


/* Liest die aktuelle Cursor Adresse */
int lcd_get_adress()
{
 int ret;
 ret = -1;
 if(!lcd_busy()) {
   ret = lcadr;
 }
 return(ret);
}

/* interne Funktionen */

/* Schreibt ein Nibble auf das Display */
int lcd_write_nibble(int regdir,int data)
{
  int ret;
  int temp;
 
  temp = data * 16;
  if (lcd_BACKLIGHT==1) temp=temp + LCD_BL;
  temp = temp & 0xfe; 		// Enable 0
  if (regdir == LCD_IR) 
  {
   temp = temp & 0xfb;	 	//  P2 auf LOW instruction
  } else temp = temp | 0x4; 	//  P2 High, DatenRegister
    
  temp = temp & 0xfc;		//  P1 auf 0, schreiben
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
  temp =temp | 0x01;
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
  temp =temp & 0xfe;
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
 return(ret);
} 

/* liest ein Nibble aus dem Display */
int lcd_read_nibble(int regdir)
{
  int temp,ibyte;
  int ret;
  ret   = 0;
  ibyte = 0;
  temp  = 0xf0;
  
  if (lcd_BACKLIGHT) temp=temp + LCD_BL;
  temp = temp & 0xfe; 	// Enable auf LOW
  if (regdir == LCD_IR) {
   temp = temp & 0xfb;
  }else temp = temp | 0x04 ;
  temp = temp | 0x02; 
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
  temp=temp | 0x01;
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
  ret=iic_rx_pcf8574(&ibyte,PCF_ADRESS);
  temp=temp & 0xfe;  // Enable wieder auf LOW
  ret=iic_tx_pcf8574(temp,PCF_ADRESS);
  ibyte = ibyte & 0xf0;
  return (ibyte);  
}


/* Testet ob Display Busy ist , 1 = Busy , 0 OK*/
int lcd_busy(void)
{
  int busy, time_cnt, time_out,data_1,data_2;
  time_out=10; 	// 10x Testen
  time_cnt=0;
  busy=1;	// True			

  do {
    time_cnt++;   
    data_1=lcd_read_nibble(LCD_IR);
    usleep(1);
    data_2=lcd_read_nibble(LCD_IR);
   if (data_1 & 0x10) { 
     busy=1;
     printf("TimeOut busy\n");
    } else 
    {
     busy =0;
     lcadr = data_1 + (data_2 >> 4);
     break;
    } 
  } while ((time_cnt < time_out));
  return(busy);
}

