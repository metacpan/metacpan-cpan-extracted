# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

# BEGIN { $| = 1; print "1..10\n"; }
# END {print "not ok 1\n" unless $loaded;}


use i2c_ser;
use vars;
$loaded = 1;
# print "ok 1\n";

######################### End of black magic.

###########################################################################
# I2C - Interface (Serieller-Port)                                         #
###########################################################################

# Port Delay 
i2c_ser::set_port_delay(8);

# Interface automatisch suchen
$iport = i2c_ser::init_iic(0);
print "Suche Interface...\n";
if ($iport > 0) {
 print "I2C-Interface gefunden an $iport \n\n"; 
} else {
  print "I2C-Interface nicht gefunden. \n"; 
  exit 1;
 }


###########################################################################

###########################################################################
#                           PCF8574                                       # 
###########################################################################
# Def. Konstanten
($tx_8574,$rx_8574) = i2c_ser::pcf8574_const();
 print "PCF8574: def. Konstanten -> TX-ADR: $tx_8574, RX-ADR: $rx_8574 \n";
# Ein Byte senden, (Adresse = 0, dh. 112) 
 $r=i2c_ser::iic_tx_pcf8574(12,0);
 print "PCF8574: Sende #12 an (pcf8574) Ret: $r \n";
# Ein Byte einlesen
 $r=i2c_ser::iic_rx_pcf8574(0);
 print "PCF8574: Empfangenes Byte $r \n\n";
###########################################################################


###########################################################################
#                            PCF8591                                      #
###########################################################################
# Variablen

# $pcf8591_mode  = 0; 		# 0 = 4x Eing. , 16 3x Dif, 32 2 xSE 2xDif, 48 2x Dif
 $pcf8591_adroff = 0;		# Adresse = 0 default 144 
 $pcf8591_ref  = 4.0;		# Referenz Ub.


# Def. Konstanten
 ($pcf8591_adr,$pcf8591_rx,$pcf8591_c4s,$pcf8591_c3d,$pcf8591_c2s, $pcf8591_c2d) = i2c_ser::pcf8591_const();
print "PCF8591: def. Konstanten -> ADR: $pcf8591_adr, RX: $pcf8591_rx Modes: $pcf8591_c4s,$pcf8591_c3d,$pcf8591_c2s,$pcf8591_c2d \n";
print "PCF8591: Mode : 0 = 4x Eing. , 16 3x Dif, 32 2 xSE 2xDif, 48 2x Dif \n";
# Datenpointer anlegen 
$ptr =i2c_ser::create8591();
# Initialisierung
$r=i2c_ser::pcf8591_init($ptr,$pcf8591_mode,$pcf8591_ref);
# Daten Kanal 0 auslesen
 $chan = i2c_ser::pcf8591_readchan($ptr,0);
 $ubval=i2c_ser::pcf8591_aout($ptr,0);
 print "PCF8591: Kanal 0 = $chan , $ubval Volts ,  \n";
# Daten alle Kanaele auslesen
($a,$b,$c,$d) = i2c_ser::pcf8591_read4chan($ptr);
 print "PCF8591: Kanal 0 : ".i2c_ser::pcf8591_aout($ptr,0)." V \n";
 print "PCF8591: Kanal 1 : ".i2c_ser::pcf8591_aout($ptr,1)." V \n";
 print "PCF8591: Kanal 2 : ".i2c_ser::pcf8591_aout($ptr,2)." V \n";
 print "PCF8591: Kanal 3 : ".i2c_ser::pcf8591_aout($ptr,3)." V \n";
# Output setzen 2.5 V
i2c_ser::pcf8591_setda($ptr,3.5);
 print "PCF8591: DA : auf 2.5 V gesetzt.\n\n";
# Daten löschen 
i2c_ser::delete8591($ptr);
############################################################################


###########################################################################
#                            SDA3302                                      #
###########################################################################
# Variablen

# $sda3302_step = 62500; 	# Schrittweite 62,5 KHz
# $sda3302_zf   = 37300000; 	# ZF 37,3 MHz
# $sda3302_mode = 206;		# Modus 206 = PLL, 238 Teiler
# $sda3302_adr  = 192;		# Adresse = 0 default 192  (Adr_Offset 0,2,4,6);

# Def. Konstanten
($sda3302_adr,$sda3302_step,$sda3302_zf,$sda3302_PLL,$sda3302_DIV) = i2c_ser::sda3302_const();
print "SDA3302: def. Konstanten -> ADR: $sda3302_adr, Step: $sda3302_step, ZF: $sda3302_zf, Mode PLL: $sda3302_PLL, Mode DIV: $sda3302_DIV \n";
# @w= i2c_ser::pcf8591_const(); oder so ....
# Datenpointer anlegen 
 $ptr3302=i2c_ser::create3302();
# Initialisierung
 $r=i2c_ser::sda3302_init($ptr3302,$sda3302_PLL);
 $f=104100000; # Frequenz -> RADIO 21 
