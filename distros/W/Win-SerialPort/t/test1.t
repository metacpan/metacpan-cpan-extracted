use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 309;
}
cmp_ok($Win::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use Win::SerialPort qw( :STAT 0.20 );

use strict;
use warnings;

## verifies the (0, 1) list returned by binary functions
sub test_bin_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (1 == shift);
    return 1;
}

## verifies the (0, 255) list returned by byte functions
sub test_byte_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (255 == shift);
    return 1;
}

## verifies the (0, 0xffff) list returned by short functions
sub test_short_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (0xffff == shift);
    return 1;
}

## verifies the (0, 0xffffffff) list returned by long functions
sub test_long_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (0xffffffff == shift);
    return 1;
}

## verifies the value returned by byte functions
sub test_byte_value {
    my $v = shift;
    return undef if (($v < 0) or ($v > 255));
    return 1;
}

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

my $file = "COM1";
if ($SerialJunk::Makefile_Test_Port) {
    $file = $SerialJunk::Makefile_Test_Port;
}
if (exists $ENV{Makefile_Test_Port}) {
    $file = $ENV{Makefile_Test_Port};
}

if (@ARGV) {
    $file = shift @ARGV;
}
my $cfgfile = $file."_test.cfg";

my $fault = 0;
my $ob;
my $pass;
my $fail;
my $in;
my $in2;
my @opts;
my $out;
my $err;
my $blk;
my $e;
my $s="testing is a wonderful thing - this is a 60 byte long string";
#      123456789012345678901234567890123456789012345678901234567890
my $line = $s.$s.$s;		# about 185 MS at 9600 baud
my $tick;
my $tock;
my %required_param;
my @necessary_param = Win::SerialPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

## 2 - 6 SerialPort Global variable ($Babble);

is_bad(scalar Win::SerialPort::debug, 'no debug init');
ok(scalar Win::SerialPort::debug(1), 'set debug');
is_bad(scalar Win::SerialPort::debug(2), 'invalid set debug');
ok(scalar Win::SerialPort->debug(1), 'set debug');
ok(scalar Win::SerialPort::debug(), 'read debug state');

# 7 - 20: yes_true subroutine, no need to SHOUT if it works

ok( Win::SerialPort::debug("T"), 'yes_true() tests = T' );
ok( !Win::SerialPort::debug("F"), 'F');

{
    no strict 'subs';
    ok( Win::SerialPort::debug(T), 'T');
    ok(!Win::SerialPort::debug(F), 'F');
    ok( Win::SerialPort::debug(Y), 'Y');
    ok(!Win::SerialPort::debug(N), 'N');
    ok( Win::SerialPort::debug(ON), 'ON');
    ok(!Win::SerialPort::debug(OFF), 'OFF');
    ok( Win::SerialPort::debug(TRUE), 'TRUE');
    ok(!Win::SerialPort::debug(FALSE), 'FALSE');
    ok( Win::SerialPort::debug(Yes), 'Yes');
    ok(!Win::SerialPort::debug(No), 'No');
    ok( Win::SerialPort::debug("yes"), 'yes');
    ok(!Win::SerialPort::debug("f"), 'f');
}

@opts = Win::SerialPort::debug();
ok(test_bin_list(@opts), 'binary_opt_array');

# 21: Constructor

