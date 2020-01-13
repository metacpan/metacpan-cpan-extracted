use 5.008008;
use strict;
use warnings;

package portable::loader::JSON;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use portable::lib;
use portable::loader;

sub init {
	my $me = shift;
	my ($loader) = @_;
	$loader->register_extension('portable.json');
	return;
}

our $decoder;

sub parse {
	my $me = shift;
	my ($filename) = @_;
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

1;

