use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 315;
}
cmp_ok($Win32::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

use AltPort qw( :STAT 0.20 );

use strict;
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

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

my $ob;
my $pass;
my $in;
my @necessary_param = Win32::SerialPort->set_test_mode_active(1);

# 2: Constructor

ok ($ob = Win32::SerialPort->start ($cfgfile), "start $cfgfile");
die unless ($ob);    # next tests would die at runtime

#### 3 - 45: Check Port Capabilities from stty() Match Save

my @opts = $ob->stty();
my @saves = @opts;
ok (scalar @opts, 'stty parameters');
is(shift @opts, 9600, 'stty baud');
is(shift @opts, "intr", 'stty "intr"');

is(shift @opts, "^C", 'stty "^C"');
is(shift @opts, "quit", 'stty "quit"');
is(shift @opts, "^D", 'stty "^D"');
is(shift @opts, "erase", 'stty "erase"');
is(shift @opts, "^H", 'stty "^H"');
is(shift @opts, "kill", 'stty "kill"');
is(shift @opts, "^U", 'stty "^U"');

is(shift @opts, "eof", 'stty "eof"');
is(shift @opts, "^Z", 'stty "^Z"');
is(shift @opts, "eol", 'stty "eol"');
is(shift @opts, "^J", 'stty "^J"');
is(shift @opts, "start", 'stty "start"');
is(shift @opts, "^Q", 'stty "^Q"');
is(shift @opts, "stop", 'stty "stop"');
is(shift @opts, "^S", 'stty "^S"');
is(shift @opts, "-echo", 'stty "-echo"');
is(shift @opts, "echoe", 'stty "echoe"');

is(shift @opts, "echok", 'stty "echok"');
is(shift @opts, "-echonl", 'stty "-echonl"');
is(shift @opts, "echoke", 'stty "echoke"');
is(shift @opts, "-echoctl", 'stty "-echoctl"');
is(shift @opts, "-istrip", 'stty "-istrip"');
is(shift @opts, "-icrnl", 'stty "-icrnl"');
is(shift @opts, "-ocrnl", 'stty "-ocrnl"');
is(shift @opts, "-igncr", 'stty "-igncr"');
is(shift @opts, "-inlcr", 'stty "-inlcr"');

is(shift @opts, "onlcr", 'stty "onlcr"');
is(shift @opts, "-opost", 'stty "-opost"');
is(shift @opts, "-isig", 'stty "-isig"');
is(shift @opts, "-icanon", 'stty "-icanon"');
is(shift @opts, "cs8", 'stty "cs8"');
is(shift @opts, "-cstopb", 'stty "-cstopb"');
is(shift @opts, "-clocal", 'stty "-clocal"');
is(shift @opts, "-crtscts", 'stty "-crtscts"');
is(shift @opts, "-ixoff", 'stty "-ixoff"');
is(shift @opts, "-ixon", 'stty "-ixon"');
is(shift @opts, "-parenb", 'stty "-parenb"');
is(shift @opts, "-parodd", 'stty "-parodd"');
is(shift @opts, "-inpck", 'stty "-inpck"');

is(scalar @opts, 0, 'done with stty parameters');

print "Change all the parameters\n";

#### 46 - 74: Modify All Port Capabilities

is($ob->stty_echo(1), 1, 'stty_echo(1)');
is($ob->is_xon_char(0x91), 0x91, 'is_xon_char(0x91)');
is($ob->is_xoff_char(0x92), 0x92, 'is_xoff_char(0x92)');

is($ob->is_baudrate(1200), 1200, 'is_baudrate(1200)');
is($ob->is_parity("odd"), "odd", 'is_parity("odd")');
is($ob->is_databits(7), 7, 'is_databits(7)');
is($ob->is_stopbits(2), 2, 'is_stopbits(2)');
is($ob->is_handshake("xoff"), "xoff", 'is_handshake("xoff")');

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
is($ob->stty_echoe(0), 0, 'stty_echoe(0)');
is($ob->stty_echok(0), 0, 'stty_echok(0)');

is($ob->stty_intr("a"), "a", 'stty_intr("a")');
is($ob->stty_quit("b"), "b", 'stty_quit("b")');
is($ob->stty_eof("c"), "c", 'stty_eof("c")');
is($ob->stty_eol("d"), "d", 'stty_eol("d")');
is($ob->stty_erase("e"), "e", 'stty_erase("e")');
is($ob->stty_kill("f"), "f", 'stty_kill("f")');
is($ob->stty_echonl(1), 1, 'stty_echonl(1)');

$pass = $ob->can_parity_enable;
if ($pass) {
    # Windows bug, not fixed since NT4
    ok (defined $ob->is_parity_enable(1), 'parity_enable defined');
}
else {
    is($ob->is_parity_enable, 0, 'parity_enable');
}

#### 75 - 120: Check Port Capabilities from stty() Match Changes

@opts = $ob->stty();
ok (scalar @opts, 'changed stty parameters');
is(shift @opts, 1200, 'baud');
is(shift @opts, "intr", '"intr"');
is(shift @opts, "a", '"a"');
is(shift @opts, "quit", '"quit"');
is(shift @opts, "b", '"b"');
is(shift @opts, "erase", '"erase"');
is(shift @opts, "e", '"e"');
is(shift @opts, "kill", '"kill"');
is(shift @opts, "f", '"f"');

is(shift @opts, "eof", '"eof"');
is(shift @opts, "c", '"c"');
is(shift @opts, "eol", '"eol"');
is(shift @opts, "d", '"d"');

is(shift @opts, "start", '"start"');
is(shift @opts, "0x91", '"0x91"');
is(shift @opts, "stop", '"stop"');
is(shift @opts, "0x92", '"0x92"');
is(shift @opts, "echo", '"echo"');
is(shift @opts, "-echoe", '"-echoe"');

is(shift @opts, "-echok", '"-echok"');
is(shift @opts, "echonl", '"echonl"');
is(shift @opts, "-echoke", '"-echoke"');
is(shift @opts, "echoctl", '"echoctl"');
is(shift @opts, "istrip", '"istrip"');
is(shift @opts, "icrnl", '"icrnl"');
is(shift @opts, "ocrnl", '"ocrnl"');
is(shift @opts, "igncr", '"igncr"');
is(shift @opts, "inlcr", '"inlcr"');

is(shift @opts, "-onlcr", '"-onlcr"');
is(shift @opts, "opost", '"opost"');
is(shift @opts, "isig", '"isig"');
is(shift @opts, "icanon", '"icanon"');
is(shift @opts, "cs7", '"cs7"');
is(shift @opts, "cstopb", '"cstopb"');
is(shift @opts, "-clocal", '"-clocal"');

is(shift @opts, "-crtscts", '"-crtscts"');
is(shift @opts, "ixoff", '"ixoff"');
is(shift @opts, "ixon", '"ixon"');

$pass = $ob->can_parity_enable;
if ($pass) {
	## $MS bug workaround
    ok(($in = shift @opts) =~ /parenb/, '"parenb"');
    is(shift @opts, "parodd", '"parodd"');
    ok(($in = shift @opts) =~ /inpck/, '"inpck"');
}
else {
    is(shift @opts, "-parenb", '"-parenb"');
    is(shift @opts, "-parodd", '"-parodd"');
    is(shift @opts, "-inpck", '"-inpck"');
}
is(scalar @opts, 0, 'done with stty parameters');
is_bad ($ob->stty("bad"), 'invalid stty option');
is_bad ($ob->stty(1234), 'invalid stty value');
is_bad ($ob->stty("quit",undef), 'invalid stty setting');

#### 121 - 175: Check Port Capabilities from stty() Restore

ok ($ob->stty(@saves), 'restore stty from array');

@opts = $ob->stty();
ok (scalar @opts, 'stty parameters');
is(scalar @saves, scalar @opts, 'number of parameters match');
is(shift @opts, 9600, 'stty baud');
is(shift @opts, "intr", 'stty "intr"');

is(shift @opts, "^C", 'stty "^C"');
is(shift @opts, "quit", 'stty "quit"');
is(shift @opts, "^D", 'stty "^D"');
is(shift @opts, "erase", 'stty "erase"');
is(shift @opts, "^H", 'stty "^H"');
is(shift @opts, "kill", 'stty "kill"');
is(shift @opts, "^U", 'stty "^U"');

is(shift @opts, "eof", 'stty "eof"');
is(shift @opts, "^Z", 'stty "^Z"');
is(shift @opts, "eol", 'stty "eol"');
is(shift @opts, "^J", 'stty "^J"');
is(shift @opts, "start", 'stty "start"');
is(shift @opts, "^Q", 'stty "^Q"');
is(shift @opts, "stop", 'stty "stop"');
is(shift @opts, "^S", 'stty "^S"');
is(shift @opts, "-echo", 'stty "-echo"');
is(shift @opts, "echoe", 'stty "echoe"');

is(shift @opts, "echok", 'stty "echok"');
is(shift @opts, "-echonl", 'stty "-echonl"');
is(shift @opts, "echoke", 'stty "echoke"');
is(shift @opts, "-echoctl", 'stty "-echoctl"');
is(shift @opts, "-istrip", 'stty "-istrip"');
is(shift @opts, "-icrnl", 'stty "-icrnl"');
is(shift @opts, "-ocrnl", 'stty "-ocrnl"');
is(shift @opts, "-igncr", 'stty "-igncr"');
is(shift @opts, "-inlcr", 'stty "-inlcr"');

is(shift @opts, "onlcr", 'stty "onlcr"');
is(shift @opts, "-opost", 'stty "-opost"');
is(shift @opts, "-isig", 'stty "-isig"');
is(shift @opts, "-icanon", 'stty "-icanon"');
is(shift @opts, "cs8", 'stty "cs8"');
is(shift @opts, "-cstopb", 'stty "-cstopb"');
is(shift @opts, "-clocal", 'stty "-clocal"');
is(shift @opts, "-crtscts", 'stty "-crtscts"');
is(shift @opts, "-ixoff", 'stty "-ixoff"');
is(shift @opts, "-ixon", 'stty "-ixon"');
is(shift @opts, "-parenb", 'stty "-parenb"');
is(shift @opts, "-parodd", 'stty "-parodd"');
is(shift @opts, "-inpck", 'stty "-inpck"');

is(scalar @opts, 0, 'done with stty parameters');

is(Win32::SerialPort::cntl_char(undef), "<undef>", 'cntl_char(undef)');
is(Win32::SerialPort::cntl_char("\c_"), "^_", 'cntl_char("\c_")');
is(Win32::SerialPort::cntl_char(" "), " ", 'cntl_char(" ")');
is(Win32::SerialPort::cntl_char("\176"), "~", 'cntl_char("\176")');
is(Win32::SerialPort::cntl_char("\177"), "0x7f", 'cntl_char("\177")');
is(Win32::SerialPort::cntl_char("\200"), "0x80", 'cntl_char("\200")');
is(Win32::SerialPort::argv_char("^B"), 0x02, 'argv_char("^B")');
is(Win32::SerialPort::argv_char("^_"), 0x1f, 'argv_char("^_")');
is(Win32::SerialPort::argv_char("0xab"), 0xab, 'argv_char("0xab")');
is(Win32::SerialPort::argv_char("0202"), 0x82, 'argv_char("0202")');

print "Change all the parameters via stty\n";

#### 176 - 315: Modify All Parameters with stty()

is($ob->stty_echo, 0, 'stty_echo');
ok($ob->stty("echo"), 'stty("echo")');
is($ob->stty_echo, 1, 'stty_echo');
ok($ob->stty("-echo"), 'stty("-echo")');
is($ob->stty_echo, 0, 'stty_echo');

is($ob->is_xon_char, 0x11, 'is_xon_char');
is($ob->is_xoff_char, 0x13, 'is_xoff_char');
ok($ob->stty("start",0xc1), 'stty("start",0xc1)');
is($ob->is_xon_char, 0xc1, 'is_xon_char');
is($ob->is_xoff_char, 0x13, 'is_xoff_char');
ok($ob->stty("stop",0xc3), 'stty("stop",0xc3)');
is($ob->is_xon_char, 0xc1, 'is_xon_char');
is($ob->is_xoff_char, 0xc3, 'is_xoff_char');
ok($ob->stty("start",0x11,"stop",0x13), 'stty("start",0x11,"stop",0x13)');
is($ob->is_xon_char, 0x11, 'is_xon_char');
is($ob->is_xoff_char, 0x13, 'is_xoff_char');

is($ob->baudrate, 9600, 'baudrate');
ok($ob->stty(1200), 'stty(1200)');
is($ob->baudrate, 1200, 'baudrate');
ok($ob->stty("9600"), 'stty("9600")');
is($ob->baudrate, 9600, 'baudrate');

is($ob->is_databits, 8, 'is_databits');
is($ob->is_stopbits, 1, 'is_stopbits');
ok($ob->stty("cs5","cstopb"), 'stty("cs5","cstopb")');
SKIP: {
    skip "Some modern devices won't support old options", 5,
	if ($ob->is_databits == 8);
    is($ob->is_databits, 5, 'is_databits');
    ok($ob->is_stopbits, 'is_stopbits'); # detect misses '1 only'
    ok($ob->stty("cs6","-cstopb"), 'stty("cs6","-cstopb")');
    is($ob->is_databits, 6, 'is_databits');
    is($ob->is_stopbits, 1, 'is_stopbits');
}
ok($ob->stty("cs7"), 'stty("cs7")');
is($ob->is_databits, 7, 'is_databits');
ok($ob->stty("cs8"), 'stty("cs8")');
is($ob->is_databits, 8, 'is_databits');

is($ob->is_handshake, "none", 'is_handshake');
ok($ob->stty("ixon"), 'stty("ixon")');
is($ob->is_handshake, "xoff", 'is_handshake');
ok($ob->stty("-ixon"), 'stty("-ixon")');
is($ob->is_handshake, "none", 'is_handshake');
ok($ob->stty("ixoff"), 'stty("ixoff")');
is($ob->is_handshake, "xoff", 'is_handshake');
ok($ob->stty("-ixoff"), 'stty("-ixoff")');
is($ob->is_handshake, "none", 'is_handshake');
ok($ob->stty("crtscts"), 'stty("crtscts")');

is($ob->is_handshake, "rts", 'is_handshake');
ok($ob->stty("-crtscts"), 'stty("-crtscts")');
is($ob->is_handshake, "none", 'is_handshake');
ok($ob->stty("-clocal"), 'stty("-clocal")');
is($ob->is_handshake, "dtr", 'is_handshake');
ok($ob->stty("clocal"), 'stty("clocal")');
is($ob->is_handshake, "none", 'is_handshake');

is($ob->is_parity, "none", 'is_parity');
ok($ob->stty("parodd"), 'stty("parodd")');
is($ob->is_parity, "odd", 'is_parity');
ok($ob->stty("-parodd"), 'stty("-parodd")');
is($ob->is_parity, "even", 'is_parity');

$pass = $ob->can_parity_enable;
if ($pass) {
	# $MS doesn't report parity ON state correctly
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("inpck"), 'stty("inpck")');
    ok (defined $ob->is_parity_enable, 'parity_enable ON defined');
    ok($ob->stty("-parenb"), 'stty("-parenb")');
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("parenb"), 'stty("parenb")');
    ok (defined $ob->is_parity_enable, 'parity_enable ON defined');
    ok($ob->stty("-parenb"), 'stty("-parenb")');
}
else {
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("inpck"), 'stty("inpck")');
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("-parenb"), 'stty("-parenb")');
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("parenb"), 'stty("parenb")');
    is($ob->is_parity_enable, 0, 'parity_enable OFF');
    ok($ob->stty("-parenb"), 'stty("-parenb")');
}
ok($ob->stty("-inpck"), 'stty("-inpck")');
is($ob->is_parity, "none", 'is_parity');

