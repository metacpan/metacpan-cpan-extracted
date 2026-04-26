use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'XS.c',
    'XS.xs',
    'lib/Text/Minify/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-minify.t',
    't/02-minify_utf8.t',
    't/03-minify_ascii.t',
    't/04-undef.t',
    't/10-overflow.t',
    't/author-leaks.t',
    't/author-ppport.t',
    't/author-xs-check.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
