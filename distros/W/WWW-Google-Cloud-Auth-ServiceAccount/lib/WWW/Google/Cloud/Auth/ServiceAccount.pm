package WWW::Google::Cloud::Auth::ServiceAccount;

use Moose;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Carp;
use JSON;
use LWP::UserAgent;
use Crypt::JWT qw(encode_jwt);

use version; our $VERSION = version->declare('v1.0.1');

has credentials_path => (
    isa      => 'Str',
    required => 1,
);

has auth_url => (
    isa => 'Str',
    default => 'https://www.googleapis.com/oauth2/v4/token',
);

has grant_type => (
    isa     => 'Str',
    default => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
);

has scope => (
    isa     => 'Str',
    default =>  'https://www.googleapis.com/auth/cloud-platform',
);

# so that the token doesn't expire after checking it but before the request
# is processed on the other side.
has token_expiry_shift => (
    isa      => 'Str',
    required => 0,
    default  => 10,
);

has clock => (
    isa     => 'CodeRef',
    default => sub {sub {time}}
);

has ua_string => (
    isa     => 'Str',
    default => "WWW-Google-Cloud-Auth/$VERSION",
);

has _token => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    default  => undef,
    init_arg => undef,
);

has _token_expiry => (
    is       => 'rw',
    isa      => 'Int',
    default  => 0,
    init_arg => undef,
);

has _ua => (
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua',
    lazy     => 1,
    init_arg => undef,
);

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => $self->ua_string,
    );
    return $ua;
}

sub _generate_jwt {
    my $self = shift;
    open (my $fh, '<', $self->credentials_path) or die("Can't open credentials file: $!");
    my $creds_json = do {local $/; <$fh>};
    my $creds      = JSON::decode_json($creds_json);
    my $payload = {
        iss => $creds->{client_email},
        scope => $self->scope,
        aud => 'https://www.googleapis.com/oauth2/v4/token',
        exp => $self->clock->() + 600,
        iat => $self->clock->(),
    };
    my $key = $creds->{private_key};
    return encode_jwt(alg => 'RS256', payload => $payload, key => \$key);
}

sub get_token {
    my $self = shift;
    return $self->_token if($self->_token && $self->clock->() < $self->_token_expiry);

    my $jwt = $self->_generate_jwt();
    my $response = $self->_ua->post(
        $self->auth_url,
        {
            grant_type => $self->grant_type,
            assertion  => $jwt,
        }
    );

    if ($response->is_success) {
        my $r = decode_json($response->decoded_content);
        $self->_token($r->{access_token});
        $self->_token_expiry($self->clock->() + $r->{expires_in} - $self->token_expiry_shift);
        return $self->_token;
    } else {
        my @err = ($response->code, $response->message, $response->decoded_content);
        croak "@err";
    }
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf8

=head1 NAME

WWW::Google::Cloud::Auth::ServiceAccount - Service account based OAuth authentication for Google Cloud APIs

=head1 SYNOPSIS

    my $auth = WWW::Google::Cloud::Auth::ServiceAccount>new(
        credentials_path => '/home/myapp/priv/google_some_service.json',
    );

    my $response = $ua->post(
		 $some_google_cloud_api_endpoint,
		'Content-Type' => 'application/json; charset=utf-8',
		'Authorization' => 'Bearer ' . $auth->get_token,
		 Content => $arguments,
	);

=head1 DESCRIPTION

This is a library for service account based OAuth authentication with Google Cloud API endpoints for server to server applications.
See: L<https://developers.google.com/identity/protocols/OAuth2ServiceAccount>

=head1 FUNCTIONS

=head2 WWW::Google::Cloud::Auth::ServiceAccount->new(credentials_path => $credentials_path);

Instantiate a new WWW::Google::Cloud::Auth::ServiceAccount object.

Arguments:

=over 4

=item

credentials path [required]

The path to the JSON-encoded credentials file provided by Google.

=item

auth_url [optional]

The URL to get the OAuth token from. Defaults to https://www.googleapis.com/oauth2/v4/token. You probably don't need to change this.

=back

Returns:

=over 4

A new WWW::Google::Cloud::Auth::ServiceAccount instance.

=back

=head2 $auth->get_token()

Get a valid token to use for authorization. If there is a valid cached token return that.

Arguments:

=over 4

None

=back

Returns:

=over 4

The OAuth token

=back

=head1 AUTHOR

This module is written by Larion Garaczi <larion@cpan.org> (2019)

=head1 SOURCE CODE

The source code for this module is hosted on GitHub L<https://github.com/larion/www-google-cloud-auth>.

Feel free to contribute :)

=head1 LICENSE AND COPYRIGHT

This module is free software and is published under the same
terms as Perl itself.

=cut
