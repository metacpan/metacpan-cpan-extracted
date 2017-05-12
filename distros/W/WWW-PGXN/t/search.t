#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 44;
#use Test::More 'no_plan';
use File::Spec::Functions qw(catdir);
use Test::MockModule;
use WWW::PGXN;
use URI::QueryParam;

my $searcher_path;
my %params;
SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
    sub new { $searcher_path = $_[1]; bless {} => shift }
    sub search { shift; %params = @_; return { foo => 1 } };
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'http://api.pgxn.org/' ];

# Make sure the search methods dispatch as they should.
my $fetched_url;
my $mocker = Test::MockModule->new('WWW::PGXN');
$mocker->mock(_fetch => sub {
    $fetched_url = $_[1];
    return { content => '{"foo":"bar"}' };
});
$mocker->mock(_uri_templates => {
    search => URI::Template->new('/search/{in}'),
});

my @query = ( query  => 'whü', offset => 2, limit  => 10 );
# Track types.
for my $in (qw(docs dists extensions users tags)) {
    ok my $res = $pgxn->search(in => $in, @query), "Search in $in";
    is_deeply $res, {foo => 'bar'}, "Should have the $in results";
    is_deeply $fetched_url->query_form_hash, { l => 10, q => 'whü', o => 2 },
        "Should have requested the proper $in URL query form";
    $fetched_url->query_form([]);
    is $fetched_url, "http://api.pgxn.org/search/$in",
        "Should have requested the proper $in URL host and path";
}

# Now make sure that the file system does the right thing.
ok $pgxn->url('file:t/mirror'), 'Set a file: URL';
$mocker->unmock_all;
my $path = catdir qw(t mirror);

for my $in (qw(docs dists extensions users tags)) {
    ok my $res = $pgxn->search(in => $in, @query), "Search via file:/search/${in}s";
    is $searcher_path, $path,
    'The file system path should have been passed to the searcher';
    is_deeply $res, {foo => 1}, "Should have the $in results";
    is_deeply \%params, {in => $in, @query}, "Searcher shoudld have got $in args";
}

# Make sure we get errors for invalid indexes.
local $@;
eval { $pgxn->search };
like $@, qr{\QMissing required "in" parameter to search()},
    'Should get exception for missing "in" param';

eval { $pgxn->search(in => 'ha ha') };
like $@, qr{^Invalid "in" parameter to search\(\); Must be one of:
\* dists
\* docs
\* extensions
\* tags
\* users}, 'Should get exception for invalid "in" param';
