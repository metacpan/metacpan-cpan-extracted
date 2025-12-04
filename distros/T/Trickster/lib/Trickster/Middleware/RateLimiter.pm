package Trickster::Middleware::RateLimiter;

use strict;
use warnings;
use v5.14;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(
    requests
    window
    storage
    key_generator
    error_handler
);

sub prepare_app {
    my ($self) = @_;
    
    $self->requests(60) unless $self->requests;
    $self->window(60) unless $self->window;
    $self->storage({}) unless $self->storage;
    
    $self->key_generator(sub {
        my $env = shift;
        return $env->{REMOTE_ADDR} || 'unknown';
    }) unless $self->key_generator;
    
    $self->error_handler(sub {
        my ($env, $remaining, $reset) = @_;
        return [
            429,
            [
                'Content-Type' => 'application/json',
                'X-RateLimit-Limit' => $self->requests,
                'X-RateLimit-Remaining' => 0,
                'X-RateLimit-Reset' => $reset,
                'Retry-After' => $reset - time,
            ],
            ['{"error":"Rate limit exceeded"}'],
        ];
    }) unless $self->error_handler;
}

sub call {
    my ($self, $env) = @_;
    
    my $key = $self->key_generator->($env);
    my $now = time;
    
    # Get or initialize bucket
    my $bucket = $self->storage->{$key} ||= {
        count => 0,
        reset => $now + $self->window,
    };
    
    # Reset bucket if window expired
    if ($now >= $bucket->{reset}) {
        $bucket->{count} = 0;
        $bucket->{reset} = $now + $self->window;
    }
    
    # Check rate limit
    if ($bucket->{count} >= $self->requests) {
        return $self->error_handler->($env, 0, $bucket->{reset});
    }
    
    # Increment counter
    $bucket->{count}++;
    
    my $remaining = $self->requests - $bucket->{count};
    
    # Call app
    my $res = $self->app->($env);
    
    # Add rate limit headers
    return $self->response_cb($res, sub {
        my $res = shift;
        push @{$res->[1]},
            'X-RateLimit-Limit' => $self->requests,
            'X-RateLimit-Remaining' => $remaining,
            'X-RateLimit-Reset' => $bucket->{reset};
    });
}

1;

__END__

=head1 NAME

Trickster::Middleware::RateLimiter - Rate limiting middleware for Trickster

=head1 SYNOPSIS

    use Trickster::Middleware::RateLimiter;
    
    # Default: 60 requests per 60 seconds per IP
    $app->middleware(Trickster::Middleware::RateLimiter->new);
    
    # Custom limits
    $app->middleware(Trickster::Middleware::RateLimiter->new(
        requests => 100,
        window => 3600,  # 1 hour
    ));
    
    # Custom key generator (e.g., by user ID)
    $app->middleware(Trickster::Middleware::RateLimiter->new(
        key_generator => sub {
            my $env = shift;
            return $env->{'trickster.user_id'} || $env->{REMOTE_ADDR};
        },
    ));

=head1 DESCRIPTION

Trickster::Middleware::RateLimiter provides rate limiting to protect
your application from abuse.

=head1 OPTIONS

=over 4

=item requests

Number of requests allowed per window.
Default: 60

=item window

Time window in seconds.
Default: 60

=item storage

Hash ref for storing rate limit data.
Default: in-memory hash (not suitable for multi-process)

=item key_generator

Code ref that generates a key from the environment.
Default: uses REMOTE_ADDR

=item error_handler

Code ref that returns the response when rate limit is exceeded.

=back

=head1 HEADERS

The middleware adds the following headers to responses:

=over 4

=item X-RateLimit-Limit

Maximum number of requests allowed

=item X-RateLimit-Remaining

Number of requests remaining in current window

=item X-RateLimit-Reset

Unix timestamp when the rate limit resets

=back

=cut
