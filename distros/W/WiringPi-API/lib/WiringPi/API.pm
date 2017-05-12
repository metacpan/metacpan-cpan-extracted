package WiringPi::API;  

use strict;
use warnings;

our $VERSION = '2.3609';

require XSLoader;
XSLoader::load('WiringPi::API', $VERSION);

require Exporter;
our @ISA = qw(Exporter);

my @wpi_c_functions = qw(
    wiringPiSetup       wiringPiSetupSys    wiringPiSetupGpio
    wiringPiSetupPhys   pinMode             pullUpDnControl
    digitalRead         digitalWrite        digitalWriteByte
    pwmWrite            getAlt              piGpioLayout
    wpiToGpio           physPinToGpio       pwmSetRange
    lcdInit             lcdHome             lcdClear
    lcdDisplay          lcdCursor           lcdCursorBlink
    lcdSendCommand      lcdPosition         lcdDefChar
    lcdPutChar          lcdPuts             setInterrupt
    softPwmCreate       softPwmWrite        softPwmStop
    sr595Setup          bmp180Setup         bmp180Pressure
    bmp180Temp          analogRead          analogWrite
    physPinToWpi        wiringPiVersion     ads1115Setup
    pseudoPinsSetup     wiringPiSPISetup    spiDataRW
    wiringPiI2CSetup    wiringPiI2CSetupInterface
    wiringPiI2CRead     wiringPiI2CReadReg8 wiringPiI2CReadReg16
    wiringPiI2CWrite    wiringPiI2CWriteReg8    wiringPiI2CWriteReg16
);

my @wpi_perl_functions = qw(
    setup           setup_sys       setup_phys          setup_gpio 
    pull_up_down    read_pin        write_pin           pwm_write
    get_alt         gpio_layout     wpi_to_gpio         phys_to_gpio
    pwm_set_range   lcd_init        lcd_home            lcd_clear
    lcd_display     lcd_cursor      lcd_cursor_blink    lcd_send_cmd
    lcd_position    lcd_char_def    lcd_put_char        lcd_puts
    set_interrupt   soft_pwm_create soft_pwm_write      soft_pwm_stop
    shift_reg_setup bmp180_setup    bmp180_pressure     bmp180_temp
    analog_read     analog_write    pin_mode            phys_to_wpi
    ads1115_setup   spi_setup       spi_data            i2c_setup
    i2c_interface   i2c_read        i2c_read_byte       i2c_read_word
    i2c_write       i2c_write_byte  i2c_write_word      testChar
);

our @EXPORT_OK;

@EXPORT_OK = (@wpi_c_functions, @wpi_perl_functions);
our %EXPORT_TAGS;

$EXPORT_TAGS{wiringPi} = [@wpi_c_functions];
$EXPORT_TAGS{perl} = [@wpi_perl_functions];
$EXPORT_TAGS{all} = [@wpi_c_functions, @wpi_perl_functions];

sub new {
    return bless {}, shift;
}

# soft PWM functions

sub soft_pwm_create {
    shift if @_ == 4;
    my ($pin, $value, $range) = @_;
    softPwmCreate($pin, $value, $range);
}
sub soft_pwm_write {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    softPwmWrite($pin, $value);
}
sub soft_pwm_stop {
    shift if @_ == 2;
    my $pin = shift;
    softPwmStop($pin);
}

# interrupt functions

sub set_interrupt {
    shift if @_ == 4;
    my ($pin, $edge, $callback) = @_;
    setInterrupt($pin, $edge, $callback);
}

# system functions

sub setup {
    return wiringPiSetup();
}
sub setup_sys {
    return wiringPiSetupSys();
}
sub setup_phys {
    return wiringPiSetupPhys();
}
sub setup_gpio {
    return wiringPiSetupGpio();
}

# pin functions

sub pin_mode {
    shift if @_ == 3;
    my ($pin, $mode) = @_;
    if (! grep {$mode == $_} qw(0 1 2 3)){
        die "pin_mode() requires either 0, 1, 2 or 3 as a param";
    }
    pinMode($pin, $mode);
}
sub pull_up_down {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    # off, down up = 0, 1, 2
    pullUpDnControl($pin, $value);
    select(undef, undef, undef, 0.02);
}
sub read_pin {
    shift if @_ == 2;
    my $pin = shift;
    return digitalRead($pin);
}
sub write_pin {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    digitalWrite($pin, $value);
}
sub pwm_write {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    pwmWrite($pin, $value);
}
sub get_alt {
    shift if @_ == 2;
    my $pin = shift;
    return getAlt($pin);
}
sub analog_read {
    shift if @_ == 2;
    my ($pin) = @_;
    return analogRead($pin)
}
sub analog_write {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    return analogWrite($pin, $value);
}

