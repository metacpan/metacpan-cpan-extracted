# UMLS::Similarity::jcn.pm
#
# Module implementing the semantic relatedness measure described 
# by Jiang and Conrath (1997)
#
# Copyright (c) 2009-2011,
#
# Bridget T McInnes, University of Minnesota, Twin Cities
# bthomson at umn.edu
#
# Siddharth Patwardhan, University of Utah, Salt Lake City
# sidd at cs.utah.edu
#
# Serguei Pakhomov, University of Minnesota, Twin Cities
# pakh002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota
# liux0935 at umn.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to 
#
# The Free Software Foundation, Inc., 
# 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.


package UMLS::Similarity::jcn;

use strict;
use warnings;
use UMLS::Similarity;
use UMLS::Similarity::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.09';

my $debug    = 0;
my $intrinsic = undef; 
my $originaloption = undef;

sub new
{
    my $className = shift;
    my $interface = shift;
    my $params    = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::jcn->new()\n"; }

    my $self = {};
     
    # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    
    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("jcn",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
    }

    if(defined $params->{"intrinsic"}) { 
	$intrinsic = $params->{"intrinsic"}; 

	# set the propagation/frequency information
	$interface->setPropagationParameters($params);

    }
    else { 
	# set the propagation/frequency information
	$interface->setPropagationParameters($params);
	
	#  if the icpropagation or icfrequency option is not 
	#  defined set the default options for icpropagation
	if( (!defined $params->{"icpropagation"}) &&
	    (!defined $params->{"icfrequency"}) ) {
	    
	    print STDERR "Setting default propagation file (jcn)\n";
	    
	    #  get the icfrequency file
	    my $icfrequency = ""; foreach my $path (@INC) {
		if(-e $path."/UMLS/icfrequency.default.dat") { 
		    $icfrequency = $path."/UMLS/icfrequency.default.dat";
		}
		elsif(-e $path."\\UMLS\\icfrequency.default.dat") { 
		    $icfrequency =  $path."\\UMLS\\icfrequency.default.dat";
		}
	    }
	    
	    #  set the cuilist
	    my $fhash = $interface->getCuiList();
	    
	    #  load the frequency counts
	    open(FILE, $icfrequency) || die "Could not open $icfrequency\n";
	    while(<FILE>) { 
		chomp;
		my ($cui, $freq) = split/<>/;
		if(exists ${$fhash}{$cui}) { 
		    ${$fhash}{$cui} = $freq;
		}
	    }
	    
	    #  propagate the counts
	    my $phash = $interface->propagateCounts($fhash);
	}
    }
    #  check if the original distance score should be returned rather 
    #  than the similarity score
    if(defined $params->{"original"}) { $originaloption = 1; }
    return $self;
}

    
sub getRelatedness
{
    my $self = shift;

    return undef if(!defined $self || !ref $self);

    my $concept1 = shift;
    my $concept2 = shift;

    if($concept1 eq $concept2) { return 1; }

    my $interface = $self->{'interface'};
    
    my $ic1; my $ic2; 
    if(defined $intrinsic) {
	if($intrinsic=~/sanchez/) { 
	    $ic1 = $interface->getSanchezIntrinsicIC($concept1);
	    $ic2 = $interface->getSanchezIntrinsicIC($concept2);
	}
	else { 
	    $ic1 = $interface->getSecoIntrinsicIC($concept1);
	    $ic2 = $interface->getSecoIntrinsicIC($concept2);
	}
    }
    else { 
	$ic1 = $interface->getIC($concept1);
	$ic2 = $interface->getIC($concept2);
    }
    
    #  Check to make certain that the IC for each of the
    #  concepts is greater than zero otherwise return zero
    #  for lack of data
    if($ic1 <= 0 or $ic2 <= 0) { return -1; }

    #  get the lcses of the concepts
    my $lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the IC of the lcs with the lowest IC 
    my $iclcs = 0; my $l;
    foreach my $lcs (@{$lcses}) {
	my $value = 0;  
	if(defined $intrinsic) { 
	    if($intrinsic=~/sanchez/) { 
		$value = $interface->getSanchezIntrinsicIC($lcs);
	    }
	    else {
		$value = $interface->getSecoIntrinsicIC($lcs);
	    }
	}
	else { 
	    $value = $interface->getIC($lcs);
	}
	if($iclcs < $value) { $iclcs = $value; $l = $lcs; }
    }
    
    #  return -1
    if($iclcs <= 0) { return -1; }

    #  calculate the distance
    my $distance = ($ic1 + $ic2) - (2 * $iclcs);

    # if the distance is zero 
    # implies ic1 == ic2 == ic3 (most probably all three represent
    # the same concept)... i.e. maximum relatedness... i.e. infinity...
    # We'll return the maximum possible value ("Our infinity").
    # Here's how we got our infinity...
    # distance = ic1 + ic2 - (2 x ic3)
    # Largest possible value for (1/distance) is infinity, when distance = 0.
    # That won't work for us... Whats the next value on the list...
    # the smallest value of distance greater than 0...
    # Consider the formula again... distance = ic1 + ic2 - (2 x ic3)
    # We want the value of distance when ic1 or ic2 have information content
    # slightly more than that of the root (ic3)... (let ic2 == ic3 == 0)
    # Assume frequency counts of 0.01 less than the frequency count of the
    # root for computing ic1...
    # sim = 1/ic1
    # sim = 1/(-log((freq(root) - 0.01)/freq(root)))
    if($distance <= 0) { 
	my $rootFreq = $interface->getFrequency($l);
	
	#  if the root frequency is greater than zero
	if ($rootFreq > 0.01) {
	    $distance = -log (($rootFreq - 0.01) / $rootFreq);
	}
	# otherwise the root frequency is 0 so return 0 for lack of data
	else {
	    return -1;
	}
    }

    if(defined $originaloption)    { return $distance; }

    #  now calculate the similarity score
    my $score = -1;
    if($distance > 0) { 
	$score = 1 / $distance;
    }
    
    return $score;
}

