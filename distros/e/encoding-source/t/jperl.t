#!perl
# This script is written in euc-jp

use strict;
use warnings;
use Test::More tests => 10;

my $Enamae = "\xbe\xae\xbb\xf4\x20\xc3\xc6"; # euc-jp, with \x escapes
use encoding::source "euc-jp";

my $Namae  = "¾®»ô ÃÆ";   # in Japanese, in euc-jp
my $Name   = "Dan Kogai"; # in English
# euc-jp in \x format but after the pragma.  But this one will be converted!
my $Ynamae = "\xbe\xae\xbb\xf4\x20\xc3\xc6"; 

my $str = $Namae; $str =~ s/¾®»ô ÃÆ/Dan Kogai/;
is($str, $Name, q{regex});
$str = $Namae; $str =~ s/$Namae/Dan Kogai/;
is($str, $Name, q{regex - with variable});
is(length($Namae), 4, q{utf8:length});
{
    use bytes;
    # converted to UTF-8 so 3*3+1
    is(length($Namae),   10, q{bytes:length});
    is(length($Enamae),   7, q{euc:length}); # 2*3+1
    is  ( $Namae, $Ynamae,   q{literal conversions});
    isnt($Enamae, $Ynamae,   q{before and after}); 
    is($Enamae, Encode::encode('euc-jp', $Namae)); 
}
# let's test the scope as well.  Must be in utf8 realm
is(length($Namae), 4, q{utf8:length});

use bytes;
is(length($Namae), 10, 'length under use bytes');
