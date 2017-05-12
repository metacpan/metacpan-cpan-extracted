
use strict;
use warnings;

use Test::More tests => 117;
use Test::NoWarnings;
use Test::Exception;

use HTTP::Daemon;
use HTTP::Response;
use HTTP::Date qw( time2str );
use DateTime;
use HTTP::Status qw( HTTP_OK HTTP_NOT_FOUND );
use HTML::HeadParser;
use utf8;

BEGIN {
    use_ok( 'WWW::Sitemapper' );
};

{

    package MyWebSite::Map;
    use Moose;

    use base qw( WWW::Sitemapper );

    has 'url_parents' => (
        is => 'rw',
        isa => 'HashRef',
        default => sub { +{} },
    );

    sub _build_robot_config {
        my $self = shift;

        return {
            NAME => 'MyRobot',
            EMAIL => 'me@domain.tld',
            DELAY => 0,
        };
    }

    sub url_test : Hook('follow-url-test') {
        my $self = shift;
        my ($robot, $hook_name, $uri) = @_;

        my @restricted = (
            qr{^/12.html},
        );

        my $url = $uri->path_query;

        if ( $self->site->host eq $uri->host ) {
            for my $re ( @restricted ) {
                if ( $url =~ /$re/ ) {
                    return 0;
                }
            }

            return 1;
        }

        return 0;
    }

    sub incorrect_attr : Attr(whatever) {
        my $self = shift;

        return 1;
    }

    around '_map_builder' => sub {
        my $orig = shift;
        my $self = shift;
        my ($robot, $hook_name, $from_url, $to_url) = @_;

        $self->url_parents->{$to_url->path}->{$from_url->path} = 1;

        $self->$orig( $robot, $hook_name, $from_url, $to_url );
    };
};

# We want to be safe from non-resolving local host names
delete $ENV{HTTP_PROXY};
my $d = HTTP::Daemon->new( LocalAddr => 'localhost' ) || die;
my $server_host = $d->url;
my $is_test;
my $STATUS_STORAGE_FILE = "t/status.storage";
my $TEST_TIME = time();
my $W3C_DATETIME = DateTime->from_epoch(
        epoch => $TEST_TIME
)->strftime('%FT%T%z');
$W3C_DATETIME =~ s/(\d{2})$/:$1/;
# for qr
$W3C_DATETIME =~ s/([\-\+])/\\$1/g;
my $HTTP_DATE = time2str($TEST_TIME);

