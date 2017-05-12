use rig -file => 'xt/perlrig';
use rig common; # same as use Data::Dumper + use List::Utils

# now use it
print first { $_ > 10 } (1,9,23,12); # from List::Utils;
$foo = { aa=>11 };
print Dumper $foo;  # from Data::Dumper

