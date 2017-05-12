use Test::More tests => 5;
use WebService::Livedoor::Auth;

my $auth = WebService::Livedoor::Auth->new({
    app_key => 'ac68fa32da1305dafe3421d012f0aaba',
    secret => 'ccd0ea2d35d7bafd',
});

{
    my $uri = $auth->uri_to_login;
    isa_ok($uri, 'URI');
    my %query = $uri->query_form;
    is($query{app_key}, 'ac68fa32da1305dafe3421d012f0aaba');
    ok(!(exists $query{userdata}));
    my $sig = delete $query{sig};
    is($auth->calc_sig(\%query), $sig);
}

{
    my $uri = $auth->uri_to_login({
        userdata => 'xxx',
    });
    my %query = $uri->query_form;
    is($query{userdata}, 'xxx');
}
