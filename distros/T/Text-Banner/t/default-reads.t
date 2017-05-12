
use warnings;
use strict;
use Test::More tests => 4;

# Check if module loads ok
BEGIN { use_ok('Text::Banner', qw()) }

my $banner = Text::Banner->new();

is($banner->size()   , 1     , 'default size');  
is($banner->rotate() , 'H'   , 'default rotate');
is($banner->fill()   , undef , 'default fill');  

