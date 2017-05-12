package WebService::CloudFlare::Host::Request::ZoneDelete;
use Moose;
with 'WebService::CloudFlare::Host::Role::Request';

has 'req_map' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    init_arg => undef,
    default => sub {{
        'act'       => 'action',
        'zone_name' => 'zone_name', 
        'user_key'  => 'user_key', 
    }},
);

has 'action' => ( 
    is => 'ro',
    isa => 'Str', 
    init_arg => undef, 
    default => 'zone_delete' 
);

has [qw/ zone_name user_key /] 
    => (is => 'ro', isa => 'Str', required => 1);

1;
