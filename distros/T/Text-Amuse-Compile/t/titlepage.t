#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Copy qw/move/;
use File::Basename qw/basename/;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my $pdf = !!$ENV{TEST_WITH_LATEX};

my $targetdir = File::Spec->catdir(qw/t titlepages/);
opendir (my $dh, $targetdir) or die "Cannot open $targetdir $!";
my @files = map { File::Spec->catfile($targetdir, $_) }
  grep { /\.muse$/ and -f File::Spec->catfile($targetdir, $_)  } readdir($dh);
closedir $dh;

my $tests = 62;

if ($pdf) {
    plan tests => $tests + (scalar(@files) * 2);
}
else {
    plan tests => $tests;
}






for my $coverpage (0, 1) {
    my $c = Text::Amuse::Compile->new(tex => 1,
                                      pdf => $pdf,
                                      extra => { nocoverpage => !$coverpage });
    for my $file (@files) {
        $c->compile($file);
        my $basename = $file;
        $basename =~ s/\.muse$//;
        my $outtex = $basename . '.tex';
        my $outpdf = $basename . '.pdf';
        ok (-f $outtex, "$outtex is fine");
        if ($pdf) {
            ok (-f $outpdf, "$outpdf is fine");
            move($outpdf, $outpdf . ($coverpage ? '.cp' : '.nc') . '.pdf');
        }
        my $body = read_file($outtex);
        my @fields = split(/-/, basename($basename));
        for my $f (@fields) {
            like($body, qr{usekomafont\{\Q$f\E\}.*\Q$f\E}, "Found komafont $f in the body");
        }
        if ($coverpage) {
            like($body, qr{titlepage}, "Found the titlepage");
        }
        else {
            unlike($body, qr{titlepage}, "Found the titlepage");
        }

        my $expected = $file;
        if ($coverpage) {
            
        }
    }
}

unless ($ENV{NO_CLEANUP}) {
    opendir (my $dh, $targetdir) or die "Cannot open $targetdir $!";
    my @files = map { File::Spec->catfile($targetdir, $_) }
      grep { -f File::Spec->catfile($targetdir, $_) } readdir($dh);
    closedir $dh;
    foreach my $file (@files) {
        if ($file !~ m/\.muse/) {
            unlink $file;
        }
    }
}
