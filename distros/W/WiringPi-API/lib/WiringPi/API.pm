package WiringPi::API;  

use strict;
use warnings;

our $VERSION = '3.1802';

use Carp qw(croak);
use Fcntl qw(
    F_GETFL
    F_SETFL
    F_SETOWN
    O_ASYNC
    O_NONBLOCK
    F_GETPIPE_SZ
    F_SETPIPE_SZ
    F_SETSIG
);
use POSIX qw(WNOHANG);
use RPi::Const qw(:all);
use Scalar::Util qw(blessed);

use WiringPi::API::BackgroundInterrupt;
use WiringPi::API::BackgroundInterrupts;
use WiringPi::API::Worker;
use WiringPi::API::WorkerThread;

require XSLoader;
XSLoader::load('WiringPi::API', $VERSION);

use constant {
    INTERRUPT_LOOP_TIMEOUT => 1000,
};

require Exporter;
our @ISA = qw(Exporter);

my @wpi_c_functions = (
    # Setup
    qw(
        wiringPiSetup           wiringPiSetupGpio       wiringPiSetupPinType
        wiringPiSetupGpioDevice wiringPiGpioDeviceGetFd pseudoPinsSetup
        wiringPiVersion
    ),
    # Pin
    qw(
        pinMode                 pinModeAlt              getAlt
        getPinModeAlt           pullUpDnControl         digitalRead
        digitalWrite            digitalWriteByte
    ),
    # ADC (analog to digital)
    qw(
        ads1115Setup            analogRead              analogWrite
    ),
    # BMP180 barometric pressure sensor
    qw(
        bmp180Setup             bmp180Pressure          bmp180Temp
    ),
    # Board
    qw(
        physPinToGpio           physPinToWpi            piBoard40Pin
        piBoardId               piGpioLayout            piRP1Model
        wpiPinToGpio
    ),
    # Developer
    qw(
        wiringPiGlobalMemoryAccess  wiringPiUserLevelAccess
    ),
    # I2C
    qw(
        wiringPiI2CSetup        wiringPiI2CSetupInterface
        wiringPiI2CRead         wiringPiI2CReadReg8     wiringPiI2CReadReg16
        wiringPiI2CReadBlockData                        wiringPiI2CRawRead
        wiringPiI2CWrite        wiringPiI2CWriteReg8    wiringPiI2CWriteReg16
        wiringPiI2CWriteBlockData                       wiringPiI2CRawWrite
    ),
    # Interrupt
    qw(
        wiringPiISRStop
    ),
    # LCD
    qw(
        lcdInit                 lcdCharDef              lcdClear
        lcdCursor               lcdCursorBlink          lcdDisplay
        lcdHome                 lcdPosition             lcdPutchar
        lcdPuts                 lcdSendCommand
    ),
    # Pad drive / tone / clock
    qw(
        gpioClockSet            pwmToneWrite            setPadDrive
        setPadDrivePin
    ),
    # PWM
    qw(
        pwmSetClock             pwmSetMode              pwmSetRange
        pwmWrite
    ),
    # Serial
    qw(
        serialOpen              serialDataAvail         serialFlush
        serialGetchar           serialPutchar           serialPuts
    ),
    # Shift register
    qw(
        sr595Setup
    ),
    # Soft tone
    qw(
        softToneCreate          softToneStop            softToneWrite
    ),
    # SPI
    qw(
        wiringPiSPISetup        wiringPiSPISetupMode    spiDataRW
        wiringPiSPIGetFd        wiringPiSPIClose
    ),
    # Timing
    qw(
        delay                   delayMicroseconds       micros
        millis                  piHiPri                 piMicros64
    ),
);
my @wpi_perl_functions = (
    # Setup
    qw(
        setup                       setup_gpio
        wiringpi_setup_pin_type     wiringpi_setup_gpio_device
        wiringpi_gpio_device_get_fd wiringpi_version
    ),
    # Pin
    qw(
        pin_mode            pin_mode_alt        get_alt
        get_pin_mode_alt    pull_up_down        read_pin
        write_pin           digital_read_byte   digital_read_byte2
        digital_write_byte  digital_write_byte2
    ),
    # ADC (analog to digital)
    qw(
        ads1115_setup       analog_read         analog_write
    ),
    # BMP180 barometric pressure sensor
    qw(
        bmp180_setup        bmp180_pressure     bmp180_temp
    ),
    # Board
    qw(
        gpio_layout         phys_to_gpio        phys_to_wpi
        pi_board40_pin      pi_board_id         pi_rp1_model
        wpi_to_gpio
    ),
    # Developer
    qw(
        wiringpi_global_memory_access           wiringpi_user_level_access
    ),
    # I2C
    qw(
        i2c_setup           i2c_interface
        i2c_read            i2c_read_byte       i2c_read_word
        i2c_read_block      i2c_raw_read
        i2c_write           i2c_write_byte      i2c_write_word
        i2c_write_block     i2c_raw_write
    ),
    # Interrupt
    qw(
        set_interrupt       background_interrupt        background_interrupts
        auto_dispatch_interrupts                        dispatch_interrupts
        wait_interrupts     run_interrupt_loop          stop_interrupt
        stop_interrupts     stop_interrupt_loop         interrupt_fd
        interrupt_buffer    interrupt_dropped           last_interrupt
    ),
    # LCD
    qw(
        lcd_init            lcd_char_def        lcd_clear
        lcd_cursor          lcd_cursor_blink    lcd_display
        lcd_home            lcd_position        lcd_put_char
        lcd_puts            lcd_send_cmd
    ),
    # Pad drive / tone / clock
    qw(
        gpio_clock_set      pwm_tone_write      set_pad_drive
        set_pad_drive_pin
    ),
    # PWM
    qw(
        pwm_set_clock       pwm_set_mode        pwm_set_range
        pwm_write
    ),
    # Serial
    qw(
        serial_open         serial_close        serial_data_avail
        serial_flush        serial_get_char     serial_gets
        serial_put_char     serial_puts
    ),
    # Shift register
    qw(
        shift_reg_setup
    ),
    # Soft PWM
    qw(
        soft_pwm_create     soft_pwm_stop       soft_pwm_write
    ),
    # Soft tone
    qw(
        soft_tone_create    soft_tone_stop      soft_tone_write
    ),
    # SPI
    qw(
        spi_setup           spi_setup_mode      spi_data
        spi_get_fd          spi_close
    ),
    # Thread / lock
    qw(
        pi_lock             pi_unlock
    ),
    # Timing
    qw(
        delay_microseconds  pi_hi_pri           pi_micros64
    ),
    # Worker
    qw(
        worker
    ),
);
my @wpi_constants = @RPi::Const::EXPORT_OK;

our @EXPORT_OK;

@EXPORT_OK = (@wpi_c_functions, @wpi_perl_functions, @wpi_constants);
our %EXPORT_TAGS;

$EXPORT_TAGS{wiringPi} = [@wpi_c_functions];
$EXPORT_TAGS{perl} = [@wpi_perl_functions];
$EXPORT_TAGS{constants} = [@wpi_constants];
$EXPORT_TAGS{all} = [@wpi_c_functions, @wpi_perl_functions, @wpi_constants];

# Valid interrupt edge types

my %VALID_INT_EDGE = map { $_ => 1 } (
    INT_EDGE_FALLING,
    INT_EDGE_RISING,
    INT_EDGE_BOTH,
);

# Interrupt dispatch state (per-interpreter). The callback registry lives here
# in Perl - the wiringPi ISR thread only writes event records to the self-pipe
# (see API.xs); dispatch runs callbacks in whichever interpreter services the fd

my %_interrupt_cb;      # Pin => CODE ref
my $_interrupt_fh;      # Cached read handle (dup of interrupt_fd())
my $_interrupt_fh_fd;   # The fd $_interrupt_fh was opened on
my $_last_interrupt;    # Hashref of the most recently dispatched event

# background_interrupt() state - handles of forked children, reaped at exit

my @_bg_children;

# auto_dispatch_interrupts() state. When enabled, the interrupt read fd is put
# into async (SIGIO) mode and $SIG{IO} drains+dispatches at Perl safe points

my $_auto_dispatch      = 0;    # Is auto-dispatch currently enabled?
my $_auto_dispatch_prev;        # Prior handler for the chosen signal
my $_auto_dispatch_fd;          # The fd we wired O_ASYNC/F_SETOWN onto
my $_auto_dispatch_sig  = 'IO'; # Delivery signal name (default SIGIO)
my $_auto_dispatch_signum;      # Its number (for F_SETSIG; 0 = default SIGIO)

my %_sig_num;                   # Signal name -> number, lazily built

# interrupt_buffer() state. A requested pipe capacity is remembered and applied
# whenever the self-pipe is (re)created, so it can be set before arming

my $_interrupt_buffer_req;      # Requested pipe size in bytes, or undef
my $_interrupt_buffer_fd;       # The fd we last applied the size to

# run_interrupt_loop() state - cleared by stop_interrupt_loop() to break out

my $_run_loop = 0;

sub new {
    return bless {}, shift;
}

# Serial functions

sub serial_open {
    shift if @_ > 2;
    my ($dev_ptr, $baud) = @_;
    my $fd = serialOpen($dev_ptr, $baud);
    croak "Could not open serial device $dev_ptr\n" if $fd == -1;
    return $fd;
}
sub serial_close {
    shift if @_ > 1;
    my ($fd) = @_;
    serialClose($fd);
}
sub serial_flush {
    shift if @_ > 1;
    my ($fd) = @_;
    serialFlush($fd);
}
sub serial_put_char {
    shift if @_ > 2;
    my ($fd, $unsigned_char) = @_;
    serialPutchar($fd, $unsigned_char);
}
sub serial_puts {
    shift if @_ > 2;
    my ($fd, $char) = @_;
    serialPuts($fd, $char);
}
sub serial_data_avail {
    shift if @_ > 1;
    my ($fd) = @_;
    serialDataAvail($fd);
}
sub serial_get_char {
    shift if @_ > 1;
    my ($fd) = @_;
    serialGetchar($fd);
}
sub serial_gets {
    shift if @_ > 2;
    my ($fd, $nbytes) = @_;

    if (! defined $fd) {
        croak "serial_gets() requires the \$fd param";
    }
    if (! defined $nbytes || $nbytes !~ /^\d+$/) {
        croak "serial_gets() requires \$nbytes, and it must be a " .
              "non-negative integer";
    }

    # Returns the exact bytes read (binary-safe); may be shorter than $nbytes if
    # the port's read timeout elapsed first

    return serialGets($fd, $nbytes);
}

# Interrupt functions

