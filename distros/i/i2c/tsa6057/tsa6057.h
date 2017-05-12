/***********************************************************************/
/*  TSA6057 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 12.11.2000                                    */
/*  Dateiname          : tsa6057.h				       */
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

BS	1
*/

#define TSA6057_ADR	196		// Adresse default 196 , (198 )
#define TSA6057_AM	16		// AM 
#define TSA6057_FM	32		// FM
#define TSA6057_R01	0		// Raster 1 KHz
#define TSA6057_R10	64		// Raster 10 KHz
#define TSA6057_R25	128		// Raster 25 KHz
#define TSA6057_BS	4		// Bandswitch

typedef struct tsa6057 {
 int sadr;				// Sub-Adress = 0
 int raster;				// Raster 1 / 10  /25 KHz
 int db0;				// Teiler und ChargePump
 int db1;				// Teiler 
 int db2;				// Raster  /FM/AM / Teiler
 int db3;				// TestByte = 0
} tsa6057;

tsa6057 tsa; 				// tsa-Daten

int tsa6057_init(tsa6057 *sp,int Raster,int Mode); 	// Raster & Mode
int tsa6057_calc(tsa6057 *sp,long Freq);		// Berechnet die Teilerfaktoren in *sp , Rückgabe Teiler 
int tsa6057_send(tsa6057 *sp,int Adr_Off);		// Sendet die Daten an die PLL , Adress Offset 0 | 2


