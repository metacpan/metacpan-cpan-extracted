/***********************************************************************/
/*  Demo fuer IIC-Parallel-Interface  			               */
/*  V0.1  erstellt am  : 30.10.2000                                    */
/*  Dateiname          : cpumon.c				       */
/*  Zeigt CPU Auslastung auf LC-Display an			       */
/*                                    				       */
/*  Aenderungen : 						       */
/*                                                                     */
/*                                                                     */
/* 30.10.00 , Test für i2c_lpt.c                                       */
/* *********************************************************************/

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


#include "i2c_ser.h" 		// i2c Funktionen für ser. Schnittstelle
#include "../lcd/lcd.h"			// LCD Funktionen  
#include "../pcf8574/pcf8574.h"		// PCF8574 Funktionen


typedef struct cpuvar {		// CPU
 float user;
 float nice;
 float system;
 float load;
 float idle;
} cpuvar;

// Variablen 
 int user_p,nice_p,sys_p,idle_p,sum_p;	 	// vorherige Werte
 cpuvar cpu;
  
 int LPT;


// Misst CPU Auslastung , derzeit nur 1 CPU unterstützt
int proc_stat(cpuvar *cpuv)
{
 int ret;
 FILE *fd;

 int user_a,nice_a,sys_a,idle_a,sum_a;	 	// aktuelle Werte
 float c_user,c_nice,c_sys,c_idle,cpu_usage; 	// Berechnete Werte
 
 char tag[]="cpu0";

 ret 	= 0;

	user_a 	= 0;
	nice_a 	= 0;
	sys_a 	= 0;
	idle_a	= 0;
	sum_a	= 0;
	
	// Aktuelle Werte einlesen

	  if((fd = fopen("/proc/stat", "r")) == NULL) {
	   ret=9;
           return ret;
	 }
	
 	fscanf(fd, "%32s %d %d %d %d", tag, &user_a, &nice_a, &sys_a, &idle_a);
	fclose(fd);	 

 	sum_a = ((user_a - user_p) + (nice_a - nice_p) + (sys_a - sys_p) + (idle_a - idle_p));
 	
 	c_user	= (100.0 / sum_a)* (user_a-user_p);
 	c_nice 	= (100.0 / sum_a)* (nice_a-user_p);
 	c_sys	= (100.0 / sum_a)* (sys_a-sys_p);
 	c_idle	= (100.0 / sum_a)* (idle_a-idle_p);
 	
 	user_p 	= user_a;
	nice_p 	= nice_a;
	sys_p 	= sys_a;
	idle_p	= idle_a;
 	
 	cpu_usage = c_user+c_sys;

        cpuv->user=c_user;
     	cpuv->nice=c_nice;
	cpuv->system=c_sys;
    	cpuv->load=cpu_usage;
    	cpuv->idle=c_idle;
    	
  return ret;
}


// Zeigt den Wert cpu.load graf. auf LC-Display an
int show_lcd_bar(void)
{
 int bar;
 const char temp[] = "#############";
 if (cpu.load > 99.9) cpu.load=99.9;	// Problem auf der Anzeige mit der letzten Stelle
 bar = (cpu.load / 10);			// Anzahl der Balken
 sprintf(lcd_STRING,"%4.1f%%    ",cpu.load);
 lcd_instr(LCD_ADR+0x40);		// 2. Zeile
 lcd_write_str(lcd_STRING);
 strcpy(lcd_STRING,"         ");
 strncpy(lcd_STRING,temp,bar);
 lcd_instr(LCD_ADR+0x46);
 lcd_write_str(lcd_STRING); 
 return 0;
}

// Zeigt den Wert cpu.load auf LC-Display an
int show_lcd_val(void)
{
  if(cpu.idle>99.9) cpu.idle=99.9;	// Problem auf der Anzeige mit der letzten Stelle
  if(cpu.user>99.9) cpu.user=99.9;
  sprintf(lcd_STRING," %4.1f %4.1f %4.1f",cpu.user,cpu.system,cpu.idle);
  lcd_instr(LCD_ADR+0x40);		// 2. Zeile
  lcd_write_str(lcd_STRING);
 return 0;
}

int main(int argc, char *argv[]) {

 int test;
 int option;
 int opt;
 int update;
 
 PCF_ADRESS 	= 0;		// Adresse des PCF'S , 0 für den 1. im System usw.
 LPT  		= 0;		// Vorbelegung LPT - Port, 0 Automatisch suchen
 lcd_BACKLIGHT	= 1;		// Licht einschalten
 
 option		= 0;		// Darstellung der Werte 
 update		= 2;		// Update Der Anzeige alle 2 Sec.


 while((opt=getopt(argc, argv, ":b:v:p:s:?")) != EOF)
    switch(opt)
   {
 
    case 'p':
     LPT=atoi(optarg);
     if((LPT<0) | (LPT>3)) LPT=0;
     break;
 
    case 'b':
     option=1;		// Darstellung Usage & Balken
     break;
 
    case 'v':
     option=0;		// Darstellung Werte
     break;
     
    case 's':
     update=atoi(optarg); // Update in sec
     break;

        
   case '?':
      printf("cpumon -p [0-3] -[b|v] -s [sec]\n");     
      printf("\t-p LPT Port 0=automatisch suchen\n");	
      printf("\t-b 1 Anzeige CPU-USage und Balken\n");	
      printf("\t-v 1 Anzeige Cpu-User / System / Idle\n");	
      printf("\t-s Update der Anzeige in sec. \n");	
      exit(1);
    break;
  }

 
 printf("*** i²c-LCD CPU-Monitor 0.2 (c) Ingo Gerlach 11/2000 *** \n");
 set_port_delay(2);		// Portdelay 1-25 25 ..langsam
 test = init_iic(LPT);		// Init ii2c 
 printf("Suche i2c-Interface...");
 if (init_iic(LPT)) 		// gibt 0 zurück falls kein Interface gefunden wird. Sonst die Adresse
 {
  printf(" gefunden an Port 0x%03xh! \n",test);
 } else {
    printf("Interface nicht gefunden.\n");
    exit (2);
  }
  
 set_strobe(1);			// diverse Einstellungen für i2c-Betrieb
 io_disable();
 test=lcd_init();		// Display initialisieren
 lcd_backlight(0); 		// Einschalten (gibt 1 zurück wenn, OK)
 
 lcd_ADRESS=1;			//  * CPU-Monitor * , Beschriftung
 lcd_instr(LCD_ADR+lcd_ADRESS);	// Adresse Setzen
 lcd_write_str("*CPU-Monitor*");
 lcd_instr(LCD_COF);    	// Cursor OFF
//  lcd_ADRESS=1;
// lcd_read_str(5);
// printf("Test: %s \n",lcd_STRING);

 // Var's init. dann Endlos ....

  cpu.user	=0;
  cpu.nice	=0;
  cpu.system	=0;
  cpu.load	=0;
  cpu.idle	=0;
  user_p  	=0;
  nice_p	=0;
  sys_p 	=0;
  idle_p	=0;
  sum_p		=0;

 while (1)
 { 
  proc_stat(&cpu);		// CPU Daten einlesen
  if(option==1) {
   show_lcd_bar();		// Anzeige als Balken
  } else show_lcd_val();
  sleep(update);
 }
 
 printf("deinit %d\n",deinit_iic()); 
 return 0;
}
