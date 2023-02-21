use strict;
use warnings;
use Util::H2O::More qw/d2o o2d/;

require Data::Dumper;
my $foo = [ qw/1 2 3 4 5/, [qw/ 6 7 8 9 /], { foo => 1, code => sub { 1 } }, sub { 2 }, ];

d2o $foo;

print Data::Dumper::Dumper($foo);

my $foo2 = o2d $foo;

print Data::Dumper::Dumper($foo2);