is($ob->is_parity_enable, 0, 'parity_enable OFF');
is($ob->stty_echoe, 1, 'stty_echoe');
is($ob->stty_echok, 1, 'stty_echok');
is($ob->stty_echoke, 1, 'stty_echoke');
is($ob->stty_echoctl, 0, 'stty_echoctl');
is($ob->stty_echonl, 0, 'stty_echonl');

ok($ob->stty("-echoe","-echok","-echoke"), 'stty -echoe -echok -echoke');
ok($ob->stty("echoctl","echonl"), 'stty echoctl echonl');
is($ob->stty_echoe, 0, 'stty_echoe');
is($ob->stty_echok, 0, 'stty_echok');
is($ob->stty_echoke, 0, 'stty_echoke');
is($ob->stty_echoctl, 1, 'stty_echoctl');
is($ob->stty_echonl, 1, 'stty_echonl');

ok($ob->stty("echoe","echok","echoke"), 'stty echoe echok echoke');
ok($ob->stty("-echoctl","-echonl"), 'stty -echoctl -echonl');
is($ob->stty_echoe, 1, 'stty_echoe');
is($ob->stty_echok, 1, 'stty_echok');
is($ob->stty_echoke, 1, 'stty_echoke');
is($ob->stty_echoctl, 0, 'stty_echoctl');
is($ob->stty_echonl, 0, 'stty_echonl');

