use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
### use Data::Dumper;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 90;
}
cmp_ok($Win32::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use Win32::SerialPort qw( :STAT 0.20 );

use strict;
use warnings;

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

my $e="testing is a wonderful thing - this is a 60 byte long string";
#      123456789012345678901234567890123456789012345678901234567890
my $line = $e.$e.$e;		# about 185 MS at 9600 baud

my $fault = 0;
my $ob;
my $pass;
my $fail;
my $match;
my $left;
my @opts;
my $patt;
my $err;
my $blk;
my $tick;
my $tock;
my $in;
my $out;
my $instead;
my @necessary_param = Win32::SerialPort->set_test_mode_active(1);

## 2: Open as Tie using File 

    # constructor = TIEHANDLE method
ok ($ob = tie(*PORT,'Win32::SerialPort', $cfgfile), "tie $cfgfile");
die unless ($ob);    # next tests would die at runtime

### 27 - 65: Defaults for streamline and lookfor

@opts = $ob->are_match("\n");
is (scalar @opts, 1, 'are match');
is ($opts[0], "\n", 'new line as default');
is ($ob->lookclear, 1, 'lookclear');
is ($ob->is_prompt(""), "", 'is_prompt');
is ($ob->lookfor, "", 'lookfor');
is ($ob->streamline, "", 'streamline');

($in, $out, $patt, $instead) = $ob->lastlook;
is ($in, "", 'input that MATCHED');
is ($out, "", 'input AFTER match');
is ($patt, "", 'PATTERN that matched');
is ($instead, "", 'input INSTEAD of matching');
is ($ob->matchclear, "", 'MATCH was first');

is($ob->handshake("none"), "none", 'handshake("none")');
is($ob->stty_onlcr(0), 0, 'stty_onlcr(0)');

is($ob->read_char_time(0), 0, 'read_char_time(0)');
is($ob->read_const_time(1000), 1000, 'read_const_time(1000)');
is($ob->read_interval(0), 0, 'read_interval(0)');
is($ob->write_char_time(0), 0, 'write_char_time(0)');
is($ob->write_const_time(2000), 2000, 'write_const_time(2000)');

    # tie to PRINT method
$tick=$ob->get_tick_count;
$pass=print PORT $line;
is(0+$^E, 0, 'confirm no error');
$tock=$ob->get_tick_count;

is($pass, 1, 'PRINT method');
$err=$tock - $tick;
if ($err < 160) {
	$BUFFEROUT = 1;	# USB and virtual ports can't test output timing
}
if ($BUFFEROUT) {
	is_bad ($err > 210, 'skip PRINT timing');
} else {
	is_bad (($err < 160) or ($err > 210), 'PRINT timing');
}
print "<185> elapsed time=$err\n";

    # tie to READLINE method
SKIP: {
    skip "Can't rely on tied input/output", 18 if $BUFFEROUT;
    $tick=$ob->get_tick_count;
    $fail = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 1121, 'timeout error');

    is_bad(defined $fail, 'READLINE returns undef');
    $err=$tock - $tick;
    is_bad (($err < 800) or ($err > 1200), 'READLINE timeout');
    print "<1000> elapsed time=$err\n";

    $tick=$ob->get_tick_count;
    @opts = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 1121, 'timeout error');

    is(scalar @opts, 0, 'slurp returns empty');
    $err=$tock - $tick;
    is_bad (($err < 800) or ($err > 1200), 'slurp timeout');
    print "<1000> elapsed time=$err\n";

    # tie to PRINTF method
    $tick=$ob->get_tick_count;
    $pass=printf PORT "123456789_%s_987654321", $line;
    is(0+$^E, 0, 'confirm no error');
    $tock=$ob->get_tick_count;

    is($pass, 1, 'PRINTF method');
    $err=$tock - $tick;
    is_bad (($err < 180) or ($err > 235), 'PRINTF timing');
    print "<205> elapsed time=$err\n";

    # tie to GETC method
    $tick=$ob->get_tick_count;
    $fail = getc PORT;
    is(0+$^E, 1121, 'timeout error');
    $tock=$ob->get_tick_count;

    is_bad(defined $fail, 'GETC returns undef');
    $err=$tock - $tick;
    is_bad (($err < 800) or ($err > 1200), 'GETC timing');
    print "<1000> elapsed time=$err\n";

    # tie to WRITE method
    $tick=$ob->get_tick_count;
    $pass=syswrite PORT, $line, length($line), 0;
    is($pass, 180, 'syswrite count');
    is(0+$^E, 0, 'confirm no error');
    $tock=$ob->get_tick_count;

    $err=$tock - $tick;
    is_bad (($err < 160) or ($err > 210), 'syswrite timing');
    print "<185> elapsed time=$err\n";

    # tie to READ method
    my $in = "1234567890";
    $tick=$ob->get_tick_count;
    $fail = sysread (PORT, $in, 5, 0);
    is(0+$^E, 1121, 'timeout error');
    $tock=$ob->get_tick_count;

    is_bad(defined $fail, 'sysread returns undef');
    $err=$tock - $tick;
    is_bad (($err < 800) or ($err > 1200), 'sysread timing');
    print "<1000> elapsed time=$err\n";
}

    # force READLINE hardware errors
