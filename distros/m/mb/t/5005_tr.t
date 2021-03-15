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

    sub { eval(<<'END1'); }, # test no 13
$_='AAA'; my $r=tr/A/1/s; $r == 3
END1

    sub { mb::eval(<<'END1'); }, # test no 14
return 'SKIP'; $_='‚`‚`‚`'; my $r=tr/‚`/‚P/s; ($r == 3, $r)
END1
    sub { mb::eval(<<'END1'); }, # test no 15
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/s; $_ eq '‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 16
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/cs; $r == 1;
END1
    sub { mb::eval(<<'END1'); }, # test no 17
$_='‚`‚`‚`'; my $r=tr/‚`/‚P/cs; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 18
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/cs; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 19
$_='‚`‚`‚`'; my $r=tr/‚a/‚P/cs; $_ eq '‚P'
END1

    sub { mb::eval(<<'END1'); }, # test no 20
$_='‚`‚`‚`'; my $r=tr/‚`//ds; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 21
$_='‚`‚`‚`'; my $r=tr/‚`//ds; $_ eq ''
END1

    sub { mb::eval(<<'END1'); }, # test no 22
$_='‚`‚`‚`'; my $r=tr/‚`//cds; $r == 1;
END1
    sub { mb::eval(<<'END1'); }, # test no 23
$_='‚`‚`‚`'; my $r=tr/‚`//cds; $_ eq '‚`‚`‚`'
END1

    sub { mb::eval(<<'END1'); }, # test no 24
$_='‚`‚`‚`'; my $r=tr/‚a//cds; $r == 1
END1
    sub { mb::eval(<<'END1'); }, # test no 25
$_='‚`‚`‚`'; my $r=tr/‚a//cds; $_ eq ''
END1
    sub { mb::eval(<<'END1'); }, # test no 26
$_='ABC'; my $var='A'; my $r=tr/$var/5/; $_ eq 'ABC'
END1
    sub { mb::eval(<<'END1'); }, # test no 27
$_='$'; my $r=tr/$/5/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 28
$_='$var'; my $var='A'; my $r=tr/$var/5678/; $_ eq '5678'
END1
    sub { mb::eval(<<'END1'); }, # test no 29
$_='ABC'; my @var='A'; my $r=tr/@var/5/; $_ eq 'ABC'
END1
    sub { mb::eval(<<'END1'); }, # test no 30
$_='@'; my $r=tr/@/5/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 31
$_='@var'; my @var='A'; my $r=tr/@var/5678/; $_ eq '5678'
END1
    sub { mb::eval(<<'END1'); }, # test no 32
$_='@'; my $r=tr/@/5/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 33
$_='\\'; my $r=tr/\\/5/; $_ eq '5'
END1
    sub { CORE::eval(<<'END1'); }, # test no 34
$_='U'; my $r=tr/\U/56/; $_ eq '5'
END1
    sub { CORE::eval(<<'END1'); }, # test no 35
$_='\\'; my $r=tr/\\/7/; $_ eq '7'
END1
    sub { mb::eval(<<'END1'); }, # test no 36
$_='UuLlQE\\Aa'; my $r=tr/\UAa/5678/; $_ eq '5uLlQE\\67'
END1
    sub { mb::eval(<<'END1'); }, # test no 37
$_='UuLlQE\\Aa'; my $r=tr/\uaA/5678/; $_ eq 'U5LlQE\\76'
END1
    sub { mb::eval(<<'END1'); }, # test no 38
$_='UuLlQE\\Aa'; my $r=tr/\LAa/5678/; $_ eq 'Uu5lQE\\67'
END1
    sub { mb::eval(<<'END1'); }, # test no 39
$_='UuLlQE\\Aa'; my $r=tr/\laA/5678/; $_ eq 'UuL5QE\\76'
END1
    sub { mb::eval(<<'END1'); }, # test no 40
$_='UuLlQE\\Aa'; my $r=tr/\QAa/5678/; $_ eq 'UuLl5E\\67'
END1
    sub { mb::eval(<<'END1'); }, # test no 41
$_='UuLlQE\\Aa'; my $r=tr/\EaA/5678/; $_ eq 'UuLlQ5\\76'
END1
    sub { mb::eval(<<'END1'); }, # test no 42
$_="\a\b\e\f\n\r\t"; my $r=tr/\a\b\e\f\n\r\t/2345678/; ($_ eq '2345678', "($_)")
END1
    sub { mb::eval(<<'END1'); }, # test no 43
$_="\0"; my $r=tr/\0/2/; $_ eq '2'
END1
    sub { mb::eval(<<'END1'); }, # test no 44
$_="0\0"; my $r=tr/\00/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 45
$_="0\0"; my $r=tr/\000/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 46
$_="\123"; my $r=tr/\123/56/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 47
$_="\0"; my $r=tr/\o0/2/; $_ eq '2'
END1
    sub { mb::eval(<<'END1'); }, # test no 48
