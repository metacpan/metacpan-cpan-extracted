# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { mb::eval(<<'END1'); }, # test no 1
'1234567890' =~ /3/
END1
    sub { mb::eval(<<'END1'); }, # test no 2
'1234567890' !~ /A/
END1
    sub { CORE::eval(<<'END1'); }, # test no 3
'アイウエオ' =~ /E/
END1
    sub { mb::eval(<<'END1'); }, # test no 4
'アイウエオ' !~ /E/
END1
    sub { mb::eval(<<'END1'); }, # test no 5
'アイウエオ' =~ /ウ/
END1
    sub { mb::eval(<<'END1'); }, # test no 6
'アイウエオ' !~ /カ/
END1
    sub { mb::eval(<<'END1'); }, # test no 7
'1234567890' =~ m/3/
END1
    sub { mb::eval(<<'END1'); }, # test no 8
'1234567890' !~ m/A/
END1
    sub { CORE::eval(<<'END1'); }, # test no 9
'アイウエオ' =~ m/E/
END1
    sub { mb::eval(<<'END1'); }, # test no 10
'アイウエオ' !~ m/E/
END1
    sub { mb::eval(<<'END1'); }, # test no 11
'アイウエオ' =~ m/ウ/
END1
    sub { mb::eval(<<'END1'); }, # test no 12
'アイウエオ' !~ m/カ/
END1
    sub { mb::eval(<<'END1'); }, # test no 13
'1234567890' =~ qr/3/
END1
    sub { mb::eval(<<'END1'); }, # test no 14
'1234567890' !~ qr/A/
END1
    sub { CORE::eval(<<'END1'); }, # test no 15
'アイウエオ' =~ qr/E/
END1
    sub { mb::eval(<<'END1'); }, # test no 16
'アイウエオ' !~ qr/E/
END1
    sub { mb::eval(<<'END1'); }, # test no 17
'アイウエオ' =~ qr/ウ/
END1
    sub { mb::eval(<<'END1'); }, # test no 18
'アイウエオ' !~ qr/カ/
END1
    sub { mb::eval(<<'END1'); }, # test no 19
$_='1234567890'; s/3/1/; $_ eq '1214567890';
END1
    sub { mb::eval(<<'END1'); }, # test no 20
$_='1234567890'; s/A/1/; $_ eq '1234567890';
END1
    sub { CORE::eval(<<'END1'); }, # test no 21
$_='アイウエオ'; s/E/1/; $_ ne 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 22
$_='アイウエオ'; s/E/1/; $_ eq 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 23
$_='アイウエオ'; s/ウ/1/; $_ eq 'アイ1エオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 24
$_='アイウエオ'; s/カ/1/; $_ eq 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 25
$_='アAイウAエAオ'; @_=split(/A/); "@_" eq 'ア イウ エ オ';
END1
    sub { mb::eval(<<'END1'); }, # test no 26
'1234567890' =~ m'3'
END1
    sub { mb::eval(<<'END1'); }, # test no 27
'1234567890' !~ m'A'
END1
    sub { CORE::eval(<<'END1'); }, # test no 28
'アイウエオ' =~ m'E'
END1
    sub { mb::eval(<<'END1'); }, # test no 29
'アイウエオ' !~ m'E'
END1
    sub { mb::eval(<<'END1'); }, # test no 30
'アイウエオ' =~ m'ウ'
END1
    sub { mb::eval(<<'END1'); }, # test no 31
'アイウエオ' !~ m'カ'
END1
    sub { mb::eval(<<'END1'); }, # test no 32
'1234567890' =~ qr'3'
END1
    sub { mb::eval(<<'END1'); }, # test no 33
'1234567890' !~ qr'A'
END1
    sub { CORE::eval(<<'END1'); }, # test no 34
'アイウエオ' =~ qr'E'
END1
    sub { mb::eval(<<'END1'); }, # test no 35
'アイウエオ' !~ qr'E'
END1
    sub { mb::eval(<<'END1'); }, # test no 36
'アイウエオ' =~ qr'ウ'
END1
    sub { mb::eval(<<'END1'); }, # test no 37
'アイウエオ' !~ qr'カ'
END1
    sub { mb::eval(<<'END1'); }, # test no 38
$_='1234567890'; s'3'1'; $_ eq '1214567890';
END1
    sub { mb::eval(<<'END1'); }, # test no 39
$_='1234567890'; s'A'1'; $_ eq '1234567890';
END1
    sub { CORE::eval(<<'END1'); }, # test no 40
$_='アイウエオ'; s'E'1'; $_ ne 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 41
$_='アイウエオ'; s'E'1'; $_ eq 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 42
$_='アイウエオ'; s'ウ'1'; $_ eq 'アイ1エオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 43
$_='アイウエオ'; s'カ'1'; $_ eq 'アイウエオ';
END1
    sub { mb::eval(<<'END1'); }, # test no 44
$_='アAイウAエAオ'; @_=split('A'); "@_" eq 'ア イウ エ オ';
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
