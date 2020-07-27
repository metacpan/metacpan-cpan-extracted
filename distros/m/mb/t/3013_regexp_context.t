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
    sub { eval(<<'END1'); }, # test no 1
1;
END1
    sub { mb::eval(<<'END1'); }, # test no 2
1;
END1
    sub { mb::eval(<<'END1'); }, # test no 3
'A' =~ /A/;
END1
    sub { mb::eval(<<'END1'); }, # test no 4
@_ = 'ABC' =~ /(A)(B)(C)/; "@_" eq 'A B C';
END1
    sub { mb::eval(<<'END1'); }, # test no 5
@_ = 'ABCABCABC' =~ /(A)(B)(C)/; "@_" eq 'A B C';
END1
    sub { mb::eval(<<'END1'); }, # test no 6
@_ = 'ABCABCABC' =~ /(A)(B)(C)/g; "@_" eq 'A B C A B C A B C';
END1
    sub { mb::eval(<<'END1'); }, # test no 7
@_ = 'アイウアイウアイウ' =~ /(ア)(イ)(ウ)/g; "@_" eq 'ア イ ウ ア イ ウ ア イ ウ';
END1
    sub { mb::eval(<<'END1'); }, # test no 8
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $` eq 'アイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 9
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $& eq 'ウアイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 10
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $' eq 'ウアイウ';
END1
    sub { mb::eval(<<'END1'); }, # test no 11
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $1 eq 'ウアイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 12
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $2 eq 'ウ';
END1
    sub { mb::eval(<<'END1'); }, # test no 13
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $3 eq 'ア';
END1
    sub { mb::eval(<<'END1'); }, # test no 14
@_ = 'アイウアイウアイウ' =~ /((ウ)(ア)(イ))/; $4 eq 'イ';
END1
    sub { mb::eval(<<'END1'); }, # test no 15
$_='A'; s/A//;
END1
    sub { mb::eval(<<'END1'); }, # test no 16
$_='ABC'; s/(A)(B)(C)//; "($1)($2)($3)" eq '(A)(B)(C)';
END1
    sub { mb::eval(<<'END1'); }, # test no 17
$_='ABCABCABC'; s/(A)(B)(C)//; "($1)($2)($3)" eq '(A)(B)(C)';
END1
    sub { mb::eval(<<'END1'); }, # test no 18
$_='ABCDEFGHI'; s/(.)(.)(.)//g; "($1)($2)($3)" eq '(G)(H)(I)';
END1
    sub { mb::eval(<<'END1'); }, # test no 19
$_='アイウエオカキクケコ'; s/(.)(.)(.)//g; "($1)($2)($3)" eq '(キ)(ク)(ケ)';
END1
    sub { mb::eval(<<'END1'); }, # test no 20
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $` eq 'アイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 21
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $& eq 'ウアイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 22
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $' eq 'ウアイウ';
END1
    sub { mb::eval(<<'END1'); }, # test no 23
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $1 eq 'ウアイ';
END1
    sub { mb::eval(<<'END1'); }, # test no 24
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $2 eq 'ウ';
END1
    sub { mb::eval(<<'END1'); }, # test no 25
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $3 eq 'ア';
END1
    sub { mb::eval(<<'END1'); }, # test no 26
$_='アイウアイウアイウ'; s/((ウ)(ア)(イ))//; $4 eq 'イ';
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
