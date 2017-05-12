/***********************************************************************/
/*  IIC-(Seriell(Paralell)-Interface Routinen		               */
/*  V0.1  erstellt am  : 04.11.2000 I. Gerlach (DH1AAD)                */
/*  Dateiname          : i2c_fncs.h				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*  25.11.00	unsigned char durch int ersetzt			       */
/*                                                                     */
/*                                                                     */
/* 04.11.00 , Basiert auf i2c_lpt.h für ParPort-Adapter                */
/*                                                                     */
/***********************************************************************/


/* Funktionen decl. extern i2c_ser & i2c_par*/ 

 int init_iic (int portnr);		// 0 sucht Interface, (1-2 COM-Port Ser.) (1-3 Par-Port)
 int deinit_iic (void); 		// Rückgabe = 0, KeinInterface gefunden, PortAdresse = OK
 int set_port_delay (int delay); 	// Setzt Pausenwert fuer Port Zugriff 
 int read_sda (void); 			// Liest SDA aus
 int read_scl (void); 			// Liest SCL aus
 int iic_start(void); 			// Bereitet die Uebertragung vor
 int iic_stop(void);			// Beendet Datenuebertragung
 int iic_send_byte(int byte); 		// Sendet ein Byte
 int iic_read_byte(int ack); 		// Liest ein Byte und sendet ein ACK wenn ack <> 0

/* Interne Funktionen i2c_ser & i2c_par	*/
 int iic_ok (void);			// Prueft ob i2c-Interface angeschlossen ist.
 int wait_port(void); 			// Pause fuer Port Zugriff 
 int sda_high (void); 			// Setzt SDA auf high
 int sda_low (void); 			// Setzt SDA auf low
 int scl_high (void); 			// Setzt SCL auf high
 int scl_low (void); 			// Setzt SCL auf high
 

/* Funktionen nur f. i2c_par Adapter 8-Bit in/out. Dummy Funktionen f. (i2c_ser) */
 int set_strobe (int status); 		// status 0 | 1
 int byte_out (int status); 		// status wird ausgegeben
 int byte_in (int status); 		// status enthaelt das eingelesene Byte
 int get_status(int status); 		// Statusport des Parports einlesen
 int io_disable (void); 		// nur i2c
 int io_enable (void);	 		// 8-bit i/o einschalten 
 int inp32(int Port); 			// Liest ein Byte von Port ein
 int out32(int Port,int byte);		// Gibt ein Byte auf Port aus.
 int read_int (void); 			// Prueft ob INT Leitung aktiv ist, 
					// Rueckgabe 1 = Ja , 0 = Nein

