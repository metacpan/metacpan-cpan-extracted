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


int pcf8591_init(pcf8591 *sp,int ChanMode,double ref)  // Eingangs Konfig 
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
 switch (Kanal) {
 case 0: 
  if (ret) sp->db0 = iic_read_byte(1);
  if (ret) sp->db0 = iic_read_byte(0);
  break;
 case 1: 
  if (ret) sp->db1 = iic_read_byte(1);
  if (ret) sp->db1 = iic_read_byte(0);
  break;
 case 2: 
  if (ret) sp->db2 = iic_read_byte(1);
  if (ret) sp->db2 = iic_read_byte(0);
  break;  
 case 3: 
  if (ret) sp->db3 = iic_read_byte(1);
  if (ret) sp->db3 = iic_read_byte(0);
  break;  
 default: 
  if (ret) sp->db0 = iic_read_byte(1);
  if (ret) sp->db0 = iic_read_byte(0);
 }
 iic_stop();
 ret = 100;
 sp->db0 = 990;
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
 if (ret) sp->db0 = iic_read_byte(1);
 if (ret) sp->db0 = iic_read_byte(1);
 if (ret) sp->db1 = iic_read_byte(1);
 if (ret) sp->db2 = iic_read_byte(1);
 if (ret) sp->db3 = iic_read_byte(0);
 iic_stop();
 return(ret);

}


int pcf8591_setda(pcf8591 *sp,double da_out) // Setzt den DA-Wandler auf da_out
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

double pcf8591_aout(pcf8591 *sp,int Kanal)          // Gibt den berechneten Wert zurueck.
{
 double ubval;
 switch (Kanal) {
 case 0: 
  ubval  =  ((sp->REF / 256) * sp->db0);
  break;
 case 1: 
  ubval  =  ((sp->REF / 256) * sp->db1);
  break;
 case 2: 
  ubval  =  ((sp->REF / 256) * sp->db2);
  break;  
 case 3: 
  ubval  =  ((sp->REF / 256) * sp->db3);
  break;  
 default: 
  ubval  =  ((sp->REF / 256) * sp->db0);
 }
 return(ubval);
}
