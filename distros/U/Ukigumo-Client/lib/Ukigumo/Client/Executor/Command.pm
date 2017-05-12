use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Command;
use Mouse;
use Mouse::Util::TypeConstraints;
use Ukigumo::Constants;

subtype 'ArrayRefOfStrs', as 'ArrayRef[Str]';
coerce 'ArrayRefOfStrs', from 'Str', via { [$_] };

has command => (
    is       => 'ro',
    isa      => 'ArrayRefOfStrs',
    required => 1,
    coerce   => 1,
);

sub run {
    my ($self, $c) = @_;

    for my $command (@{ $self->command }) {
        return STATUS_FAIL if $c->tee($command) != 0;
    }

    return STATUS_SUCCESS;
}

1;
__END__

=head1 NAME

Ukigumo::Client::Executor::Command - runs command

=head1 DESCRIPTION

This executor runs command.
