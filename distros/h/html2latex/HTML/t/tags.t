#!/usr/bin/perl -w
use Latex;
use strict;

my @files = qw(t/tags);
my $parser = new HTML::Latex;

print '1..',scalar @files,"\n";

foreach my $file (@files){
    $parser->set_log("/dev/null");

    my ($htmlfile,$latexfile) = $parser->html2latex("$file.html") or die "Couldn't process $file.html";

    print "not " if (!(-f $latexfile) || `diff $latexfile $file.correct`);
    print "ok\n";
}

unlink <*.tex>;
