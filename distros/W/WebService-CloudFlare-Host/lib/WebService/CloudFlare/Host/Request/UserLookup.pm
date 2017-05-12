package WebService::CloudFlare::Host::Request::UserLookup;
use Moose;
with 'WebService::CloudFlare::Host::Role::Request';

has 'req_map' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    init_arg => undef,
    default => sub {{
        'act'               => 'action',
        'cloudflare_email'  => 'email', 
        'unique_id'         => 'unique_id',  
    }},
);

has 'action' => ( 
    is => 'ro',
    isa => 'Str', 
    init_arg => undef, 
    default => 'user_lookup' 
);


has [qw/ email unique_id /] 
    => (is => 'ro', isa => 'Str', required => 0);

1;
