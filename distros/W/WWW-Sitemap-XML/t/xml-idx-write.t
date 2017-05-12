
use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::NoWarnings;
use IO::Zlib;
use IO::File;

BEGIN { use_ok('WWW::SitemapIndex::XML') };

my $o;

lives_ok {
    $o = WWW::SitemapIndex::XML->new();
} 'test object created';

lives_ok {
    $o->load( string => _read('t/data/sitemapindex.xml') );
} 'sitemapindex.xml loaded';

is scalar $o->sitemaps, 9, "all 9 Sitemaps loaded";

my $wfn = "t/data/sitemapindex-$$.xml";
lives_ok {
    $o->write( $wfn, my $pretty_print = 1 );
} 'written sitemapindex.xml via filename';

my $o2;
lives_ok {
    $o2 = WWW::SitemapIndex::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->sitemaps ], [ $o2->sitemaps ],
    "...and all sitemap indexes were written";

unlink $wfn;

$wfn = "t/data/sitemapindex-$$.xml.gz";
lives_ok {
    $o->write( $wfn );
} 'written sitemapindex.xml.gz via filename';

lives_ok {
    $o2 = WWW::SitemapIndex::XML->new();
    my $fh = IO::Zlib->new;
    $fh->open($wfn, "rb" );
    $o2->load( IO => $fh );
    $fh->close;
} '...and loaded back';

is_deeply [ $o->sitemaps ], [ $o2->sitemaps ],
    "...and all sitemap indexes were written";

unlink $wfn;

$wfn = "t/data/sitemapindex2-$$.xml";
my $fh = IO::File->new( $wfn, "w");
lives_ok {
    $o->write( $fh, my $pretty_print = 1 );
} 'written sitemapindex.xml via filehandle';
$fh->close;

lives_ok {
    $o2 = WWW::SitemapIndex::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->sitemaps ], [ $o2->sitemaps ],
    "...and all sitemap indexes were written";

unlink $wfn;


$wfn = "t/data/sitemapindex3-$$.xml";
open SITEMAPIDX1, ">", $wfn or die "Cannot open $wfn for writing: $!";
lives_ok {
    $o->write( \*SITEMAPIDX1, my $pretty_print = 1 );
} 'written sitemapindex.xml via filehandle';
close SITEMAPIDX1;

lives_ok {
    $o2 = WWW::SitemapIndex::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->sitemaps ], [ $o2->sitemaps ],
    "...and all sitemap indexes were written";

unlink $wfn;

sub _read {
    local $/;
    open SITEMAPIDX, shift;
    my $xml =  <SITEMAPIDX>;
    close SITEMAPIDX;
    return $xml;
}

