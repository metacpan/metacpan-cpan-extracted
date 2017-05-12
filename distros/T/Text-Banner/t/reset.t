
use warnings;
use strict;
use Test::More tests => 4;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $banner = Text::Banner->new();

$banner->fill('*');
$banner->set('Yes');
$actual = $banner->get();

$expected = <<'EOF';
*     *                 
 *   *   ******   ****  
  * *    *       *      
   *     *****    ****  
   *     *            * 
   *     *       *    * 
   *     ******   ****  
   
EOF

is($actual, $expected, 'fill star');


$banner->fill('reset');
$actual = $banner->get();

$expected = <<'EOF';
Y     Y                 
 Y   Y   eeeeee   ssss  
  Y Y    e       s      
   Y     eeeee    ssss  
   Y     e            s 
   Y     e       s    s 
   Y     eeeeee   ssss  
   
EOF

is($actual, $expected, 'fill reset');


$banner->fill(0);
$actual = $banner->get();

$expected = <<'EOF';
0     0                 
 0   0   000000   0000  
  0 0    0       0      
   0     00000    0000  
   0     0            0 
   0     0       0    0 
   0     000000   0000  
   
EOF

is($actual, $expected, 'fill zero');


