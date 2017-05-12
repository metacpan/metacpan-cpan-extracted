package i2c_ser;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw( 
	
);
$VERSION = '1.00';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined i2c_ser macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap i2c_ser $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

i2c_ser - Perl extension fuer diverse i2c devices. 
Version 0.1 / 2.12.2000

=head1 SYNOPSIS

  use i2c_ser;
  
  *** Allgemeine I²C-Routinen ***
  
  i2c_ser::init_iic(int PortNr)	
  i2c_ser::deinit_iic(void)			
  i2c_ser::set_port_delay(int delay)	  
  i2c_ser::read_sda(void)	
  i2c_ser::read_scl(void)	
  i2c_ser::iic_start(void)
  i2c_ser::iic_stop(void)	
  i2c_ser::send_byte(int byte)
  i2c_ser::read_byte(int ack)


  ***    PCF8574    ***

  i2c_ser::pcf8574_const()
  i2c_ser::iic_tx_pcf8574(int Data, int Adress_Offset) 
  i2c_ser::iic_rx_pcf8574(int Adress_Offset) 	

  ***    PCF8591    ***

  i2c_ser::pcf8591_const()
  i2c_ser::create8591()
  i2c_ser::pcf8591_init($ptr,$pcf8591_mode,$pcf8591_ref_UB)
  i2c_ser::pcf8591_readchan($ptr,$Kanal)
  i2c_ser::pcf8591_read4chan($ptr);
  i2c_ser::pcf8591_aout($ptr,$Kanal)
  i2c_ser::pcf8591_setda($ptr,$ubval);
  i2c_ser::delete8591($ptr)


  ***    SDA3302    ***

  i2c_ser::sda3302_const()
  i2c_ser::create3302()
  i2c_ser::sda3302_init($ptr3302,$sda3302_mode)
  i2c_ser::sda3302_calc($ptr3302,$frequenz)
  i2c_ser::sda3302_send($ptr3302,$sda3302_adr_off)
  i2c_ser::delete3302($ptr3302)

  ***    TSA6057    ***

  i2c_ser::tsa6057_const()
  i2c_ser::tsa6057()
  i2c_ser::tsa6057_init($ptr,Raster,Mode)
  i2c_ser::tsa6057_calc($ptr,$frequenz)
  i2c_ser::tsa6057_send($ptr,$adr_off)
  i2c_ser::delete6057($ptr)

  ***  LCD-Funktionen (PCF8574)  ***
  i2c_ser::lcd_init()
  i2c_ser::lcd_backlight($On_Off)
  i2c_ser::lcd_instr($Kommando)
  i2c_ser::lcd_get_adress()
  i2c_ser::lcd_wchar(ord(H))
  i2c_ser::lcd_write_str($string)
  i2c_ser::lcd_rchar($ram_adresse)
  i2c_ser::lcd_read_str($len,$ram_adresse)


