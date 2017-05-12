use Test::More tests => 9;
use YAML qw(LoadFile);

BEGIN {
    use_ok('WWW::DomainTools::SearchEngine');
}

my $CONFIG = LoadFile('t/license.yml');

my $obj = WWW::DomainTools::SearchEngine->new(
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

my $api = WWW::DomainTools::SearchEngine->new(
    partner     => $CONFIG->{partner},
    key         => $CONFIG->{key},
    customer_ip => $CONFIG->{customer_ip},
);
my $res = $api->request(
    ext => "COM|NET|ORG|INFO",
    q   => 'example.com',
);

ok( defined $res->{application}, "response came back" );

SKIP: {
    skip 'no commercial license edit t/license.yml', 3
        unless $CONFIG->{commercial_license};

    my $expect_taken = $api->domain_is_available("example.com");
    my $expect_avail
        = $api->domain_is_available("asdfasdfasdflkjhpoiuasdf.com");

    ok( $expect_taken == 0, 'domain should be taken' );
    ok( $expect_avail == 1, 'domain shoule be available' );

    # unsupported tld

    eval {
        my $expect_die = $api->domain_is_available("example.unsupported");
    };
    if ($@) {
        ok( 1, 'unsupported tld should die' );
    }
    else {
        ok( 0, 'unsupported tld should die' );
    }

}
