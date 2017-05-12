#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;

my $contextf;
my $help;
my $sent;


my $ok = GetOptions (
		     'context=s' => \$contextf,
		     help => \$help
		     );
$ok or exit 1;

if ($help) {
	print "Usage: sentence_split.pl --context FILE \n";
	print "			| {--help }\n";
	print "Options:\n";
	print "\t--context FILE       a file containing the text to be split\n";
	print "\t--help               show this help message\n";
    exit;
}

unless (defined $contextf) {
    print STDERR "The --context argument is required. This is the text to be split into sentences\n";
    print "Usage: sentence_split.pl --context FILE \n";
    exit 1;
}

open (FH, '<', $contextf) or die "Cannot open '$contextf': $!";
local $/ = undef;
my $string = <FH>;
$string =~ tr/\n/ /;
close FH;

# The sentence boundary algorithm used here is based on one described
# by C. Manning and H. Schutze. 2000. Foundations of Statistical Natural
# Language Processing. MIT Press: 134-135.
# This needs filename as a commandline argument

# abbreviations that (almost) never occur at the end of a sentence
my @known_abbr = qw/prof Prof ph d Ph D dr Dr mr Mr mrs Mrs ms Ms vs/;

# abbreviations that can occur at the end of sentence
my @sometimes_abbr = qw/etc jr Jr sr Sr/;

my $pbm = '<pbound/>'; # putative boundary marker

# put a putative sent. boundary marker after all .?!
$string =~ s/([.?!])/$1$pbm/g;

# move the boundary after quotation marks
$string =~ s/$pbm"/"$pbm/g;
$string =~ s/$pbm'/'$pbm/g;

# remove boundaries after certain abbreviations
foreach my $abbr (@known_abbr) {
$string =~ s/\b$abbr(\W*)$pbm/$abbr$1 /g;
}

foreach my $abbr (@sometimes_abbr) {
$string =~ s/$abbr(\W*)\Q$pbm\E\s*([a-z])/$abbr$1 $2/g;
}
# remove !? boundaries if not followed by uc letter
$string =~ s/([!?])\s*$pbm\s*([a-z])/$1 $2/g;


# all remaining boundaries are real boundaries
my @sentences = map {s/^\s+|\s+$//g; $_} split /[.?!]+\Q$pbm\E/, $string;

foreach $sent(@sentences)
{
	print "$sent\n";
}

=head1 NAME

sentence_split.pl - splits text into sentences

=head1 SYNOPSIS

 sentence_split.pl --context FILE | {--help }

=head1 DESCRIPTION

 Takes a string as an input and outputs one sentence per line

=head1 OPTIONS

=over

=item --context=B<FILE>

 The name of the file which contains text to be split into sentences.  

=back


=head1 SEE ALSO

 L<WordNet::SenseRelate::AllWords>

The main web page for SenseRelate is

 L<http://senserelate.sourceforge.net/>

There are several mailing lists for SenseRelate:

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-users/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-news/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-developers/>

=head1 AUTHORS

 Jason Michelizzi 

 Varada Kolhatkar

 Ted Pedersen, University of Minnesota, Duluth
 E<lt>tpederse at d.umn.eduE<gt>

=head1 BUGS

Please report to senserelate-users mailing list. 

=head1 COPYRIGHT

Copyright (C) 2004-2008 Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
