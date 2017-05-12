
use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::NoWarnings;
use IO::Zlib;
use IO::File;

BEGIN { use_ok('WWW::Sitemap::XML') };

my $o;

lives_ok {
    $o = WWW::Sitemap::XML->new();
} 'test object created';

lives_ok {
    $o->load( string => _read('t/data/sitemap.xml') );
} 'sitemap.xml loaded';

is scalar $o->urls, 9, "all 9 URLs loaded";

my $wfn = "t/data/sitemap-$$.xml";
lives_ok {
    $o->write( $wfn, my $pretty_print = 1 );
} 'written sitemap.xml via filename';

my $o2;
lives_ok {
    $o2 = WWW::Sitemap::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->urls ], [ $o2->urls ],
    "...and all urls were written";

unlink $wfn;

$wfn = "t/data/sitemap-$$.xml.gz";
lives_ok {
    $o->write( $wfn );
} 'written sitemap.xml.gz via filename';

lives_ok {
    $o2 = WWW::Sitemap::XML->new();
    my $fh = IO::Zlib->new;
    $fh->open($wfn, "rb" );
    $o2->load( IO => $fh );
    $fh->close;
} '...and loaded back';

is_deeply [ $o->urls ], [ $o2->urls ],
    "...and all urls were written";

unlink $wfn;

$wfn = "t/data/sitemap2-$$.xml";
my $fh = IO::File->new( $wfn, "w");
lives_ok {
    $o->write( $fh, my $pretty_print = 1 );
} 'written sitemap.xml via filehandle';
$fh->close;

lives_ok {
    $o2 = WWW::Sitemap::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->urls ], [ $o2->urls ],
    "...and all urls were written";

unlink $wfn;


$wfn = "t/data/sitemap3-$$.xml";
open SITEMAP1, ">", $wfn or die "Cannot open $wfn for writing: $!";
lives_ok {
    $o->write( \*SITEMAP1, my $pretty_print = 1 );
} 'written sitemap.xml via filehandle';
close SITEMAP1;

lives_ok {
    $o2 = WWW::Sitemap::XML->new();
    $o2->load( string => _read($wfn) );
} '...and loaded back';

is_deeply [ $o->urls ], [ $o2->urls ],
    "...and all urls were written";

unlink $wfn;

sub _read {
    local $/;
    open SITEMAP, shift;
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}

