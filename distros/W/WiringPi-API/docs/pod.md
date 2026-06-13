# TABLE OF CONTENTS

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [EXAMPLES](#examples)
  - [Output - blink an LED](#output---blink-an-led)
  - [Input - read a button](#input---read-a-button)
  - [Background interrupt - blink an LED on each button press](#background-interrupt---blink-an-led-on-each-button-press)
- [DESCRIPTION](#description)
- [EXPORT_OK](#export_ok)
- [EXPORT_TAGS](#export_tags)
  - [:all](#all)
  - [:perl](#perl)
  - [:wiringPi](#wiringpi)
  - [:constants](#constants)
- [FUNCTION TABLE OF CONTENTS](#function-table-of-contents)
  - [CORE](#core)
  - [BOARD](#board)
  - [LCD](#lcd)
  - [INTERRUPT](#interrupt)
  - [CONCURRENCY / BACKGROUND WORKERS](#concurrency--background-workers)
  - [ANALOG TO DIGITAL CONVERTER](#analog-to-digital-converter)
  - [SHIFT REGISTER](#shift-register)
  - [SERIAL](#serial)
  - [I2C](#i2c)
  - [SPI](#spi)
  - [BAROMETRIC SENSOR](#barometric-sensor)
- [CORE FUNCTIONS](#core-functions)
  - [new()](#new)
  - [setup()](#setup)
  - [setup_gpio()](#setup_gpio)
  - [wiringpi_setup_pin_type($pin_type)](#wiringpi_setup_pin_typepin_type)
  - [wiringpi_setup_gpio_device($pin_type)](#wiringpi_setup_gpio_devicepin_type)
  - [wiringpi_gpio_device_get_fd()](#wiringpi_gpio_device_get_fd)
  - [wiringpi_version()](#wiringpi_version)
  - [pin_mode($pin, $mode)](#pin_modepin-mode)
  - [pin_mode_alt($pin, $alt)](#pin_mode_altpin-alt)
    - [Raspberry Pi 5 (RP1) differences](#raspberry-pi-5-rp1-differences)
  - [read_pin($pin);](#read_pinpin)
  - [write_pin($pin, $state)](#write_pinpin-state)
  - [analog_read($pin);](#analog_readpin)
  - [analog_write($pin, $value)](#analog_writepin-value)
  - [pull_up_down($pin, $direction)](#pull_up_downpin-direction)
  - [pwm_write($pin, $value)](#pwm_writepin-value)
  - [get_alt($pin)](#get_altpin)
  - [digital_read_byte()](#digital_read_byte)
  - [digital_read_byte2()](#digital_read_byte2)
  - [digital_write_byte($value)](#digital_write_bytevalue)
  - [digital_write_byte2($value)](#digital_write_byte2value)
- [BOARD FUNCTIONS](#board-functions)
  - [gpio_layout()](#gpio_layout)
  - [wpi_to_gpio($pin_num)](#wpi_to_gpiopin_num)
  - [phys_to_gpio($pin_num)](#phys_to_gpiopin_num)
  - [phys_to_wpi($pin_num)](#phys_to_wpipin_num)
  - [pwm_set_range($range)](#pwm_set_rangerange)
  - [pwm_set_clock($divisor)](#pwm_set_clockdivisor)
  - [pwm_set_mode($mode)](#pwm_set_modemode)
- [SOFT PWM FUNCTIONS](#soft-pwm-functions)
  - [soft_pwm_create($pin, $value, $range)](#soft_pwm_createpin-value-range)
  - [soft_pwm_write($pin, $value)](#soft_pwm_writepin-value)
  - [soft_pwm_stop($pin)](#soft_pwm_stoppin)
- [SOFT TONE FUNCTIONS](#soft-tone-functions)
  - [soft_tone_create($pin)](#soft_tone_createpin)
  - [soft_tone_write($pin, $freq)](#soft_tone_writepin-freq)
  - [soft_tone_stop($pin)](#soft_tone_stoppin)
- [THREAD/LOCK FUNCTIONS](#threadlock-functions)
  - [pi_lock($key)](#pi_lockkey)
  - [pi_unlock($key)](#pi_unlockkey)
- [TIMING FUNCTIONS](#timing-functions)
  - [delay($ms)](#delayms)
  - [delay_microseconds($us)](#delay_microsecondsus)
  - [millis()](#millis)
  - [micros()](#micros)
  - [pi_micros64()](#pi_micros64)
  - [pi_hi_pri($priority)](#pi_hi_pripriority)
- [PAD DRIVE / TONE / CLOCK FUNCTIONS](#pad-drive--tone--clock-functions)
  - [set_pad_drive($group, $value)](#set_pad_drivegroup-value)
  - [set_pad_drive_pin($pin, $value)](#set_pad_drive_pinpin-value)
  - [pwm_tone_write($pin, $freq)](#pwm_tone_writepin-freq)
  - [gpio_clock_set($pin, $freq)](#gpio_clock_setpin-freq)
- [BOARD IDENTITY FUNCTIONS](#board-identity-functions)
  - [pi_board_id()](#pi_board_id)
  - [pi_board40_pin()](#pi_board40_pin)
  - [pi_rp1_model()](#pi_rp1_model)
  - [get_pin_mode_alt($pin)](#get_pin_mode_altpin)
  - [wiringpi_global_memory_access()](#wiringpi_global_memory_access)
  - [wiringpi_user_level_access()](#wiringpi_user_level_access)
- [LCD FUNCTIONS](#lcd-functions)
  - [lcd_init(%args)](#lcd_initargs)
  - [lcd_home($fd)](#lcd_homefd)
  - [lcd_clear($fd)](#lcd_clearfd)
  - [lcd_display($fd, $state)](#lcd_displayfd-state)
  - [lcd_cursor($fd, $state)](#lcd_cursorfd-state)
  - [lcd_cursor_blink($fd, $state)](#lcd_cursor_blinkfd-state)
  - [lcd_send_cmd($fd, $command)](#lcd_send_cmdfd-command)
  - [lcd_position($fd, $x, $y)](#lcd_positionfd-x-y)
  - [lcd_char_def($fd, $index, $data)](#lcd_char_deffd-index-data)
  - [lcd_put_char($fd, $char)](#lcd_put_charfd-char)
  - [lcd_puts($fd, $string)](#lcd_putsfd-string)
- [INTERRUPT FUNCTIONS](#interrupt-functions)
  - [set_interrupt($pin, $edge, $callback, $debounce_us)](#set_interruptpin-edge-callback-debounce_us)
  - [dispatch_interrupts()](#dispatch_interrupts)
  - [wait_interrupts($timeout_ms)](#wait_interruptstimeout_ms)
  - [interrupt_fd()](#interrupt_fd)
  - [interrupt_dropped()](#interrupt_dropped)
  - [interrupt_buffer($bytes)](#interrupt_bufferbytes)
  - [run_interrupt_loop($timeout_ms, $max)](#run_interrupt_looptimeout_ms-max)
  - [stop_interrupt_loop()](#stop_interrupt_loop)
  - [last_interrupt()](#last_interrupt)
  - [stop_interrupt($pin)](#stop_interruptpin)
  - [stop_interrupts()](#stop_interrupts)
  - [auto_dispatch_interrupts($bool, $signal)](#auto_dispatch_interruptsbool-signal)
  - [background_interrupt($pin, $edge, $callback, $debounce_us)](#background_interruptpin-edge-callback-debounce_us)
  - [background_interrupts([$pin, $edge, $callback, $debounce_us], ...)](#background_interruptspin-edge-callback-debounce_us-)
    - [Example - single-threaded event loop (any Perl)](#example---single-threaded-event-loop-any-perl)
    - [Example - background handling via fork](#example---background-handling-via-fork)
    - [Example - hands-off in-process handling (auto_dispatch_interrupts)](#example---hands-off-in-process-handling-auto_dispatch_interrupts)
    - [Example - background process (background_interrupt)](#example---background-process-background_interrupt)
- [CONCURRENCY / BACKGROUND WORKERS](#concurrency--background-workers-1)
  - [worker(\&body, \%opts)](#workerbody-opts)
  - [The worker handle](#the-worker-handle)
  - [Periodic sampler handing data back to main](#periodic-sampler-handing-data-back-to-main)
  - [Shared-memory mechanism (opt-in ithread)](#shared-memory-mechanism-opt-in-ithread)
- [ADC FUNCTIONS](#adc-functions)
  - [ADS1115 MODEL](#ads1115-model)
    - [ads1115_setup($pin_base, $addr)](#ads1115_setuppin_base-addr)
- [SHIFT REGISTER FUNCTIONS](#shift-register-functions)
  - [shift_reg_setup](#shift_reg_setup)
- [SERIAL FUNCTIONS](#serial-functions)
  - [serial_open($device, $baud)](#serial_opendevice-baud)
  - [serial_close($fd)](#serial_closefd)
  - [serial_flush($fd)](#serial_flushfd)
  - [serial_data_avail($fd)](#serial_data_availfd)
  - [serial_get_char($fd)](#serial_get_charfd)
  - [serial_put_char($fd, $char)](#serial_put_charfd-char)
  - [serial_puts($fd, $string)](#serial_putsfd-string)
  - [serial_gets($fd, $nbytes)](#serial_getsfd-nbytes)
- [I2C FUNCTIONS](#i2c-functions)
  - [i2c_setup($addr)](#i2c_setupaddr)
  - [i2c_interface($device, $addr)](#i2c_interfacedevice-addr)
  - [i2c_read($fd)](#i2c_readfd)
  - [i2c_read_byte($fd, $reg)](#i2c_read_bytefd-reg)
  - [i2c_read_word($fd, $reg)](#i2c_read_wordfd-reg)
  - [i2c_write($fd, $data)](#i2c_writefd-data)
  - [i2c_write_byte($fd, $reg, $data)](#i2c_write_bytefd-reg-data)
  - [i2c_write_word($fd, $reg, $data)](#i2c_write_wordfd-reg-data)
  - [i2c_read_block($fd, $reg, $size)](#i2c_read_blockfd-reg-size)
  - [i2c_raw_read($fd, $size)](#i2c_raw_readfd-size)
  - [i2c_write_block($fd, $reg, \@bytes)](#i2c_write_blockfd-reg-bytes)
  - [i2c_raw_write($fd, \@bytes)](#i2c_raw_writefd-bytes)
- [SPI FUNCTIONS](#spi-functions)
  - [spi_setup](#spi_setup)
  - [spi_data](#spi_data)
  - [spi_get_fd($channel)](#spi_get_fdchannel)
  - [spi_setup_mode($channel, $speed, $mode)](#spi_setup_modechannel-speed-mode)
  - [spi_close($channel)](#spi_closechannel)
- [BMP180 PRESSURE SENSOR FUNCTIONS](#bmp180-pressure-sensor-functions)
  - [bmp180_setup($pin_base)](#bmp180_setuppin_base)
  - [bmp180_temp($pin, $want)](#bmp180_temppin-want)
  - [bmp180_pressure($pin)](#bmp180_pressurepin)
- [DEVELOPER FUNCTIONS](#developer-functions)
  - [pseudoPinsSetup(int pinBase)](#pseudopinssetupint-pinbase)
  - [pinModeAlt(int pin, int mode)](#pinmodealtint-pin-int-mode)
- [AUTHOR](#author)
- [COPYRIGHT AND LICENSE](#copyright-and-license)

# NAME

WiringPi::API - API for wiringPi, providing access to the Raspberry Pi's board,
GPIO and connected peripherals

# SYNOPSIS

No matter which import option you choose, you must initialize the software
before making any other calls by running one of the `setup*()` routines. That
call also selects the pin-numbering scheme - for example, `setup_gpio()` uses
the BCM GPIO numbers printed on the Pi's board.

    use WiringPi::API qw(:all)

    # use as a base class with OO functionality

    use parent 'WiringPi::API';

    # use in the traditional Perl OO way

    use WiringPi::API;

    my $api = WiringPi::API->new;

# EXAMPLES

These examples import the function set with the `:all` tag (which also brings
in the constants), and call `setup_gpio()` so the pin numbers are the
**BCM GPIO** numbers printed on the Pi's board.

## Output - blink an LED

    use WiringPi::API qw(:all);

    setup_gpio();                  # GPIO (BCM) pin numbering

    pin_mode(17, OUTPUT);          # An LED wired to GPIO17

    for (1..5) {
        write_pin(17, HIGH);       # On
        delay(500);                # Wait 500ms
        write_pin(17, LOW);        # Off
        delay(500);
    }

## Input - read a button

    use WiringPi::API qw(:all);

    setup_gpio();

    pin_mode(27, INPUT);           # A button wired to GPIO27
    pull_up_down(27, PUD_UP);      # Enable the internal pull-up

    # Pressed pulls the pin LOW

    print read_pin(27) ? "Released\n" : "Pressed\n";

## Background interrupt - blink an LED on each button press

A button on GPIO27 arms a handler in its own process; every press blinks an LED
on GPIO17, while the main program is free to do real work - the handler fires
even while main is busy or sleeping:

    use WiringPi::API qw(:all);

    setup_gpio();
    pin_mode(17, OUTPUT);          # LED
    pin_mode(27, INPUT);           # Button
    pull_up_down(27, PUD_UP);

    my $h = background_interrupt(
        27,
        INT_EDGE_FALLING,
        sub {
            for (1 .. 3) {             # blink 3 times per press
                write_pin(17, HIGH);
                delay(100);
                write_pin(17, LOW);
                delay(100);
            }
        }
    );

    for my $i (1..10) {          # Main does its own work meanwhile
        print "Working ($i) ...\n";
        delay(1000);
    }

    $h->stop;                     # Tear down and reap the handler

# DESCRIPTION

This is an XS-based module, and requires [wiringPi](http://wiringpi.com) version
3.18+ to be installed. The `wiringPiDev` shared library is also required (for
the LCD functionality), but it's installed by default with `wiringPi`.

See the documentation on the [wiringPi](http://wiringpi.com) website for a more
in-depth description of most of the functions it provides. Some of the
functions we've wrapped are not documented, they were just selectively plucked
from the C code itself. Each mapped function lists which C function it is
responsible for.

# EXPORT\_OK

Exported with the `:all` tag, or individually.

Perl wrapper functions for the XS functions. Not all of these are direct
wrappers; several have additional/modified functionality than the wrapped
versions, but are still 100% compatible. They are grouped below by purpose;
within each group the names are listed alphabetically, except where a natural
flow (eg. `setup` before its variants, or `lcd_init` before the rest) reads
better.

    Setup

      setup                       setup_gpio
      wiringpi_setup_pin_type     wiringpi_setup_gpio_device
      wiringpi_gpio_device_get_fd wiringpi_version

    Pin

      pin_mode            pin_mode_alt        get_alt
      get_pin_mode_alt    pull_up_down        read_pin
      write_pin           digital_read_byte   digital_read_byte2
      digital_write_byte  digital_write_byte2

    ADC (analog to digital)

      ads1115_setup       analog_read         analog_write

    BMP180 barometric pressure sensor

      bmp180_setup        bmp180_pressure     bmp180_temp

    Board

      gpio_layout         phys_to_gpio        phys_to_wpi
      pi_board40_pin      pi_board_id         pi_rp1_model
      wpi_to_gpio

    Developer

      wiringpi_global_memory_access           wiringpi_user_level_access

    I2C

      i2c_setup           i2c_interface
      i2c_read            i2c_read_byte       i2c_read_word
      i2c_read_block      i2c_raw_read
      i2c_write           i2c_write_byte      i2c_write_word
      i2c_write_block     i2c_raw_write

    Interrupt

      set_interrupt       background_interrupt        background_interrupts
      auto_dispatch_interrupts                        dispatch_interrupts
      wait_interrupts     run_interrupt_loop          stop_interrupt
      stop_interrupts     stop_interrupt_loop         interrupt_fd
      interrupt_buffer    interrupt_dropped           last_interrupt

    LCD

      lcd_init            lcd_char_def        lcd_clear
      lcd_cursor          lcd_cursor_blink    lcd_display
      lcd_home            lcd_position        lcd_put_char
      lcd_puts            lcd_send_cmd

    Pad drive / tone / clock

      gpio_clock_set      pwm_tone_write      set_pad_drive
      set_pad_drive_pin

    PWM

      pwm_set_clock       pwm_set_mode        pwm_set_range
      pwm_write

    Serial

      serial_open         serial_close        serial_data_avail
      serial_flush        serial_get_char     serial_gets
      serial_put_char     serial_puts

    Shift register

      shift_reg_setup

    Soft PWM

      soft_pwm_create     soft_pwm_stop       soft_pwm_write

    Soft tone

      soft_tone_create    soft_tone_stop      soft_tone_write

    SPI

      spi_setup           spi_setup_mode      spi_data
      spi_get_fd          spi_close

    Thread / lock

      pi_lock             pi_unlock

    Timing

      delay_microseconds  pi_hi_pri           pi_micros64

    Worker

      worker

# EXPORT\_TAGS

See ["EXPORT\_OK"](#export_ok)

## :all

Exports all available exportable functions.

## :perl

Export only Perlish snake\_case named version of the functions.

## :wiringPi

Export only the C based camelCase version of the function names.

## :constants

Export only the constants. These (including `WPI_PIN_BCM` / `WPI_PIN_WPI` and
the `INT_EDGE_*` edge triggers) are defined in and re-exported from
[RPi::Const](https://metacpan.org/pod/RPi%3A%3AConst), the single source of truth for constants across the `RPi::`
suite.

# FUNCTION TABLE OF CONTENTS

## CORE

See ["CORE FUNCTIONS"](#core-functions).

## BOARD

See ["BOARD FUNCTIONS"](#board-functions).

## LCD

See ["LCD FUNCTIONS"](#lcd-functions).

## INTERRUPT

See ["INTERRUPT FUNCTIONS"](#interrupt-functions).

## CONCURRENCY / BACKGROUND WORKERS

See ["CONCURRENCY / BACKGROUND WORKERS"](#concurrency-background-workers).

## ANALOG TO DIGITAL CONVERTER

See ["ADC FUNCTIONS"](#adc-functions).

## SHIFT REGISTER

See ["SHIFT REGISTER FUNCTIONS"](#shift-register-functions)

## SERIAL

See ["SERIAL FUNCTIONS"](#serial-functions)

## I2C

See ["I2C FUNCTIONS"](#i2c-functions)

## SPI

See ["SPI FUNCTIONS"](#spi-functions)

## BAROMETRIC SENSOR

See ["BMP180 PRESSURE SENSOR FUNCTIONS"](#bmp180-pressure-sensor-functions).

# CORE FUNCTIONS

## new()

NOTE: After an object is created, one of the `setup*` methods must be called
to initialize the Pi board.

Returns a new `WiringPi::API` object.

## setup()

Maps to `int wiringPiSetup()`

Sets the pin number mapping scheme to `wiringPi`.

See [pinout.xyz](https://pinout.xyz/pinout/wiringpi) for a pin number
conversion chart, or on the command line, run `gpio readall`.

Note that only one of the `setup*()` methods should be called per program run.

## setup\_gpio()

Maps to `int wiringPiSetupGpio()`

Sets the pin numbering scheme to `GPIO`.

Personally, this is the setup routine that I always use, due to the GPIO numbers
physically printed right on the Pi board.

## wiringpi\_setup\_pin\_type($pin\_type)

Maps to `int wiringPiSetupPinType(enum WPIPinType pinType)`

A unified setup routine that takes the pin-numbering scheme as a parameter,
rather than having a separate function per scheme. `$pin_type` must be one of
the exported constants `WPI_PIN_BCM` (equivalent to `setup_gpio()`) or
`WPI_PIN_WPI` (equivalent to `setup()`).

Physical-pin setup (`WPI_PIN_PHYS`) is **not supported** - that constant is not
exported, and passing it (or any other value) causes a `croak`.

## wiringpi\_setup\_gpio\_device($pin\_type)

Maps to `int wiringPiSetupGpioDevice(enum WPIPinType pinType)`

As `wiringpi_setup_pin_type()`, but initialises wiringPi over the GPIO
character-device (libgpiod) interface instead of the legacy `/dev/gpiomem`
memory-mapped path. `$pin_type` takes the same `WPI_PIN_BCM` / `WPI_PIN_WPI`
constants and is validated the same way.

This is offered as an opt-in alternative; the default `setup()` / `setup_gpio()`
routines are unchanged.

## wiringpi\_gpio\_device\_get\_fd()

Maps to `int wiringPiGpioDeviceGetFd()`

Returns the open file descriptor of the GPIO character device, when wiringPi was
initialised via `wiringpi_setup_gpio_device()`.

The pin-type constants `WPI_PIN_BCM` and `WPI_PIN_WPI` are available
individually or via the `:constants` / `:all` export tags.

## wiringpi\_version()

Maps to `void wiringPiVersion(int *major, int *minor)`.

Returns the version of the installed **wiringPi C library** (eg. `3.18`). This
is the underlying library version, **not** the `$VERSION` of this Perl
distribution.

In scalar context, returns the version as a string (eg. `"3.18"`). In list
context, returns the `($major, $minor)` integer pair (eg. `(3, 18)`).

The exported C-level `wiringPiVersion()` always returns the version string.

## pin\_mode($pin, $mode)

Maps to `void pinMode(int pin, int mode)`

Puts the pin in either INPUT, OUTPUT, PWM or GPIO\_CLOCK mode.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $mode

Mandatory: `0` for INPUT, `1` OUTPUT, `2` PWM\_OUTPUT and `3` GPIO\_CLOCK.

## pin\_mode\_alt($pin, $alt)

Maps to the undocumented `void pinModeAlt(int pin, int mode)`

Allows you to set any pin to any mode. ALT modes allowed:

    value   mode
    ------------
    0       INPUT
    1       OUTPUT
    4       ALT0
    5       ALT1
    6       ALT2
    7       ALT3
    3       ALT4
    2       ALT5

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $alt

Mandatory, Integer: The mode you want to put the pin into. See the list above
for the relevant values for this parameter.

### Raspberry Pi 5 (RP1) differences

On the Pi 5 the GPIO is driven by the RP1 chip rather than the Broadcom SoC, and
its alternate-function map is **completely different** from earlier Pis. The
`$alt` **values** above are unchanged - wiringPi remaps them internally - but
what each mode **selects** is not: `ALT0`..`ALT5` route entirely different
peripherals on the Pi 5 than they do on a Pi 0-4. Consult the RP1 datasheet (or
the `pinctrl` tool) for your Pi 5, **not** the BCM2835 ALT tables, to know which
function a given value actually enables.

Two further specifics on the Pi 5:

- `INPUT` (`0`) and `OUTPUT` (`1`) both select the RP1 GPIO (`SYS_RIO`)
function; the in/out direction itself is set separately (eg. via `pin_mode()`),
not by the alt value.
- RP1 adds three more alternate functions - `ALT6`, `ALT7` and `ALT8` (values
`8`, `9` and `10`). These are accepted **only** on a Pi 5; on a Pi 0-4 the
valid range stays `0-7` and passing `8`-`10` croaks. The Pi 5 is detected via
`pi_rp1_model()`, so a `setup*()` routine must have run first.

## read\_pin($pin);

Maps to `int digitalRead(int pin)`

Returns the current state (HIGH/on, LOW/off) of a given pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

## write\_pin($pin, $state)

Maps to `void digitalWrite(int pin, int state)`

Sets the state (HIGH/on, LOW/off) of a given pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $state

Mandatory: `1` to turn the pin on (HIGH), and `0` to turn it LOW (off).

## analog\_read($pin);

Maps to `int analogRead(int pin)`

Returns the data for an analog pin. Note that the Raspberry Pi doesn't have
analog pins, so this is used when connected through an ADC or to pseudo analog
pins.

Parameters:

    $pin

Mandatory: The pseudo pin number, in the pin numbering scheme dictated by
whichever `setup*()` routine you used.

## analog\_write($pin, $value)

Maps to `void analogWrite(int pin, int value)`

Writes the value to the corresponding analog pseudo pin.

Parameters:

    $pin

Mandatory: The pseudo pin number, in the pin numbering scheme dictated by
whichever `setup*()` routine you used.

    $value

Mandatory: The data which you want to write to the pseudo pin. 

## pull\_up\_down($pin, $direction)

Maps to `void pullUpDnControl(int pin, int pud)`

Enable/disable the built-in pull up/down resistors for a specified pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $direction

Mandatory: `2` for UP, `1` for DOWN and `0` to disable the resistor.

## pwm\_write($pin, $value)

Maps to `void pwmWrite(int pin, int value)`

Sets the Pulse Width Modulation duty cycle (on-time) of the pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $value

Mandatory: `0` to `1023`. `0` is 0% (off) and `1023` is 100% (fully on).

## get\_alt($pin)

Maps to `int getAlt(int pin)`

This returns the current mode of the pin (using `getAlt()` C call). Modes are
INPUT `0`, OUTPUT `1`, PWM\_OUT `2` and CLOCK `3`.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

## digital\_read\_byte()

Maps to `unsigned int digitalReadByte()`

Reads all eight bits of the first 8-bit GPIO bank at once and returns the value
as a single integer (`0`-`255`).

**Note:** the byte-bank operations (`digital_read_byte()`,
`digital_read_byte2()`, `digital_write_byte()`, `digital_write_byte2()`) are
**not supported on the Raspberry Pi 5**. On a Pi 5, the underlying wiringPi call
prints a diagnostic and terminates the process.

## digital\_read\_byte2()

Maps to `unsigned int digitalReadByte2()`

As `digital_read_byte()`, but reads the second 8-bit GPIO bank.

## digital\_write\_byte($value)

Maps to `void digitalWriteByte(int value)`

Writes the 8-bit `$value` (`0`-`255`) to the first 8-bit GPIO bank in a
single operation.

Parameters:

    $value

Mandatory: An integer `0`-`255`; each bit is written to the corresponding pin
of the bank.

## digital\_write\_byte2($value)

Maps to `void digitalWriteByte2(int value)`

As `digital_write_byte()`, but writes to the second 8-bit GPIO bank.

# BOARD FUNCTIONS

## gpio\_layout()

Maps to `int piGpioLayout()`

Returns the Raspberry Pi board's GPIO layout (ie. the board revision).

## wpi\_to\_gpio($pin\_num)

Maps to `int wpiPinToGpio(int pin)`

Converts a `wiringPi` pin number to the Broadcom (GPIO) representation, and
returns it.

Parameters:

    $pin_num

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

## phys\_to\_gpio($pin\_num)

Maps to `int physPinToGpio(int pin)`

Converts the pin number on the physical board to the `GPIO` representation,
and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

## phys\_to\_wpi($pin\_num)

Maps to `int physPinToWpi(int pin)`

Converts the pin number on the physical board to the `wiringPi` numbering
representation, and returns it.

Parameters:

    $pin_num

Mandatory: The pin number on the physical Raspberry Pi board.

Returns: The `wiringPi` pin number, or `-1` if the physical pin has no
`wiringPi` equivalent or `$pin_num` is out of range (less than `0` or
greater than `63`).

## pwm\_set\_range($range)

Maps to `void pwmSetRange(int range)`

Sets the range register of the Pulse Width Modulation (PWM) functionality. It
defaults to `1024` (`0-1023`).

Parameters:

    $range

Mandatory: An unsigned integer specifying the PWM range register. The duty
cycle then spans `0` to one less than this value (the default `1024` gives
`0-1023`).

## pwm\_set\_clock($divisor)

Maps to `void pwmSetClock(int divisor)`.

The PWM clock can be set to control the PWM pulse widths. The PWM clock is
derived from a 19.2MHz clock. You can set any divider.

For example, say you wanted to drive a DC motor with PWM at about 1kHz, and
control the speed in 1/1024 increments from 0/1024 (stopped) through to
1024/1024 (full on). In that case you might set the clock divider to be 16, and
the RANGE to 1024. The pulse repetition frequency will be
1.2MHz/1024 = 1171.875Hz.

Parameters:

    $divisor

Mandatory, Integer: An unsigned integer to set the pulse width to.

## pwm\_set\_mode($mode)

Each PWM channel can run in either Balanced or Mark-Space mode. In Balanced
mode, the hardware sends a combination of clock pulses that results in an
overall DATA pulses per RANGE pulses. In Mark-Space mode, the hardware sets the
output HIGH for DATA clock pulses wide, followed by LOW for RANGE-DATA clock
pulses.

Parameters:

    $mode

Mandatory, Integer: `0` for Mark-Space mode, or `1` for Balanced mode.

Note: If using [RPi::WiringPi::Const](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AConst), you can use `PWM_MODE_MS` or
`PWM_MODE_BAL`.

# SOFT PWM FUNCTIONS

Software-driven PWM on any GPIO pin. See
[wiringPi softPwm page](http://wiringpi.com/reference/software-pwm-library/).

## soft\_pwm\_create($pin, $value, $range)

Maps to `int softPwmCreate(int pin, int value, int range)`

Creates a software-controlled PWM pin. Returns `0` on success.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $value

Mandatory: The initial duty-cycle value, between `0` and `$range`.

    $range

Mandatory: The PWM range (a typical value is `100`).

## soft\_pwm\_write($pin, $value)

Maps to `void softPwmWrite(int pin, int value)`

Updates the PWM duty-cycle value on a pin previously set up with
`soft_pwm_create()`.

Parameters:

    $pin

Mandatory: The pin number.

    $value

Mandatory: The new duty-cycle value, between `0` and the range the pin was
created with.

## soft\_pwm\_stop($pin)

Maps to `void softPwmStop(int pin)`

Stops software PWM on the given pin.

Parameters:

    $pin

Mandatory: The pin number.

# SOFT TONE FUNCTIONS

Software-generated tone (square-wave frequency) output on any GPIO pin. See
[wiringPi softTone page](http://wiringpi.com/reference/software-tone-library/).

(Note: wiringPi's `softServo` library is not built into the wiringPi 3.18
shared library and is therefore not wrapped.)

## soft\_tone\_create($pin)

Maps to `int softToneCreate(int pin)`

Sets up a pin for software tone output. Returns `0` on success.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

## soft\_tone\_write($pin, $freq)

Maps to `void softToneWrite(int pin, int freq)`

Sets the frequency (in Hz) of the tone on a pin previously set up with
`soft_tone_create()`. A frequency of `0` stops the tone.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The frequency in Hz.

## soft\_tone\_stop($pin)

Maps to `void softToneStop(int pin)`

Stops the software tone on the given pin.

Parameters:

    $pin

Mandatory: The pin number.

# THREAD/LOCK FUNCTIONS

Mutex locks provided by wiringPi for synchronising access between threads. They
are typically used to serialise shared state in a `mechanism => 'thread'`
worker - see ["CONCURRENCY / BACKGROUND WORKERS"](#concurrency-background-workers).

## pi\_lock($key)

Maps to `void piLock(int key)`

Acquires the lock identified by `$key`, waiting until it is available.

Parameters:

    $key

Mandatory: The lock number, `0` to `3`.

## pi\_unlock($key)

Maps to `void piUnlock(int key)`

Releases the lock identified by `$key`.

Parameters:

    $key

Mandatory: The lock number, `0` to `3`.

# TIMING FUNCTIONS

wiringPi timing and scheduling helpers. See
[wiringPi timing page](http://wiringpi.com/reference/timing/).

`delay()`, `millis()` and `micros()` are exported under the `:wiringPi` tag
as their native wiringPi names.

## delay($ms)

Maps to `void delay(unsigned int ms)`

Pauses execution for at least `$ms` milliseconds.

## delay\_microseconds($us)

Maps to `void delayMicroseconds(unsigned int us)`

Pauses execution for at least `$us` microseconds.

## millis()

Maps to `unsigned int millis()`

Returns the number of milliseconds elapsed since the program called one of the
`setup*()` routines, as an integer.

## micros()

Maps to `unsigned int micros()`

Returns the number of microseconds elapsed since the program called one of the
`setup*()` routines, as an integer.

## pi\_micros64()

Maps to `unsigned long long piMicros64()`

As `micros()`, but returns a 64-bit microsecond count (does not wrap as
quickly). Requires a 64-bit Perl (`use64bitint`).

## pi\_hi\_pri($priority)

Maps to `int piHiPri(const int pri)`

Attempts to set a high (real-time) scheduling priority for the running program.
Returns `0` on success, `-1` on failure (e.g. insufficient privileges).

Parameters:

    $priority

Mandatory: The priority, `0` (lowest) to `99` (highest).

# PAD DRIVE / TONE / CLOCK FUNCTIONS

## set\_pad\_drive($group, $value)

Maps to `void setPadDrive(int group, int value)`

Sets the drive strength for a group of GPIO pins.

Parameters:

    $group

Mandatory: The pad group (`0`, `1` or `2`).

    $value

Mandatory: The drive strength, `0` to `7`.

## set\_pad\_drive\_pin($pin, $value)

Maps to `void setPadDrivePin(int pin, int value)`

Sets the drive strength for a single GPIO pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $value

Mandatory: The drive strength, `0` to `7`.

## pwm\_tone\_write($pin, $freq)

Maps to `void pwmToneWrite(int pin, int freq)`

Writes a tone of the given frequency (in Hz) to a PWM-capable pin.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The frequency in Hz. A frequency of `0` stops the tone.

## gpio\_clock\_set($pin, $freq)

Maps to `void gpioClockSet(int pin, int freq)`

Sets the output frequency (in Hz) on a GPIO clock pin.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The clock frequency in Hz.

# BOARD IDENTITY FUNCTIONS

## pi\_board\_id()

Maps to `void piBoardId(int *model, int *rev, int *mem, int *maker, int *overVolted)`

Returns identifying information about the board. In list context, returns
`($model, $rev, $mem, $maker, $over_volted)`. In scalar context, returns a hash
reference with keys `model`, `rev`, `mem`, `maker` and `over_volted`. The
values are the integer codes used by wiringPi.

## pi\_board40\_pin()

Maps to `int piBoard40Pin()`

Returns true if the board has the standard 40-pin GPIO header.

## pi\_rp1\_model()

Maps to `int piRP1Model()`

Returns the RP1 model code on boards that use the RP1 I/O controller (e.g. the
Raspberry Pi 5), or a falsey value on boards without one.

## get\_pin\_mode\_alt($pin)

Maps to `enum WPIPinAlt getPinModeAlt(int pin)`

Like `get_alt()`, but returns the pin's current mode as a `WPIPinAlt` enum
value: `-1` (unknown), `0` (input), `1` (output), then the `ALT` modes.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

## wiringpi\_global\_memory\_access()

Maps to `int wiringPiGlobalMemoryAccess()`

Returns a value indicating the level of direct GPIO memory access available to
the current process (`0` if none).

## wiringpi\_user\_level\_access()

Maps to `int wiringPiUserLevelAccess()`

Returns true if user-level (non-root) GPIO access is available (e.g. via
`/dev/gpiomem`).

# LCD FUNCTIONS

There are several methods to drive standard Liquid Crystal Displays. See
[wiringPiDev LCD page](http://wiringpi.com/dev-lib/lcd-library/) for full
details.

## lcd\_init(%args)

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
width, `d4` through `d7` must be set to `0`.

Note: When in 4-bit mode, the `d0` through `3` parameters actually map to
pins `d4` through `d7` on the LCD board, so you need to connect those pins
to their respective selected GPIO pins.

NOTE: There is an upper limit of the number of LCDs that can be initialized
simultaneously. This number is 8 (0-7). Always check the return of this
function to ensure you're under the maximum file descriptors. If you receive a
\`-1\`, you're out of bounds, and any functions called on the LCD will cause a 
segmentation fault.

## lcd\_home($fd)

Maps to `void lcdHome(int fd)`

Moves the LCD cursor to the home position (top row, leftmost column).

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

## lcd\_clear($fd)

Maps to `void lcdClear(int fd)`

Clears the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

## lcd\_display($fd, $state)

Maps to `void lcdDisplay(int fd, int state)`

Turns the LCD display on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $state

Mandatory: `0` to turn the display off, and `1` for on.

## lcd\_cursor($fd, $state)

Maps to `void lcdCursor(int fd, int state)`

Turns the LCD cursor on and off.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $state

Mandatory: `0` to turn the cursor off, `1` for on.

## lcd\_cursor\_blink($fd, $state)

Maps to `void lcdCursorBlink(int fd, int state)`

Allows you to enable/disable a blinking cursor.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $state

Mandatory: `0` to turn the cursor blink off, `1` for on. Default is off
(`0`).

## lcd\_send\_cmd($fd, $command)

Maps to `void lcdSendCommand(int fd, char command)`

Sends any arbitrary command to the LCD.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $command

Mandatory: A command to submit to the LCD.

## lcd\_position($fd, $x, $y)

Maps to `void lcdPosition(int fd, int x, int y)`

Moves the cursor to the specified position on the LCD display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $x

Mandatory: Column position. `0` is the left-most edge.

    $y

Mandatory: Row position. `0` is the top row.

## lcd\_char\_def($fd, $index, $data)

Maps to `void lcdCharDef(int fd, unsigned char data [8])`.

This allows you to re-define one of the 8 user-definable characters in the
display.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $index

Mandatory: Index of the display character. Values are `0-7`. Once the char
is stored at this index, it can be used at any time with the `lcd_put_char()`
function.

    $data

Mandatory: Array reference of exactly 8 elements. Each element is a single
unsigned char byte. These bytes represent the character from the top-line to
the bottom line. 

Note that the characters are actually 5 x 8, so only the lower 5 bits are of
each element are used (ie. `0b11111` or `0b00011111`). The index is from 0 to 7
and you can subsequently print the character defined using the lcdPutchar()
call using the same index sent in to this function.

## lcd\_put\_char($fd, $char)

Maps to `void lcdPutchar(int fd, unsigned char data)`

Writes a single ASCII character to the LCD display, at the current cursor
position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $char

Mandatory: The character byte to print to the LCD. Note that 0-7 are reserved
for custom characters, as defined with `lcd_char_def()`. To print one of your
custom chars, `$char` should be the same integer of the `$index` you used to
store it in that function.

## lcd\_puts($fd, $string)

Maps to `void lcdPuts(int fd, char *string)`

Writes a string to the LCD display, at the current cursor position.

Parameters:

    $fd

Mandatory: The file descriptor integer returned by `lcd_init()`.

    $string

Mandatory: A string to display.

# INTERRUPT FUNCTIONS

## set\_interrupt($pin, $edge, $callback, $debounce\_us)

Arms an interrupt handler on `$pin`. Maps to wiringPi's `wiringPiISR2()`.

The wiringPi interrupt thread never calls into Perl: when an edge fires it
writes a small event record to an internal pipe (the "self-pipe"). Your
`$callback` runs later, in **your** interpreter, when you service that pipe with
`wait_interrupts()` or `dispatch_interrupts()`. Because Perl is only ever
entered by the interpreter that owns it, this works on **any** Perl - threaded or
not - and the old "interrupts need a threaded Perl or they segfault" caveat no
longer applies.

Arm in the same process that will dispatch. For background handling while your
main program does other work, `fork` a child that arms and dispatches (see the
examples below).

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
`setup*()` routine you used.

    $edge

Mandatory: one of `INT_EDGE_FALLING` (`1`), `INT_EDGE_RISING` (`2`) or
`INT_EDGE_BOTH` (`3`). `INT_EDGE_SETUP` (`0`) is **not** a valid trigger and
is rejected. These constants are importable via the `:constants` or `:all`
tags.

    $callback

Mandatory: A code reference that runs when the interrupt is dispatched. It
receives two arguments: the edge that fired and the event timestamp in
microseconds.

    $debounce_us

Optional: debounce period in microseconds, passed through to `wiringPiISR2()`
(default `0` = no debounce).

    \%opts

Optional: a trailing options hash reference. The only option is `auto_dispatch`:
a true value turns on auto-dispatch (see `auto_dispatch_interrupts()`) as part
of arming, so the callback fires on its own without a dispatch loop. This enables
the **process-wide** switch (it is not selective per pin); a string value picks
the delivery signal, eg `{ auto_dispatch => 'USR1' }`.

Re-arming the same pin is safe - the previous listener is stopped first, so a
second wiringPi thread is never stacked on the pin.

## dispatch\_interrupts()

Non-blocking. Reads every event currently waiting in the self-pipe, runs the
registered callback for each, and returns the number dispatched (`0` if none
were waiting). Never blocks waiting for an edge.

## wait\_interrupts($timeout\_ms)

Blocks until at least one interrupt event is available (or `$timeout_ms`
milliseconds elapse), dispatches all pending events via `dispatch_interrupts()`,
and returns the number dispatched (`0` on timeout). An undefined `$timeout_ms`
blocks indefinitely. The usual single-threaded pattern is:

    wait_interrupts(1000) while 1;

## interrupt\_fd()

Returns the readable file descriptor of the self-pipe (an integer), or `-1`
before any interrupt has been armed. Use this to drive your own `select`/`poll`
loop instead of `wait_interrupts()`; call `dispatch_interrupts()` when it
becomes readable.

## interrupt\_dropped()

Returns the number of interrupt events dropped because the self-pipe was full
when an edge fired (bursts beyond the pipe buffer). Normally `0`; reset by
`stop_interrupts()`.

**Overflow policy.** Edges are FIFO-queued in the kernel pipe (capacity is the
kernel default - typically 64 KiB to 256 KiB - holding thousands of the
fixed-size event records). The wiringPi ISR thread writes each edge with a
**non-blocking** `write()`, so it never stalls. If the pipe is full (your code
isn't draining fast enough - e.g. stuck in a long, non-yielding C/XS call), the
overflowing edges are **dropped, not merged and not blocked**, and each one
increments `interrupt_dropped()` - so loss is never silent. Order is preserved;
no two edges are ever coalesced into one (debounce, via `set_interrupt`'s
`$debounce_us`, is the only mechanism that intentionally collapses edges). If
you see drops, drain faster (`wait_interrupts`/`auto_dispatch_interrupts`),
move handling to its own process (`background_interrupt`), raise the queue size
with `interrupt_buffer()`, or debounce to cut the edge rate.

## interrupt\_buffer($bytes)

Gets or sets the capacity of the interrupt self-pipe (the queue that absorbs
edge bursts before `interrupt_dropped()` starts counting).

With no argument, returns the current capacity in bytes (or the pending request
if no interrupt has been armed yet). With `$bytes`, requests that capacity
(`F_SETPIPE_SZ`) and returns the size the kernel actually granted - it rounds up
to a page and caps at `/proc/sys/fs/pipe-max-size`:

    interrupt_buffer(1 << 20);    # Ask for ~1 MiB of queue
    my $size = interrupt_buffer;  # What we actually got

The request is remembered, so you may set it **before** arming (it is applied when
the pipe is created) and it persists across `stop_interrupts()` - the new pipe
from a later `set_interrupt()` is sized the same way.

## run\_interrupt\_loop($timeout\_ms, $max)

A blocking dispatch loop, so you don't have to write `wait_interrupts(...)
while 1` yourself. It repeatedly calls `wait_interrupts($timeout_ms)` (poll
interval, default 1000 ms) and returns the total number of events dispatched.

It runs until one of:

- `stop_interrupt_loop()` is called - from inside a callback, or from a
signal handler (it only flips a flag, so it is signal-safe);
- `$max` events have been dispatched, if you pass a positive `$max`.

The `$timeout_ms` is just the poll granularity - how often the loop checks the
stop flag - not a run time limit. Arm your interrupts first; if nothing is armed
the loop sleeps the interval rather than spinning.

    set_interrupt(0, INT_EDGE_RISING, sub {
        my ($edge, $ts) = @_;
        stop_interrupt_loop() if done_enough();   # Break out from the callback
    });

    my $count = run_interrupt_loop(1000);          # Blocks, dispatching, until stopped

## stop\_interrupt\_loop()

Breaks out of `run_interrupt_loop()` at the next iteration. Safe to call from a
callback or a signal handler, and a no-op if no loop is running.

## last\_interrupt()

Returns a hash reference describing the most recently **dispatched** interrupt
event, or `undef` if none has been dispatched yet (or since the last
`stop_interrupts()`). The keys are:

    pin       The pin you armed (your numbering scheme - the dispatch key)
    pin_bcm   The BCM gpio that fired
    edge      INT_EDGE_FALLING (1) or INT_EDGE_RISING (2)
    status    wiringPi's statusOK (1 for a real edge on this path)
    ts_us     Edge timestamp, in microseconds

The event is published **before** the callback runs, so a callback - which only
receives `($edge, $ts_us)` - can call `last_interrupt()` to obtain the BCM pin
or status as well. Handy when one shared callback is armed on several pins:

    set_interrupt($pin, INT_EDGE_BOTH, sub {
        my $i = last_interrupt();

        printf(
            "BCM %d went %s\n",
            $i->{pin_bcm},
            $i->{edge} == INT_EDGE_RISING ? "high" : "low"
        );
    });

Returns a fresh copy each call, so mutating it won't affect later reads.

## stop\_interrupt($pin)

Stops the interrupt on `$pin` (`wiringPiISRStop()`) and forgets its callback.

## stop\_interrupts()

Stops every armed interrupt, closes the self-pipe and resets interrupt state.
There is no dispatcher thread to join. A later `set_interrupt()` re-creates the
pipe automatically.

## auto\_dispatch\_interrupts($bool, $signal)

Enables (`1`) or disables (`0`) async auto-dispatch. When enabled, the
interrupt read fd is put into async mode and a signal handler drains and
dispatches pending events, so `set_interrupt()` callbacks fire **automatically
in this process** with no `wait_interrupts()`/`dispatch_interrupts()` loop to
write. Callbacks run at Perl safe points (between ops, and on interrupted
`sleep`/`select`), so they may read and modify your program's variables with
no locking.

The optional `$signal` chooses the delivery signal (default `'IO'`, i.e.
`SIGIO`). Pass a signal name - eg `'USR1'` (`'SIGUSR1'` is also accepted) -
to deliver via that signal instead (wired with `F_SETSIG`), which avoids
clashing with other `SIGIO`/`O_ASYNC` users in your program. The name must be
one Perl knows (it croaks otherwise).

You can call it before or after `set_interrupt()`; arming creates the pipe and
wires it for you. Disabling restores the previous handler for the chosen signal.

Caveats: a long, non-yielding C/XS call defers the callback until it returns
(use `background_interrupt()` if you need it to fire even then); and it claims
a process-global signal - don't enable it on a signal your program already
drives. See the example below.

## background\_interrupt($pin, $edge, $callback, $debounce\_us)

Handles an interrupt in a **background process** with one call: it forks, arms
the interrupt in the child, and runs `$callback` there on each edge while your
main program does whatever it likes - true fire-while-busy, even during long
blocking work. `$callback` receives `($edge, $timestamp_us)`. Arguments are
validated (and croak) **before** forking; `$debounce_us` is optional.

Because the callback runs in a separate process it **cannot** see or change your
main program's variables (use it for independent handlers - drive a pin, log,
notify). Returns a handle:

    my $h = background_interrupt(18, INT_EDGE_RISING, sub { ... });

    $h->stop;        # Signal the child, run its ISR teardown, reap it
    $h->pid;         # The child PID
    $h->running;     # True while the child is alive

`stop` is idempotent (safe to call repeatedly, and after the child has already
exited). A handle going out of scope stops its child, and an `END` block reaps
any still-running background children at exit, so a forgotten `stop` can't leak
a zombie. Needs no threaded Perl. See the example below.

A trailing options hash reference may follow the arguments. The only option is
`results`: when true, a defined value **returned** by `$callback` is shipped
back to the parent, which drains it from the handle:

    my $h = background_interrupt(
        18,
        INT_EDGE_RISING,
        sub {
            my ($edge, $ts_us) = @_;
            return "$edge\@$ts_us"; # Reported to the parent
        },
        { results => 1 }
    );

    while (defined(my $msg = $h->read)) {
        # Non-blocking drain
        print "handler said: $msg\n";
    }

    # $h->fh gives the read filehandle, for select / IO::Select

Without `results` (the default) the handler is fire-and-forget and the common
case stays a one-liner.

## background\_interrupts(\[$pin, $edge, $callback, $debounce\_us\], ...)

Like `background_interrupt()`, but a **single** background child services
**many** pins (instead of one child per pin). Pass one array-ref spec per pin;
all are validated before forking, and the child arms them all and dispatches
every edge from one loop. Returns a handle with the same `stop`/`pid`/
`running`, plus `arm($pin)` and `disarm($pin)`:

    setup_gpio();

    my $h = background_interrupts(
        [17, INT_EDGE_RISING, \&on_button],
        [27, INT_EDGE_BOTH,   \&on_sensor, 5000],   # With debounce
    );

    $h->disarm(27);   # Stop servicing pin 27 (without killing the child)
    $h->arm(27);      # Resume it
    $h->stop;         # Tear down + reap the one child

The callbacks are fixed when the child forks - `fork` cannot carry new code
across - so `arm`/`disarm` only toggle pins that were registered in the
initial call (arming an unregistered pin croaks). Each callback runs in the
child and cannot touch your main program's variables.

The shared-child handle has **no results channel**: calling `$h->read` or
`$h->fh` on it croaks. Routing per-pin return values back through one
multiplexed child is out of scope here - use a per-pin
["background\_interrupt($pin, $edge, $callback, $debounce\_us)"](#background_interrupt-pin-edge-callback-debounce_us) with
`{ results => 1 }` when you need values back from the handler.

### Example - single-threaded event loop (any Perl)

    use WiringPi::API qw(setup_gpio pin_mode set_interrupt wait_interrupts
                         INT_EDGE_RISING);

    setup_gpio();
    pin_mode(18, 0);

    set_interrupt(
        18,
        INT_EDGE_RISING,
        sub {
            my ($edge, $ts_us) = @_;
            print "edge $edge at $ts_us us\n";
        }
    );

    wait_interrupts(1000) while 1;   # Dispatches in THIS process

### Example - background handling via fork

    use WiringPi::API qw(setup_gpio pin_mode set_interrupt wait_interrupts
                         INT_EDGE_RISING);

    setup_gpio();
    pin_mode(18, 0);

    my $pid = fork // die "fork: $!";

    if ($pid == 0) {
        # Child owns + dispatches the interrupt

        set_interrupt(
            18,
            INT_EDGE_RISING,
            sub {
                my ($edge, $ts_us) = @_;
                # ... handle the edge ...
            }
        );

        wait_interrupts(1000) while 1;

        exit 0;
    }

    # Parent is free to do other work; reap $pid at exit

### Example - hands-off in-process handling (auto\_dispatch\_interrupts)

Fire callbacks automatically in your own process, with no dispatch loop. The
callback updates your program's own state (no locking needed):

    use WiringPi::API qw(setup_gpio pin_mode set_interrupt auto_dispatch_interrupts
                         INT_EDGE_RISING);

    setup_gpio();
    pin_mode(18, 0);

    auto_dispatch_interrupts(1);      # Callbacks now fire on their own

    my $count = 0;
    set_interrupt(18, INT_EDGE_RISING, sub { $count++ });

    while (1) {
        # The callback fires between ops & in sleep
        do_main_work();
        print "edges so far: $count\n";
        sleep 1;
    }

### Example - background process (background\_interrupt)

Run an independent handler in its own process - it fires even while main is
blocked in long work. The library owns the fork, the loop and the cleanup:

    use WiringPi::API qw(setup_gpio pin_mode background_interrupt INT_EDGE_RISING);

    setup_gpio();
    pin_mode(18, 0);

    my $h = background_interrupt(0, INT_EDGE_RISING, sub {
        my ($edge, $ts_us) = @_;
        # runs in the background on each rising edge - independent work only
    });

    for (1 .. 10) {
        do_other_work();              # the handler fires on its own meanwhile
        sleep 1;
    }

    $h->stop;                         # stops + reaps the background handler

# CONCURRENCY / BACKGROUND WORKERS

`worker()` runs a piece of code in the background with the least possible user
code: it owns the spawn mechanism, the loop **and** the lifecycle, so your body
carries no `fork`, no `use threads`, no `detach`, no `while (1)` and no
manual cleanup. It is the general-purpose sibling of
["background\_interrupt($pin, $edge, $callback, $debounce\_us)"](#background_interrupt-pin-edge-callback-debounce_us).

This module needs **neither `threads` nor a threaded Perl**: `worker()` is
fork-based by default and works on any Perl. An ithread mechanism is available
as a documented opt-in (see `mechanism` below) for users who specifically want
shared-memory ergonomics on a threaded Perl.

**The setup-once-in-main contract:** call `setup()` (or `setup_gpio()`) and do
your `pin_mode()` calls **once, in the parent, before** starting a worker. A
fork-based worker inherits that state; you drive the pins from inside the body.

The hands-off heartbeat LED - the helper owns the loop and the lifecycle:

    use WiringPi::API qw(setup_gpio pin_mode write_pin worker);

    setup_gpio();
    pin_mode(18, OUTPUT);

    my $w = worker(
        sub {
            write_pin(18, OUTPUT);
            sleep 1;
            write_pin(18, INPUT);
            sleep 1
        }
    );

    # ... main does its own work ...

    $w->stop;   # Idempotent; END reaps if forgotten

## worker(\\&body, \\%opts)

Spawns a background child that runs `\&body` **repeatedly** by default, and
returns a handle (see ["The worker handle"](#the-worker-handle) below). All arguments are validated
**before** spawning, so a bad call croaks immediately rather than failing in the
background.

`\&body` is mandatory and must be a `CODE` reference. `\%opts`, if given,
must be a hash reference. The options are:

- `once => 1`

    Run `\&body` a single time, then the child exits on its own (`$w->running`
    becomes false). Without this, the body loops until the worker is stopped.

- `interval => $secs`

    Pace the loop: sleep `$secs` (a positive number, fractional allowed) between
    passes, so a periodic sampler/blinker needs no `sleep` of its own. The sleep
    wakes early when the worker is stopped, so `$w->stop` stays responsive even
    with a long cadence.

- `results => 1`

    Stream **every** defined value the body returns back to the parent, length-framed
    over an inherited pipe. Drain it with `$w->read` (non-blocking) or select on
    `$w->fh` - identical to `background_interrupt`'s results channel.

    **Size limit:** the drain stays non-blocking only while each record fits one
    atomic pipe write - keep returned values under `PIPE_BUF` (4096 bytes, which
    includes a 4-byte length frame). A larger value can be split across writes, and
    `$w->read` will then block until the remainder of that record arrives.

- `shared => 1`

    Publish the body's return value as a **lossy latest value**: the parent reads the
    most recent value with `$w->value`. The child never blocks on a slow or
    absent reader (a full pipe simply drops the update), so this suits a sampler
    whose intermediate readings don't matter.

    Values larger than `PIPE_BUF` (4096 bytes, including a 4-byte length frame) are
    **dropped** on this channel: a non-blocking write of an oversized frame could be
    truncated and desync the reader, so the writer skips it. This fits the lossy
    contract - if you need every large value intact, use `results` instead.

- `mechanism => 'fork' | 'thread'`

    The spawn mechanism. Defaults to `'fork'` (no threaded Perl required).
    `'thread'` runs the body in an ithread for shared-memory ergonomics; it
    **requires `threads` to be loaded** (`use threads;` before calling `worker()`)
    and croaks with a clear message otherwise. Under `'thread'` the `results` and
    `shared` pipe channels are rejected - share a variable and serialise it with
    ["pi\_lock($key)"](#pi_lock-key) / ["pi\_unlock($key)"](#pi_unlock-key) instead.

## The worker handle

`worker()` returns a handle - `WiringPi::API::Worker` for a fork worker, or
`WiringPi::API::WorkerThread` for a thread worker - with the same shape as the
["background\_interrupt($pin, $edge, $callback, $debounce\_us)"](#background_interrupt-pin-edge-callback-debounce_us) handle:

- `$w->stop`

    Stop the worker and reap it. **Idempotent** - safe to call more than once, and a
    `DESTROY` plus an `END` block reap the worker if you forget, so a missed
    `stop` can't leak a zombie or an orphaned thread.

- `$w->running`

    True while the worker is still alive; false once it has stopped or (for
    `once => 1`) finished its single pass.

- `$w->pid`

    The child's process id for a fork worker, or the thread id (tid) for a thread
    worker.

- `$w->read` / `$w->fh`

    Drain the next streamed value / get the readable filehandle, when the worker was
    started with `results => 1` (otherwise `undef`). On a **thread** worker these
    croak instead - thread mode has no pipe channels (use shared memory with
    [pi_lock($key)](#pi_lockkey) / [pi_unlock($key)](#pi_unlockkey)).

- `$w->value`

    The latest published value, when the worker was started with `shared => 1`
    (otherwise `undef`). On a **thread** worker this croaks for the same reason as
    `$w->read`.

## Periodic sampler handing data back to main

    use WiringPi::API qw(setup_gpio pin_mode analog_read worker);

    setup_gpio();
    pin_mode(18, INPUT);

    # Sample once a second; main only ever wants the latest reading.

    my $w = worker(sub { analog_read(0) }, { interval => 1, shared => 1 });

    while (1) {
        my $latest = $w->value;       # Most recent sample, or undef yet
        # ... act on $latest ...
        sleep 5;
    }

    $w->stop;

## Shared-memory mechanism (opt-in ithread)

On a threaded Perl you can run the body in an ithread instead of a fork, and
share state directly. Serialise access to shared state with the wiringPi mutex
locks (see ["THREAD/LOCK FUNCTIONS"](#thread-lock-functions)):

    use threads;                      # required for mechanism => 'thread'
    use threads::shared;
    use WiringPi::API qw(setup_gpio worker pi_lock pi_unlock);

    setup();

    my $count :shared = 0;

    my $w = worker(
        sub {
            pi_lock(0);
            $count++;
            pi_unlock(0);
            select(undef, undef, undef, 0.1);
        },
        { mechanism => 'thread' }
    );

    # ... main reads $count under the same lock ...

    $w->stop;   # Sets the stop flag and joins the thread

# ADC FUNCTIONS

Analog to digital converters (ADC) allow you to read analog data on the
Raspberry Pi, as the Pi doesn't have any analog input pins.

This section is broken down by type/model.

## ADS1115 MODEL

### ads1115\_setup($pin\_base, $addr)

Maps to \`ads1115Setup(int pinBase, int addr)\`.

The ADS1115 is a four channel, 16-bit wide ADC.

Parameters:

    $pin_base

Mandatory: Signed integer, higher than that of all GPIO pins. This is the base
number we'll use to access the pseudo pins on the ADC. Example: If `400` is
sent in, ADC pin `A0` (or `0`) will be pin 400, and `AD3` (the fourth analog
pin) will be 403.

Parameters:

    $addr

Mandatory: Signed integer. This parameter depends on how you have the `ADDR`
pin on the ADC connected to the Pi. Below is a chart showing if the `ADDR` pin
is connected to the Pi `Pin`, you'll get the address. You can also use
`i2cdetect -y 1` to find out your ADC address.

    Pin     Address
    ---------------
    Gnd     0x48
    VDD     0x49
    SDA     0x4A
    SCL     0x4B

# SHIFT REGISTER FUNCTIONS

Shift registers allow you to add extra output pins by multiplexing a small
number of GPIO.

Currently, we support the SR74HC595 unit, which provides eight outputs by using
only three GPIO. To further, this particular unit can be daisy chained up to
four wide to provide an additional 32 outputs using the same three GPIO pins.

## shift\_reg\_setup

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

Mandatory: Integer, the GPIO pin number connected to the register's `DS` pin
(14). Can be any GPIO pin capable of output.

    $clock_pin

Mandatory: Integer, the GPIO pin number connected to the register's `SHCP` pin
(11). Can be any GPIO pin capable of output.

    $latch_pin

Mandatory: Integer, the GPIO pin number connected to the register's `STCP` pin
(12). Can be any GPIO pin capable of output.

# SERIAL FUNCTIONS

These functions provide basic access to read and write to a serial device.

## serial\_open($device, $baud)

Maps to `int serialOpen(const char *device, const int baud)`

Opens a serial device for read/write access.

Parameters:

    $device

Mandatory, String: The name of the serial device, eg: `/dev/ttyACM0`.

    $baud

Mandatory, Integer: The speed of the serial device. (eg: `9600`).

Return, Integer: The file descriptor of the device.

## serial\_close($fd)

Maps to `void serialClose(const int fd)`

Closes an already open serial device.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

## serial\_flush($fd)

Maps to `serialFlush(const int fd)`

Flushes the serial device's buffer.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

## serial\_data\_avail($fd)

Maps to `serialDataAvail(const int fd)`

Check if there is any data available on the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

## serial\_get\_char($fd)

Maps to `serialGetchar(const int fd)`

Read a single byte from the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

## serial\_put\_char($fd, $char)

Maps to `serialPutchar(const int fd, const unsigned char c)`

Write a single byte to the interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

    $char

Mandatory, Byte: A single byte to write to the serial interface.

## serial\_puts($fd, $string)

Maps to `serialPuts(const int fd, const char* string)`

Write an arbitrary length string to the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

    $string

Mandatory, String: The content to write to the device.

## serial\_gets($fd, $nbytes)

Reads up to `$nbytes` bytes from the serial interface and returns them as a
single string.

The read blocks only until the port's configured read timeout (the `VTIME`
value set by `serial_open()`) elapses, so the returned string may be **shorter**
than `$nbytes` if fewer bytes arrived in time (or the device closed). The
result is binary-safe: embedded `NUL` bytes and trailing whitespace are
preserved exactly as received.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to `serial_open()`.

    $nbytes

Mandatory, Integer: The maximum number of bytes to read. Must be a non-negative
integer.

Returns: A string of the bytes actually read (length `0` to `$nbytes`). Croaks
on a read error.

# I2C FUNCTIONS

These functions allow you to read and write devices on the Inter-Integrated
Circuit (I2C) bus.

## i2c\_setup($addr)

Maps to `int wiringPiI2CSetup(int devId)`

Configures the I2C bus in preparation for communicating with a device.

Parameters:

    $addr

Mandatory: Integer, the address of your device as seen by running for example:
`i2cdetect -y 1`.

## i2c\_interface($device, $addr)

Maps to `int wiringPiI2CSetupInterface(const char* device, int devId)`

Like `i2c_setup()`, but lets you name the I2C device file explicitly (e.g.
`/dev/i2c-1`) instead of relying on the default.

Parameters:

    $device

Mandatory: String, the path to the I2C device file (e.g. `/dev/i2c-1`).

    $addr

Mandatory: Integer, the I2C address of the device.

Returns: Integer, the file descriptor for the device (as `i2c_setup()`).

## i2c\_read($fd)

Performs a quick one-off, one-byte read without needing to specify the register
value. Some very simple devices operate without register values needed.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

Returns: A single byte of data from the device on the I2C bus.

## i2c\_read\_byte($fd, $reg)

Reads a single byte from the specified register.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to read data from.

Returns: A single byte of data from the device on the I2C bus from the selected
register.

## i2c\_read\_word($fd, $reg)

Reads two bytes from the specified register.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to read data from.

Returns: Integer, two bytes of data from the device on the I2C bus from the
selected register.

## i2c\_write($fd, $data)

Performs a quick one-off, one-byte write without needing to specify the register
value. Some very simple devices operate without register values needed.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the `ioctl()` call, `0` on success.

## i2c\_write\_byte($fd, $reg, $data)

Writes a single byte to the register specified.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to write the data to.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the `ioctl()` call, `0` on success.

## i2c\_write\_word($fd, $reg, $data)

Writes two bytes to the register specified.

Parameters:

    $fd

Mandatory: Integer, the file descriptor that was returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to write the data to.

    $data

Mandatory: Integer, the value to write to the device.

Returns: The value of the `ioctl()` call, `0` on success.

## i2c\_read\_block($fd, $reg, $size)

Maps to `int wiringPiI2CReadBlockData(int fd, int reg, uint8_t *values, uint8_t size)`

Reads up to `$size` bytes (max 255) in a single block transaction starting at
register `$reg`.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to read from.

    $size

Mandatory: Integer `0`-`255`, the number of bytes to read.

Returns: A list of the bytes read (its length is the actual count returned by
the device). Croaks on a read error.

## i2c\_raw\_read($fd, $size)

Maps to `int wiringPiI2CRawRead(int fd, uint8_t *values, uint8_t size)`

As `i2c_read_block()`, but reads directly from the device without a register
address.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from `i2c_setup()`.

    $size

Mandatory: Integer `0`-`255`, the number of bytes to read.

Returns: A list of the bytes read. Croaks on a read error.

## i2c\_write\_block($fd, $reg, \\@bytes)

Maps to `int wiringPiI2CWriteBlockData(int fd, int reg, const uint8_t *values, uint8_t size)`

Writes a block of up to 255 bytes in a single transaction starting at register
`$reg`.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from `i2c_setup()`.

    $reg

Mandatory: Integer, the register to write to.

    \@bytes

Mandatory: An array reference of byte values (`0`-`255`), at most 255 elements.

Returns: The value of the underlying call, `0` on success.

## i2c\_raw\_write($fd, \\@bytes)

Maps to `int wiringPiI2CRawWrite(int fd, const uint8_t *values, uint8_t size)`

As `i2c_write_block()`, but writes directly to the device without a register
address.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from `i2c_setup()`.

    \@bytes

Mandatory: An array reference of byte values (`0`-`255`), at most 255 elements.

Returns: The value of the underlying call, `0` on success.

# SPI FUNCTIONS

These functions allow you to set up and read/write to devices on the serial
peripheral interface (SPI) bus.

## spi\_setup

Maps to `int wiringPiSPISetup(int channel, int speed)`

Configure the SPI bus for use to communicate with its connected devices.

Parameters:

    $channel

Mandatory: Integer, the SPI channel the device is connected to. `0` for channel
`/dev/spidev0.0` and `1` for channel `/dev/spidev0.1`.

    $speed

Optional: Integer, the speed for SPI communication. Defaults to 1000000 (1MHz).

Note that it's wise to do some error checking when attempting to open the SPI
bus. We return the return value of an `ioctl()` call, so this does the trick:

    if ((spi_setup(0, 1000000) < 0){
        croak "failed to open the SPI bus...\n";
    }

## spi\_data

Maps to: `int spiDataRW(int channel, AV* data, int len)`, which calls
`int wiringPiSPIDataRW(int channel, unsigned char* data, int len)`.

Writes, and then reads a block of data over the SPI bus. The read following the
write is read into the transmit buffer, so it'll be overwritten and sent back
as a Perl array.

Parameters:

    $channel

Mandatory: Integer, the SPI channel the device is connected to. `0` for channel
`/dev/spidev0.0` and `1` for channel `/dev/spidev0.1`.

    $data

Mandatory: An array reference, with each element containing a single unsigned
8-bit byte that you want to write to the device. If you want to read-only, send
in an aref with all the elements set to `0`. These will be overwritten with
the read data, and sent back as a Perl array.

    $len

Mandatory: Integer, the number of bytes contained in the `$data` parameter
array reference that will be sent to the device. I could just count the number
of elements, but this keeps things consistent, and ensures the user is fully
aware of the data they are sending on the bus.

Returns a Perl array containing the same number of elements you sent in. 

    # read-only... three bytes

    my $buf = [0x00, 0x00, 0x00];

    my @ret = spiDataRW($chan, $buf, 3);

## spi\_get\_fd($channel)

Maps to `int wiringPiSPIGetFd(int channel)`

Returns the open file descriptor for an SPI channel that was previously set up.

Parameters:

    $channel

Mandatory: Integer, `0` or `1`.

## spi\_setup\_mode($channel, $speed, $mode)

Maps to `int wiringPiSPISetupMode(int channel, int speed, int mode)`

As `spi_setup()`, but also selects the SPI mode (clock polarity/phase).

Parameters:

    $channel

Mandatory: Integer, `0` or `1`.

    $speed

Mandatory: Integer, the bus speed in Hz (e.g. `1000000`).

    $mode

Mandatory: Integer `0`-`3`, the SPI mode.

Returns: Integer, the file descriptor on success or `-1` on error.

## spi\_close($channel)

Maps to `int wiringPiSPIClose(const int channel)`

Closes the given SPI channel, releasing its file descriptor.

Parameters:

    $channel

Mandatory: Integer, `0` or `1`.

# BMP180 PRESSURE SENSOR FUNCTIONS

These functions configure and fetch data from the BMP180 barometric pressure
sensor.

## bmp180\_setup($pin\_base)

Configures the system to read from a BMP180 pressure sensor.

These functions can not return the raw values from the sensor. See each
function documentation to learn how to do so.

Parameters:

    $pin_base

Mandatory: Integer, the number at which to place the pseudo analog pins in the 
GPIO stack. For example, if you use `200`, pin `200` represents the
temperature feature of the sensor, and `201` represents the pressure feature.

Return: undef.

## bmp180\_temp($pin, $want)

Returns the temperature from the sensor.

Parameters:

    $pin

Mandatory: Integer, represents the `$pin_base` used in the setup function `+ 0`.

    $want

Optional: `'c'` for Celcius, and `'f'` for Farenheit. Defaults to `'f'`.

Return: A floating point number in the requested conversion.

NOTE: To get the raw sensor temperature, call the C function 
`bmp180Temp($pin)` directly.

## bmp180\_pressure($pin)

Returns the current air pressure in kPa.

Parameters:

    $pin

Mandatory: Integer, represents the `$pin_base` used in the setup function `+ 1`.

Return: A floating point number that represents the air pressure in kPa.

NOTE: To get the raw sensor pressure, call the C function 
`bmp180Pressure($pin)` directly.

# DEVELOPER FUNCTIONS

These functions are under testing, or don't potentially have a use to the end
user. They may be risky to use, so use at your own risk.

Most are called directly by their C name. Where a snake_case Perl wrapper does
exist (e.g. `pin_mode_alt()` for `pinModeAlt`), that wrapper is the
recommended interface.

## pseudoPinsSetup(int pinBase)

This function allocates shared memory for the pseudo pins used to communicate
with devices that are beyond the reach of the Pi's GPIO (eg: shift registers,
ADCs etc).

Parameters:

    pinBase

Mandatory: Integer, larger than the highest GPIO pin number. Eg: `500` will be
the base for the analog pins on an ADS1115 ADC. Pin `A0` would be `500`, and
ADC pin `A3` would be `503`.

## pinModeAlt(int pin, int mode)

Undocumented function that allows any pin to be set to any mode.

The alternate-function map differs between the Broadcom SoC (Pi 0-4) and the RP1
chip on the Pi 5; see ["pin\_mode\_alt($pin, $alt)"](#pin_mode_alt-pin-alt) for the mode values and the
per-SoC differences in what each one selects.

Parameters:

    pin

Mandatory: Signed integer, any valid GPIO pin number.

    mode

Mandatory: Signed integer, any valid wiringPi pin mode.

# AUTHOR

Steve Bertrand, <steveb@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
