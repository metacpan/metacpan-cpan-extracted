package Test::Mock::LWP::Conditional::Stubs;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    return bless +{ count => 0, stubs => [] }, $class;
}

sub is_http_res {
    my ($self, $res) = @_;
    return blessed($res) && $res->isa('HTTP::Response');
}

sub is_stub {
    my ($self, $stub) = @_;
    return $self->is_http_res($stub) || ref($stub) eq 'CODE';
}

sub add {
    my ($self, $stub) = @_;
    push @{$self->{stubs}}, $stub if $self->is_stub($stub);
}

sub execute {
    my ($self, $req) = @_;

    my $i = $self->{count}++;
    my $stub = $self->{stubs}->[$i] || $self->{stubs}->[-1] || return;

    if ($self->is_http_res($stub)) {
        return $stub;
    }
    elsif (ref($stub) eq 'CODE') {
        return $stub->($req);
    }
}

1;