ok($ob = Win::SerialPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

#### 22 - 41: Check Port Capabilities 

ok($ob->can_baud, 'can_baud');
ok($ob->can_databits, 'can_databits');
ok($ob->can_stopbits, 'can_stopbits');
ok($ob->can_dtrdsr, 'can_dtrdsr');
ok($ob->can_handshake, 'can_handshake');
ok($ob->can_parity_check, 'can_parity_check');
ok($ob->can_parity_config, 'can_parity_config');
ok($ob->can_parity_enable, 'can_parity_enable');
ok($ob->can_rtscts, 'can_ctsrts');
ok($ob->can_rlsd, 'can_rlsd');
ok($ob->can_xonxoff, 'can_xonxoff');
ok($ob->can_interval_timeout, 'can_interval_timeout');
ok($ob->can_total_timeout, 'can_total_timeout');
ok($ob->can_xon_char, 'can_xon_char');
ok($ob->is_rs232, 'is_rs232');

is($ob->can_spec_char, 0, 'can_spec_char');
is($ob->can_ioctl, 0, 'can_ioctl');
is($ob->can_16bitmode, 0, 'can_16bitmode');
is_bad($ob->is_modem, 'is_modem');

## 42 - 61: Byte Capabilities

$in = $ob->xon_char;
ok(test_byte_value($in), 'xon_char value');
is_bad(scalar $ob->xon_char(500), 'byte limit');
@opts = $ob->xon_char;
ok(test_byte_list(@opts), 'xon_char range');
ok(scalar $ob->xon_char(0x11), 'set xon_char');

$in = $ob->xoff_char;
ok(test_byte_value($in), 'xoff_char value');
is_bad(scalar $ob->xoff_char(-1), 'byte limit');
@opts = $ob->xoff_char;
ok(test_byte_list(@opts), 'xoff_char range');
ok(scalar $ob->xoff_char(0x13), 'set xoff_char');

$in = $ob->eof_char;
ok(test_byte_value($in), 'eof_char value');
is_bad(scalar $ob->eof_char(500), 'byte limit');
@opts = $ob->eof_char;
ok(test_byte_list(@opts), 'eof_char range');
is(scalar $ob->eof_char(0), 0, 'set eof_char');

$in = $ob->event_char;
ok(test_byte_value($in), 'event_char value');
is_bad(scalar $ob->event_char(5000), 'byte limit');
@opts = $ob->event_char;
ok(test_byte_list(@opts), 'event_char range');
is(scalar $ob->event_char(0), 0, 'set event_char');

$in = $ob->error_char;
ok(test_byte_value($in), 'error_char value');
is_bad(scalar $ob->error_char(65600), 'byte limit');
@opts = $ob->error_char;
ok(test_byte_list(@opts), 'error_char range');
is(scalar $ob->error_char(0), 0, 'set error_char');

#### 62 - 92: Set Basic Port Parameters 

## 62 - 67: Baud (Valid/Invalid/Current)

@opts=$ob->baudrate;		# list of allowed values
ok(1 == grep(/^9600$/, @opts), '9600 baud in list');
ok(0 == grep(/^9601/, @opts), '9601 baud not in list'); # force scalar context

ok($in = $ob->baudrate, 'read baudrate');
ok(1 == grep(/^$in$/, @opts), "confirm $in in baud array");
is_bad(scalar $ob->baudrate(9601), 'cannot set 9601 baud');
ok($ob->baudrate(9600), 'can set 9600 baud');
    # leaves 9600 pending

## 68 - 73: Parity (Valid/Invalid/Current)

@opts=$ob->parity;		# list of allowed values
ok(1 == grep(/none/, @opts), 'parity none in list');
ok(0 == grep(/any/, @opts), 'parity any not in list');

ok($in = $ob->parity, 'read parity');
ok(1 == grep(/^$in$/, @opts), "confirm $in in parity array");

is_bad(scalar $ob->parity("any"), 'cannot set any parity');
ok($ob->parity("none"), 'can set none parity');
    # leaves "none" pending

## 74: Missing Param test

is_bad(scalar $ob->write_settings, 'write_settings prerequisites');

## 75 - 80- Databits (Valid/Invalid/Current)

@opts=$ob->databits;		# list of allowed values
ok(1 == grep(/8/, @opts), '8 databits in list');
ok(0 ==  grep(/4/, @opts), '4 databits not in list');

ok($in = $ob->databits, 'read databits');
ok(1 == grep(/^$in$/, @opts), 'confirm $in databits in list');

is_bad(scalar $ob->databits(3), 'cannot set 3 databits');
ok($ob->databits(8), 'can set 8 databits');
    # leaves 8 pending

## 81 - 86: Stopbits (Valid/Invalid/Current)

@opts=$ob->stopbits;		# list of allowed values
ok(1 == grep(/2/, @opts), '2 stopbits in list');
ok(0 == grep(/2.5/, @opts), '2.5 stopbits not in list');

ok($in = $ob->stopbits, 'read stopbits');
ok(1 == grep(/^$in$/, @opts), "confirm $in stopbits in list");

is_bad(scalar $ob->stopbits(3), 'cannot set 3 stopbits');
ok($ob->stopbits(1), 'can set 1 stopbit');
    # leaves 1 pending

## 87 - 92: Handshake (Valid/Invalid/Current)

@opts=$ob->handshake;		# list of allowed values
ok(1 == grep(/none/, @opts), 'handshake none in list');
ok(0 ==  grep(/moo/, @opts), 'handshake moo not in list');

ok($in = $ob->handshake, 'read handshake');
ok(1 == grep(/^$in$/, @opts), "confirm handshake $in in list");

is_bad(scalar $ob->handshake("moo"), 'cannot set handshake moo');
ok($ob->handshake("rts"), 'can set handshake rts');

## 93 - 99: Buffer Size

($in, $out) = $ob->buffer_max(512);
is_bad(defined $in, 'invalid buffer_max command');
($in, $out) = $ob->buffer_max;
ok(defined $in, 'read in buffer_max');
ok(defined $out, 'read out buffer_max');

if (($in > 0) and ($in < 4096))		{ $in2 = $in; } 
else					{ $in2 = 4096; }

if (($out > 0) and ($out < 4096))	{ $err = $out; } 
else					{ $err = 4096; }

ok(scalar $ob->buffers($in2, $err), 'valid set buffer_max');

@opts = $ob->buffers(4096, 4096, 4096);
is_bad(defined $opts[0], 'invalid buffers command');
($in, $out)= $ob->buffers;
ok($in2 == $in, 'check buffers in setting');
ok($out == $err, 'check buffers out setting');

## 100 - 102: Alias and Device

is($ob->alias, $file, 'original alias from new');
is($ob->alias("TestPort"), 'TestPort', 'set alias');
if ($file =~ /^COM\d+$/io) {
	is($ob->device, '\\\\.\\'.$file, 'device from new');
} else {
	is($ob->device, $file, 'original device from new');
}

## 103 - 108: Read Timeouts

@opts = $ob->read_interval;
ok(test_long_list(@opts), 'read_interval range');
is($ob->read_interval(0xffffffff), 0xffffffff, 'set read_interval');

@opts = $ob->read_const_time;
ok(test_long_list(@opts), 'read_const_time range');
is($ob->read_const_time(0), 0, 'set read_const_time');

@opts = $ob->read_char_time;
ok(test_long_list(@opts), 'read_char_time range');
is($ob->read_char_time(0), 0, 'set read_char_time');

## 109 - 112: Write Timeouts

@opts = $ob->write_const_time;
ok(test_long_list(@opts), 'write_const_time range');
is($ob->write_const_time(200), 200, 'set write_const_time');

@opts = $ob->write_char_time;
ok(test_long_list(@opts), 'write_char_time range');
is($ob->write_char_time(10), 10, 'set write_char_time');

## 113 - 116: Other Parameters (Defaults)

is($ob->binary(1), 1, 'binary');

is($ob->parity_enable(0), 0, 'parity_enable');

@opts = $ob->xon_limit;
ok(test_short_list(@opts), 'xon_limit range');

@opts = $ob->xoff_limit;
ok(test_short_list(@opts), 'xoff_limit range');

## 117 - 119: Finish Initialize

is($ob->write_settings, 1, 'write_settings');

is($ob->xon_limit(100), 100, 'xon_limit');
is($ob->xoff_limit(200), 200, 'xoff_limit');

## 120 - 137: Constants from Package

is($ob->BM_fCtsHold, 1, 'constant BM_fCtsHold');
is($ob->BM_fDsrHold, 2, 'constant BM_fDsrHold');
is($ob->BM_fRlsdHold, 4, 'constant BM_fRlsdHold');
is($ob->BM_fXoffHold, 8, 'constant BM_fXoffHold');
is($ob->BM_fXoffSent, 0x10, 'constant BM_fXoffSent');
is($ob->BM_fEof, 0x20, 'constant BM_fEof');
is($ob->BM_fTxim, 0x40, 'constant BM_fTxim');

is($ob->MS_CTS_ON, 0x10, 'constant MS_CTS_ON');
is($ob->MS_DSR_ON, 0x20, 'constant MS_DSR_ON');
is($ob->MS_RING_ON, 0x40, 'constant MS_RING_ON');
is($ob->MS_RLSD_ON, 0x80, 'constant MS_RLSD_ON');

is($ob->CE_RXOVER, 0x1, 'constant CE_RXOVER');
is($ob->CE_OVERRUN, 0x2, 'constant CE_OVERRUN');
is($ob->CE_RXPARITY, 0x4, 'constant CE_RXPARITY');
is($ob->CE_FRAME, 0x8, 'constant CE_FRAME');
is($ob->CE_BREAK, 0x10, 'constant CE_BREAK');
is($ob->CE_TXFULL, 0x100, 'constant CE_TXFULL');
is($ob->CE_MODE, 0x8000, 'constant CE_MODE');

## 138 - 144: Status

is($ob->purge_all, 1, 'purge_all');
@opts = $ob->status;
is(scalar @opts, 4, 'status');

# for an unconnected port, should be $in=0, $out=0, $blk=1 (no CTS), $err=0
# USB and virtual ports can be different, but stil 4 elements

($blk, $in, $out, $err)=@opts;
# warn "WCB status: $blk, $in, $out, $err\n";

ok(defined $blk, 'blocking byte');
ok(defined $in, 'input count');
ok(defined $out, 'output count');
ok(defined $err, 'error byte');

## xxx - xxx: Optional Messages

@opts = $ob->user_msg;
ok(test_bin_list(@opts), 'user_msg_array');
is(scalar $ob->user_msg, 0, 'user_msg init OFF');
is(scalar $ob->user_msg(1), 1, 'user_msg ON');

@opts = $ob->error_msg;
ok(test_bin_list(@opts), 'error_msg_array');
is(scalar $ob->error_msg, 0, 'error_msg init OFF');
is($ob->error_msg(1), 1, 'error_msg ON');

is($ob->handshake("none"), 'none', 'set handshake none');

## 145 - 150: Save Configuration
## (before any writes which might confuse USB driver)

ok(scalar $ob->save($cfgfile), 'save');

is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, 'none', 'parity');
is($ob->handshake, 'none', 'set handshake none');
is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');