1;
__END__

=head1 NAME

UMLS::Similarity::jcn - Perl module for computing the semantic 
relatednessof concepts in the Unified Medical Language System 
(UMLS) using the method described by Jiang and Conrath (1997).

=head1 CITATION

 @inproceedings{JiangC97,
  Author = {Jiang, J. and Conrath, D.},
  Booktitle = {Proceedings on International Conference 
               on Research in Computational Linguistics},
  Pages = {pp. 19-33},
  Title = {Semantic similarity based on corpus statistics 
           and lexical taxonomy},
  Year = {1997}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::jcn;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $jcn = UMLS::Similarity::jcn->new($umls);
  die "Unable to create measure object.\n" if(!$jcn);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $jcn->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic similarity of two concepts in 
the UMLS according to a method described by Jiang and Conrath (1997). 
This measure is based on a combination of using edge counts in the UMLS 
'is-a' hierarchy and using the information content values of the concepts, 
as describedin the paper by Jiang and Conrath. Their measure, however, 
computes values that indicate the semantic distance between words (as 
opposed to their semantic similarity). In this implementation of the 
measure we invert the value so as to obtain a measure of semantic 
relatedness. Other issues that arise due to this inversion (such as 
handling of zero values in the denominator) have been taken care of 
as special cases.

The IC of a concept is defined as the negative log of the probabilty 
of the concept. 

To use this measure, a propagation file containing the probability 
of a CUI for each of the CUIs from the source(s) specified in the 
configuration file. The format for this file is as follows:

 C0000039<>0.00003951
 C0000052<>0.00003951
 C0000084<>0.00003951
 C0000096<>0.00003951

A larger of example of this file can be found in the icpropagation file 
in the samples/ directory. 

A propagation file can be created using the create-icfrequency.pl and 
the create-icpropagation.pl programs in the utils/ directory. The 
create-icfrequency.pl program takes plain text and returns a list of 
CUIs that are mapped to the text and the CUIs frequency counts. This 
file can then be used by the create-icpropagation.pl program to create 
a file containing a list of CUIs and their probability counts, or used 
directly by the umls-similarity.pl program which will calculate the 
probability of a concept on the fly. 

=head1 SELF SIMILARITY

Since the Jiang and Conrath measure was initially calculated as 
a distance measure and turned into a similarity measure, we need 
to take care ofthe special cases in which the similarity of the 
two concepts results in zero but does not mean that the two 
concepts are not similar. Here is an explaination of how we did 
and why. This is taken from the discussion about this measure 
when it was being implemented in WordNet::Similarity. The 
actual message chain is located here:

L<http://tech.groups.yahoo.com/group/wn-similarity/message/8>

The Jiang and Conrath measure is calculated as follows:

 sim(c1, c2) = 1 / distance(c1, c2)

where

 c1, c2 are the two concepts,
 distance(c1, c2) = ic(c1) + ic(c2) - (2 * ic(lcs(c1, c2)))
 ic               = the information content of the concept.
 lcs(c1, c2)      = the least common subsumer of c1 and c2.

Now, we don't want distance to be 0 (=> similarity will become
undefined). The distance can be 0 in 2 cases...

(1) ic(c1) = ic(c2) = ic(lcs(c1, c2)) = 0

ic(lcs(c1, c2)) can be 0 if the lcs turns out to be the root
node (information content of the root node is zero). But since
c1 and c2 can never be the root node, ic(c1) and ic(c2) would be 0
only if the 2 concepts have a 0 frequency count, in which case, for
lack of data, we return a relatedness of 0 (similar to the lin case).

Note that the root node ACTUALLY has an information content of
zero. Technically, none of the other concepts can have an information
content value of zero. We assign concepts zero values, when
in reality their information content is undefined (due to zero
frequency counts). To see why look at the formula for information
content: ic(c) = -log(freq(c)/freq(ROOT)) {log(0)? log(1)?}

(2) The second case that distance turns out to be zero is when...

