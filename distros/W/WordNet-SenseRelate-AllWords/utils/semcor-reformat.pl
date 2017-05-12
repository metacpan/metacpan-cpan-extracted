#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec;
use WordNet::QueryData;

our $key = 0;
our $semcor_dir;
our $file;
our $version;
our $help;

my $res = GetOptions (key => \$key, "semcor=s" => \$semcor_dir,
		      "file" => \$file, version => \$version, help => \$help );
unless ($res) {
    showUsage();
    exit 1;
}

if ($help) {
    showUsage("Long");
    exit;
}

if ($version) {
    print "semcor-reformat.pl - Reformat SemCor sense tagged files for use by wsd.pl\n";
    print 'Last modified by : $Id: semcor-reformat.pl,v 1.17 2009/05/22 19:16:38 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $semcor_dir or defined $file) {
    showUsage();
    exit 2;
}

if ($semcor_dir) {
    unless (-e $semcor_dir) {
	print STDERR "Invalid directory '$semcor_dir'\n";
	showUsage();
	exit 3;
    }
}

my $wn = WordNet::QueryData->new;
my $datapath = $wn->dataPath;

unless (open IDXFH, '<', "$datapath/index.sense") {
    open IDXFH, '<', "$datapath/sense.idx" or die "Cannot open index file: #!";
}

sub wf_handler;
sub punc_handler;
sub p_handler;
sub s_handler;
sub context_handler;

my %posLetter = (1 => 'n',
		 2 => 'v',
		 3 => 'a',
		 4 => 'r',
		 5 => 'a');

my %posMap = (JJ =>   'a',
	      OD =>   'a',
	      JJR =>  'a',
	      JJT =>  'a',
              JJS =>  'a',
	      CD =>   'a',
	      RB =>   'r',
	      RBR =>  'r',
	      RBT =>  'r',
              RBS =>  'r',
	      RP =>   'r',
	      WRB =>  'r',
	      WQL=>   'r',
	      QL =>   'r',
	      QLP =>  'r',
	      RN =>   'r',
	      NN =>   'n',
	      NNS =>  'n',
	      NNP =>  'n',
	      NP =>   'n',
	      NPS =>  'n',
	      NR =>   'n',
	      NRS =>  'n',
	      VB  =>  'v',
	      VBD =>  'v',
	      VBG =>  'v',
	      VBN =>  'v',
	      VBZ =>  'v',
	      VBS =>  'v',
	      VBP =>  'v',
	      DO =>   'v',
	      DOD=>   'v',
	      DOZ=>   'v',
	      HV =>   'v',
	      HVD =>  'v',
	      HVG =>  'v',
	      HVN =>  'v',
	      HVZ =>  'v',
	      BE  =>  'v',
	      BED =>  'v',
	      BEDZ => 'v',
	      BEG =>  'v',
	      BEN =>  'v',
	      BEZ =>  'v',
	      BEM =>  'v',
	      BER =>  'v',
	      MD =>   'v');

my $flag = 1;

my %handlers = (contextfile => sub {}, # ignore this tag
		p => \&p_handler,
                s => \&s_handler,
                context => \&context_handler,
                wf => \&wf_handler,
                punc => \&punc_handler,
                );

# some global variables modified by the handler functions
my $paragraph_number = 0;
my $sentence_number = 0;
my $context_filename = File::Spec->devnull; #'/dev/null';
my $wordnum = 0;
# input file

my @files;
if ($semcor_dir) {
    # get the files we are going to process
    my $gpattern = File::Spec->catdir ($semcor_dir, 'brown1', 'tagfiles');
    $gpattern = File::Spec->catdir ($gpattern, 'br-*');
    @files = glob ($gpattern);
    $gpattern = File::Spec->catdir ($semcor_dir, 'brown2', 'tagfiles');
    $gpattern = File::Spec->catdir ($gpattern, 'br-*');
    push @files, glob ($gpattern);
}
else {
    @files = @ARGV;

    unless (scalar @files) {
	print STDERR "No input files specified\n";
	exit 4;
    }

    foreach my $f (@files) {
        unless (-e $f) {
	    print STDERR "File '$f' does not exist\n";
	    exit 5;
        }
    }
}


foreach my $f (@files) {
    processFile ($f)
}