#Teiler Berechnen
 $teiler = i2c_ser::sda3302_calc($ptr3302,$f);
 print "SDA3302: Teiler f($f)Hz : $teiler \n";
#Daten an PLL senden
 $r = i2c_ser::sda3302_send($ptr3302,0);
 $fres = ($teiler * $sda3302_step) - $sda3302_zf;
 print "SDA3302: Res. Frequenz $fres \n\n";
# Daten löschen
 i2c_ser::delete3302($ptr3302);
############################################################################


###########################################################################
#                            TSA6057                                      #
###########################################################################

# Def. Konstanten
($tsa6057_adr,$tsa6057_am,$tsa6057_fm,$tsa6057_R01,$tsa6057_R10,$tsa6057_R25) = i2c_ser::tsa6057_const();
print "TSA6057: def. Konstanten -> ADR: $tsa6057_adr,$tsa6057_am,$tsa6057_fm,$tsa6057_R01,$tsa6057_R10,$tsa6057_R25 \n";
# Datenpointer anlegen 
 $ptr=i2c_ser::create6057();
# Initialisierung
 $r=i2c_ser::tsa6057_init($ptr,$tsa6057_R25,$tsa6057_fm);
 $f=57600000; # Frequenz
#Teiler Berechnen
 $teiler = i2c_ser::tsa6057_calc($ptr,$f);
 print "TSA6057: Teiler f($f)Hz : $teiler \n";
#Daten an PLL senden
 $r = i2c_ser::tsa6057_send($ptr,0);
# Daten löschen
 i2c_ser::delete6057($ptr);
############################################################################

######################## Frequenz SDA & TSA setzen #########################

 $VCO =  58700000;
 $fo  = 145675000;

# Datenpointer anlegen TSA6057
 $ptr=i2c_ser::create6057();
# Initialisierung
 $r=i2c_ser::tsa6057_init($ptr,$tsa6057_R25,$tsa6057_fm);

# Datenpointer anlegen SDA3302
 $ptr3302=i2c_ser::create3302();
# Initialisierung
 $r=i2c_ser::sda3302_init($ptr3302,$sda3302_PLL);

  i2c_ser::iic_tx_pcf8574(5,0); # NF-Schmal , Squelch ein 12 FM-Breit
  
  $teiler = i2c_ser::sda3302_calc($ptr3302,$fo);


  $freq = ($teiler*$sda3302_step)-$sda3302_zf;
  
  $df = $fo - $freq;
  print "\nTUNER: Teiler $teiler , Fres : $freq \n"; 
  $nf = $VCO - $df;
  print "TUNER: Dif: $nf\n"; 
  i2c_ser::tsa6057_calc($ptr,$nf);

  $r = i2c_ser::sda3302_send($ptr3302,0);
  $r = i2c_ser::tsa6057_send($ptr,0);

  print "TUNER: Frequenz eingestellt. -> $fo\n\n"; 

i2c_ser::delete6057($ptr);
i2c_ser::delete3302($ptr3302);
###########################################################################

###########################################################################
# 			LCD-Routinen fuer PCF8574 Board			  #
###########################################################################
# LCD Befehle 
# Cursor Off 	= 0x0c
# Cursor On 	= 0x0e
# Cursor home 	= 0x02
# Cursor blink 	= 0x0f
# Display Clear	= 0x01
# Display Off	= 0x08
# Adresse setz.	= 0x80

print "LCD : Display Initialisieren..\n";
i2c_ser::lcd_init();
$licht = i2c_ser::lcd_backlight(1);
print "LCD : Licht an \n";
i2c_ser::lcd_instr(0x0c);
print "LCD : Cursor Off \n";
$lcdadr=i2c_ser::lcd_get_adress();
print "LCD : Der Cursor ist jetzt an Adresse $lcdadr \n";
i2c_ser::lcd_wchar(ord(H));
i2c_ser::lcd_wchar(ord(a));
i2c_ser::lcd_wchar(ord(l));
i2c_ser::lcd_wchar(ord(l));
i2c_ser::lcd_wchar(ord(o));
$lcdadr=i2c_ser::lcd_get_adress();
print "LCD : Der Cursor ist jetzt an Adresse $lcdadr \n";
i2c_ser::lcd_instr(0x01);
i2c_ser::lcd_write_str("Hallo Display");
print "LCD : Ausgabe mit lcd_write_str  \n";
i2c_ser::lcd_instr(0x80+0);
$rchar=chr(i2c_ser::lcd_rchar(0));
print "LCD : Zeichen an Adresse 0 : $rchar  \n";
$rchar=i2c_ser::lcd_read_str(15,0);
print "LCD : String ab Adresse 0 einlesen : $rchar  \n";
i2c_ser::lcd_instr(0x80+0x40); # 2. Zeile
$fo = $fo / 1000000;
i2c_ser::lcd_write_str($fo." MHz");
print "LCD : 2. Zeile $fo MHz\n";
###########################################################################
# deinit Port
$r =i2c_ser::deinit_iic();
print "Deinit $iport \n";
