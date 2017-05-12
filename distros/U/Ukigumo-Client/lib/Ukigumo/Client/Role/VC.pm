use strict;
use warnings;
use utf8;

package Ukigumo::Client::Role::VC;
use Mouse::Role;

has branch => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has repository => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has description => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		join(' ', $self->repository, $self->branch);
	}
);

has skip_if_unmodified => (
    is  => 'ro',
    isa => 'Bool',
    default => undef,
);

requires qw(
	get_revision
	update
    get_log
    default_branch
);

1;

