#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 36;
#use Test::More 'no_plan';
use File::Spec::Functions qw(catfile);
use utf8;

my $CLASS;
BEGIN {
    $CLASS = 'WWW::PGXN';
    use_ok $CLASS or die;
}

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

my $pgxn = new_ok $CLASS, [ url => 'http://api.pgxn.org/' ];
is $pgxn->url, 'http://api.pgxn.org', 'Should have the URL';
is $pgxn->proxy, undef, 'Should have no proxy';

##############################################################################
# Test the request object.
isa_ok $pgxn->_request, 'HTTP::Tiny', 'The request object';

# Switch to local files.
ok $pgxn->url('file:t/mirror'), 'Switch to local mirror';
isa_ok my $req = $pgxn->_request, 'WWW::PGXN::FileReq', 'The request object';

##############################################################################
# Test FileReq.
ok my $res = $req->get(URI->new('file:t/nonexistent.txt')),
    'Fetch nonexisent file';
is_deeply $res, {
    success => 0,
    status  => 404,
    reason  => 'not found',
    headers => {},
}, 'Should have "not found" response';

my $f = catfile qw(t mirror index.json);
open my $fh, '<:raw', $f or die "Cannot open $f: $!\n";
my $json = do {
    local $/;
    <$fh>;
};
close $fh;

ok $res = $req->get(URI->new('file:t/mirror/index.json')),
    'Fetch mirror/index.json';
is_deeply $res, {
    success => 1,
    status  => 200,
    reason  => 'OK',
    content => $json,
    headers => {},
}, 'Should have the content response';

##############################################################################
# Test the templates. Start with a bogus URL.
$pgxn->url('file:t');
local $@;
eval { $pgxn->_uri_templates };
like $@, qr{Request for file:t/index\.json failed: 404: not found},
    'Should get exception for bad templates URL';

# Now get the real thing.
$pgxn->url('file:t/mirror');
ok my $tmpl =  $pgxn->_uri_templates, 'Get the URI templates';
my $data = JSON->new->utf8->decode($json);
is_deeply $tmpl, { map { $_ => URI::Template->new($data->{$_}) } keys %{ $data } },
    'Should have all the templates';

##############################################################################
# Test url formatting.
is $pgxn->_url_for(dist => {dist => 'pair'}),
    'file:t/mirror/dist/pair.json',
    '_url_for() should work';

local $@;
eval { $pgxn->_url_for('nonexistent') };
like $@, qr{No URI template named "nonexistent"},
    'Should get error for nonexistent URI template';

##############################################################################
# Test url generation methods.
is $pgxn->meta_url_for('pair', '1.2.0'),
    'file:t/mirror/dist/pair/1.2.0/META.json',
    'meta_url_for() shuld work';

is $pgxn->download_url_for('pair', '1.2.0'),
    'file:t/mirror/dist/pair/1.2.0/pair-1.2.0.zip',
    'download_url_for() shuld work';

is $pgxn->source_url_for('pair', '1.2.0'),
    'file:t/mirror/src/pair/pair-1.2.0/',
    'source_url_for() shuld work';

is $pgxn->tag_url_for('whatever'),
    'file:t/mirror/tag/whatever.json',
    'tag_url_for() should work';

is $pgxn->extension_url_for('explanation'),
    'file:t/mirror/extension/explanation.json',
    'extension_url_for() should work';

is $pgxn->user_url_for('theory'),
    'file:t/mirror/user/theory.json',
    'user_url_for() should work';

is $pgxn->html_doc_url_for('pair', '0.1.2', 'doc/foo'),
    'file:t/mirror/dist/pair/0.1.2/doc/foo.html',
    'html_doc_url_for() should work';

is $pgxn->meta_path_for('pair', '1.2.0'),
    '/dist/pair/1.2.0/META.json',
    'meta_path_for() shuld work';

is $pgxn->download_path_for('pair', '1.2.0'),
    '/dist/pair/1.2.0/pair-1.2.0.zip',
    'download_path_for() shuld work';

is $pgxn->source_path_for('pair', '1.2.0'),
    '/src/pair/pair-1.2.0/',
    'source_path_for() shuld work';

is $pgxn->tag_path_for('whatever'),
    '/tag/whatever.json',
    'tag_path_for() should work';

is $pgxn->extension_path_for('explanation'),
    '/extension/explanation.json',
    'extension_path_for() should work';

is $pgxn->user_path_for('theory'),
    '/user/theory.json',
    'user_path_for() should work';

is $pgxn->html_doc_path_for('pair', '0.1.2', 'doc/foo'),
    '/dist/pair/0.1.2/doc/foo.html',
    'html_doc_path_for() should work';

##############################################################################
# Test spec fetching.
ok my $spec = $pgxn->spec, 'Get spec';
like $spec, qr{PGXN Meta Spec - The PGXN distribution metadatå specification$}m,
    'It should look like the text file';
ok $spec = $pgxn->spec('txt'), 'Get text spec';
like $spec, qr{PGXN Meta Spec - The PGXN distribution metadatå specification$}m,
    'It should look like the text file';
ok $spec = $pgxn->spec('html'), 'Get HTML spec';
like $spec, qr{<p>PGXN Meta Spec - The PGXN distribution metadatå specification</p>$}m,
    'It should look like the HTML file';