$_="0\0"; my $r=tr/\o00/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 49
$_="0\0"; my $r=tr/\o000/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 50
$_="\123"; my $r=tr/\o123/56/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 51
$_="\0"; my $r=tr/\o{0}/2/; $_ eq '2'
END1
    sub { mb::eval(<<'END1'); }, # test no 52
$_="0\0"; my $r=tr/\o{00}/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 53
$_="0\0"; my $r=tr/\o{000}/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 54
$_="\123"; my $r=tr/\o{123}/56/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 55
$_="\x0"; my $r=tr/\x0/2/; $_ eq '2'
END1
    sub { mb::eval(<<'END1'); }, # test no 56
$_="0\x0"; my $r=tr/\x00/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 57
$_="\x123"; my $r=tr/\x123/56/; $_ eq '56'
END1
    sub { mb::eval(<<'END1'); }, # test no 58
$_="\x0"; my $r=tr/\x{0}/2/; $_ eq '2'
END1
    sub { mb::eval(<<'END1'); }, # test no 59
$_="0\x0"; my $r=tr/\x{00}/56/; $_ eq '05'
END1
    sub { mb::eval(<<'END1'); }, # test no 60
$_="\x{8141}"; my $r=tr/\x{8141}/56/; $_ eq '5'
END1
    sub { mb::eval(<<'END1'); }, # test no 61
$_="\c@"; my $r=tr/\c@/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 62
$_="\cA"; my $r=tr/\cA/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 63
$_="\c["; my $r=tr/\c[/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 64
return 'SKIP'; $_="\c\\"; my $r=tr/\c\/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 65
$_="\x1C"; my $r=tr/\c\/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 66
$_="\c]"; my $r=tr/\c]/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 67
$_="\c^"; my $r=tr/\c^/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 68
$_="\c_"; my $r=tr/\c_/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 69
$_="\c?"; my $r=tr/\c?/678/; $_ eq '6'
END1
    sub { mb::eval(<<'END1'); }, # test no 70
$_="ABCDEFG"; my $r=tr/B-E/3456/; $_ eq 'A3456FG'
END1
    sub { mb::eval(<<'END1'); }, # test no 71
$_="ABCDEFG"; my $r=tr/BCDE/3-6/; $_ eq 'A3456FG'
END1
    sub { mb::eval(<<'END1'); }, # test no 72
$_="ABCDEFG"; my $r=tr/B-E/3-6/; $_ eq 'A3456FG'
END1
    sub { mb::eval(<<'END1'); }, # test no 73
$_="\x0A\x0B\x0C\x0D"; my $r=tr/\n-\r/1234/; ($_ eq '1234', "($_)")
END1
    sub { mb::eval(<<'END1'); }, # test no 74
$_="-ABC-"; my $r=tr/-AB/123/; $_ eq '123C1'
END1
    sub { mb::eval(<<'END1'); }, # test no 75
$_="-ABC-"; my $r=tr/AB-/123/; $_ eq '312C3'
END1
    sub { mb::eval(<<'END1'); }, # test no 76
$_="-ABC-"; my $r=tr/A-C/123/; $_ eq '-123-'
END1
    sub { mb::eval(<<'END1'); }, # test no 77
$_="-"; my $r=tr/\-/3/; $_ eq '3'
END1
    sub { mb::eval(<<'END1'); }, # test no 78
$_="A-"; my $r=tr/A\-/23/; $_ eq '23'
END1
    sub { mb::eval(<<'END1'); }, # test no 79
$_="A-"; my $r=tr/A-/23/; $_ eq '23'
END1
    sub { mb::eval(<<'END1'); }, # test no 80
$_="A-"; my $r=tr/\-A/23/; $_ eq '32'
END1
    sub { mb::eval(<<'END1'); }, # test no 81
$_="A-"; my $r=tr/-A/23/; $_ eq '32'
END1
    sub { mb::eval(<<'END1'); }, # test no 82
$_=",-."; my $r=tr/,-./789/; $_ eq '789'
END1
    sub { mb::eval(<<'END1'); }, # test no 83
$_=",-."; my $r=tr/--./789/; $_ eq ',78'
END1
    sub { mb::eval(<<'END1'); }, # test no 84
$_=",-."; my $r=tr/,--/789/; $_ eq '78.'
END1
    sub { mb::eval(<<'END1'); }, # test no 85
$_=",-."; my $r=tr/,\-./654/; $_ eq '654'
END1
    sub { mb::eval(<<'END1'); }, # test no 86
$_="-.,"; my $r=tr/,\-./654/; $_ eq '546'
END1
    sub { mb::eval(<<'END1'); }, # test no 87
$_="ABC-"; my $r=tr/AC-/654/; $_ eq '6B54'
END1

##############################################################################
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
