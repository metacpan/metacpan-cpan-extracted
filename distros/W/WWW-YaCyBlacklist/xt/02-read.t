#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 12;

require_ok( 'WWW::YaCyBlacklist' );

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
is( $ycb->_check_host_regex('*.today'), 0, 'domain' );
is( $ycb->_check_host_regex('fritz.box'), 0, 'host' );
is( $ycb->_check_host_regex('\bhsk\d+.*\.\w/.*'), 1, 'regex' );

my $length = $ycb->length;
is( $length, 0, 'no_files' );
$ycb->read_from_array('research.ingram-braun.net/.*','wpdev.ingram-braun.net/.*','links.ingram-braun.net/.*' );
cmp_ok( $ycb->length, '>', $length, 'numerical' );
like( $ycb->length, '/\d{1}/', 'read_from_array' );

my $black1 = 'C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/yacy/default.black';
my $black2 = "C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/yacy/ib-mirrors.black";
$ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
$ycb->read_from_files($black1,$black2);
like( $ycb->length, '/\d{5}/', 'length_like' );

my @urls = (
    'https://finaplus.org/',
    'https://web.de/magazine/gesundheit/fachanwalt-rate-unterschreiben-41041864?utm_source=firefox-newtab-de-de',
    'https://nexulo.buzz/?gad_source=2&gclid=Cj0KCQjwj8jDBhD1ARIsACRV2Tt2D3SGcsAW1Qqnww44mI-8MzensUWGUWEywcDoMQ-jBtSiaq1foN0aAgpxEALw_wcB',
    'https://afuhvn.sbs/xz/?gad_source=2',
    'https://metacpan.org/dist/WWW-YaCyBlacklist',
    'https://search.google.com/search-console/settings/crawl-stats/drilldown?resource_id=https%3A%2F%2Fschach-goettingen.de%2F&response=2&hl=de',
    'https://zarelli-clarkson.com/?sfnsn=scwspmo',
    'https://chesstempo.com/game-database/game/ingram-braun-vs-georg-hildebrand/4081464/87',
    'https://www.msn.com/de-de/unterhaltung/other/block-prozess-gerhard-delling-bekommt-laut-anwalt-keine-auftr%C3%A4ge-mehr/ar-AA1IpAhH',
    'https://theporndude.com/',
    'https://pornmopsfidel.de/',
);
my @matched = $ycb->find_matches( @urls );
my @notmatched = $ycb->find_non_matches( @urls );
is( scalar @matched, 6, 'matched with regex' );
is( scalar @notmatched, 5, 'not matched with regex' );

$ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 0 } );
$ycb->read_from_files($black1,$black2);
@matched = $ycb->find_matches( @urls );
@notmatched = $ycb->find_non_matches( @urls );
is( scalar @matched, 5, 'matched w/o regex' );
is( scalar @notmatched, 6, 'not matched w/o regex' );