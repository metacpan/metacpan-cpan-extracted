#!/usr/bin/perl
use strict;
use warnings;

use vars::global create => qw( $foo @bar %baz );

$foo = "I'm foo";
@bar = qw( I could be bar );
$baz{taz} = 'uaz!';


package Else::Where;

use vars::global qw( $foo );
print 'In ', __PACKAGE__, ' $foo is << ', $foo, " >>\n";

eval {
   vars::global->import('@BAR'); 
};
print $@ if $@;