## 151 - 180: No Handshake, Polled Write, $BUFFEROUT detection

$tick=$ob->get_tick_count;
is($ob->write($line), 180, 'write 180 characters');
$tock=$ob->get_tick_count;

$err=$tock - $tick;
if ($err < 120) {
	$BUFFEROUT = 1;	# USB and virtual ports can't test output timing
}
if ($BUFFEROUT) {
	is_bad ($err > 300, 'skip write timing');
} else {
	is_bad (($err < 120) or ($err > 300), 'write timing');
}
print "<185> elapsed time=$err\n";

ok(defined $ob->reset_error, 'reset_error');
	
SKIP: {
    skip "Can't rely on status and no input", 26 if $BUFFEROUT;
    ($blk, $in, $out, $err)=$ob->status;
    is($blk, 0, 'blocking bits');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');

    ## 131 - 136: Block by DSR without Output

    is($ob->handshake("dtr"), 'dtr', 'set handshake dtr');

    ($blk, $in, $out, $err)=$ob->status;
    is($blk, $ob->BM_fDsrHold, 'DSR blocking bits');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');

    ## 137 - 141: Unsent XOFF without Output

    is($ob->handshake("xoff"), 'xoff', 'set handshake xoff');

    ($blk, $in, $out, $err)=$ob->status;
    is($blk, 0, 'blocking bits');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');

    ## 142 - 150: Block by XOFF without Output

    ok($ob->xoff_active, 'xoff active');
    ok(scalar $ob->transmit_char(0x33), 'transmit xoff');

    $in2=($ob->BM_fXoffHold | $ob->BM_fTxim);
    ($blk, $in, $out, $err)=$ob->status;
    ok($blk & $in2, 'XoffHold or Txim');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');

    ok($ob->xon_active, 'xon_active');
    ($blk, $in, $out, $err)=$ob->status;
    is($blk, 0, 'blocking bits');
    is($in, 0, 'input bytes');
    is($err, 0, 'error bytes');

    ## 151 - 152: No Handshake

    is($ob->handshake("none"), 'none', 'set handshake none');
    ok(scalar $ob->purge_all, 'purge_all');
}

