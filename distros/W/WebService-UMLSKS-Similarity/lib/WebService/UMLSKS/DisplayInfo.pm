
=head1 NAME

WebService::UMLSKS::DisplayInfo - Display the required information like definitions, CUI about the input term.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::DisplayInfo;
    use WebService::UMLSKS::Query;
    
    my $display_obj =  new DisplayInfo;
    my $query = new Query;
    
    my $object_ref = $query->runQuery($service, $qterm,	'getConceptProperties', {params});
    # object_ref is a hash reference returned by web service getConceptProperties.
    my $object_f = $display_obj->display_object($object_ref); 
   

=head1 DESCRIPTION

This module has package DisplayInfo which has subroutines 'new', format _object, format_scalar, format_homogenous_hash, format_homogenous_array and extract_object_class.
This module displays required information about the concept.

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################


use strict;
use SOAP::Lite;
use warnings;
no warnings qw/redefine/;


package WebService::UMLSKS::DisplayInfo;

my $indentation = 0;

=head2 new

This sub creates a new object of DisplayInfo.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	#print "in new in display_info";
	bless( $self, $class );
	return $self;
}

=head2 display_object

This sub calls format_object.

=cut



sub display_object {
	my $self = shift;
	my $object_refr = shift;
	my $return_ref = format_object ($object_refr);
	#print "\n array : @t";
	return $return_ref;
}

# This sub formats the structures returned by the web service. It calls
# the appropriate subroutines depending on the type of structure
# it is called with. If the input reference is a hash reference it calls 
# format_homogenous_hash method. If input is array reference,
# it calls format homogenous array and simillarly for scalar input 
# reference it calls format_scalar.


=head2 format_object

This sub calls appropriate formatting sub.

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
}


=head2 format_scalar

This sub formats scalar object.

=cut

sub format_scalar {

	my $scalar_ref = shift;
	#print "in format_scalar";
	print $$scalar_ref;
	return format_object($$scalar_ref);

}



=head2 indent

This sub is used for indentation.

=cut

sub indent {

	#print "\n";
	my $number = shift;
	my $i;
	for ( $i = 0 ; $i < $number ; $i++ ) {
		print "  ";
	}

}


=head2 format_homogeneous_hash

This sub formats hash.

=cut

sub format_homogeneous_hash {
	$indentation++;
	my $hash_ref  = shift;
	#print "in format_hash";
	my @incl_rows = ();

	#print "\n";
	indent($indentation);

	#print "hash{";
	foreach my $att ( keys %$hash_ref ) {    #---- removed rels
		
		
		 #Follwing regular expression is used to display just the required information.
		if ( $att =~
/\bqueryInput\b|\brelease\b|\bkey\b|\bempty\b|\bperformance\b|\bperformanceMode\b|\bRAs\b|\bCAs\b|\bSTYs\b|\bdefs\b|\bConcept\b|\bterms\b|\bSGs\b|\bCOCs\b|\bCXTs\b|\bcontentClass\b|\bcontentClassName\b|\bSATUI\b|\bDefinition\b|\bAUI\b|\bATUI\b|\bcontents\b|\brels\b/
		  )
		{

		}
		else {    #----------------------------------------------------------
			
			if ( $att =~ /\brel\b/ && $hash_ref->{$att} =~ /RO|SIB/ ) {
				if (
					$att =~ /CUI|RUI|type|CN|autoGen|SRUI|directionality|relA/ )
				{

				}
			}
			elsif($att !~ /\bCUI\b/) {
			
				print "\n";
				indent($indentation);
				if ( $att =~ /CN/ ) {
					print "Preferred Term";
				}
				else {
					
					print $att;
				}
				print ":";

				print $hash_ref->{$att};
			
			}
		}
	

  #---added rels,relation and relsources
  #Follwing regular expression is used to display just the required information.
			if ( $att =~
				/contents|CUI|CN|defs|Concept|rels|Relation|relSources/ )
			{
				if ( $att =~ /defs/ ) {
					my $def_ref = $hash_ref->{$att};

					my $contents_def_ref = $def_ref->{"contents"};
					if ( !@$contents_def_ref ) {

						# if content_ref is empty

						print
"\n\tThere are no definitions available for your query term/CUI in UMLS using current configuaration.";

					}
				}

				push @incl_rows, $att, format_object( $hash_ref->{$att} );
			}
		
		

	}

	#print "};";
	$indentation--;

	#my $bgcolor = $BGCOLOR{extract_object_class($hash_ref) || 'HASH'};
	#my $incl_table = $q->table({border => 1, bgcolor => $bgcolor}, @incl_rows);
	return @incl_rows;
}



=head2 format_homogeneous_array

This sub formats array.

=cut

sub format_homogeneous_array {
	$indentation++;
	my $array_ref = shift;
	#print "in format_array";
	my @incl_rows = ();

	#print "\n";
	indent($indentation);

	#print "array(";
	foreach my $val (@$array_ref) {

		if ( $val =~ /contents|Definition|Concept/ ) {
			if ( $val =~ /contents/)
			{
				
			}
		}
		else {
			if ( $val =~ /Definition|defs/ ) {
				if ( !@$array_ref ) {
					print "There is no $val information for this query";
				}
			}

			#indent($indentation);
			print "\n";
			indent($indentation);
			print $val;
		}
		push @incl_rows, format_object($val);

	}

	#print ");";
	$indentation--;
	@incl_rows = ('no values') unless @incl_rows;

	#my $bgcolor = $BGCOLOR{extract_object_class($array_ref) || 'ARRAY'};
	#my $incl_table = $q->table({border => 1, bgcolor => $bgcolor}, @incl_rows);
	return @incl_rows;
}



=head2 extract_object_class

This sub is used to remove exact reference to object.

=cut

sub extract_object_class {
	my $object_ref = shift;

	# remove exact reference
	$object_ref =~ s/\(0x[\d\w]+\)$//o;

	my ( $class, $type ) = split /=/, $object_ref;

	my $res = undef;
	if ($type) {
		$res = $class;
	}
	else {
		$res = $object_ref;
	}

	return $res;
}



#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------



=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ws-getUMLSInfo.pl 

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
