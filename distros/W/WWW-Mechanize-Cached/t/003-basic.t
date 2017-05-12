use strict;
use warnings FATAL => 'all';

use Test::More;

use WWW::Mechanize::Cached;

my $class  = 'WWW::Mechanize::Cached';
my $cacher = $class->new;
isa_ok( $cacher => $class );

done_testing();
