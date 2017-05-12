
use warnings;
use strict;
use Test::More tests => 8;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $actual;
my $expected;

my $banner = Text::Banner->new();

$banner->size(1);
$banner->set('aBc');
$banner->fill('.');
$banner->rotate('v');
$actual = $banner->get();

$expected = <<'EOF';
       
....   
  . .  
  .  . 
  .  . 
  . .  
....   
.......
.  .  .
.  .  .
.  .  .
.  .  .
.  .  .
 .. .. 
       
 ....  
.    . 
.    . 
.    . 
.    . 
 .  .  
EOF

is($actual, $expected, 'vert1');


$banner->rotate('h');
$banner->fill('|');
$banner->size(1);
$banner->set('1_ H');
$actual = $banner->get();

$expected = <<'EOF';
   |                    |     | 
  ||                    |     | 
 | |                    |     | 
   |                    ||||||| 
   |                    |     | 
   |                    |     | 
 |||||  |||||||         |     | 
    
EOF

is($actual, $expected, 'hor1');


$banner->set('ooo');
$actual = $banner->get();

$expected = <<'EOF';
                        
  ||||    ||||    ||||  
 |    |  |    |  |    | 
 |    |  |    |  |    | 
 |    |  |    |  |    | 
 |    |  |    |  |    | 
  ||||    ||||    ||||  
   
EOF

is($actual, $expected, 'hor1o');


$banner->rotate('h');
$banner->fill(9);
$banner->size(1);
$banner->set('!@#$');
$actual = $banner->get();

$expected = <<'EOF';
  999    99999    9 9    99999  
  999   9     9   9 9   9  9  9 
  999   9 999 9 9999999 9  9    
   9    9 999 9   9 9    99999  
        9 9999  9999999    9  9 
  999   9         9 9   9  9  9 
  999    99999    9 9    99999  
    
EOF

is($actual, $expected, 'punc 9');


$banner->size(2);
$banner->fill('+');
$banner->set('foo');
$actual = $banner->get();

$expected = <<'EOF';
                                                
                                                
  ++++++++++++      ++++++++        ++++++++    
  ++++++++++++      ++++++++        ++++++++    
  ++              ++        ++    ++        ++  
  ++              ++        ++    ++        ++  
  ++++++++++      ++        ++    ++        ++  
  ++++++++++      ++        ++    ++        ++  
  ++              ++        ++    ++        ++  
  ++              ++        ++    ++        ++  
  ++              ++        ++    ++        ++  
  ++              ++        ++    ++        ++  
  ++                ++++++++        ++++++++    
  ++                ++++++++        ++++++++    
      
      
EOF

is($actual, $expected, 'size2');


$banner->set('MYtext');
$banner->size(1);
$banner->fill('/');
$actual = $banner->get();

$expected = <<'EOF';
/     / /     /                                 
//   //  /   /    /////  //////  /    /   ///// 
/ / / /   / /       /    /        /  /      /   
/  /  /    /        /    /////     //       /   
/     /    /        /    /         //       /   
/     /    /        /    /        /  /      /   
/     /    /        /    //////  /    /     /   
      
EOF

is($actual, $expected, 'size1');


$banner->set('ff');
$banner->size(2);
$banner->fill('w');
$banner->rotate('v');
$actual = $banner->get();

$expected = <<'EOF';
              
              
wwwwwwwwwwww  
wwwwwwwwwwww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
          ww  
          ww  
              
              
wwwwwwwwwwww  
wwwwwwwwwwww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
      ww  ww  
          ww  
          ww  
EOF

is($actual, $expected, 'size2 vert');


# The following are unspecified by the POD
# but are here soley for coverage:
$banner->size(0);
$banner->size(6);
$banner->rotate('d');
$banner->set();
$banner->fill(chr 31);
my $b2 = $banner->new();
{
    # Suppress warnings from Text::Banner
    local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /uninitialized|blessing/};
    Text::Banner::new();
}

