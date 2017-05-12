use warnings;
use strict;

use Test::More tests => 6;

BEGIN {
	use_ok "Time::OlsonTZ::Data",
		qw(olson_version olson_code_version olson_data_version);
}

like $_, qr/\A[0-9]{4}[a-z]\z/
	foreach olson_version(), olson_code_version(), olson_data_version();
ok olson_code_version() le olson_version();
ok olson_data_version() le olson_version();

1;
