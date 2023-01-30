#!perl
package Tie_Subset_Testlib;
use warnings;
use strict;
use Carp;

=head1 Synopsis

Test support library for the Perl modules L<Tie::Subset::Array> and L<Tie::Subset::Hash>.

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

BEGIN {
	# "parent" pragma wasn't core until 5.10.1, so just do it ourselves instead of using "base".
	require Exporter;
	our @ISA = qw/ Exporter /;  ## no critic (ProhibitExplicitISA)
}
our @EXPORT = qw/ $AUTHOR_TESTS warns exception /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{TIE_SUBSET_AUTHOR_TESTS};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}

sub exception (&) {  ## no critic (ProhibitSubroutinePrototypes)
	return eval { shift->(); 1 } ? undef : ($@ || confess "\$@ was false");
}

sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return wantarray ? @warns : scalar @warns;
}

1;
