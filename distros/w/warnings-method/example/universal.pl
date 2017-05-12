#!perl -w
use strict;
use warnings::method;
use UNIVERSAL qw(can isa);

print '[] isa ARRAY: ', isa([], 'ARRAY'), "\n";
print 'strict can &import: ', can('strict', 'import'), "\n";
