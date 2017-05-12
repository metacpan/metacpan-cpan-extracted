/***********************************************************************/
/*  LCD Funktionen						       */	
/*  fuer i2c-Parallel-Interface 			               */
/*  V0.1  erstellt am  : 26.10.2000                                    */
/*  Dateiname          : lcd.h					       */
/*                		       				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 26.10.00 , Start  					               */
/*                                                                     */
/***********************************************************************/


#define PCF8574	112		// PCF8574 Adresse default	

/* LCD Konstanten    */
#define LCD_IR	0x00		// Instruction Register
#define LCD_DR	0x01		// Data Register
#define LCD_BL	0x08		// Backlight
#define LCD_COF	0x0C		// Cursor Off
#define	LCD_CON	0x0E		// Cursor On
#define LCD_CBL	0x0F		// Cursor Blink
#define LCD_CHM	0x02		// Cursor Home
#define LCD_CLR	0x01		// Display Clear
#define LCD_OFF	0x08		// Display Off
#define	LCD_ADR 0x80		// Adresse setzen

/* LCD Parameter */
#define	LCD_LIN	2		// Anzahl der Zeilen 
#define	LCD_CHR	16		// Anzahl der Zeichen / Zeile

/* glob. Vars */

int 	lcd_BACKLIGHT;		// 1 = ON; 0=Off
int 	lcd_ADRESS;		// Adresse im RAM 
char 	lcd_STRING[LCD_LIN*(LCD_CHR-1)];	// String 


/* Funk. decl. extern */

int 	lcd_init(void);				// Initialisiert Display , 2 Zeilen 4-BIT
int 	lcd_instr(int cmd);			// LCD Commando
int 	lcd_wchar(int data);			// Schreibt ein Zeichen in das Display
int 	lcd_rchar(int *data,int adr);		// Liest ein Zeichen vom Display von Adresse adr
int 	lcd_write_str(char *lstr);		// Schreibt einen String auf LCD
int 	lcd_read_str(int len,int adr);		// Liest String in lstr, von Adresse adr, mit len Anzahl
int 	lcd_backlight(int cmd);			// 0 Licht aus, 1 Licht an
int     lcd_get_adress(void);                   // Liest die aktuelle Adresse aus dem Display. 

/* Funk. decl. intern */
int	lcd_write_nibble(int regdir,int data);	// regdir LCD_IR | LCD_IR , DatenByte
int	lcd_read_nibble(int regdir);		// regdir LCD_IR | LCD_DR , DatenByte
int	lcd_busy(void);				// Gibt 1 bei Busy 0, bei OK 

