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
scalar('ABC' =~ /(A)(B)(C)/);
END
    sub { mb::eval(<<'END'); }, # test no 2
'ABC' =~ /(A)(B)(C)/; $1 eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 3
'ABC' =~ /(A)(B)(C)/; $2 eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 4
'ABC' =~ /(A)(B)(C)/; $3 eq 'C';
END
    sub { mb::eval(<<'END'); }, # test no 5
'ABC' =~ /(B)/; $` eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 6
'ABC' =~ /(B)/; ${`} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 7
'ABC' =~ /(B)/; $PREMATCH eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 8
'ABC' =~ /(B)/; ${PREMATCH} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 9
'ABC' =~ /(B)/; ${^PREMATCH} eq 'A';
END
    sub { mb::eval(<<'END'); }, # test no 10
'ABC' =~ /(B)/; $& eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 11
'ABC' =~ /(B)/; ${&} eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 12
'ABC' =~ /(B)/; $MATCH eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 13
'ABC' =~ /(B)/; ${MATCH} eq 'B';
END
    sub { mb::eval(<<'END'); }, # test no 14
'ABC' =~ /(B)/; ${^MATCH} eq 'B';
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 15
$_='ABCDEF'; /((B)(C)(D))/; $` eq CORE::substr($_, 0, $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 16
$_='ABCDEF'; /((B)(C)(D))/; $& eq CORE::substr($_, $-[1], $+[1] - $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 17
$_='ABCDEF'; /(B)(C)(D)/; $' eq CORE::substr($_, $+[0]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 18
$_='ABCDEF'; /(B)(C)(D)/; $1 eq CORE::substr($_, $-[1], $+[1] - $-[1]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 19
$_='ABCDEF'; /(B)(C)(D)/; $2 eq CORE::substr($_, $-[2], $+[2] - $-[2]);
END
    sub { return 'SKIP' if $] < 5.006; mb::eval(<<'END'); }, # test no 20
$_='ABCDEF'; /(B)(C)(D)/; $3 eq CORE::substr($_, $-[3], $+[3] - $-[3]);
END
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
