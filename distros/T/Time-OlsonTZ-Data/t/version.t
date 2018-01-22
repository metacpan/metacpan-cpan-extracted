use warnings;
use strict;

use Test::More tests => 4;

BEGIN {
	use_ok "Time::OlsonTZ::Data",
		qw(olson_version olson_code_version olson_data_version);
}

like olson_version(), qr/\A[0-9]{4}[a-z]\z/;
is olson_code_version(), olson_version();
is olson_data_version(), olson_version();

1;
