use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/SemanticDiff.pm',
    'lib/XML/SemanticDiff/BasicHandler.pm',
    't/00-compile.t',
    't/01basic.t',
    't/02load_xml.t',
    't/03simple_compare.t',
    't/04namespaces.t',
    't/05simple_handler.t',
    't/06pass_to_handler.t',
    't/07pitest.t',
    't/08nonexist_ns.t',
    't/09two-tags.t',
    't/10wide-chars.t',
    't/11tag-in-different-locations.t',
    't/12missing-element-has-o-as-cdata.t',
    't/13to-doc-read.t',
    't/14ignore_xpath.t',
    't/15ignore_multi.t',
    't/style-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
