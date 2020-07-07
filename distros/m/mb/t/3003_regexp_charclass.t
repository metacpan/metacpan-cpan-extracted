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
    sub { eval mb::parse(<<'END'); }, # test no 1
'ABC' =~ /A([ABC])C/;
END
    sub { eval mb::parse(<<'END'); }, # test no 2
'ABC' =~ /A([ABC])C/; $1 eq 'B';
END
    sub { eval mb::parse(<<'END'); }, # test no 3
'‚ ‚¢‚¤' =~ /‚ ([‚ ‚¢‚¤])‚¤/;
END
    sub { eval mb::parse(<<'END'); }, # test no 4
'‚ ‚¢‚¤' =~ /‚ ([‚ ‚¢‚¤])‚¤/; $1 eq '‚¢';
END
    sub { eval mb::parse(<<'END'); }, # test no 5
'ABC' !~ /A([^ABC])C/;
END
    sub { eval mb::parse(<<'END'); }, # test no 6
'‚ ‚¢‚¤' !~ /‚ ([^‚ ‚¢‚¤])‚¤/;
END
    sub { eval mb::parse(<<'END'); }, # test no 7
'ABC' !~ /A([XYZ])C/;
END
    sub { eval mb::parse(<<'END'); }, # test no 8
'‚ ‚¢‚¤' !~ /‚ ([‚©‚«‚­])‚¤/;
END
    sub { eval mb::parse(<<'END'); }, # test no 9
'ABC' =~ /A([^XYZ])C/;
END
    sub { eval mb::parse(<<'END'); }, # test no 10
'ABC' =~ /A([^XYZ])C/; $1 eq 'B';
END
    sub { eval mb::parse(<<'END'); }, # test no 11
'‚ ‚¢‚¤' =~ /‚ ([^‚©‚«‚­])‚¤/;
END
    sub { eval mb::parse(<<'END'); }, # test no 12
'‚ ‚¢‚¤' =~ /‚ ([^‚©‚«‚­])‚¤/; $1 eq '‚¢';
END
    sub { eval mb::parse(<<'END'); }, # test no 13
'‚ ‚¢‚¤' =~ /‚¢/;
END
    sub { eval mb::parse(<<'END'); }, # test no 14
'ABC' =~ /abc/i;
END
    sub { eval mb::parse(<<'END'); }, # test no 15
'abc' =~ /ABC/i;
END
    sub { eval mb::parse(<<'END'); }, # test no 16
'ƒA' !~ /A/;
END
    sub { eval mb::parse(<<'END'); }, # test no 17
'ƒA' !~ /A/i;
END
    sub { eval mb::parse(<<'END'); }, # test no 18
'ƒA' !~ /a/;
END
    sub { eval mb::parse(<<'END'); }, # test no 19
'ƒA' !~ /a/i;
END
    sub { eval mb::parse(<<'END'); }, # test no 20
'ƒa' !~ /A/;
END
    sub { eval mb::parse(<<'END'); }, # test no 21
'ƒa' !~ /A/i;
END
    sub { eval mb::parse(<<'END'); }, # test no 22
'ƒa' !~ /a/;
END
    sub { eval mb::parse(<<'END'); }, # test no 23
'ƒa' !~ /a/i;
END
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
