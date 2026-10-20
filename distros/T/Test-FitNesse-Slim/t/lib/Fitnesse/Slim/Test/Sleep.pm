package Fitnesse::Slim::Test::Sleep;

use strict;
use warnings;
use Time::HiRes qw(sleep);

sub new {
    my ($class, $milliseconds) = @_;
    my $self = bless { timer => 0 }, $class;
    _sleep_milliseconds($milliseconds) if defined $milliseconds;
    return $self;
}

sub set_timer {
    my ($self, $milliseconds) = @_;
    $self->{timer} = $milliseconds;
    return;
}

sub do_sleep {
    my ($self) = @_;
    _sleep_milliseconds($self->{timer});
    return "WakeUp $self->{timer}";
}

sub _sleep_milliseconds {
    my ($milliseconds) = @_;
    die "java.lang.IllegalArgumentException: timeout value is negative\n"
        if $milliseconds < 0;
    sleep($milliseconds / 1000);
    return;
}

1;
