/***********************************************************************/
/*  PCF8574 Funktionen						       */	
/*  fuer i2c-Interface 			               */
/*                                                                     */
/*  0.2                                                                */
/*  0.1 erstellt am  : 28.10.2000                                      */
/*  Dateiname        : pcf8574.c					       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 28.10.00 , Start  					               */
/*                                                                     */
/***********************************************************************/

#include <stdio.h>
#include "i2c_ser.h"
#include "pcf8574.h"



/* Funktionen */

unsigned char iic_tx_pcf8574(unsigned char data,unsigned char adr)
{
 unsigned char ret;
 iic_start();
 ret = iic_send_byte(PCF8574_TX + (adr*2));
 if (ret)
 {
   ret = iic_send_byte(data);
   if (ret) iic_stop();
 }  
 return ret;
}

unsigned char iic_rx_pcf8574(unsigned char *data,unsigned char adr)
{
 unsigned char ret;
 iic_start();
 ret = iic_send_byte(PCF8574_RX + (adr*2));
 if (ret)
 {
   *data = iic_read_byte(0);
 } else *data = 0;
 iic_stop(); 
 return ret;
}