if ($is_test = fork ) {
    # wait for server to start up
    sleep 1;

    my @valid_links = map {
        "$server_host$_"
    } qw(
        index.html
            1.html
                11.html
                    3.html
                        31.html
                        32.html
            2.html
                21.html
                22.html
    );
    my @valid_redirects = map {
        "$server_host$_"
    } qw(
        friendly_url.html
    );

    my $mapper;

    lives_ok {
        $mapper = MyWebSite::Map->new(
            site => "${server_host}index.html",
            status_storage => $STATUS_STORAGE_FILE,
            auto_save => 0.02,
        );
    } "mapper object created";

    lives_ok {
        $mapper->run();
    } "run() works";

    my $root = $mapper->tree;

    is_deeply(
        [ sort keys %{ $root->_dictionary } ],
        [ sort @valid_links ],
        "valid links were fetched"
    );
    is_deeply(
        [ sort keys %{ $root->_redirects } ],
        [ sort @valid_redirects ],
        "valid redirects were found"
    );

    # Root / index.html
    is( $root->uri, "${server_host}index.html",
        "root->uri is correct"
    );
    is($root->id, '0', "root->id is correct");
    is($root->title, 'Root', "root->title is correct");
    is scalar @{$root->nodes}, 2, 'root has two direct nodes';
    is_deeply(
        [ map { $_->uri->as_string } $root->children ],
        [ map { "$server_host$_" } qw( 1.html 2.html ) ],
        "root has correct nodes mapped"
    );
    is_deeply(
        [ map { $_->uri->as_string } $root->children ],
        [ map { $_->loc->as_string } $root->children ],
        "root nodes have loc() same as uri()"
    );
    is_deeply(
        [ map { $_->id } $root->children ],
        [ qw( 0:0 0:1 ) ],
        "root nodes have correct ids"
    );
    is_deeply(
        [ map { $_->title } $root->children ],
        [ qw( Child1 Child2 ) ],
        "root nodes have correct titles"
    );

    # Child1 / 1.html
    my $child1 = $root->nodes->[0];

    is( $child1->uri, "${server_host}1.html",
        "child1->uri is correct"
    );
    is($child1->id, '0:0', "child1->id is correct");
    is($child1->title, 'Child1', "child1->title is correct");
    is scalar @{$child1->nodes}, 1, 'child1 has one direct node';
    isnt($_->uri->as_string, $_->loc->as_string,
        "child11 node ". $_->id ." is a redirect"
    ) for $child1->children;
    is_deeply(
        [ map { $_->uri->as_string } $child1->children ],
        [ map { "$server_host$_" } qw( 11.html ) ],
        "child1 has correct nodes mapped"
    );
    is_deeply(
        [ map { $_->id } $child1->children ],
        [ qw( 0:0:0 ) ],
        "child1 nodes have correct ids"
    );
    is_deeply(
        [ map { $_->title } $child1->children ],
        [ qw( FriendlyUrl ) ],
        "child1 nodes have correct titles"
    );
    is( $root->find_node( URI->new("${server_host}12.html") ), undef,
        "child12 (12.html) was not followed"
    );

    # Child11 / 11.html > friendly_url.html
    my $child11 = $child1->nodes->[0];

    is( $child11->uri, "${server_host}11.html",
        "child11->uri is correct"
    );
    is( $child11->loc, "${server_host}friendly_url.html",
        "child11->loc points to redirected location"
    );
    is($child11->id, '0:0:0', "child11->id is correct");
    is($child11->title, 'FriendlyUrl', "child11->title is correct");
    is scalar @{$child11->nodes}, 1, 'child11 has one direct node';
    is_deeply(
        [ map { $_->uri->as_string } $child11->children ],
        [ map { $_->loc->as_string } $child11->children ],
        "child1 nodes have loc() same as uri()"
    );

    is_deeply(
        [ map { $_->uri->as_string } $child11->children ],
        [ map { "$server_host$_" } qw( 3.html ) ],
        "child11 has correct nodes mapped"
    );
    is_deeply(
        [ map { $_->id } $child11->children ],
        [ qw( 0:0:0:0 ) ],
        "child11 nodes have correct ids"
    );
    is_deeply(
        [ map { $_->title } $child11->children ],
        [ qw( Child3 ) ],
        "child11 nodes have correct titles"
    );
    is( $root->find_node( URI->new("${server_host}12.html") ), undef,
        "child112 (12.html) was not followed"
    );

    # Child3 / 3.html
    my $child3 = $child11->nodes->[0];

    is( $child3->uri, "${server_host}3.html",
        "child3->uri is correct"
    );
    is($child3->id, '0:0:0:0', "child3->id is correct");
    is($child3->title, 'Child3', "child3->title is correct");
    is scalar @{$child3->nodes}, 2, 'child3 has two direct nodes';
    is_deeply(
        [ map { $_->uri->as_string } $child3->children ],
        [ map { "$server_host$_" } qw( 31.html 32.html ) ],
        "child3 has correct nodes mapped"
    );
    is_deeply(
        [ map { $_->uri->as_string } $child3->children ],
        [ map { $_->loc->as_string } $child3->children ],
        "child3 nodes have loc() same as uri()"
    );
    is_deeply(
        [ map { $_->id } $child3->children ],
        [ qw( 0:0:0:0:0 0:0:0:0:1 ) ],
        "child3 nodes have correct ids"
    );
    is_deeply(
        [ map { $_->title } $child3->children ],
        [ qw( Child31 Dziecię32 ) ],
        "child3 nodes have correct titles"
    );

    # Child31 / 31.html
    my $child31 = $child3->nodes->[0];

    is( $child31->uri, "${server_host}31.html",
        "child31->uri is correct"
    );
    is($child31->id, '0:0:0:0:0', "child31->id is correct");
    is($child31->title, 'Child31', "child31->title is correct");
    is scalar @{$child31->nodes}, 0, 'child31 has no nodes';

    # Child32 / 32.html
    my $child32 = $child3->nodes->[1];

    is( $child32->uri, "${server_host}32.html",
        "child32->uri is correct"
    );
    is($child32->id, '0:0:0:0:1', "child32->id is correct");
    is($child32->title, 'Dziecię32', "child32->title is correct");
    is scalar @{$child32->nodes}, 0, 'child32 has no nodes';

    # Child2 / 2.html
    my $child2 = $root->nodes->[1];

    is( $child2->uri, "${server_host}2.html",
        "child2->uri is correct"
    );
    is($child2->id, '0:1', "child2->id is correct");
    is($child2->title, 'Child2', "child2->title is correct");
    is scalar @{$child2->nodes}, 2, 'child2 has two direct nodes';
    is_deeply(
        [ map { $_->uri->as_string } $child2->children ],
        [ map { $_->loc->as_string } $child2->children ],
        "child2 nodes have loc() same as uri()"
    );
    is_deeply(
        [ map { $_->uri->as_string } $child2->children ],
        [ map { "$server_host$_" } qw( 21.html 22.html ) ],
        "child2 has correct nodes mapped"
    );
    is_deeply(
        [ map { $_->id } $child2->children ],
        [ qw( 0:1:0 0:1:1 ) ],
        "child2 nodes have correct ids"
    );
    is_deeply(
        [ map { $_->title } $child2->children ],
        [ qw( Child21 Child22 ) ],
        "child2 nodes have correct titles"
    );

    # child21 / 21.html
    my $child21 = $child2->nodes->[0];

    is( $child21->uri, "${server_host}21.html",
        "child21->uri is correct"
    );
    is($child21->id, '0:1:0', "child21->id is correct");
    is($child21->title, 'Child21', "child21->title is correct");
    is scalar @{$child21->nodes}, 0, 'child21 has no nodes';

    # child21 / 22.html
    my $child22 = $child2->nodes->[1];

    is( $child22->uri, "${server_host}22.html",
        "child22->uri is correct"
    );
    is($child22->id, '0:1:1', "child22->id is correct");
    is($child22->title, 'Child22', "child22->title is correct");
    is scalar @{$child22->nodes}, 0, 'child22 has no nodes';


    # txt_sitemap
    my $txt_sitemap;
    my $_txt_sitemap;
    lives_ok {
        $txt_sitemap = $mapper->txt_sitemap();
    } "txt_sitemap() called successfully";
    {
        local $/;
        open( FILE, "t/data/sitemap.txt" )
            or die "Cannot open sitemap.txt: $!\n";
        $_txt_sitemap = <FILE>;
        close( FILE );
    }
    strip_host_from_sitemap( \$txt_sitemap );
    is( $txt_sitemap, $_txt_sitemap, "txt_sitemap() is created correctly" );

    lives_ok {
        $txt_sitemap = $mapper->txt_sitemap(with_id => 1);
    } "txt_sitemap() called successfully";
    {
        local $/;
        open( FILE, "t/data/sitemap_with_id.txt" )
            or die "Cannot open sitemap_with_id.txt: $!\n";
        $_txt_sitemap = <FILE>;
        close( FILE );
    }
    strip_host_from_sitemap( \$txt_sitemap );
    is( $txt_sitemap, $_txt_sitemap,
        "txt_sitemap(with_id) is created correctly"
    );

    lives_ok {
        $txt_sitemap = $mapper->txt_sitemap(with_id => 1, with_title => 1);
    } "txt_sitemap() called successfully";
    {
        local $/;
        open( FILE, "<:utf8", "t/data/sitemap_with_id_with_title.txt" )
            or die "Cannot open sitemap_with_id_with_title.txt: $!\n";
        $_txt_sitemap = <FILE>;
        close( FILE );
    }
    strip_host_from_sitemap( \$txt_sitemap );
    is( $txt_sitemap, $_txt_sitemap,
        "txt_sitemap(with_id, with_title) is created correctly"
    );

    my $html_sitemap;
    my $_html_sitemap;
    lives_ok {
        $html_sitemap = $mapper->html_sitemap();
    } "html_sitemap() called successfully";
    {
        local $/;
        open( FILE, "<:utf8", "t/data/html_sitemap.html" )
            or die "Cannot open html_sitemap.html: $!\n";
        $_html_sitemap = <FILE>;
        close( FILE );
    }
    strip_host_from_sitemap( \$html_sitemap );
    is( $html_sitemap, $_html_sitemap,
        "html_sitemap() is created correctly"
    );

    my $xml_sitemap;
    my $_xml_sitemap;
    lives_ok {
        $xml_sitemap = $mapper->xml_sitemap->as_xml->toString(0);
    } "xml_sitemap() called successfully";
    do {
        my $url = sprintf(
            '<url>'.
                '<loc>%s</loc>'.
                '<lastmod>%s</lastmod>'.
                '<changefreq>%s</changefreq>'.
                '<priority>%s</priority>'.
            '</url>',
            $$_->loc, $W3C_DATETIME, 'weekly', '0.5'
        );
        like( $xml_sitemap,
            qr/$url/,
            "node ". $$_->id ." is correct in XML sitemap"
        );
    } for sort { $$a->id cmp $$b->id } $mapper->tree->all_entries;

    lives_ok {
        $xml_sitemap = $mapper->xml_sitemap(
            priority => '-0.2',
            changefreq => 'daily',
        )->as_xml->toString(0);
    } "xml_sitemap(priority=>scalar, changefreq=>scalar) called successfully";
    do {
        my $url = sprintf(
            '<url>'.
                '<loc>%s</loc>'.
                '<lastmod>%s</lastmod>'.
                '<changefreq>%s</changefreq>'.
                '<priority>%s</priority>'.
            '</url>',
            $$_->loc, $W3C_DATETIME, 'daily', '0.3'
        );
        like( $xml_sitemap,
            qr/$url/,
            "node ". $$_->id ." is correct in XML sitemap"
        );
    } for sort { $$a->id cmp $$b->id } $mapper->tree->all_entries;


    lives_ok {
        $xml_sitemap = $mapper->xml_sitemap(
            priority => {
                '3\d?\.html' => '0.8',
                '\.pdf$' => '0.2',
            },
            changefreq => {
                '3\d?\.html' => 'always',
                '\.pdf$' => 'never',
            },
        )->as_xml->toString(0);
    } "xml_sitemap(priority=>{re}, changefreq=>{re}) called successfully";
    do {
        my @opts = $$_->loc =~ /3\d?\.html/ ?
            ( 'always', '0.8' )
            :
            ( 'weekly', '0.5' );
        my $url = sprintf(
            '<url>'.
                '<loc>%s</loc>'.
                '<lastmod>%s</lastmod>'.
                '<changefreq>%s</changefreq>'.
                '<priority>%s</priority>'.
            '</url>',
            $$_->loc, $W3C_DATETIME, @opts
        );
        like( $xml_sitemap,
            qr/$url/,
            "node ". $$_->id ." is correct in XML sitemap"
        );
    } for sort { $$a->id cmp $$b->id } $mapper->tree->all_entries;

    lives_ok {
        $xml_sitemap = $mapper->xml_sitemap(
            priority => [
                { '1.html$' => '0.8' },
                { '^/2'     => '0.2' },
            ],
            changefreq => [
                { '1.html$' => 'always' },
                { '^/2'     => 'never' },
            ],
        )->as_xml->toString(0);
    } "xml_sitemap(priority=>[re], changefreq=>[re]) called successfully";
    do {
        my @opts = $$_->loc =~ m{/2} ?
            ( 'never', '0.2' )
            :
            (
                $$_->loc =~ /1.html$/ ?
                ( 'always', '0.8' )
                :
                ( 'weekly', '0.5' )
            );
        my $url = sprintf(
            '<url>'.
                '<loc>%s</loc>'.
                '<lastmod>%s</lastmod>'.
                '<changefreq>%s</changefreq>'.
                '<priority>%s</priority>'.
            '</url>',
            $$_->loc, $W3C_DATETIME, @opts
        );
        like( $xml_sitemap,
            qr/$url/,
            "node ". $$_->id ." is correct in XML sitemap"
        );
    } for sort { $$a->id cmp $$b->id } $mapper->tree->all_entries;

    is_deeply(
        $mapper->url_parents,
        {
            '/2.html' => {
                '/2.html'            => 1,
                '/index.html'        => 1,
                '/31.html'           => 1,
                '/3.html'            => 1,
                '/1.html'            => 1,
                '/32.html'           => 1,
                '/21.html'           => 1,
                '/friendly_url.html' => 1,
                '/22.html'           => 1
            },
            '/11.html' => { '/1.html' => 1 },
            '/31.html' => {
                '/32.html' => 1,
                '/31.html' => 1,
                '/3.html'  => 1
            },
            '/3.html' => {
                '/32.html'           => 1,
                '/31.html'           => 1,
                '/3.html'            => 1,
                '/friendly_url.html' => 1
            },
            '/1.html' => {
                '/2.html'            => 1,
                '/index.html'        => 1,
                '/31.html'           => 1,
                '/3.html'            => 1,
                '/1.html'            => 1,
                '/32.html'           => 1,
                '/21.html'           => 1,
                '/friendly_url.html' => 1,
                '/22.html'           => 1
            },
            '/32.html' => {
                '/32.html' => 1,
                '/31.html' => 1,
                '/3.html'  => 1
            },
            '/21.html' => {
                '/2.html'  => 1,
                '/21.html' => 1,
                '/22.html' => 1
            },
            '/12.html' => { '/1.html' => 1 },
            '/22.html' => {
                '/2.html'  => 1,
                '/21.html' => 1,
                '/22.html' => 1
            }
        },
        "method modifiers work for Hook'ed methods"
    );

    undef $mapper;

    $mapper = MyWebSite::Map->new(
        site => "${server_host}index.html",
        status_storage => $STATUS_STORAGE_FILE,
    );

    lives_ok {
        $mapper->restore_state();
    } "restore_state() called successfully";

    lives_ok {
        $txt_sitemap = $mapper->txt_sitemap();
    } "txt_sitemap() called successfully";
    {
        local $/;
        open( FILE, "t/data/sitemap.txt" )
            or die "Cannot open sitemap.txt: $!\n";
        $_txt_sitemap = <FILE>;
        close( FILE );
    }
    strip_host_from_sitemap( \$txt_sitemap );
    is( $txt_sitemap, $_txt_sitemap, "txt_sitemap() is restored correctly" );


# test http server
} else {
    while ( my $c = $d->accept ) {
        while ( my $r = $c->get_request ) {
            my $url = $r->uri->path;
            if ( $url eq '/DONE-TESTING' ) {
                exit;
            } elsif ( -e ( my $filepath = "t/data$url" ) ) {
                my $content;
                {
                    local $/;
                    open(FILE, $filepath) or die "Cannot open file: $filepath!";
                    $content = <FILE>;
                    close FILE;
                };
                my $hp = HTML::HeadParser->new;
                $hp->parse( $content );

                if ( my $redirect = $hp->header('Location') ) {
                    $c->send_redirect( $redirect );
                } else {
                    my $response = HTTP::Response->new( HTTP_OK, undef,
                        [
                            'Content-Type' => 'text/html',
                            'Date' => $HTTP_DATE,
                            'Last-Modified' => $HTTP_DATE,
                        ],
                        $content
                    );
                    $c->send_response( $response );
                }
            } else {
                $c->send_error( HTTP_NOT_FOUND );
            }
        }
        $c->close;
        undef( $c );
    }
    $d->shutdown;
};

END {
    if ( $is_test ) {
        shutdown_server();
        unlink $STATUS_STORAGE_FILE;
    }
};

sub shutdown_server {
    my $ua = LWP::UserAgent->new;
    $ua->get( "${server_host}DONE-TESTING" );
};

sub strip_host_from_sitemap {
    my $data = shift;
    (my $host = $server_host) =~ s/^.*?\/\/([^:\/]+).*$/$1/;
    $$data =~ s/$server_host//g;
    $$data =~ s/$host//g;
}

