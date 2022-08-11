#!perl
use strict;
use warnings;
use feature 'lexical_subs';

use Test::More tests => 1;

eval "
  # This doesn't die
	my sub fatal { die 7 };

	use Voo do {
		# This is BEGIN time, and dies
		my sub fatal { die 42 };
		\&fatal
	};

	# This doesn't die
	die 7;
";


like( $@, qr/42/, "called at begin time" );
