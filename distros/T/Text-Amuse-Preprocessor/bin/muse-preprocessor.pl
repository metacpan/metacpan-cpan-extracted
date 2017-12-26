#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor;
use Getopt::Long;
use Data::Dumper;
use File::Temp qw//;
use File::Spec;
use File::Copy qw/move copy/;

my ($fix_links, $fix_typography, $fix_nbsp, $remove_nbsp, $show_nbsp,
    $fix_footnotes, $inplace, $help);

GetOptions (
            links => \$fix_links,
            typography => \$fix_typography,
            nbsp => \$fix_nbsp,
            'remove-nbsp' => \$remove_nbsp,
            'show-nbsp' => \$show_nbsp,
            footnotes => \$fix_footnotes,
            inplace => \$inplace,
            help => \$help,
           ) or die;

if ($help or !@ARGV) {
    pod2usage("Using Text::Amuse::Preprocessor version " .
              $Text::Amuse::Preprocessor::VERSION . "\n");
    exit;
}

=head1 NAME

muse-preprocessor.pl -- fix your muse document

=head1 SYNOPSIS

 muse-preprocessor.pl [ options ] inputfile.muse [ outputfile.muse ]

The input file is processed according to the options and the output is
left in the output file. Both arguments are mandatory, unless
--inplace is specified.

Options:

=over 4

=item links

Makes all the links active

=item typography

Apply typographical fixes according to the language of the document

=item nbsp

Add non-breaking spaces according to the language of the document (if
applicable).

=item remove-nbsp

Unconditionally remove all the invisible non-breaking spaces

=item show-nbsp

Make the (usually) invisible non-breaking spaces explicit with a
double tilde.

=item footnotes

Rearrange the footnotes.

=item inplace

Overwrite the original file.

=item help

Show this help and exit.

=back

=cut

my ($infile, $outfile) = @ARGV;

die "$infile is not a file\n" unless -f $infile;

my $wd;

if ($inplace) {
    die "--inplace and a second argument are mutually exclusive" if $outfile;
    $wd = File::Temp->newdir;
    $outfile = File::Spec->catfile($wd, 'out.muse');
}
elsif (!$outfile) {
    die "Missing outfile and --inplace was not specified!\n";
}

my $pp = Text::Amuse::Preprocessor->new(
                                        fix_links      => $fix_links,
                                        fix_nbsp       => $fix_nbsp,
                                        remove_nbsp    => $remove_nbsp,
                                        show_nbsp      => $show_nbsp,
                                        fix_footnotes  => $fix_footnotes,
                                        fix_typography => $fix_typography,
                                        input => $infile,
                                        output => $outfile,
                                       );
if ($pp->process) {
    if ($inplace) {
        my $backup = $infile . '.' . time() . '~';
        copy($infile, $backup) or die "Cannot copy $infile to $backup $!";
        print "Saved backup of $infile in $backup\n";
        move($outfile, $infile) or die "Cannot move $outfile to $infile $!";
    }
}
else {
    die Dumper($pp->error);
}
