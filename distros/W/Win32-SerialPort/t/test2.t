use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 146;
}
cmp_ok($Win32::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use Win32::SerialPort qw( :STAT 0.20 );

use strict;
use warnings;

# tests start using file created by test1.pl

use Win32;

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
my $blk;
my $err;
my $e;
my $tick;
my $tock;
my $s="testing is a wonderful thing - this is a 60 byte long string";
#      123456789012345678901234567890123456789012345678901234567890
my $line = $s.$s.$s;		# about 185 MS at 9600 baud
my @necessary_param = Win32::SerialPort->set_test_mode_active(1);

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

# 2: Constructor

ok($ob = Win32::SerialPort->start ($cfgfile), "start $cfgfile");
die unless ($ob);    # next tests would die at runtime

#### 3 - 24: Check Port Capabilities Match Save

is($ob->xon_char, 0x11, 'xon_char');
is($ob->xoff_char, 0x13, 'xoff_char');
is($ob->eof_char, 0, 'eof_char');
is($ob->event_char, 0, 'event_char');
is($ob->error_char, 0, 'error_char');
is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, "none", 'parity');
is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');
is($ob->handshake, "none", 'handshake');
is($ob->read_interval, 0xffffffff, 'read_interval');
is($ob->read_const_time, 0, 'read_const_time');
is($ob->read_char_time, 0, 'read_char_time');
is($ob->write_const_time, 200, 'write_const_time');
is($ob->write_char_time, 10, 'write_char_time');

($in, $out)= $ob->buffers;
is(4096, $in, 'buffer in');
is(4096, $out, 'buffer out');

is($ob->alias, 'TestPort', 'alias');

is($ob->binary, 1, 'binary');

is($ob->parity_enable, 0, 'parity_enable');
is($ob->xoff_limit, 200, 'xoff_limit');
is($ob->xon_limit, 100, 'xon_limit');


## 25 - 30: Status

ok(scalar $ob->purge_all, 'purge_all');
$ob->reset_error;
is(scalar (@opts = $ob->status), 4, 'status array');

# for an unconnected port, should be $in=0, $out=0, $blk=0, $err=0
($blk, $in, $out, $err)=@opts;

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
	is($blk, 0, 'blocking bits');
	is($in, 0, 'input count');
	is($out, 0, 'output count');
	is($err, 0, 'error bits');
	is_bad (($delay < 120) or ($delay > 300), 'write timing');
}
print "<185> elapsed time=$delay\n";

# 31 - 33: "Instant" return for read_interval=0xffffffff

