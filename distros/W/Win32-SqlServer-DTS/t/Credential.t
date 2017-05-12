use Test::More tests => 3;

BEGIN { use_ok('Win32::SqlServer::DTS::Credential') }
can_ok( 'Win32::SqlServer::DTS::Credential', qw(new to_list) );

require Win32::SqlServer::DTS::Credential;

my $credential = Win32::SqlServer::DTS::Credential->new(
    {
        server                 => 'somewhere',
        user                   => 'user',
        password               => 'password',
        use_trusted_connection => 0
    }
);

my @list = $credential->to_list();

is( scalar( @list ),
    4, 'to_list method returns 4 elements in a list' );
