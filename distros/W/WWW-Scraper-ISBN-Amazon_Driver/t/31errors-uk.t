#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use WWW::Scraper::ISBN;
use Data::Dumper;
use Test::MockModule;

###########################################################

my $uri;
my $ok = 1;

my $mock = Test::MockModule->new('WWW::Mechanize');
$mock->mock( 'get'     => sub {
    my ( $self, $url ) = @_;
    $uri = $url;
    $ok = 0 if($uri =~ /0201795264/);    # site failure
    $ok = 1 if($uri =~ /9780672320675/); # site content failure
    $ok = 0 if($uri =~ /dp.9781408307557/); # site link failure
    $ok = 1 if($uri =~ /9781408307557/); # site search ok

    $ok = 1 if($uri =~ /1444738623/); # site search ok
    $ok = 1 if($uri =~ /9781444738629/); # site search not ok
    return;
} );
$mock->mock( 'uri'     => sub { return $uri; } );
$mock->mock( 'success' => sub { return $ok; } );
$mock->mock( 'content' => sub {
    return 'xxx' if($uri =~ /9780672320675/); # site content failure
    return 'xxx http://www.amazon.co.uk/xxx/dp/9781408307557/ref=sr_1_1/ xxx' if($uri =~ /9781408307557/); # link failure
    return 'xxx http://www.amazon.co.uk/xxx/dp/9781444738629/ref=sr_1_1/ xxx' if($uri =~ /1444738623/); # link failure
    return;
} );

###########################################################

my $DRIVER          = 'AmazonUK';

my %tests = (
    '0201795264'    => { error => qr/website appears to be unavailable/ },
    '9780672320675' => { error => qr/Failed to find that book/ },
    '9781408307557' => { error => qr/Could not extract data/ },
    '1444738623'    => { error => qr/website appears to be unavailable/ },
);

###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
    $scraper->drivers($DRIVER);

    for my $isbn (keys %tests) {
        my $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        like( $error, $tests{$isbn}->{error}, "matched expected error for $isbn" );

    }
}

