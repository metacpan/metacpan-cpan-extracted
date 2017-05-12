
use warnings;
use strict;
use Test::More tests => 3;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

# Check module version number
BEGIN { use_ok('Text::Banner', '2.01') }

my $actual;
my $expected;

my $banner = Text::Banner->new();
$banner->set('#');
$banner->fill('#');
$actual = $banner->get();

$expected = <<'EOF';
  # #   
  # #   
####### 
  # #   
####### 
  # #   
  # #   
 
EOF

is($actual, $expected, 'fill');

__END__

Make sure a standard version variable is used.
The original module did not.

