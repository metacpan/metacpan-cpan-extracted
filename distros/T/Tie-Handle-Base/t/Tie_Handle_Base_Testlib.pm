#!perl
package Tie_Handle_Base_Testlib;
use warnings;
use strict;
use 5.008_001;
use Carp;

=head1 Synopsis

Test support library for the Perl module Tie::Handle::Base.

=head1 Author, Copyright, and License

Copyright (c) 2017-2023 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

BEGIN {
	# "parent" pragma wasn't core until 5.10.1, so just do it ourselves
	# instead of using "base".
	require Exporter;
	our @ISA = qw/ Exporter /;  ## no critic (ProhibitExplicitISA)
}
our @EXPORT = qw/ $AUTHOR_TESTS $TEMPDIR newtempfn slurp warns exception /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{TIE_HANDLE_BASE_AUTHOR_TESTS};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}

use File::Temp qw/tempdir tempfile/;
# always returns a new temporary filename
# newtempfn() - return a nonexistent filename (small chance for a race condition)
# newtempfn("content") - writes that content to the file (file will exist)
# newtempfn("content","layers") - does binmode with those layers then writes the content
our $TEMPDIR = tempdir("TieHandleBaseTests_XXXXXXXXXX", TMPDIR=>1, CLEANUP=>1);
sub newtempfn {
	my ($fh,$fn) = tempfile(DIR=>$TEMPDIR,UNLINK=>1);
	if (@_) {
		my $content = shift;
		if (@_) {
			binmode $fh, shift or croak "binmode $fn: $!";
			@_ and carp "too many args to newtempfn";
		}
		print $fh $content or croak "print $fn: $!";
		close $fh or croak "close $fn: $!";
	}
	else {
		close $fh or croak "close $fn: $!";
		unlink $fn or croak "unlink $fn: $!";
	}
	return $fn;
}

sub slurp {
	my ($fn,$layers) = @_;
	$layers = '' unless defined $layers;
	open my $fh, "<$layers", $fn or croak "open $fn: $!";
	my $x = do { local $/=undef; <$fh> };
	close $fh or croak "close $fn: $!";
	return $x;
}

#use Test::Fatal 'exception';
# We really only use "exception" for really simple cases, so let's
# use this cheapo replacement so we can depend only on core modules!
sub exception (&) {  ## no critic (ProhibitSubroutinePrototypes)
	return eval { shift->(); 1 } ? undef : ($@ || confess "\$@ was false");
}

sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	# Possible To-Do for Later: can we (lexically) disable warning fatality in this block? (for author tests, at least)
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return wantarray ? @warns : scalar @warns;
}

## no critic (ProhibitMultiplePackages, RequireCarping)

{
	package Tie::Handle::Unprintable;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	# we can't mock CORE::print, but we can use a tied handle to cause it to return false
	sub WRITE { return undef }  ## no critic (ProhibitExplicitReturnUndef)
}

1;
