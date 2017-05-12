package WordNet::SenseRelate::WordToSet;

=head1 NAME

WordNet::SenseRelate::WordToSet - Find the WordNet Sense of a Target 
Word that is Most Related to a Given Set of Words

=head1 SYNOPSIS

  use WordNet::SenseRelate::WordToSet;
  use WordNet::QueryData;
  my $qd = WordNet::QueryData->new;

  my %options = (measure => 'WordNet::Similarity::jcn',
                 wordnet => $qd);

  my $mod = WordNet::SenseRelate::WordToSet->new (%options);

  my $res = $mod->disambiguate (target => 'bank',
                              context => [qw/money cash dollar/]);

  # all senses for target and their scores are returned
  # we will just print the sense most related to the set

  $best_score = -100;
  foreach my $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
        $best_score = $res->{$key};
        $best = $key;
    }
  }

  # let's call WordNet::QueryData to get the gloss of the most
  # related sense of the target to the set 

  print "$best : ", join(", ", $qd->querySense($best, "glos")), "\n";

  my $res = $mod->disambiguate (target => 'bank',
                              context => [qw/river shore slope water/]);

  # all senses for target and their scores are returned
  # we will just print the sense most related to the set

  $best_score = -100;
  foreach my $key (keys %$res) {
    next unless defined $res->{$key};
    if ($res->{$key} > $best_score) {
        $best_score = $res->{$key};
        $best = $key;
    }
  }

  # let's call WordNet::QueryData to get the gloss of the most
  # related sense of the target to the set 

  print "$best : ", join(", ", $qd->querySense($best, "glos")), "\n";
  
=head1 DESCRIPTION

WordNet::SenseRelate::WordToSet finds the sense of a given target word 
that is most related to the words in a given set. 

=head2 Methods

The methods below will die() on serious errors.  Wrap calls to these
methods in an eval BLOCK to catch the exceptions.  See
'perldoc -f eval' for more information.

=over

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our @ISA = ();
our $VERSION = '0.04';

my %wordnet;
my %simMeasure;
my %trace;
my %wnformat;
my %threshold;

# constants used to specify trace levels
#use constant TR_CONTEXT    =>  1;  # show the context window
#use constant TR_BESTSCORE  =>  2;  # show the best score
#use constant TR_ALLSCORES  =>  4;  # show all non-zero scores

# the previous three levels don't make a lot of sense for WordToSet
# * The context should be obvious
# * All the scores are returned from disambiguate() 
use constant TR_PAIRWISE   =>  1;  # show all the non-zero similarity scores
use constant TR_ZERO       =>  2;
use constant TR_MEASURE    =>  4;  # show similarity measure traces

=item B<new>Z<>

Z<>The constructor for this class.

Parameters:

  wordnet   => REFERENCE : WordNet::QueryData object (required)
  measure   => STRING    : name of a WordNet::Similarity measure (required)
  config    => FILENAME  : path to a config file for above measure
  trace     => INTEGER   : generate traces (default : 0)
  threshold => NUMBER    : similarity scores less than this are ignored

Returns:

   A reference to the constructed object or undef on error.

The trace levels are:

 1 show non-zero scores from the semantic relatedness measure

 2 show zero & undefined scores from the relatedness measure
   (no effect unless combined with level 1)

 4 show traces from the semantic relatedness measure

