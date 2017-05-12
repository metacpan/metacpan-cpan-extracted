
package threads::tbb::refcounter;

use Carp;
our $VERSION = '0.01';

sub import {
    my $package = shift;

    my @package;
    for my $arg ( @_ ) {
	if ( $arg =~ m{^\d+(\.\d+.*)?$} ) {
	    if ( $arg gt $VERSION ) {
		croak "version $arg requested - this is "
		    .__PACKAGE__." $VERSION";
	    }
	}
	push @package, $arg;
    }
    for my $pkg ( @package ) {
	$package->setup($pkg);
    }
}

sub setup {
    no strict 'refs';
    no warnings 'redefine';
    shift if UNIVERSAL::isa($_[0], __PACKAGE__);
    my $target = shift;
    my $destroy = "${target}::DESTROY";
    my $destroy_rc = "${target}::_DESTROY_tbbrc";
    my $refcnt_inc = "${target}::CLONE_REFCNT_inc";
    my $clone_skip = "${target}::CLONE_SKIP";

    # multiple modules can call this, don't re-setup.
    return if defined &$destroy_rc;

    # find the DESTROY method and wrap it.
    croak "no DESTROY defined in $target; did you load it, and are you sure it's a real XS class?"
	unless defined &$destroy;

    *$destroy_rc = \&$destroy;
    *$destroy = \&pvmg_rc_dec;
    *$refcnt_inc = \&pvmg_rc_inc;
    *$clone_skip = \&clone_skip;
}

sub clone_skip { 0 }

1;
