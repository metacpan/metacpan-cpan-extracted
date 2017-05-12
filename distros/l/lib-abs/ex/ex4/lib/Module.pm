package #
        Module;

use strict;
use lib::abs;

sub something {
	my $data = lib::abs::path('../data'); # returns absolute path to data directory
	my $keep = do { open my $f, '<', "$data/.keep"; local $/; <$f> };
	# ...
}

1;
