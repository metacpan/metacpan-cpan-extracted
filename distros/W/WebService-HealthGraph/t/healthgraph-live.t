use Test2::Bundle::Extended;
use Test2::Plugin::BailOnFail;

use Data::Printer;
use DateTime ();
use List::AllUtils qw( any );
use Test::RequiresInternet ( 'api.runkeeper.com' => 443 );
use URI::FromHash qw( uri );
use WebService::HealthGraph ();

SKIP: {
    skip 'Token required for live tests', 1 unless $ENV{HEALTHGRAPH_TOKEN};

    my $runkeeper = WebService::HealthGraph->new(
        debug => 1,
        token => $ENV{HEALTHGRAPH_TOKEN},
    );
    ok( $runkeeper,           'compiles' );
    ok( $runkeeper->ua,       'ua' );
    ok( $runkeeper->base_url, 'base_url' );

    my $user = $runkeeper->user;
    ok( $user,               'get_user' );
    ok( $runkeeper->user_id, 'user_id' );
    ok( $runkeeper->url_map, 'url_map' );
    diag( np( $runkeeper->url_map ) );
    ok( $runkeeper->uri_for('team'), 'uri_for team' );

    my @non_feeds = ( 'change_log', 'profile', 'settings', 'records', );

    # Test feeds
    my $query
        = { noEarlierThan => DateTime->now->subtract( days => 7 )->ymd };
    foreach my $key ( sort keys %{ $runkeeper->url_map } ) {
        next if any { $key eq $_ } ( @non_feeds, 'diabetes' );

        my $uri = uri( path => $user->content->{$key}, query => $query, );

        my $feed = $runkeeper->get( $uri, { feed => 1 } );
        ok( $feed,          "GET $uri" );
        ok( $feed->success, '200 code' );

        if ( $feed->content && @{ $feed->content->{items} } ) {
            my $item = $feed->content->{items}->[0];

            # team items have "url"
            my $uri = $item->{uri} || $item->{url};
            my $item_response = $runkeeper->get($uri);
            ok( $item_response->success, "GET $uri" );
        }
    }

    foreach my $type (@non_feeds) {
        my $res = $runkeeper->get( $runkeeper->url_map->{$type} );
        ok( $res->success, $type );
    }

    # Test iterator
    use URI::FromHash qw( uri );

    my $uri = uri(
        path            => '/weight',
        query           => { pageSize => 1, },
        query_separator => '&',
    );

    my $feed = $runkeeper->get( $uri, { feed => 1 } );

    my $count;
    while ( my $item = $feed->next ) {
        ++$count;
        if ( $count == 1 ) {
            diag $feed->next_page_uri;
        }
        last if $count > 2;
    }
}

done_testing;
