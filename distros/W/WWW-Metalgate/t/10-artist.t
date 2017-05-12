use strict;
use warnings;

use Test::More tests => 2;

use_ok("WWW::Metalgate::Artist");

my $artist = WWW::Metalgate::Artist->new( name => "Angra" );
ok($artist, "got instance");
