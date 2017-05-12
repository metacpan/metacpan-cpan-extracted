package WebService::CloudFlare::Host::Request::UserCreate;
use Moose;
with 'WebService::CloudFlare::Host::Role::Request';

has 'req_map' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    init_arg => undef,
    default => sub {{
        act                     => 'action',
        cloudflare_email        => 'email',
        cloudflare_pass         => 'pass',
        cloudflare_username     => 'user',
        unique_id               => 'unique_id',
        clobber_unique_id       => 'clobber',
    }},
);

has 'action' => ( 
    is => 'ro',
    isa => 'Str', 
    init_arg => undef, 
    default => 'user_create' 
);


has [qw/ email pass /] 
    => (is => 'ro', isa => 'Str', required => 1);
    
has [qw/user unique_id clobber/] 
    => (is => 'ro', isa => 'Str', required => 0);

1;