Note: the trace levels can be added together to achieve a combined effect.
For example, to show the non-zero scores, the zero scores, and the
traces from the measure, use level 7.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    $class = ref $class || $class;

    my $qd;
    my $measure;
    my $measure_config;
    my $threshold = 0;
    my $trace;
    my $wnformat = 0;

    while (my ($key, $val) = each %args) {
	if ($key eq 'wordnet') {
	    $qd = $val;
	}
	elsif ($key eq 'measure') {
	    $measure = $val;
	}
	elsif ($key eq 'config') {
	    $measure_config = $val;
	}
	elsif ($key eq 'threshold') {
	    $threshold = $val;
	}
	elsif ($key eq 'trace') {
	    $trace = $val;
	}
	elsif ($key eq 'wnformat') {
	    $wnformat = $val;
	}
	else {
	    croak "Unknown parameter type '$key'";
	}
    }

    unless (ref $qd) {
	croak "No WordNet::QueryData object supplied";
    }

    unless ($measure) {
	croak "No relatedness measure supplied";
    }

    my $self = bless [], $class;

    # initialize tracing
    if (defined $trace) {
	$trace{$self} = {level => $trace, string => ''};
	if (($trace & TR_ZERO) and !($trace & TR_PAIRWISE)) {
	    warn ("Warning: trace level ", TR_ZERO,
		  " has no effect unless combined with level ", TR_PAIRWISE,
		   ".\n");
	}
    }
    else {
	$trace{$self} = {level => 0, string => ''};
    }

    # setup relatedness measure
    my $file = $measure;
    $file =~ s/::/\//g;
    require "${file}.pm";

    if (defined $measure_config) {
	$simMeasure{$self} = $measure->new ($qd, $measure_config);
    }
    else {
	$simMeasure{$self} = $measure->new ($qd);
    }

    # check for errors
    my ($errCode, $errStr) = $simMeasure{$self}->getError;
    if ($errCode) {
        croak $errStr;
    }

    # turn on traces in the relatedness measure if required
    if ($trace{$self}->{level} & TR_MEASURE) {
        $simMeasure{$self}->{trace} = 1;
    }
    else {
        $simMeasure{$self}->{trace} = 0;
    }
    
    $wordnet{$self} = $qd;

    # store threshold value
    $threshold{$self} = $threshold;

    $wnformat{$self} = $wnformat;

    return $self;
}

sub DESTROY
{
    my $self = shift;
    
    delete $wordnet{$self};
    delete $simMeasure{$self};
    delete $threshold{$self};
    delete $trace{$self};
    delete $wnformat{$self};

    1;
}


=item disambiguate

Disambiguates the target word

Parameters:

  target  => STRING    : the target word to disambiguate (required)
  context => REFERENCE : a reference to an array of context words

Returns:

  A hash reference.  The keys of the hash will be the senses of the
  target word, and the values will be the score for each sense.

=cut

sub disambiguate
{
    my $self = shift;
    my %options = @_;

    # local vars
    my @context;
    my $target;

    while (my ($key, $val) = each %options) {
	if ($key eq 'target') {
	    $target = $val;
	}
	elsif ($key eq 'context') {
	    if ('ARRAY' eq ref $val) {
		@context = @$val;
	    }
	    else {
		carp "Value for option 'context' is not an array reference";
		return undef;
	    }
	}
	elsif ($key eq 'threshold') {
	    $threshold{$self} = $val;
	}
	else {
	    croak "Unknown option '$key'";
	}
    }

    my $tagged = 0;

    # quick sanity check to ensure that all words are in WordNet
    my $qd = $wordnet{$self};
    if ($wnformat{$self}) {
	foreach my $word ($target, @context) {
	    my @t = $qd->querySense ($word);
	    unless (scalar @t) {
		warn "'$word' is not found in WordNet\n";
		return undef;
	    }
	}
    }
    else {
	foreach my $word ($target, @context) {
	    my @t = $qd->validForms ($target);
	    unless (scalar @t) {
		warn "'$word' is not found in WordNet\n";
		return undef;
	    }
	}
    }
    
    my $result;
    $result = $self->doNormal ($target, @context);

    return $result;
}

