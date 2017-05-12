use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'WWW::YouTube::Info::Simple' ) };

my @methods = qw/
  get_info
  new
  _url_decode
  _url_encode
  get_conn
  get_keywords
  get_resolution
  get_title
  get_url
/;
can_ok( 'WWW::YouTube::Info::Simple', $_ ) for @methods;

done_testing();

