package Twitter::API::Error;
# ABSTRACT: Twitter API exception
$Twitter::API::Error::VERSION = '1.0002';
use Moo;
use Ref::Util qw/is_arrayref is_hashref/;
use Try::Tiny;
use namespace::clean;

use overload '""' => sub { shift->error };

with qw/Throwable StackTrace::Auto/;

#pod =method http_request
#pod
#pod Returns the L<HTTP::Request> object used to make the Twitter API call.
#pod
#pod =method http_response
#pod
#pod Returns the L<HTTP::Response> object for the API call.
#pod
#pod =method twitter_error
#pod
#pod Returns the inflated JSON error response from Twitter (if any).
#pod
#pod =cut

has context => (
    is       => 'ro',
    required => 1,
    handles  => {
        http_request  => 'http_request',
        http_response => 'http_response',
        twitter_error => 'result',
    },
);

#pod =method stack_trace
#pod
#pod Returns a L<Devel::StackTrace> object encapsulating the call stack so you can discover, where, in your application the error occurred.
#pod
#pod =method stack_frame
#pod
#pod Delegates to C<< stack_trace->frame >>. See L<Devel::StackTrace> for details.
#pod
#pod =method next_stack_fram
#pod
#pod Delegates to C<< stack_trace->next_frame >>. See L<Devel::StackTrace> for details.
#pod
#pod =cut

has '+stack_trace' => (
    handles => {
        stack_frame      => 'frame',
        next_stack_frame => 'next_frame',
    },
);

#pod =method error
#pod
#pod Returns a reasonable string representation of the exception. If Twitter
#pod returned error information in the form of a JSON body, it is mined for error
#pod text. Otherwise, the HTTP response status line is used. The stack frame is
#pod mined for the point in your application where the request initiated and
#pod appended to the message.
#pod
#pod When used in a string context, C<error> is called to stringify exception.
#pod
#pod =cut

has error => (
    is => 'lazy',
);

sub _build_error {
    my $self = shift;

    my $error = $self->twitter_error_text || $self->http_response->status_line;
    my ( $location ) = $self->stack_frame(0)->as_string =~ /( at .*)/;
    return $error . ($location || '');
}

sub twitter_error_text {
    my $self = shift;
    # Twitter does not return a consistent error structure, so we have to
    # try each known (or guessed) variant to find a suitable message...

    return '' unless $self->twitter_error;
    my $e = $self->twitter_error;

    return is_hashref($e) && (
        # the newest variant: array of errors
        exists $e->{errors}
            && is_arrayref($e->{errors})
            && exists $e->{errors}[0]
            && is_hashref($e->{errors}[0])
            && exists $e->{errors}[0]{message}
            && $e->{errors}[0]{message}

        # it's single error variant
        || exists $e->{error}
            && is_hashref($e->{error})
            && exists $e->{error}{message}
            && $e->{error}{message}

        # the original error structure (still applies to some endpoints)
        || exists $e->{error} && $e->{error}

        # or maybe it's not that deep (documentation would be helpful, here,
        # Twitter!)
        || exists $e->{message} && $e->{message}
    ) || ''; # punt
}

#pod =method twitter_error_code
#pod
#pod Returns the numeric error code returned by Twitter, or 0 if there is none. See
#pod L<https://dev.twitter.com/overview/api/response-codes> for details.
#pod
#pod =cut

sub twitter_error_code {
    my $self = shift;

    for ( $self->twitter_error ) {
        return is_hashref($_)
            && exists $_->{errors}
            && exists $_->{errors}[0]
            && exists $_->{errors}[0]{code}
            && $_->{errors}[0]{code}
            || 0;
    }
}

#pod =method is_token_error
#pod
#pod Returns true if the error represents a problem with the access token or its
#pod Twitter account, rather than with the resource being accessed.
#pod
#pod Some Twitter error codes indicate a problem with authentication or the
#pod token/secret used to make the API call. For example, the account has been
#pod suspended or access to the application revoked by the user. Other error codes
#pod indicate a problem with the resource requested. For example, the target account
#pod no longer exists.
#pod
#pod is_token_error returns true for the following Twitter API errors:
#pod
#pod =for :list
#pod * 32: Could not authenticate you
#pod * 64: Your account is suspended and is not permitted to access this feature
#pod * 88: Rate limit exceeded
#pod * 89: Invalid or expired token
#pod * 99: Unable to verify your credentials.
#pod * 135: Could not authenticate you
#pod * 136: You have been blocked from viewing this user's profile.
#pod * 215: Bad authentication data
#pod * 226: This request looks like it might be automated. To protect our users from
#pod   spam and other malicious activity, we can’t complete this action right now.
#pod * 326: To protect our users from spam…
#pod
#pod For error 215, Twitter's API documentation says, "Typically sent with 1.1
#pod responses with HTTP code 400. The method requires authentication but it was not
#pod presented or was wholly invalid." In practice, though, this error seems to be
#pod spurious, and often succeeds if retried, even with the same tokens.
#pod
#pod The Twitter API documentation describes error code 226, but in practice, they
#pod use code 326 instead, so we check for both. This error code means the account
#pod the tokens belong to has been locked for spam like activity and can't be used
#pod by the API until the user takes action to unlock their account.
#pod
#pod See Twitter's L<Error Codes &
#pod Responses|https://dev.twitter.com/overview/api/response-codes> documentation
#pod for more information.
#pod
#pod =cut