SKIP: {
    skip "Can't rely on timing and status details", 99 if $BUFFEROUT;

    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(10);
    $tock=$ob->get_tick_count;

    is($in, 0, 'character count');
    is_bad ($in2, 'no input');
    $out=$tock - $tick;
    ok ($out < 100, 'instant return from read');
    print "<0> elapsed time=$out\n";

    print "Beginning Timed Tests at 2-5 Seconds per Set\n";

    is($ob->read_const_time(2000), 2000, 'read_const_time');
    is($ob->read_interval(0), 0, 'read_interval');
    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(10);
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is($in, 0, 'two second constant timeout');
    is_bad($in2,'no data returned');
    is_bad (($out < 1800) or ($out > 2400), 'read timeout');
    print "<2000> elapsed time=$out\n";

    # 4 Second Timeout Constant+Character

    is($ob->read_char_time(100), 100, 'read_char_time');
    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(20);
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is($in, 0, 'four second constant+character timeout');
    is_bad($in2,'no data returned');
    is_bad (($out < 3800) or ($out > 4400), 'read timeout');
    print "<4000> elapsed time=$out\n";
#12
    # 3 Second Character Timeout

    is($ob->read_const_time(0), 0, 'read_const_time');
    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(30);
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is($in, 0, 'three second character timeout');
    is_bad($in2,'no data returned');
    is_bad (($out < 2800) or ($out > 3400), 'read timeout');
    print "<3000> elapsed time=$out\n";

    # 2 Second Constant Write Timeout

    is($ob->read_char_time(0), 0, 'read_char_time');
    is($ob->read_interval, 0, 'read_interval');
    is($ob->write_const_time(2000), 2000, 'write_const_time');
    is($ob->write_char_time(0), 0, 'write_char_time');
    is($ob->handshake("rts"), "rts", 'handshake rts should block');
#21
    $e="12345678901234567890";

    $tick=$ob->get_tick_count;
    is($ob->write($e), 0, 'write no characters');
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is_bad (($out < 1800) or ($out > 2400), 'write_timeout');
    print "<2000> elapsed time=$out\n";

    # 3.5 Second Timeout Constant+Character
    is($ob->write_char_time(75), 75, 'write_char_time');
    $tick=$ob->get_tick_count;
    is($ob->write($e), 0, 'write no characters');
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is_bad (($out < 3300) or ($out > 3900), 'write_timeout');
    print "<3500> elapsed time=$out\n";

    # 2.5 Second Read Constant Timeout
    is($ob->read_const_time(2500), 2500, 'read_const_time');
    is($ob->read_interval(0), 0, 'read_interval');
    ok(scalar $ob->purge_all, 'purge_all');
    $tick=$ob->get_tick_count;
    $in = $ob->read_bg(10);
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is($in, 0, '2.5 second constant read timeout');
    ok($out < 100, 'starts in background');
    print "<0> elapsed time=$out\n";
#31
    ($pass, $in, $in2) = $ob->read_done(0);
    $tock=$ob->get_tick_count;

    is($pass, 0, 'read_done(0)');
    is($in, 0, 'read_bg count');
    is($in2, "", 'read_bg data');
    $out=$tock - $tick;
    ok ($out < 100, 'not blocked');	


print "A Series of 1 Second Groups with Background I/O\n";

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    is($in, 0, 'read_bg count');
    is($in2, "", 'read_bg data');
    is($ob->write_bg($e), 0, 'write_bg');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');
    is($out, 0, 'write_bg count');
#41
    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    ($blk, $in, $out, $err)=$ob->status;
    is($in, 0, 'read char count');
    is($out, 20, 'write char count');
    is($blk, 1, 'blocking bits');
    is($err, 0, 'error bits char count');

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 1, 'read_done(0)');
    is($in, 0, 'read_bg count');
    is($in2, "", 'read_bg data');
    $tock=$ob->get_tick_count;
    $out=$tock - $tick;
    is_bad (($out < 2800) or ($out > 3400), 'read_done timing');
    print "<3000> elapsed time=$out\n";
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');
#52
    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);		# double check ok?
    is($pass, 1, 'read_done(0)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    sleep 1;
    ($pass, $out) = $ob->write_done(0);
    is($pass, 1, 'write_done(0)');
    is($out, 0, 'write_done count');
    $tock=$ob->get_tick_count;			# expect about 5 seconds
    $out=$tock - $tick;
    is_bad (($out < 4800) or ($out > 5400), 'write_done timing');
    print "<5000> elapsed time=$out\n";
#59
    $tick=$ob->get_tick_count;			# new timebase
    $in = $ob->read_bg(10);
    is($in, 0, 'read_bg count');
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    ## print "testing fail message:\n";
    $in = $ob->read_bg(10);
    is_bad (defined $in, 'already reading');

    ($pass, $in, $in2) = $ob->read_done(1);
    is($pass, 1, 'read_done(1)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');
    $tock=$ob->get_tick_count;			# expect 2.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 2300) or ($out > 2800), 'read_done(1) timing');
    print "<2500> elapsed time=$out\n";
#69
    $tick=$ob->get_tick_count;			# new timebase
    $in = $ob->read_bg(10);
    is($in, 0, 'read_bg count');
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    ok(scalar $ob->purge_rx, 'purge_rx');
    ($pass, $in, $in2) = $ob->read_done(1);
    ok(scalar $ob->purge_rx, 'purge_rx');
    if (Win32::IsWinNT()) {
        is($pass, 0, 'read_done(1) after purge');
    } else {
        is($pass, 1, 'read_done(1) after purge');
    }
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');
    $tock=$ob->get_tick_count;			# expect 1 second
    $out=$tock - $tick;
    is_bad (($out < 900) or ($out > 1200), 'purge_rx timing');
    print "<1000> elapsed time=$out\n";
#80
    is($ob->write_bg($e), 0, 'write_bg');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    sleep 1;
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');
    ok(scalar $ob->purge_tx, 'purge_tx');
    ($pass, $out) = $ob->write_done(1);
    ok(scalar $ob->purge_tx, 'purge_tx');
    if (Win32::IsWinNT()) {
        is($pass, 0, 'write_done(1)');
    } else {
        is($pass, 1, 'write_done(1)');
    }
    $tock=$ob->get_tick_count;			# expect 2 seconds
    $out=$tock - $tick;
    is_bad (($out < 1900) or ($out > 2200), 'write_done(1) timing');
    print "<2000> elapsed time=$out\n";
#87
    $tick=$ob->get_tick_count;			# new timebase
    $in = $ob->read_bg(10);
    is($in, 0, 'read_bg count');
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    is($ob->write_bg($e), 0, 'write_bg');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    sleep 1;
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    ($pass, $in, $in2) = $ob->read_done(1);
    is($pass, 1, 'read_done(1)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');
    $tock=$ob->get_tick_count;			# expect 2.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 2300) or ($out > 2800), 'write_done(1) timing');
    print "<2500> elapsed time=$out\n";

    ($pass, $out) = $ob->write_done(1);
    is($pass, 1, 'write_done(1)');
    $tock=$ob->get_tick_count;			# expect 3.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 3300) or ($out > 3800), 'write_done(1) timing');
    print "<3500> elapsed time=$out\n";
#99
}

is($ob->user_msg, 1, 'user_msg');
is($ob->user_msg(0), 0, 'user_msg(0)');
is($ob->user_msg(1), 1, 'user_msg(1)');
is($ob->error_msg, 1, 'error_msg');
is($ob->error_msg(0), 0, 'error_msg(0)');
is($ob->error_msg(1), 1, 'error_msg(1)');

#### 137 - 143: Application Parameter Defaults

is($ob->devicetype, 'none', 'devicetype');
is($ob->hostname, 'localhost', 'hostname');
is($ob->hostaddr, 0, 'hostaddr');
is($ob->datatype, 'raw', 'datatype');
is($ob->cfg_param_1, 'none', 'cfg_param_1');
is($ob->cfg_param_2, 'none', 'cfg_param_2');
is($ob->cfg_param_3, 'none', 'cfg_param_3');

undef $ob;

# 144 - 145: Reopen tests (unconfirmed) $ob->close via undef

sleep 1;
ok($ob = Win32::SerialPort->start ($cfgfile), "start $cfgfile");
die unless ($ob);    # next tests would die at runtime
ok($ob->close, 'close');
undef $ob;
