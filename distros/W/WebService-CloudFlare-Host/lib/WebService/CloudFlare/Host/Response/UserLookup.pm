package WebService::CloudFlare::Host::Response::UserLookup;
use Moose;
with 'WebService::CloudFlare::Host::Role::Response';

sub res_map {
    return (
        'result'        => 'result',
        'msg'           => 'msg',
        'action'        => 'request:act',
        'unique_id'     => 'response:unique_id',
        'user_exists'   => 'response:user_exists',
        'email'         => 'response:cloudflare_email',
        'user_authed'   => 'response:user_authed',
        'user_key'      => 'response:user_key',
        'zones'         => 'response:hosted_zones',
    );
}



has [qw/ result action /] 
    => ( is => 'rw', isa => 'Str', required => 1 );

has [qw/ unique_id cloudflare_email user_key  /] 
    => ( is => 'rw', isa => 'Str|Undef', required => 0 );

has [qw/ zones /]
    => ( is => 'rw', isa => 'ArrayRef[Str]|Undef', required => 0 );

has [qw/ user_exists user_authed /]
    => ( is => 'rw', isa => 'json_bool', required => 1, coerce => 1 );

1;
