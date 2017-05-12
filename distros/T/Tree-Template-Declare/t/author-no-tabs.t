
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Tree/Template/Declare.pm',
    'lib/Tree/Template/Declare/DAG_Node.pm',
    'lib/Tree/Template/Declare/HTML_Element.pm',
    'lib/Tree/Template/Declare/LibXML.pm',
    't/01-basic.t',
    't/02-xslt.t',
    't/03-html.t',
    't/04-xml.t',
    't/05-mixed.t',
    't/06-code.t',
    't/07-inherit.t'
);

notabs_ok($_) foreach @files;
done_testing;