# board functions

sub gpio_layout {
    return piGpioLayout();
}
sub wpi_to_gpio {
    shift if @_ == 2;
    my $pin = shift;
    return wpiPinToGpio($pin);
}
sub phys_to_gpio {
    shift if @_ == 2;
    my $pin = shift;
    return physPinToGpio($pin);
}
sub phys_to_wpi {
    shift if @_ == 2;
    my $pin = shift;
    return physPinToWpi($pin);
}
sub pwm_set_range {
    shift if @_ == 2;
    my $range = shift;
    pwmSetRange($range);
}

# lcd functions

sub lcd_init {
    shift if @_ == 27;
    my %params = @_;

    my @required_args = qw(
        rows cols bits rs strb
        d0 d1 d2 d3 d4 d5 d6 d7
    );

    my @args;
    for (@required_args){
        if (! defined $params{$_}) {
            die "\n'$_' is a required param for WiringPi::API::lcd_init()\n";
        }
        push @args, $params{$_};
    }

    my $fd = lcdInit(@args); # LCD handle
    return $fd;
}
sub lcd_home {
    shift if @_ == 2;
    lcdHome($_[0]);
}
sub lcd_clear {
    shift if @_ == 2;
    lcdClear($_[0]);
}
sub lcd_display {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdDisplay($fd, $state);
}
sub lcd_cursor {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdCursor($fd, $state);
}
sub lcd_cursor_blink {
    shift if @_ == 3;
    my ($fd, $state) = @_;
    lcdCursorBlink($fd, $state);
}
sub lcd_send_cmd {
    shift if @_ == 3;
    my ($fd, $cmd) = @_;
    lcdSendCommand($fd, $cmd);
}
sub lcd_position {
    shift if @_ == 4;
    my ($fd, $x, $y) = @_;
    lcdPosition($fd, $x, $y);
}
sub lcd_char_def {
    shift if @_ == 4;
    my ($fd, $index, $data) = @_;
    lcdPuts($fd, "\n");
    my $unsigned_char = pack "C[8]", @$data;
    lcdCharDef($fd, $index, $unsigned_char);
}
sub lcd_put_char {
    shift if @_ == 3;
    my ($fd, $data) = @_;
    lcdPutchar($fd, $data);
}
sub lcd_puts {
    shift if @_ == 3;
    my ($fd, $string) = @_;
    lcdPuts($fd, $string);
}

# ads1115 functions

sub ads1115_setup {
    shift if @_ == 3;
    my ($pin_base, $addr) = @_;

    return ads1115Setup($pin_base, $addr);
}

# shift register functions

sub shift_reg_setup {
    shift if @_ == 6;
    my ($pin_base, $num_pins, $data_pin, $clock_pin, $latch_pin) = @_;

    die "\$pin_base must be an integer\n" if $pin_base !~ /^\d+$/;

    if ($num_pins < 0 && $num_pins > 32){
        die "\$num_pins must be between 0 and 32\n"     
    }

    for ($data_pin, $clock_pin, $latch_pin){
        if ($_ < 0 && $_ > 40){
            die "$data_pin, $clock_pin and $latch_pin must all be valid " .
                "GPIO pin numbers\n";
        }
    }

    sr595Setup($pin_base, $num_pins, $data_pin, $clock_pin, $latch_pin);
}

# I2C functions

