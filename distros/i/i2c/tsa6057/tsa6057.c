/***********************************************************************/
/*  TSA6057 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 12.11.2000                                    */
/*  Dateiname          : tsa6057.c				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 12.11.00 , Start 						       */
/*                                                                     */
/***********************************************************************/

/*


Ansteuereung TSA6057
		128	64	32	16	8	4	2	1	
--------------------------------------------------------------------------
Adresse:	1	1	0	0	0	1	A0	0  	: 196 / 198
SubAdress:	0	0	0	0	0	0	0	0  	: 0 
DB0:		S6	S5	S4	S3	S2	S1	S0	CP
DB1:		S14	S13	S12	S11	S10	S9	S8	S7
DB2:		Ref1	Ref2	FM-_AM	_FM-AM	x	BS	S16	S15	: 
DB3:		T1	T2	T3	X	X	X	X	X	: 0

REF1/2	:	Raster 
0	0	1  KHz 	: 0
0	1	10 KHz	: 64
1	0	25 KHz	: 128

Mode:	16	AM
	32	FM
*/


#include "../src/i2c_fncs.h"
#include "tsa6057.h"


int tsa6057_init(tsa6057 *sp,int Mode,int Raster)	// Mode 0 PLL, 1 Teiler, Rückgabe Mode
{
  memset(sp,0,sizeof(tsa6057));		// Strucktur auf 0 setzen
  sp->sadr=0;				
  sp->db2=Raster+Mode+TSA6057_BS;	// Raster / Mode / BS on
  switch(Raster)
  {
    case 0: 	sp->raster = 1000;
    		break;
    case 64: 	sp->raster = 10000;
    		break;
    case 128: 	sp->raster = 25000;
    		break;
    default:	sp->raster = 25000;		
   }  		
 return(Mode);
}

int tsa6057_calc(tsa6057 *sp,long Freq)// Berechnet die Teilerfaktoren in *sp , Rückgabe Teiler 
{
 int n;
 // int temp; 
  n = (Freq / sp->raster); // Berechnet wird ein ganzzahliger Teiler.
  sp->db0 = ((n & 127) << 1)+1;			// 1. 6 Bits 
  sp->db1 = (n & 32640) >> 7;			// Oberes Nibble holen n0-n7
  sp->db2 = sp->db2 +((n & 98304) >> 15);	// n14-n8
 return(n);				// Rückgabe : Teiler ,die tats. Freq. errechnet sich aus 
}					// Fres = ((n*Raster)

int tsa6057_send(tsa6057 *sp,int Adr_Off) 	        // Sendet die Daten an die PLL
{
 int ret;
 iic_start();
 ret = iic_send_byte(TSA6057_ADR+Adr_Off);
 ret = iic_send_byte(sp->sadr);
 ret = iic_send_byte(sp->db0);
 ret = iic_send_byte(sp->db1);
 ret = iic_send_byte(sp->db2); 
 ret = iic_send_byte(sp->db3);
 iic_stop();
 return(ret);
}