=head1 DESCRIPTION

  *** Allgemeine I²C-Routinen ***
  
	$ret=i2c_ser::init_iic(int PortNr)
	ret gibt Portnummer (dezimal z.B. 888) zurück, wenn Interface gefunden wird.
	PortNr = 0 , es wird automatisch gesucht
	PortNr 1-3 , es wird nur an dem angegebenen Port gesucht.
	
        i2c_ser::deinit_iic(void)			
        Der mit init_iic() geöffnete Port wird wieder geschlossen.

	i2c_ser::set_port_delay(int delay)
	Setzt eine gewisse Verzoegerung für die Portzugriffe.
	Der Wert 'delay' muss groesser 0 sein. 
	Sinnvolle Werte liegen zwischen 5 - 25 .

	i2c_ser::read_sda(void)	
	Gibt den Status high/low der SDA-Leitung zurueck.

	i2c_ser::read_scl(void)	
	Gibt den Status high/low der SCL-Leitung zurueck.

	i2c_ser::iic_start(void)
	Initiert den I2C-Bus

	i2c_ser::iic_stop(void)	
	Schickt Stop-Bedingung auf den Bus.

	i2c_ser::send_byte(int byte)
	Sendet das Byte 'byte'

	i2c_ser::read_byte(int ack)
	Lies ein Byte , gibt , wenn 'ack' <> 0 ist, ein ACK aus.


  *** 8 BIT I/O - Routinen ***

	i2c_ser::set_strobe(int status)
	Setz die Strobleitung auf Status (0|1)

	i2c_ser::byte_out(int byte_out)
	Gibt das Byte byte_out aus.

	i2c_ser::byte_in(int byte_in)
	Liest das Byte byte_in

	i2c_ser::get_status(int status)

	i2c_ser::io_disable(void)

	i2c_ser::io_enable(void)


  *** PCF8574 - Routinen ***

       ($tx_8574,$rx_8574) = i2c_ser::pcf8574_const();
	Gibt die def. Konstanten zurück. 

	i2c_ser::iic_tx_pcf8574(int Data, int Adress_Offset) 
	Sendet das Byte 'Data' zum PCF8574.
	Ist die Adresse <> 112 , muss Adresss_Offste entsprechend gesetz werden.
	Sonst Adress_Offset=0.

	i2c_ser::iic_rx_pcf8574(int Adress_Offset) 	
	Liest den Eingang aus.
	# Ein Byte einlesen
	$r=i2c_ser::iic_rx_pcf8574(0);
	print "PCF8574: Value $r \n\n";
	Ist die Adresse <> 113 , muss Adresss_Offste entsprechend gesetz werden.
	Sonst Adress_Offset=0.

  ***    PCF8591    ***

	i2c_ser::pcf8591_const()
       ($pcf8591_adr,
	$pcf8591_rx,
	$pcf8591_c4s,
	$pcf8591_c3d,
	$pcf8591_c2s, 
	$pcf8591_c2d) = i2c_ser::pcf8591_const();
	Gibt die def. Konstanten zurück. 

	i2c_ser::create8591()
	Erzeugt einen Pointer auf Datenstruktur.
	$ptr =i2c_ser::create8591();

        i2c_ser::pcf8591_init($ptr,$pcf8591_mode,$pcf8591_ref_UB);
	Initialisiert den Wandler.
        Mode : 0 = 4x Eing. , 16 3x Dif, 32 2 xSE 2xDif, 48 2x Dif
	
	i2c_ser::pcf8591_readchan($ptr,$Kanal)
	$chan = i2c_ser::pcf8591_readchan($ptr,$Kanal);
	Liest den Wert des $Kanal aus.

	@Kanaele = i2c_ser::pcf8591_read4chan($ptr);
	Liest Alle 4 Kanaele aus. Rueckgabe Array.

	$chan = i2c_ser::pcf8591_aout($ptr,$Kanal)
	Berechnet für den $Kanal den Wert in Volt.

	i2c_ser::pcf8591_setda($ptr,$ubval);
	Setzt den Ausgang des DA Wandlers auf $ubval.

	i2c_ser::delete8591($ptr)
	Loescht den Pointer.


  *** SDA3302 - Routinen ***

	i2c_ser::sda3302_const()
        ($sda3302_adr,
	$sda3302_step,
	$sda3302_zf,
	$sda3302_PLL,
	$sda3302_DIV) = i2c_ser::sda3302_const();
	Gibt die def. Konstanten zurück. 

	i2c_ser::create3302()
	Erzeugt einen Pointer auf Datenstruktur.
	$ptr3302=i2c_ser::create3302();

	i2c_ser::sda3302_init($ptr3302,$sda3302_mode)
	Initialisiert die PLL.
	'mode' legt Fest, ob der SDA3302 als Teiler (238)
	oder als PLL (206) arbeitet.

	i2c_ser::sda3302_calc($ptr3302,$frequenz)
	Berechnet fuer $frequenz die Teiler.

	i2c_ser::sda3302_send($ptr3302,$adr_offset)
	Sendet die Teiler zur PLL.

	i2c_ser::delete3302($ptr3302)
	Loescht den Pointer.


  *** TSA6057 - Routinen ***

	i2c_ser::tsa6057_const()
	($tsa6057_adr,
	$tsa6057_am,
	$tsa6057_fm,
	$tsa6057_R01,
	$tsa6057_R10,
	$tsa6057_R25) = i2c_ser::tsa6057_const();
	Gibt die def. Konstanten zurück. 

	i2c_ser::create6057()
	Erzeugt einen Pointer auf Datenstruktur.
	$ptr=i2c_ser::create6057();

	i2c_ser::tsa6057_init($ptr,$RASTER,$MODE);
	Initialisiert die PLL.
	Raster legt das Ratser Fest. Mode AM | FM.

	$teiler = i2c_ser::tsa6057_calc($ptr,$frequenz);
	Berechnet fuer $frequenz die Teiler.

	i2c_ser::tsa6057_send($ptr,$adr_offset);
	Sendet die Teiler zur PLL.
	adr_offset 0 | 2

	i2c_ser::delete6057($ptr)
	Loescht den Pointer.

  ***  LCD-Funktionen (PCF8574)  ***
	LCD Befehle 
	Cursor Off 	= 0x0c
	Cursor On 	= 0x0e
	Cursor home 	= 0x02
	Cursor blink 	= 0x0f
	Display Clear	= 0x01
	Display Off	= 0x08
	Adresse setz.	= 0x80

	i2c_ser::lcd_init();
	Initialisiert das Display. 

	$bl = i2c_ser::lcd_backlight($on_off);
	Schaltet, sofern vorhanden, die Beleuchtung des Displays ein.
	$on_off = 1 -> Licht an.
	$on_off = 0 -> Licht aus.

	i2c_ser::lcd_instr($cmd);
	Schickt das Kommando $cmd an das Display.
	Display Off	= 0x08
	i2c_ser::lcd_instr(0x08);
	

	$lcdadr=i2c_ser::lcd_get_adress();
	Liest die Adresse Cursorposition.	

	i2c_ser::lcd_wchar(ord(H));
	Schreibt ein einzelnes Zeichen an die aktuelle Adresse.

	i2c_ser::lcd_write_str("Hallo Display");
	Schreibt einen String in das Display.

	$rchar=chr(i2c_ser::lcd_rchar($Adresse));
	Liest das Zeichen an $Adresse.

	$rchar=i2c_ser::lcd_read_str($len,$adr);
	Liest einen String mit Länge $len ab Position
	$Adresse aus dem Display.



=head1 AUTHOR
IngoGerlach@welfen-netz.com (DH1AAD) 2.12.2000

=head1 SEE ALSO

perl(1).

=cut
