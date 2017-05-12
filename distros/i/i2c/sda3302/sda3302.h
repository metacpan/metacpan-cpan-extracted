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
/*	      Funktionen PLL / Frequenzteiler 		               */
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
Bei diesem Tuner fehlt leider der HyperBand Bereich, so daß ein durchgaengiger Betrieb 
nicht Moeglich ist. 
Laut Datenblatt (UV1317) ergeben sich folgende Bereiche (Wird ueber P0-P2, geschaltet).

Bereiche:	P0=	Low  VHF	 48-122	MHz
		P1=	High VHF	122-295	MHz
		P2=	UHF		471-855	MHz

*/

#define SDA3302_ADR	192		// SDA3302 Adresse default 192 , (194, 196, 198 )
#define SDA3302_STEP	62500		// Abstimmschritt 62.5 KHz
#define SDA3302_ZF	37300000	// ZF 37,3 MHz , bzw. 0
#define SDA3302_P	8		// Fester Vorteiler 8
#define SDA3302_Q	4000000		// Ref. Quarz 4.00 MHz
#define SDA3302_QDF	512		// Interner Teiler f. Quarz Ref
#define SDA3302_PLL	206		// SDA arbeitet als PLL
#define SDA3302_DIV	238		// SDA arbeitet als Teiler
#define SDA3302_BS0B	 48500000	// Umschaltbereich P0 
#define SDA3302_BS1B	122000000	// Umschaltbereich P1
#define SDA3302_BS2B	471000000	// Umschaltbereich P2
#define SDA3302_BS0	1		// Umschaltbereich P0
#define SDA3302_BS1	2		// Umschaltbereich P1
#define SDA3302_BS2	4		// Umschaltbereich P2

typedef struct sda3302 {
 int div1;				// wird Berechnet n14-n8
 int div2;				// wird Berechnet n7 -n0
 int cnt1;				// 206 PLL / 238 Teiler Bit 5 = 1
 int cnt2;				// Bandswitch
} sda3302;

sda3302 sda; 				// sda-Daten

int sda3302_init(sda3302 *sp,int Mode); // Mode 206 PLL, 238 Teiler, -> Rückgabe Mode
int sda3302_calc(sda3302 *sp,long Freq);// Berechnet die Teilerfaktoren in *sp , Rückgabe Teiler 
int sda3302_send(sda3302 *sp,int Adr);	// Sendet die Daten an die PLL, Adr 0,2,4,6 

