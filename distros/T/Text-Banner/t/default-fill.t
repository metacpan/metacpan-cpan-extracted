
use warnings;
use strict;
use Test::More tests => 2;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $banner = Text::Banner->new();
$banner->set('1030');
$actual = $banner->get();

$expected = <<'EOF';
   1      000    33333    000   
  11     0   0  3     3  0   0  
 1 1    0     0       3 0     0 
   1    0     0  33333  0     0 
   1    0     0       3 0     0 
   1     0   0  3     3  0   0  
 11111    000    33333    000   
    
EOF

is($actual, $expected, 'default fill');

__END__

Make sure RT-85381 bugs have been fixed.

Call 'get' using the default value of 'fill'.  There was a bug where the
returned output was a 7x7 block of '1's and '0's for each character of
the 'set' input string.  There was another bug which prevented the the 0's
from appearing in the output when the 'set' input string contained
multiple 0's.

