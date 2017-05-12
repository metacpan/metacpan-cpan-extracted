use strict;
use warnings;

use Test::More tests => 17;

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/projects/1234.xml', 'project.xml' );

$ohloh->stash( 'http://www.ohloh.net/projects/1234/contributors.xml',
    'contributors.xml' );

my $project = $ohloh->get_project('foo');

my @contributors = $project->contributors;

is scalar(@contributors) => 1, 'one contributor';

my $c = shift @contributors;

is $c->analysis_id         => 100430,            'analysis_id';
is $c->contributor_id      => 51860,             'contributor_id';
is $c->contributor_name    => 'Yanick Champoux', 'contributor_name';
is $c->account_id          => 12933,             'account_id';
is $c->account_name        => 'Yanick',          'account_name';
is $c->primary_language_id => 8,                 'primary_language';
is $c->primary_language_nice_name => 'Perl', 'primarly_language_nice_name';
is $c->comment_ratio     => '0.0410958904109589',   'comment_ratio';
is $c->first_commit_time => '2008-01-02T21:26:27Z', 'first_commit_time';
is $c->last_commit_time  => '2008-01-03T21:00:03Z', 'last_commit_time';
is $c->man_months        => 1,                      'man_months';
is $c->commits           => 8,                      'commits';
is $c->median_commits    => 8,                      'median_commits';

$ohloh->stash( 'http://www.ohloh.net/accounts/', 'account.xml' );

my $a = $c->account;
isa_ok $a => 'WWW::Ohloh::API::Account', '$c->account';
is $a->name => 'Yanick', 'account name';

like $c->as_xml => qr#<(contributor_fact)>.*?</\1>#, 'as_xml()';

