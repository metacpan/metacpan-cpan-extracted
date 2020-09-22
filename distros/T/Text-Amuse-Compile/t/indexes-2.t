#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 1;
use Text::Amuse::Compile;

use Path::Tiny;

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $workingdir = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
my $musefile = $workingdir->child('test.muse');
$musefile->spew_raw(path(qw/t testfile index-mark.muse/)->slurp_raw);

my $c = Text::Amuse::Compile->new(
                                  logger => sub { diag @_ },
                                  tex => 1,
                                  extra => {
                                            format_id => 'c123',
                                            headings => 'chapter_section',
                                           },
                                 );

$c->compile("$musefile");
my $tex  = $workingdir->child('test.tex')->slurp_utf8;

$tex =~ s/\A.*BEGIN(.*)END.*\z/$1/s;
eq_or_diff([ split(/\r?\n/, $tex) ],
           [ split(/\r?\n/, path(qw/t testfile index-mark.expected/)->slurp_utf8) ]);


