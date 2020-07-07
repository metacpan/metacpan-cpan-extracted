# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { mb::eval(<<'END'); }, # test no 1
$_='ABC'; scalar(s/(A)(B)(C)//);
END
    sub { mb::eval(<<'END'); }, # test no 2
$_='ABC'; s/(A)(B)(C)//; $1 eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 3
$_='ABC'; s/(A)(B)(C)//; $2 eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 4
$_='ABC'; s/(A)(B)(C)//; $3 eq 'C';
END
    sub { mb::eval(<<'END'); }, # test no 5
$_='ABC'; s/(B)//; $` eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 6
$_='ABC'; s/(B)//; ${`} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 7
$_='ABC'; s/(B)//; $PREMATCH eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 8
$_='ABC'; s/(B)//; ${PREMATCH} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 9
$_='ABC'; s/(B)//; ${^PREMATCH} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 10
$_='ABC'; s/(B)//; $& eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 11
$_='ABC'; s/(B)//; ${&} eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 12
$_='ABC'; s/(B)//; $MATCH eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 13
$_='ABC'; s/(B)//; ${MATCH} eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 14
$_='ABC'; s/(B)//; ${^MATCH} eq 'B';
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 15
my $a=$_='ABCDEF'; s/((B)(C)(D))//; $` eq CORE::substr($a, 0, $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 16
my $a=$_='ABCDEF'; s/((B)(C)(D))//; $& eq CORE::substr($a, $-[1], $+[1] - $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 17
my $a=$_='ABCDEF'; s/(B)(C)(D)//; $' eq CORE::substr($a, $+[0]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 18
my $a=$_='ABCDEF'; s/(B)(C)(D)//; $1 eq CORE::substr($a, $-[1], $+[1] - $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 19
my $a=$_='ABCDEF'; s/(B)(C)(D)//; $2 eq CORE::substr($a, $-[2], $+[2] - $-[2]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 20
my $a=$_='ABCDEF'; s/(B)(C)(D)//; $3 eq CORE::substr($a, $-[3], $+[3] - $-[3]);
END
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
