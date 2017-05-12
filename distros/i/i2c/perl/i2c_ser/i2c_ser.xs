#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../../i2c_ser/i2c_ser.h"
#include "../../pcf8574/pcf8574.h"
#include "../../sda3302/sda3302.h"
#include "../../tsa6057/tsa6057.h"
#include "../../pcf8591/pcf8591.h"
#include "../../lcd/lcd.h"

static int 
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = i2c_ser		PACKAGE = i2c_ser		


double
constant(name,arg)
	char *		name
	int		arg



int 
init_iic(a)
	int a
OUTPUT:
RETVAL


int 
deinit_iic()
OUTPUT:
RETVAL


int 
set_port_delay(a)
	int a
OUTPUT:
RETVAL

int 
read_sda()
OUTPUT:
RETVAL

int 
read_scl()
OUTPUT:
RETVAL

int 
iic_start()
OUTPUT:
RETVAL

int 
iic_stop()
OUTPUT:
RETVAL

int 
iic_send_byte(a)
	int a
OUTPUT:
RETVAL

int 
iic_read_byte(a)
	int a
OUTPUT:
RETVAL

int 
set_strobe(a)
	int a
OUTPUT:
RETVAL

int 
byte_out(a)
	int a
OUTPUT:
RETVAL

int 
byte_in(a)
	int a
OUTPUT:
RETVAL

int 
get_status(a)
	int a
OUTPUT:
RETVAL

int 
io_disable()
OUTPUT:
RETVAL

int 
io_enable()
OUTPUT:
RETVAL

######################## PCF 8574 / 8-BIT I/O #####################################
# Gibt alle def. Constanten zurück
int
pcf8574_const()
PPCODE:
 EXTEND(SP,2);
 PUSHs(sv_2mortal(newSViv(PCF8574_TX)));
 PUSHs(sv_2mortal(newSViv(PCF8574_RX)));

int
iic_tx_pcf8574(Data,Adress)
	int Data
	int Adress
OUTPUT:
RETVAL

int
iic_rx_pcf8574(Adress)
	int Adress
PREINIT:
	int	status;
	int 	Data;
PPCODE:
 status = iic_rx_pcf8574(&Data,Adress);
 EXTEND(SP,1);
 PUSHs(sv_2mortal(newSViv(Data)));



########################## SDA 3302 / PLL / TUNER ##################################
# Gibt def. Constanten zurück
int
sda3302_const()
PPCODE:
 EXTEND(SP,5);
 PUSHs(sv_2mortal(newSViv(SDA3302_ADR)));
 PUSHs(sv_2mortal(newSViv(SDA3302_STEP)));
 PUSHs(sv_2mortal(newSViv(SDA3302_ZF)));
 PUSHs(sv_2mortal(newSViv(SDA3302_PLL)));
 PUSHs(sv_2mortal(newSViv(SDA3302_DIV)));

sda3302 *
create3302()
CODE:
sda3302	*s = (sda3302*) malloc(sizeof(sda3302));
s->div1 = 0;
s->div2 = 0;
s->cnt1 = 0;
s->cnt2 = 0;
RETVAL  = s;
OUTPUT:
RETVAL

int
sda3302_init(sda,mode)
	sda3302*	sda
	int		mode
OUTPUT:
RETVAL


# So funkt es leider nicht ...
#sda3302 *
#sda3302_init(sda,mode)
#	int 		mode
#REINIT:
#int 		status;
#PPCODE:
#	sda3302	*s = (sda3302*) malloc(sizeof(sda3302));
#	s->div1 = 0;
#	s->div2 = 0;
#	s->cnt1 = 0;
#	s->cnt2 = 0;
#	status = sda3302_init(s,mode);
#	EXTEND(SP,1);
#	PUSHs(sv_2mortal(newSViv(s)));

int
sda3302_calc(sda,freq)
	sda3302*	sda
	long		freq
OUTPUT:
RETVAL

int
sda3302_send(sda,Adresse)
	sda3302*	sda
	int		Adresse
OUTPUT:
RETVAL

void
delete3302(sda)
	sda3302*	sda
CODE:
if (sda != NULL)
{
free(sda);
}

########################## TSA 6057 / PLL  ##################################
# Gibt def. Constanten zurück
int
tsa6057_const()
PPCODE:
 EXTEND(SP,6);
 PUSHs(sv_2mortal(newSViv(TSA6057_ADR)));
 PUSHs(sv_2mortal(newSViv(TSA6057_AM)));
 PUSHs(sv_2mortal(newSViv(TSA6057_FM)));
 PUSHs(sv_2mortal(newSViv(TSA6057_R01)));
 PUSHs(sv_2mortal(newSViv(TSA6057_R10)));
 PUSHs(sv_2mortal(newSViv(TSA6057_R25)));

