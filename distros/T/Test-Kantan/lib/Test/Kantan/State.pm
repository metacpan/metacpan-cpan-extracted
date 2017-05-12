package Test::Kantan::State;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has pass_cnt => (is => 'ro', default => sub { 0 });
has fail_cnt => (is => 'ro', default => sub { 0 });

no Moo;

sub is_passing {
    my $self = shift;
    return $self->fail_cnt == 0;
}

sub passed {
    my ($self) = @_;
    $self->{pass_cnt}++;
}

sub failed {
    my ($self) = @_;
    $self->{fail_cnt}++;
}

1;
