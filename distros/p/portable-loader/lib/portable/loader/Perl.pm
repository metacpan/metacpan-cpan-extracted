use 5.008008;
use strict;
use warnings;

package portable::loader::Perl;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use portable::lib;

sub load {
	my $me = shift;
	my ($collection) = @_;
	my $filename = portable::lib->search_inc("$collection.portable.pl");
	if ($filename) {
		my $rv = do($filename) or die "Error loading $filename";
		return ($filename => $rv);
	}
	return;
}

1;

