
=head1 NAME

WebService::UMLSKS::GetNeighbors - Fetches all the neighbor concepts for the input concept.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::GetNeighbors;
    
    my $Neighbors_ref = call_getconceptproperties($cui);# Neighbors_ref is a hash reference
    my $read_Neighbors = new GetNeighbors;
    # $ref is a reference of an array of all Neighbors' CUI for the input cui.
    my $ref  = $read_Neighbors->read_object( $Neighbors_ref );   
	   


=head1 DESCRIPTION

This module has package GetParents which has subroutines 'new', 'read_object','extract_object_class', 
'format_object', 'format_homogeneous_hash', 'format_scalar', format_homogeneous_array.


=head1 SUBROUTINES

The subroutines are as follows:


=cut

###############################################################################
##########  CODE STARTS HERE  #################################################



use SOAP::Lite;
use strict;
use warnings;

no warnings qw/redefine/;


package WebService::UMLSKS::GetNeighbors;
our $ConceptInfo_ref;
use Log::Message::Simple qw[msg error debug];
my %ConceptInfo;
my %directions;
my @parents;
my @children;
my @siblings;
my $indentation;
my $verbose = 0;
my @attribute = ();
my @relationattr = ();


#print "\n in format hash";
	#my %directions =  %$WebService::UMLSKS::FormGraph::Directions_ref;
	
	#$directions{"PAR"} = "U";
	#$directions{"CHD"} = "D";
	#$directions{"RB"} = "H";
	#$directions{"RN"} = "H";

=head2 new

This sub creates a new object of GetNeighbors.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	#print "in new in display_info";
	bless( $self, $class );
	return $self;
}

=head2 read_object

This sub reads hash reference object passed to this
sub and fetches the required Neighbors' information.

=cut

sub read_object {

	my $self        = shift;
	my $object_refr = shift;
	my $qterm = shift;
	my $ver = shift;
	my $directions_ref = shift;
	my $attribute_ref = shift;
	
	$verbose = $ver;
	 %directions = %$directions_ref;
	# printHash(\%directions);


	# If the attributes are specified, then set the relations and relation attributes.

	if(@$attribute_ref){
		
		foreach my $attr (@$attribute_ref){
			$attr =~ /(.*?)\s*-\s*(.*)$/;
			my $rel = $1;
			my $att = $2;
			$att =~ s/\s*//g;
			$rel =~ s/\s*//g;
			
			
			
			# If this relation is in directions
			if($rel ~~ %directions){
				unless($rel ~~ @relationattr){
					push(@relationattr,$rel);
				}
				unless($att ~~ @attribute){
					push(@attribute,$att);
				}
				
			}
		}
		
		
	}

	undef @parents;
	undef @children;
	undef @siblings;
	
	@parents = ();
	@children = ();
	@siblings = ();
	        
	        
	#msg ("\t relation for which atttributes are specified : @relationattr",$verbose);
	#msg ("\t attribues are : @attribute",$verbose);         
	my @neighbors = ();
	
	#my $return_ref =
	format_object($object_refr);
	chomp(@parents);
	chomp(@children);
	chomp(@siblings);

	$ConceptInfo_ref = \%ConceptInfo;

	my $parents_ref = findUnique(\@parents,$qterm);
	my $children_ref = findUnique(\@children,$qterm);
	my $siblings_ref = findUnique(\@siblings,$qterm);
	
	if(defined $parents_ref){
		#print "\n parents are @unique";
		push(@neighbors,$parents_ref);
	}
	else{
		#msg( "\n No parents found for $qterm in current Source/s", $verbose);
		push(@neighbors,"empty");
	}
	if(defined $children_ref){
		#print "\n parents are @unique";
		push(@neighbors,$children_ref);
	}
	else{
		#msg( "\n No children found for $qterm in current Source/s", $verbose);
		push(@neighbors,"empty");
	}
	if(defined $siblings_ref){
		#print "\n siblings are @$siblings_ref";
		push(@neighbors,$siblings_ref);
	}
	else{
		#msg( "\n No siblings found for $qterm in current Source/s", $verbose);
		push(@neighbors,"empty");
	}
	
	undef $object_refr;
	return \@neighbors;
	
}


