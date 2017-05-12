use Test::More tests => 6;
use YAML qw(LoadFile);

BEGIN {
    use_ok('WWW::DomainTools::NameSpinner');
}

my $CONFIG = LoadFile('t/license.yml');

my $obj = WWW::DomainTools::NameSpinner->new(
    partner     => $CONFIG->{partner},
    key         => $CONFIG->{key},
    customer_ip => $CONFIG->{customer_ip},
    url         => $CONFIG->{url},
    ignoreme    => "asdf",
);

ok( ${ $obj->{default_params} }{partner} eq $CONFIG->{partner},
    'default set 1' );
ok( ${ $obj->{default_params} }{key} eq $CONFIG->{key}, 'default set 2' );
ok( ${ $obj->{default_params} }{customer_ip} eq $CONFIG->{customer_ip},
    'default set 3' );
ok( !defined ${ $obj->{default_params} }{ignoreme}, 'default set 4' );

my $api = WWW::DomainTools::NameSpinner->new(
    partner     => $CONFIG->{partner},
    key         => $CONFIG->{key},
    customer_ip => $CONFIG->{customer_ip},
);
my $res = $api->request(
    ext => "COM|NET|ORG|INFO",
    q   => 'example.com',
);

ok( defined $res->{application}, "response came back" );
