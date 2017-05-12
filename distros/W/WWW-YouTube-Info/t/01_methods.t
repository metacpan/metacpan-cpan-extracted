use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'WWW::YouTube::Info' ) };

my @methods = qw/
  get_info
  new
/;
can_ok( 'WWW::YouTube::Info', $_ ) for @methods;

done_testing();

