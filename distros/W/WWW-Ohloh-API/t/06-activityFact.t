use strict;
use warnings;

use Test::More tests => 14;    # last test to print

use List::MoreUtils qw/ all /;
require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash(
    'http://www.ohloh.net/projects/123/analyses/10/activity_facts.xml',
    'activityFact.xml', );

my $facts = $ohloh->get_activity_facts(10);

my @f = $facts->all;

is scalar(@f)    => 70, 'all()';
is $facts->total => 70, 'total()';
print grep { !$_->isa('WWW::Ohloh::API::ActivityFact') } @f;
ok 0 + ( all { $_->isa('WWW::Ohloh::API::ActivityFact') } @f ),
  'returns W:O:A:ActivityFact';

my $f = $facts->latest;
ok $f->isa('WWW::Ohloh::API::ActivityFact'), 'latest()';

like $f->month          => qr/2008-01/, 'month()';
is $f->code_added       => 3078,        'code_added()';
is $f->code_removed     => 1555,        'code_removed()';
is $f->comments_added   => 985,         "comments_added()";
is $f->comments_removed => 282,         "comments_removed()";
is $f->blanks_removed   => 98,          "blanks_removed()";
is $f->blanks_added     => 486,         "blanks_added()";
is $f->commits          => 51,          "commits()";
is $f->contributors     => 3,           "contributors()";

like $facts->as_xml,
  qr#<(activity_facts)>(<(activity_fact)>.*?</\3>)+</\1>#, "as_xml()";