is($ob->stty_istrip, 0, 'stty_istrip');
ok($ob->stty("istrip"), 'stty("istrip")');

is($ob->stty_istrip, 1, 'stty_istrip');
is($ob->stty_isig, 0, 'stty_isig');
is($ob->stty_icanon, 0, 'stty_icanon');
ok($ob->stty("-istrip","isig","icanon"), 'stty istrip isig icanon');
is($ob->stty_istrip, 0, 'stty_istrip');
is($ob->stty_isig, 1, 'stty_isig');
is($ob->stty_icanon, 1, 'stty_icanon');
is($ob->stty_opost, 0, 'stty_opost');

ok($ob->stty("-isig","-icanon","opost"), 'stty -isig -icanon opost');
is($ob->stty_isig, 0, 'stty_isig');
is($ob->stty_icanon, 0, 'stty_icanon');
is($ob->stty_opost, 1, 'stty_opost');
is($ob->stty_ocrnl, 0, 'stty_ocrnl');
is($ob->stty_onlcr, 1, 'stty_onlcr');

ok($ob->stty("ocrnl","-onlcr","-opost"), 'stty ocrnl -onlcr -opost');
is($ob->stty_opost, 0, 'stty_opost');
is($ob->stty_ocrnl, 1, 'stty_ocrnl');
is($ob->stty_onlcr, 0, 'stty_onlcr');
is($ob->stty_icrnl, 0, 'stty_icrnl');

