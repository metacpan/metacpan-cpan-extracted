package WebService::CloudFlare::Host::Response::UserAuth;
use Moose;
with 'WebService::CloudFlare::Host::Role::Response';

sub res_map {
    return (
        'email'         => 'response:cloudflare_email',
        'user_key'      => 'response:user_key',
        'unique_id'     => 'response:unique_id',
        'api_key'       => 'response:user_api_key',
    );
}

has [qw/ unique_id /] 
    => ( is => 'rw', isa => 'Str|Undef', required => 0 );

has [qw/ email user_key api_key /] 
    => ( is => 'rw', isa => 'Str', required => 0 );

1;
