package WebService::CloudFlare::Host::Request::UserAuth;
use Moose;
with 'WebService::CloudFlare::Host::Role::Request';

has 'req_map' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    init_arg => undef,
    default => sub {{
        'act'               => 'action',
        'cloudflare_email'  => 'email', 
        'cloudflare_pass'   => 'pass',  
        'unique_id'         => 'unique_id',
        'clobber_unique_id' => 'clobber',
    }},
);

has 'action' => ( 
    is => 'ro',
    isa => 'Str', 
    init_arg => undef, 
    default => 'user_auth' 
);

has [ qw/ email pass / ] 
    => (is => 'ro', isa => 'Str', required => 0);

has [ qw/ unique_id clobber / ] 
    => (is => 'ro', isa => 'Str', required => 0);

1;
