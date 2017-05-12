use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;                      # last test to print

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set the environment variable OHLOH_KEY to your api key to enable these tests
END_MSG

plan tests => 1;

my $ohloh = WWW::Ohloh::API->new( api_key => $ENV{OHLOH_KEY} );

eval { $ohloh->get_project( 999999 ) };

ok !!$@, "unexisting project causes an exception";
