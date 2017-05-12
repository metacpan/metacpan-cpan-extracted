BEGIN{
	$|=1;
	my $t = 4;
	$] < 5.006 ? do{ print "1..$t\n"; require 't/5005-lib.pm'} :
	eval "use Test::More tests => $t; use Test::Differences"; }
use Text::FIGlet;

#0 implicit $ENV test
$ENV{FIGLIB} = 'share';
my $font = Text::FIGlet->new();


#Avoid "chicken & egg" of verifying -m0 before core by testing single chars
#1
my $txt1 = <<'ASCII';
 /\/|
|/\/ 
     
     
     
     
ASCII
eq_or_diff scalar $font->figify(-A=>"~"), $txt1, "ASCII ~";


#2
my $txt2 = <<'ANSI';
/\___/\
\  _  /
| (_) |
/ ___ \
\/   \/
       
ANSI
eq_or_diff scalar $font->figify(-A=>chr(164)), $txt2, "ANSI [currency]";


#3
$font = Text::FIGlet->new(-D=>1, -m=>0);
my $txt3 = <<'DEUTCSH';
  ___ 
 / _ \
| |/ /
| |\ \
| ||_/
|_|   
DEUTCSH
eq_or_diff scalar $font->figify(-A=>'~'), $txt3, "DEUTSCH s-z";

#4
my $txt4 = <<'NEWLINE';
 __  __ 
|  \/  |
| |\/| |
| |  | |
|_|  |_|
        
       
 _   _ 
| | | |
| |_| |
 \__,_|
       
NEWLINE
eq_or_diff scalar $font->figify(-A=>"M\nu"), $txt4, "-A=>\\n";
