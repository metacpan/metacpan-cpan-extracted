#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
);

isa_ok( $feed, 'XML::RSS::Feed' );

my $iterations = 100;
my $title      = "This is a test 1";
my $url        = "http://www.jbisbee.com/test/url/1";
my $des        = "Description number 1";
my $rss        = {
    channel => {
        title => "Channel Title",
        link  => "http://www.google.com/",
    },
    items => [],
};

for my $i ( 1 .. $iterations ) {
    push @{ $rss->{items} },
        {
        headline    => ++$title,
        url         => ++$url,
        description => ++$des,
        };
}

ok( $feed->process(
        $rss->{items},
        $rss->{channel}{title},
        $rss->{channel}{link}
    ),
    "Processing"
);
cmp_ok( $feed->num_headlines, '==', $iterations,
    "Verify num_headlines $iterations" );
cmp_ok( $feed->late_breaking_news, '==', 100, "Verify 100 headlines" );
cmp_ok( $feed->title, 'eq', $rss->{channel}{title}, "Verify feed title" );
cmp_ok( $feed->link,  'eq', $rss->{channel}{link},  "Verify feed link" );
ok( !$feed->process( undef, $rss->{channel}{title}, $rss->{channel}{link} ),
    "Fail to process" );
$feed->title("  ");
cmp_ok(
    $feed->title, 'eq',
    $rss->{channel}{title},
    "title should fail if set as just spaces"
);