ok(defined $ob->reset_error, 'reset_error');

## 187 - xxx: Check Saved Configuration

ok($ob->close, 'close');
undef $ob;

## 188 - 190: Check File Headers

ok(open(CF, "$cfgfile"), 'open config file');
my ($signature, $name, @values) = <CF>;
close CF;

ok(1 == grep(/SerialPort_Configuration_File/, $signature), 'signature');

chomp $name;
if ($file =~ /^COM\d+$/io) {
	is($name, '\\\\.\\'.$file, 'config file device');
} else {
	is($name, $file, 'config file device');
}

## 191 - 192: Check that Values listed exactly once

$fault = 0;
foreach $e (@values) {
    chomp $e;
    ($in, $out) = split(',',$e);
    $fault++ if ($out eq "");
    $required_param{$in}++;
    }
is($fault, 0, 'no duplicate values exist');

$fault = 0;
foreach $e (@necessary_param) {
    $fault++ unless ($required_param{$e} ==1);
    }
is($fault, 0, 'all required keys appear once');

## 193 - 125: Reopen as Tie

    # constructor = TIEHANDLE method

ok ($ob = tie(*PORT,'Win::SerialPort', $cfgfile), 'tie');
die unless ($ob);    # next tests would die at runtime

SKIP: {
    skip "Tied filehandle timing and CRLF conversions", 35 if $BUFFEROUT;

    # tie to PRINT method
    $tick=$ob->get_tick_count;
    $pass=print PORT $line;
    is($pass, 1, 'PRINT method');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 160) or ($err > 245), 'write timing');
    print "<195> elapsed time=$err\n";

    # tie to PRINTF method
    $tick=$ob->get_tick_count;
    $pass=printf PORT "123456789_%s_987654321", $line;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINTF method');
    $err=$tock - $tick;
    is_bad (($err < 180) or ($err > 265), 'write timing');
    print "<215> elapsed time=$err\n";

    is($ob->read_const_time(300), 300, 'read_const_time');
    is($ob->read_char_time(20), 20, 'read_char_time');
    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(10);
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;

    is($in, 0, 'read disconnected port');
    unless ($in == 0) {
	    die "\nLooks like you have a modem on the serial port!\n".
       		"Please turn it off, or remove it and restart the tests.\n";
    }
    ok ($in2 eq "", 'no data');
    $err=$tock - $tick;
    is_bad (($err < 475) or ($err > 585), 'read timeout');
    print "<500> elapsed time=$err\n";
    is ($ob->read_char_time(0), 0, 'reset read_char_time');
    $tick=$ob->get_tick_count;
    $in2= getc PORT;
    $tock=$ob->get_tick_count;

    is_bad (defined $in2, 'getc');
    $err=$tock - $tick;
    is_bad (($err < 275) or ($err > 365), 'getc timeout');
    print "<300> elapsed time=$err\n";

    is ($ob->read_const_time(0), 0, 'reset read_const_time');
    $tick=$ob->get_tick_count;
    $in2= getc PORT;
    $tock=$ob->get_tick_count;

    is_bad (defined $in2);
    $err=$tock - $tick;
    is_bad ($err > 50);
    print "<0> elapsed time=$err\n";

    # output conversion defaults: -opost onlcr -ocrnl
    $e = "\r"x100;
    $e .= "\n"x160;
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'default no conversion');
    $err=$tock - $tick;
    is_bad (($err < 250) or ($err > 300), 'default timing');
    ## 260 characters, no mods
    print "<275> elapsed time=$err\n";
    
    is($ob->stty_opost(1), 1, 'opost');
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'opost conversion');
    $err=$tock - $tick;
    ## 100 "\r" + 160 "\r"=>"\r\n" = 420 characters
    is_bad (($err < 410) or ($err > 465), 'opost timing');
    print "<435> elapsed time=$err\n";
    
    is($ob->stty_ocrnl(1), 1, 'ocrnl');
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'ocrnl conversion');
    $err=$tock - $tick;
    ## 100 "\r"=>"\n" which gives 260 "\n"=>"\r\n" = 520 characters
    is_bad (($err < 510) or ($err > 575), 'ocrnl timing');
    print "<535> elapsed time=$err\n";
    
    is($ob->stty_opost(0), 0, 'opost off');
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'opost conversion off');
    $err=$tock - $tick;
    ## back to 260 characters with processing disabled
    is_bad (($err < 250) or ($err > 300), 'opost off timing');
    print "<275> elapsed time=$err\n";
    
    is($ob->stty_opost(1), 1, 'opost on');
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'opost conversion on');
    $err=$tock - $tick;
    ## returning to 520 characters when enabled again
    is_bad (($err < 510) or ($err > 575), 'opost timing');
    print "<535> elapsed time=$err\n";
    
    is($ob->stty_ocrnl(0), 0, 'ocrnl off');
    $tick=$ob->get_tick_count;
    $pass=print PORT $e;
    $tock=$ob->get_tick_count;
    
    is($pass, 1, 'ocrnl conversion off');
    $err=$tock - $tick;
    ## stop just the "\r=>"\n" so 420 characters
    is_bad (($err < 410) or ($err > 465), 'ocrnl off timing');
    print "<435> elapsed time=$err\n";
    
        # tie to READLINE method
    is ($ob->read_const_time(500), 500, 'read_const_time');
    $tick=$ob->get_tick_count;
    $fail = <PORT>;
    $tock=$ob->get_tick_count;
    
    is_bad(defined $fail, 'READLINE');
    $err=$tock - $tick;
    is_bad (($err < 480) or ($err > 540), 'READLINE timeout');
    print "<500> elapsed time=$err\n";
}

