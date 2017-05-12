package Text::Similarity;

use 5.006;
use strict;
use warnings;

use constant COMPFILE => "compfile";
use constant STEM     => "stem";
use constant VERBOSE  => "verbose";
use constant STOPLIST => "stoplist";
use constant NORMALIZE => "normalize";

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.13';

# Attributes -- these all have lvalue accessor methods, use those methods
# instead of accessing directly.  If you add another attribute, be sure
# to take the appropriate action in the DESTROY method; otherwise, a memory
# leak could occur.

my %errorString;
my %compounds;
my %verbose;
my %stem;
my %normalize;
my %stoplist;

sub new
{
    my $class = shift;
    my $hash_ref = shift;
    $class = ref $class || $class;
    my $self = bless [], $class;

    if (defined $hash_ref) {
	while (my ($key, $val) = each %$hash_ref) {
	    if (($key eq COMPFILE) and (defined $val)) {
		$self->_loadCompounds ($val);
	    }
	    elsif ($key eq STEM) {
		$self->stem = $val;
	    }
	    elsif ($key eq VERBOSE) {
		$self->verbose = $val;
	    }
	    elsif ($key eq NORMALIZE) {
		$self->normalize = $val;
	    }
	    elsif ($key eq STOPLIST) {
		$self->stoplist = $val;
	    }
	    else {
		$self->error ("Unknown option: $key");
	    }
	}
    }
    return $self;
}

sub DESTROY
{
    my $self = shift;
    delete $errorString{$self};
    delete $compounds{$self};
    delete $stem{$self};
    delete $verbose{$self};
    delete $normalize{$self};
    delete $stoplist{$self};
}

#sub _loadStoplist
#{
#    my $self = shift;
#    my $file = shift;
#
#    unless (open FH, '<', $file) {
#	$self->error ("Cannot open '$file': $!");
#	return undef;
#    }
#
#    while (<FH>) {
#	chomp;
#	my $word = lc;
#	$stoplist{$self}->{$word} = 1;
#    }
#
#    close FH;
#}

sub error
{
    my $self = shift;
    my $msg = shift;
    if ($msg) {
	my ($package, $file, $line) = caller;
	$errorString{$self} .= "\n" if $errorString{$self};
	$errorString{$self} .= "($file:$line) $msg";
    }
    return $errorString{$self};
}

sub verbose : lvalue
{
    my $self = shift;
    $verbose{$self}
}

sub stem : lvalue
{
    my $self = shift;
    $stem{$self}
}

sub normalize : lvalue
{
    my $self = shift;
    $normalize{$self}
}

sub sanitizeString
{
    my $self = shift;
    my $str = shift;

    # get rid of most punctuation
    $str =~ tr/.;:,?!(){}\x22\x60\x24\x25\x40<>/ /s;

    # convert to lower case
    $str =~ tr/A-Z_/a-z /;

    # convert ampersands into 'and' -- maybe not appropriate?
    # s/\&/ and /;

    # get rid of apostrophes not surrounded by word characters
    $str =~ s/(?<!\w)\x27/ /g;
    $str =~ s/\x27(?!\w)/ /g;

    # get rid of dashes, but not hyphens
    $str =~ s/--/ /g;

    # collapse consecutive whitespace chars into one space
    $str =~ s/\s+/ /g;
    return $str;
}

sub stoplist : lvalue
{
    my $self = shift;
    $stoplist{$self}
}

sub _loadCompounds
{
    my $self = shift;
    my $compfile = shift;

    unless (open FH, '<', $compfile) {
	$self->error ("Cannot open '$compfile': $!");
	return undef;
    }
    
    while (<FH>) {
	chomp;
	$compounds{$self}{$_} = 1;
    }

    close FH;
}

sub removeStopWords
{
    my $self = shift;
    my $str = shift;
    foreach my $stopword (keys %{$self->stoplist}) {
	$str =~ s/\Q $stopword \E/ /g;
    }
    return $str;
}

# compoundifies a block of text
# e.g., if you give it "we have a new bird dog", you'll get back
# "we have a new bird_dog".
# (code borrowed from rawtextFreq.pl)

