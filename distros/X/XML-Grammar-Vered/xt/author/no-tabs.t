use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/Grammar/Vered.pm',
    't/00-compile.t',
    't/00-libxml-basic.t',
    't/00-libxslt-basic.t',
    't/data/system-tests-1/expected-docbook/perl-begin-page.docbook.xml',
    't/data/system-tests-1/input-xml/perl-begin-page.xml-grammar-vered.xml',
    't/xslt.t'
);

notabs_ok($_) foreach @files;
done_testing;