## 195 - 204: Port in Use (new + quiet)

my $ob2;
is_bad ($ob2 = Win::SerialPort->new ($file), 'in use new');
is_bad (defined $ob2, 'returns undef');
is ($ob2 = Win::SerialPort->new ($file, 1), 0, 'zero if quiet');
is_bad ($ob2 = Win::SerialPort->new ($file, 0), 'quiet off');
is_bad (defined $ob2, 'back to undef');

is_bad ($ob2 = WinAPI::CommPort->new ($file), 'CommPort new');
is_bad (defined $ob2, 'undef in use');
is ($ob2 = WinAPI::CommPort->new ($file, 1), 0, 'except zero if quiet');
is_bad ($ob2 = WinAPI::CommPort->new ($file, 0), 'not quiet');
is_bad (defined $ob2, 'CommPort undef');

## 225 - 278: Other DCB bits

      # for handshake == "none"
is($ob->output_dsr, 0, 'output_dsr');
is($ob->output_cts, 0, 'output_cts');
is($ob->input_xoff, 0, 'input_xoff');
is($ob->output_xoff, 0, 'output_xoff');

is($ob->ignore_null(0), 0, 'ignore_null');
is($ob->ignore_no_dsr(0), 0, 'ignore_no_dsr');

is($ob->subst_pe_char(0), 0, 'subst_pe_error');
is($ob->abort_on_error(0), 0, 'abort_on_error');
is($ob->tx_on_xoff(0), 0, 'tx_on_xoff');

