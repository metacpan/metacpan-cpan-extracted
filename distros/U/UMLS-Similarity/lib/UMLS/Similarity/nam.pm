# UMLS::Similarity::nam.pm
#
# Module implementing the semantic similarity measure described 
# by Nguyen and Al-Mubaid (2006)
#
# Copyright (c) 2004-2011,
#
# Bridget T McInnes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
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


package UMLS::Similarity::nam;

use strict;
use warnings;
use UMLS::Similarity;
use UMLS::Similarity::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.07';

my $debug = 0;

my $originaloption = undef;

sub new
{
    my $className = shift;
    my $interface = shift;
    my $params    = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::nam->new()\n"; }


    my $self = {};
     
   # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    
    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("nam",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
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
    
    #  set up the interface
    my $interface = $self->{'interface'};
    
    #  get the minimum depth of the two concepts
    my $c1_depth  = $interface->findMinimumDepth($concept1);
    my $c2_depth  = $interface->findMinimumDepth($concept2);

    if( !(defined $c1_depth) or	!(defined $c2_depth)) {
	return -1;
    }
    
    #  find the lcses
    my $lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the minimum depth of the lowest lcs
    my $lcs_depth = -1;
    foreach my $l (@{$lcses}) {
	my $ldepth = $interface->findMinimumDepth($l);
	if($lcs_depth == -1)     { $lcs_depth = $ldepth; }
	elsif($ldepth < $lcs_depth) { $lcs_depth = $ldepth; }
    }
    
    #  if the lcs depth is zero just return zero
    if($lcs_depth < 0) { return -1; }

    #  find the shortest path between the concepts
    my $l = $interface->findShortestPathLength($concept1, $concept2);

    #  calculate nam
    my $D = $interface->depth();
    my $score = log( $l * ($D-$lcs_depth) + 2 ) / log(2);    
    
    if(defined $originaloption) { return $score;     }
    else                        { return (1/$score); }
}


1;
__END__

=head1 NAME

UMLS::Similarity::nam - Perl module for computing semantic relatedness
of concepts in the Unified Medical Language System (UMLS) using the 
method described by Nguyen and Al-Mubaid (2006)

=head1 CITATION

 @inproceedings{NguyenA06,
  title={{New ontology-based semantic similarity measure 
          for the biomedical domain}},
  author={Nguyen, H.A. and Al-Mubaid, H.},
  booktitle={Proceedings of the IEEE International Conference 
             on Granular Computing},
  pages={623--628},
  year={2006}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::nam;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $nam = UMLS::Similarity::nam->new($umls);
  die "Unable to create measure object.\n" if(!$nam);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $nam->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

The Nguyen and Al-Mubaid measure calculates similarity by calculating 
the log of two plus the product of the shortest distance between the 
two concepts minus one and the depth of the taxonomy minus the depth 
of the LCS. Concepts that are more similar with have a lower similarity 
score than concepts that are less similar with this measure.

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the nam measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::nam;
   $measure = UMLS::Similarity::nam->new($interface);

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
