use 5.008008;
use strict;
use warnings;

package portable::loader::Perl;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use portable::lib;
use portable::loader;

sub init {
	my $me = shift;
	my ($loader) = @_;
	$loader->register_extension('portable.pl');
	return;
}

sub parse {
	my $me = shift;
	my ($filename) = @_;
	my $rv = do($filename) or die "Error loading $filename";
	return ($filename => $rv);
}

1;

