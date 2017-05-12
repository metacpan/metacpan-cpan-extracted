package WebService::CloudFlare::Host::Request::ZoneSet;
use Moose;
with 'WebService::CloudFlare::Host::Role::Request';

has 'req_map' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    init_arg => undef,
    default => sub {{
        'act'        => 'action',
        'zone_name'  => 'zone_name', 
        'user_key'   => 'user_key',  
        'resolve_to' => 'resolve_to',
        'subdomains' => 'subdomains',
    }},
);

has 'action' => ( 
    is => 'ro',
    isa => 'Str', 
    init_arg => undef, 
    default => 'zone_set' 
);


has [qw/ user_key zone_name /] 
    => (is => 'ro', isa => 'Str', required => 1);

has [qw/ resolve_to subdomains /] 
    => (is => 'ro', isa => 'Str', required => 0);

1;
