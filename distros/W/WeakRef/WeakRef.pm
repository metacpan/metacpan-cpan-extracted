package WeakRef;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	weaken isweak
);
$VERSION = '0.01';

bootstrap WeakRef $VERSION;

# Preloaded methods go here.

1;

=head1 NAME

WeakRef -- an API to the Perl weak references

=head1 SYNOPSIS

	use WeakRef;

	for($i=0; $i<100000; $i++) {
		my $x = {};
		my $y = {};
		$x->{Y} = $y;
		$y->{X} = $y;
		weaken($x->{Y});
	} # no memory leak

	if(isweak($ref)) {
	}

=head1 DESCRIPTION

A patch to Perl 5.005_55 by the author implements a core API for weak
references. This module is a Perl-level interface to that API, allowing
weak references to be created in Perl.

A weak reference is just like an ordinary Perl reference except that
it isn't included in the reference count of the thing referred to.
This means that once all references to a particular piece of data are
weak, the piece of data is freed and all the weak references are set
to undef. This is particularly useful for implementing circular
data structures without memory leaks or caches of objects.

The command

	use WeakRef;

exports two symbols to the user's namespace by default: C<weaken> and
C<isweak>. C<weaken> takes a single argument, the reference to be weakened,
and returns the same value.
The idiom

	weaken($this->{Thing}->{Parent} = $this);

is useful.

The C<isweak> command takes a single parameter and returns true if
the parameter is a weak reference, undef otherwise.

=head1 BUGS

None known.

=head1 AUTHOR

Tuomas J. Lukka		lukka@iki.fi

Copyright (c) 1999 Tuomas J. Lukka. All rights reserved. This
program is free software; you can redistribute it and/or modify it under the
same terms as perl itself.

=head1 BLATANT PLUG

This module and the patch to the core Perl were written in connection 
with the APress book `Tuomas J. Lukka's Definitive Guide to Object-Oriented
Programming in Perl', to avoid explaining why certain things would have
to be done in cumbersome ways.

=cut
