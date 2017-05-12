#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;

######
# let's check our subs/methods.
######

BEGIN {
	use_ok('Test::Software::License');
}

my @subs = qw(
	_check_for_license_file
	_from_metajson_ok
	_from_metayml_ok
	_from_perlmodule_ok
	_from_perlscript_ok
	_guess_license
	_hack_check_license_url
	_hack_guess_license_from_meta
	all_software_license_ok
	import
);

foreach my $subs (@subs) {
	can_ok('Test::Software::License', $subs);
}

done_testing();

__END__

