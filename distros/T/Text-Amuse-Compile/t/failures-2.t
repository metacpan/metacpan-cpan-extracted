#!/usr/bin/env perl

BEGIN {
    $ENV{AMW_DEBUG} = 1;
}

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec;
use Text::Amuse::Compile::Utils qw/append_file read_file write_file/;
use Test::More;
use File::Temp;
use Cwd;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    diag "Using (Xe|Lua)LaTeX for testing";
    plan tests => 4;
}
else {
    plan skip_all => "No TEST_WITH_LATEX env found! skipping tests\n";
    exit;
}

my $wd = File::Temp->newdir;

for my $luatex (0..1) {
    my $logfile = File::Spec->rel2abs(File::Spec->catfile($wd,
                                                          'for-multipar-footnotes.logging.' . $luatex ));
    diag "Logging in $logfile";
    unlink $logfile if -f $logfile;
    my $c = Text::Amuse::Compile->new(
                                      pdf => 1,
                                      luatex => $luatex,
                                      cleanup => 0,
                                      logger => sub { append_file($logfile, @_) },
                                      report_failure_sub => sub { diag @_ },
                                     );
    $c->compile(File::Spec->catfile('t', 'testfile', 'for-multipar-footnotes.muse'));
    my $body = read_file(File::Spec->catfile('t', 'testfile', 'for-multipar-footnotes.tex'));
    $body =~ s/endgraf/par/g;
    write_file(File::Spec->catfile('t', 'testfile', 'for-multipar-footnotes.tex'), $body);

    $c->compile(File::Spec->catfile('t', 'testfile', 'for-multipar-footnotes.muse'));
    my $logs = read_file($logfile);
    like $logs, qr{аргументацией};
    like $logs, qr{It is possible that you have a multiparagraph footnote};
}
