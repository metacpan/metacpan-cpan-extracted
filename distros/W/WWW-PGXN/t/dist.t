#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 85;
#use Test::More 'no_plan';
use WWW::PGXN;
use File::Spec::Functions qw(catfile);

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get a nonexistent distribution.
ok !$pgxn->get_distribution('nonexistent'),
    'Should get nothing when searching for a nonexistent distribution';

# Fetch distribution data.
ok my $dist = $pgxn->get_distribution('pair'),
    'Find distribution "pair"';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
can_ok $dist => qw(
    new
    abstract
    license
    name
    version
    description
    generated_by
    no_index
    prereqs
    provides
    date
    release_status
    resources
    sha1
    user
    releases
    tags
    maintainers
    special_files
    docs
    versions_for
    version_for
    download_url
    download_path
    source_url
    source_path
    download_to
    body_for_html_doc
    url_for_html_doc
    path_for_html_doc
);
is $dist->{_pgxn}, $pgxn, 'It should contain the WWW::PGXN object';

# Examine the distribution data.
is $dist->name, 'pair', 'Distribution name should be "pair"';
is_deeply $dist->releases, {
    stable =>  [
        {"version" => "0.1.2", "date" => "2010-10-29T22:44:42Z"},
        {"version" => "0.1.0", "date" => "2010-10-19T03:59:54Z"},
    ],
    testing => [{"version" => "0.1.1", "date" => "2010-10-27T23:12:51Z"}],
}, 'Releases should be correct';
is $dist->version_for('stable'), '0.1.2', 'Should have proper stable version';
is $dist->version_for('testing'), '0.1.1', 'Should have proper testing version';
is $dist->version_for('unstable'), undef, 'Should have no unstable version';

is $dist->date_for('stable'), '2010-10-29T22:44:42Z', 'Should have proper stable date';
is $dist->date_for('testing'), '2010-10-27T23:12:51Z', 'Should have proper testing date';
is $dist->date_for('unstable'), undef, 'Should have no unstable date';

is_deeply [$dist->versions_for('stable')], [qw(0.1.2 0.1.0)],
    'Should have stable versions';
is_deeply [ $dist->versions_for('testing') ], [qw(0.1.1)],
  'Should have testing versions';
is_deeply [ $dist->versions_for('unstable') ], [],
  'Should have no unstable versions';

##############################################################################
# Now find for a particular version number.
ok $dist = $pgxn->get_distribution('pair' => '0.1.2'),
    'Find pair 0.1.2';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
is $dist->name, 'pair', 'Name should be "pair"';
is $dist->version, '0.1.2', 'Version should be "0.1.2"';
is $dist->abstract, 'A key/value pair dåtå type', 'Should have abstrct';
is $dist->description, 'This library contains a single PostgreSQL extension called `pair`.',
    'Should have description';
is $dist->date, '2010-11-10T12:18:03Z', 'Should have release date';
is $dist->release_status, 'stable', 'Should have release status';
is $dist->user, 'theory', 'Should have user';
is $dist->license, 'postgresql', 'Should have license';
is $dist->sha1, 'cebefd23151b4b797239646f7ae045b03d028fcf', 'Should have SHA1';
is_deeply [$dist->maintainers], ['David E. Wheeler <david@justatheory.com>'],
    'Should have maintainers';
is_deeply [$dist->tags], ['ordered pair', 'pair', 'key value'],
    'Should have tags';
is_deeply [$dist->special_files], ["Changes","Makefile","README.md","META.json"],
    'Should have special files';
is $dist->generated_by, undef, 'generated_by should be undef';
is_deeply $dist->no_index, {}, 'Should have empty no-index';
is_deeply $dist->prereqs, {}, 'Should have empty prereqs';
is_deeply $dist->provides, {
    pair => {
         abstract => 'A key/value pair dåtå type',
         file => 'sql/pair.sql',
         version => '0.1.2'
      }
}, 'Should have provides';

is_deeply $dist->resources, {
    bugtracker => {
        web => 'http://github.com/theory/kv-pair/issues/'
    },
    repository => {
        type => 'git',
        url => 'git://github.com/theory/kv-pair.git',
        web => 'http://github.com/theory/kv-pair/'
    }
}, 'Should have resources';

##############################################################################
# Have a look at the docs in 0.1.1.
ok $dist = $pgxn->get_distribution('pair' => '0.1.1'),
    'Find pair 0.1.1';
is_deeply $dist->docs, {
    'README'   => { title => 'pair 0.1.1' },
    'doc/pair' => { title => 'pair', abstract => 'A key/value pair data type' }
}, 'Should have docs hash';

ok my $doc = $dist->body_for_html_doc('README'),
    'Fetch the README body';

# Contents should be the decoded HTML.
is $doc, do {
    my $fn = catfile qw(t mirror dist pair 0.1.1 README.html);
    open my $fh, '<:encoding(utf-8)', $fn or die "Cannot open $fn: $!\n";
    local $/;
    <$fh>;
}, 'Should have the encoded contents of the file';

