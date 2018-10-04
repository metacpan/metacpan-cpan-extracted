package Twitter::API;
# ABSTRACT: A Twitter REST API library for Perl

our $VERSION = '1.0005';
use 5.14.1;
use Moo;
use Carp;
use Digest::SHA;
use Encode qw/encode_utf8/;
use HTTP::Request;
use HTTP::Request::Common qw/POST/;
use JSON::MaybeXS ();
use Module::Runtime qw/use_module/;
use Ref::Util qw/is_arrayref is_ref/;
use Try::Tiny;
use Twitter::API::Context;
use Twitter::API::Error;
use URI;
use URL::Encode ();
use WWW::OAuth;
use namespace::clean;

with qw/MooX::Traits/;
sub _trait_namespace { 'Twitter::API::Trait' }

has [ qw/consumer_key consumer_secret/ ] => (
    is       => 'ro',
    required => 1,
);

has [ qw/access_token access_token_secret/ ] => (
    is        => 'rw',
    predicate => 1,
    clearer   => 1,
);

# The secret is no good without the token.
after clear_access_token => sub {
    shift->clear_access_token_secret;
};

has api_url => (
    is      => 'ro',
    default => sub { 'https://api.twitter.com' },
);

has upload_url => (
    is      => 'ro',
    default => sub { 'https://upload.twitter.com' },
);

has api_version => (
    is      => 'ro',
    default => sub { '1.1' },
);

has agent => (
    is      => 'ro',
    default => sub {
        (join('/', __PACKAGE__, $VERSION) =~ s/::/-/gr) . ' (Perl)';
    },
);

has timeout => (
    is      => 'ro',
    default => sub { 10 },
);

has default_headers => (
    is => 'ro',
    default => sub {
        my $agent = shift->agent;
        {
            user_agent               => $agent,
            x_twitter_client         => $agent,
            x_twitter_client_version => $VERSION,
            x_twitter_client_url     => 'https://github.com/semifor/Twitter-API',
        };
    },
);

has user_agent => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        use_module 'HTTP::Thin';
        HTTP::Thin->new(
            timeout => $self->timeout,
            agent   => $self->agent,
        );
    },
    handles => {
        send_request   => 'request',
    },
);

has json_parser => (
    is      => 'ro',
    lazy    => 1,
    default => sub { JSON::MaybeXS->new(utf8 => 1) },
    handles => {
        from_json => 'decode',
        to_json   => 'encode',
    },
);

around BUILDARGS => sub {
    my ( $next, $class ) = splice @_, 0, 2;

    my $args = $class->$next(@_);
    croak 'use new_with_traits' if exists $args->{traits};

    return $args;
};

sub get  { shift->request( get => @_ ) }
sub post { shift->request( post => @_ ) }

