# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
##############################################################################
    sub { mb::eval(<<'END1'); }, # test no 1
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/; $r == 3
END1
    sub { mb::eval(<<'END1'); }, # test no 2
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/; $_ eq '‚P‚P‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 3
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/c; $r == 0
END1
    sub { mb::eval(<<'END1'); }, # test no 4
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/c; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 5
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/c; $r == 3
END1
    sub { mb::eval(<<'END1'); }, # test no 6
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/c; $_ eq '‚P‚P‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 7
$_='‚`‚`‚`'; my $r=tr/‚`//d; $r == 3
END1
    sub { mb::eval(<<'END1'); }, # test no 8
$_='‚`‚`‚`'; my $r=tr/‚`//d; $_ eq ''
END1

    sub { mb::eval(<<'END1'); }, # test no 9
$_='‚`‚`‚`'; my $r=tr/‚`//cd; $r == 0
END1
    sub { mb::eval(<<'END1'); }, # test no 10
$_='‚`‚`‚`'; my $r=tr/‚`//cd; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 11
$_='‚`‚`‚`'; my $r=tr/‚a//cd; $r == 3
END1
    sub { mb::eval(<<'END1'); }, # test no 12
$_='‚`‚`‚`'; my $r=tr/‚a//cd; $_ eq ''
END1

    sub { mb::eval(<<'END1'); }, # test no 13 # SKIP
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/s; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 14
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/s; $_ eq '‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 15
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/cs; $r == 1;
END1
    sub { mb::eval(<<'END1'); }, # test no 16
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/cs; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 17
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/cs; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 18
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/cs; $_ eq '‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 19 # SKIP
$_='‚`‚`‚`'; my $r=tr/‚`//ds; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 20
$_='‚`‚`‚`'; my $r=tr/‚`//ds; $_ eq ''
END1

    sub { mb::eval(<<'END1'); }, # test no 21 # SKIP
$_='‚`‚`‚`'; my $r=tr/‚`//cds; $r == 1;
END1
    sub { mb::eval(<<'END1'); }, # test no 22
$_='‚`‚`‚`'; my $r=tr/‚`//cds; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 23 # SKIP
$_='‚`‚`‚`'; my $r=tr/‚a//cds; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 24
$_='‚`‚`‚`'; my $r=tr/‚a//cds; $_ eq ''
END1

##############################################################################
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
