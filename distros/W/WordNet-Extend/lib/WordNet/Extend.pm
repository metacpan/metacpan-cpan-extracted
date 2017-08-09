# WordNet::Extend version 1.000
# Updated: 08/06/17
#
# Jon Rusert, University of Minnesota Duluth
# ruse0008 at d.umn.edu
#
# Ted Pedersen, University of Minnesota Duluth             
# tpederse at d.umn.edu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package WordNet::Extend;

=head1 NAME                                                                                           

WordNet::Extend - Perl modules for extending your local WordNet.       
                           
=head1 SYNOPSIS  
           
=head2 Basic Usage Example      
  
 use WordNet::Extend::Locate;    
 use WordNet::Extend::Insert;       

 my $locate = WordNet::Extend::Locate->new();   
 my $insert = WordNet::Extend::Insert->new();
 @in1 = ("crackberry","noun","withdef.1", "A BlackBerry, a handheld device considered addictive for its networking capability.");    

 print "Locating where $in1[0] should be inserted...\n";
 @loc1 = @{$locate->locate(\@in1)};   
 
 print "System found $loc1[1] as the ideal insertion location...\n";
                                    
 if($loc1[2] eq "attach")
 {
     print "Attaching $in1[0] to $loc1[0]";
     $insert->attach(\@in1, \@loc1);                                                                  
 }
 else
 {
     print "Merging $in1[0] into $loc1[0]";
     $insert->merge(\@in1, @loc1);
 }
 
 #$insert->restoreWordNet();

=head1 DESCRIPTION          
  
=head2 Introduction      

WordNet is a widely used tool in NLP and other research areas. A drawback of WordNet is the amount of time between updates. WordNet was last updated and released in December, 2006, and no further updates are planned. WordNet::Extend aims to help developers get a large use out of WordNet by allowing users to push the bounds of their own local WordNet. Both by allowing users to insert new lemmas into WordNet (WordNet::Extend::Insert) and helping users decide where a good place to insert new lemmas into WordNet is (WordNet::Extend::Locate). 
                                                                    
=cut

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);

%EXPORT_TAGS = ();

@EXPORT_OK = ();

@EXPORT = ();

$VERSION = '1.000';

