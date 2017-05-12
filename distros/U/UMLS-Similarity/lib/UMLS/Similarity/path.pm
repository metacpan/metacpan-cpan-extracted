# UMLS::Similarity::path.pm
#
# Module implementing the simple edge counting measure of 
# semantic relatedness.
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


package UMLS::Similarity::path;

use strict;
use warnings;
use UMLS::Similarity;
use UMLS::Similarity::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.07';

my $debug = 0;

sub new
{
    my $className = shift;
    my $interface    = shift;
    
    return undef if(ref $className);
  
    my $self = {};
        
    # Bless the object.
    bless($self, $className);
        
    # The backend interface object.
    $self->{'interface'} = $interface;

    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("path",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
    }

    return $self;
}


sub getRelatedness
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept1 = shift;
    my $concept2 = shift;
    
    #  if concept 1 and 2 are the same just return 1
    if($concept1 eq $concept2) { return 1; }

    #  get the interface
    my $interface = $self->{'interface'};
    
    #  find the shortest paths
    my $length = $interface->findShortestPathLength($concept1, $concept2);
    
    #  if length is less than zero (this shouldn't happen) 
    #  return a score of zero
    if($length <= 0) { return $length; }

    #  otherwise return the reciprocal of the length
    return (1/$length);
}


1;
__END__

=head1 NAME

UMLS::Similarity::path - Perl module for computing semantic similarity 
of concepts in the UMLS by simple edge counting. 

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::path;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $path = UMLS::Similarity::path->new($umls);
  die "Unable to create measure object.\n" if(!$path);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $path->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

If the concepts being compared are the same, then the resulting 
similarity score will be 1.  For example, the score for C0005767 
and C0005767 is 1.

The relatedness value returned by C<getRelatedness()> is the 
multiplicative inverse of the path length between the two synsets 
(1/path_length).  This has a slightly subtle effect: it shifts 
the relative magnitude of scores. For example, if we have the 
following pairs of synsets with the given path lengths:

  concept1 concept2: 3
  concept3 concept4: 4
  concept5 concept6: 5

We observe that the difference in the score for concept1-concept2 
and concept3-concept4 is the same as for concept3-concept4 and 
concept5-concept6. When we take the multiplicative inverse of them, 
we get:

  concept1 concept2: .333
  concept3 concept4: .25
  concept5 concept6: .2

Now the difference between the scores for concept3-concept4 is less 
than the difference for concept1-concept2 and concept3-concept4. This 
can have negative consequences when computing correlation coefficients.
It might be useful to compute relatedness as S<max_distance - 
path_length>, where max_distance is the longest possible shortest 
path between two conceps.  The original path length can be easily 
determined by taking the multiplicative inverse of the returned 
relatedness score: S<1/score = 1/(1/path_length) = path_length>. 

If two different terms are given as input to getRelatedness, but 
both terms belong to the same concept, then 1 is returned (e.g.,
car and auto both belong to the same concept).

=head1 USAGE

The semantic relatedness modules in this distribution are built as 
classes that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the path measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::path;
   $measure = UMLS::Similarity::path->new($interface);

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
