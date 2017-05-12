# UMLS::Similarity::res.pm
#
# Module implementing the semantic relatedness measure described 
# by Resnik (1995)
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


package UMLS::Similarity::res;

use strict;
use warnings;
use UMLS::Similarity;
use UMLS::Similarity::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.07';

my $debug    = 0;
my $stoption = 0;
my $intrinsic= undef; 

sub new
{
    my $className = shift;
    my $interface = shift;
    my $params    = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::res->new()\n"; }

    my $self = {};
     
    # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    
    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("res",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
    }

    if(defined $params->{"intrinsic"}) { 
	$intrinsic = $params->{"intrinsic"}; 

	# set the propagation/frequency information
	$interface->setPropagationParameters($params);
	
    }
    #  load the propagation information for semantic types
    elsif(defined $params->{"st"}) { 
	#  set the st option
	$stoption = 1;
	
	if(defined $params->{"icfrequency"}) { 
	    
	    #  get the file name
	    my $icfrequency = $params->{"icfrequency"};
	    
	    #  initialize hte hash
	    my %fhash = ();

	    #  load the frequency counts
	    open(FILE, $icfrequency) || die "Could not open $icfrequency\n";
	    while(<FILE>) { 
		chomp;
		if($_=~/REL|SAB|N/) { next; }
		my ($st, $freq) = split/<>/;
		$fhash{$st} = $freq;
	    }
	    
	    #  if defined smoothing set the smoothing parameter
	    if(defined $params->{"smooth"}) { $interface->setStSmoothing(); }

	    #  propagate the semantic type counts 
	    $interface->propagateStCounts(\%fhash); 

	}
	else {
	    my $icpropagation = "";
	    #  get the icpropagation file if defined
	    if(defined $params->{"icpropagation"}) { 
		$icpropagation = $params->{"icpropagation"};
	    }
	    #  otherwise get the default icpropagation file
	    else {
		foreach my $path (@INC) {
		    if(-e $path."/UMLS/icpropagation.st.default.dat") { 
			$icpropagation = $path."/UMLS/icpropagation.st.default.dat";
		    }
		    elsif(-e $path."\\UMLS\\icpropagation.st.default.dat") { 
			$icpropagation =  $path."\\UMLS\\icpropagation.st.default.dat";
		    }
		}
	    }
	    
	    # get the probability counts
	    my %hash = ();
	    open(FILE, $icpropagation) || die "Could not open $icpropagation\n";
	    while(<FILE>) { 
		chomp;
		my ($st, $freq) = split/<>/;
		$hash{$st} = $freq;
	    }

	    $interface->loadStPropagationHash(\%hash);
	}
    }
    #  load the propagation information for the concepts
    else {

	# set the propagation/frequency information
	$interface->setPropagationParameters($params);
	
	#  if the icpropagation or icfrequency option is not 
	#  defined set the default options for icpropagation
	if( (!defined $params->{"icpropagation"}) &&
	    (!defined $params->{"icfrequency"}) ) {
	    
	    print STDERR "Setting default propagation file (res)\n";
	    
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

    #  set up the interface
    my $interface = $self->{'interface'};

    #  get the lcses of the concepts
    my $lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the ic of the lcs with the lowest ic score
    my $score = 0; my $l = "";
    if($stoption  == 1) { 
	foreach my $lcs (@{$lcses}) {
	    my $sts = $interface->getSt($lcs);
	    foreach my $st (@{$sts}) { 
		my $value = $interface->getStIC($st);
		if($score < $value) { $score = $value; $l = $lcs; }
	    }
	}
    }
    elsif(defined $intrinsic) {
	foreach my $lcs (@{$lcses}) {
	    my $value; 
	    if($intrinsic=~/sanchez/) { 
		$value = $interface->getSanchezIntrinsicIC($lcs);
	    }
	    else { 
		$value = $interface->getSecoIntrinsicIC($lcs);
	    }
	    if($score < $value) { $score = $value; $l = $lcs; }
	}
    }
    else {
	foreach my $lcs (@{$lcses}) {
	    my $value = $interface->getIC($lcs);
	    if($score < $value) { $score = $value; $l = $lcs; }
	}
    }
    
    #  if the information content is less then zero return -1
    if($score <= 0) { return -1; }
    
    #  return that score
    return $score
}


1;
__END__

=head1 NAME

UMLS::Similarity::res - Perl module for computing the semantic 
relatednessof concepts in the Unified Medical Language System 
(UMLS) using the method described by Resnik (1995).

=head1 CITATION

 @article{Resnik95,
  title={{Using information content to evaluate semantic 
          similarity in a taxonomy}},
  author={Resnik, P.},
  journal={Proceedings of the 14th International Joint 
           Conference on Artificial Intelligence},
  volume={1},
  pages={448--453},
  year={1995}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::res;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $res = UMLS::Similarity::res->new($umls);
  die "Unable to create measure object.\n" if(!$res);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $res->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic similarity of two concepts in 
the UMLS according to a method described by Resnik (1995). The 
relatedness measure proposed by Resnik is the information content 
(IC) of the least common subsumer of the two concepts. 

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
a file containing a list of CUIs and their probability, or used 
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

To create an object of the res measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::res;
   $measure = UMLS::Similarity::res->new($interface);

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
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
