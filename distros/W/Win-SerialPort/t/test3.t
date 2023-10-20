use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 264;
}
cmp_ok($AltPort::VERSION, '>=', 0.20, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use AltPort qw( :STAT :PARAM 0.20 );

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

is(AltPort::nocarp, 0, 'nocarp');				# 2
my @necessary_param = AltPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

# 3: Constructor

ok($ob = AltPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

is($ob->debug, 0, 'no debug init');
is($ob->debug(1), 1, 'set debug');
is($ob->debug(2), 0, 'invalid set debug');
is($ob->debug(1), 1, 'set debug');
is($ob->debug, 1, 'read debug state');
is($ob->debug(0), 0, 'set and read debug off');

#### 20 - 38: Check Port Capabilities 

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

## 25 - 44: Byte Capabilities

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

#### 45 - 93: Set Basic Port Parameters wth are_xx and is_xx 

## set once with valid values before trying invalid

ok($pass = $ob->is_baudrate, 'existing baudrate');
is(scalar $ob->is_baudrate($pass), $pass, "valid set $pass baud");
ok($pass = $ob->is_parity, 'existing parity');
is(scalar $ob->is_parity($pass), $pass, "valid set $pass parity");

## 57: Missing Param test

is_bad(scalar $ob->write_settings, 'write_settings prerequisites missing');

ok($pass = $ob->is_databits, 'existing databits');
is($ob->is_databits($pass), $pass, "valid set $pass databits");
ok($pass = $ob->is_stopbits, 'existing stopbits');
is($ob->is_stopbits($pass), $pass, "valid set $pass stopbits");
ok($pass = $ob->is_handshake, 'existing handshake');
is($ob->is_handshake($pass), $pass, "valid set $pass handshake");

ok(scalar $ob->write_settings, 'write_settings prerequisites');

## 45 - 50: Baud (Valid/Invalid/Current)

@opts=$ob->are_baudrate;
ok(1 == grep(/^9600$/, @opts), '9600 baud in list');
ok(0 == grep(/^9601$/, @opts), '9601 baud not in list');

ok($in = $ob->is_baudrate, 'read is_baudrate');
ok(1 == grep(/^$in$/, @opts), "confirm $in in list");

is_bad(scalar $ob->is_baudrate(9601), 'cannot set 9601 baud');
is(scalar $ob->is_baudrate(9600), 9600, 'can set 9600 baud');
    # leaves 9600 pending

## 51 - 56: Parity (Valid/Invalid/Current)

@opts=$ob->are_parity;
ok(1 == grep(/none/, @opts), 'parity none in list');
ok(0 == grep(/any/, @opts), 'parity any not in list');

ok($in = $ob->is_parity, 'read is_parity');
ok(1 == grep(/^$in$/, @opts), "confirm $in in list");

is_bad(scalar $ob->is_parity("any"), 'cannot set any parity');
is(scalar $ob->is_parity("none"), 'none', 'can set none parity');
    # leaves "none" pending

## 58 - 63: Databits (Valid/Invalid/Current)

@opts=$ob->are_databits;
ok(1 == grep(/8/, @opts), 'databits 8 in list');
ok(0 == grep(/4/, @opts), 'databits 4 not in list');

ok($in = $ob->is_databits, 'read is_databits');
ok(1 == grep(/^$in$/, @opts), "confirm $in in list");

is_bad(scalar $ob->is_databits(3), 'cannot set 3 databits');
is($ob->is_databits(8), 8, 'can set 8 databits');
    # leaves 8 pending


## 64 - 69: Stopbits (Valid/Invalid/Current)

@opts=$ob->are_stopbits;
ok(1 == grep(/^1$/, @opts), 'one stopbit in list');
ok(0 == grep(/3/, @opts), 'three stopbits not in list');

ok($in = $ob->is_stopbits, 'read is_stopbits');
ok(1 == grep(/^$in$/, @opts), "confirm $in in list");

is_bad(scalar $ob->is_stopbits(3), 'cannot set 3 stopbits');
is($ob->is_stopbits(1), 1, 'can set 1 stopbit');
    # leaves 1 pending


## 70 - 75: Handshake (Valid/Invalid/Current)

@opts=$ob->are_handshake;
ok(1 == grep(/none/, @opts), 'handshake none in list');
ok(0 == grep(/moo/, @opts), 'handshake moo not in list');

ok($in = $ob->is_handshake, 'read is_handshake');
ok(1 == grep(/^$in$/, @opts), "confirm $in in list");

is_bad(scalar $ob->is_handshake("moo"), 'cannot set moo handshake');
is($ob->is_handshake("rts"), 'rts', 'can set rts handshake');
    # leaves "rts" pending for status

## 76 - 81: Buffer Size

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

## 82: Alias and Device

is($ob->alias, $file, 'original alias from new');
is($ob->alias("TestPort"), 'TestPort', 'set alias');
if ($file =~ /^COM\d+$/io) {
	is($ob->device, '\\\\.\\'.$file, 'device from new');
} else {
	is($ob->device, $file, 'original device from new');
}

## 83 - 88: Read Timeouts

@opts = $ob->read_interval;
ok(test_long_list(@opts), 'read_interval range');
is($ob->read_interval(0xffffffff), 0xffffffff, 'set read_interval');

@opts = $ob->read_const_time;
ok(test_long_list(@opts), 'read_const_time range');
is($ob->read_const_time(0), 0, 'set read_const_time');

@opts = $ob->read_char_time;
ok(test_long_list(@opts), 'read_char_time range');
is($ob->read_char_time(0), 0, 'set read_char_time');

## 89 - 92: Write Timeouts

@opts = $ob->write_const_time;
ok(test_long_list(@opts), 'write_const_time range');
is($ob->write_const_time(200), 200, 'set write_const_time');

@opts = $ob->write_char_time;
ok(test_long_list(@opts), 'write_char_time range');
is($ob->write_char_time(10), 10, 'set write_char_time');

## 93 - 96: Other Parameters (Defaults)

is($ob->binary(1), 1, 'binary');

is($ob->parity_enable(0), 0, 'parity_enable');

@opts = $ob->xon_limit;
ok(test_short_list(@opts), 'xon_limit range');

@opts = $ob->xoff_limit;
ok(test_short_list(@opts), 'xoff_limit range');

## 97 - 99: Finish Initialize

is($ob->write_settings, 1, 'write_settings');

is($ob->xon_limit(100), 100, 'xon_limit');
is($ob->xoff_limit(200), 200, 'xoff_limit');

## 100 - 130: Constants from Package

no strict 'subs';
is(BM_fCtsHold, 1, 'BM_fCtsHold');
is(BM_fDsrHold, 2, 'BM_fDsrHold');
is(BM_fRlsdHold, 4, 'BM_fRlsdHold');
is(BM_fXoffHold, 8, 'BM_fXoffHold');
is(BM_fXoffSent, 0x10, 'BM_fXoffSent');
is(BM_fEof, 0x20, 'BM_fEof');
is(BM_fTxim, 0x40, 'BM_fTxim');
is(BM_AllBits, 0x7f, 'BM_AllBits');

is(MS_CTS_ON, 0x10, 'MS_CTS_ON');

is(MS_DSR_ON, 0x20, 'MS_DSR_ON');
is(MS_RING_ON, 0x40, 'MS_RING_ON');
is(MS_RLSD_ON, 0x80, 'MS_RLSD_ON');

is(CE_RXOVER, 0x1, 'CE_RXOVER');
is(CE_OVERRUN, 0x2, 'CE_OVERRUN');
is(CE_RXPARITY, 0x4, 'CE_RXPARITY');
is(CE_FRAME, 0x8, 'CE_FRAME');
is(CE_BREAK, 0x10, 'CE_BREAK');
is(CE_TXFULL, 0x100, 'CE_TXFULL');
is(CE_MODE, 0x8000, 'CE_MODE');

is(ST_BLOCK, 0x0, 'ST_BLOCK');
is(ST_INPUT, 0x1, 'ST_INPUT');
is(ST_OUTPUT, 0x2, 'ST_OUTPUT');
is(ST_ERROR, 0x3, 'ST_ERROR');

is(LONGsize, 0xffffffff, 'LONGsize');
is(SHORTsize, 0xffff, 'SHORTsize');
is($ob->nocarp, 0x1, 'nocarp');
is(yes_true("F"), 0x0, 'yes_true("F")');
is(yes_true("T"), 0x1, 'yes_true("T")');
use strict 'subs';

## 118 - 123: Status

is($ob->purge_all, 1, 'purge_all');
@opts = $ob->status;
is(scalar (@opts = $ob->status), 4, 'status array');

# for an unconnected port, should be $in=0, $out=0, $blk=1 (no CTS), $err=0
($blk, $in, $out, $err)=@opts;

## 124 - 130: No Handshake, Polled Write

is($ob->handshake("none"), 'none', 'set handshake none');

# A test to check $BUFFEROUT
$tick=$ob->get_tick_count;
is($ob->write($line), 180, 'write 180 characters');
$tock=$ob->get_tick_count;

my $delay=$tock - $tick;
if ($delay < 120) {
	$BUFFEROUT = 1;	# USB and virtual ports can't test output timing
}
if ($BUFFEROUT) {
	# USB and virtual ports can be different, but stil 4 elements
	ok(defined $blk, 'blocking byte');
	ok(defined $in, 'input count');
	ok(defined $out, 'output count');
	ok(defined $err, 'error byte');
	is_bad ($delay > 300, 'skip write timing');
} else {
	is($blk, $ob->BM_fCtsHold, 'blocking bit CTS');
	is($in, 0, 'input count');
	is($out, 0, 'output count');
	is($err, 0, 'error bits');
	is_bad (($delay < 120) or ($delay > 300), 'write timing');
}
print "<185> elapsed time=$delay\n";

ok(defined $ob->reset_error, 'reset_error');
	
SKIP: {
    skip "Can't rely on status or no input", 14 if $BUFFEROUT;
    ($blk, $in, $out, $err)=$ob->status;
    is($blk, 0, 'blocking bits');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');

    ## 141 - 146: Block by DSR without Output

    is($ob->handshake("dtr"), 'dtr', 'set handshake dtr');

    ($blk, $in, $out, $err)=$ob->status;
    is($blk, BM_fDsrHold, 'DSR blocking bits');
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
}

## 142 - 150: Block by XOFF without Output

ok($ob->xoff_active, 'xoff active');

ok(scalar $ob->xmit_imm_char(0x33), 'transmit xoff');

SKIP: {
    skip "Can't rely on status or no input", 4 if $BUFFEROUT;
    $in2=(BM_fXoffHold | BM_fTxim);
    ($blk, $in, $out, $err)=$ob->status;
    ok($blk & $in2, 'XoffHold or Txim');
    is($in, 0, 'input bytes');
    is($out, 0, 'output bytes');
    is($err, 0, 'error bytes');
}

ok($ob->xon_active, 'xon_active');
($blk, $in, $out, $err)=$ob->status;

SKIP: {
    skip "Can't rely on status or no input", 3 if $BUFFEROUT;
    is($blk, 0, 'blocking bits');
    is($in, 0, 'input bytes');
    is($err, 0, 'error bytes');
}

## 151 - 152: No Handshake

is($ob->handshake("none"), 'none', 'set handshake none');
ok(scalar $ob->purge_all, 'purge_all');
ok(defined $ob->reset_error, 'reset_error');

## 153 - 158: Optional Messages

@opts = $ob->user_msg;
ok(test_bin_list(@opts), 'user_msg_array');
is(scalar $ob->user_msg, 0, 'user_msg init OFF');
is(scalar $ob->user_msg(1), 1, 'user_msg ON');

@opts = $ob->error_msg;
ok(test_bin_list(@opts), 'error_msg_array');
is(scalar $ob->error_msg, 0, 'error_msg init OFF');
is($ob->error_msg(1), 1, 'error_msg ON');

## 96 - 164: Save and Check Configuration

ok(scalar $ob->save($cfgfile), 'save');

is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, 'none', 'parity');

is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');

## 174 - 187: Other Misc. Tests

ok(scalar $ob->can_rlsd_config, 'can_rlsd_config');
ok($ob->suspend_tx, 'suspend_tx');
is(scalar $ob->dtr_active(1), 1, 'dtr_active ON');
is(scalar $ob->rts_active(1), 1, 'rts_active ON');
is(scalar $ob->break_active(1), 1, 'break_active ON');
if ($BUFFEROUT) {
	ok(defined $ob->modemlines, 'modemlines');
} else {
	is($ob->modemlines, 0, 'modemlines');
}

sleep 1;

ok($ob->resume_tx, 'resume_tx');
is(scalar $ob->dtr_active(0), 1, 'dtr_active OFF');
is(scalar $ob->rts_active(0), 1, 'rts_active OFF');
is(scalar $ob->break_active(0), 1, 'break_active OFF');
if ($BUFFEROUT) {
	ok(defined $ob->modemlines, 'modemlines');
} else {
	is($ob->modemlines, 0, 'modemlines');
}
is($ob->debug_comm(1), 1, 'debug_comm ON');
is($ob->debug_comm(0), 0, 'debug_comm OFF');

is($ob->close, 1, 'close');
undef $ob;

## 102 - 105: Check File Headers

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

## 106 - 107: Check that Values listed exactly once

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

## 93 - 125: Reopen as Tie

    # constructor = TIEHANDLE method

ok ($ob = tie(*PORT,'Win::SerialPort', $cfgfile), 'tie');
die unless ($ob);    # next tests would die at runtime

SKIP: {
    skip "Tied timing and output separators", 33 if $BUFFEROUT;

    # tie to PRINT method
    $tick=$ob->get_tick_count;
    $pass=print PORT $line;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINT method');
    $err=$tock - $tick;
    is_bad (($err < 160) or ($err > 245), 'write timing');
    print "<185> elapsed time=$err\n";

    # tie to PRINTF method
    $tick=$ob->get_tick_count;
    $pass=printf PORT "123456789_%s_987654321", $line;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINTF method');
    $err=$tock - $tick;
    is_bad (($err < 180) or ($err > 235));
    print "<205> elapsed time=$err\n";

    # tie to READLINE method
    is ($ob->read_const_time(500), 500, 'READLINE timeout');
    $tick=$ob->get_tick_count;
    $fail = <PORT>;
    $tock=$ob->get_tick_count;
    is_bad(defined $fail);
    $err=$tock - $tick;
    is_bad (($err < 480) or ($err > 540));
    print "<500> elapsed time=$err\n";
#7
    ## 201 - 215: Record and Field Separators

    my $r = "I am the very model of an output record separator";	## =49
    #        1234567890123456789012345678901234567890123456789
    my $f = "The fields are alive with the sound of music";		## =44
    my $ff = "$f, with fields they have sung for a thousand years";	## =93
    my $rr = "$r, not animal or vegetable or mineral or any other";	## =98

    is($ob->output_record_separator, "", 'output_record_separator');
    is($ob->output_field_separator, "", 'output_field_separator');
    $, = "";
    $\ = "";

    # tie to PRINT method
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINT method, multiple strings');
    $err=$tock - $tick;
    is_bad (($err < 160) or ($err > 210), 'write timing');
    print "<185> elapsed time=$err\n";

    is($ob->output_field_separator($f), "", 'output_field_separator');
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINT method, alt field separator');
    $err=$tock - $tick;
    is_bad (($err < 260) or ($err > 310), 'write timing');
    print "<275> elapsed time=$err\n";

    is($ob->output_record_separator($r), "", 'output_record_separator');
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINT method, alt record separator');
    $err=$tock - $tick;
    is_bad (($err < 310) or ($err > 360), 'write timing');
    print "<325> elapsed time=$err\n";
#17
    is($ob->output_record_separator, $r, 'alt record separator');
    is($ob->output_field_separator, $f, 'alt field separator');
    $, = $ff;
    $\ = $rr;
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;

    $, = "";
    $\ = "";
    is($pass, 1, 'PRINT method, alt $, and $\\');
    $err=$tock - $tick;
    is_bad (($err < 310) or ($err > 360), 'write timing');
    print "<325> elapsed time=$err\n";

    $, = $ff;
    $\ = $rr;
    is($ob->output_field_separator(""), $f, 'alt field separator');
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;

    $, = "";
    $\ = "";
    is($pass, 1, 'PRINT method, normal $, and $\\');
    $err=$tock - $tick;
    is_bad (($err < 410) or ($err > 460), 'write timing');
    print "<425> elapsed time=$err\n";

    $, = $ff;
    $\ = $rr;
    is($ob->output_record_separator(""), $r, 'output_record_separator');
    $tick=$ob->get_tick_count;
    $pass=print PORT $s, $s, $s;
    $tock=$ob->get_tick_count;

    $, = "";
    $\ = "";
    is($pass, 1, 'PRINT method, normal $, and $\\');
    $err=$tock - $tick;
    is_bad (($err < 460) or ($err > 510), 'write timing');
    print "<475> elapsed time=$err\n";
#27
    is($ob->output_field_separator($f), "", 'output_field_separator');
    is($ob->output_record_separator($r), "", 'output_record_separator');

    # tie to PRINTF method
    $tick=$ob->get_tick_count;
    $pass=printf PORT "123456789_%s_987654321", $line;
    $tock=$ob->get_tick_count;
    is($pass, 1, 'PRINT method');
    $err=$tock - $tick;
    is_bad (($err < 240) or ($err > 295), 'write timing');
    print "<260> elapsed time=$err\n";

    is($ob->output_field_separator(''), $f, 'output_field_separator');
    is($ob->output_record_separator(''), $r, 'output_record_separator');
}

## 227 - 241: Port in Use (new + quiet)

my $ob2;
is_bad ($ob2 = Win::SerialPort->new ($file), "port $file already open");
is_bad (defined $ob2, 'returns undef');
is ($ob2 = Win::SerialPort->new ($file, 1), 0, 'quiet returns zero');
is_bad ($ob2 = Win::SerialPort->new ($file, 0), 'quiet off');
is_bad (defined $ob2, 'returns undef');

is_bad ($ob2 = WinAPI::CommPort->new ($file), "CommPort uses same $file");
is_bad (defined $ob2, 'returns undef');
is ($ob2 = WinAPI::CommPort->new ($file, 1), 0, 'quiet is one');
is_bad ($ob2 = WinAPI::CommPort->new ($file, 0), 'quiet is zero');
is_bad (defined $ob2, 'but still undef');

is_bad ($ob2 = AltPort->new ($file), "repeat for inherited $file");
is_bad (defined $ob2, 'undef');

is ($ob2 = AltPort->new ($file, 1), 0, 'inherited with quiet');
is_bad ($ob2 = AltPort->new ($file, 0), 'no quiet');
is_bad (defined $ob2, 'undef again');

    # destructor = CLOSE method
ok(close PORT, 'close');
is(internal_buffer, 4096, 'internal_buffer with no object');

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!
untie *PORT;

no strict 'vars';	# turn off strict in order to check
			# "RAW" symbols not exported by default

is_bad(defined $CloseHandle, 'confirm RAW symbols not exported');
$CloseHandle = 1;	# for "-w"
