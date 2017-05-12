/***********************************************************************/
/*  PCF8591 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 12.11.2000                                    */
/*  Dateiname          : pcf8591.h				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 12.11.00 , Start 						       */
/*                                                                     */
/***********************************************************************/

/*


Ansteuereung PCF8591
		128	64	32	16	8	4	2	1	
--------------------------------------------------------------------------
Adresse:	1	0	0	1	A2	A1	A0	R/_W  	: 144 Write / 145 Read
ControlByte	0	A	I1 	I2	0	AI	Ch1	Ch2

A	Analog Output Enable
I1/I2	00	4x Eingang
	01	3 dif. Eing.
	10	2x Single Ended / 2x Diff. Eingang
	11	2x diff.


*/

#define PCF8591_ADR	144		// Adresse default 144 
#define PCF8591_RX	145		// Adresse default 145 / Lesen
#define PCF8591_C4S	  0		// 4 Eing.
#define PCF8591_C3D	 16 		// 3 Dif. Eing.	
#define PCF8591_C2S	 32 		// 2 SE / 2 Dif. Eing.	
#define PCF8591_C2D	 48 		// 2 Dif. Eing.	
#define PCF8591_AOE	 64 		// Analog Output enable
	
typedef struct pcf8591 {
 int chan_mode;				// Def. der Eingaenge sh. PCF8591_Cxx
 float REF;				// Referenz Spannung
 int da_val;				// Wert f. DA-Wandler 
 int data[3];				// Data
} pcf8591;

pcf8591 adda; 				// pcf-Daten

int pcf8591_init(pcf8591 *sp,int ChanMode,float ref);   // Eingangs Konfig 
int pcf8591_readchan(pcf8591 *sp,int Kanal);		// Liest einen Kanal 
int pcf8591_read4chan(pcf8591 *sp);	    		// Liest alle Kanaele
int pcf8591_setda(pcf8591 *sp, float da_out);	    	// Setzt den DA-Wandler auf 
float pcf8591_aout(pcf8591 *sp,int Kanal);	    	// Gibt den berechneten Wert zurueck.

