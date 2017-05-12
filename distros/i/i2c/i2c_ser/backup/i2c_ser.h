/***********************************************************************/
/*  IIC-Seriell-Interface  I2C				               */
/*  V0.1  erstellt am  : 04.11.2000                                    */
/*  Dateiname          : i2c_ser.h				       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 04.11.00 , Basiert auf i2c_lpt.h für ParPort-Adapter                */
/*                                                                     */
/***********************************************************************/


#define MCR	4	// Modem Control Register xFC 	= Base + 4
#define MSR	6	// Modem Status Register xFE	= Base + 6


/* Funktionen decl. */ 

 int init_iic (int portnr);		// Aufruf : 0 sucht Interface, 1-2 COM-PortVorgabe
 int deinit_iic (void); 		// Rückgabe = 0, KeinInterface gefunden, PortAdresse = OK
 int set_port_delay (unsigned char d); 	// Setzt Pausenwert fuer Port Zugriff
 int read_sda (void); 			// Liest SDA aus
 int read_scl (void); 			// Liest SCL aus
 int iic_start(void); 			// Bereitet die Uebertragung vor
 int iic_stop(void);			// Beendet Datenuebertragung
 unsigned char iic_send_byte (unsigned char w); 
 unsigned char iic_read_byte(unsigned char ack); 

/* Interne Funktionen */
 int iic_ok (void);			// Prueft ob i2c-Interface angeschlossen ist.
 int wait_port(void); 			// Pause fuer Port Zugriff
 int sda_high (void); 			// Setzt SDA auf high
 int sda_low (void); 			// Setzt SDA auf low
 int scl_high (void); 			// Setzt SCL auf high
 int scl_low (void); 			// Setzt SCL auf high
 

/* Dummy Funktionen (i2c_lpt) */
 int set_strobe (int status); 
 int byte_out (int status); 
 int byte_in (int status); 
 int get_status(int status); 
 int io_disable (int status); 
 int io_enable (int status); 
 int inp32(int Port); 
 int out32(int Port, int status); 
 int read_int (void); 

