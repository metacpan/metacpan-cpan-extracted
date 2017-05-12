package WebService::CloudFlare::Host::Response::ZoneSet;
use Moose;
with 'WebService::CloudFlare::Host::Role::Response';


sub res_map {
    return (
        'zone_name'  => 'response:zone_name',
        'resolving'  => 'response:resolving_to',
        'forwarded'  => 'response:hosted_cnames',
        'hosted'     => 'response:forward_tos',
    );
}



has [qw/ zone_name resolving_to /] 
    => ( is => 'rw', isa => 'Str', required => 0 );

has [qw/ forwarded hosted /]
    => ( is => 'rw', isa => 'HashRef[Str]', required => 0 );

1;