# Do the same for the doc.
ok $doc = $dist->body_for_html_doc('doc/pair'),
    'Fetch the doc/pair body';
is $doc, do {
    my $fn = catfile qw(t mirror dist pair 0.1.1 doc pair.html);
    open my $fh, '<:encoding(utf-8)', $fn or die "Cannot open $fn: $!\n";
    local $/;
    <$fh>;
}, 'Should have the encoded contents of the doc/pair file';

is $dist->url_for_html_doc('README'), 'file:t/mirror/dist/pair/0.1.1/README.html',
    'Should have README URL';
is $dist->url_for_html_doc('doc/pair'), 'file:t/mirror/dist/pair/0.1.1/doc/pair.html',
    'Should have doc/pair URL';
is $dist->path_for_html_doc('README'), '/dist/pair/0.1.1/README.html',
    'Should have README path';
is $dist->path_for_html_doc('doc/pair'), '/dist/pair/0.1.1/doc/pair.html',
    'Should have doc/pair path';
is $dist->path_for_html_doc('doc/nonexistent'), undef,
    'Should get undef for nonexistent path';

# Make sure we have no errors if there's no doc URI template.
delete $pgxn->_uri_templates->{htmldoc};
is $dist->body_for_html_doc('README'), undef,
    'Should get no errors when no doc URI template';
is $dist->url_for_html_doc('README'), undef, 'Should again have no README URL';
is $dist->path_for_html_doc('README'), undef,
    'Should again have no README path';

ok $dist = $pgxn->get_distribution('pair'), 'Find current pair (0.1.2)';
is_deeply $dist->docs, {
    'README'   => { title => 'pair 0.1.2' },
    'doc/pair' => { title => 'pair', abstract => 'A key/value pair data type' }
}, 'Should have 0.1.2 merged docs hash';

# Should get nothing for 0.1.0.
ok $dist = $pgxn->get_distribution('pair' => '0.1.0'),
    'Find pair 0.1.0';
is_deeply $dist->docs, {}, 'Should have no docs';
is $dist->body_for_html_doc('README'), undef, 'Should have no README.html';
is $dist->body_for_html_doc('doc/pair'), undef, 'Should have no doc/pair.html';
is $dist->url_for_html_doc('README'), undef, 'Should have no README URL';
is $dist->path_for_html_doc('README'), undef,
    'Should have no README path';

##############################################################################
# Test merging.
ok $dist = $pgxn->get_distribution('pair'),
    'Find "pair" again';
ok $dist->_merge_meta, 'Merge distmeta';

is $dist->version_for('stable'), '0.1.2', 'Should have proper stable version';
is $dist->version, '0.1.2', 'Version should be "0.1.2"';

ok $dist = $pgxn->get_distribution('pair' => '0.1.2'),
    'Find "pair" 0.1.2 again';
ok $dist->_merge_by_dist, 'Merge dist';
is $dist->version_for('stable'), '0.1.2', 'Should have proper stable version';
is $dist->version, '0.1.2', 'Version should be "0.1.2"';

# Test implicit merging.
ok $dist = $pgxn->get_distribution( 'pair'),
    'Find "pair" once more';
is $dist->version_for('stable'), '0.1.2', 'Should have proper stable version';
is $dist->version, '0.1.2', 'Version should be "0.1.2"';

ok $dist = $pgxn->get_distribution('pair' => '0.1.2'),
    'Find "pair" 0.1.2 once more';
is $dist->version_for('stable'), '0.1.2', 'Should have proper stable version';
is $dist->version, '0.1.2', 'Version should be "0.1.2"';

##############################################################################
# Test other methods.
ok $dist = $pgxn->get_distribution('pair' => '0.1.1'),
    'Find pair 1.0.1';

is $dist->download_url, 'file:t/mirror/dist/pair/0.1.1/pair-0.1.1.zip',
    'Should have donload URL';
is $dist->download_path, '/dist/pair/0.1.1/pair-0.1.1.zip',
    'Should have download path';

# Check source URLs.
is $dist->source_url, 'file:t/mirror/src/pair/pair-0.1.1/','Should have source URL';
is $dist->source_path, '/src/pair/pair-0.1.1/','Should have source path';

# They should be undef if no "source" template.
delete $pgxn->_uri_templates->{source};
is $dist->source_url, undef, 'Should have no source URL when no tmplate';
is $dist->source_path, undef, 'Should have no source path when no tmplate';

# Download to a file.
my $zip = catfile qw(t my-pair-0.1.1.zip);
ok !-e $zip, "$zip should not yet exist";
END { unlink $zip }
is $dist->download_to($zip), $zip, "Download to $zip";
ok -e $zip, "$zip should now exist";

# Download to a directory.
my $pgz = catfile qw(t pair-0.1.1.zip);
ok !-e $pgz, "$pgz should not yet exist";
END { unlink $pgz }
is $dist->download_to('t'), $pgz, 'Download to t/';
ok -e $pgz, "$pgz should now exist";
