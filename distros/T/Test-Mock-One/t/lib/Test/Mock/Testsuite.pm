package Test::Mock::Testsuite;
use strict;
use warnings;

sub new {
    my $self = shift;
    my %args = @_;

    bless(\%args, ref $self || 'Test::Mock::Testsuite');
}

sub bar {
    my $self = shift;

    $self->{mock}->foo(@_);
}

1;
