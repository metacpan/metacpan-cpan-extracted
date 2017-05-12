# UMLS::Similarity.pm 
#
# Perl implementation of semantic relatedness measures.
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
# Ying Liu, University of Minnesota, Twin Cities
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

package UMLS::Similarity;

$VERSION = '1.47';


sub new
{
    my $className = shift;
    return undef if(ref $className);

    my $interface = shift;

    my $self = {};
    
    # The backend interface object.
    $self->{'interface'} = $interface;

    # Bless object, initialize it and return it.
    bless($self, $className);

    return $self;
}



1;
__END__


=head1 NAME

UMLS::Similarity - A suite of Perl modules that implement a number 
of semantic similarity measures in order to calculate the similarity 
between two concepts in the UMLS. The measures use the UMLS-Interface 
module to access the UMLS present in a mysql database.

=head1 SYNOPSIS

 use UMLS::Interface;
 use UMLS::Similarity::lch;
 use UMLS::Similarity::path;

 my $umls = UMLS::Interface->new(); 
 die "Unable to create UMLS::Interface object.\n" if(!$umls);

 my $lch = UMLS::Similarity::lch->new($umls);
 die "Unable to create measure object.\n" if(!$lch);

 my $path = UMLS::Similarity::path->new($umls);
 die "Unable to create measure object.\n" if(!$path);

 my $cui1 = "C0005767";
 my $cui2 = "C0007634";

 $ts1 = $umls->getTermList($cui1);
 my $term1 = pop @{$ts1};

 $ts2 = $umls->getTermList($cui2);
 my $term2 = pop @{$ts2};

 my $lvalue = $lch->getRelatedness($cui1, $cui2);

 my $pvalue = $path->getRelatedness($cui1, $cui2);

 print "The lch similarity between $cui1 ($term1) and $cui2 ($term2) is $lvalue\n";

 print "The path similarity between $cui1 ($term1) and $cui2 ($term2) is $pvalue\n";

=head1 DESCRIPTION

This package consists of Perl modules along with supporting Perl
programs that implement the semantic relatedness measures described by
Leacock & Chodorow (1998), Wu & Palmer (1994), Nguyen and Al-Mubaid 
(2006), Rada, et. al. 1989, Patwardhan (2003), Lin (1988), Resnik (1996), 
Jiang & Conrath (1997), Patwardhan (2006), Banerjee and Pedersen (2003) 
and a simple path based measure.

The Perl modules are designed as objects with methods that take as
input two concepts. The semantic relatedness of these concepts is 
returned by these methods. A quantitative measure of the degree to
which two word senses are related has wide ranging applications in
numerous areas, such as word sense disambiguation, information
retrieval, etc. For example, in order to determine which sense of a
given word is being used in a particular context, the sense having the
highest relatedness with its context word senses is most likely to be
the sense being used. Similarly, in information retrieval, retrieving
documents containing highly related concepts are more likely to have
higher precision and recall values.

The following sections describe the organization of this software
package and how to use it. A few typical examples are given to help
clearly understand the usage of the modules and the supporting
utilities.

=head1 REFERENCING

    If you write a paper that has used UMLS-Interface in some way, we'd 
    certainly be grateful if you sent us a copy and referenced UMLS-Interface. 
    We have a published paper that provides a suitable reference:

    @inproceedings{McInnesPP09,
       title={{UMLS-Interface and UMLS-Similarity : Open Source 
               Software for Measuring Paths and Semantic Similarity}}, 
       author={McInnes, B.T. and Pedersen, T. and Pakhomov, S.V.}, 
       booktitle={Proceedings of the American Medical Informatics 
                  Association (AMIA) Symposium},
       year={2009}, 
       month={November}, 
       address={San Fransico, CA}
    }

    This paper is also found in
    <http://www-users.cs.umn.edu/~bthomson/publications/pubs.html>
    or
    <http://www.d.umn.edu/~tpederse/Pubs/amia09.pdf>

=head1 CONTACT US

  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :

      umls-similarity@yahoogroups.com

  You can join this group by going to:

      http://tech.groups.yahoo.com/group/umls-similarity/

  You may also contact us directly if you prefer :

      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 SEE ALSO

UMLS::Interface(1)

UMLS::Similarity::lch(3)
UMLS::Similarity::path(3)
UMLS::Similarity::wup(3) 
UMLS::Similarity::nam(3) 
UMLS::Similarity::cdist(3) 
UMLS::Similarity::lin(3) 
UMLS::Similarity::res(3)
UMLS::Similarity::jcn(3) 
UMLS::Similarity::vector(3) 
UMLS::Similarity::random(3)

=head1 AUTHORS

  Bridget McInnes <bthomson at umn.edu>
  Siddharth Patwardhan <sidd at cs.utah.edu>
  Serguei Pakhomov <pakh0002 at umn.edu>
  Ted Pedersen <tpederse at d.umn.edu>
  Ying Liu <liux0935 at umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2011 by Bridget McInnes, Siddharth Patwardhan, 
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
