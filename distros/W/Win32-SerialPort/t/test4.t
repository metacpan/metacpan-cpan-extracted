use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 518;
}
cmp_ok($Win32::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use Win32::SerialPort qw( :STAT 0.20 );

use strict;
use warnings;

use AltPort 0.20;		# check inheritance & export
use Win32;

# tests start using file created by test1.pl


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
my $tc = 2;		# next test number
my $ob;
my $pass;
my $fail;
my $in;
my $in2;
my $instead;
my @opts;
my $out;
my $blk;
my $err;
my $e;
my $tick;
my $tock;
my $patt;
my $s="testing is a wonderful thing - this is a 60 byte long string";
#      123456789012345678901234567890123456789012345678901234567890
my $line = $s.$s.$s;		# about 185 MS at 9600 baud
my @necessary_param = AltPort->set_test_mode_active(1);

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

# 2: Constructor

ok($ob = AltPort->start ($cfgfile), "start $cfgfile");
die unless ($ob);    # next tests would die at runtime

#### 3 - 26: Check Port Capabilities Match Save

is($ob->is_xon_char, 0x11, 'is_xon_char');
is($ob->is_xoff_char, 0x13, 'is_xoff_char');
is($ob->is_eof_char, 0, 'is_eof_char');
is($ob->is_event_char, 0, 'is_event_char');
is($ob->is_error_char, 0, 'is_error_char');
is($ob->is_baudrate, 9600, 'is_baudrate');
is($ob->is_parity, "none", 'is_parity');
is($ob->is_databits, 8, 'is_databits');
is($ob->is_stopbits, 1, 'is_stopbits');
is($ob->is_handshake, "none", 'is_handshake');
is($ob->is_read_interval, 0xffffffff, 'is_read_interval');
is($ob->is_read_const_time, 0, 'is_read_const_time');
is($ob->is_read_char_time, 0, 'is_read_char_time');
is($ob->is_write_const_time, 200, 'is_write_const_time');
is($ob->is_write_char_time, 10, 'is_write_char_time');

($in, $out)= $ob->are_buffers;
is(4096, $in, 'buffer in');
is(4096, $out, 'buffer out');

is($ob->alias, "TestPort", 'alias');
is($ob->is_binary, 1, 'is_binary');
is(scalar $ob->is_parity_enable, 0, 'is_parity_enable');

is($ob->is_xoff_limit, 200, 'is_xoff_limit');
is($ob->is_xon_limit, 100, 'is_xon_limit');
is($ob->user_msg, 1, 'user_msg');
is($ob->error_msg, 1, 'error_msg');

### 27 - 65: Defaults for stty and lookfor

@opts = $ob->are_match;
is($#opts, 0, 'last are_match element');
is($opts[0], "\n", 'are_match default');
is($ob->lookclear, 1, 'lookclear');
is($ob->is_prompt, "", 'is_prompt');
is($ob->lookfor, "", 'lookfor');
is($ob->streamline, "", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'lastlook in');
is($out, "", 'lastlook out');
is($patt, "", 'lastlook pat');
is($instead, "", 'lastlook instead');
is($ob->matchclear, "", 'matchclear');

is($ob->stty_intr, "\cC", 'stty_intr');
is($ob->stty_quit, "\cD", 'stty_quit');
is($ob->stty_eof, "\cZ", 'stty_eof');
is($ob->stty_eol, "\cJ", 'stty_eol');
is($ob->stty_erase, "\cH", 'stty_erase');
is($ob->stty_kill, "\cU", 'stty_kill');
is($ob->stty_bsdel, "\cH \cH", 'stty_bsdel');

my $space76 = " "x76;
my $cstring = "\r$space76\r";
is($ob->stty_clear, $cstring, 'stty_clear');

is($ob->is_stty_intr, 3, 'is_stty_intr');
is($ob->is_stty_quit, 4, 'is_stty_quit');
is($ob->is_stty_eof, 26, 'is_stty_eof');
is($ob->is_stty_eol, 10, 'is_stty_eol');
is($ob->is_stty_erase, 8, 'is_stty_erase');
is($ob->is_stty_kill, 21, 'is_stty_kill');

is($ob->stty_echo, 0, 'stty_echo');
is($ob->stty_echoe, 1, 'stty_echoe');
is($ob->stty_echok, 1, 'stty_echok');
is($ob->stty_echonl, 0, 'stty_echonl');
is($ob->stty_echoke, 1, 'stty_echoke');
is($ob->stty_echoctl, 0, 'stty_echoctl');
is($ob->stty_istrip, 0, 'stty_istrip');
is($ob->stty_icrnl, 0, 'stty_icrnl');
is($ob->stty_ocrnl, 0, 'stty_ocrnl');
is($ob->stty_igncr, 0, 'stty_igncr');
is($ob->stty_inlcr, 0, 'stty_inlcr');
is($ob->stty_onlcr, 1, 'stty_onlcr');
is($ob->stty_opost, 0, 'stty_opost');
is($ob->stty_isig, 0, 'stty_isig');
is($ob->stty_icanon, 0, 'stty_icanon');

#### 67 - 73: Application Parameter Defaults

is($ob->devicetype, 'none', 'devicetype');
is($ob->hostname, 'localhost', 'hostname');
is($ob->hostaddr, 0, 'hostaddr');			# 69
is($ob->datatype, 'raw', 'datatype');
is($ob->cfg_param_1, 'none', 'cgf_param_1');
is($ob->cfg_param_2, 'none', 'cgf_param_2');
is($ob->cfg_param_3, 'none', 'cgf_param_3');

print "Change all the parameters\n";

#### 74 - 227: Modify All Port Capabilities

is($ob->is_xon_char(1), 0x01, 'is_xon_char');
is($ob->is_xoff_char(2), 0x02, 'is_xoff_char');

is($ob->devicetype('type'), 'type', 'devicetype');
is($ob->hostname('any'), 'any', 'xhostname');
is($ob->hostaddr(9000), 9000, 'hostaddr');
is($ob->datatype('fixed'), 'fixed', 'datatype');
is($ob->cfg_param_1('p1'), 'p1', 'cfg_param_1');
is($ob->cfg_param_2('p2'), 'p2', 'cfg_param_2');
is($ob->cfg_param_3('p3'), 'p3', 'cfg_param_3');

$pass = $ob->can_spec_char;			# generic port can't set
if ($pass) {
    is($ob->is_eof_char(4), 0x04, 'is_eof_char');
    is($ob->is_event_char(3), 0x03, 'is_event_char');
    is($ob->is_error_char(5), 5, 'is_error_char');
}
else {
    is($ob->is_eof_char(4), 0, 'is_eof_char');
    is($ob->is_event_char(3), 0, 'is_event_char');
    is($ob->is_error_char(5), 0, 'is_error_char');
}

is($ob->is_baudrate(1200), 1200, 'is_baudrate');
is($ob->is_parity("odd"), "odd", 'is_parity');

is($ob->is_databits(7), 7, 'is_databits');
is($ob->is_stopbits(2), 2, 'is_stopbits');
is($ob->is_handshake("xoff"), "xoff", 'is_handshake');
is($ob->is_read_interval(0), 0x0, 'is_read_interval');
is($ob->is_read_const_time(1000), 1000, 'is_read_const_time');
is($ob->is_read_char_time(50), 50, 'is_read_char_time');
is($ob->is_write_const_time(2000), 2000, 'is_write_const_time');
is($ob->is_write_char_time(75), 75, 'is_write_char_time');

($in, $out)= $ob->buffers(8092, 1024);
is(8092, $ob->is_read_buf, 'is_read_buf');
is(1024, $ob->is_write_buf, 'is_write_buf');

is($ob->alias("oddPort"), "oddPort", 'alias');
is($ob->is_xoff_limit(45), 45, 'is_xoff_limit');

$pass = $ob->can_parity_enable;
if ($pass) {
    # Windows bug, not fixed since NT4
    ok(defined $ob->is_parity_enable(1), 'is_parity_enable ON');
}
else {
    is(scalar $ob->is_parity_enable, 0, 'is_parity_enable OFF');
}

is($ob->is_xon_limit(90), 90, 'is_xon_limit');
is($ob->user_msg(0), 0, 'user_msg OFF');
is($ob->error_msg(0), 0, 'error_msg OFF');

@opts = $ob->are_match ("END","Bye");
is($#opts, 1, 'are_match count');
is($opts[0], "END", 'END');
is($opts[1], "Bye", 'Bye');
is($ob->stty_echo(0), 0, 'stty_echo(0)');
is($ob->lookclear("Good Bye, Hello"), 1, 'lookclear("Good Bye, Hello"');

is($ob->is_prompt("Hi:"), "Hi:", 'is_prompt');
is($ob->lookfor, "Good ", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Hello", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "Bye", 'matched at beginning');
is($ob->matchclear, "", 'reset matchclear');

is($ob->lookclear("Bye, Bye, Love. The END has come"), 1, 'lookclear("Bye, Bye, Love. The END has come")');
is($ob->lookfor, "", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Bye, Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "Bye", 'matched at beginning');

# data not reset by lastlook, but by matchclear
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($out, ", Bye, Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "", 'matchclear cleared initial match');

is($ob->lookfor, ", ", 'lookfor');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "Bye", 'WHAT matched');

is($ob->lookfor, ", Love. The ", 'lookfor');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "END", 'input that MATCHED');
is($out, " has come", 'input AFTER match');
is($patt, "END", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "END", 'matched at beginning');
is($ob->lookfor, "", 'lookfor');
is($ob->matchclear, "", 'matchclear');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($patt, "", 'PATTERN that matched');
is($instead, " has come", 'input INSTEAD of match');

is($ob->lookclear("First\nSecond\nThe END"), 1, 'lookclear("First\nSecond\nThe END")');
is($ob->lookfor, "First\nSecond\nThe ", 'lookfor');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "END", 'input that MATCHED');
is($out, "", 'input AFTER match');
is($patt, "END", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');

is($ob->lookclear("Good Bye, Hello"), 1, 'lookclear("Good Bye, Hello"');
is($ob->streamline, "Good ", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Hello", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');

is($ob->lookclear("Bye, Bye, Love. The END has come"), 1, 'lookclear("Bye, Bye, Love. The END has come")');
is($ob->streamline, "", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Bye, Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "Bye", 'matchclear');

# data not reset by lastlook, but by matchclear
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($out, ", Bye, Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "", 'matchclear');

is($ob->streamline, ", ", 'streamline');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "Bye", 'input that MATCHED');
is($out, ", Love. The END has come", 'input AFTER match');
is($patt, "Bye", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "Bye", 'matchclear');

is($ob->streamline, ", Love. The ", 'streamline');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "END", 'input that MATCHED');
is($out, " has come", 'input AFTER match');
is($patt, "END", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->matchclear, "END", 'matchclear');
is($ob->streamline, "", 'streamline');
is($ob->matchclear, "", 'matchclear');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($patt, "", 'PATTERN that matched');
is($instead, " has come", 'input INSTEAD of match');

is($ob->lookclear("First\nSecond\nThe END"), 1, 'lookclear("First\nSecond\nThe END")');
is($ob->streamline, "First\nSecond\nThe ", 'streamline');
($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "END", 'input that MATCHED');
is($out, "", 'input AFTER match');
is($patt, "END", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');

is($ob->stty_intr("a"), "a", 'stty_intr("a")');
is($ob->stty_quit("b"), "b", 'stty_quit("b")');
is($ob->stty_eof("c"), "c", 'stty_eof("c")');

is($ob->stty_eol("d"), "d", 'stty_eol("d")');
is($ob->stty_erase("e"), "e", 'stty_erase("e")');
is($ob->stty_kill("f"), "f", 'stty_kill("f")');

is($ob->is_stty_intr, 97, 'is_stty_intr');
is($ob->is_stty_quit, 98, 'is_stty_quit');
is($ob->is_stty_eof, 99, 'is_stty_eof');

is($ob->is_stty_eol, 100, 'is_stty_eol');
is($ob->is_stty_erase, 101, 'is_stty_erase');
is($ob->is_stty_kill, 102, 'is_stty_kill');

is($ob->stty_clear("g"), "g", 'stty_clear("g")');
is($ob->stty_bsdel("h"), "h", 'stty_bsdel("h")');
is($ob->stty_echoe(0), 0, 'stty_echoe(0)');

is($ob->stty_echok(0), 0, 'stty_echok(0)');
is($ob->stty_echonl(1), 1, 'stty_echonl(1)');
is($ob->stty_echoke(0), 0, 'stty_echoke(0)');
is($ob->stty_echoctl(1), 1, 'stty_echoctl(1)');
is($ob->stty_istrip(1), 1, 'stty_istrip(1)');
is($ob->stty_icrnl(1), 1, 'stty_icrnl(1)');
is($ob->stty_ocrnl(1), 1, 'stty_ocrnl(1)');
is($ob->stty_igncr(1), 1, 'stty_igncr(1)');
is($ob->stty_inlcr(1), 1, 'stty_inlcr(1)');
is($ob->stty_onlcr(0), 0, 'stty_onlcr(0)');

is($ob->stty_opost(1), 1, 'stty_opost(1)');
is($ob->stty_isig(1), 1, 'stty_isig(1)');
is($ob->stty_icanon(1), 1, 'stty_icanon(1)');

is($ob->lookclear, 1, 'lookclear');
is($ob->is_prompt, "Hi:", 'is_prompt');
is($ob->is_prompt(""), "", 'is_prompt("")');
is($ob->lookfor, "", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($out, "", 'input AFTER match');
is($patt, "", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->stty_echo(1), 1, 'stty_echo(1)');

#### 228 - 290: Check Port Capabilities Match Changes

is($ob->is_xon_char, 0x01, 'is_xon_char');
is($ob->is_xoff_char, 0x02, 'is_xoff_char');

$pass = $ob->can_spec_char;			# generic port can't set
if ($pass) {
    is($ob->is_eof_char, 0x04, 'is_eof_char');
    is($ob->is_event_char, 0x03, 'is_event_char');
    is($ob->is_error_char, 5, 'is_error_char');
}
else {
    is($ob->is_eof_char, 0, 'is_eof_char');
    is($ob->is_event_char, 0, 'is_event_char');
    is($ob->is_error_char, 0, 'is_error_char');
}
is($ob->is_baudrate, 1200, 'is_baudrate');

is($ob->devicetype, 'type', 'devicetype');
is($ob->hostname, 'any', 'hostname');
is($ob->hostaddr, 9000, 'hostaddr');

is($ob->datatype, 'fixed', 'datatype');
is($ob->cfg_param_1, 'p1', 'cfg_param_1');
is($ob->cfg_param_2, 'p2', 'cfg_param_2');
is($ob->cfg_param_3, 'p3', 'cfg_param_3');

is($ob->is_databits, 7, 'is_databits');
is($ob->is_stopbits, 2, 'is_stopbits');
is($ob->is_handshake, "xoff", 'is_handshake');
is($ob->is_read_interval, 0x0, 'is_read_interval');
is($ob->is_read_const_time, 1000, 'is_read_const_time');
is($ob->is_read_char_time, 50, 'is_read_char_time');
is($ob->is_write_const_time, 2000, 'is_write_const_time');
is($ob->is_write_char_time, 75, 'is_write_char_time');

($in, $out)= $ob->are_buffers;
is($in, 8092, 'are_buffers in');
is($out, 1024,  'are_buffers out');
is($ob->alias, "oddPort", 'alias');

$pass = $ob->can_parity_enable;
if ($pass) {
    # Windows bug, not fixed since NT4
    ok(defined $ob->is_parity_enable(1), 'is_parity_enable ON');
}
else {
    is(scalar $ob->is_parity_enable, 0, 'is_parity_enable OFF');
}

is($ob->is_xoff_limit, 45, 'is_xoff_limit');
is($ob->is_xon_limit, 90, 'is_xon_limit');

is($ob->user_msg, 0, 'user_msg OFF');
is($ob->error_msg, 0, 'error_msg OFF');

@opts = $ob->are_match;
is($#opts, 1, 'are_match count');
is($opts[0], "END", 'END');
is($opts[1], "Bye", 'Bye');

is($ob->stty_intr, "a", 'stty_intr');
is($ob->stty_quit, "b", 'stty_quit');
is($ob->stty_eof, "c", 'stty_eof');
is($ob->stty_eol, "d", 'stty_eol');
is($ob->stty_erase, "e", 'stty_erase');
is($ob->stty_kill, "f", 'stty_kill');

is($ob->is_stty_intr, 97, 'is_stty_intr');
is($ob->is_stty_quit, 98, 'is_stty_quit');
is($ob->is_stty_eof, 99, 'is_stty_eof');

is($ob->is_stty_eol, 100, 'is_stty_eol');
is($ob->is_stty_erase, 101, 'is_stty_erase');
is($ob->is_stty_kill, 102, 'is_stty_kill');

is($ob->stty_clear, "g", 'stty_clear');
is($ob->stty_bsdel, "h", 'stty_bsdel');

is($ob->stty_echo, 1, 'stty_echo');
is($ob->stty_echoe, 0, 'stty_echoe');
is($ob->stty_echok, 0, 'stty_echok');

is($ob->stty_echonl, 1, 'stty_echonl');
is($ob->stty_echoke, 0, 'stty_echoke');
is($ob->stty_echoctl, 1, 'stty_echoctl');

is($ob->stty_istrip, 1, 'stty_istrip');
is($ob->stty_icrnl, 1, 'stty_icrnl');
is($ob->stty_ocrnl, 1, 'stty_ocrnl');
is($ob->stty_igncr, 1, 'stty_igncr');
is($ob->stty_inlcr, 1, 'stty_inlcr');
is($ob->stty_onlcr, 0, 'stty_onlcr');
is($ob->stty_opost, 1, 'stty_opost');
is($ob->stty_isig, 1, 'stty_isig');
is($ob->stty_icanon, 1, 'stty_icanon');
is($ob->is_parity, "odd", 'is_parity');

print "Restore all the parameters\n";

ok($ob->restart ($cfgfile), "restart $cfgfile");

#### 291 - 361: Check Port Capabilities Match Original

is($ob->is_xoff_char, 0x13, 'is_xoff_char');
is($ob->is_eof_char, 0, 'is_eof_char');
is($ob->is_event_char, 0, 'is_event_char');
is($ob->is_error_char, 0, 'is_error_char');
is($ob->is_baudrate, 9600, 'is_baudrate');
is($ob->is_parity, "none", 'is_parity');
is($ob->is_databits, 8, 'is_databits');

is($ob->is_stopbits, 1, 'is_stopbits');
is($ob->is_handshake, "none", 'is_handshake');
is($ob->is_read_interval, 0xffffffff, 'is_read_interval');
is($ob->is_read_const_time, 0, 'is_read_const_time');

is($ob->is_read_char_time, 0, 'is_read_char_time');
is($ob->is_write_const_time, 200, 'is_write_const_time');
is($ob->is_write_char_time, 10, 'is_write_char_time');

($in, $out)= $ob->are_buffers;
is($in, 4096, 'are_buffers in');
is($out, 4096, 'are_buffers out');

is($ob->alias, "TestPort", 'alias');
is($ob->is_binary, 1, 'is_binary');
is(scalar $ob->is_parity_enable, 0, 'is_parity_enable OFF');
is($ob->is_xoff_limit, 200, 'is_xoff_limit');
is($ob->is_xon_limit, 100, 'is_xon_limit');
is($ob->user_msg, 1, 'user_msg');
is($ob->error_msg, 1, 'error_msg');

@opts = $ob->are_match("\n");
is($#opts, 0, 'single are_match');
is($opts[0], "\n", 'linefeed');
is($ob->lookclear, 1, 'lookclear');
is($ob->is_prompt, "", 'is_prompt');
is($ob->lookfor, "", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is($in, "", 'input that MATCHED');
is($out, "", 'input AFTER match');
is($patt, "", 'PATTERN that matched');
is($instead, "", 'input INSTEAD of match');
is($ob->streamline, "", 'streamline');
is($ob->matchclear, "", 'matchclear');

is($ob->stty_intr, "\cC", 'stty_intr');
is($ob->stty_quit, "\cD", 'stty_quit');
is($ob->stty_eof, "\cZ", 'stty_eof');
is($ob->stty_eol, "\cJ", 'stty_eol');
is($ob->stty_erase, "\cH", 'stty_erase');
is($ob->stty_kill, "\cU", 'stty_kill');
is($ob->stty_clear, $cstring, 'stty_clear');
is($ob->stty_bsdel, "\cH \cH", 'stty_bsdel');

is($ob->is_stty_intr, 3, 'is_stty_intr');
is($ob->is_stty_quit, 4, 'is_stty_quit');
is($ob->is_stty_eof, 26, 'is_stty_eof');
is($ob->is_stty_eol, 10, 'is_stty_eol');
is($ob->is_stty_erase, 8, 'is_stty_erase');
is($ob->is_stty_kill, 21, 'is_stty_kill');

is($ob->stty_echo, 0, 'stty_echo');
is($ob->stty_echoe, 1, 'stty_echoe');

is($ob->stty_echok, 1, 'stty_echok');
is($ob->stty_echonl, 0, 'stty_echonl');
is($ob->stty_echoke, 1, 'stty_echoke');
is($ob->stty_echoctl, 0, 'stty_echoctl');
is($ob->stty_istrip, 0, 'stty_istrip');

is($ob->stty_icrnl, 0, 'stty_icrnl');
is($ob->stty_ocrnl, 0, 'stty_ocrnl');
is($ob->stty_igncr, 0, 'stty_igncr');
is($ob->stty_inlcr, 0, 'stty_inlcr');
is($ob->stty_onlcr, 1, 'stty_onlcr');
is($ob->stty_opost, 0, 'stty_opost');
is($ob->stty_isig, 0, 'stty_isig');
is($ob->stty_icanon, 0, 'stty_icanon');
is($ob->is_xon_char, 0x11, 'is_xon_char');

is($ob->hostaddr, 0, 'hostaddr');
is($ob->datatype, 'raw', 'datatype');
is($ob->cfg_param_1, 'none', 'cfg_param_1');
is($ob->cfg_param_2, 'none', 'cfg_param_2');
is($ob->cfg_param_3, 'none', 'cfg_param_3');
is($ob->devicetype, 'none', 'devicetype');
is($ob->hostname, 'localhost', 'hostname');

## 362 - 372: Status

ok(scalar $ob->purge_all, 'purge_all');
$ob->reset_error;

is(scalar (@opts = $ob->is_status), 4, 'is_status array');

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

$ob->reset_error;

# 373 - 375: "Instant" return for read_interval=0xffffffff

SKIP: {
    skip "Can't rely on timing and status details", 90 if $BUFFEROUT;

    ($blk, $in, $out, $err)=$ob->is_status(0x150);	# test only
    is($err, 0x150, 'error_bits forced');

    ($blk, $in, $out, $err)=$ob->is_status(0x0f);	# test only
    is($err, 0x15f, 'error bits add');

    is($ob->reset_error, 0x15f, 'reset_error');

    ($blk, $in, $out, $err)=$ob->is_status;
    is($err, 0, 'error bits');

    $tick=$ob->get_tick_count;
    ($in, $in2) = $ob->read(10);
    $tock=$ob->get_tick_count;

    is($in, 0, 'character count');
    is_bad ($in2, 'no input');
    $out=$tock - $tick;
    ok ($out < 100, 'instant return from read');
    print "<0> elapsed time=$out\n";

# 376 - 384: 1 Second Constant Timeout

    is($ob->is_read_const_time(2000), 2000, 'is_read_const_time');
    is($ob->is_read_interval(0), 0, 'is_read_interval');
    is($ob->is_read_char_time(100), 100, 'is_read_char_time');
    is($ob->is_read_const_time(0), 0, 'is_read_const_time');
    is($ob->is_read_char_time(0), 0, 'is_read_char_time');
    
    is($ob->is_read_interval(0xffffffff), 0xffffffff, 'is_read_interval');
    is($ob->is_write_const_time(1000), 1000, 'is_write_const_time');
    is($ob->is_write_char_time(0), 0, 'is_write_char');
    is($ob->is_handshake("rts"), 'rts', 'is_handshake("rts")');

# 385 - 386

    $e="12345678901234567890";

    $tick=$ob->get_tick_count;
    is($ob->write($e), 0, 'write');
    $tock=$ob->get_tick_count;

    $out=$tock - $tick;
    is_bad (($out < 800) or ($out > 1300), 'write timeout');
    print "<1000> elapsed time=$out\n";

# 387 - 389: 2.5 Second Timeout Constant+Character

    is($ob->is_write_char_time(75), 75, 'is_write_char_time');

    $tick=$ob->get_tick_count;
    is($ob->write($e), 0, 'write');
    $tock=$ob->get_tick_count;

    $out=$tock - $tick;
    is_bad (($out < 2300) or ($out > 2900), 'write_timeout');
    print "<2500> elapsed time=$out\n";

# 390 - 398: 1.5 Second Read Constant Timeout

    is($ob->is_read_const_time(1500), 1500, 'is_read_const_time');
    is($ob->is_read_interval(0), 0, 'is_read_interval');
    ok (scalar $ob->purge_all, 'purge_all');

    $tick=$ob->get_tick_count;
    $in = $ob->read_bg(10);
    $tock=$ob->get_tick_count;


    $out=$tock - $tick;
    is($in, 0, 'read_bg');
    ok ($out < 100, 'background returns quickly');
    print "<0> elapsed time=$out\n";

    ($pass, $in, $in2) = $ob->read_done(0);
    $tock=$ob->get_tick_count;

    is($pass, 0, 'read_done(0)');
    is($in, 0, 'read_bg count');
    is($in2, "", 'read_bg data');
    $out=$tock - $tick;
    ok ($out < 100, 'not blocked');	

    is($ob->write_bg($e), 0, 'write_bg');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');
    is($out, 0, 'write_bg count');

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);
    is($pass, 0, 'read_done(0)');
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    ($blk, $in, $out, $err)=$ob->is_status;
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
    is_bad (($out < 1800) or ($out > 2400), 'read_done timing');
    print "<2000> elapsed time=$out\n";
    ($pass, $out) = $ob->write_done(0);
    is($pass, 0, 'write_done(0)');

    sleep 1;
    ($pass, $in, $in2) = $ob->read_done(0);	# double check ok?
    is($pass, 1, 'read_done(0)');
    is($in, 0, 'read_done count');
    is($in2, "", 'read_done data');

    sleep 1;
    ($pass, $out) = $ob->write_done(0);
    is($pass, 1, 'write_done(0)');
    is($out, 0, 'write_done count');
    $tock=$ob->get_tick_count;			# expect about 4 seconds
    $out=$tock - $tick;
    is_bad (($out < 3800) or ($out > 4400), 'write_done timing');
    print "<4000> elapsed time=$out\n";

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
    $tock=$ob->get_tick_count;			# expect 1.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 1300) or ($out > 1800), 'read_done(1) timing');
    print "<1500> elapsed time=$out\n";

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
    $tock=$ob->get_tick_count;			# expect 1.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 1300) or ($out > 1800), 'write_done(1) timing');
    print "<1500> elapsed time=$out\n";

    ($pass, $out) = $ob->write_done(1);
    is($pass, 1, 'write_done(1)');
    $tock=$ob->get_tick_count;			# expect 2.5 seconds
    $out=$tock - $tick;
    is_bad (($out < 2300) or ($out > 2800), 'write_done(1) timing');
    print "<2500> elapsed time=$out\n";
#99
}

is($ob->user_msg, 1, 'user_msg');
is($ob->user_msg(0), 0, 'user_msg(0)');
is($ob->user_msg(1), 1, 'user_msg(1)');
is($ob->error_msg, 1, 'error_msg');
is($ob->error_msg(0), 0, 'error_msg(0)');
is($ob->error_msg(1), 1, 'error_msg(1)');

# 465 - 516 Test and Normal "lookclear"

$ob->reset_error;
is($ob->stty_echo(0), 0, 'stty_echo');
is ($ob->lookclear("Before\nAfter"), 1, 'lookclear load');
is ($ob->lookfor, "Before", 'lookfor match in middle');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "\n", 'MATCHED');
is ($out, "After", 'AFTER');
is ($patt, "\n", 'PATTERN');
is ($instead, "", 'INSTEAD');

is ($ob->lookfor, "", 'lookfor no match');
($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'no MATCH');
is ($patt, "", 'no PATTERN');
is ($instead, "After", 'found AFTER');

@opts = $ob->are_match ("B*e","ab..ef","-re","12..56","END");
is ($#opts, 4, 're matches');
is ($opts[2], "-re", 're delimiter');
is ($ob->lookclear("Good Bye, the END, Hello"), 1, 'lookclear load');
is ($ob->lookfor, "Good Bye, the ", 'lookfor BEFORE');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "END", 'MATCHED');
is ($out, ", Hello", 'AFTER');
is ($patt, "END", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->lookclear("Good Bye, the END, Hello"), 1, 'lookclear load');
is ($ob->streamline, "Good Bye, the ", 'streamline BEFORE');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "END", 'MATCHED');
is ($out, ", Hello", 'AFTER');
is ($patt, "END", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->lookclear("Good B*e, abcdef, 123456"), 1, 'lookclear load for re');
is ($ob->lookfor, "Good ", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "B*e", 'wildcard MATCHED');
is ($out, ", abcdef, 123456", 'AFTER');
is ($patt, "B*e", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->lookfor, ", abcdef, ", 'lookfor');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "123456", 'MATCHED');
is ($out, "", 'nothing AFTER');
is ($patt, "12..56", 'PATTERN is re');
is ($instead, "", 'nothing INSTEAD');

is ($ob->lookclear("Good B*e, abcdef, 123456"), 1, 'lookclear load for re');
is ($ob->streamline, "Good ", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "B*e", 'wildcard MATCHED');
is ($out, ", abcdef, 123456", 'AFTER');
is ($patt, "B*e", 'PATTERN');
is ($instead, "", 'no INSTEAD');

is ($ob->streamline, ", abcdef, ", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "123456", 'MATCHED');
is ($out, "", 'nothing AFTER');
is ($patt, "12..56", 'PATTERN is re');

@necessary_param = Win32::SerialPort->set_test_mode_active(0);

is_bad ($in = $ob->lookclear("Good\nBye"), 'lookclear no testmode');
is ($ob->lookfor, "", 'lookfor no match');
($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'no MATCH');
is ($out, "", 'no AFTER');
is ($patt, "", 'no PATTERN');

undef $ob;
