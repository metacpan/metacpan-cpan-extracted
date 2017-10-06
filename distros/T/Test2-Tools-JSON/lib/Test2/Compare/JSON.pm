package Test2::Compare::JSON;
use strict;
use warnings;

use base 'Test2::Compare::Base';

use Carp qw/croak/;

use Test2::Util::HashBase qw/inref json/;

sub init {
    my $self = shift;

    croak "'inref' must be a reference" unless ref $self->{+INREF};

    $self->SUPER::init();
}

sub operator { 'JSON' }

sub name { '' . $_[0]->{+INREF} }

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $exists;

    eval {
        $self->{+JSON}->decode($got);
    };

    return $@ ? 0 : 1;
}

sub deltas {
    my $self = shift;
    my %params = @_;
    my ($got, $convert, $seen) = @params{qw/got convert seen/};

    my $check = $convert->($self->{+INREF});

    my $delta = $check->run(
        id      => [META => 'JSON'],
        got     => $self->{+JSON}->decode($got),
        exists  => 1,
        convert => $convert,
        seen    => {},
    );
    return unless $delta;
    return $delta;
}

1;
