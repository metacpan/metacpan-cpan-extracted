#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Text::Amuse::Preprocessor::Footnotes;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

muse-check-footnotes.pl - check consistency of footnotes in a muse document

=head1 SYNOPSIS

 muse-check-footnotes.pl file1.muse [ file2.muse, ... ]

Check if the footnote parsing raises errors. No output if everything
is fine, otherwise print a short report.

=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut

my ($verbose, $help);

GetOptions("v|verbose" => \$verbose, # no op
           "h|help" => \$help) or die;

if ($help || !@ARGV) {
    pod2usage("\n");
    exit;
}

foreach my $file (@ARGV) {
    my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $file);
    $pp->process;
    if (my $error = $pp->error) {
        print "$file: found: $error->{footnotes_found} ($error->{footnotes}) references: $error->{references_found} ($error->{references})\n";
        print "Differences between the list of footnotes and references:\n$error->{differences}\n";
    }
}
