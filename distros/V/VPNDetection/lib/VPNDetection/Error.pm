package VPNDetection::Error;

use strict;
use warnings;

use Mojo::Headers;
use Scalar::Util ();
use Time::Local ();

use overload
    '""' => sub { $_[0]->{message} },
    'bool' => sub { 1 },
    fallback => 1;

our $VERSION = '3.9.0';

my %RETRYABLE = (rate_limited => 1, server_error => 1, network => 1);

my %MONTH;
@MONTH{qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)} = 0 .. 11;
my $DAY = join '|', qw(Mon Tue Wed Thu Fri Sat Sun);
my $WEEKDAY = join '|', qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);
my $MON = join '|', keys %MONTH;
my $TIME = '([0-9]{2}):([0-9]{2}):([0-9]{2})';

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

# A per-entry failure inside a successful batch: the status the single lookup
# would have answered, and its message, with no headers at all - so a 429 here
# is a spent allowance, which is the only kind the API puts in an entry.
sub from_entry {
    my ($class, $status, $message) = @_;
    return $class->from_response($status, Mojo::Headers->new, { error => $message });
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

# An empty field says nothing, so it gives way to the other envelope, then to
# the status, rather than reading as a message of nothing at all (3.8.0 answered
# `{"error": "", "rc": "NOT_LICENSED"}` with an empty message).
sub _message {
    my ($body) = @_;
    return undef unless ref $body eq 'HASH';
    for my $key (qw(error rc)) {
        return $body->{$key} if defined $body->{$key} && !ref $body->{$key} && length $body->{$key};
    }
    return undef;
}

# Seconds as digits, or an HTTP date, and nothing else, so a value that is
# neither is no Retry-After at all and the 429 a spent quota. RFC 9110 allows
# exactly three date forms, all in GMT. Through 3.8.0 a fraction was read as
# seconds, and Mojo::Date read ISO 8601, any zone as GMT and a day or month it
# does not know as Monday or January, each of which held a call on a date the
# server never sent.
sub _retry_after {
    my ($value) = @_;
    return undef unless defined $value;
    $value =~ s/^\s+|\s+\z//g;
    return $value + 0 if $value =~ /\A[0-9]+\z/;

    my $epoch = _http_date($value);
    return undef unless defined $epoch;
    my $seconds = $epoch - time;
    return $seconds > 0 ? $seconds : 0;
}

# IMF-fixdate (Sun, 06 Nov 1994 08:49:37 GMT), RFC 850 (Sunday, 06-Nov-94
# 08:49:37 GMT) and asctime (Sun Nov  6 08:49:37 1994), as epoch seconds.
sub _http_date {
    my ($value) = @_;
    my ($day, $month, $year, $hour, $minute, $second);
    if ($value =~ /\A(?:$DAY), ([0-9]{2}) ($MON) ([0-9]{4}) $TIME GMT\z/) {
        ($day, $month, $year, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
    }
    elsif ($value =~ /\A(?:$WEEKDAY), ([0-9]{2})-($MON)-([0-9]{2}) $TIME GMT\z/) {
        ($day, $month, $year, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
        # A two-digit year more than 50 years ahead is the most recent past one
        # with those digits, as RFC 9110 has a recipient read it.
        my $now = (gmtime)[5] + 1900;
        $year += $now - $now % 100;
        $year -= 100 if $year > $now + 50;
    }
    elsif ($value =~ /\A(?:$DAY) ($MON) ( [1-9]|[0-9]{2}) $TIME ([0-9]{4})\z/) {
        ($month, $day, $hour, $minute, $second, $year) = ($1, $2, $3, $4, $5, $6);
    }
    else {
        return undef;
    }
    # Already past, and Time::Local reads a year below 1000 as one after 1900.
    return 0 if $year < 1970;
    # Time::Local refuses a day, hour or minute out of range, which is no date.
    my $epoch = eval { Time::Local::timegm($second, $minute, $hour, $day + 0, $MONTH{$month}, $year) };
    return $epoch;
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
