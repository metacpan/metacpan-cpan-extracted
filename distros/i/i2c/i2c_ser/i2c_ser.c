/*
#  Seriell-Interface  I2C				            
#  V0.1  erstellt am  	: Linux Version 04.11.2000                                  
#  Dateiname          	: i2c_ser.c				    
#  Änderungen 		: I. Gerlach / DH1AAD 
#                                     				    
#  Aenderungen 		unsigned char durch int ersetzt. 
#			Voll Funtionskompatibel zur i2c_par.c 
#			  	
#  
#  MSR xFE	: _DCD	_RI	_DSR	_CTS	DDCD	TE	DDSR	DCTS 
#  BIT 		: 7 	6 	5 	4 	3 	2 	1	0 
#
#  MCR xFC	: RES	RES	RES	Loop	Out2	Out1	_RTS	_DTR
#  BIT 		: 7 	6 	5 	4 	3 	2 	1	0 
*/ 


 

#include <stdio.h>  
#include <unistd.h> 
#include <sys/io.h> /* for outb() and inb() */
#include "i2c_ser.h"


/* Macro, linux hat andere Reihenfolge, outb(Byte,Port) , 26.10.00*/
#define outp(a,b) outb(b,a);
 
static int port_delay; 		// Wartezeit fuer Portzugriffe 
static int datamem; 	 	// Allgemeine Variable
static int portadress; 		// 3f8,2f8
static int ctrlstat; 		// Nimmt den ControlPort Status vor initalisierung auf 

 
 /********************* Funktionen ***************************************/ 

/* ******************************************************************************* */
 
int init_iic (int portnr) 
// IIC 2 Initialisieren 
// Eingabe  : 0 : an COM 1..2 suchen 
//            1 : COM 1 , 0x3F8
//            2 : COM 2 , 0x2F8
// Rückgabe : Basisadresse des COM-Portes 
//            0 : IIC 2 nicht gefunden 
{ 
  char ok; 
  int test; 
  int ports[2]={0x2f8,0x3f8};

  ok  = 0; 
  test = 0; 
  portadress = 0; 
   
  if (portnr==0) // automatisch suchen
  { 
    for(test=0;test<2;test++)
    {
      portadress=ports[test];
      if ((ioperm(portadress,7,1) == 0) && iic_ok())
      {
       ok = 1;
       break;
      } else  ioperm(portadress,7,0);
    } 
  }  
  else  // Portvorgabe 
  { 
    switch(portnr) 
    { 
     case 1:  
	   portadress = 0x3f8; 
	   break; 
     case 2:  
	   portadress = 0x2f8; 
	   break; 
     default:
           portadress =	 0x3f8;
    } 
    // Linux spec.
    if (ioperm(portadress,7,1)) 
    {
     printf("Sorry, dieses Programm muss als root ausgefuehrt werden.\n");
     exit(1);
    }
    ctrlstat = inb(portadress+MCR);
    if (portadress > 0) 
    { 
      if (iic_ok()) ok = 1; 
    } 
  }  // else
  if (!ok) portadress = 0;  
 return (portadress);
} 
  
// ****************************************************************************************** 
 
int deinit_iic (void) 
// IIC-Interface deinitialisieren 
{ 
 int status = 0; 
  outp (portadress+MCR, ctrlstat); // Alter Wert 7,12, 8 
  status=ioperm(portadress,7,0);
 return (status); 
} 

int set_port_delay (int delay) 
// Wartezeit für den Zugriff den Port setzen 
{ 
 port_delay = delay; 
 return (delay); 
} 


int iic_start(void)
// Start Bit senden 
{
  int status =0; 
  sda_high();            	// Datenleitung auf High 
  scl_high();            	// Taktleitung auf High 
  while (!read_scl());   	// warten bis Takt High 
  wait_port();          	// warten 
  sda_low();             	// Datenleitung auf Low 
  wait_port();          	// warten 
  scl_low();             	// Taktleitung auf Low 
 return status; 
} 

int iic_stop(void) 
/* Stop bit senden, indem waehrend der Clock High Periode ein */ 
/* Zustandswechsel von Low nach High initiiert wird.          */ 
{ 
  int status =0; 
  sda_low();          		// Datenleitung auf Low 
  scl_high();         		// Taktleitung auf High 
  while (!read_scl()); 
  wait_port();       		// warten 
  sda_high();   		// Datenleitung auf High 
  return status; 
} 

int iic_send_byte (int byte) 
/* Es wird ein Byte ueber den IIC Bus gesendet                    */ 
/* und anschliessend ein ACK vom SLAVE erwartet                   */ 
/* Die Routine kehrt 1 zurueck, wenn ein ACK vom SLAVE kam        */ 
{ 
  int maske; 
  int flag; 
 
  maske = 0x80;              // Bit maske 
  //outp (portadress+CONTROL_PORT, 1); 
  //outp (portadress+CONTROL_PORT, 7); // War 5, 6.2.2000 
  do 
   { 
    if (byte & maske)           // selectiertes Bit gesetzt ? 
      sda_high();            // Ja -> DATENLEITUNG auf High 
    else 
      sda_low();             // Nein -> Datenleitung auf Low 
    scl_high();              // Clock leitung auf High 
    while (!read_scl());     // warten bis SCL auf High 
    maske /= 2;              // Bit maske nach rechts verschieben 
    scl_low();               // Clockleitung auf Low 
   } 
  while (maske);             // das ganze 8 mal wiederholen 
  wait_port(); 
  sda_high();                // Daten- und Clockleitung auf High 
  scl_high(); 
  while (!read_scl());       // warten bis SCL auf High 
  if (read_sda()) flag = 0; else flag = 1; // jetzt mueste der SLAVE die Datenleitung auf LOW ziehen 
  scl_low();                 // Clock auf Low 
  return(flag);              // wurde die Datenleitung auf Low gezogen, so kehrt die 
			     // Routine mit 1 zurueck. 
} 
  
