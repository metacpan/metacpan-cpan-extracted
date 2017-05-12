use strict;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use JSON::Syck;
use Test::More tests => 1;

my $data = JSON::Syck::Load('{"i":-2}');

is $data->{i}, -2;
