/***********************************************************************/
/*  PCF8574 Funktionen						       */	
/*  fuer i2c-Interface 	 				               */
/*  V0.1  erstellt am  : 28.10.2000                                    */
/*  Dateiname          : pcf8574.h				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 28.10.00 , Start  					               */
/*                                                                     */
/***********************************************************************/

/*
Portdaten der verwendeten Schaltung 

P0	Enable E
P1	R/_W 	1 Lesen / 0 Schreiben
P2	D/_I	1 Daten	/ 0 Instruction
P3	BL	1 Licht an / 0 Licht aus
P4-P7	Daten

*/
#define PCF8574_TX	112		// PCF8574 Adresse default
#define PCF8574_RX	113

unsigned char PCF_ADRESS;		// Falls mehrere PCF'S vorhanden sind default 0

unsigned char iic_tx_pcf8574(unsigned char data,unsigned char adr);
unsigned char iic_rx_pcf8574(unsigned char *data,unsigned char adr);

