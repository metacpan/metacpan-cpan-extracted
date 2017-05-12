use Test::More tests => 16;
BEGIN { use_ok('WWW::TinySong') };

my $ua;
ok($ua = WWW::TinySong->ua, 'ua() returns true value');
$ua->timeout(30);
$ua->env_proxy;

my $service;
ok($service = WWW::TinySong->service, 'service() returns true value');
like($service, qr(^http://)i, 'service() returns a http URL');

ok(defined(WWW::TinySong->retries), 'retries() is defined');

my $retries = 5;
is(WWW::TinySong->retries($retries), $retries, 'retries() sets correctly');

SKIP: {
    my $conn_ok;
    eval 'use Net::Config qw(%NetConfig); $conn_ok = $NetConfig{test_hosts}';
    skip 'Net::Config needed for network-related tests', 10 if $@;
    skip 'No network connection', 10 unless $conn_ok;

    my($res, @res);

    # link() check
    $res = WWW::TinySong->link('dreams');
    diag("link() returned $res");
    ok($res, 'link() returns true value');

    # a() check
    $res = WWW::TinySong->link('around the world');
    diag("a() returned $res");
    ok($res, 'a() returns true value');
    
    # b() check
    ok($res = WWW::TinySong->b('feel good inc'), 'b() returns true value');
    $res = get_artists($res);
    diag("b() returned artists: $res");
    like($res, qr/gorillaz/i, 'b() gives expected results');
    
    # search() check
    ok(@res = WWW::TinySong->search('three little birds'),
        'search() returns true value');
    $res = get_artists(@res);
    diag("search() returned artists: $res");
    like($res, qr/bob marley/i, 'search() gives expected results');

    # s() check
    ok(@res = WWW::TinySong->s('stairway to heaven'),
        's() returns true value');
    $res = get_artists(@res);
    diag("s() returned artists: $res");
    like($res, qr/led zeppelin/i, 's() gives expected results');

    # scrape() check
    ok(@res = WWW::TinySong->scrape('we can work it out'),
        'scrape() returns true value');
    $res = get_artists(@res);
    diag("scrape() returned artists: $res");
    like($res, qr/beatles/i, 'scrape() gives expected results');
}

sub get_artists {
    local %_ = map {$_->{artistName} => 1} @_;
    return join('; ', sort keys %_);
}
