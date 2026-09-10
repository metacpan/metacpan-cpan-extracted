package VPNDetection::Error;

use strict;
use warnings;

use Mojo::Date;
use Scalar::Util ();

use overload
    '""' => sub { $_[0]->{message} },
    'bool' => sub { 1 },
    fallback => 1;

our $VERSION = '1.5.0';

my %RETRYABLE = (rate_limited => 1, server_error => 1, network => 1);

sub new {
    my ($class, %args) = @_;
    return bless {
        kind => $args{kind},
        message => defined $args{message} ? $args{message} : $args{kind},
        status => $args{status},
        retry_after => $args{retry_after},
    }, $class;
}

sub throw {
    my $class = shift;
    die $class->new(@_);
}

# Classifies one failed response. The two APIs behind this host answer with
# different envelopes - the lookup endpoint uses `error`, the database endpoints
# use `rc` - and both are read here so a caller never has to know which was hit.
sub from_response {
    my ($class, $status, $headers, $body) = @_;
    my $message = _message($body);
    $message = "request failed with status $status" unless defined $message;
    my $retry_after = _retry_after($headers->header('Retry-After'));

    # Present means a transient rate limit and retrying works; absent means an
    # allowance is spent. Nothing else in the response separates the two.
    if ($status == 429) {
        return $class->new(
            kind => defined $retry_after ? 'rate_limited' : 'quota_exceeded',
            message => $message, status => $status, retry_after => $retry_after,
        );
    }
    return $class->new(kind => 'bad_request', message => $message, status => $status)
        if $status == 400;
    return $class->new(kind => 'unauthorized', message => $message, status => $status)
        if $status == 401;
    return $class->new(kind => 'forbidden', message => $message, status => $status)
        if $status == 403;
    # Any other 4xx is a CLIENT error. Falling through to the server_error
    # default would make it retryable, so a bad dataset id would be retried
    # twice before failing. Only 5xx and transport failures are worth a retry.
    return $class->new(kind => 'bad_request', message => $message, status => $status)
        if $status < 500;
    return $class->new(kind => 'server_error', message => $message, status => $status);
}

# Anything a promise can reject with becomes one of these. Mojo::UserAgent
# rejects with a plain string when a connection never got far enough to have a
# status, which is exactly the transport failure the retry rule wants.
sub wrap {
    my ($class, $err) = @_;
    return $err if Scalar::Util::blessed($err) && $err->isa(__PACKAGE__);
    my $message = defined $err ? "$err" : 'request failed';
    $message =~ s/\s+\z//;
    return $class->new(kind => 'network', message => $message);
}

sub kind { $_[0]->{kind} }
sub message { $_[0]->{message} }
sub status { $_[0]->{status} }
sub retry_after { $_[0]->{retry_after} }

sub retryable {
    return $RETRYABLE{ $_[0]->{kind} } ? 1 : 0;
}

sub _message {
    my ($body) = @_;
    return undef unless ref $body eq 'HASH';
    for my $key (qw(error rc)) {
        return $body->{$key} if defined $body->{$key} && !ref $body->{$key};
    }
    return undef;
}

sub _retry_after {
    my ($value) = @_;
    return undef unless defined $value;
    $value =~ s/^\s+|\s+\z//g;
    return undef unless length $value;
    return $value + 0 if $value =~ /\A[0-9]+(?:\.[0-9]+)?\z/;

    # The header also permits an HTTP date.
    my $epoch = Mojo::Date->new($value)->epoch;
    return undef unless defined $epoch;
    my $seconds = $epoch - time;
    return $seconds > 0 ? $seconds : 0;
}

1;

__END__

=head1 NAME

VPNDetection::Error - why a request failed

=head1 SYNOPSIS

    my $result = eval { $client->lookup('1.1.1.1') };
    if (my $err = $@) {
        die $err unless ref $err && $err->isa('VPNDetection::Error');
        warn $err->kind, ': ', $err->message;
        warn 'worth retrying' if $err->retryable;
    }

=head1 DESCRIPTION

Every failure raised by this library is one of these objects. It stringifies to
its message, so C<warn $@> and C<die $@> read as they would with an ordinary
string exception.

=head1 METHODS

=head2 kind

One of C<bad_request>, C<unauthorized>, C<forbidden>, C<rate_limited>,
C<quota_exceeded>, C<server_error> or C<network>.

C<rate_limited> and C<quota_exceeded> both arrive as HTTP 429 and are not the
same thing. A rate limit is the API protecting itself, carries C<Retry-After>,
and retrying works. A spent quota carries no such header, and retrying will not
help until the window rolls over or the limit is raised. The header is the only
thing that separates them.

=head2 message

The API's explanation, or a fallback naming the status.

=head2 status

The HTTP status, or C<undef> for a transport failure.

=head2 retry_after

Seconds to wait, when the API said so.

=head2 retryable

Whether retrying this exact request could succeed. True for C<rate_limited>,
C<server_error> and C<network>, false for everything else.

=cut
