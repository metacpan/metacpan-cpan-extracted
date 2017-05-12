/***********************************************************************/
/*  PCF8591 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 12.11.2000                                    */
/*  Dateiname          : pcf8591.c				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 12.11.00 , Start 						       */
/*                                                                     */
/***********************************************************************/

#include "../src/i2c_fncs.h"
#include "pcf8591.h"

int pcf8591_init(pcf8591 *sp,int ChanMode,float ref)  // Eingangs Konfig 
{
 memset(sp,0,sizeof(pcf8591));
 sp->chan_mode = ChanMode;
 sp->REF       = ref;
 sp->da_val    = 0;
 return(0);
}

int pcf8591_readchan(pcf8591 *sp,int Kanal) // Liest einen Kanal 
{
 int temp = 0;
 int ret;
 
 temp  = sp->chan_mode;
 temp |= PCF8591_AOE; 		// AOE auf 1 
 temp |= 4;			// AutoIncrement
 temp |= Kanal;			// Kanal Setzen 

 iic_start();
 ret = iic_send_byte(PCF8591_ADR);
 if (ret) ret = iic_send_byte(temp);
 iic_stop();
 if (ret) iic_start();
 if (ret) ret = iic_send_byte(PCF8591_RX);
 if (ret) sp->data[Kanal] = iic_read_byte(1);
 if (ret) sp->data[Kanal] = iic_read_byte(0);
 iic_stop();
 return(ret);
}

int pcf8591_read4chan(pcf8591 *sp)	    // Liest alle Kanaele
{
 int temp = 0;
 int ret;
 
 temp  = sp->chan_mode;
 temp |= PCF8591_AOE; 		// AOE auf 1 
 temp |= 4;			// AutoIncrement

 iic_start();
 ret = iic_send_byte(PCF8591_ADR);
 if (ret) ret = iic_send_byte(temp);
 iic_stop();
 if (ret) iic_start();
 ret = iic_send_byte(PCF8591_RX);
 if (ret) sp->data[0] = iic_read_byte(1);
 if (ret) sp->data[0] = iic_read_byte(1);
 if (ret) sp->data[1] = iic_read_byte(1);
 if (ret) sp->data[2] = iic_read_byte(1);
 if (ret) sp->data[3] = iic_read_byte(0);
 iic_stop();
 return(ret);

}


int pcf8591_setda(pcf8591 *sp,float da_out) // Setzt den DA-Wandler auf da_out
{
 int temp = 0;
 int ret  = 0;
 sp->da_val = (da_out * 256) / sp->REF;
 iic_start();
 ret = iic_send_byte(PCF8591_ADR);
 temp |= PCF8591_AOE; 		// AOE auf 1 
 if (ret) ret = iic_send_byte(temp);
 if (ret) ret = iic_send_byte(sp->da_val);
 iic_stop();
 return(ret);
}

float pcf8591_aout(pcf8591 *sp,int Kanal)          // Gibt den berechneten Wert zurueck.
{
  float ubval;
  ubval  =  ((sp->REF / 256) * sp->data[Kanal]);
 return(ubval);
}
