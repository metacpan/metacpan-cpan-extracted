use 5.008008;
use strict;
use warnings;

package portable::loader::JSON;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use portable::lib;

our $decoder;

sub load {
	my $me = shift;
	my ($collection) = @_;
	my $filename = portable::lib->search_inc("$collection.portable.json");
	if ($filename) {
		require JSON::Eval;
		$decoder ||= JSON::Eval->new;
		my $jsontext = do {
			open my $fh, '<', $filename
				or die "Could not open $filename: $!";
			local $/;
			<$fh>;
		};
		return ($filename => $decoder->decode($jsontext));
	}
	return;
}

1;

