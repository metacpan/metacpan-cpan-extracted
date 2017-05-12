# UMLS::Similarity::lin.pm
#
# Module implementing the semantic relatedness measure described 
# by Lin (1997)
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


package UMLS::Similarity::lin;

use strict;
use warnings;
use UMLS::Similarity;
use UMLS::Similarity::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.07';

my $intrinsic = undef; 
my $debug = 0;

sub new
{
    my $className = shift;
    my $interface = shift;
    my $params    = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::lin->new()\n"; }

    my $self = {};
 
   # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    
    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("lin",  $interface);
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
	    
	    print STDERR "Setting default propagation file (lin)\n";
	    
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
    return $self;
}


sub getRelatedness
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept1 = shift;
    my $concept2 = shift;

    if($concept1 eq $concept2) { return 1; }

    #  set up the interface
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
    
    #  if any of the concepts have an ic of zero return -1
    if( ($ic1 <= 0) || ($ic2 <= 0) ) { return -1; }
    #  get the lcses
    my $lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the ic of the lcs with the lowest ic score
    my $iclcs = 0; my $l = "";
    foreach my $lcs (@{$lcses}) {
	my $value;
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

    #  if it is zero just return -1
    if($iclcs <= 0) { return -1; }

    #  calculate lin
    my $score = 0;
    if($ic1 > 0 and $ic2 > 0) { 
	my $a = 2 * $iclcs; 
	my $b = $ic1 + $ic2; 
	$score = (2 * $iclcs) / ($ic1 + $ic2);
    }
    
    return $score
}


1;
__END__

=head1 NAME

UMLS::Similarity::lin - Perl module for computing the semantic 
relatednessof concepts in the Unified Medical Language System 
(UMLS) using the method described by Lin (1997).

=head1 CITATION

 @article{Lin97,
  title={{Using syntactic dependency as local context to resolve 
          word sense ambiguity}},
  author={Lin, D.},
  journal={Proceedings of the 35th Annual Meeting of the 
           Association for Computational Linguistics},
  pages={64--71},
  year={1997}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::lin;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $lin = UMLS::Similarity::lin->new($umls);
  die "Unable to create measure object.\n" if(!$lin);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $lin->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic relatedness of two concepts in 
the UMLS according to a method described by Lin (1998). The 
relatedness measure proposed by Lin is the IC(lcs) / IC(concept1) 
+ IC(concept2). One can observe, then, that the similarity value 
will be greater-than or equal-to zero and less-than or equal-to one.

If the information content of any of either concept1 or concept2 is zero,
then zero is returned as the relatedness score, due to lack of data.
Ideally, the information content of a synset would be zero only if that
synset were the root node, but when the frequency of a synset is zero,
we use the value of zero as the information content because of a lack
of better alternatives.

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
  getError()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the lin measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::lin;
   $measure = UMLS::Similarity::lin->new($interface);

The reference of the initialized object is stored in the scalar
variable '$measure'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. This, as well as any other error/warning may be tested.

   die "Unable to create object.\n" if(!defined $measure);
   ($err, $errString) = $measure->getError();
   die $errString."\n" if($err);

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
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
