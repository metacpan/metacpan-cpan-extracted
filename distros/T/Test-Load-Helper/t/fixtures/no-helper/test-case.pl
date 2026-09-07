
use v5.10;
use strict;
use warnings;

say q (load helper);

eval {
	use Test::Load::Helper;
	say q (loaded);
} // do {;
	say q (not loaded: ), $@;
};

1;
