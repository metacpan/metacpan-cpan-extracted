#!perl -w
use strict;

use File::Touch;
use Test::More tests => 7;
use Test::Deep;

use_ok('XML::LibXSLT::Cache');

my $cache = new_ok('XML::LibXSLT::Cache');
my $filename = 't/xsl/master.xsl';
my $import_filename = 't/xsl/import.xsl';
my $time = time;

my $ref = File::Touch->new(mtime => $time - 3600, no_create => 1);
$ref->touch($import_filename);

my $stylesheet = $cache->parse_stylesheet_file($filename);

my $cached_rec = $cache->{cache}{$filename};
isa_ok($cached_rec, 'ARRAY');

my ($cached_ss, $deps) = @$cached_rec;
is(int($cached_ss), int($stylesheet), 'cached stylesheet');

my $number = re(qr/^\d+\z/);
my $attrs = [ $number, $number ];
cmp_deeply($deps, {
    $filename                   => $attrs,
    $import_filename            => $attrs,
    't/xsl/import_import.xsl'   => $attrs,
    't/xsl/import_include.xsl'  => $attrs,
    't/xsl/include.xsl'         => $attrs,
    't/xsl/include_import.xsl'  => $attrs,
    't/xsl/include_include.xsl' => $attrs,
}, 'dependencies');

$cached_ss = $cache->parse_stylesheet_file($filename);
is($cached_ss, $stylesheet, 'cached stylesheet');

$ref = File::Touch->new(mtime => $time, no_create => 1);
$ref->touch($import_filename);

my $new_ss = $cache->parse_stylesheet_file($filename);
isnt(int($new_ss), int($stylesheet), 'new stylesheet');