int iic_read_byte(int ack) 
/* Es wird ein Byte vom IIc Bus gelesen                            */ 
/* Ist das "ack" ungleich 0, so wird abschliesend ein ACK gesendet */ 
/* zurueckgegeben wird das empfangene Byte                         */ 
{ 
  int b, q; 
 
  sda_high();                   // Datenleitung auf High 
  b = 0;                        // byte loeschen 
  for (q = 0; q < 8; q++) 
   { 
    scl_high();                 // Clockleitung auf High 
    while (!read_scl());        // warten bis SCL auf High 
    b <<= 1;                    // datenbyte nach links schieben 
    if (read_sda())             // Zustand der datenleitung ins Byte kopieren 
      b |= 1; 
    scl_low();                  // Clock auf Low 
   } 
  if (ack) sda_low(); else sda_high(); 
  scl_high();                   // Clockleitung auf High 
  while (!read_scl()); 
  wait_port(); 
  scl_low();                    // Clockleitung auf Low 
  sda_high(); 
  return(b); 
} 
  

// Interne Funktionen 

int iic_ok (void) 
// prüft, ob das IIC-Interface am angegebenen Port angeschlossen ist 
{ 
  int ret = 0; 
				// SCL prüfen 
  outp(portadress+MCR,0); 	// Bit 1 = RTS (MCR 1) auf high setzen d.h. _CTS Bit 4 
  wait_port();
  ret = inb (portadress+MSR); 	// wird 0 (MSR 4) wenn IF angeschlossen ist.

  if ((ret & 16)==0) 		// OK , Bit 4 nicht gesetzt
  {
				// SDA prüfen 
    outp(portadress+MCR,1); 	// Bit 0 = DTR (MCR 0) auf high setzen d.h. _DSR Bit 5 und _DCD Bit 7 wird 0
    wait_port();
    ret = inb (portadress+MSR); 
    if ((ret & 160) == 0 ) 	// OK , Bit 5 und 7 MSR  = 0
    {
     outp(portadress+MCR,0); 	// Bit 0 = DTR (MCR 0) auf low setzen d.h. _DSR Bit 5 und _DCD Bit 7 wird 1
     wait_port();
     ret = (inb(portadress+MSR) && 160); 
    }
  } else ret = 0;
 return ret;
}


int wait_port(void) 
// Kleine Pause einlegen
{ 
  unsigned char b; 
  int status =0; 
   b = port_delay; 
  while (b--) inb(portadress); 
 return status; 
} 

int sda_high (void) 
// SDA Leitung auf low MCR0 / DTR 
{ 
  int status =0; 
  datamem=inb(portadress+MCR); 
  datamem |= 1; // DTR setzen --> SDA high 
  outp (portadress+MCR, datamem); 
  wait_port(); 
 return status; 
} 
 
int sda_low (void) 
// SDA Leitung auf low 
{ 
  int status =0; 
  datamem=inb(portadress+MCR); 
  datamem &= 254; // DTR loeschen --> SDA low
  outp (portadress+MCR, datamem); 
  wait_port(); 
 return status; 
} 

int read_sda (void) 
// auslesen der SDA-Leitung  DSR / MSR 5
// 1 : high   0 : low
{ 
  if (inb(portadress+MSR) & 32) return (1); 
  else return (0); 
} 

int scl_high(void) 
// SCL Leitung auf high MCR1 / RTS 
{ 
  int status =0; 
  datamem=inb(portadress+MCR); 
  datamem |= 2; // RTS setzen --> SCL high 
  outp (portadress+MCR, datamem); 
  wait_port(); 
 return status; 
} 

int scl_low(void) 
// SCL Leitung auf low MCR1 / RTS 
{ 
  int status =0; 
  datamem=inb(portadress+MCR); 
  datamem &=253; // RTS setzen --> SCL low 
  outp (portadress+MCR, datamem); 
  wait_port(); 
 return status; 
} 

int read_scl (void) 
// auslesen der SCL-Leitung CTS / MSR 4
// 1 : high   0 : low
{ 
  if (inb(portadress+MSR) & 16) return (1); 
  else return (0); 
} 


/* Dummy Funktionen , nur aus kompatibilitaets Gruenden zu i2c_lpt.h */
/* Alle Funktionen geben 0 zurueck. */

 int set_strobe (int status)	{ return(0); }
 int byte_out (int status)	{ return(0); } 
 int byte_in (int status)	{ return(0); } 
 int get_status(int status) 	{ return(0); } 
 int io_disable (void) 		{ return(0); } 
 int io_enable (void)		{ return(0); } 
 int inp32(int Port) 		{ return(0); } 
 int out32(int Port, int byte)	{ return(0); } 
 int read_int(void)		{ return(0); } 