ic(c1) + ic(c2) = 2 * ic(lcs(c1, c2))

(which could have a more likely special case ic(c1) = ic(c2) =
ic(lcs(c1, c2)) if all three turn out to be the same concept.)

How should one handle this?

Intuitively this is the case of maximum relatedness (zero
distance). For jcn this relatedness would be infinity... But we
can't return infinity. And simply returning a 0 wouldn't work...
since here we have found a pair of concepts with maximum
relatedness, and returning a 0 would be like saying that they
aren't related at all.

So what could we return as the maximum relatedness value?

So the way I handled this was to try to find the smallest distance
greater than 0, so that sim would be a very high value, but not
infinity. To find this value of distance I consider the formula of
distance...

 distance = ic(c1) + ic(c2) - (2 * ic(lcs(c1, c2)))

we get distance = 0 if ic(c1) = ic(c2) = ic(lcs(c1, c2))
So consider the case that ic(c2) = ic(lcs(c1, c2), but ic(c1) is the
information content value just slightly more than that of ic(c2) (and
ic(lcs(c1, c2))). We want to find the value of distance corresponding
to such a case and this would be the next highest value of distance
after 0.

We could select ic(c2) and ic(lcs(c1, c2)) to represent a highly
specific concept or a highly general concept for this computation...
We'll decide which one to select later...
For now we want a formula to represent a value of
distance = "almost zero".

 ic(concept) = -log(freq(concept)/freq(root))

For ic(c1) to be just slightly more than ic(c2) (or ic(lcs(c1, c2))),
what if we just reduced freq(concept) in the above formula by 1. i.e.

 ic(c2) = ic(lcs(c1, c2)) = -log(freq/rootFreq)

 ic(c1) = -log((freq-1)/rootFreq)

Since frequency is counted in whole numbers, this is the closest
ic(c1) could be to ic(c2) (but not equal to it). With this formula we
would have

 distance = ic(c1) + ic(c2) - (2 * ic(lcs(c1, c2)))
          = ic(c1) + ic(c2) - (2 * ic(c2))

... since ic(c2) = ic(lcs(c1, c2))

          = ic(c1) - ic(c2)
          = -log((freq-1)/rootFreq) + log(freq/rootFreq)

Now comes the part where we want to decide whether to select a
highly specific concept or a highly general concept for ic2 and
ic3... I selected them to be the most general concepts for some non
mathematical reasons (tho' I think I had come up with some
mathematical ones)...

My reasons...

The most general concept is the root node... we always have the
frequency count of the root node (non zero)... (if the root node is
zero then there is something really wrong with the information
content computed). It would be very difficult to find the most
specific concept (tho' not impossible).

Somehow, mathematically, I had a feeling that the more general
ic(c1) and ic(c2) are, they would be closer to each other on the
log scale than if they were more specific concepts (I could be
mistaken and it could be the other way around... and I don't have a
proof right now to support what I'm saying)

anyway, taking the most general concepts (the root concept), we have

distance = -log((rootFreq - 1)/rootFreq) + log(rootFreq/rootFreq)
         = -log((rootFreq - 1)/rootFreq) + log(1)
         = -log((rootFreq - 1)/rootFreq)

This is the distance corresponding to "almost zero"... And this is
what I put in the code for the 0 case (sim = infinity case).

With the hocus pocus above I have made an artificial bound on relatedness
to "almost infinity".

=head1 PROPAGATION

The Information Content (IC) is  defined as the negative log 
of the probability of a concept. The probability of a concept, 
c, is determine by summing the probability of the concept 
ocurring in some text plus the probability its decendants 
occuring in some text:

For more information on how this is calculated please see 
the README file. 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the jcn measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::jcn;
   $measure = UMLS::Similarity::jcn->new($interface);

The reference of the initialized object is stored in the scalar
variable '$measure'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. 

To find the semantic relatedness of the concept 'blood' (C0005767) and
the concept 'cell' (C0007634) using the measure, we would write
the following piece of code:

   $relatedness = $measure->getRelatedness('C0005767', 'C0007634');

=head1 CONFIGURATION OPTION

The UMLS-Interface package takes a configuration file to determine 
which sources and relations to use when obtaining the path information.

The format of the configuration file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

SAB :: include MSH
REL :: include RB, RN

or 

SAB :: include MSH
REL :: exclude PAR, CHD

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

For more information about the configuration options please 
see the README.

=head1 SEE ALSO

perl(1), UMLS::Interface

perl(1), UMLS::Similarity(3)

=head1 CONTACT US

  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :

      umls-similarity@yahoogroups.com

  You can join this group by going to:

      http://tech.groups.yahoo.com/group/umls-similarity/

  You may also contact us directly if you prefer :

      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu


=head1 AUTHORS

  Bridget T McInnes <bthomson at cs.umn.edu>
  Siddharth Patwardhan <sidd at cs.utah.edu>
  Serguei Pakhomov <pakh0002 at umn.edu>
  Ted Pedersen <tpederse at d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2011 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
