# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '��' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { mb::eval(<<'END1'); }, # test no 1
'A' =~ /A/
END1
    sub { mb::eval(<<'END1'); }, # test no 2
'A' =~ /A/i
END1
    sub { mb::eval(<<'END1'); }, # test no 3
'A' =~ /a/i
END1
    sub { mb::eval(<<'END1'); }, # test no 4
'ABC' =~ /ABC/i
END1
    sub { mb::eval(<<'END1'); }, # test no 5
'ABC' =~ /abc/i
END1
    sub { mb::eval(<<'END1'); }, # test no 6
'abc' =~ /ABC/i
END1
    sub { mb::eval(<<'END1'); }, # test no 7
'abc' =~ /abc/i
END1
    sub { mb::eval(<<'END1'); }, # test no 8
'AbC' =~ /aBc/i
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
