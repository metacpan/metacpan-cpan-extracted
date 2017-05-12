/*
#  Parallel-Interface  I2C				            
#  V0.1  erstellt am  	: Linux Version 26.10.2000                                  
#  Dateiname          	: i2c_lpt.c				    
#  Änderungen 		: I. Gerlach / DH1AAD WinVersion 
#                                     				    
#  Aenderungen : 
#
# 25.11.00 	unsigned char durch int ersetzt.
# 28.10.00  	automatische Suche nach Interface implementiert. iic_ok / iic_init.
# 26.10.00  	Basiert auf i2c_dll.c WindowsVersion  
# 2/2000 	Erweiterung auf div. Routinen zum Steuern des Paralellports PS/2 & EPP 
# 98/99  	Erweiterung auf div. Routinen zum Steuern des Paralellports (nur SPP) 
# 2.2 98 	Anpassung an Visual C++ 4.2 für DLL WIN95 (Original von ELV /96)
# 
# 
*/ 


/******************************************************************/
/* ALLGEMEINE IIC-Routinen:                                       */
/* iic_start(), iic_sende_byte(), iic_lese_byte() und iic_stop(). */
/******************************************************************/



#include <stdio.h>  
#include <unistd.h> 
#include <sys/io.h> /* for outb() and inb() */

#include "i2c_lpt.h"


/* Macro, linux hat andere Reihenfolge, outb(Byte,Port) , 26.10.00*/
#define outp(a,b) outb(b,a);

static int port_delay;
static int datamem;
static int portadress;
static int ctrlstat; 		// Nimmt den ControlPort Status vor initalisierung auf


/********************* Funktionen ***************************************/



// Win 95 & 98 / Linux

int wait_port(void)
{
  int b;
  int status =0;
  b = port_delay;
  while (b--) inb(portadress);
 return status;
}

int set_strobe (int status)
{
 outp (portadress+CONTROL_PORT, status+2);
 return status;
}

int    get_status(int status)
{
 status = inb (portadress+STATUS_PORT);
 return status;
}

int inp32(int Port)
{
  return inb (Port);
}

int out32(int Port,int byte)
{
 outp (Port, byte);
 return byte;
}

int io_disable (void)
{
 outp (portadress+CONTROL_PORT,2); 
 return 1;
}

int io_enable (void)
{
 outp (portadress+CONTROL_PORT, 6);
 return 1;
}


int byte_out (int status)
{
 outp (portadress+CONTROL_PORT, 7); // C0,C2,C4 auf 1, 1-DIR, 2-Busy,4-G an 74LS245
 outp (portadress, status);
 return status;
}

int byte_in (int status)
{
 outp (portadress+CONTROL_PORT, 36); // 
 //wait_port();
 wait_port();
 outp (portadress+CONTROL_PORT, 38); // 
 //wait_port();
 wait_port();
 status = inb(portadress);
 //wait_port();
 wait_port();
 outp (portadress+CONTROL_PORT, 36); // 
 //wait_port();
 wait_port();
 outp (portadress+CONTROL_PORT, 2); // 
 return status;
}


int sda_high (void)
// SDA Leitung auf High
{
  int status =0;
  datamem &= 253; // D1 löschen --> SDA high
  outp (portadress, datamem);
  wait_port();
 return status;
}


int sda_low (void)
// SDA Leitung auf Low
{
  int status =0;
  datamem |= 2;
  outp(portadress, datamem);
  wait_port();
 return status;
}

int scl_high (void)
// SCL Leitung auf High
{
 int status =0;
  datamem &= 254;
  outp (portadress, datamem);
  wait_port();
 return status;
}

int scl_low (void)
// SCL Leitung auf Low
{
 int status =0;
  datamem |= 1;
  outp (portadress, datamem);
  wait_port();
 return status;
}

int read_sda (void)
// auslesen der SDA-Leitung
// 0 : Low   1 : High
{
  if (inb(portadress+STATUS_PORT) & 64) return (0);
  else return (1);
}

int read_scl (void)
// auslesen der SCL-Leitung
// 0 : Low   1 : High
{
  if (inb(portadress+STATUS_PORT) & 8) return (0);
  else return (1);
}

