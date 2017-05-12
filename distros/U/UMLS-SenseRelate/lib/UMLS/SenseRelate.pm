# UMLS::SenseRelate.pm 
#
# Perl implementation of the senerelate algorithm 
#
# Copyright (c) 2010-2012
#
# Bridget T McInnes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
##
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

package UMLS::SenseRelate;

$VERSION = '0.29';

sub new
{
    my $className = shift;
    return undef if(ref $className);

    my $self = {};
    
    # Bless object, initialize it and return it.
    bless($self, $className);

    return $self;
}



1;
__END__


=head1 NAME

UMLS::SenseRelate - A suit of Perl modules that implement the 
senserelate word sense disambiguation algorithm using the semantic 
similarity and relatedness options from the UMLS::Similarity package. 

=head1 SYNOPSIS

 use UMLS::Interface;
 use UMLS::Similarity;
 use UMLS::SenseRelate::TargetWord;

 #  initialize option hash and umls
 my %option_hash = ();
 my $umls        = "";
 my $meas        = "";
 my $senserelate = "";
 my %params      = ();
 
 #  set interface     
 $option_hash{"t"} = 1;
 $option_hash{"realtime"} = 1;
 $umls = UMLS::Interface->new(\%option_hash);

 #  set measure
 use UMLS::Similarity::path;
 $meas = UMLS::Similarity::path->new($umls);

 #  set senserelate
 $params{"measure"} = "path";

 $senserelate = UMLS::SenseRelate::TargetWord->new($umls, $meas, \%params); 

 #  set the target word
 my $tw = "adjustment";        

 #  provide an instance where the target word is in <head> tags
 my $instance = "Fifty-three percent of the subjects reported below average ";
    $instance .= "marital <head>adjustment</head>.";

 my ($hashref) = $senserelate->assignSense($tw, $instance, undef); 

 if(defined $hashref) {
    print "Target word ($tw) was assigned the following sense(s):\n";
    foreach my $sense (sort keys %{$hashref}) {  
      print "  $sense\n"; 
    }
 }
 else {
    print "Target word ($tw) has no senses.\n";
 }

=head1 DESCRIPTION

This package consists of the UMLS::SenseRelate::TargetWord module which 
performs target word sense disambugation using the semantic similarity 
and relatedness measure in the UMLS::Similarity package. 

=head1 CONTACT US

  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :

      umls-similarity@yahoogroups.com

  You can join this group by going to:

      http://tech.groups.yahoo.com/group/umls-similarity/

  You may also contact us directly if you prefer :

      Bridget T. McInnes: bthomson at umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 SEE ALSO

UMLS::Interface(1)
UMLS::Similarity(2)

=head1 AUTHORS

  Bridget McInnes <bthomson at umn.edu>
  Serguei Pakhomov <pakh0002 at umn.edu>
  Ted Pedersen <tpederse at d.umn.edu>
  Ying Liu <liux0935 at umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2012 by Bridget McInnes, Serguei Pakhomov, 
Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
