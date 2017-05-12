use strict;
use warnings;
use utf8;

package Ukigumo::Client::VC::Callback;
use Mouse;
use Cwd;

with 'Ukigumo::Client::Role::VC';

has 'revision_cb' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { 'unknown' } },
);

has 'update_cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has 'get_log_cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default => sub { sub { '-' } },
);

has 'default_branch_cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub { 'master' } },
);

sub default_branch {
    my $self = shift;
    $self->default_branch_cb->(@_);
}

sub get_revision {
	my $self = shift;
	$self->revision_cb->(@_);
}

sub update {
    my $self = shift;
	$self->update_cb->(@_);
}

sub get_log {
    my $self = shift;
    $self->get_log_cb->(@_)
}

1;

