
use warnings;
use strict;
use Test::More tests => 3;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $b1 = Text::Banner->new();
$b1->set('a');
$b1->fill('#');
$actual = $b1->get();

$expected = <<'EOF';
        
   ##   
  #  #  
 #    # 
 ###### 
 #    # 
 #    # 
 
EOF

is($actual, $expected, 'new1');

my $b2 = Text::Banner->new();
$b2->set('b');
$b2->fill('#');
$actual = $b2->get();

$expected = <<'EOF';
        
 #####  
 #    # 
 #####  
 #    # 
 #    # 
 #####  
 
EOF

is($actual, $expected, 'new2');

__END__

Make sure RT-39431 bug has been fixed.

Call 'new' multiple times.  There was a bug where the second call to 'get'
returned blank output.