tsa6057 *
create6057()
CODE:
tsa6057	*s = (tsa6057*) malloc(sizeof(tsa6057));
s->sadr = 0;
s->db0 = 0;
s->db1 = 0;
s->db2 = 0;
s->db3 = 0;
RETVAL  = s;
OUTPUT:
RETVAL

int
tsa6057_init(tsa,raster,mode)
	tsa6057*	tsa
	int		mode
	int 		raster
OUTPUT:
RETVAL


int
tsa6057_calc(tsa,freq)
	tsa6057*	tsa
	long		freq
OUTPUT:
RETVAL

int
tsa6057_send(tsa,Adresse)
	tsa6057*	tsa
	int		Adresse
OUTPUT:
RETVAL

void
delete6057(tsa)
	tsa6057*	tsa
CODE:
if (tsa != NULL)
{
free(tsa);
}


########################### PCF 8591 AD/DA #####################################

# Gibt alle def. Constanten zurück
int
pcf8591_const()
PPCODE:
 EXTEND(SP,7);
 PUSHs(sv_2mortal(newSViv(PCF8591_ADR)));
 PUSHs(sv_2mortal(newSViv(PCF8591_RX)));
 PUSHs(sv_2mortal(newSViv(PCF8591_C4S)));
 PUSHs(sv_2mortal(newSViv(PCF8591_C3D)));
 PUSHs(sv_2mortal(newSViv(PCF8591_C2S)));
 PUSHs(sv_2mortal(newSViv(PCF8591_C2D)));
 PUSHs(sv_2mortal(newSViv(PCF8591_C3D)));

pcf8591 *
create8591()
CODE:
pcf8591	*s = (pcf8591*) malloc(sizeof(pcf8591));
	s->chan_mode = 0;
	s->REF 	     = 0.0;
	s->da_val    = 0;
RETVAL  = s;
OUTPUT:
RETVAL


int
pcf8591_init(adda,mode,ref)
	pcf8591*	adda
	int 		mode
	double		ref
OUTPUT:
RETVAL

# Direkter Zugriff auf Funktion nicht möglich ??
# pcf8591_readchan(adda,Kanal);
int
pcf8591_readchan(adda,Kanal)
	pcf8591*	adda
	int		Kanal
PREINIT:
	int	status;
PPCODE:
 status = pcf8591_readchan(adda,Kanal);
 EXTEND(SP,1);
 PUSHs(sv_2mortal(newSViv(adda->data[Kanal])));


int
pcf8591_read4chan(adda)
	pcf8591*	adda
PREINIT:
	int	status;
PPCODE:
 status = pcf8591_read4chan(adda);
 EXTEND(SP,4);
 PUSHs(sv_2mortal(newSViv(adda->data[0])));
 PUSHs(sv_2mortal(newSViv(adda->data[1])));
 PUSHs(sv_2mortal(newSViv(adda->data[2])));
 PUSHs(sv_2mortal(newSViv(adda->data[3])));

int
pcf8591_setda(adda,outval)
	pcf8591*	adda
	double		outval
OUTPUT:
RETVAL


double
pcf8591_aout(adda,Kanal)
	pcf8591*	adda
	int		Kanal
OUTPUT:
RETVAL



void
delete8591(adda)
	pcf8591*	adda
CODE:
if (adda != NULL)
{
free(adda);
}

########################### LCD #####################################
int
lcd_init()
OUTPUT:
RETVAL

int
lcd_instr(command)
	int	command
OUTPUT:
RETVAL

int
lcd_wchar(wchar)
	int	wchar
OUTPUT:
RETVAL

int
lcd_rchar(adr)
	int	adr
PREINIT:
	int	status;
	int	rchar;
PPCODE:
 status = lcd_rchar(&rchar,adr);
 EXTEND(SP,1);
 PUSHs(sv_2mortal(newSViv(rchar)));

int
lcd_read_str(slen,adr)
	int	slen
	int	adr
PREINIT:
	int	status;
PPCODE:
 status = lcd_read_str(slen,adr);
 EXTEND(SP,1); 	
 PUSHs(sv_2mortal(newSVpv(lcd_STRING,0)));

int
lcd_write_str(string)
	char*	string
OUTPUT:
RETVAL

int
lcd_backlight(on_off)
	int	on_off
OUTPUT:
RETVAL

int
lcd_get_adress()
OUTPUT:
RETVAL

