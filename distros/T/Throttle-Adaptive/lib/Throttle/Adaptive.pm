use strict;
use warnings;
package Throttle::Adaptive;
our $AUTHORITY = 'cpan:TVDW';
$Throttle::Adaptive::VERSION = '0.001';
# ABSTRACT: implementation of the "adaptive throttling" algorithm by Google

use Time::HiRes qw/CLOCK_MONOTONIC/;

sub new {
    my ($class, %args)= @_;
    return bless {
        ratio => $args{ratio} || 2,
        time => $args{time} || 120,

        window => [],
        window_success => 0,
        window_total => 0,
    }, $class;
}

sub _process_window {
    my ($self)= @_;
    my $now= Time::HiRes::clock_gettime(CLOCK_MONOTONIC);
    while (@{$self->{window}} && $self->{window}[0][0] < $now) {
        my $entry= shift @{$self->{window}};
        $self->{window_total}--;
        $self->{window_success}-- if $entry->[1];
    }
    return;
}

sub should_fail {
    my ($self)= @_;
    $self->_process_window;

    my $fail= ( rand() < (($self->{window_total} - ($self->{ratio} * $self->{window_success})) / ($self->{window_total} + 1)) );
    $self->count(1) if $fail;
    return $fail;
}

sub count {
    my ($self, $error)= @_;
    my $success= !$error;

    $self->{window_total}++;
    push @{$self->{window}}, [ Time::HiRes::clock_gettime(CLOCK_MONOTONIC)+$self->{time}, $success ];
    $self->{window_success}++ if $success;
    return;
}

1;

__END__

=pod

=head1 NAME

Throttle::Adaptive - implementation of the "adaptive throttling" algorithm by Google

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Perl implementation of the I<adaptive throttling> algorithm described in
L<Google's SRE book|https://landing.google.com/sre/sre-book/chapters/handling-overload/>, used to
proactively reject requests to overloaded services.

=head1 EXAMPLE

    use Throttle::Adaptive;

    my $THROTTLE= Throttle::Adaptive->new;
    # my $THROTTLE= Throttle::Adaptive->new(
    #     ratio => 2,
    #     time => 120,
    # );

    sub do_request {
        my ($url)= @_;
        if ($THROTTLE->should_fail) {
            die "Proactively rejecting request which is likely to fail";
        }

        my $response= http_request($url);
        $THROTTLE->count($response->is_error && $response->error->is_timeout);

        if ($response->is_error) {
            die "Request failed: ".$reponse->error->as_string;
        }

        return $response->body;
    }

=head1 API

Construct a new C<Throttle::Adaptive> object via the C<new> method, which accepts the named
arguments C<ratio> and C<time> respectively indicating the fail:success ratio after which to start
rejecting requests (default: C<2>), and the window size in seconds (default: C<120>). For most use
cases the defaults are sufficient.

    my $throttler= Throttle::Adaptive->new;

This object has two methods, C<should_fail> and C<count>.

=over

=item should_fail

C<should_fail> should be invoked prior to submitting the request. If this function returns false,
the request should not be executed, and an error should be returned to the user. If it returns
true, the request should be executed, and C<count> should be used to track the success of the
request.

=item count($error)

C<count> tracks the success of the request once it is known whether it has succeeded. It takes one
argument, C<$error>, indicating whether the reason of the request failure is something we would
proactively fail for in the future (usually timeouts go into this category, but a HTTP 429 response
could also qualify).

=back

    if ($throttler->should_fail) {
        warn "Request skipped: throttler";
        return undef;
    }
    my $response = perform_request(...);
    if (is_timeout($response)) {
        $throttler->count(1);
    } else {
        $throttler->count(0);
    }
    return $response;

=head1 CAVEATS

One should make sure to only invoke C<count> on requests that have been submitted, and not in
situations where C<should_fail> indicates that the request should not be performed at all.

=head1 AUTHOR

Tom van der Woerdt <info@tvdw.eu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
