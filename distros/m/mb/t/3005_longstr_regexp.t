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
    sub {                            $_=<<'END1'; mb::eval(); }, # test no 1
('A' x 32765).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 2
('A' x 32766).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 3
('A' x 32767).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 4
('A' x 32768).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 5
('A' x 65534).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 6
('A' x 65535).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 7
('A' x 65536).'B' =~ /B/
END1
    sub {                            $_=<<'END1'; mb::eval(); }, # test no 8
('A' x 32765).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 9
('A' x 32766).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 10
('A' x 32767).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); }, # test no 11
('A' x 32768).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 12
('A' x 65534).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 13
('A' x 65535).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); }, # test no 14
('A' x 65536).'B' !~ /C/
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