sub set_interrupt {
    shift if @_ && blessed($_[0]);

    my ($pin, $edge, $callback, @rest) = @_;

    # An optional trailing options hashref may follow the (optional) debounce.

    my %opts = (@rest && ref $rest[-1] eq 'HASH') ? %{ pop @rest } : ();

    my ($debounce_us) = @rest;

    if (! defined $pin || $pin !~ /^\d+$/) {
        croak "set_interrupt() requires \$pin to be a positive integer";
    }

    if (! defined $edge || ! $VALID_INT_EDGE{$edge}) {
        croak "set_interrupt() \$edge must be INT_EDGE_FALLING (1), " .
              "INT_EDGE_RISING (2) or INT_EDGE_BOTH (3)";
    }

    if (! defined $callback || ref $callback ne 'CODE') {
        croak "set_interrupt() requires \$callback to be a CODE reference";
    }

    $debounce_us = 0 if ! defined $debounce_us;

    if ($debounce_us !~ /^\d+$/) {
        croak "set_interrupt() \$debounce_us must be a non-negative integer";
    }

    # The callback stays in Perl, keyed by the user's pin; the ISR thread only
    # writes {pin, edge, ts} records to the self-pipe. dispatch_interrupts()
    # fans them back out to these callbacks in the consuming interpreter

    $_interrupt_cb{$pin} = $callback;

    my $rv = _arm_interrupt($pin, $edge, $debounce_us);

    # Opt-in: turn on auto-dispatch as part of arming. This enables the
    # process-wide switch (it is not selective per pin); a non-"1" true value
    # (eg 'USR1') picks the delivery signal.

    if ($opts{auto_dispatch} && ! $_auto_dispatch) {
        my $v = $opts{auto_dispatch};
        my $sig = ($v =~ /^[A-Za-z]/) ? $v : undef;
        auto_dispatch_interrupts(1, $sig);
    }

    # Arming lazily creates the self-pipe; apply any pending pipe-size request
    # and (if auto-dispatch is on) wire the (possibly new) read fd for SIGIO

    _apply_interrupt_buffer() if defined $_interrupt_buffer_req;
    _auto_dispatch_apply()    if $_auto_dispatch;

    return $rv;
}
sub dispatch_interrupts {
    shift if @_ == 1;

    my $fh = _interrupt_fh();
    return 0 if ! defined $fh;

    my $dispatched = 0;

    while (1) {
        my $buf = "";
        my $n = sysread($fh, $buf, 24);

        if (! defined $n) {
            next if $!{EINTR};      # Interrupted before any data - retry
            last;                   # EAGAIN (drained) or a real error - stop
        }

        last if $n == 0;            # EOF: all write ends closed
        last if $n != 24;           # Short read (24-byte writes are atomic)

        # Record layout mirrors isr_event_t in API.xs: caller pin, BCM pin,
        # edge, statusOK, timestamp. Keep this in sync with that struct

        my ($pin, $pin_bcm, $edge, $status, $ts_us) = unpack "i I i i q", $buf;

        # Publish the full event before running the callback, so the callback
        # may query last_interrupt() for the BCM pin / status it doesn't get
        # in its ($edge, $ts_us) arguments

        $_last_interrupt = {
            pin     => $pin,
            pin_bcm => $pin_bcm,
            edge    => $edge,
            status  => $status,
            ts_us   => $ts_us,
        };

        my $cb = $_interrupt_cb{$pin};
        $cb->($edge, $ts_us) if $cb;

        $dispatched++;
    }

    return $dispatched;
}
sub wait_interrupts {
    shift if @_ && ref $_[0];

    my ($timeout_ms) = @_;

    my $fh = _interrupt_fh();
    return 0 if ! defined $fh;

    my $rin = "";
    vec($rin, fileno($fh), 1) = 1;

    my $timeout = defined $timeout_ms ? $timeout_ms / 1000 : undef;
    my $nfound = select(my $rout = $rin, undef, undef, $timeout);

    return 0 if ! $nfound || $nfound < 0;   # Timeout or error

    return dispatch_interrupts();
}
sub stop_interrupt {
    shift if @_ == 2;

    my ($pin) = @_;

    if (! defined $pin || $pin !~ /^\d+$/) {
        croak "stop_interrupt() requires \$pin to be a positive integer";
    }

    wiringPiISRStop($pin);
    delete $_interrupt_cb{$pin};

    return 1;
}
sub stop_interrupts {
    shift if @_ == 1;

    stop_interrupt($_) for keys %_interrupt_cb;

    # Drop our cached read dup, then close the C-side pipe (this discards any
    # records still buffered) and reset the dropped counter. A later
    # set_interrupt() lazily re-creates the pipe

    if (defined $_interrupt_fh) {
        close $_interrupt_fh;
        $_interrupt_fh    = undef;
        $_interrupt_fh_fd = undef;
    }

    _close_interrupt_pipe();

    # The fd we wired for SIGIO is gone; a later set_interrupt() re-creates the
    # pipe and (if auto-dispatch is still on) re-wires the new fd. The pipe-size
    # request persists and is re-applied to the new pipe on the next arm

    $_auto_dispatch_fd     = undef;
    $_interrupt_buffer_fd  = undef;

    # Forget the last event - the interrupt subsystem is torn down

    $_last_interrupt = undef;

    return 1;
}
sub last_interrupt {
    shift if @_ == 1;

    return undef if ! defined $_last_interrupt;

    # Return a copy so callers can't mutate our internal state

    return { %$_last_interrupt };
}
sub interrupt_buffer {
    shift if @_ && ref $_[0];

    my ($bytes) = @_;

    my $fh = _interrupt_fh();

    if (! defined $bytes) {
        # Getter: the live pipe capacity, or the pending request if not armed
        return $_interrupt_buffer_req if ! defined $fh;
        return fcntl($fh, F_GETPIPE_SZ, 0);
    }

    # Setter

    if ($bytes !~ /^\d+$/ || $bytes == 0) {
        croak "interrupt_buffer() requires a positive integer size in bytes";
    }

    # Remember it so a (re)created pipe gets the same capacity; the kernel
    # rounds up to a page and caps at /proc/sys/fs/pipe-max-size

    $_interrupt_buffer_req = 0 + $bytes;

    return $_interrupt_buffer_req if ! defined $fh;   # Applied on the next arm

    my $set = fcntl($fh, F_SETPIPE_SZ, $_interrupt_buffer_req);

    if (! defined $set) {
        croak "interrupt_buffer() could not set the pipe size to " .
            "$_interrupt_buffer_req bytes: $!";
    }

    $_interrupt_buffer_fd = fileno($fh);

    return $set;   # The actual size the kernel granted
}
sub run_interrupt_loop {
    shift if @_ && ref $_[0];

    my ($timeout_ms, $max) = @_;

    $timeout_ms = INTERRUPT_LOOP_TIMEOUT if ! defined $timeout_ms;

    if ($timeout_ms !~ /^\d+$/ || $timeout_ms == 0) {
        croak "run_interrupt_loop() \$timeout_ms must be a positive integer";
    }

    if (defined $max && ($max !~ /^\d+$/ || $max == 0)) {
        croak "run_interrupt_loop() \$max must be a positive integer";
    }

    $_run_loop = 1;
    my $total = 0;

    while ($_run_loop) {
        # Nothing armed yet: sleep the poll interval rather than busy-spinning,
        # since wait_interrupts() returns at once when there is no interrupt fd

        if (interrupt_fd() < 0) {
            select undef, undef, undef, $timeout_ms / 1000;
            next;
        }

        $total += wait_interrupts($timeout_ms);

        last if defined $max && $total >= $max;
    }

    $_run_loop = 0;

    return $total;
}
sub stop_interrupt_loop {
    shift if @_ == 1;
    $_run_loop = 0;
    return 1;
}
sub auto_dispatch_interrupts {
    shift if @_ && blessed($_[0]);

    my ($enable, $signal) = @_;

    if (! defined $enable || $enable !~ /^[01]$/) {
        croak "auto_dispatch_interrupts() requires a boolean first argument (0 or 1)";
    }

    if ($enable) {
        return 1 if $_auto_dispatch;

        # Choose the delivery signal (default SIGIO). A different named signal
        # (eg 'USR1') is wired via F_SETSIG so it won't clash with other SIGIO
        # users. 'SIGUSR1' and 'USR1' are both accepted

        $signal = 'IO' if ! defined $signal;
        $signal =~ s/^SIG//;

        my $signum = _signal_number($signal);

        if (! defined $signum) {
            croak "auto_dispatch_interrupts() unknown signal '$signal'";
        }

        # Safe-signal handler: Perl runs it between ops, so the dispatched
        # callbacks touch your variables with no locking. Save the prior
        # handler so disable can restore it

        $_auto_dispatch_sig    = $signal;
        $_auto_dispatch_signum = $signum;
        $_auto_dispatch_prev   = $SIG{$signal};
        $SIG{$signal} = \&dispatch_interrupts;
        $_auto_dispatch = 1;

        # Wire the read fd now if the pipe already exists; otherwise the next
        # set_interrupt() (which creates it) will wire it

        _auto_dispatch_apply();

        return 1;
    }

    return 1 if ! $_auto_dispatch;

    _auto_dispatch_clear();

    if (defined $_auto_dispatch_prev) {
        $SIG{$_auto_dispatch_sig} = $_auto_dispatch_prev;
    }
    else {
        delete $SIG{$_auto_dispatch_sig};
    }

    $_auto_dispatch_prev   = undef;
    $_auto_dispatch_sig    = 'IO';
    $_auto_dispatch_signum = undef;
    $_auto_dispatch        = 0;

    return 1;
}
sub background_interrupt {
    shift if @_ && blessed($_[0]);

    my ($pin, $edge, $callback, @rest) = @_;

    # An optional trailing options hashref may follow the (optional) debounce

    my %opts = (@rest && ref $rest[-1] eq 'HASH') ? %{ pop @rest } : ();
    my ($debounce_us) = @rest;

    # Validate everything BEFORE forking - never fork into a guaranteed failure

    if (! defined $pin || $pin !~ /^\d+$/) {
        croak "background_interrupt() requires \$pin to be a positive integer";
    }

    if (! defined $edge || ! $VALID_INT_EDGE{$edge}) {
        croak "background_interrupt() \$edge must be INT_EDGE_FALLING (1), " .
            "INT_EDGE_RISING (2) or INT_EDGE_BOTH (3)";
    }

    if (! defined $callback || ref $callback ne 'CODE') {
        croak "background_interrupt() requires \$callback to be a CODE reference";
    }

    if (defined $debounce_us && $debounce_us !~ /^\d+$/) {
        croak "background_interrupt() \$debounce_us must be a non-negative integer";
    }

    # Opt-in results channel: ship the callback's defined return value back to
    # the parent over a pipe (B5). Set up before forking so both ends inherit

    my ($res_r, $res_w);

    if ($opts{results}) {
        pipe($res_r, $res_w)
            or croak "background_interrupt() results pipe failed: $!";
    }

    my $pid = fork;
    croak "background_interrupt() fork failed: $!" if ! defined $pid;

    if ($pid == 0) {
        # CHILD: own the interrupt. wiringPi ISR pthreads don't survive fork, so
        # arming MUST happen here, post-fork. TERM runs the ISR teardown + exits

        close $res_r if $res_r;

        $SIG{TERM} = sub {
            stop_interrupt($pin);
            exit 0;
        };

        my $cb = $callback;

        if ($res_w) {
            # Wrap so a defined return value is length-framed up to the parent
            $cb = sub {
                my $ret = $callback->(@_);
                if (defined $ret) {
                    my $payload = "$ret";
                    syswrite $res_w, pack("N", length $payload) . $payload;
                }
                return;
            };
        }

        set_interrupt($pin, $edge, $cb, $debounce_us);
        wait_interrupts(1000) while 1;
        exit 0;
    }

    # PARENT: record the child so $h->stop / the END reaper can clean it up

    close $res_w if $res_w;

    my $handle = WiringPi::API::BackgroundInterrupt->_new($pid, $res_r);
    push @_bg_children, $handle;

    return $handle;
}
sub background_interrupts {
    shift if @_ && blessed($_[0]);

    my @specs = @_;

    if (! @specs) {
        croak "background_interrupts() requires at least one " .
            "[\$pin, \$edge, \$callback, \$debounce_us] spec";
    }

    # Validate every spec BEFORE forking

    for my $spec (@specs) {
        if (ref $spec ne 'ARRAY') {
            croak "background_interrupts() each spec must be an array reference";
        }

        my ($pin, $edge, $cb, $deb) = @$spec;

        if (! defined $pin || $pin !~ /^\d+$/) {
            croak "background_interrupts() each \$pin must be a positive integer";
        }
        if (! defined $edge || ! $VALID_INT_EDGE{$edge}) {
            croak "background_interrupts() each \$edge must be INT_EDGE_FALLING " .
                "(1), INT_EDGE_RISING (2) or INT_EDGE_BOTH (3)";
        }
        if (! defined $cb || ref $cb ne 'CODE') {
            croak "background_interrupts() each \$callback must be a CODE reference";
        }
        if (defined $deb && $deb !~ /^\d+$/) {
            croak "background_interrupts() each \$debounce_us must be a " .
                "non-negative integer";
        }
    }

    # Control pipe: parent -> child arm/disarm commands (one text line each)

    pipe(my $ctrl_r, my $ctrl_w)
        or croak "background_interrupts() control pipe failed: $!";

    my $pid = fork;
    croak "background_interrupts() fork failed: $!" if ! defined $pid;

    if ($pid == 0) {
        # CHILD: arm every spec, then service edges + control commands in one
        # select loop. The callback table is fixed here (fork can't carry new
        # code); the control channel only toggles these known pins

        close $ctrl_w;

        $SIG{TERM} = sub {
            stop_interrupts();
            exit 0;
        };

        my %table;   # pin => [edge, cb, deb]

        for my $spec (@specs) {
            my ($pin, $edge, $cb, $deb) = @$spec;
            $table{$pin} = [$edge, $cb, $deb];
            set_interrupt($pin, $edge, $cb, $deb);
        }

        _background_interrupt_shared_loop($ctrl_r, \%table);
        exit 0;
    }

    # PARENT.

    close $ctrl_r;

    my @pins = map { $_->[0] } @specs;
    my $handle =
        WiringPi::API::BackgroundInterrupts->_new($pid, $ctrl_w, \@pins);
    push @_bg_children, $handle;

    return $handle;
}

