use 5.008008;
use strict;
use warnings;

package portable::alias;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use portable::loader ();
use B ();

sub import {
	my $me = shift;
	my $caller = caller;
	my ($collection, $as) = @_;
	$as ||= $collection;
	
	my $pkg = portable::loader->load($collection);
	my $qpkg = B::perlstring($pkg);
	
	local $@;
	eval qq{
		sub $caller\::$as {
			return $qpkg unless \@_;
			$qpkg\->type_library->get_type(\@_);
		}
		1;
	} or die "Eww: $@";
}


1;
