use Test::More;

use URL::List;

my %urls = (
    'http://www.google.com/' => {
        host   => 'www.google.com',
        domain => 'google.com',
        tld    => 'com',
    }
);

foreach my $url ( keys %urls ) {
    my $list = URL::List->new;
    $list->add( $url );

    my $dist_by_host   = $list->distributed_by_host;
    my $dist_by_domain = $list->distributed_by_domain;
    my $dist_by_tld    = $list->distributed_by_tld;

    is( $dist_by_host  ->{ $urls{$url}->{host} }  ->[0], $url, $url );
    is( $dist_by_domain->{ $urls{$url}->{domain} }->[0], $url, $url );
    is( $dist_by_tld   ->{ $urls{$url}->{tld} }   ->[0], $url, $url );
}

my @urls = (
    'http://www.vg.no',
    'http://www.vg.no:80',
    'http://www.vg.no/',
    'http://www.vg.no:80/',
    'http://www.vg.no/index.html',

    'http://www.vg.no',
    'http://www.vg.no:80',
    'http://www.vg.no/',
    'http://www.vg.no:80/',
    'http://www.vg.no/index.html',
);

my $list = URL::List->new;

foreach my $url ( @urls ) {
    $list->add( $url );
}

is( $list->count, 5, 'URL count is OK' );

is_deeply( $list->distributed_by_host,   { 'www.vg.no' => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_domain, { 'vg.no'     => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_tld,    { 'no'        => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );

$list = URL::List->new( allow_duplicates => 1 );

foreach my $url ( @urls ) {
    $list->add( $url );
}

is( $list->count, 10, 'URL count is OK' );

is_deeply( $list->distributed_by_host,   { 'www.vg.no' => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html', 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_domain, { 'vg.no'     => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html', 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_tld,    { 'no'        => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html', 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );

$list = URL::List->new(
    urls => \@urls,
);

is( $list->count, 5, 'URL count is OK' );

is_deeply( $list->distributed_by_host,   { 'www.vg.no' => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_domain, { 'vg.no'     => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );
is_deeply( $list->distributed_by_tld,    { 'no'        => [ 'http://www.vg.no', 'http://www.vg.no:80', 'http://www.vg.no/', 'http://www.vg.no:80/', 'http://www.vg.no/index.html' ] } );

done_testing;
