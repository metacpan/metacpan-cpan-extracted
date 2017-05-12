#!/home/ben/software/install/perl
use warnings;
use strict;
use Unicode::Properties 'uniprops';
print join (',',uniprops('2')), "\n";