use constant TOKEN_ERRORS => (32, 64, 88, 89, 99, 135, 136, 215, 226, 326);
my %token_errors = map +($_ => undef), TOKEN_ERRORS;

sub is_token_error {
    exists $token_errors{shift->twitter_error_code};
}

#pod =method http_response_code
#pod
#pod Delegates to C<< http_response->code >>. Returns the HTTP status code of the
#pod response.
#pod
#pod =cut

sub http_response_code { shift->http_response->code }

#pod =method is_pemanent_error
#pod
#pod Returns true for HTTP status codes representing an error and with values less
#pod than 500. Typically, retrying an API call with one of these statuses right away
#pod will simply result in the same error, again.
#pod
#pod =cut

sub is_permanent_error { shift->http_response_code < 500 }

#pod =method is_temporary_error
#pod
#pod Returns true or HTTP status codes of 500 or greater. Often, these errors
#pod indicate a transient condition. Retrying the API call right away may result in
#pod success. See the L<RetryOnError|Twitter::API::Trait::RetryOnError> for
#pod automatically retrying temporary errors.
#pod
#pod =cut

sub is_temporary_error { !shift->is_permanent_error }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Error - Twitter API exception

=head1 VERSION

version 1.0002

=head1 SYNOPSIS

    use Try::Tiny;
    use Twitter::API;
    use Twitter::API::Util 'is_twitter_api_error';

    my $client = Twitter::API->new(%options);

    try {
        my $r = $client->get('account/verify_credentials');
    }
    catch {
        die $_ unless is_twitter_api_error;

        warn "Twitter says: ", $_->twitter_error_text;
    };

=head1 DESCRIPTION

Twitter::API dies, throwing a Twitter::API::Error exception when it receives an
error. The error object contains information about the error so your code can
decide how to respond to various error conditions.

=head1 METHODS

=head2 http_request

Returns the L<HTTP::Request> object used to make the Twitter API call.

=head2 http_response

Returns the L<HTTP::Response> object for the API call.

=head2 twitter_error

Returns the inflated JSON error response from Twitter (if any).

=head2 stack_trace

Returns a L<Devel::StackTrace> object encapsulating the call stack so you can discover, where, in your application the error occurred.

=head2 stack_frame

Delegates to C<< stack_trace->frame >>. See L<Devel::StackTrace> for details.

=head2 next_stack_fram

Delegates to C<< stack_trace->next_frame >>. See L<Devel::StackTrace> for details.

=head2 error

Returns a reasonable string representation of the exception. If Twitter
returned error information in the form of a JSON body, it is mined for error
text. Otherwise, the HTTP response status line is used. The stack frame is
mined for the point in your application where the request initiated and
appended to the message.

When used in a string context, C<error> is called to stringify exception.

=head2 twitter_error_code

Returns the numeric error code returned by Twitter, or 0 if there is none. See
L<https://dev.twitter.com/overview/api/response-codes> for details.

=head2 is_token_error

Returns true if the error represents a problem with the access token or its
Twitter account, rather than with the resource being accessed.

Some Twitter error codes indicate a problem with authentication or the
token/secret used to make the API call. For example, the account has been
suspended or access to the application revoked by the user. Other error codes
indicate a problem with the resource requested. For example, the target account
no longer exists.

is_token_error returns true for the following Twitter API errors:

=over 4

=item *

32: Could not authenticate you

=item *

64: Your account is suspended and is not permitted to access this feature

=item *

88: Rate limit exceeded

=item *

89: Invalid or expired token

=item *

99: Unable to verify your credentials.

=item *

135: Could not authenticate you

=item *

136: You have been blocked from viewing this user's profile.

=item *

215: Bad authentication data

=item *

226: This request looks like it might be automated. To protect our users from spam and other malicious activity, we can’t complete this action right now.

=item *

326: To protect our users from spam…

=back

For error 215, Twitter's API documentation says, "Typically sent with 1.1
responses with HTTP code 400. The method requires authentication but it was not
presented or was wholly invalid." In practice, though, this error seems to be
spurious, and often succeeds if retried, even with the same tokens.

The Twitter API documentation describes error code 226, but in practice, they
use code 326 instead, so we check for both. This error code means the account
the tokens belong to has been locked for spam like activity and can't be used
by the API until the user takes action to unlock their account.

See Twitter's L<Error Codes &
Responses|https://dev.twitter.com/overview/api/response-codes> documentation
for more information.

=head2 http_response_code

Delegates to C<< http_response->code >>. Returns the HTTP status code of the
response.

=head2 is_pemanent_error

Returns true for HTTP status codes representing an error and with values less
than 500. Typically, retrying an API call with one of these statuses right away
will simply result in the same error, again.

=head2 is_temporary_error

Returns true or HTTP status codes of 500 or greater. Often, these errors
indicate a transient condition. Retrying the API call right away may result in
success. See the L<RetryOnError|Twitter::API::Trait::RetryOnError> for
automatically retrying temporary errors.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
