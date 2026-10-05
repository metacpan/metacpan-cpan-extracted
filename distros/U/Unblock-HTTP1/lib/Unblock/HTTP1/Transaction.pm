package Unblock::HTTP1::Transaction;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.10';

sub _new {
    my ($class, $owner, $request, %args) = @_;
    my $self = bless {
        owner       => $owner,
        request     => $request,
        response    => undef,
        state       => 'active',
        error       => undef,
        callbacks   => $args{callbacks} || {},
        local_done  => $args{local_done} ? 1 : 0,
        remote_done => $args{remote_done} ? 1 : 0,
        send_plan   => $args{send_plan},
        blocked     => 0,
    }, $class;
    weaken($self->{owner});
    return $self;
}

sub request { $_[0]{request} }
sub response { $_[0]{response} }
sub state { $_[0]{state} }
sub error { $_[0]{error} }
sub is_complete { $_[0]{state} eq 'complete' ? 1 : 0 }
sub is_cancelled { $_[0]{state} eq 'cancelled' ? 1 : 0 }
sub is_error { $_[0]{state} eq 'error' ? 1 : 0 }
sub is_terminal { $_[0]{state} ne 'active' ? 1 : 0 }

sub write {
    my ($self, $bytes) = @_;
    croak 'write(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'write(): HTTP/1 connection is gone';
    return $owner->_transaction_write($self, $bytes, 0);
}

sub end {
    my ($self, $bytes) = @_;
    croak 'end(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'end(): HTTP/1 connection is gone';
    return $owner->_transaction_write($self, defined($bytes) ? $bytes : '', 1);
}

sub respond {
    my ($self, $response, %option) = @_;
    croak 'respond(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'respond(): HTTP/1 connection is gone';
    return $owner->_transaction_respond($self, $response, %option);
}

sub send_informational {
    my ($self, $response) = @_;
    croak 'send_informational(): Transaction is terminal' if $self->is_terminal;
    my $owner = $self->{owner} or croak 'send_informational(): HTTP/1 connection is gone';
    return $owner->_transaction_informational($self, $response);
}

sub cancel {
    my ($self) = @_;
    return $self if $self->is_terminal;
    my $owner = $self->{owner};
    $owner->_transaction_cancel($self) if $owner;
    return $self;
}

sub _set_response { $_[0]{response} = $_[1]; return $_[0] }
sub _mark_local_done { $_[0]{local_done} = 1; return }
sub _mark_remote_done { $_[0]{remote_done} = 1; return }
sub _mark_complete { $_[0]{state} = 'complete'; return }
sub _mark_cancelled { $_[0]{state} = 'cancelled'; return }
sub _fail { $_[0]{state} = 'error'; $_[0]{error} = $_[1]; return }

sub _invoke {
    my ($self, $name, @args) = @_;
    my $cb = $self->{callbacks}{$name} or return 1;
    my $ok = eval { $cb->($self, @args); 1 };
    return $ok ? 1 : "$@";
}

1;

__END__

=head1 NAME

Unblock::HTTP1::Transaction - One HTTP/1 request and response exchange

=head1 DESCRIPTION

A Transaction connects one Uniform request with its response and any
incremental body production. It owns no socket and performs no waiting.

For a client streaming request body, C<write()> and C<end()> produce body
bytes. For a server streaming response body, they do the same after
C<respond(..., stream_body =E<gt> 1)>.

A server Transaction can send an informational response with
C<send_informational()> before the final C<respond()>.

=head1 STATE

The common Unblock HTTP transaction lifecycle vocabulary is:

    state
    error
    is_complete
    is_cancelled
    is_error
    is_terminal

C<error()> is undefined unless the Transaction failed. Cancellation is a
separate terminal state and does not manufacture an error string.

=cut
