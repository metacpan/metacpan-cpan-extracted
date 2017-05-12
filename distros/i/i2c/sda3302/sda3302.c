/***********************************************************************/
/*  SDA3302 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 05.11.2000                                    */
/*  Dateiname          : sda3302.h				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 05.11.00 , Start Test mit sep. PLL und Tuner UV917		       */
/*	      Funktionen PLL / Frequenzteiler		               */
/*                                                                     */
/***********************************************************************/

/*

Der SDA3302 arbeitet zwischen 16-1300MHz, Schrittweite ist 62,5 KHz. 
Der feste Vorteiler P ist 8. 
Der Variable Vorteiler N hat einen Bereich von 256-32767.
Als Frequenzteiler liegt der kleinste Bereich bei nmin = P * Nmin = 8 * 256 = 2048 
Die Quarzfrequenz liegt bei 4.00 MHz, der Teiler Q=512.

Ansteuereung SDA3302 
		128	64	32	16	8	4	2	1	
--------------------------------------------------------------------------
Adresse:	1	1	0	0	0	A1	A0	0  : 192	
Teiler1:	0	N14	N13	N12	N11	N10	N9	N8 :
Teiler2:	N7	N6	N5	N4	N3	N2	N1	N0
Control1:	1	1	T1	T0	1	1	1	0  : 206 (PLL/238 Teiler)
Control2:	P7	P6	P5	P4	X	P2	P1	P0

Betrieb:	T0=T1=	0 	PLL
		T1=	1	Frequenzteiler


Zu Testzwecken wurde hier die Siemens-Applikation aus dem Datenblatt (Seite 23) aufgebaut.
Als Tuner diente ein alter Phillips UV917 (UV1317) ohne eigene PLL.
Bei diesem Tuner fehlt leider der HyperBand Bereich, so daﬂ ein durchgaengiger Betrieb 
nicht Moeglich ist. 
Laut Datenblatt (UV1317) ergeben sich folgende Bereiche (Wird ueber P0-P2, geschaltet).

Bereiche:	P0=	Low  VHF	 48-122	MHz
		P1=	High VHF	122-295	MHz
		P2=	UHF		471-855	MHz

*/

#include <stdlib.h>
#include "../src/i2c_fncs.h"
#include "sda3302.h"


int sda3302_init(sda3302 *sp,int Mode)	// Mode 206 PLL, 238 Teiler, R¸ckgabe Mode
{
  memset(sp,0,sizeof(sda3302));		// Strucktur auf 0 setzen
  sp->cnt1=Mode;			// Mode PLL  / Teiler Charge Pump 0!!!
  sp->cnt2=2;	
 return(Mode);
}

int sda3302_calc(sda3302 *sp,long Freq)// Berechnet die Teilerfaktoren in *sp , R¸ckgabe Teiler 
{
 int n;
 int temp; 
  n =  ((SDA3302_ZF+Freq)*SDA3302_QDF) / (SDA3302_P * SDA3302_Q); // Berechnet wird ein ganzzahliger Teiler.
  temp = n & 32512;			// Oberes Nibble 
  sp->div2  = n - (n & 32512);		// Oberes Nibble holen n0-n7
  sp->div1  = temp >> 8;		// n14-n8
  sp->cnt2=SDA3302_BS0; 		// Vorgabe BS0
  if(Freq>SDA3302_BS1B) sp->cnt2=SDA3302_BS1;
  if(Freq>SDA3302_BS2B) sp->cnt2=SDA3302_BS2;
  return(n);				// R¸ckgabe : Teiler ,die tats. Freq. errechnet sich aus 
}					// Fres = ((n*SDA3302_STEP) - SDA3302_ZF)

int sda3302_send(sda3302 *sp,int Adr)   // Sendet die Daten an die PLL
{
 int ret;
 iic_start();
 ret = iic_send_byte(SDA3302_ADR+Adr);
 ret = iic_send_byte(sp->div1);
 ret = iic_send_byte(sp->div2);
 ret = iic_send_byte(sp->cnt1); 
 ret = iic_send_byte(sp->cnt2);
 iic_stop();
 return(ret);
}