sub _apply_interrupt_buffer {
    # Apply a pending pipe-size request to the (possibly newly created) pipe.
    # Best-effort: the explicit interrupt_buffer() setter reports errors; here
    # we only re-apply the remembered size, and skip if already applied.

    my $fh = _interrupt_fh();
    return if ! defined $fh;

    my $fd = fileno($fh);
    return if defined $_interrupt_buffer_fd && $_interrupt_buffer_fd == $fd;

    fcntl($fh, F_SETPIPE_SZ, $_interrupt_buffer_req);
    $_interrupt_buffer_fd = $fd;

    return;
}
sub _auto_dispatch_apply {
    # Put the interrupt read fd into async (SIGIO) mode. No-op until the pipe
    # exists, or if we've already wired this exact fd.

    my $fh = _interrupt_fh();
    return 0 if ! defined $fh;

    my $fd = fileno($fh);
    return 1 if defined $_auto_dispatch_fd && $_auto_dispatch_fd == $fd;

    # Force a purely-numeric owner pid: if $$ has ever been stringified, Perl's
    # fcntl would pass it as a pointer and the kernel reads garbage (ESRCH).
    my $owner = 0 + $$;

    defined fcntl($fh, F_SETOWN, $owner)
        or croak "auto_dispatch_interrupts() F_SETOWN failed: $!";

    # Choose the delivery signal: 0 = the default (SIGIO), otherwise the chosen
    # signal's number so O_ASYNC raises that instead. Force numeric - a string
    # would be passed to fcntl as a pointer (EINVAL).
    my $setsig = ($_auto_dispatch_sig ne 'IO') ? 0 + $_auto_dispatch_signum : 0;
    defined fcntl($fh, F_SETSIG, $setsig)
        or croak "auto_dispatch_interrupts() F_SETSIG failed: $!";

    my $flags = fcntl($fh, F_GETFL, 0);
    defined $flags
        or croak "auto_dispatch_interrupts() F_GETFL failed: $!";

    defined fcntl($fh, F_SETFL, $flags | O_ASYNC)
        or croak "auto_dispatch_interrupts() F_SETFL O_ASYNC failed: $!";

    $_auto_dispatch_fd = $fd;

    # Drain anything that arrived before async delivery was armed.
    dispatch_interrupts();

    return 1;
}
sub _auto_dispatch_clear {
    # Remove async mode from the interrupt read fd, if we wired it.
    return 0 if ! defined $_interrupt_fh;

    my $flags = fcntl($_interrupt_fh, F_GETFL, 0);
    if (defined $flags) {
        fcntl($_interrupt_fh, F_SETFL, $flags & ~O_ASYNC);
    }
    fcntl($_interrupt_fh, F_SETSIG, 0);   # back to the default signal

    $_auto_dispatch_fd = undef;

    return 1;
}
sub _background_interrupt_shared_cmd {
    my ($line, $table) = @_;

    if ($line =~ /^arm (\d+)$/) {
        my $spec = $table->{$1} or return;
        set_interrupt($1, @$spec);
    }
    elsif ($line =~ /^disarm (\d+)$/) {
        stop_interrupt($1);
    }

    return;
}
sub _background_interrupt_shared_loop {
    my ($ctrl, $table) = @_;

    my $cmd_buf = "";

    while (1) {
        my $ifd = interrupt_fd();
        my $cfd = fileno($ctrl);

        my $rin = "";
        vec($rin, $cfd, 1) = 1;
        vec($rin, $ifd, 1) = 1 if $ifd >= 0;

        my $nfound = select(my $rout = $rin, undef, undef, 1);
        next if ! defined $nfound || $nfound <= 0;   # timeout / EINTR

        if (vec($rout, $cfd, 1)) {
            my $got = sysread($ctrl, my $chunk, 4096);
            if (! defined $got) {
                next if $!{EINTR};
                last;                            # read error: shut down
            }
            last if $got == 0;                   # parent closed control: shut down

            $cmd_buf .= $chunk;
            while ($cmd_buf =~ s/^([^\n]*)\n//) {
                _background_interrupt_shared_cmd($1, $table);
            }
        }

        if ($ifd >= 0 && vec($rout, $ifd, 1)) {
            dispatch_interrupts();
        }
    }

    stop_interrupts();
    return;
}
sub _interrupt_fh {
    my $fd = interrupt_fd();
    return undef if $fd < 0;

    # Re-open if the pipe was torn down and re-armed onto a different fd. A dup
    # ("<&") gives us our own fd sharing the pipe's non-blocking description, so
    # closing this handle never closes the C-side interrupt_fd().
    if (! defined $_interrupt_fh || ! defined $_interrupt_fh_fd
        || $_interrupt_fh_fd != $fd) {
        close $_interrupt_fh if defined $_interrupt_fh;
        open($_interrupt_fh, "<&", $fd)
            or croak "could not access the interrupt fd ($fd): $!";
        $_interrupt_fh_fd = $fd;
    }

    return $_interrupt_fh;
}
sub _signal_number {
    my ($name) = @_;

    if (! %_sig_num) {
        require Config;
        my @names = split ' ', $Config::Config{sig_name};
        my @nums  = split ' ', $Config::Config{sig_num};
        @_sig_num{@names} = @nums;
    }

    my $num = $_sig_num{$name};
    return defined $num ? 0 + $num : undef;
}

# Thread / async worker

