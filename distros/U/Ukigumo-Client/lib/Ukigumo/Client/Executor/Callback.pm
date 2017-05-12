use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Callback;
use Mouse;

has run_cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub run {
	my $self = shift;
	$self->run_cb->(@_);
}

no Mouse;__PACKAGE__->meta->make_immutable;