sub i2c_setup {
    shift if @_ == 2;
    my ($addr) = @_;

    if ($addr !~ /^\d$/){
        die "address param must be an integer\n";
    }

    # file descriptor

    return wiringPiI2CSetup($addr);
}
sub i2c_interface {
    die "i2c_interface() is not available at this time\n";
}
sub i2c_read {
    shift if @_ > 1;
    my ($fd) = @_;

    if (! defined $fd){
        die "i2c_read() requires an \$fd param\n";
    }

    return wiringPiI2CRead($fd);
}
sub i2c_read_byte {
    shift if @_ > 2;
    my ($fd, $reg) = @_;

    if (! defined $fd){
        die "i2c_read_byte() requires an \$fd param\n";
    }
    if (! defined $reg){
        die "i2c_read_byte() requires a \$register param\n";
    }

    return wiringPiI2CReadReg8($fd, $reg);
}
sub i2c_read_word {
    shift if @_ > 2;
    my ($fd, $reg) = @_;

    if (! defined $fd){
        die "i2c_read_word() requires an \$fd param\n";
    }
    if (! defined $reg){
        die "i2c_read_word() requires a \$register param\n";
    }

    return wiringPiI2CReadReg8($fd, $reg);
}
sub i2c_write {
    shift if @_ > 2;
    my ($fd, $data) = @_;

    if (! defined $fd){
        die "i2c_write() requires an \$fd param\n";
    }
    if (! defined $data){
        die "i2c_write() requires a \$data param\n";

    }
    return wiringPiI2CWrite($fd, $data);
}
sub i2c_write_byte {
    shift if @_ > 3;
    my ($fd, $reg, $data) = @_;

    if (! defined $fd){
        die "i2c_write_byte() requires an \$fd param\n";
    }
    if (! defined $reg){
        die "i2c_write_byte() requires a \$register param\n";
    }
    if (! defined $data){
        die "i2c_write_byte() requires a \$data param\n";
    }

    return wiringPiI2CWriteReg8($fd, $reg);
}
sub i2c_write_word {
    shift if @_ > 3;
    my ($fd, $reg, $data) = @_;

    if (! defined $fd){
        die "i2c_write_word() requires an \$fd param\n";
    }
    if (! defined $reg){
        die "i2c_write_word() requires a \$register param\n";
    }
    if (! defined $data){
        die "i2c_write_word() requires a \$data param\n";
    }

    return wiringPiI2CWriteReg16($fd, $reg);
}

# SPI functions

sub spi_setup {
    shift if @_ == 3;
    my ($channel, $speed) = @_;

    if ($channel != 0 && $channel != 1){
        die "spi_setup() channel param must be 0 or 1\n";
    }

    $speed = 1000000 if ! defined $speed;

    return wiringPiSPISetup($channel, $speed);
}
sub spi_data {
    shift if @_ == 4;
    my ($chan, $data, $len) = @_;

    if ($chan != 0 && $chan != 1){
        die "spi_data() channel param must be 0 or 1\n";
    }

    if (ref $data ne 'ARRAY'){
        die "spi_data() data param must be an array reference\n";
    }
    if (@$data != $len){
        die "spi_data() array reference must have \$len param count\n";
    }

    my $buf;

    for (@$data){
        push @$buf, $_;
    }

    return spiDataRW($chan, $buf, $len);
}

# bmp180 pressure sensor functions

sub bmp180_setup {
    shift if @_ == 2;
    my $base = shift;

    if (! defined $base || $base !~ /^\d+$/){
        die "bmp180 setup parametermust be an integer\n";
    }

    bmp180Setup($base);
}
sub bmp180_temp {
    shift if ref $_[0];
    my ($pin, $want) = @_;

    $want = 'f' if ! defined $want;
    
    my $temp = bmp180Temp($pin);
    my $c = $temp / 10;

    if ($want eq 'f'){
        # returning farenheit
        return $c * 1.8 + 32;
    }
    else {
        # returning celcius
        return $c;
    }
}
sub bmp180_pressure {
    shift if ref $_[0];
    my ($pin) = @_;

    # return kPa
    return bmp180Pressure($pin) / 100;
}
sub _vim{1;};

1;
__END__

=head1 NAME

WiringPi::API - API for wiringPi, providing access to the Raspberry Pi's board,
GPIO and connected peripherals

=head1 SYNOPSIS

No matter which import option you choose, before you can start making calls,
you must initialize the software by calling one of the C<setup*()> routines.

    use WiringPi::API qw(:all)

    # use as a base class with OO functionality

    use parent 'WiringPi::API';

    # use in the traditional Perl OO way

    use WiringPi::API;

    my $api = WiringPi::API->new;

=head1 DESCRIPTION

This is an XS-based module, and requires L<wiringPi|http://wiringpi.com> version
2.36+ to be installed. The C<wiringPiDev> shared library is also required (for
the LCD functionality), but it's installed by default with C<wiringPi>.