$fail = $ob->input; # should clear any remaining characters
($blk, $pass, $fail, $err)=$ob->is_status(0x8);	# test only
$tick=$ob->get_tick_count;
$fail = <PORT>;
$tock=$ob->get_tick_count;
is(0+$^E, 1117, 'forced hardware error');
is_bad(defined $fail, 'error returns undef');
$err=$tock - $tick;
is_bad ($err > 100, 'rapidly');
print "<0> elapsed time=$err\n";
is ($ob->reset_error, 0, 'reset_error');

## $fail = $ob->input; # should clear any remaining characters
($blk, $pass, $fail, $err)=$ob->is_status(0x8);	# test only
$tick=$ob->get_tick_count;
@opts = <PORT>;
$tock=$ob->get_tick_count;
is(0+$^E, 1117, 'forced hardware error');
is_bad(scalar @opts, 'slurp returns undef');
$err=$tock - $tick;
is_bad ($err > 100, 'quickly');
print "<0> elapsed time=$err\n";
is ($ob->reset_error, 0, 'reset_error');

    # READLINE data processing
is($ob->linesize, 1, 'linesize default');
is($ob->linesize(0), 0, 'linesize(0)');
is($ob->lookclear("First\nSecond\n\nFourth\nLast Line\nEND"), 1, 'lookclear five line load');

SKIP: {
    skip "Can't rely on no input", 37 if $BUFFEROUT;
    $tick=$ob->get_tick_count;
    $pass = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 0, 'no error');
    is($pass, "First\n", 'first line');
    $err=$tock - $tick;
    is_bad ($err > 100, 'should be fast');
    print "<0> elapsed time=$err\n";

    is($ob->lastline("Last L..e"), "Last L..e", 'lastline');
    $ob->reset_error;
    $tick=$ob->get_tick_count;
    @opts = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 0, 'check no error');
    is($#opts, 3, 'four more lines');
    is($opts[0], "Second\n", 'second line');
    is($opts[1], "\n", 'third line');
    is($opts[2], "Fourth\n", 'fourth line');
    is($opts[3], "Last Line\n", 'fifth line');

    ($in, $out, $patt, $instead) = $ob->lastlook;
    is ($in, "", 'input that MATCHED');
    is ($out, "END", 'input AFTER match');
    is ($patt, "\n", 'PATTERN that matched');
    is ($instead, "", 'input INSTEAD of matching');
    is ($ob->matchclear, "", 'MATCH was not first');
    
        # preload and do three lines non-blocking
    is($ob->lookclear("One\n\nThree\nFour\nLast Line\nplus"), 1, 'load for non-blocking');
    $ob->reset_error;
    $tick=$ob->get_tick_count;
    $pass = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 0, 'check no error');
    ## $ob->reset_error;
    is($pass, "One\n", 'line One');
    $err=$tock - $tick;
    is_bad ($err > 100, 'speedy');
    print "<0> elapsed time=$err\n";
    
    $ob->reset_error;
    $pass = <PORT>;
    is(0+$^E, 0, 'check no error');
    ## $ob->reset_error;
    is($pass, "\n", 'line Two');
    ($in, $out, $patt, $instead) = $ob->lastlook;
    is ($in, "", 'input that MATCHED');
    is ($out, "Three\nFour\nLast Line\nplus", 'input AFTER match');
    is ($patt, "\n", 'PATTERN that matched');
    
    $ob->reset_error;
    $pass = <PORT>;
    is(0+$^E, 0, 'check no error');
    is($pass, "Three\n", 'line Three');
    ($in, $out, $patt, $instead) = $ob->lastlook;
    is ($in, "", 'input that MATCHED');
    is ($out, "Four\nLast Line\nplus", 'input AFTER match');
    is ($patt, "\n", 'PATTERN that matched');

    # switch back to blocking reads
    is($ob->linesize(1), 1, 'linesize');
    
    $ob->reset_error;
    $tick=$ob->get_tick_count;
    $fail = <PORT>;
    $tock=$ob->get_tick_count;
    is(0+$^E, 1121, 'timeout error');

    is_bad(defined $fail, 'READLINE returns undef');
    $err=$tock - $tick;
    is_bad (($err < 800) or ($err > 1200), 'READLINE timeout');
    print "<1000> elapsed time=$err\n";

    ($in, $out, $patt, $instead) = $ob->lastlook;
    is ($in, "", 'input that MATCHED');
    is ($out, "Four\nLast Line\nplus", 'input AFTER match');
    is ($patt, "", 'PATTERN that matched');
    is ($instead, "", 'input INSTEAD of matching');
}

    # destructor = CLOSE method
ok(close PORT, 'close');

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!
untie *PORT;