ok($ob->stty("-ocrnl","onlcr","icrnl"), 'stty -ocrnl onlcr icrnl');
is($ob->stty_ocrnl, 0, 'stty_ocrnl');
is($ob->stty_onlcr, 1, 'stty_onlcr');

is($ob->stty_icrnl, 1, 'stty_icrnl');
is($ob->stty_igncr, 0, 'stty_igncr');
is($ob->stty_inlcr, 0, 'stty_inlcr');

ok($ob->stty("-icrnl","igncr","inlcr"), 'stty -icrnl igncr inlcr');
is($ob->stty_icrnl, 0, 'stty_icrnl');
is($ob->stty_igncr, 1, 'stty_igncr');
is($ob->stty_inlcr, 1, 'stty_inlcr');

ok($ob->stty("-igncr","-inlcr"), 'stty -igncr -inlcr');
is($ob->stty_igncr, 0, 'stty_igncr');
is($ob->stty_inlcr, 0, 'stty_inlcr');

is($ob->stty_intr, "\cC", 'stty_intr');
is($ob->stty_quit, "\cD", 'stty_quit');
is($ob->stty_eof, "\cZ", 'stty_eof');
is($ob->stty_eol, "\cJ", 'stty_eol');
is($ob->stty_erase, "\cH", 'stty_erase');
is($ob->stty_kill, "\cU", 'stty_kill');

ok($ob->stty("intr",ord("A"),"quit",ord "B",
		 "eof",0x43,"eol",68,
		 "erase",0105,"kill",0x66), 'stty char settings');

is($ob->stty_intr, "A", 'stty_intr');
is($ob->stty_quit, "B", 'stty_quit');
is($ob->stty_eof, "C", 'stty_eof');
is($ob->stty_eol, "D", 'stty_eol');
is($ob->stty_erase, "E", 'stty_erase');
is($ob->stty_kill, "f", 'stty_kill');

ok($ob->stty("intr","^C","quit",4, "eof",032,"eol",0x0a,
		 "erase",ord("\cH"),
		 "kill",ord "\cU"), 'restore stty char settings');

is($ob->stty_intr, "\cC", 'stty_intr');
is($ob->stty_quit, "\cD", 'stty_quit');
is($ob->stty_eof, "\cZ", 'stty_eof');
is($ob->stty_eol, "\cJ", 'stty_eol');
is($ob->stty_erase, "\cH", 'stty_erase');
is($ob->stty_kill, "\cU", 'stty_kill');

ok ($ob->close, 'close');
undef $ob;
