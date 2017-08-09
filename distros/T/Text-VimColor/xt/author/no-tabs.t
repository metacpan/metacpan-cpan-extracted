use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/text-vimcolor',
    'lib/Text/VimColor.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000-vim-version.t',
    't/all-syntax-groups.t',
    't/ansi.t',
    't/bin.t',
    't/compare-formats.t',
    't/encoding.t',
    't/html.t',
    't/input_filename.t',
    't/lib/TVC_Share.pm',
    't/lib/TVC_Test.pm',
    't/new.t',
    't/override-options.t',
    't/share-dir.t',
    't/tvctestsyn.t',
    't/untie-std-handles.t',
    't/vim_let.t',
    't/vim_options.t',
    't/xml.t'
);

notabs_ok($_) foreach @files;
done_testing;
