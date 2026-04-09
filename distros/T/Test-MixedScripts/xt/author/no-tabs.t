use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/MixedScripts.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all_perl_files_scripts_ok.t',
    't/data/ascii-01.txt',
    't/data/bad-01.txt',
    't/data/bad-02.js',
    't/data/bad-03.txt',
    't/data/good-03.pod',
    't/etc/perlcritic.rc',
    't/file_scripts_ok-Test-More.t',
    't/file_scripts_ok.t',
    't/self.t'
);

notabs_ok($_) foreach @files;
done_testing;
