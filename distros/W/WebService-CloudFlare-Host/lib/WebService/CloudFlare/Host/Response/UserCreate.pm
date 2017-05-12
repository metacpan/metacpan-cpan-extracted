package WebService::CloudFlare::Host::Response::UserCreate;
use Moose;
with 'WebService::CloudFlare::Host::Role::Response';

sub res_map {
    return (

        'api_key'       => 'response:user_api_key',
        'email'         => 'response:cloudflare_email',
        'user_key'      => 'response:user_key',
        'unique_id'     => 'response:unique_id',
        'username'      => 'response:cloudflare_username',

        'result'        => 'result',
    );
}



    has [qw/ api_key email user_key username code /]
    => ( is => 'rw', isa => 'Str', required => 0 );

has [qw/ msg unique_id /] 
    => ( is => 'rw', isa => 'Str|Undef', required => 0 );

1;