sub doNormal
{
    my $self = shift;
    my $target = shift;
    my @context = @_;
    my $measure = $simMeasure{$self};
    my $threshold = $threshold{$self};

    my $tracelevel = $trace{$self}->{level};
    my @traces;

    # get senses for the target and context words
    my @targetsenses = $self->_getSenses ($target);
    my @contextsenses;
    for my $i (0..$#context) {
	$contextsenses[$i] = [$self->_getSenses ($context[$i])];
    }


    # now disambiguate the target

    my @sums;
    for my $targetsense (0..$#targetsenses) {
	$sums[$targetsense] = 0;

	for my $i (0..$#contextsenses) {
	    next if 0 == scalar $contextsenses[$i];
	    my @tempScores;

	    for my $k (0..$#{$contextsenses[$i]}) {
		unless (defined $contextsenses[$i][$k]) {
		    warn "\$contextsenses[$i][$k] is undef";
		}

		$tempScores[$k] = 
		    $measure->getRelatedness ($targetsenses[$targetsense],
					      $contextsenses[$i][$k]);
	    }

	    my $max = -1;
	    my $maxidx = -1;
	    for my $n (0..$#tempScores) {
		if ($tracelevel & TR_PAIRWISE) {
		    if (($tempScores[$n] && $tempScores[$n] > 0)
			|| ($tracelevel & TR_ZERO)) {
			unless (defined $contextsenses[$i][$n]) {
			    warn "\$contextsenses[$i][$n] is undef";
			}
			my $s = "    "
                            . $targetsenses[$targetsense] . ' '
                            . $contextsenses[$i][$n] . ' '
                            . (defined $tempScores[$n]
                               ? $tempScores[$n]
                               : 'undef');

			push @{$traces[$targetsense]}, $s;
		    }
		}

		if ($tracelevel & TR_MEASURE) {
		     if (($tempScores[$n] && $tempScores[$n] > 0)
			|| ($tracelevel & TR_ZERO)) {
			 push @{$traces[$targetsense]}, $measure->getTraceString;
		     }
		}

		$measure->getError; # clear errors from relatedness object

		if (defined $tempScores[$n] && ($tempScores[$n] > $max)) {
		    $max = $tempScores[$n];
		    $maxidx = $n;
		}

	    }
	    
	    $sums[$targetsense] += $max if $max > $threshold;
	}
    }

    my $max = -1;
    my $maxidx = -1;
    foreach my $p (0..$#sums) {
	if ($sums[$p] > $max) {
	    $maxidx = $p;
	    $max = $sums[$p];
	}

#	if ($tracelevel & TR_ALLSCORES
#	    && (($sums[$p] > 0) or ($tracelevel & TR_ZERO))) {
#	    $trace{$self}->{string} .= "   $targetsenses[$p]: $sums[$p]\n";
#	}

	if (($tracelevel & TR_MEASURE or $tracelevel & TR_PAIRWISE)
	    && defined $traces[$p]) {
	    for my $str (@{$traces[$p]}) {
		$trace{$self}->{string} .= $str . "\n";
	    }
	}
    }

	

    my %rhash;
    my $best_sense = '';
    my $best_score = -1;
    foreach my $i (0..$#sums) {
	if ($sums[$i] > $best_score) {
	    $best_sense = $targetsenses[$i];
	    $best_score = $sums[$i];
	}

	$rhash{$targetsenses[$i]} = $sums[$i] if $sums[$i] > $threshold;
    }

#    if ($tracelevel & TR_BESTSCORE) {
#	if ($best_score >= 0) {
#	    $trace{$self}->{string} .= " Winning sense: $best_sense\n";
#	    $trace{$self}->{string} .= " Winning score: $best_score\n";
#	}
#	else {
#	    $trace{$self}->{string} .= " Winning sense: (none)\n";
#	    $trace{$self}->{string} .= " Winning score: (none)\n";
#	}
#    }

    return \%rhash;

#    if ($maxidx >= 0) {
#	return $targetsenses[$maxidx];
#    }

#    return $target;
}

=item B<getTrace>

Gets the current trace string and resets it to "".

Parameters:

None

Returns:

The current trace string (before resetting it).  If the returned string
is not empty, it will end with a newline.

Example:

  my $str = $wsd->getTrace ();
  print $str;

=cut

sub getTrace
{
    my $self = shift;

    return '' unless $trace{$self};

    my $s = $trace{$self}->{string};
    $trace{$self}->{string} = '';
    return $s;
}

sub _getSenses
{
    my $self = shift;
    my $word = shift;
    my $qd = $wordnet{$self};
    my @senses;

    # first get all forms for each POS
    if ($word =~ /\#o/) {
	@senses = undef;
    }
    else {
	my @forms;
	unless ($wnformat{$self}) {
	    @forms = $qd->validForms ($word);
	}
	else {
	    @forms = $word;
	}
	
	if (scalar @forms == 0) {
	    @senses = ();
	}
	else {
	    # now get all the senses for each form
	    foreach my $form (@forms) {
		my @temps = $qd->querySense ($form);
		push @senses, @temps;
	    }
	}
    }

    return @senses;
}


1;

__END__

=back

=head1 SEE ALSO

 L<http://senserelate.sourceforge.net/>

 Ted Pedersen, Satanjeev Banerjee, and Siddharth Patwardhan (2005)
 Maximizing Semantic Relatedness to Perform Word Sense Disambiguation,
 University of Minnesota Supercomputing Institute Research Report UMSI
 2005/25, March.
 L<http://www.msi.umn.edu/general/Reports/rptfiles/2005-25.pdf>

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

Last modified by :
$Id: WordToSet.pm,v 1.10 2008/04/07 03:29:47 tpederse Exp $

=head1 COPYRIGHT 

Copyright (C) 2005-2008 by Jason Michelizzi and Ted Pedersen

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
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  
USA

=cut
