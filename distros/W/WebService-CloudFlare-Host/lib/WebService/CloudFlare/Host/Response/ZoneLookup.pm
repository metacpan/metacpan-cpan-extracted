package WebService::CloudFlare::Host::Response::ZoneLookup;
use Moose;
with 'WebService::CloudFlare::Host::Role::Response';

sub res_map {
    return (
        'result'        => 'result',
        'msg'           => 'msg',
        'action'        => 'request:act',
        'zone_name'     => 'response:zone_name',
        'zone_exists'   => 'response:zone_exists',
        'zone_hosted'   => 'response:zone_hosted',
        'hosted'        => 'response:hosted_cnames',
        'forwarded'     => 'response:forward_tos',
    );
}



# Strings (Required)
has [qw/ result action /] 
    => ( is => 'rw', isa => 'Str', required => 1 );

# Strings (Not Required)
has [qw/ zone_name  /] 
    => ( is => 'rw', isa => 'Str', required => 0 );

# HashRefs (Not Required)
has [qw/ hosted forwarded /]
    => ( is => 'rw', isa => 'HashRef[Str]|Undef', required => 0 );

# JSON boolean values, coerced into 1|0 (Not Required)
has [qw/ zone_exists zone_hosted /]
    => ( is => 'ro', isa => 'json_bool', required => 0, coerce => 1 );

1;
