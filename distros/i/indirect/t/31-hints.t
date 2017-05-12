#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

SKIP: {
 skip 'This fails on perl 5.11.x even without using indirect' => 1
                                              if "$]" >= 5.011 and "$]" < 5.012;
 local %^H = (a => 1);

 require indirect;

 # Force %^H repopulation with an Unicode match
 my $x = "foo";
 utf8::upgrade($x);
 $x =~ /foo/i;

 my $hints = join ',',
              map { $_, defined $^H{$_} ? $^H{$_} : '(undef)' }
               sort keys(%^H);
 is $hints, 'a,1', 'indirect does not vivify entries in %^H';
}
