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
    sub { 'A' =~ /A/; }, # test no 1
    sub { CORE::eval(<<'END'); }, # test no 2
'A' =~ /A/
END
    sub { eval mb::parse(<<'END'); }, # test no 3
'A' =~ /A/
END
    sub { eval mb::parse(<<'END'); }, # test no 4
'ABC' =~ /(.)/
END
    sub { eval mb::parse(<<'END'); }, # test no 5
'ABC' =~ /(.)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 6
'ABC' =~ /\B/
END
    sub { eval mb::parse(<<'END'); }, # test no 7
'ABC' =~ /(\D)/
END
    sub { eval mb::parse(<<'END'); }, # test no 8
'ABC' =~ /(\D)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 9
'ABC' =~ /(\H)/
END
    sub { eval mb::parse(<<'END'); }, # test no 10
'ABC' =~ /(\H)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 11
'ABC' =~ /(\N)/
END
    sub { eval mb::parse(<<'END'); }, # test no 12
'ABC' =~ /(\N)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 13
"\r" =~ /(\R)/
END
    sub { eval mb::parse(<<'END'); }, # test no 14
"\r" =~ /(\R)/; $1 eq "\r";
END
    sub { eval mb::parse(<<'END'); }, # test no 15
"\n" =~ /(\R)/
END
    sub { eval mb::parse(<<'END'); }, # test no 16
"\n" =~ /(\R)/; $1 eq "\n";
END
    sub { eval mb::parse(<<'END'); }, # test no 17
"\r\n" =~ /(\R)/
END
    sub { eval mb::parse(<<'END'); }, # test no 18
"\r\n" =~ /(\R)/; $1 eq "\r\n";
END
    sub { eval mb::parse(<<'END'); }, # test no 19
'ABC' =~ /(\S)/
END
    sub { eval mb::parse(<<'END'); }, # test no 20
'ABC' =~ /(\S)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 21
'ABC' =~ /(\V)/
END
    sub { eval mb::parse(<<'END'); }, # test no 22
'ABC' =~ /(\V)/; $1 eq 'A';
END
    sub { eval mb::parse(<<'END'); }, # test no 23
'AB!C' =~ /(\W)/
END
    sub { eval mb::parse(<<'END'); }, # test no 24
my $not_void = 'AB!C' !~ /(\W)/; $1 eq '!';
END
    sub { eval mb::parse(<<'END'); }, # test no 25
'AB C' =~ /(.)\b(.)/; (($1 eq 'B') and ($2 eq ' '));
END
    sub { eval mb::parse(<<'END'); }, # test no 26
'123' =~ /(\d)/; $1 eq '1';
END
    sub { eval mb::parse(<<'END'); }, # test no 27
"\x09" =~ /(\h)/; $1 eq "\x09";
END
    sub { eval mb::parse(<<'END'); }, # test no 28
"\x20" =~ /(\h)/; $1 eq "\x20";
END
    sub { eval mb::parse(<<'END'); }, # test no 29
"\t" =~ /(\s)/; $1 eq "\t";
END
    sub { eval mb::parse(<<'END'); }, # test no 30
"\n" =~ /(\s)/; $1 eq "\n";
END
    sub { eval mb::parse(<<'END'); }, # test no 31
"\f" =~ /(\s)/; $1 eq "\f";
END
    sub { eval mb::parse(<<'END'); }, # test no 32
"\r" =~ /(\s)/; $1 eq "\r";
END
    sub { eval mb::parse(<<'END'); }, # test no 33
"\x20" =~ /(\s)/; $1 eq "\x20";
END
    sub { eval mb::parse(<<'END'); }, # test no 34
"\x0A" =~ /(\v)/; $1 eq "\x0A";
END
    sub { eval mb::parse(<<'END'); }, # test no 35
"\x0B" =~ /(\v)/; $1 eq "\x0B";
END
    sub { eval mb::parse(<<'END'); }, # test no 36
"\x0C" =~ /(\v)/; $1 eq "\x0C";
END
    sub { eval mb::parse(<<'END'); }, # test no 37
"\x0D" =~ /(\v)/; $1 eq "\x0D";
END
    sub { eval mb::parse(<<'END'); }, # test no 38
'ABC' =~ /(\w)/; $1 eq 'A';
END
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