int read_int (void)
// Prüft, ob die INT-Leitung aktiviert ist
// 0 : kein Interrupt   1 : Interrupt aktiv (Signal auf LOW)
{
  if (inb(portadress+STATUS_PORT) & 32) return (1);
  else return (0);
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
  outp (portadress+CONTROL_PORT, 7); // War 5, 6.2.2000
  do
   {
    if (byte & maske)        // selectiertes Bit gesetzt ?
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

int iic_start(void)
/* Start bit senden, indem waehrend der Clock High Periode ein */
/* Zustandswechsel von High nach Low initiiert wird.           */
{
 int status =0;
  sda_high();            // Datenleitung auf High
  scl_high();            // Taktleitung auf High
  while (!read_scl());   // warten bis Takt High
  wait_port();          // warten
  sda_low();             // Datenleitung auf Low
  wait_port();          // warten
  scl_low();             // Taktleitung auf Low
  return status;
}

int iic_stop(void)
/* Stop bit senden, indem waehrend der Clock High Periode ein */
/* Zustandswechsel von Low nach High initiiert wird.          */
{
  int status =0;
  sda_low();          // Datenleitung auf Low
  scl_high();         // Taktleitung auf High
  while (!read_scl());
  wait_port();       // warten
  sda_high();   // Datenleitung auf High
  return status;
}

int iic_ok (void)
// prüft, ob das IIC-Interface am angegebenen Port angeschlossen ist
{
  int ret; 
  ret = 1;
  // nAck (Pin 10) muss High fuehren
  outp(portadress+CONTROL_PORT,2 ); // /INIT auf Low Disable 8 BIT IO alter Wert 4 neu 2
  ret = inb (portadress+STATUS_PORT);
  if (inb (portadress+STATUS_PORT) & 64) ret = 0;  // alter Wert 128, IF angeschlossen 6 / nicht 126
  if (ret)
  {
    outp (portadress+CONTROL_PORT ,10); // /SLCT auf High setzen , neu 10
    wait_port();
    wait_port();
    if (!(inb (portadress+STATUS_PORT) & 16)) ret = 0; // SLCT muss High-Pegel führen,
    if (ret)
    {
      outp (portadress+CONTROL_PORT, 2); // SLCT ausschalten 
      wait_port();
      wait_port();
      if (inb (portadress+STATUS_PORT) & 16) ret=0; 	// SLCT muss Low-Pegel führen, 
      //{						// ist jetzt noch high, Fehler, kein IF
      // ret = 0;
      // outp (portadress+CONTROL_PORT, 10);// /SLCT auf Low alter Wert 12 , neu 8
      //}
    }
  }
  outp (portadress, 0);
  datamem = 0;
  // Neu 2.5.98 
 return (ret);
}

/* ******************************************************************************* */

int init_iic (int portnr)
// IIC 2 Initialisieren
// Eingabe  : 0 : an LPT 1..3 suchen
//            1 : LPT 1 , 0x378
//            2 : LPT 2	, 0x278
//            3 : LPT 3	, 0x3bc
// Rückgabe : Basisadresse des LPT-Portes
//            0 : IIC 2 nicht gefunden
{
  char ok;
  int test;
  int ports[3]={0x278,0x3bc,0x378};

  ok  = 0;
  test = 0;
  portadress = 0;
  
  if (portnr==0) // automatisch suchen.28.10.00
  {
    for(test=0;test<3;test++)
    {
      portadress=ports[test];
      if ((ioperm(portadress,3,1) == 0) && iic_ok())
      {
       //printf("Portadresse %d \n",portadress);
       ok = 1;
       break;
      } else  ioperm(portadress,3,0);
    } 
  } 
  else  // Portvorgabe
  {
    switch(portnr)
    {
     case 1: 
	   portadress = 0x378;
	   break;
     case 2: 
	   portadress = 0x278;
	   break;
     case 3: 
	   portadress = 0x3bc;
	   break;
     default:
           portadress =	0x378;
    }
    // Linux spec.
    if (ioperm(portadress,3,1)) 
    {
     printf("Sorry, you were not able to gain access to the ports\n");
     printf("You must be root to run this program\n");
     exit(1);
    }
    ctrlstat = inb(portadress+CONTROL_PORT);
    if (portadress > 0)
    {
      if (iic_ok()) ok = 1;
    }
  } // else
  if (!ok) portadress = 0; 
  return (portadress);
}

// ******************************************************************************************

int deinit_iic (void)
// IIC-Interface deinitialisieren
{
 int status = 0;
  //outp (portadress, 0);
  outp (portadress+CONTROL_PORT, ctrlstat); // Alter Wert 7,12, 8
  status=ioperm(portadress,3,0);
 return (status);
}

int set_port_delay (int delay)
// Wartezeit für den Zugriff auf den Parallel-Port setzen
{
 port_delay = delay;
 return (delay);
}