is($ob->ignore_null, 0, 'ignore_null');
ok($ob->ignore_null(1), 'ignore_null_on');
ok($ob->ignore_null, 'ignore_null');
is($ob->ignore_null(0), 0, 'ignore_null_off');
is($ob->ignore_null, 0, 'ignore_null');

is($ob->ignore_no_dsr, 0, 'ignore_no_dsr');
ok($ob->ignore_no_dsr(1), 'ignore_no_dsr on');
ok($ob->ignore_no_dsr, 'ignore_no_dsr');
is($ob->ignore_no_dsr(0), 0, 'ignore_no_dsr off');
is($ob->ignore_no_dsr, 0, 'ignore_no_dsr');

is($ob->subst_pe_char, 0, 'subst_pe_char');
ok($ob->subst_pe_char(1), 'subst_pe_char on');
ok($ob->subst_pe_char, 'subst_pe_char');
is($ob->subst_pe_char(0), 0, 'subst_pe_char off');
is($ob->subst_pe_char, 0, 'subst_pe_char');

is($ob->abort_on_error, 0, 'abort_on_error');
ok($ob->abort_on_error(1), 'abort_on_error on');
ok($ob->abort_on_error, 'abort_on_error');
is($ob->abort_on_error(0), 0, 'abort_on_error off');
is($ob->abort_on_error, 0, 'abort_on_error');