See the documentation on the L<wiringPi|http://wiringpi.com> website for a more
in-depth description of most of the functions it provides. Some of the
functions we've wrapped are not documented, they were just selectively plucked
from the C code itself. Each mapped function lists which C function it is
responsible for.

=head1 EXPORT_OK

Exported with the C<:all> tag, or individually.

Perl wrapper functions for the XS functions. Not all of these are direct
wrappers; several have additional/modified functionality than the wrapped
versions, but are still 100% compatible.

    setup           setup_sys       setup_phys          setup_gpio 
    pull_up_down    read_pin        write_pin           pwm_write
    get_alt         gpio_layout     wpi_to_gpio         phys_to_gpio
    pwm_set_range   lcd_init        lcd_home            lcd_clear
    lcd_display     lcd_cursor      lcd_cursor_blink    lcd_send_cmd
    lcd_position    lcd_char_def    lcd_put_char        lcd_puts
    set_interrupt   soft_pwm_create soft_pwm_write      soft_pwm_stop
    shift_reg_setup pin_mode        analog_read         analog_write
    bmp180_setup    bmp180_pressure bmp180_temp         phys_to_wpi
    ads1115_setup   spi_setup       spi_data

=head1 EXPORT_TAGS

See L<EXPORT_OK>

=head2 :all

Exports all available exportable functions.

=head1 FUNCTION TABLE OF CONTENTS

=head2 CORE

See L</CORE FUNCTIONS>.

=head2 BOARD

See L</BOARD FUNCTIONS>.

=head2 LCD

See L</LCD FUNCTIONS>.

=head2 SOFTWARE PWM

See L</SOFT PWM FUNCTIONS>.

=head2 INTERRUPT

See L</INTERRUPT FUNCTIONS>.

=head2 ANALOG TO DIGITAL CONVERTER

See L</ADC FUNCTIONS>.

=head2 SHIFT REGISTER

See L</SHIFT REGISTER FUNCTIONS>.

=head2 I2C

See L</I2C FUNCTIONS>

=head2 SPI

See L</SPI FUNCTIONS>

=head2 BAROMETRIC SENSOR

See L</BMP180 PRESSURE SENSOR FUNCTIONS>.

=head1 CORE FUNCTIONS

=head2 new()

NOTE: After an object is created, one of the C<setup*> methods must be called
to initialize the Pi board.

Returns a new C<WiringPi::API> object.

=head2 setup()

Maps to C<int wiringPiSetup()>

Sets the pin number mapping scheme to C<wiringPi>.

See L<pinout.xyz|https://pinout.xyz/pinout/wiringpi> for a pin number
conversion chart, or on the command line, run C<gpio readall>.

Note that only one of the C<setup*()> methods should be called per program run.

=head2 setup_gpio()

Maps to C<int wiringPiSetupGpio()>

Sets the pin numbering scheme to C<GPIO>.

Personally, this is the setup routine that I always use, due to the GPIO numbers
physically printed right on the Pi board.

=head2 setup_phys()

Maps to C<int wiringPiSetupPhys()>

Sets the pin mapping to use the physical pin position number on the board.

=head2 setup_sys()

Maps to C<int wiringPiSetupSys()>

DEPRECATED.

This function is here for legacy purposes only, to provide non-root user access
to the GPIO. It required exporting the pins manually before use. wiringPi now
uses C</dev/gpiomem> by default, which does not require root level access.

Sets the pin numbering scheme to C<GPIO>.

=head2 pin_mode($pin, $mode)

Maps to C<void pinMode(int pin, int mode)>

Puts the pin in either INPUT or OUTPUT mode.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $mode

Mandatory: C<0> for INPUT, C<1> OUTPUT, C<2> PWM_OUTPUT and C<3> GPIO_CLOCK.

=head2 read_pin($pin);

Maps to C<int digitalRead(int pin)>

Returns the current state (HIGH/on, LOW/off) of a given pin.

Parameters:
    
    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

=head2 write_pin($pin, $state)

Maps to C<void digitalWrite(int pin, int state)>

Sets the state (HIGH/on, LOW/off) of a given pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $state

Mandatory: C<1> to turn the pin on (HIGH), and C<0> to turn it LOW (off).

=head2 analog_read($pin);

Maps to C<int analogRead(int pin)>

Returns the data for an analog pin. Note that the Raspberry Pi doesn't have
analog pins, so this is used when connected through an ADC or to pseudo analog
pins.

Parameters:
    
    $pin

