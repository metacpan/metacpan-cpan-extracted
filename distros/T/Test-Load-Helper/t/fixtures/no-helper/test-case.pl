
use v5.14;
use strict;

say q (load helper);

eval {
	use Test::Load::Helper;
	say q (loaded);
} // do {;
	say q (not loaded: ), $@;
};

1;
