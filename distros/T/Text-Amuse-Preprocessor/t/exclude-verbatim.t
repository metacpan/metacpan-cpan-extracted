#!perl

use utf8;
use strict;
use warnings;

use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Preprocessor;

use Test::More tests => 2;
use Data::Dumper;
use File::Temp;

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}
my $wd = File::Temp->newdir(CLEANUP => 1);
my $infile = catfile(qw/t footnotes verbatim-in.muse/);
my $expected = catfile(qw/t footnotes verbatim-exp.muse/);
my $outfile = catfile($wd, 'verbatim-in.muse');
  
my $pp = Text::Amuse::Preprocessor->new(
                                        fix_links      => 1,
                                        fix_footnotes  => 1,
                                        fix_typography => 1,
                                        input => $infile,
                                        output => $outfile,
                                        debug => 1,
                                       );

ok($pp->process, "Process ok") or die Dumper($pp->error);

eq_or_diff(_read_file($outfile), _read_file($expected));
diag $wd;
  
sub _read_file {
    my $file = shift;
    my @in;
    open (my $fh, '<:encoding(utf-8)', $file) or die "Couldn't read $file";
    while (my $l = <$fh>) {
        push @in, $l;
    }
    close $fh;
    return join('', @in);
}
