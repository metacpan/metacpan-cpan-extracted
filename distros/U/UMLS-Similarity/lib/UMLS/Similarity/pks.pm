# UMLS::Similarity::pks.pm
#
# Module implementing the semantic relatedness measure described 
# by Pekar and Staab (2002)
#
# Copyright (c) 2004-2015,
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


package UMLS::Similarity::pks;

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
    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::pks->new()\n"; }

    my $interface = shift;

    my $self = {};
     
    # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;

    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("pks",  $interface);
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

    if($concept1 eq $concept2) { return 1; }

    #  get the interfaceg
    my $interface = $self->{'interface'};

    #  get the least common subsumer(s)
    my $lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);

    #  if there aren't any return zero
    if($#{$lcses} < 0) { return -1; }

    #  get the root
    my $root = $interface->root(); 
    
    #  get the shortest path of the lcs 
    my $lcs_sp_length = 9999999999999; my $lcs = "";
    foreach my $l (@{$lcses}) {
	my $path_length  = $interface->findShortestPathLength($root, $l); 
	if(defined $path_length) { 
	    if($path_length < $lcs_sp_length) { 
		$lcs_sp_length = $path_length; $lcs = $l;
	    }
	}
    }

    my $c1_sp_length = $interface->findShortestPathLength($lcs, $concept1); 
    my $c2_sp_length = $interface->findShortestPathLength($lcs, $concept2); 

    #  if one of the shortest path lengths is less than zero return -1
    if($c1_sp_length < 0) { return -1; }
    if($c2_sp_length < 0) { return -1; }
    if($lcs_sp_length < 0) { return -1; }

    #  calculate pks
    my $a = $lcs_sp_length; 
    my $b = $c1_sp_length + $c2_sp_length + $lcs_sp_length; 
    
    if($b <= 0) { return -1.0000; }

    my $score = $a / $b; 
    
    return $score;

}

1;
__END__

=head1 NAME

UMLS::Similarity::pks - Perl module for computing semantic relatedness
of concepts in the Unified Medical Language System (UMLS) using the 
method described by Pekar and Staab (2002)

=head1 CITATION

 @inproceedings{Pekar:2002:TLF:1072228.1072318,
 author = {Pekar, Viktor and Staab, Steffen},
 title = {Taxonomy Learning: Factoring the Structure of a Taxonomy into a Semantic Classification Decision},
 booktitle = {Proceedings of the 19th International Conference on Computational Linguistics - Volume 1},
 series = {COLING '02},
 year = {2002},
 location = {Taipei, Taiwan},
 pages = {1--7},
 numpages = {7},
 url = {http://dx.doi.org/10.3115/1072228.1072318},
 doi = {10.3115/1072228.1072318},
 acmid = {1072318},
 publisher = {Association for Computational Linguistics},
 address = {Stroudsburg, PA, USA},
} 


=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::pks;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $pks = UMLS::Similarity::pks->new($umls);
  die "Unable to create measure object.\n" if(!$pks);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  $ts1 = $umls->getTermList($cui1);
  my $term1 = pop @{$ts1};

  $ts2 = $umls->getTermList($cui2);
  my $term2 = pop @{$ts2};

  my $value = $pks->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic relatedness of two concepts in 
the UMLS according to a method described by Pekar and Staab (2002). 
The relatedness measure proposed by Pekar and Stabb is 
S<-sp(LCS(c1,c2),root) / 
sp(LCS(c1,c2),c1) + sp(LCS(c1,c2),c2) + sp(LCS(c1,c2),root) 
where sp is the shortest path between the two synsets (using node-counting). 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the pks measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::pks;
   $measure = UMLS::Similarity::pks->new($interface);

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
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