Mandatory: The pseudo pin number, in the pin numbering scheme dictated by
whichever C<setup*()> routine you used.

=head2 analog_write($pin, $value)

Maps to C<void analogWrite(int pin, int value)>

Writes the value to the corresponding analog pseudo pin.

Parameters:

    $pin

Mandatory: The pseudo pin number, in the pin numbering scheme dictated by
whichever C<setup*()> routine you used.

    $value

Mandatory: The data which you want to write to the pseudo pin. 

=head2 pull_up_down($pin, $direction)

Maps to C<void pullUpDnControl(int pin, int pud)>

Enable/disable the built-in pull up/down resistors for a specified pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $direction

Mandatory: C<2> for UP, C<1> for DOWN and C<0> to disable the resistor.

=head2 pwm_write($pin, $value)

Maps to C<void pwmWrite(int pin, int value)>

Sets the Pulse Width Modulation duty cycle (on-time) of the pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $value

Mandatory: C<0> to C<1023>. C<0> is 0% (off) and C<1023> is 100% (fully on).

=head2 get_alt($pin)

Maps to C<int getAlt(int pin)>

This returns the current mode of the pin (using C<getAlt()> C call). Modes are
INPUT C<0>, OUTPUT C<1>, PWM_OUT C<2> and CLOCK C<3>.

Parameters:
    
    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

=head1 BOARD FUNCTIONS

=head2 gpio_layout()

Maps to C<int piGpioLayout()>

Returns the Raspberry Pi board's GPIO layout (ie. the board revision).

=head2 wpi_to_gpio($pin_num)

Maps to C<int wpiPinToGpio(int pin)>

Converts a C<wiringPi> pin number to the Broadcom (GPIO) representation, and
returns it.

Parameters:

    $pin_num

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

=head2 phys_to_gpio($pin_num)

Maps to C<int physPinToGpio(int pin)>

Converts the pin number on the physical board to the C<GPIO> representation,
and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

=head2 phys_to_wpi($pin_num)

Maps to C<int physPinToWpi(int pin)>

Converts the pin number on the physical board to the C<wiringPi> numbering
representation, and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

=head2 pwm_set_range($range);

Maps to C<void pwmSetRange(int range)>

Sets the range register of the Pulse Width Modulation (PWM) functionality. It
defaults to C<1024> (C<0-1023>).

Parameters:

    $range

Mandatory: An integer between C<0> and C<1023>.

=head1 LCD FUNCTIONS

There are several methods to drive standard Liquid Crystal Displays. See
L<wiringPiDev LCD page|http://wiringpi.com/dev-lib/lcd-library/> for full
details.

=head2 lcd_init(%args)

Maps to:

    int lcdInit(
        rows, cols, bits, rs, strb,
        d0, d1, d2, d3, d4, d5, d6, d7
    );

Initializes the LCD library, and returns an integer representing the handle
(file descriptor) of the device.

Parameters:

    %args = (
        rows => $num,       # number of rows. eg: 2 or 4
        cols => $num,       # number of columns. eg: 16 or 20
        bits => 4|8,        # width of the interface (4 or 8)
        rs => $pin_num,     # pin number of the LCD's RS pin
        strb => $pin_num,   # pin number of the LCD's strobe (E) pin
        d0 => $pin_num,     # pin number for LCD data pin 1
        ...
        d7 => $pin_num,     # pin number for LCD data pin 8
    );

Mandatory: All entries must have a value. If you're only using four (4) bit
width, C<d4> through C<d7> must be set to C<0>.

Note: When in 4-bit mode, the C<d0> through C<3> parameters actually map to
pins C<d4> through C<d7> on the LCD board, so you need to connect those pins
to their respective selected GPIO pins.

=head2 lcd_home($fd)

Maps to C<void lcdHome(int fd)>

Moves the LCD cursor to the home position (top row, leftmost column).

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

=head2 lcd_clear($fd)

Maps to C<void lcdClear(int fd)>

Clears the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

=head2 lcd_display($fd, $state)

Maps to C<void lcdDisplay(int fd, int state)>

Turns the LCD display on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $state

Mandatory: C<0> to turn the display off, and C<1> for on.

=head2 lcd_cursor($fd, $state)

Maps to C<void lcdCursor(int fd, int state)>

Turns the LCD cursor on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $state

Mandatory: C<0> to turn the cursor off, C<1> for on.