exit;

sub processFile
{
    my $infile = shift;
    open (FH, '<', $infile) or die "Cannot open $infile: $!";

    local $/ = undef;

    my $file = <FH>;

    # silly hack
    $file =~ s/<punc>([^<>]+)<\/punc>/<punc type=\"$1\" \/>/g;

#    while ($file =~ /<((?:\"[^\"]*\"|\'[^\']*\'|[^\'\">])*)>/g) {
    while ($file =~ /<([^>]+)>/g) {
	processTag ($1);
    }

    close FH;
}


sub processTag
{
    my $tag = shift;
    my $close_tag = 0;

    $tag =~ m|^(/)?(\w+)(.*)|;

    if ($1) {
	$close_tag = 1;
    }

    my $name = $2;
    unless (defined $name) {
	print STDERR "Nameless tag: '$tag'\n";
	return;
    }


    my $attrs_string = $3;

    my %attrs;

    while ($attrs_string =~ /(\w+)=(\S+|\"[^\"]+\")/g) {
	my $a = $1;
	my $val = $2;
	
	if (substr ($val, 0, 1) eq '"') {
	    $val = substr ($val, 1, length ($val) - 2);
	}

	$attrs{$a} = $val;

    }
    $handlers{$name} ($close_tag, %attrs);
}


sub punc_handler
{
    my $close_tag = shift;
    return if $close_tag;
    return if $key;

    my %attrs = @_;
    if ($attrs{type}) {
	if ($attrs{type} eq '.') {
	    print "\n";
	}
	elsif ($attrs{type} eq ';') {
	    print "\n";
	}
	elsif ($attrs{type} eq '!') {
	    print "\n";
	}
	elsif ($attrs{type} eq '?') {
	    print "\n";
	}
	else {
	    # do nothing
	}
    }
}

sub wf_handler
{
    my $close_tag = shift;
    my $cnt=0;
    return if $close_tag;

    my %attrs = @_;

    return unless $attrs{cmd} eq 'done';
    return unless defined $attrs{lemma};
    warn "no pos for $." unless $attrs{pos};
	
    return if $attrs{wnsn} eq '0'; # drop words that wordnet doesn't have

    if (index ($attrs{wnsn}, ';') < $[) {
	return if $attrs{wnsn} < 0; # more words that wordnet doesn't have
    }

    $flag = 0;

    my @lexsns = split /;/, $attrs{lexsn};
    my @wnsns = split /;/, $attrs{wnsn};

    my @wps;
    foreach my $i (0..$#lexsns) {
	# filter out unknown senses
	next unless length $lexsns[$i] > 1;

	#my ($w, $p, $s) = getWPS ($attrs{lemma}, $lexsns[$i]);
	my ($w, $p, $s) = getWPS ($attrs{lemma}, $lexsns[$i], $wnsns[$i]);
	push @wps, [$w, $p, $s];
    }

    if (scalar @wps < 1) {
	return; # no valid senses
    }

    $wps[0]->[0]=lc($wps[0]->[0]);
#   replacing .s with .a. Treating adjective satellite as simple adjectives

    if($wps[0]->[1] eq "s")
	{
	    $wps[0]->[1] = "a";
	}

    if ($key) {
	#print $context_filename, '.', $paragraph_number, '.', $sentence_number;
	#print ' ';
	
	print $wps[0]->[0], '.', $wps[0]->[1], ' ';
	print ++$wordnum;
	foreach my $rwps (@wps) {
	    print ' ', $rwps->[2];
	}
	print "\n";

#	print $attrs{lemma}, '.', $posMap{$attrs{pos}}, ' ';
#	print ++$wordnum, ' ';

#	# When we generate a key, we want to show the sense number.  When
#	# we generate input to WordNet-SenseRelate, then we don't want a
#	# sense number.
#	my @wnsenses = split /;/, $attrs{wnsn};
#	print join ' ', @wnsenses;
#	#print $attrs{wnsn} if defined $attrs{wnsn};

#	print "\n";
    }
    else {
	print $wps[0]->[0], '#', $wps[0]->[1], ' ';
#	print $attrs{lemma};

#	if (defined $attrs{pos}) {
#	    my $pos = $posMap{$attrs{pos}};
#	    if (defined $pos) {
#		print '#', $pos;
#	    }
#	    else {
#		print '#', $attrs{pos};
#	    }
#	}
#	print ' ';
    }
}

sub p_handler
{
    my $close_tag = shift;
    return if $close_tag;

    my %attrs = @_;

    return unless defined $attrs{pnum};

    $paragraph_number = $attrs{pnum} + 0;
}

sub s_handler
{
    my $close_tag = shift;
    return if $close_tag;

    my %attrs = @_;

    return unless defined $attrs{snum};

    $sentence_number = $attrs{snum} + 0;
}

sub context_handler
{
    my $close_tag = shift;
    return if $close_tag;

    my %attrs = @_;

    return unless defined $attrs{filename};

    $context_filename = $attrs{filename};  
}

sub getWPS
{
    my $lemma = shift;
    my $lexsn = shift;
    my $wnsn = shift;
    my $synset_type = substr $lexsn, 0, 1;
    my $pos = $posLetter{$synset_type};

    my ($sense) = "$lemma#$pos#$wnsn";

    # don't use synonyms instead of the surface form of the text
#   ($sense) = $wn->querySense ("$lemma#$pos#$wnsn", "syns"); 
    my ($w, $p, $s) = split /\#/, $sense;
    return ($w, $p, $s);
}
	
sub showUsage
{
   my $long = shift;
   print "Usage: semcor-reformat.pl {--semcor DIR | --file FILE [FILE ...]} [--key]\n";
   print "                          | {--help | --version}\n";
	

    if ($long) 
    {
    print <<'EOU';
Options:
   --semcor         name of directory containing Semcor
   --file           one or more semcor-formatted files
   --key            generate a key for scoring purposes from the input
   --help           show this help message
   --version        show version information

EOU
}
}


__END__

=head1 NAME

semcor-reformat.pl - Reformat SemCor sense tagged files for use by wsd.pl

=head1 SYNOPSIS

 semcor-reformat.pl {--semcor DIR | --file FILE [FILE ...]} [--key] 

=head1 EXAMPLE

 semcor-reformat.pl --semcor ~/semcor2.0

=head1 DESCRIPTION

This script reads a SemCor-formatted file and produces formatted
text that can be used as input to wsd.pl.  Alternatively, if the
--key option is specified, the output will also include the sense
number for each work, and this output can be used as a key file.

There are a few sources of data that are SemCor formatted, including
SemCor itself and the Senseval-2 and Senseval-3 all words data sets.
They have been made available for download by Rada Mihalcea:

L<http://www.cs.unt.edu/~rada/downloads.html>

Only the words that are assigned valid sense numbers will be
passed through this program.  All other words are discarded.
This means that only open-class words that appear in WordNet
will be passed through.  Closed class words (pronouns, conjuctions,
etc.) and other words not appearing in WordNet are discarded.

head1 OPTIONS

=over

=item --semcor=B<DIRECTORY>

The location of the SemCor directory.  This directory will contain
several sub-directories, including 'brown1' and 'brown2'.  Do
not specify these sub-directories.  Only specify the directory name
that contains them.  For example, if /home/user/semcor2.0 contains
the brown1 and brown2 directories, you would only specify
/home/user/semcor2.0 as the value of this option.  Do not use this
option at the same time as the --file option.

=item --file=B<FILE>

A semcor-formatted file to process.  This can be used instead of the
previous option to only specify a few Semcor files or to specify
Senseval files.  When this option is used, multiple files can be
specified on the command line.  For example

 semcor-reformat.pl --file br-a01 br-a02 br-k18 br-m02 br-r05

Do not attempt to use this option when using the previous option.

=item --key

Generates a key file for use by the allwords-scorer2.pl program instead of a file
that can be used for wsd.pl.  The allwords-scorer2.pl program can be used to measure
the performance of a word sense disambiguation program.  See the documentation
for scorer2-format.pl and allwords-scorer2.pl for more information.

=back

=head1 AUTHORS

 Jason Michelizzi

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: semcor-reformat.pl,v 1.17 2009/05/22 19:16:38 kvarada Exp $

=head1 SEE ALSO

 L<wsd-experiments.pl> L<scorer2-format.pl> L<scorer2-sort.pl> L<allwords-scorer2.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.
