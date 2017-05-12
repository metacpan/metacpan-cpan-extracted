package WebService::CloudFlare::Host::Response::ZoneDelete;
use Moose;
use Moose::Util::TypeConstraints;
with 'WebService::CloudFlare::Host::Role::Response';
use Data::Dumper;


sub res_map {
    return (
        'result'        => 'result',
        'msg'           => 'msg',
        'action'        => 'request:act',
        'zone_name'     => 'response:zone_name',
        'zone_deleted'  => 'response:zone_deleted',
    );
}

# Strings (Required)
has [qw/ result action /] 
    => ( is => 'rw', isa => 'Str', required => 1 );

# Strings (Not Required)
has [qw/ zone_name  /] 
    => ( is => 'rw', isa => 'Str', required => 0 );

# JSON boolean values, coerced into 1|0 (Not Required)
has [qw/ zone_deleted /]
    => ( is => 'ro', isa => 'json_bool', coerce => 1, required => 0 );

1;
