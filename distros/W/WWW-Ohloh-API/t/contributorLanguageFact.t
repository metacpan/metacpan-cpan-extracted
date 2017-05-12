use strict;
use warnings;

use Test::More tests => 11;

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/projects/1234/contributors.xml',
    'contributor_language_facts.xml' );

my @facts = $ohloh->get_contributor_language_facts( 
    project_id => 1,
    contributor_id => 1,
);

is scalar(@facts) => 7, 'seven fact';

my $c = shift @facts;

is $c->analysis_id         => 112122,            'analysis_id';
is $c->contributor_id      => 13498,             'contributor_id';
is $c->contributor_name    => 'wrowe', 'contributor_name';
is $c->language_id => 7,                 'primary_language';
is $c->language_nice_name => 'C/C++', 'primarly_language_nice_name';
is $c->comment_ratio     => '0.180879765395894',   'comment_ratio';
is $c->man_months        => 66,                      'man_months';
is $c->commits           => 1177,                      'commits';
is $c->median_commits    => 9,                      'median_commits';

like $c->as_xml => qr#<(contributor_language_fact)>.*?</\1>#, 'as_xml()';

