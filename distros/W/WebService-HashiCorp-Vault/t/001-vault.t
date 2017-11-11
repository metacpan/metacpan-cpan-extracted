use warnings;
use strict;
use Test::More;
use WebService::HashiCorp::Vault;

if (not $ENV{TEST_AUTHOR}) {
    plan skip_all =>
        'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
} else {
    plan tests => 9;
}


my @backends = qw/  Cassandra
                    Cubbyhole
                    Generic
                    MongoDB
                    MSSQL
                    MySQL
                    PostgreSQL
                    RabbitMQ
                    SSH         /;
# Start vault with: vault server -dev -dev-root-token-id=foo
my $vault = WebService::HashiCorp::Vault->new(token => 'foo');
for my $backend (@backends) {
    my $secret = $vault->secret(
                    mount   => 'secret', # optional if mounted non-default
                    backend => 'Generic', # or MySQL, or SSH, or whatever
                    path    => '/bar',
    );
    isa_ok($secret, 'WebService::HashiCorp::Vault::Secret::Generic');

}