sub worker {
    shift if @_ && blessed($_[0]);   # drop $self on method calls
    my ($body, $opts) = @_;

    # Validate everything BEFORE forking - never fork into a guaranteed failure.
    if (! defined $body || ref $body ne 'CODE') {
        croak "worker() requires \$body to be a CODE reference";
    }

    if (defined $opts && ref $opts ne 'HASH') {
        croak "worker() \%opts must be a hash reference";
    }

    $opts ||= {};

    if (defined $opts->{interval}
        && ($opts->{interval} !~ /^\d*\.?\d+$/ || $opts->{interval} <= 0)) {
        croak "worker() {interval} must be a positive number of seconds";
    }

    my $mechanism = defined $opts->{mechanism} ? $opts->{mechanism} : 'fork';

    if ($mechanism ne 'fork' && $mechanism ne 'thread') {
        croak "worker() {mechanism} must be 'fork' or 'thread'";
    }

    if ($mechanism eq 'thread') {
        if (! $INC{'threads.pm'}) {
            croak "worker() {mechanism=>'thread'} requires threads to be " .
                "loaded; add 'use threads;' before calling worker()";
        }

        if ($opts->{results} || $opts->{shared}) {
            croak "worker() {results}/{shared} are pipe channels for fork " .
                "workers; under {mechanism=>'thread'} share a variable and " .
                "serialise it with pi_lock()/pi_unlock()";
        }
    }

    # Opt-in channels carrying $body's defined return value back to the parent,
    # both length-framed over an inherited pipe (the background_interrupt model):
    #   results => every value, streamed; parent drains with read()/fh().
    #   shared  => latest value only, lossy; parent reads with value().
    # Set up before forking so both ends inherit.
    my ($res_r, $res_w);
    if ($opts->{results}) {
        pipe($res_r, $res_w)
            or croak "worker() results pipe failed: $!";
    }

    my ($val_r, $val_w);
    if ($opts->{shared}) {
        pipe($val_r, $val_w)
            or croak "worker() shared pipe failed: $!";
    }

    # Opt-in ithread mechanism: run the body in a thread instead of a fork, for
    # users who specifically want shared-memory ergonomics on a threaded Perl.
    # A shared stop flag (checked at the top of each pass) gives a clean,
    # signal-free stop()/join. threads::shared is required only here, on the
    # opt-in path - the module never loads threads itself.
    if ($mechanism eq 'thread') {
        require threads::shared;

        my $once     = $opts->{once};
        my $interval = $opts->{interval};

        my $stop = 0;
        threads::shared::share(\$stop);

        my $thr = threads->create(sub {
            until ($stop) {
                $body->();
                last if $once;
                select(undef, undef, undef, $interval) if $interval;
            }
        });

        my $handle = WiringPi::API::WorkerThread->_new($thr, \$stop);
        push @_bg_children, $handle;

        return $handle;
    }

    my $pid = fork;
    croak "worker() fork failed: $!" if ! defined $pid;

    if ($pid == 0) {
        # CHILD: the helper owns the loop AND the lifecycle, so the user body
        # carries no while/sleep of its own. {once} runs it exactly once;
        # {interval} paces each pass; otherwise the body sets its own cadence.
        # TERM flips the loop guard so the current pass finishes, then we exit
        # cleanly for the parent's stop()/END reaper.
        close $res_r if $res_r;
        close $val_r if $val_r;

        # The shared channel is lossy: never let a slow/absent reader block the
        # worker. A full pipe just drops the update (the parent only wants latest).
        if ($val_w) {
            my $flags = fcntl($val_w, F_GETFL, 0);
            fcntl($val_w, F_SETFL, $flags | O_NONBLOCK) if defined $flags;
        }

        my $once     = $opts->{once};
        my $interval = $opts->{interval};

        my $run = 1;
        $SIG{TERM} = sub { $run = 0; };

        while ($run) {
            my $ret = $body->();

            if (defined $ret) {
                my $frame = pack("N", length "$ret") . "$ret";
                syswrite $res_w, $frame if $res_w;
                syswrite $val_w, $frame if $val_w;
            }

            last if $once;

            # select() sleeps the interval but wakes early on TERM (EINTR), so
            # stop() stays responsive even with a long cadence.
            select(undef, undef, undef, $interval) if $interval;
        }

        exit 0;
    }

    # PARENT: record the child so $w->stop / the END reaper can clean it up.
    close $res_w if $res_w;
    close $val_w if $val_w;

    my $handle = WiringPi::API::Worker->_new($pid, $res_r, $val_r);
    push @_bg_children, $handle;

    return $handle;
}

# system functions

sub setup {
    return wiringPiSetup();
}
sub setup_gpio {
    return wiringPiSetupGpio();
}
sub wiringpi_setup_pin_type {
    shift if @_ == 2;
    my ($pin_type) = @_;

    if (! defined $pin_type
        || $pin_type !~ /^\d+$/
        || ($pin_type != WPI_PIN_BCM && $pin_type != WPI_PIN_WPI)) {
        croak "wiringpi_setup_pin_type() requires WPI_PIN_BCM or WPI_PIN_WPI " .
              "(physical-pin setup is not supported)";
    }

    return wiringPiSetupPinType($pin_type);
}
sub wiringpi_setup_gpio_device {
    shift if @_ == 2;
    my ($pin_type) = @_;

    if (! defined $pin_type
        || $pin_type !~ /^\d+$/
        || ($pin_type != WPI_PIN_BCM && $pin_type != WPI_PIN_WPI)) {
        croak "wiringpi_setup_gpio_device() requires WPI_PIN_BCM or " .
              "WPI_PIN_WPI (physical-pin setup is not supported)";
    }

    return wiringPiSetupGpioDevice($pin_type);
}
sub wiringpi_gpio_device_get_fd {
    return wiringPiGpioDeviceGetFd();
}
sub wiringpi_version {
    my $ver = wiringPiVersion();

    if (wantarray) {
        my ($major, $minor) = split /\./, $ver;
        return ($major, $minor);
    }

    return $ver;
}

# pin functions

