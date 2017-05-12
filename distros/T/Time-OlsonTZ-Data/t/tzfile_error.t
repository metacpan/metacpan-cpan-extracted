use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Time::OlsonTZ::Data", qw(olson_tzfile); }

foreach(qw(
	America/Does_Not_Exist
	Does_Not_Exist/New_York
	Does_Not_Exist
)) {
	eval { olson_tzfile($_) };
	like $@, qr/\Ano such timezone/;
}

1;