=head2 findUnique

This sub finds unique elements in an array.

=cut

sub findUnique
{

my $array_ref = shift;
my $qterm = shift;	
my @array = @$array_ref;
	
# The following code snippet to delete duplicate elements from an array is referred from
# perfaq4 and is modified according to need. For details refer :
# http://perldoc.perl.org/perlfaq4.html#How-can-I-remove-duplicate-elements-from-a-list-or-array%3f
# The first time the loop sees an element, that element has no key in %Seen .
# The next time the loop sees that same element, its key exists in the hash and the value for that key
# is true (since it's not 0 or undef), so the skip that iteration and the loop goes
# to the next element.

	my @unique = ();
	my %seen   = ();
	foreach my $elem (@array) {
		if ( $seen{$elem}++) {

		}
		else {
			unless($elem eq '1' | $elem eq '0' | $elem eq $qterm){
				
					push( @unique, $elem );
				
			}
			
		}
	}

	# Code snippet from perlfaq4 ends here.
	
	return \@unique;
	
}

# This sub formats the structures returned by the web service. It calls
# the appropriate subroutines depending on the type of structure
# it is called with. If the input reference is a hash reference it calls 
# format_homogenous_hash method. If input is array reference,
# it calls format homogenous array and simillarly for scalar input 
# reference it calls format_scalar.

=head2 format_object

This sub calls appropriate functions like format_homogenous_hash,
format_scalar, format_homogenous_array depending on the object reference it is called with.

=cut

sub format_object {

	my $object_ref = shift;

	#print "in format object";

	unless ( defined $object_ref ) {
		return 'undefined';
	}
	else {
		if ( $object_ref =~ /HASH/o ) {
			return format_homogeneous_hash($object_ref);
		}
		elsif ( $object_ref =~ /ARRAY/o ) {
			return format_homogeneous_array($object_ref);
		}
		elsif ( $object_ref =~ /SCALAR/o ) {
			return format_scalar($object_ref);
		}
		elsif ( defined $object_ref ) {
			return $object_ref;
		}
		else {
			return 'term is not present';
		}
	}
	
	undef $object_ref;
}


=head2 format_scalar

This sub formats scalar object.

=cut


sub format_scalar {
	my $scalar_ref = shift;
	#my $q = shift;
	
	#print "\n In format scalar";
	#print "\n scalar_ref is $$scalar_ref";
	format_object($$scalar_ref);
	
}



=head2 format_homogeneous_hash

This sub formats hash.

=cut