sub pin_mode {
    shift if @_ == 3;
    my ($pin, $mode) = @_;
    if (! grep {$mode == $_} qw(0 1 2 3)){
        croak "pin_mode() requires either 0, 1, 2 or 3 as a param";
    }
    pinMode($pin, $mode);
}
sub pin_mode_alt {
    shift if @_ == 3;
    my ($pin, $alt) = @_;

    # The Broadcom SoC (Pi 0-4) takes a 3-bit function select (0-7). The RP1
    # chip on the Pi 5 adds ALT6-ALT8 (8-10), so widen the range there. See the
    # POD for the per-SoC differences in what each value actually selects.
    my $max = pi_rp1_model() ? 10 : 7;

    if (! grep {$alt == $_} 0 .. $max){
        croak "pin_mode_alt() requires 0-$max as a param";
    }

    # Legacy (Broadcom) value -> mode:
    # 0 INPUT, 1 OUTPUT, 4 ALT0, 5 ALT1, 6 ALT2, 7 ALT3, 3 ALT4, 2 ALT5

    pinModeAlt($pin, $alt);
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
sub digital_read_byte {
    return digitalReadByte();
}
sub digital_read_byte2 {
    return digitalReadByte2();
}
sub digital_write_byte {
    shift if @_ == 2;
    my ($value) = @_;
    digitalWriteByte($value);
}
sub digital_write_byte2 {
    shift if @_ == 2;
    my ($value) = @_;
    digitalWriteByte2($value);
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

    # Mirror the C bounds guard: phys_wpi_map has 64 entries (0-63), so any
    # index outside that (or a non-integer) has no wiringPi pin - return the
    # -1 "no such pin" sentinel rather than reading out of bounds.
    return -1 if ! defined $pin || $pin !~ /^-?\d+$/ || $pin < 0 || $pin >= 64;

    return physPinToWpi($pin);
}
sub pwm_set_range {
    shift if @_ > 1;
    my $range = shift;
    pwmSetRange($range);
}
sub pwm_set_clock {
    shift if @_ > 1;
    my $divisor = shift;
    pwmSetClock($divisor);
}
sub pwm_set_mode {
    shift if @_ > 1;
    my $mode = shift;
    pwmSetMode($mode);
}

# soft pwm functions

sub soft_pwm_create {
    shift if @_ == 4;
    my ($pin, $value, $range) = @_;
    return softPwmCreate($pin, $value, $range);
}
sub soft_pwm_write {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    softPwmWrite($pin, $value);
}
sub soft_pwm_stop {
    shift if @_ == 2;
    my ($pin) = @_;
    softPwmStop($pin);
}

# soft tone functions

sub soft_tone_create {
    shift if @_ == 2;
    my ($pin) = @_;
    return softToneCreate($pin);
}
sub soft_tone_stop {
    shift if @_ == 2;
    my ($pin) = @_;
    softToneStop($pin);
}
sub soft_tone_write {
    shift if @_ == 3;
    my ($pin, $freq) = @_;
    softToneWrite($pin, $freq);
}

# thread/lock functions

sub pi_lock {
    shift if @_ == 2;
    my ($key) = @_;

    if (! defined $key || $key !~ /^[0-3]$/) {
        croak "pi_lock() requires \$key to be 0, 1, 2 or 3";
    }

    piLock($key);
}
sub pi_unlock {
    shift if @_ == 2;
    my ($key) = @_;

    if (! defined $key || $key !~ /^[0-3]$/) {
        croak "pi_unlock() requires \$key to be 0, 1, 2 or 3";
    }

    piUnlock($key);
}

# timing functions

# delay(), millis(), micros() are exported directly as their wiringPi C names
# (under the :wiringPi tag); a same-named Perl wrapper would shadow the XS sub.

sub delay_microseconds {
    shift if @_ == 2;
    my ($us) = @_;
    delayMicroseconds($us);
}
sub pi_micros64 {
    return piMicros64();
}
sub pi_hi_pri {
    shift if @_ == 2;
    my ($pri) = @_;
    return piHiPri($pri);
}

# pad drive / pwm tone / gpio clock functions

sub set_pad_drive {
    shift if @_ == 3;
    my ($group, $value) = @_;
    setPadDrive($group, $value);
}
sub set_pad_drive_pin {
    shift if @_ == 3;
    my ($pin, $value) = @_;
    setPadDrivePin($pin, $value);
}
sub pwm_tone_write {
    shift if @_ == 3;
    my ($pin, $freq) = @_;
    pwmToneWrite($pin, $freq);
}
sub gpio_clock_set {
    shift if @_ == 3;
    my ($pin, $freq) = @_;
    gpioClockSet($pin, $freq);
}

# board / identity functions

sub pi_board_id {
    my ($model, $rev, $mem, $maker, $over_volted) = piBoardId();

    if (wantarray) {
        return ($model, $rev, $mem, $maker, $over_volted);
    }

    return {
        model       => $model,
        rev         => $rev,
        mem         => $mem,
        maker       => $maker,
        over_volted => $over_volted,
    };
}
sub pi_board40_pin {
    return piBoard40Pin();
}
sub pi_rp1_model {
    return piRP1Model();
}
sub get_pin_mode_alt {
    shift if @_ == 2;
    my ($pin) = @_;
    return getPinModeAlt($pin);
}
sub wiringpi_global_memory_access {
    return wiringPiGlobalMemoryAccess();
}
sub wiringpi_user_level_access {
    return wiringPiUserLevelAccess();
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
            croak "\n'$_' is a required param for WiringPi::API::lcd_init()\n";
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

    croak "\$pin_base must be an integer\n" if $pin_base !~ /^\d+$/;

    if ($num_pins < 0 || $num_pins > 32){
        croak "\$num_pins must be between 0 and 32\n";
    }

    for ($data_pin, $clock_pin, $latch_pin){
        if ($_ < 0 || $_ > 40){
            croak "$data_pin, $clock_pin and $latch_pin must all be valid " .
                "GPIO pin numbers\n";
        }
    }

    sr595Setup($pin_base, $num_pins, $data_pin, $clock_pin, $latch_pin);
}

# I2C functions

sub i2c_setup {
    shift if @_ == 2;
    my ($addr) = @_;

    if (! defined $addr){
        croak "i2c_setup() requires an \$addr param\n";
    }

    if ($addr =~ /^0x[0-9a-fA-F]+$/){
        $addr = hex($addr);
    }
    elsif ($addr !~ /^\d+$/){
        croak "i2c_setup() address param must be an integer or hex value\n";
    }

    # file descriptor

    return wiringPiI2CSetup($addr);
}
sub i2c_interface {
    shift if @_ > 2;
    my ($device, $dev_id) = @_;

    if (! defined $device){
        croak "i2c_interface() requires a \$device param\n";
    }
    if (! defined $dev_id){
        croak "i2c_interface() requires a \$dev_id param\n";
    }

    return wiringPiI2CSetupInterface($device, $dev_id);
}
sub i2c_read {
    shift if @_ > 1;
    my ($fd) = @_;

    if (! defined $fd){
        croak "i2c_read() requires an \$fd param\n";
    }

    return wiringPiI2CRead($fd);
}
sub i2c_read_byte {
    shift if @_ > 2;
    my ($fd, $reg) = @_;

    if (! defined $fd){
        croak "i2c_read_byte() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_read_byte() requires a \$register param\n";
    }

    return wiringPiI2CReadReg8($fd, $reg);
}
sub i2c_read_word {
    shift if @_ > 2;
    my ($fd, $reg) = @_;

    if (! defined $fd){
        croak "i2c_read_word() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_read_word() requires a \$register param\n";
    }

    return wiringPiI2CReadReg16($fd, $reg);
}
sub i2c_write {
    shift if @_ > 2;
    my ($fd, $data) = @_;

    if (! defined $fd){
        croak "i2c_write() requires an \$fd param\n";
    }
    if (! defined $data){
        croak "i2c_write() requires a \$data param\n";

    }
    return wiringPiI2CWrite($fd, $data);
}
sub i2c_write_byte {
    shift if @_ > 3;
    my ($fd, $reg, $data) = @_;

    if (! defined $fd){
        croak "i2c_write_byte() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_write_byte() requires a \$register param\n";
    }
    if (! defined $data){
        croak "i2c_write_byte() requires a \$data param\n";
    }

    return wiringPiI2CWriteReg8($fd, $reg, $data);
}
sub i2c_write_word {
    shift if @_ > 3;
    my ($fd, $reg, $data) = @_;

    if (! defined $fd){
        croak "i2c_write_word() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_write_word() requires a \$register param\n";
    }
    if (! defined $data){
        croak "i2c_write_word() requires a \$data param\n";
    }

    return wiringPiI2CWriteReg16($fd, $reg, $data);
}
sub i2c_read_block {
    shift if @_ > 3;
    my ($fd, $reg, $size) = @_;

    if (! defined $fd){
        croak "i2c_read_block() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_read_block() requires a \$register param\n";
    }
    if (! defined $size){
        croak "i2c_read_block() requires a \$size param\n";
    }

    return wiringPiI2CReadBlockData($fd, $reg, $size);
}
sub i2c_raw_read {
    shift if @_ > 2;
    my ($fd, $size) = @_;

    if (! defined $fd){
        croak "i2c_raw_read() requires an \$fd param\n";
    }
    if (! defined $size){
        croak "i2c_raw_read() requires a \$size param\n";
    }

    return wiringPiI2CRawRead($fd, $size);
}
sub i2c_write_block {
    shift if @_ > 3;
    my ($fd, $reg, $values) = @_;

    if (! defined $fd){
        croak "i2c_write_block() requires an \$fd param\n";
    }
    if (! defined $reg){
        croak "i2c_write_block() requires a \$register param\n";
    }
    if (ref $values ne 'ARRAY'){
        croak "i2c_write_block() requires an array reference of bytes\n";
    }

    return wiringPiI2CWriteBlockData($fd, $reg, $values);
}
sub i2c_raw_write {
    shift if @_ > 2;
    my ($fd, $values) = @_;

    if (! defined $fd){
        croak "i2c_raw_write() requires an \$fd param\n";
    }
    if (ref $values ne 'ARRAY'){
        croak "i2c_raw_write() requires an array reference of bytes\n";
    }

    return wiringPiI2CRawWrite($fd, $values);
}

# SPI functions

sub spi_setup {
    shift if @_ == 3;
    my ($channel, $speed) = @_;

    if ($channel != 0 && $channel != 1){
        croak "spi_setup() channel param must be 0 or 1\n";
    }

    $speed = 1000000 if ! defined $speed;

    return wiringPiSPISetup($channel, $speed);
}
sub spi_data {
    shift if @_ == 4;
    my ($chan, $data, $len) = @_;

    if ($chan != 0 && $chan != 1){
        croak "spi_data() channel param must be 0 or 1\n";
    }

    if (ref $data ne 'ARRAY'){
        croak "spi_data() data param must be an array reference\n";
    }
    if (@$data != $len){
        croak "spi_data() array reference must have \$len param count\n";
    }

    my $buf;

    for (@$data){
        push @$buf, $_;
    }

    return spiDataRW($chan, $buf, $len);
}
sub spi_get_fd {
    shift if @_ > 1;
    my ($channel) = @_;

    if (! defined $channel || ($channel != 0 && $channel != 1)){
        croak "spi_get_fd() channel param must be 0 or 1\n";
    }

    return wiringPiSPIGetFd($channel);
}
sub spi_setup_mode {
    shift if @_ > 3;
    my ($channel, $speed, $mode) = @_;

    if (! defined $channel || ($channel != 0 && $channel != 1)){
        croak "spi_setup_mode() channel param must be 0 or 1\n";
    }
    if (! defined $speed){
        croak "spi_setup_mode() requires a \$speed param\n";
    }
    if (! defined $mode){
        croak "spi_setup_mode() requires a \$mode param\n";
    }

    return wiringPiSPISetupMode($channel, $speed, $mode);
}
sub spi_close {
    shift if @_ > 1;
    my ($channel) = @_;

    if (! defined $channel || ($channel != 0 && $channel != 1)){
        croak "spi_close() channel param must be 0 or 1\n";
    }

    return wiringPiSPIClose($channel);
}

# bmp180 pressure sensor functions

sub bmp180_setup {
    shift if @_ == 2;
    my $base = shift;

    if (! defined $base || $base !~ /^\d+$/){
        croak "bmp180 setup parametermust be an integer\n";
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

END {
    # Reap any still-running background children at process exit, so a forgotten
    # stop() can't leak a zombie or orphan a handler.

    for my $handle (@_bg_children) {
        $handle->stop if $handle && $handle->running;
    }
}

sub _vim{1;};

1;
__END__

=head1 NAME

WiringPi::API - API for wiringPi, providing access to the Raspberry Pi's board,
GPIO and connected peripherals

=head1 SYNOPSIS

No matter which import option you choose, you must initialize the software
before making any other calls by running one of the C<setup*()> routines. That
call also selects the pin-numbering scheme - for example, C<setup_gpio()> uses
the BCM GPIO numbers printed on the Pi's board.

    use WiringPi::API qw(:all)

    # use as a base class with OO functionality

    use parent 'WiringPi::API';

    # use in the traditional Perl OO way

    use WiringPi::API;

    my $api = WiringPi::API->new;

=head1 EXAMPLES

These examples import the function set with the C<:all> tag (which also brings
in the constants), and call C<setup_gpio()> so the pin numbers are the
B<BCM GPIO> numbers printed on the Pi's board.

=head2 Output - blink an LED

    use WiringPi::API qw(:all);

    setup_gpio();                  # GPIO (BCM) pin numbering

    pin_mode(17, OUTPUT);          # An LED wired to GPIO17

    for (1..5) {
        write_pin(17, HIGH);       # On
        delay(500);                # Wait 500ms
        write_pin(17, LOW);        # Off
        delay(500);
    }

=head2 Input - read a button

    use WiringPi::API qw(:all);

    setup_gpio();

    pin_mode(27, INPUT);           # A button wired to GPIO27
    pull_up_down(27, PUD_UP);      # Enable the internal pull-up

    # Pressed pulls the pin LOW

    print read_pin(27) ? "Released\n" : "Pressed\n";

=head2 Background interrupt - blink an LED on each button press

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

=head1 DESCRIPTION

This is an XS-based module, and requires L<wiringPi|http://wiringpi.com> version
3.18+ to be installed. The C<wiringPiDev> shared library is also required (for
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
versions, but are still 100% compatible. They are grouped below by purpose;
within each group the names are listed alphabetically, except where a natural
flow (eg. C<setup> before its variants, or C<lcd_init> before the rest) reads
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

=head1 EXPORT_TAGS

See L</EXPORT_OK>

=head2 :all

Exports all available exportable functions.

=head2 :perl

Export only Perlish snake_case named version of the functions.

=head2 :wiringPi

Export only the C based camelCase version of the function names.

=head2 :constants

Export only the constants. These (including C<WPI_PIN_BCM> / C<WPI_PIN_WPI> and
the C<INT_EDGE_*> edge triggers) are defined in and re-exported from
L<RPi::Const>, the single source of truth for constants across the C<RPi::>
suite.

=head1 FUNCTION TABLE OF CONTENTS

=head2 CORE

See L</CORE FUNCTIONS>.

=head2 BOARD

See L</BOARD FUNCTIONS>.

=head2 LCD

See L</LCD FUNCTIONS>.

=head2 INTERRUPT

See L</INTERRUPT FUNCTIONS>.

=head2 CONCURRENCY / BACKGROUND WORKERS

See L</CONCURRENCY / BACKGROUND WORKERS>.

=head2 ANALOG TO DIGITAL CONVERTER

See L</ADC FUNCTIONS>.

=head2 SHIFT REGISTER

See L</SHIFT REGISTER FUNCTIONS>

=head2 SERIAL

See L</SERIAL FUNCTIONS>

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

=head2 wiringpi_setup_pin_type($pin_type)

Maps to C<int wiringPiSetupPinType(enum WPIPinType pinType)>

A unified setup routine that takes the pin-numbering scheme as a parameter,
rather than having a separate function per scheme. C<$pin_type> must be one of
the exported constants C<WPI_PIN_BCM> (equivalent to C<setup_gpio()>) or
C<WPI_PIN_WPI> (equivalent to C<setup()>).

Physical-pin setup (C<WPI_PIN_PHYS>) is B<not supported> - that constant is not
exported, and passing it (or any other value) causes a C<croak>.

=head2 wiringpi_setup_gpio_device($pin_type)

Maps to C<int wiringPiSetupGpioDevice(enum WPIPinType pinType)>

As C<wiringpi_setup_pin_type()>, but initialises wiringPi over the GPIO
character-device (libgpiod) interface instead of the legacy C</dev/gpiomem>
memory-mapped path. C<$pin_type> takes the same C<WPI_PIN_BCM> / C<WPI_PIN_WPI>
constants and is validated the same way.

This is offered as an opt-in alternative; the default C<setup()> / C<setup_gpio()>
routines are unchanged.

=head2 wiringpi_gpio_device_get_fd()

Maps to C<int wiringPiGpioDeviceGetFd()>

Returns the open file descriptor of the GPIO character device, when wiringPi was
initialised via C<wiringpi_setup_gpio_device()>.

The pin-type constants C<WPI_PIN_BCM> and C<WPI_PIN_WPI> are available
individually or via the C<:constants> / C<:all> export tags.

=head2 wiringpi_version()

Maps to C<void wiringPiVersion(int *major, int *minor)>.

Returns the version of the installed B<wiringPi C library> (eg. C<3.18>). This
is the underlying library version, B<not> the C<$VERSION> of this Perl
distribution.

In scalar context, returns the version as a string (eg. C<"3.18">). In list
context, returns the C<($major, $minor)> integer pair (eg. C<(3, 18)>).

The exported C-level C<wiringPiVersion()> always returns the version string.

=head2 pin_mode($pin, $mode)

Maps to C<void pinMode(int pin, int mode)>

Puts the pin in either INPUT, OUTPUT, PWM or GPIO_CLOCK mode.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $mode

Mandatory: C<0> for INPUT, C<1> OUTPUT, C<2> PWM_OUTPUT and C<3> GPIO_CLOCK.

=head2 pin_mode_alt($pin, $alt)

Maps to the undocumented C<void pinModeAlt(int pin, int mode)>

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
C<setup*()> routine you used.

    $alt

Mandatory, Integer: The mode you want to put the pin into. See the list above
for the relevant values for this parameter.

=head3 Raspberry Pi 5 (RP1) differences

On the Pi 5 the GPIO is driven by the RP1 chip rather than the Broadcom SoC, and
its alternate-function map is B<completely different> from earlier Pis. The
C<$alt> B<values> above are unchanged - wiringPi remaps them internally - but
what each mode B<selects> is not: C<ALT0>..C<ALT5> route entirely different
peripherals on the Pi 5 than they do on a Pi 0-4. Consult the RP1 datasheet (or
the C<pinctrl> tool) for your Pi 5, B<not> the BCM2835 ALT tables, to know which
function a given value actually enables.

Two further specifics on the Pi 5:

=over 4

=item *

C<INPUT> (C<0>) and C<OUTPUT> (C<1>) both select the RP1 GPIO (C<SYS_RIO>)
function; the in/out direction itself is set separately (eg. via C<pin_mode()>),
not by the alt value.

=item *

RP1 adds three more alternate functions - C<ALT6>, C<ALT7> and C<ALT8> (values
C<8>, C<9> and C<10>). These are accepted B<only> on a Pi 5; on a Pi 0-4 the
valid range stays C<0-7> and passing C<8>-C<10> croaks. The Pi 5 is detected via
C<pi_rp1_model()>, so a C<setup*()> routine must have run first.

=back

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

=head2 digital_read_byte()

Maps to C<unsigned int digitalReadByte()>

Reads all eight bits of the first 8-bit GPIO bank at once and returns the value
as a single integer (C<0>-C<255>).

B<Note:> the byte-bank operations (C<digital_read_byte()>,
C<digital_read_byte2()>, C<digital_write_byte()>, C<digital_write_byte2()>) are
B<not supported on the Raspberry Pi 5>. On a Pi 5, the underlying wiringPi call
prints a diagnostic and terminates the process.

=head2 digital_read_byte2()

Maps to C<unsigned int digitalReadByte2()>

As C<digital_read_byte()>, but reads the second 8-bit GPIO bank.

=head2 digital_write_byte($value)

Maps to C<void digitalWriteByte(int value)>

Writes the 8-bit C<$value> (C<0>-C<255>) to the first 8-bit GPIO bank in a
single operation.

Parameters:

    $value

Mandatory: An integer C<0>-C<255>; each bit is written to the corresponding pin
of the bank.

=head2 digital_write_byte2($value)

Maps to C<void digitalWriteByte2(int value)>

As C<digital_write_byte()>, but writes to the second 8-bit GPIO bank.

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

Returns: The C<wiringPi> pin number, or C<-1> if the physical pin has no
C<wiringPi> equivalent or C<$pin_num> is out of range (less than C<0> or
greater than C<63>).

=head2 pwm_set_range($range)

Maps to C<void pwmSetRange(int range)>

Sets the range register of the Pulse Width Modulation (PWM) functionality. It
defaults to C<1024> (C<0-1023>).

Parameters:

    $range

Mandatory: An integer between C<0> and C<1023>.

=head2 pwm_set_clock($divisor)

Maps to C<void pwmSetClock(int divisor)>.

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

=head2 pwm_set_mode($mode)

Each PWM channel can run in either Balanced or Mark-Space mode. In Balanced
mode, the hardware sends a combination of clock pulses that results in an
overall DATA pulses per RANGE pulses. In Mark-Space mode, the hardware sets the
output HIGH for DATA clock pulses wide, followed by LOW for RANGE-DATA clock
pulses.

Parameters:

    $mode

Mandatory, Integer: C<0> for Mark-Space mode, or C<1> for Balanced mode.

Note: If using L<RPi::WiringPi::Const>, you can use C<PWM_MODE_MS> or
C<PWM_MODE_BAL>.

=head1 SOFT PWM FUNCTIONS

Software-driven PWM on any GPIO pin. See
L<wiringPi softPwm page|http://wiringpi.com/reference/software-pwm-library/>.

=head2 soft_pwm_create($pin, $value, $range)

Maps to C<int softPwmCreate(int pin, int value, int range)>

Creates a software-controlled PWM pin. Returns C<0> on success.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $value

Mandatory: The initial duty-cycle value, between C<0> and C<$range>.

    $range

Mandatory: The PWM range (a typical value is C<100>).

=head2 soft_pwm_write($pin, $value)

Maps to C<void softPwmWrite(int pin, int value)>

Updates the PWM duty-cycle value on a pin previously set up with
C<soft_pwm_create()>.

Parameters:

    $pin

Mandatory: The pin number.

    $value

Mandatory: The new duty-cycle value, between C<0> and the range the pin was
created with.

=head2 soft_pwm_stop($pin)

Maps to C<void softPwmStop(int pin)>

Stops software PWM on the given pin.

Parameters:

    $pin

Mandatory: The pin number.

=head1 SOFT TONE FUNCTIONS

Software-generated tone (square-wave frequency) output on any GPIO pin. See
L<wiringPi softTone page|http://wiringpi.com/reference/software-tone-library/>.

(Note: wiringPi's C<softServo> library is not built into the wiringPi 3.18
shared library and is therefore not wrapped.)

=head2 soft_tone_create($pin)

Maps to C<int softToneCreate(int pin)>

Sets up a pin for software tone output. Returns C<0> on success.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

=head2 soft_tone_write($pin, $freq)

Maps to C<void softToneWrite(int pin, int freq)>

Sets the frequency (in Hz) of the tone on a pin previously set up with
C<soft_tone_create()>. A frequency of C<0> stops the tone.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The frequency in Hz.

=head2 soft_tone_stop($pin)

Maps to C<void softToneStop(int pin)>

Stops the software tone on the given pin.

Parameters:

    $pin

Mandatory: The pin number.

=head1 THREAD/LOCK FUNCTIONS

Mutex locks provided by wiringPi for synchronising access between threads. They
are typically used to serialise shared state in a C<< mechanism => 'thread' >>
worker - see L</CONCURRENCY / BACKGROUND WORKERS>.

=head2 pi_lock($key)

Maps to C<void piLock(int key)>

Acquires the lock identified by C<$key>, waiting until it is available.

Parameters:

    $key

Mandatory: The lock number, C<0> to C<3>.

=head2 pi_unlock($key)

Maps to C<void piUnlock(int key)>

Releases the lock identified by C<$key>.

Parameters:

    $key

Mandatory: The lock number, C<0> to C<3>.

=head1 TIMING FUNCTIONS

wiringPi timing and scheduling helpers. See
L<wiringPi timing page|http://wiringpi.com/reference/timing/>.

C<delay()>, C<millis()> and C<micros()> are exported under the C<:wiringPi> tag
as their native wiringPi names.

=head2 delay($ms)

Maps to C<void delay(unsigned int ms)>

Pauses execution for at least C<$ms> milliseconds.

=head2 delay_microseconds($us)

Maps to C<void delayMicroseconds(unsigned int us)>

Pauses execution for at least C<$us> microseconds.

=head2 millis()

Maps to C<unsigned int millis()>

Returns the number of milliseconds elapsed since the program called one of the
C<setup*()> routines, as an integer.

=head2 micros()

Maps to C<unsigned int micros()>

Returns the number of microseconds elapsed since the program called one of the
C<setup*()> routines, as an integer.

=head2 pi_micros64()

Maps to C<unsigned long long piMicros64()>

As C<micros()>, but returns a 64-bit microsecond count (does not wrap as
quickly). Requires a 64-bit Perl (C<use64bitint>).

=head2 pi_hi_pri($priority)

Maps to C<int piHiPri(const int pri)>

Attempts to set a high (real-time) scheduling priority for the running program.
Returns C<0> on success, C<-1> on failure (e.g. insufficient privileges).

Parameters:

    $priority

Mandatory: The priority, C<0> (lowest) to C<99> (highest).

=head1 PAD DRIVE / TONE / CLOCK FUNCTIONS

=head2 set_pad_drive($group, $value)

Maps to C<void setPadDrive(int group, int value)>

Sets the drive strength for a group of GPIO pins.

Parameters:

    $group

Mandatory: The pad group (C<0>, C<1> or C<2>).

    $value

Mandatory: The drive strength, C<0> to C<7>.

=head2 set_pad_drive_pin($pin, $value)

Maps to C<void setPadDrivePin(int pin, int value)>

Sets the drive strength for a single GPIO pin.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $value

Mandatory: The drive strength, C<0> to C<7>.

=head2 pwm_tone_write($pin, $freq)

Maps to C<void pwmToneWrite(int pin, int freq)>

Writes a tone of the given frequency (in Hz) to a PWM-capable pin.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The frequency in Hz. A frequency of C<0> stops the tone.

=head2 gpio_clock_set($pin, $freq)

Maps to C<void gpioClockSet(int pin, int freq)>

Sets the output frequency (in Hz) on a GPIO clock pin.

Parameters:

    $pin

Mandatory: The pin number.

    $freq

Mandatory: The clock frequency in Hz.

=head1 BOARD IDENTITY FUNCTIONS

=head2 pi_board_id()

Maps to C<void piBoardId(int *model, int *rev, int *mem, int *maker, int *overVolted)>

Returns identifying information about the board. In list context, returns
C<($model, $rev, $mem, $maker, $over_volted)>. In scalar context, returns a hash
reference with keys C<model>, C<rev>, C<mem>, C<maker> and C<over_volted>. The
values are the integer codes used by wiringPi.

=head2 pi_board40_pin()

Maps to C<int piBoard40Pin()>

Returns true if the board has the standard 40-pin GPIO header.

=head2 pi_rp1_model()

Maps to C<int piRP1Model()>

Returns the RP1 model code on boards that use the RP1 I/O controller (e.g. the
Raspberry Pi 5), or a falsey value on boards without one.

=head2 get_pin_mode_alt($pin)

Maps to C<enum WPIPinAlt getPinModeAlt(int pin)>

Like C<get_alt()>, but returns the pin's current mode as a C<WPIPinAlt> enum
value: C<-1> (unknown), C<0> (input), C<1> (output), then the C<ALT> modes.

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

=head2 wiringpi_global_memory_access()

Maps to C<int wiringPiGlobalMemoryAccess()>

Returns a value indicating the level of direct GPIO memory access available to
the current process (C<0> if none).

=head2 wiringpi_user_level_access()

Maps to C<int wiringPiUserLevelAccess()>

Returns true if user-level (non-root) GPIO access is available (e.g. via
C</dev/gpiomem>).

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

NOTE: There is an upper limit of the number of LCDs that can be initialized
simultaneously. This number is 8 (0-7). Always check the return of this
function to ensure you're under the maximum file descriptors. If you receive a
`-1`, you're out of bounds, and any functions called on the LCD will cause a 
segmentation fault.

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

Maps to C<void lcdPutchar(int fd, unsigned char data)>

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

=head1 INTERRUPT FUNCTIONS

=head2 set_interrupt($pin, $edge, $callback, $debounce_us)

Arms an interrupt handler on C<$pin>. Maps to wiringPi's C<wiringPiISR2()>.

The wiringPi interrupt thread never calls into Perl: when an edge fires it
writes a small event record to an internal pipe (the "self-pipe"). Your
C<$callback> runs later, in B<your> interpreter, when you service that pipe with
C<wait_interrupts()> or C<dispatch_interrupts()>. Because Perl is only ever
entered by the interpreter that owns it, this works on B<any> Perl - threaded or
not - and the old "interrupts need a threaded Perl or they segfault" caveat no
longer applies.

Arm in the same process that will dispatch. For background handling while your
main program does other work, C<fork> a child that arms and dispatches (see the
examples below).

Parameters:

    $pin

Mandatory: The pin number, in the pin numbering scheme dictated by whichever
C<setup*()> routine you used.

    $edge

Mandatory: one of C<INT_EDGE_FALLING> (C<1>), C<INT_EDGE_RISING> (C<2>) or
C<INT_EDGE_BOTH> (C<3>). C<INT_EDGE_SETUP> (C<0>) is B<not> a valid trigger and
is rejected. These constants are importable via the C<:constants> or C<:all>
tags.

    $callback

Mandatory: A code reference that runs when the interrupt is dispatched. It
receives two arguments: the edge that fired and the event timestamp in
microseconds.

    $debounce_us

Optional: debounce period in microseconds, passed through to C<wiringPiISR2()>
(default C<0> = no debounce).

    \%opts

Optional: a trailing options hash reference. The only option is C<auto_dispatch>:
a true value turns on auto-dispatch (see C<auto_dispatch_interrupts()>) as part
of arming, so the callback fires on its own without a dispatch loop. This enables
the B<process-wide> switch (it is not selective per pin); a string value picks
the delivery signal, eg C<< { auto_dispatch =E<gt> 'USR1' } >>.

Re-arming the same pin is safe - the previous listener is stopped first, so a
second wiringPi thread is never stacked on the pin.

=head2 dispatch_interrupts()

Non-blocking. Reads every event currently waiting in the self-pipe, runs the
registered callback for each, and returns the number dispatched (C<0> if none
were waiting). Never blocks waiting for an edge.

=head2 wait_interrupts($timeout_ms)

Blocks until at least one interrupt event is available (or C<$timeout_ms>
milliseconds elapse), dispatches all pending events via C<dispatch_interrupts()>,
and returns the number dispatched (C<0> on timeout). An undefined C<$timeout_ms>
blocks indefinitely. The usual single-threaded pattern is:

    wait_interrupts(1000) while 1;

=head2 interrupt_fd()

Returns the readable file descriptor of the self-pipe (an integer), or C<-1>
before any interrupt has been armed. Use this to drive your own C<select>/C<poll>
loop instead of C<wait_interrupts()>; call C<dispatch_interrupts()> when it
becomes readable.

=head2 interrupt_dropped()

Returns the number of interrupt events dropped because the self-pipe was full
when an edge fired (bursts beyond the pipe buffer). Normally C<0>; reset by
C<stop_interrupts()>.

B<Overflow policy.> Edges are FIFO-queued in the kernel pipe (capacity is the
kernel default - typically 64 KiB to 256 KiB - holding thousands of the
fixed-size event records). The wiringPi ISR thread writes each edge with a
B<non-blocking> C<write()>, so it never stalls. If the pipe is full (your code
isn't draining fast enough - e.g. stuck in a long, non-yielding C/XS call), the
overflowing edges are B<dropped, not merged and not blocked>, and each one
increments C<interrupt_dropped()> - so loss is never silent. Order is preserved;
no two edges are ever coalesced into one (debounce, via C<set_interrupt>'s
C<$debounce_us>, is the only mechanism that intentionally collapses edges). If
you see drops, drain faster (C<wait_interrupts>/C<auto_dispatch_interrupts>),
move handling to its own process (C<background_interrupt>), raise the queue size
with C<interrupt_buffer()>, or debounce to cut the edge rate.

=head2 interrupt_buffer($bytes)

Gets or sets the capacity of the interrupt self-pipe (the queue that absorbs
edge bursts before C<interrupt_dropped()> starts counting).

With no argument, returns the current capacity in bytes (or the pending request
if no interrupt has been armed yet). With C<$bytes>, requests that capacity
(C<F_SETPIPE_SZ>) and returns the size the kernel actually granted - it rounds up
to a page and caps at F</proc/sys/fs/pipe-max-size>:

    interrupt_buffer(1 << 20);    # Ask for ~1 MiB of queue
    my $size = interrupt_buffer;  # What we actually got

The request is remembered, so you may set it B<before> arming (it is applied when
the pipe is created) and it persists across C<stop_interrupts()> - the new pipe
from a later C<set_interrupt()> is sized the same way.

=head2 run_interrupt_loop($timeout_ms, $max)

A blocking dispatch loop, so you don't have to write C<< wait_interrupts(...)
while 1 >> yourself. It repeatedly calls C<wait_interrupts($timeout_ms)> (poll
interval, default 1000 ms) and returns the total number of events dispatched.

It runs until one of:

=over 4

=item * C<stop_interrupt_loop()> is called - from inside a callback, or from a
signal handler (it only flips a flag, so it is signal-safe);

=item * C<$max> events have been dispatched, if you pass a positive C<$max>.

=back

The C<$timeout_ms> is just the poll granularity - how often the loop checks the
stop flag - not a run time limit. Arm your interrupts first; if nothing is armed
the loop sleeps the interval rather than spinning.

    set_interrupt(0, INT_EDGE_RISING, sub {
        my ($edge, $ts) = @_;
        stop_interrupt_loop() if done_enough();   # Break out from the callback
    });

    my $count = run_interrupt_loop(1000);          # Blocks, dispatching, until stopped

=head2 stop_interrupt_loop()

Breaks out of C<run_interrupt_loop()> at the next iteration. Safe to call from a
callback or a signal handler, and a no-op if no loop is running.

=head2 last_interrupt()

Returns a hash reference describing the most recently B<dispatched> interrupt
event, or C<undef> if none has been dispatched yet (or since the last
C<stop_interrupts()>). The keys are:

    pin       The pin you armed (your numbering scheme - the dispatch key)
    pin_bcm   The BCM gpio that fired
    edge      INT_EDGE_FALLING (1) or INT_EDGE_RISING (2)
    status    wiringPi's statusOK (1 for a real edge on this path)
    ts_us     Edge timestamp, in microseconds

The event is published B<before> the callback runs, so a callback - which only
receives C<($edge, $ts_us)> - can call C<last_interrupt()> to obtain the BCM pin
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

=head2 stop_interrupt($pin)

Stops the interrupt on C<$pin> (C<wiringPiISRStop()>) and forgets its callback.

=head2 stop_interrupts()

Stops every armed interrupt, closes the self-pipe and resets interrupt state.
There is no dispatcher thread to join. A later C<set_interrupt()> re-creates the
pipe automatically.

=head2 auto_dispatch_interrupts($bool, $signal)

Enables (C<1>) or disables (C<0>) async auto-dispatch. When enabled, the
interrupt read fd is put into async mode and a signal handler drains and
dispatches pending events, so C<set_interrupt()> callbacks fire B<automatically
in this process> with no C<wait_interrupts()>/C<dispatch_interrupts()> loop to
write. Callbacks run at Perl safe points (between ops, and on interrupted
C<sleep>/C<select>), so they may read and modify your program's variables with
no locking.

The optional C<$signal> chooses the delivery signal (default C<'IO'>, i.e.
C<SIGIO>). Pass a signal name - eg C<'USR1'> (C<'SIGUSR1'> is also accepted) -
to deliver via that signal instead (wired with C<F_SETSIG>), which avoids
clashing with other C<SIGIO>/C<O_ASYNC> users in your program. The name must be
one Perl knows (it croaks otherwise).

You can call it before or after C<set_interrupt()>; arming creates the pipe and
wires it for you. Disabling restores the previous handler for the chosen signal.

Caveats: a long, non-yielding C/XS call defers the callback until it returns
(use C<background_interrupt()> if you need it to fire even then); and it claims
a process-global signal - don't enable it on a signal your program already
drives. See the example below.

=head2 background_interrupt($pin, $edge, $callback, $debounce_us)

Handles an interrupt in a B<background process> with one call: it forks, arms
the interrupt in the child, and runs C<$callback> there on each edge while your
main program does whatever it likes - true fire-while-busy, even during long
blocking work. C<$callback> receives C<($edge, $timestamp_us)>. Arguments are
validated (and croak) B<before> forking; C<$debounce_us> is optional.

Because the callback runs in a separate process it B<cannot> see or change your
main program's variables (use it for independent handlers - drive a pin, log,
notify). Returns a handle:

    my $h = background_interrupt(18, INT_EDGE_RISING, sub { ... });

    $h->stop;        # Signal the child, run its ISR teardown, reap it
    $h->pid;         # The child PID
    $h->running;     # True while the child is alive

C<stop> is idempotent (safe to call repeatedly, and after the child has already
exited). A handle going out of scope stops its child, and an C<END> block reaps
any still-running background children at exit, so a forgotten C<stop> can't leak
a zombie. Needs no threaded Perl. See the example below.

A trailing options hash reference may follow the arguments. The only option is
C<results>: when true, a defined value B<returned> by C<$callback> is shipped
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

Without C<results> (the default) the handler is fire-and-forget and the common
case stays a one-liner.

=head2 background_interrupts([$pin, $edge, $callback, $debounce_us], ...)

Like C<background_interrupt()>, but a B<single> background child services
B<many> pins (instead of one child per pin). Pass one array-ref spec per pin;
all are validated before forking, and the child arms them all and dispatches
every edge from one loop. Returns a handle with the same C<stop>/C<pid>/
C<running>, plus C<arm($pin)> and C<disarm($pin)>:

    setup_gpio();

    my $h = background_interrupts(
        [17, INT_EDGE_RISING, \&on_button],
        [27, INT_EDGE_BOTH,   \&on_sensor, 5000],   # With debounce
    );

    $h->disarm(27);   # Stop servicing pin 27 (without killing the child)
    $h->arm(27);      # Resume it
    $h->stop;         # Tear down + reap the one child

The callbacks are fixed when the child forks - C<fork> cannot carry new code
across - so C<arm>/C<disarm> only toggle pins that were registered in the
initial call (arming an unregistered pin croaks). Each callback runs in the
child and cannot touch your main program's variables.

The shared-child handle has B<no results channel>: calling C<< $h->read >> or
C<< $h->fh >> on it croaks. Routing per-pin return values back through one
multiplexed child is out of scope here - use a per-pin
L</background_interrupt($pin, $edge, $callback, $debounce_us)> with
C<< { results => 1 } >> when you need values back from the handler.

=head3 Example - single-threaded event loop (any Perl)

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

=head3 Example - background handling via fork

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

=head3 Example - hands-off in-process handling (auto_dispatch_interrupts)

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

=head3 Example - background process (background_interrupt)

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

=head1 CONCURRENCY / BACKGROUND WORKERS

C<worker()> runs a piece of code in the background with the least possible user
code: it owns the spawn mechanism, the loop B<and> the lifecycle, so your body
carries no C<fork>, no C<use threads>, no C<detach>, no C<while (1)> and no
manual cleanup. It is the general-purpose sibling of
L</background_interrupt($pin, $edge, $callback, $debounce_us)>.

This module needs B<neither C<threads> nor a threaded Perl>: C<worker()> is
fork-based by default and works on any Perl. An ithread mechanism is available
as a documented opt-in (see C<mechanism> below) for users who specifically want
shared-memory ergonomics on a threaded Perl.

B<The setup-once-in-main contract:> call C<setup()> (or C<setup_gpio()>) and do
your C<pin_mode()> calls B<once, in the parent, before> starting a worker. A
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

=head2 worker(\&body, \%opts)

Spawns a background child that runs C<\&body> B<repeatedly> by default, and
returns a handle (see L</The worker handle> below). All arguments are validated
B<before> spawning, so a bad call croaks immediately rather than failing in the
background.

C<\&body> is mandatory and must be a C<CODE> reference. C<\%opts>, if given,
must be a hash reference. The options are:

=over 4

=item C<< once => 1 >>

Run C<\&body> a single time, then the child exits on its own (C<< $w->running >>
becomes false). Without this, the body loops until the worker is stopped.

=item C<< interval => $secs >>

Pace the loop: sleep C<$secs> (a positive number, fractional allowed) between
passes, so a periodic sampler/blinker needs no C<sleep> of its own. The sleep
wakes early when the worker is stopped, so C<< $w->stop >> stays responsive even
with a long cadence.

=item C<< results => 1 >>

Stream B<every> defined value the body returns back to the parent, length-framed
over an inherited pipe. Drain it with C<< $w->read >> (non-blocking) or select on
C<< $w->fh >> - identical to C<background_interrupt>'s results channel.

=item C<< shared => 1 >>

Publish the body's return value as a B<lossy latest value>: the parent reads the
most recent value with C<< $w->value >>. The child never blocks on a slow or
absent reader (a full pipe simply drops the update), so this suits a sampler
whose intermediate readings don't matter.

=item C<< mechanism => 'fork' | 'thread' >>

The spawn mechanism. Defaults to C<'fork'> (no threaded Perl required).
C<'thread'> runs the body in an ithread for shared-memory ergonomics; it
B<requires C<threads> to be loaded> (C<use threads;> before calling C<worker()>)
and croaks with a clear message otherwise. Under C<'thread'> the C<results> and
C<shared> pipe channels are rejected - share a variable and serialise it with
L</pi_lock($key)> / L</pi_unlock($key)> instead.

=back

=head2 The worker handle

C<worker()> returns a handle - C<WiringPi::API::Worker> for a fork worker, or
C<WiringPi::API::WorkerThread> for a thread worker - with the same shape as the
L</background_interrupt($pin, $edge, $callback, $debounce_us)> handle:

=over 4

=item C<< $w->stop >>

Stop the worker and reap it. B<Idempotent> - safe to call more than once, and a
C<DESTROY> plus an C<END> block reap the worker if you forget, so a missed
C<stop> can't leak a zombie or an orphaned thread.

=item C<< $w->running >>

True while the worker is still alive; false once it has stopped or (for
C<< once => 1 >>) finished its single pass.

=item C<< $w->pid >>

The child's process id for a fork worker, or the thread id (tid) for a thread
worker.

=item C<< $w->read >> / C<< $w->fh >>

Drain the next streamed value / get the readable filehandle, when the worker was
started with C<< results => 1 >> (otherwise C<undef>).

=item C<< $w->value >>

The latest published value, when the worker was started with C<< shared => 1 >>
(otherwise C<undef>).

=back

=head2 Periodic sampler handing data back to main

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

=head2 Shared-memory mechanism (opt-in ithread)

On a threaded Perl you can run the body in an ithread instead of a fork, and
share state directly. Serialise access to shared state with the wiringPi mutex
locks (see L</THREAD/LOCK FUNCTIONS>):

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

=head1 SERIAL FUNCTIONS

These functions provide basic access to read and write to a serial device.

=head2 serial_open($device, $baud)

Maps to C<int serialOpen(const char *device, const int baud)>

Opens a serial device for read/write access.

Parameters:

    $device

Mandatory, String: The name of the serial device, eg: C</dev/ttyACM0>.

    $baud

Mandatory, Integer: The speed of the serial device. (eg: C<9600>).

Return, Integer: The file descriptor of the device.

=head2 serial_close($fd)

Maps to C<void serialClose(const int fd)>

Closes an already open serial device.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

=head2 serial_flush($fd)

Maps to C<serialFlush(const int fd)>

Flushes the serial device's buffer.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

=head2 serial_data_avail($fd)

Maps to C<serialDataAvail(const int fd)>

Check if there is any data available on the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

=head2 serial_get_char($fd)

Maps to C<serialGetchar(const int fd)>

Read a single byte from the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

=head2 serial_put_char($fd, $char)

Maps to C<serialPutchar(const int fd, const unsigned char c)>

Write a single byte to the interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

    $char

Mandatory, Byte: A single byte to write to the serial interface.

=head2 serial_puts($fd, $string)

Maps to C<serialPuts(const int fd, const char* string)>

Write an arbitrary length string to the serial interface.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

    $string

Mandatory, String: The content to write to the device.

=head2 serial_gets($fd, $nbytes)

Reads up to C<$nbytes> bytes from the serial interface and returns them as a
single string.

The read blocks only until the port's configured read timeout (the C<VTIME>
value set by C<serial_open()>) elapses, so the returned string may be B<shorter>
than C<$nbytes> if fewer bytes arrived in time (or the device closed). The
result is binary-safe: embedded C<NUL> bytes and trailing whitespace are
preserved exactly as received.

Parameters:

    $fd

Mandatory, Integer: The file descriptor returned by your call to C<serial_open()>.

    $nbytes

Mandatory, Integer: The maximum number of bytes to read. Must be a non-negative
integer.

Returns: A string of the bytes actually read (length C<0> to C<$nbytes>). Croaks
on a read error.

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

Maps to C<int wiringPiI2CSetupInterface(const char* device, int devId)>

Like C<i2c_setup()>, but lets you name the I2C device file explicitly (e.g.
C</dev/i2c-1>) instead of relying on the default.

Parameters:

    $device

Mandatory: String, the path to the I2C device file (e.g. C</dev/i2c-1>).

    $addr

Mandatory: Integer, the I2C address of the device.

Returns: Integer, the file descriptor for the device (as C<i2c_setup()>).

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

=head2 i2c_read_block($fd, $reg, $size)

Maps to C<int wiringPiI2CReadBlockData(int fd, int reg, uint8_t *values, uint8_t size)>

Reads up to C<$size> bytes (max 255) in a single block transaction starting at
register C<$reg>.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to read from.

    $size

Mandatory: Integer C<0>-C<255>, the number of bytes to read.

Returns: A list of the bytes read (its length is the actual count returned by
the device). Croaks on a read error.

=head2 i2c_raw_read($fd, $size)

Maps to C<int wiringPiI2CRawRead(int fd, uint8_t *values, uint8_t size)>

As C<i2c_read_block()>, but reads directly from the device without a register
address.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from C<i2c_setup()>.

    $size

Mandatory: Integer C<0>-C<255>, the number of bytes to read.

Returns: A list of the bytes read. Croaks on a read error.

=head2 i2c_write_block($fd, $reg, \@bytes)

Maps to C<int wiringPiI2CWriteBlockData(int fd, int reg, const uint8_t *values, uint8_t size)>

Writes a block of up to 255 bytes in a single transaction starting at register
C<$reg>.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from C<i2c_setup()>.

    $reg

Mandatory: Integer, the register to write to.

    \@bytes

Mandatory: An array reference of byte values (C<0>-C<255>), at most 255 elements.

Returns: The value of the underlying call, C<0> on success.

=head2 i2c_raw_write($fd, \@bytes)

Maps to C<int wiringPiI2CRawWrite(int fd, const uint8_t *values, uint8_t size)>

As C<i2c_write_block()>, but writes directly to the device without a register
address.

Parameters:

    $fd

Mandatory: Integer, the file descriptor returned from C<i2c_setup()>.

    \@bytes

Mandatory: An array reference of byte values (C<0>-C<255>), at most 255 elements.

Returns: The value of the underlying call, C<0> on success.

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
        croak "failed to open the SPI bus...\n";
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

=head2 spi_get_fd($channel)

Maps to C<int wiringPiSPIGetFd(int channel)>

Returns the open file descriptor for an SPI channel that was previously set up.

Parameters:

    $channel

Mandatory: Integer, C<0> or C<1>.

=head2 spi_setup_mode($channel, $speed, $mode)

Maps to C<int wiringPiSPISetupMode(int channel, int speed, int mode)>

As C<spi_setup()>, but also selects the SPI mode (clock polarity/phase).

Parameters:

    $channel

Mandatory: Integer, C<0> or C<1>.

    $speed

Mandatory: Integer, the bus speed in Hz (e.g. C<1000000>).

    $mode

Mandatory: Integer C<0>-C<3>, the SPI mode.

Returns: Integer, the file descriptor on success or C<-1> on error.

=head2 spi_close($channel)

Maps to C<int wiringPiSPIClose(const int channel)>

Closes the given SPI channel, releasing its file descriptor.

Parameters:

    $channel

Mandatory: Integer, C<0> or C<1>.

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

The alternate-function map differs between the Broadcom SoC (Pi 0-4) and the RP1
chip on the Pi 5; see L</pin_mode_alt($pin, $alt)> for the mode values and the
per-SoC differences in what each one selects.

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

Same as L</digitalReadByte()>, but reads from the second group of eight GPIO pins.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

