use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/XML/Grammar/Vered.pm',
    't/00-compile.t',
    't/00-libxml-basic.t',
    't/00-libxslt-basic.t',
    't/data/system-tests-1/expected-docbook/perl-begin-page.docbook.xml',
    't/data/system-tests-1/input-xml/perl-begin-page.xml-grammar-vered.xml',
    't/xslt.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
