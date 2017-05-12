package WebService::Site24x7::Client;

use Moo;

with 'Role::REST::Client';

has version               => (is => 'rw', required => 1);
has auth_token            => (is => 'rw', required => 1);
has user_agent_header     => (is => 'rw', lazy => 1, builder => 1);
has '+server'             => (builder => 1, lazy => 1);
has '+persistent_headers' => (default => \&_build_persistent_headers);

sub _build_user_agent_header  { "perl WebService::Site24x7 " . shift->version }
sub _build_server             { 'https://www.site24x7.com/api' }
sub _build_persistent_headers {
    my $self = shift;
    return {
        'Authorization' => "Zoho-authtoken " . $self->auth_token,
        'User-Agent'    => $self->user_agent_header,
    };
}

1;
