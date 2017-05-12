package Test::Mock::Mango::DB;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.03';

use Test::Mock::Mango::Collection;

sub new {
	my $class = shift;

	bless {
		name => shift
	}, $class;
}
sub collection { Test::Mock::Mango::Collection->new(shift,shift) }

# ------------------------------------------------------------------------------

# Just return undef
#
sub command {
	my ($self, $command) = (shift,shift);
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $err = undef;

	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}	

	return $cb->($self, $err, undef) if $cb; # Non blocking
	return undef;                            # Blocking
}

1;

=encoding utf8

=head1 NAME

Test::Mock::Mango::DB - fake Mango::DB

=head1 DESCRIPTION

Simulated mango db for unit testing as part of L<Test::Mock::Mango>.

=cut