sub format_homogeneous_hash {
	
	my $hash_ref = shift;
	my $flag   = 0;
	my $flag2  = 0;
	my $t_flag = 0;
	my $c_flag = 0;
	my $current_term;
	my $current_cui;
	my $q_cui;
	my $q_term;
	my $relation;
	my $roflag = 0;
	my $relflag = 0;
	my $accept_rela  = 1;
	
	
	foreach my $att (keys %$hash_ref) {
		
		if ( $att =~ /\brel\b/) {
				if(defined $hash_ref->{$att})
				{
					if($hash_ref->{$att} ~~ %directions){
						if($hash_ref->{$att} ~~ @relationattr)
						{
							#msg("relation is :$hash_ref->{$att}", $verbose );
							$roflag = 1;
							#print "\n roflag : $roflag";
							$flag = 0;
							
						}
						else{
							#msg( "\n got relation $att : $hash_ref->{$att}", $verbose);
							$flag = 1;
							
							
						}
						$relation = $hash_ref->{$att};
						
					}
					else{
						$flag = 0;
					}
					
					
				}
		}
		
		if ( $flag == 1 || $roflag == 1 ) {
			if($att =~ /CN/){
				#print " \n got term , $att : $hash_ref->{$att}";
				$current_term = $hash_ref->{$att};
				$t_flag       = 1;
				
			}
			if($roflag == 1 && $att =~ /\brelA\b/){
				if($hash_ref->{$att} ~~ @attribute){  
					
					$relflag  = 1;
					#msg(" \n RELA : for term $current_term , $att : $hash_ref->{$att}",$verbose);
				}
			}
			
				if($roflag == 1 && $relflag == 0)
				{
					#print "\n not the rela I want";
					$accept_rela = 0;
				}
				if($roflag == 1 && $relflag == 1){
					$accept_rela = 1;
				}
				if($t_flag == 1 && $accept_rela == 1){
					#print "\n yehhhhhh got the rela I want";
					
					if(defined $hash_ref->{$att}){
					if($hash_ref->{$att} =~ /^C[0-9]/){
							
							$current_cui = $hash_ref->{$att};
							if(defined $current_cui){ #c 1
								unless ($current_cui ~~ %ConceptInfo){
									#msg(" \n got rela , $att : $hash_ref->{$att}",$verbose);				
									#print " \n inserting in hash $current_cui : $current_term";
									$ConceptInfo{$current_cui} = $current_term;
								}
								
								# Push all the respective neighbors in the the lists 
									if($directions{$relation} eq "U")
									{
										push(@parents, $current_cui);
									#	msg( " \n inserting in parent , relation is $relation $current_cui : $current_term",$verbose);
										#print " \n inserting in parents $current_cui : $current_term";
									}
									elsif($directions{$relation} eq "D")
									{
										push(@children, $current_cui);
									#msg( " \n inserting in children , relation is $relation $current_cui : $current_term",$verbose);
										
									}
									elsif($directions{$relation} eq "H")
									{
										push(@siblings, $current_cui);
										#print " \n inserting in siblings $current_cui : $current_term";
										
									}
								
							}
					}
					}
				}
			
		}
		
		if ( $att =~ /CN/ ) {				
					
					$q_term = $hash_ref->{$att};
					#print "\n got xtra term : $q_term";
					$c_flag = 1;
				}
				elsif( $att =~ /CUI|cui|Cui/){
					if($c_flag == 1){
						$q_cui = $hash_ref ->{$att};
						#print "\n got xtra cui : $q_cui";
						unless($q_cui ~~ %ConceptInfo){
							$ConceptInfo{$q_cui} = $q_term;
						}
						
					}
				}
		
		#Follwing regular expression is used to get just the required information.
		if ( $att =~ /contents|CUI|Concept|rels|Relation|relSources/ ) {

			format_object($hash_ref->{$att});	

		}	
		#format_object($hash_ref->{$att});		
	}

}


=head2 format_homogeneous_array

This sub formats array.

=cut

sub format_homogeneous_array {
	my $array_ref = shift;
	#print "\n in format array";
	foreach my $val (@$array_ref) {
	format_object($val);							   
	}	
}




=head2 extract_object_class

This sub is used to remove exact reference to object.

=cut

sub extract_object_class {
	my $object_ref = shift;

	# remove exact reference
	$object_ref =~ s/\(0x[\d\w]+\)$//o;

	my ($class, $type) = split /=/, $object_ref;

	my $res = undef;
	if ($type) {
		$res = $class;
	} else {
		$res = $object_ref;
	}
	
	
	return $res;
}

=head2 printHash

This sub prints argument hash.

=cut

sub printHash
{
	msg("\nIn print hash", $verbose);
	my $ref = shift;
	my %hash = %$ref;
	foreach my $key(keys %hash)
	{
		msg( "\n $key => $hash{$key}",$verbose);
	}
}


undef %ConceptInfo;
undef %directions;
undef @children;
undef @parents;
undef @siblings;


#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------



=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ws-getAllowablePath.pl 

=cut


=head1 AUTHORS

Mugdha Choudhari,             University of Minnesota Duluth
                             E<lt>chou0130 at d.umn.eduE<gt>

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>




=head1 COPYRIGHT

Copyright (C) 2011, Mugdha Choudhari, Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to 
The Free Software Foundation, Inc., 
59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut

#---------------------------------PERLDOC ENDS HERE---------------------------------------------------------------

1;
