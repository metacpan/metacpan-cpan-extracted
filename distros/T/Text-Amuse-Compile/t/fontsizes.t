#!perl

use strict;
use warnings;
use Test::More tests => 12;
use File::Spec;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file/;
use Text::Amuse::Compile::TemplateOptions;

foreach my $font_size (Text::Amuse::Compile::TemplateOptions->all_fontsizes) {
    my $c = Text::Amuse::Compile->new(tex => 1, pdf => $ENV{TEST_WITH_LATEX},
                                      extra => { fontsize => $font_size });
    my $file = File::Spec->catfile(qw/t manual br-in-footnotes.muse/);
    $c->compile($file);
    my $pdf = my $tex = $file;
    $pdf =~ s/\.muse$/\.pdf/;
    $tex =~ s/\.muse$/\.tex/;
    like (read_file($tex), qr{fontsize=\Q$font_size\E}, "TeX ok with font size $font_size");
  SKIP: {
        skip "no pdf required", 1 unless $ENV{TEST_WITH_LATEX};
        ok (-f $pdf, "$pdf produced with size $font_size");
        unlink $pdf or die "Cannot unlink $pdf";
    }
    unlink $tex or die "Cannot unlink $tex";
}
