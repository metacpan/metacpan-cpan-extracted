# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl VideoLAN-LibVLC.t'

#########################

use strict;
use warnings;
use Test::More;
BEGIN { use_ok('VideoLAN::LibVLC', ':constants') || BAIL_OUT };

foreach my $constname (@{ $VideoLAN::LibVLC::EXPORT_TAGS{constants} }) {
	if (eval "my \$a = $constname; 1") {
		ok($constname);
	}
	elsif ($@ =~ /available on this version/) {
		SKIP: { skip "$constname unavailable on this version of libvlc", 1; fail($constname); }
	}
	else {
		fail($constname);
	}
}

done_testing;