=head2 lcd_cursor_blink($fd, $state)

Maps to C<void lcdCursorBlink(int fd, int state)>

Allows you to enable/disable a blinking cursor.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $state

Mandatory: C<0> to turn the cursor blink off, C<1> for on. Default is off
(C<0>).

=head2 lcd_send_cmd($fd, $command)

Maps to C<void lcdSendCommand(int fd, char command)>

Sends any arbitrary command to the LCD.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $command

Mandatory: A command to submit to the LCD.

=head2 lcd_position($fd, $x, $y)

Maps to C<void lcdPosition(int fd, int x, int y)>

Moves the cursor to the specified position on the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $x

Mandatory: Column position. C<0> is the left-most edge.

    $y

Mandatory: Row position. C<0> is the top row.

=head2 lcd_char_def($fd, $index, $data)

Maps to C<void lcdCharDef(int fd, unsigned char data [8])>. This function is

This allows you to re-define one of the 8 user-definable characters in the
display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $index

Mandatory: Index of the display character. Values are C<0-7>. Once the char
is stored at this index, it can be used at any time with the C<lcd_put_char()>
function.

    $data

Mandatory: Array reference of exactly 8 elements. Each element is a single
unsigned char byte. These bytes represent the character from the top-line to
the bottom line. 

Note that the characters are actually 5 x 8, so only the lower 5 bits are of
each element are used (ie. `0b11111` or 0b00011111`). The index is from 0 to 7
and you can subsequently print the character defined using the lcdPutchar()
call using the same index sent in to this function.

=head2 lcd_put_char($fd, $char)

Maps to C<void lcdPutChar(int fd, unsigned char data)>

Writes a single ASCII character to the LCD display, at the current cursor
position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $char

Mandatory: The character byte to print to the LCD. Note that 0-7 are reserved
for custom characters, as defined with C<lcd_char_def()>. To print one of your
custom chars, C<$char> should be the same integer of the C<$index> you used to
store it in that function.

=head2 lcd_puts($fd, $string)

Maps to C<void lcdPuts(int fd, char *string)>

Writes a string to the LCD display, at the current cursor position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by C<lcd_init()>.

    $string

Mandatory: A string to display.

=head1 SOFT PWM FUNCTIONS

Note: The software PWM functionality is experimental, and from what I've
tested, not very reliable, so I'd stay away from this at this time.

Software Pulse Width Modulation is not the same as hardware PWM. It should not
be used for critical things as it's frequency isn't 100% stable.

This software PWM allows you to use PWM on ANY GPIO pin, not just the single
hardware pin available.

=head2 soft_pwm_create($pin, $initial_value, $range)

Creates a new software PWM thread that runs outside of your main application.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $initial_value

Optional: A value between C<0> and C<$range>.

    $range

Optional: Look at this like a dial. We start at C<0> and the dial has turned
completely when we hit the C<$range> integer. If not sent in, defaults to
C<1023>.

=head2 soft_pwm_write($pin, $value)

Sets the C<HIGH> frequency on C<pin> to whatever is in C<$value>. The value must
be lower than what was set in the C<$range> parameter to C<soft_pwm_create()>.

=head2 soft_pwm_stop($pin)

Turns off software PWM on the C<$pin>.

=head1 INTERRUPT FUNCTIONS

=head2 set_interrupt($pin, $edge, $callback)

IMPORTANT: The interrupt functionality requires that your Perl can be used
in pthreads. If you do not have a threaded Perl, the program will cause a
segmentation fault.

Wrapper around wiringPi's C<wiringPiISR()> that allows you to send in the name
of a Perl sub in your own code that will be called if an interrupt is
triggered.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $edge

Mandatory: C<1> (lowering), C<2> (raising) or C<3> (both).

    $callback

Mandatory: The string name of a subroutine previously written in your user code
that will be called when the interrupt is triggered. This is your interrupt
handler.

=head1 ADC FUNCTIONS

Analog to digital converters (ADC) allow you to read analog data on the
Raspberry Pi, as the Pi doesn't have any analog input pins.

This section is broken down by type/model.

=head2 ADS1115 MODEL

=head3 ads1115_setup($pin_base, $addr)

Maps to `ads1115Setup(int pinBase, int addr)`.

The ADS1115 is a four channel, 16-bit wide ADC.

Parameters:

    $pin_base

Mandatory: Signed integer, higher than that of all GPIO pins. This is the base
number we'll use to access the pseudo pins on the ADC. Example: If C<400> is
sent in, ADC pin C<A0> (or C<0>) will be pin 400, and C<AD3> (the fourth analog
pin) will be 403.

Parameters:

    $addr

Mandatory: Signed integer. This parameter depends on how you have the C<ADDR>
pin on the ADC connected to the Pi. Below is a chart showing if the C<ADDR> pin
is connected to the Pi C<Pin>, you'll get the address. You can also use
C<i2cdetect -y 1> to find out your ADC address.

    Pin     Address
    ---------------
    Gnd     0x48
    VDD     0x49
    SDA     0x4A
    SCL     0x4B

=head1 SHIFT REGISTER FUNCTIONS

Shift registers allow you to add extra output pins by multiplexing a small
number of GPIO.

Currently, we support the SR74HC595 unit, which provides eight outputs by using
only three GPIO. To further, this particular unit can be daisy chained up to
four wide to provide an additional 32 outputs using the same three GPIO pins.

=head2 shift_reg_setup

This function configures the Raspberry Pi to use a shift register (The
SR74HC595 is currently supported).

Parameters:

    $pin_base

Mandatory: Signed integer, higher than that of all existing GPIO pins. This
parameter registers pin 0 on the shift register to an internal GPIO pin number.
For example, setting this to 100, you will be able to access the first output
on the register as GPIO 100 in all other functions.

    $num_pins

Mandatory: Signed integer, the number of outputs on the shift register. For a
single SR74HC595, this is eight. If you were to daisy chain two together, this
parameter would be 16.

    $data_pin

Mandatory: Integer, the GPIO pin number connected to the register's C<DS> pin
(14). Can be any GPIO pin capable of output.

    $clock_pin

Mandatory: Integer, the GPIO pin number connected to the register's C<SHCP> pin
(11). Can be any GPIO pin capable of output.

    $latch_pin

Mandatory: Integer, the GPIO pin number connected to the register's C<STCP> pin
(12). Can be any GPIO pin capable of output.

=head1 I2C FUNCTIONS

These functions allow you to read and write devices on the Inter-Integrated
Circuit (I2C) bus.

=head2 i2c_setup($addr)

Maps to C<int wiringPiI2CSetup(int devId)>

Configures the I2C bus in preparation for communicating with a device.

Parameters:

    $addr

Mandatory: Integer, the address of your device as seen by running for example:
C<i2cdetect -y 1>.

=head2 i2c_interface($device, $addr)

Maps to iC<int wiringPiI2CSetupInterface(const char* device, int devId)>

This feature is not implemented currently, and will be used to select different
I2C interfaces if the RPi ever receives them.

=head2 i2c_read($fd)

Performs a quick one-off, one-byte read without needing to specify the register
value. Some very simple devices operate without register values needed.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

Returns: A single byte of data from the device on the I2C bus.

=head2 i2c_read_byte($fd, $reg)

Reads a single byte from the specified register.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to read data from.

Returns: A single byte of data from the device on the I2C bus from the selected
register.

=head2 i2c_read_word($fd, $reg)

Reads two bytes from the specified register.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to read data from.

Returns: Integer, two bytes of data from the device on the I2C bus from the
selected register.

=head2 i2c_write($fd, $data)

Performs a quick one-off, one-byte write without needing to specify the register
value. Some very simple devices operate without register values needed.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the C<ioctl()> call, C<0> on success.

=head2 i2c_write_byte($fd, $reg, $data)

Writes a single byte to the register specified.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to write the data to.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the C<ioctl()> call, C<0> on success.

=head2 i2c_write_word($fd, $reg, $data)

Writes two bytes to the register specified.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to write the data to.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the C<ioctl()> call, C<0> on success.

=head1 SPI FUNCTIONS

These functions allow you to set up and read/write to devices on the serial
peripheral interface (SPI) bus.

=head2 spi_setup

Maps to C<int wiringPiSPISetup(int channel, int speed)>

Configure the SPI bus for use to communicate with its connected devices.

Parameters:

    $channel

Mandatory: Integer, the SPI channel the device is connected to. C<0> for channel
C</dev/spidev0.0> and C<1> for channel C</dev/spidev0.1>.

    $speed

Optional: Integer, the speed for SPI communication. Defaults to 1000000 (1MHz).

Note that it's wise to do some error checking when attempting to open the SPI
bus. We return the return value of an C<ioctl()> call, so this does the trick:

    if ((spi_setup(0, 1000000) < 0){
        die "failed to open the SPI bus...\n";
    }

=head2 spi_data

Maps to: C<int spiDataRW(int channel, AV* data, int len)>, which calls
C<int wiringPiSPIDataRW(int channel, unsigned char* data, int len)>.

Writes, and then reads a block of data over the SPI bus. The read following the
write is read into the transmit buffer, so it'll be overwritten and sent back
as a Perl array.

Parameters:

    $channel

Mandatory: Integer, the SPI channel the device is connected to. C<0> for channel
C</dev/spidev0.0> and C<1> for channel C</dev/spidev0.1>.

    $data

Mandatory: An array reference, with each element containing a single unsigned
8-bit byte that you want to write to the device. If you want to read-only, send
in an aref with all the elements set to C<0>. These will be overwritten with
the read data, and sent back as a Perl array.

    $len

Mandatory: Integer, the number of bytes contained in the C<$data> parameter
array reference that will be sent to the device. I could just count the number
of elements, but this keeps things consistent, and ensures the user is fully
aware of the data they are sending on the bus.

Returns a Perl array containing the same number of elements you sent in. 

    # read-only... three bytes

    my $buf = [0x00, 0x00, 0x00];

    my @ret = spiDataRW($chan, $buf, 3);

=head1 BMP180 PRESSURE SENSOR FUNCTIONS

These functions configure and fetch data from the BMP180 barometric pressure
sensor.

=head2 bmp180_setup($pin_base)

Configures the system to read from a BMP180 pressure sensor.

These functions can not return the raw values from the sensor. See each
function documentation to learn how to do so.

Parameters:

    $pin_base

Mandatory: Integer, the number at which to place the pseudo analog pins in the 
GPIO stack. For example, if you use C<200>, pin C<200> represents the
temperature feature of the sensor, and C<201> represents the pressure feature.

Return: undef.

=head2 bmp180_temp($pin, $want)

Returns the temperature from the sensor.

Parameters:

    $pin

Mandatory: Integer, represents the C<$pin_base> used in the setup function C<+ 0>.

    $want

Optional: C<'c'> for Celcius, and C<'f'> for Farenheit. Defaults to C<'f'>.

Return: A floating point number in the requested conversion.

NOTE: To get the raw sensor temperature, call the C function 
C<bmp180Temp($pin)> directly.

=head2 bmp180_pressure($pin)

Returns the current air pressure in kPa.

Parameters:

    $pin

Mandatory: Integer, represents the C<$pin_base> used in the setup function C<+ 1>.

Return: A floating point number that represents the air pressure in kPa.

NOTE: To get the raw sensor pressure, call the C function 
C<bmp180Pressure($pin)> directly.

=head1 DEVELOPER FUNCTIONS

These functions are under testing, or don't potentially have a use to the end
user. They may be risky to use, so use at your own risk.

The functions in this section do not have a Perl wrapper equivalent.

=head2 pseudoPinsSetup(int pinBase)

This function allocates shared memory for the pseudo pins used to communicate
with devices that are beyond the reach of the Pi's GPIO (eg: shift registers,
ADCs etc).

Parameters:

    pinBase

Mandatory: Integer, larger than the highest GPIO pin number. Eg: C<500> will be
the base for the analog pins on an ADS1115 ADC. Pin C<A0> would be C<500>, and
ADC pin C<A3> would be C<503>.

=head2 pinModeAlt(int pin, int mode)

Undocumented function that allows any pin to be set to any mode.

Parameters:

    pin

Mandatory: Signed integer, any valid GPIO pin number.

    mode

Mandatory: Signed integer, any valid wiringPi pin mode.

=head2 digitalWriteByte(const int value)

Writes an 8-bit byte to the first eight GPIO pins.

Parameters:

    value

Mandatory: Unsigned int, the byte value you want to send in.

Return: void

=head2 digitalWriteByte2(const int value)

Same as L</digitalWriteByte(const int value)>, but writes to the second group
of eight GPIO pins.

=head2 digitalReadByte()

Reads an 8-bit byte from the first eight GPIO pins on the Pi.

Takes no parameters, returns the byte value as an unsigned int.

=head2 digitalReadByte2()

Same as L</digitalReadByte>, but reads from the second group of eight GPIO pins.

head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

