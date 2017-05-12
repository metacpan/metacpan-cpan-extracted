
use warnings;
use strict;
use Test::More tests => 2;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $banner = Text::Banner->new();

$banner->set('10305');
$banner->fill('#');
$actual = $banner->get();

$expected = <<'EOF';
   #      ###    #####    ###   ####### 
  ##     #   #  #     #  #   #  #       
 # #    #     #       # #     # #       
   #    #     #  #####  #     # ######  
   #    #     #       # #     #       # 
   #     #   #  #     #  #   #  #     # 
 #####    ###    #####    ###    #####  
     
EOF

is($actual, $expected, 'string zero set before fill');


__END__


Corner case: an input string consisting of zeroes
where fill is called after set.

