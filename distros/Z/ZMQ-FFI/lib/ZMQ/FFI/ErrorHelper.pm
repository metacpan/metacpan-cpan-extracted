package ZMQ::FFI::ErrorHelper;
$ZMQ::FFI::ErrorHelper::VERSION = '1.19';
use Carp;
use FFI::Platypus;
use ZMQ::FFI::Util qw(zmq_version);

use Moo::Role;

has die_on_error => (
    is      => 'rw',
    default => 1,
);

has last_errno => (
    is      => 'rw',
    lazy    => 1,
    default => 0,
);

sub last_strerror {
    my ($self) = @_;

    my $strerr;
    {
        no strict q/refs/;
        my $class = ref $self;
        $strerr   = &{"$class\::zmq_strerror"}($self->last_errno);
    }

    return $strerr;
}

sub has_error {
    return $_[0]->last_errno;
}

sub check_error {
    my ($self, $func, $rc) = @_;

    $self->{last_errno} = 0;

    my $errno;
    {
        no strict q/refs/;
        my $class = ref $self;
        $errno    = &{"$class\::zmq_errno"}();
    }

    if ( $rc == -1 ) {
        $self->{last_errno} = $errno;

        if ($self->die_on_error) {
            $self->fatal($func)
        }
    }
}

sub check_null {
    my ($self, $func, $obj) = @_;

    $self->{last_errno} = 0;

    my $errno;
    {
        no strict q/refs/;
        my $class = ref $self;
        $errno    = &{"$class\::zmq_errno"}();
    }

    unless ($obj) {
        $self->{last_errno} = $errno;

        if ($self->die_on_error) {
            $self->fatal($func)
        }
    }
}

sub fatal {
    my ($self, $func) = @_;

    my $strerr = $self->last_strerror;
    confess "$func: $strerr";
}

sub bad_version {
    my ($self, $verstr, $msg, $use_die) = @_;

    if ($use_die) {
        die   "$msg\n"
            . "your version: $verstr";
    }
    else {
        croak   "$msg\n"
              . "your version: $verstr";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::ErrorHelper

=head1 VERSION

version 1.19

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
