
use warnings;
use strict;
use Test::More tests => 2;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $banner = Text::Banner->new();

$banner->set('0');
$actual = $banner->get();

$expected = <<'EOF';
  000   
 0   0  
0     0 
0     0 
0     0 
 0   0  
  000   
 
EOF

is($actual, $expected, 'single zero string');


__END__


Corner case: an input string consisting of a single 0
using the default fill pattern.