sub request {
    my $self = shift;

    my $c = Twitter::API::Context->new({
        http_method => uc shift,
        url         => shift,
        args        => shift || {},
        # shallow copy so we don't spoil the defaults
        headers     => {
            %{ $self->default_headers },
            accept       => 'application/json',
            content_type => 'application/json;charset=utf8',
        },
        extra_args  => \@_,
    });

    $self->extract_options($c);
    $self->preprocess_args($c);
    $self->preprocess_url($c);
    $self->prepare_request($c);
    $self->add_authorization($c);

    # Allow early exit for things like Twitter::API::AnyEvent
    $c->set_http_response($self->send_request($c) // return $c);

    $self->inflate_response($c);
    return wantarray ? ( $c->result, $c ) : $c->result;
}

sub extract_options {
    my ( $self, $c ) = @_;

    my $args = $c->args;
    for ( keys %$args ) {
        $c->set_option($1, delete $$args{$_}) if /^-(.+)/;
    }
}

sub preprocess_args {
    my ( $self, $c ) = @_;

    if ( $c->http_method eq 'GET' ) {
        $self->flatten_array_args($c->args);
    }

    # If any of the args are arrayrefs, we'll infer it's multipart/form-data
    $c->set_option(multipart_form_data => 1) if
        $c->http_method eq 'POST' && !!grep is_ref($_), values %{ $c->args };
}

sub preprocess_url {
    my ( $self, $c ) = @_;

    my $url = $c->url;
    my $args = $c->args;
    $url =~ s[:(\w+)][delete $$args{$1} // croak "missing arg $1"]eg;
    $c->set_url($self->api_url_for($url));
}

sub prepare_request {
    my ( $self, $c ) = @_;

    # possibly override Accept header
    $c->set_header(accept => $c->get_option('accept'))
        if $c->has_option('accept');

    # dispatch on HTTP method
    my $http_method = $c->http_method;
    my $prepare_method = join '_', 'mk', lc($http_method), 'request';
    my $dispatch = $self->can($prepare_method)
        || croak "unexpected HTTP method: $http_method";

    my $req = $self->$dispatch($c);
    $c->set_http_request($req);
}

sub mk_get_request {
    shift->mk_simple_request(GET => @_);
}

sub mk_delete_request {
    shift->mk_simple_request(DELETE => @_);
}

sub mk_post_request {
    my ( $self, $c ) = @_;

    if ( $c->get_option('multipart_form_data') ) {
        return $self->mk_multipart_post($c);
    }

    if ( $c->has_option('to_json') ) {
        return $self->mk_json_post($c);
    }

    return $self->mk_form_urlencoded_post($c);
}

sub mk_multipart_post {
    my ( $self, $c ) = @_;

    $c->set_header(content_type => 'multipart/form-data;charset=utf-8');
    POST $c->url,
        %{ $c->headers },
        Content => [
            map { is_ref($_) ? $_ : encode_utf8 $_ } %{ $c->args },
        ];
}

sub mk_json_post {
    my ( $self, $c ) = @_;

    POST $c->url,
        %{ $c->headers },
        Content => $self->to_json($c->get_option('to_json'));
}

sub mk_form_urlencoded_post {
    my ( $self, $c ) = @_;

    $c->set_header(
        content_type => 'application/x-www-form-urlencoded;charset=utf-8');
    POST $c->url,
        %{ $c->headers },
        Content => $self->encode_args_string($c->args);
}

sub mk_simple_request {
    my ( $self, $http_method, $c ) = @_;

    my $uri = URI->new($c->url);
    if ( my $encoded = $self->encode_args_string($c->args) ) {
        $uri->query($encoded);
    }

    # HTTP::Message expects an arrayref, so transform
    my $headers = [ %{ $c->headers } ];

    return HTTP::Request->new($http_method, $uri, $headers);
}

sub add_authorization {
    my ( $self, $c ) = @_;

    my $req = $c->http_request;

    my %cred = (
        client_id     => $self->consumer_key,
        client_secret => $self->consumer_secret,
    );

    my %oauth;
    # only the token management methods set 'oauth_args'
    if ( my $opt = $c->get_option('oauth_args') ) {
        %oauth = %$opt;
        $cred{token}        = delete $oauth{oauth_token};
        $cred{token_secret} = delete $oauth{oauth_token_secret};
    }
    else {
        # protected request; requires tokens
        $cred{token} = $c->get_option('token')
            // $self->access_token
            // croak 'requires an oauth token';
        $cred{token_secret} = $c->get_option('token_secret')
            // $self->access_token_secret
            // croak 'requires an oauth token secret';
    }

    WWW::OAuth->new(%cred)->authenticate($req, \%oauth);
}

around send_request => sub {
    my ( $orig, $self, $c ) = @_;

    $self->$orig($c->http_request);
};

sub inflate_response {
    my ( $self, $c ) = @_;

    my $res = $c->http_response;
    my $data;
    try {
        if ( $res->content_type eq 'application/json' ) {
            $data = $self->from_json($res->content);
        }
        elsif ( ( $res->content_length // 0 ) == 0 ) {
            # E.g., 200 OK from media/metadata/create
            $data = '';
        }
        elsif ( ($c->get_option('accept') // '') eq 'application/x-www-form-urlencoded' ) {

            # Twitter sets Content-Type: text/html for /oauth/request_token and
            # /oauth/access_token even though they return url encoded form
            # data. So we'll decode based on what we expected when we set the
            # Accept header. We don't want to assume form data when we didn't
            # request it, because sometimes twitter returns 200 OK with actual
            # HTML content. We don't want to decode and return that. It's an
            # error. We'll just leave $data unset if we don't have a reasonable
            # expectation of the content type.

            $data = URL::Encode::url_params_mixed($res->content, 1);
        }
    }
    catch {
        # Failed to decode the response body, synthesize an error response
        s/ at .* line \d+.*//s;  # remove file/line number
        $res->code(500);
        $res->status($_);
    };

    $c->set_result($data);
    return if defined($data) && $res->is_success;

    $self->process_error_response($c);
}

sub flatten_array_args {
    my ( $self, $args ) = @_;

    # transform arrays to comma delimited strings
    for my $k ( keys %$args ) {
        my $v = $$args{$k};
        $$args{$k} = join ',' => @$v if is_arrayref($v);
    }
}

sub encode_args_string {
    my ( $self, $args ) = @_;

    my @pairs;
    for my $k ( sort keys %$args ) {
        push @pairs, join '=', map $self->uri_escape($_), $k, $$args{$k};
    }

    join '&', @pairs;
}

sub uri_escape { URL::Encode::url_encode_utf8($_[1]) }

sub process_error_response {
    Twitter::API::Error->throw({ context => $_[1] });
}

sub api_url_for {
    my $self = shift;

    $self->_url_for('.json', $self->api_url, $self->api_version, @_);
}

sub upload_url_for {
    my $self = shift;

    $self->_url_for('.json', $self->upload_url, $self->api_version, @_);
}

sub oauth_url_for {
    my $self = shift;

    $self->_url_for('', $self->api_url, 'oauth', @_);
}

sub _url_for {
    my ( $self, $ext, @parts ) = @_;

    # If we already have a fully qualified URL, just return it
    return $_[-1] if $_[-1] =~ m(^https?://);

    join('/', @parts) . $ext;
}

# OAuth handshake

sub oauth_request_token {
    my $self = shift;
    my %args = @_ == 1 && is_ref($_[0]) ? %{ $_[0] } : @_;

    my %oauth_args;
    $oauth_args{oauth_callback} = delete $args{callback} // 'oob';
    return $self->request(post => $self->oauth_url_for('request_token'), {
        -accept     => 'application/x-www-form-urlencoded',
        -oauth_args => \%oauth_args,
        %args, # i.e. ( x_auth_access_type => 'read' )
    });
}

sub _auth_url {
    my ( $self, $endpoint ) = splice @_, 0, 2;
    my %args = @_ == 1 && is_ref($_[0]) ? %{ $_[0] } : @_;

    my $uri = URI->new($self->oauth_url_for($endpoint));
    $uri->query_form(%args);
    return $uri;
};

sub oauth_authentication_url { shift->_auth_url(authenticate => @_) }
sub oauth_authorization_url  { shift->_auth_url(authorize    => @_) }

sub oauth_access_token {
    my $self = shift;
    my %args = @_ == 1 && is_ref($_[0]) ? %{ $_[0] } : @_;

    # We'll take 'em with or without the oauth_ prefix :)
    my %oauth_args;
    @oauth_args{map s/^(?!oauth_)/oauth_/r, keys %args} = values %args;

    $self->request(post => $self->oauth_url_for('access_token'), {
        -accept     => 'application/x-www-form-urlencoded',
        -oauth_args => \%oauth_args,
    });
}

sub xauth {
    my ( $self, $username, $password ) = splice @_, 0, 3;
    my %extra_args = @_ == 1 && is_ref($_[0]) ? %{ $_[0] } : @_;

    $self->request(post => $self->oauth_url_for('access_token'), {
        -accept     => 'application/x-www-form-urlencoded',
        -oauth_args => {},
        x_auth_mode     => 'client_auth',
        x_auth_password => $password,
        x_auth_username => $username,
        %extra_args,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API - A Twitter REST API library for Perl

=for html <a href="https://travis-ci.org/semifor/Twitter-API"><img src="https://travis-ci.org/semifor/Twitter-API.svg?branch=master" alt="Build Status" /></a>

=head1 VERSION

version 1.0005

=head1 SYNOPSIS

    ### Common usage ###

    use Twitter::API;
    my $client = Twitter::API->new_with_traits(
        traits              => 'Enchilada',
        consumer_key        => $YOUR_CONSUMER_KEY,
        consumer_secret     => $YOUR_CONSUMER_SECRET,
        access_token        => $YOUR_ACCESS_TOKEN,
        access_token_secret => $YOUR_ACCESS_TOKEN_SECRET,
    );

    my $me   = $client->verify_credentials;
    my $user = $client->show_user('twitter');

    # In list context, both the Twitter API result and a Twitter::API::Context
    # object are returned.
    my ($r, $context) = $client->home_timeline({ count => 200, trim_user => 1 });
    my $remaning = $context->rate_limit_remaining;
    my $until    = $context->rate_limit_reset;


    ### No frills ###

    my $client = Twitter::API->new(
        consumer_key    => $YOUR_CONSUMER_KEY,
        consumer_secret => $YOUR_CONSUMER_SECRET,
    );

    my $r = $client->get('account/verify_credentials', {
        -token        => $an_access_token,
        -token_secret => $an_access_token_secret,
    });

    ### Error handling ###

    use Twitter::API::Util 'is_twitter_api_error';
    use Try::Tiny;

    try {
        my $r = $client->verify_credentials;
    }
    catch {
        die $_ unless is_twitter_api_error($_);

        # The error object includes plenty of information
        say $_->http_request->as_string;
        say $_->http_response->as_string;
        say 'No use retrying right away' if $_->is_permanent_error;
        if ( $_->is_token_error ) {
            say "There's something wrong with this token."
        }
        if ( $_->twitter_error_code == 326 ) {
            say "Oops! Twitter thinks you're spam bot!";
        }
    };

=head1 DESCRIPTION

Twitter::API provides an interface to the Twitter REST API for perl.

Features:

=over 4

=item *

full support for all Twitter REST API endpoints

=item *

not dependent on a new distribution for new endpoint support

=item *

optionally specify access tokens per API call

=item *

error handling via an exception object that captures the full request/response context

=item *

full support for OAuth handshake and Xauth authentication

=back

Additional features are available via optional traits:

=over 4

=item *

convenient methods for API endpoints with simplified argument handling via L<ApiMethods|Twitter::API::Trait::ApiMethods>

=item *

normalized booleans (Twitter likes 'true' and 'false', except when it doesn't) via L<NormalizeBooleans|Twitter::API::Trait::NormalizeBooleans>

=item *

automatic decoding of HTML entities via L<DecodeHtmlEntities|Twitter::API::Trait::DecodeHtmlEntities>

=item *

automatic retry on transient errors via L<RetryOnError|Twitter::API::Trait::RetryOnError>

=item *

"the whole enchilada" combines all the above traits via L<Enchilada|Twitter::API::Trait::Enchilada>

=item *

app-only (OAuth2) support via L<AppAuth|Twitter::API::Trait::AppAuth>

=item *

automatic rate limiting via L<RateLimiting|Twitter::API::Trait::RateLimiting>

=back

Some features are provided by separate distributions to avoid additional
dependencies most users won't want or need:

=over 4

=item *

async support via subclass L<Twitter::API::AnyEvent|https://github.com/semifor/Twitter-API-AnyEvent>

=item *

inflate API call results to objects via L<Twitter::API::Trait::InflateObjects|https://github.com/semifor/Twitter-API-Trait-InflateObjects>

=back

=head1 OVERVIEW

=head2 Migration from Net::Twitter and Net::Twitter::Lite

Migration support is included to assist users migrating from L<Net::Twitter>
and L<Net::Twitter::Lite>. It will be removed from a future release. See
L<Migration|Twitter::API::Trait::Migration> for details about migrating your
existing Net::Twitter/::Lite applications.

=head2 Normal usage

Normally, you will construct a Twitter::API client with some traits, primarily
B<ApiMethods>. It provides methods for each known Twitter API endpoint.
Documentation is provided for each of those methods in
L<ApiMethods|Twitter::API::Trait::ApiMethods>.

See the list of traits in the L</DESCRIPTION> and refer to the documentation
for each.

=head2 Minimalist usage

Without any traits, Twitter::API provides access to API endpoints with the
L<get|get-url-args> and L<post|post-url-args> methods described below, as well
as methods for managing OAuth authentication. API results are simply perl data
structures decoded from the JSON responses. Refer to the L<Twitter API
Documentation|https://dev.twitter.com/rest/public> for available endpoints,
parameters, and responses.

=head1 ATTRIBUTES

=head2 consumer_key, consumer_secret

Required. Every application has it's own application credentials.

=head2 access_token, access_token_secret

Optional. If provided, every API call will be authenticated with these user
credentials. See L<AppAuth|Twitter::API::Trait::AppAuth> for app-only (OAuth2)
support, which does not require user credentials. You can also pass options
C<-token> and C<-token_secret> to specify user credentials on each API call.

=head2 api_url

Optional. Defaults to C<https://api.twitter.com>.

=head2 upload_url

Optional. Defaults to C<https://upload.twitter.com>.

=head2 api_version

Optional. Defaults to C<1.1>.

=head2 agent

Optional. Used for both the User-Agent and X-Twitter-Client identifiers.
Defaults to C<Twitter-API-$VERSION (Perl)>.

=head2 timeout

Optional. Request timeout in seconds. Defaults to C<10>.

=head1 METHODS

=head2 get($url, [ \%args ])

Issues an HTTP GET request to Twitter. If C<$url> is just a path part, e.g.,
C<account/verify_credentials>, it will be expanded to a full URL by prepending
the C<api_url>, C<api_version> and appending C<.json>. A full URL can also be
specified, e.g. C<https://api.twitter.com/1.1/account/verify_credentials.json>.

This should accommodate any new API endpoints Twitter adds without requiring an
update to this module.

=head2 post($url, [ \%args ])

See C<get> above, for a discussion C<$url>. For file upload, pass an array
reference as described in
L<https://metacpan.org/pod/distribution/HTTP-Message/lib/HTTP/Request/Common.pm#POST-url-Header-Value-...-Content-content>.

=head2 oauth_request_token([ \%args ])

This is the first step in the OAuth handshake. The only argument expected is
C<callback>, which defaults to C<oob> for PIN based verification. Web
applications will pass a callback URL.

Returns a hashref that includes C<oauth_token> and C<oauth_token_secret>.

See L<https://developer.twitter.com/en/docs/basics/authentication/api-reference/request_token>.

=head2 oauth_authentication_url(\%args)

This is the second step in the OAuth handshake. The only required argument is
C<oauth_token>. Use the value returned by C<get_request_token>. Optional
arguments: C<force_login> and C<screen_name> to pre-fill Twitter's
authentication form.

See L<https://developer.twitter.com/en/docs/basics/authentication/api-reference/authenticate>.

=head2 oauth_authorization_url(\%args)

Identical to C<oauth_authentication_url>, but uses authorization flow, rather
than authentication flow.

See L<https://developer.twitter.com/en/docs/basics/authentication/api-reference/authorize>.

=head2 oauth_access_token(\%ags)

This is the third and final step in the OAuth handshake. Pass the request
C<token>, request C<token_secret> obtained in the C<get_request_token> call,
and either the PIN number if you used C<oob> for the callback value in
C<get_request_token> or the C<verifier> parameter returned in the web callback,
as C<verfier>.

See L<https://developer.twitter.com/en/docs/basics/authentication/api-reference/access_token>.

=head2 xauth(\%args)

Requires per application approval from Twitter. Pass C<username> and
C<password>.

=head1 SEE ALSO

=over 4

=item *

L<API::Twitter> - Twitter.com API Client

=item *

L<AnyEvent::Twitter::Stream> - Receive Twitter streaming API in an event loop

=item *

L<AnyEvent::Twitter> - A thin wrapper for Twitter API using OAuth

=item *

L<Mojo::WebService::Twitter> - Simple Twitter API client

=item *

L<Net::Twitter> - Twitter::API's predecessor (also L<Net::Twitter::Lite>)

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
