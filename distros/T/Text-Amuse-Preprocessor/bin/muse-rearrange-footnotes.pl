#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor::Footnotes;
use Getopt::Long;
use File::Copy qw/move/;

=head1 NAME

muse-rearrange-footnotes.pl - fix the footnote numbering in a muse document

=head1 DESCRIPTION

This script takes an arbitrary number of files as argument, and
rearrange the footnotes numbering, barfing if the footnotes found in
the body don't match the footnotes themselves. This is handy if you
inserted footnotes at random position, or if the footnotes are
numbered by section or chapter.

The only thing that matters is the B<order>.

Example input file content:

  This [1] is a text [1] with three footnotes [4]

  [1] first
  
  [1] second
  
  [2] third


Output in file with C<.fixed> extension:

  This [1] is a text [2] with three footnotes [3]

  [1] first
  
  [2] second
  
  [3] third
  
The original file is overwritten if the option --overwrite is provided.

=head1 SYNOPSIS

  muse-rearrange-footnotes.pl [ --overwrite ] file.muse

If the flag overwrite is not passed, the output will be left in
file.muse.fixed, otherwise the file is modified in place.

=head1 SEE ALSO

L<Text::Amuse::Preprocessor::Footnotes>

L<Text::Amuse::Preprocessor>

=cut

my ($overwrite, $help);

GetOptions(overwrite => \$overwrite,
           help => \$help) or die;

if ($help || !@ARGV) {
    pod2usage("\n");
    exit;
}

foreach my $file (@ARGV) {
    my $output = $file . ".fixed";
    my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $file,
                                                       output => $output);
    $pp->process;
    if (my $error = $pp->error) {
        print "Error $file: found footnotes: $error->{footnotes} "
          . "($error->{footnotes_found})\n"
            . "found references: $error->{references} "
              . "($error->{references_found})\n\n";
        print "Differences between the list of footnotes and references:\n$error->{differences}\n";
        next;
    }
    elsif (! -f $output) {
        die "$output not produced, this shouldn't happen!\n";
    }
    if ($overwrite) {
        move $output, $file or die "Cannot move $output into $file: $!";
    }
    else {
        print "Output left in $output\n";
    }
}


