#!/usr/local/bin/perl

my $Version = '0.03';

use strict;
use warnings;

use WordNet::SenseRelate::WordToSet;
use WordNet::QueryData;
use Getopt::Long;

my $measure = 'WordNet::Similarity::lesk';
my $trace = 0;
my $config;
my $version;
my $help;

my $res = GetOptions ("type|measure=s" => \$measure,
		      "trace=i" => \$trace,
		      "config=s" => \$config,
		      "version" => \$version,
		      "help" => \$help,
		      );

unless ($res) {
    showUsage();
    exit 1;
}

if ($version) {
    print "wordtoset.pl version ", $Version, "\n";
    print "Copyright (C) 2005-2008, Ted Pedersen and Jason Michelizzi\n";
    print "This is free software, and you are welcome to redistribute it\n";
    print "under certain conditions.  This software comes with ABSOLUTELY\n";
    print "NO WARRANTY.  See the file GPL.txt for more information.\n";
    exit;
}

if ($help) {
    showUsage("Long");
    exit;
}

my $target = shift;
my @context = @ARGV;
unless (defined $target and scalar @context) {
    unless (defined $target) {
	print STDERR "Error: no words were specified on command line!\n";
    }
    else {
	print STDERR "Error: no context words specified on command line!\n";
    }
    showUsage();
    exit 1;
}

my $qd = WordNet::QueryData->new;

# set up the options
my %options = (wordnet => $qd,
               measure => $measure,
	      );
$options{trace} = $trace if $trace;
$options{config} = $config if $config;

my $wts = WordNet::SenseRelate::WordToSet->new (%options);

my $result = $wts->disambiguate (target => $target,
				      context => [@context]);

for my $key (sort {$result->{$b} <=> $result->{$a}} keys %$result) {
  print $key, ' : ', $result->{$key},' : ', 
	$qd -> querySense($key,'glos'), , "\n\n";
}

if ($trace) {
    my $tstr = $wts->getTrace ();
    print "Traces:\n", $tstr, "\n";
}

sub showUsage
{
    my $long = shift;
    print "Usage: wordtoset.pl targetword contextword1 [contextword2 ...]\n";
    print "       [--type MEASURE] [--config FILE] [--trace LEVEL]\n";
    print "       [--help] [--version]\n";

    if ($long) {
	print "  --type MEASURE   WordNet::Similarity measure\n";
	print "  --config FILE    Configuration file for measure\n";
	print "  --trace LEVEL    Turn tracing on/off\n";
	print "  --help           Show this help message\n";
	print "  --version        Show version information\n";
        print "You may also run 'perldoc' on this script for more details\n";
    }
}

__END__

=head1 NAME

wordtoset.pl - Command line interface to WordNet-SenseRelate-WordToSet

=head1 SYNOPSIS

 wordtoset.pl bank money cash dollars loans --type WordNet::Similarity::res

 wordtoset.pl bank river shore fish swim --type WordNet::Similarilarity::res

 wordtoset.pl target context1 [context2 ...] [--type MEASURE] [--trace INT]
 [--config FILE] | --help | --version

=head1 DESCRIPTION

wordtoset.pl determines which sense of a word is most related to a given 
set of words. It outputs the sum of the similarity of relatedness scores  
of the first word (the target) to the highest scoring sense of each of 
the words in the set. 

=head1 PARAMETERS & OPTIONS

=over

=item target

The target word to assign a sense to (or disambiguate)

=item context1 [context2...]

A list of words to use as context for disambiguating the target word. 
The order of the context words does not matter. The first word is 
automatically the target word, and all the remaining words are the set 
to be compared to.

=item --type B<MEASURE>

The name of a WordNet::Similarity measure.  The default is
WordNet::Similarity::lesk.

=item --trace B<INTEGER>

Turn tracing on/off.  A value of zero turns tracing off, and a non-zero
value turns tracing on.  By default, tracing is off.  The trace levels
are:

  1 show non-zero scores from the semantic relatedness measure

  2 show zero & undefined scores from the relatedness measure (no
    effect unless combined with level 1)

  4 show traces from the semantic relatedness measure

The trace levels can be combined by adding together different levels.
For example, to show non-zero scores and the traces from the relatedness
measure, use level 5.

=item --config B<FILE>

The name of a configuration file for the specified semantic relatedness
measure.  See the documentation for the specific WordNet::Similarity
measure you are using to learn more about the format of a config file.

=item --version

Show version information.

=item --help

Show detailed help message.

=back

=head1 SEE ALSO

 L<http://senserelate.sourceforge.net/>

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Jason Michelizzi 

Last modified by : 
$Id: wordtoset.pl,v 1.4 2008/04/07 03:35:51 tpederse Exp $

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (C) 2005-2008 Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