is($ob->tx_on_xoff, 0, 'tx_on_xoff');
ok($ob->tx_on_xoff(1), 'tx_on_xoff on');
ok($ob->tx_on_xoff, 'tx_on_xoff');
is($ob->tx_on_xoff(0), 0, 'tx_on_xoff off');
is($ob->tx_on_xoff, 0, 'tx_on_xoff');

is($ob->handshake("dtr"), 'dtr', 'handshake dtr');
ok($ob->output_dsr, 'output_dsr');
is($ob->output_cts, 0, 'output_cts');
is($ob->input_xoff, 0, 'input_xoff');
is($ob->output_xoff, 0, 'output_xoff');

is($ob->handshake("rts"), 'rts', 'handshake rts');
is($ob->output_dsr, 0, 'output_dsr');
ok($ob->output_cts, 'output_cts');
is($ob->input_xoff, 0, 'input_xoff');
is($ob->output_xoff, 0, 'output_xoff');

is($ob->handshake("xoff"), 'xoff', 'handshake xoff');
is($ob->output_dsr, 0, 'output_dsr');
is($ob->output_cts, 0, 'output_cts');
ok($ob->input_xoff, 'input_xoff');
ok($ob->output_xoff, 'output_xoff');

is($ob->handshake("none"), 'none', 'handshake none');
is($ob->output_dsr, 0, 'output_dsr');
is($ob->output_cts, 0, 'output_cts');
is($ob->input_xoff, 0, 'input_xoff');
is($ob->output_xoff, 0, 'output_xoff');

## 259 - 2xx: Pulsed DCB bits

    ok ($ob->dtr_active(0), 'dtr inactive');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_on(100), 'pulse_dtr_on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 180) or ($err > 240), 'pulse dtr timing');
    print "<200> elapsed time=$err\n";

    ok ($ob->dtr_active(1), 'dtr active');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_off(200), 'pulse_dtr_off');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 370) or ($err > 450), 'dtr off timing');
    print "<400> elapsed time=$err\n";

    ok ($ob->rts_active(0), 'rts inactive');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_rts_on(150), 'pulse_rts_on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 275) or ($err > 345), 'rts on timing');
    print "<300> elapsed time=$err\n";

    ok ($ob->rts_active(1), 'rts active');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_rts_off(50), 'pulse_rts_off');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 80) or ($err > 130), 'rts off timing');
    print "<100> elapsed time=$err\n";

    $tick=$ob->get_tick_count;
    ok ($ob->pulse_break_on(50), 'pulse break on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 80) or ($err > 130), 'break timing');
    print "<100> elapsed time=$err\n";

    ok ($ob->rts_active(0), 'rts inactive');
    ok ($ob->dtr_active(0), 'dtr inactive');


    # destructor = CLOSE method
    ok(close PORT, 'close');				# 275

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!
untie *PORT;