sub compoundify
{
    my $self = shift;
    my $block = shift; # get the block of text
    my $done;
    my $temp;

    unless ($compounds{$self}) {
	return $block;
    }

    # get all the words into an array
    my @wordsArray = $block =~ /(\w+)/g;

    # now compoundify, GREEDILY!!
    my $firstPtr = 0;
    my $string = "";

    while($firstPtr <= $#wordsArray)
    {
        my $secondPtr = $#wordsArray;
        $done = 0;
        while($secondPtr > $firstPtr && !$done)
        {
            $temp = join ("_", @wordsArray[$firstPtr..$secondPtr]);
            if(exists $compounds{$self}{$temp})
            {
                $string .= "$temp ";
                $done = 1;
            }
            else
            {
                $secondPtr--;
            }
        }
        if(!$done)
        {
            $string .= "$wordsArray[$firstPtr] ";
        }
        $firstPtr = $secondPtr + 1;
    }
    $string =~ s/ $//;

    return $string;
}



1;

__END__

=head1 NAME

Text::Similarity - Measure the pair-wise Similarity of Files or Strings 

=head1 SYNOPSIS

      # this will return an un-normalized score that just gives the
      # number of overlaps by default (or F1 if normalize is set),
      # plus a hash table of other scores, with the following keys
      #	'wc1', 'wc2', 'raw', 'precision', 'recall', 'F', 'dice', 'E', 'cosine', 'raw_lesk','lesk'
      # wc1 and wc2 are respective word counts; see Overlaps.pm for definitions of other scores

      use Text::Similarity::Overlaps;
      my $mod = Text::Similarity::Overlaps->new;
      defined $mod or die "Construction of Text::Similarity::Overlaps failed";

      # adjust file names to reflect true relative position
      # these paths are valid from lib/Text/Similarity
      my $text_file1 = 'Overlaps.pm';
      my $text_file2 = '../OverlapFinder.pm';

      my $score = $mod->getSimilarity ($text_file1, $text_file2);
      print "The similarity of $text_file1 and $text_file2 is : $score\n";

      my ($score1, %allScores) = $mod->getSimilarity ($text_file1, $text_file2);
      print "The raw similarity of $text_file1 and $text_file2 is : $allScores{'raw'}\n";
      print "The lesk score of $text_file1 and $text_file2 is : $allScores{'lesk'}\n";


      # if you want to turn on the verbose options and provide a stoplist
      # you can pass those parameters to Overlaps.pm via hash arguments

      # the verbose option causes extra scores to be printed to STDERR

      use Text::Similarity::Overlaps;
      my %options = ('verbose' => 1, 'stoplist' => '../../samples/stoplist.txt');

      my $mod = Text::Similarity::Overlaps->new (\%options);
      defined $mod or die "Construction of Text::Similarity::Overlaps failed";

      # adjust file names to reflect true relative position
      # these paths are valid from lib/Text/Similarity
      my $text_file1 = 'Overlaps.pm';
      my $text_file2 = '../OverlapFinder.pm';
     
      my ($score, %allScores) = $mod->getSimilarity ($text_file1, $text_file2);
      print "The raw similarity of $text_file1 and $text_file2 is : $allScores{'raw'}\n";
      print "The lesk score of $text_file1 and $text_file2 is : $allScores{'lesk'}\n";

=head1 DESCRIPTION

This module is a superclass for other modules and provides generic 
services such as stop word removal, compound identification, and text 
cleaning or sanitizing. 

It's important to realize that additional methods of measuring 
similarity can be added to this package. Text::Similarity::Overlaps is 
just one possible way of measuring similarity, others can be added. 

Subroutine sanitizeString carries out text cleaning. Briefly, it removes 
nearly all punctuation except for underscores and embedded apostrophes, 
converts all text to lower case, and collapes multiple white spaces to 
a single space. 

This module is where compounds are identified (although currently 
disabled). When implemented it will check a list of compounds provided 
by the user, and then when a compound is found in the text it will be 
desigated via an underscore (e.g., white house might be converted to 
white_house).

Stop words are removed here. The length of the documents reported does 
not include the stop words. Overlaps are found after stopword removal. 
By including a word in the stoplist, you are saying that the word never 
existed in your input (in effect).

=head1 BUGS

=over

=item * 
Compoundify and stemming currently not supported.

=item * 
Granularity option in getSimilarity not supported.

=item * 
Cleaning should probably be optional. 

=back

=head1 SEE ALSO

L<http://text-similarity.sourceforge.net> 

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah
 sidd at cs.utah.edu

 Jason Michelizzi

 Ying Liu, University of Minnesota, Twin Cities
 liux0395 at umn.edu

Last modified by :
$Id: Similarity.pm,v 1.4 2015/10/08 13:22:13 tpederse Exp $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010, Ted Pedersen, Jason Michelizzi, Siddharth 
Patwardhan, and Ying Liu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
