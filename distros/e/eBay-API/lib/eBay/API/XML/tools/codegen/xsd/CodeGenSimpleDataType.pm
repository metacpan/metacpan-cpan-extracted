package # put package name on different line to skip pause indexing
    CodeGenSimpleDataType;

use strict;
use warnings;

use Exporter;
use BaseCodeGenDataType;
our @ISA = ('Exporter'
	    ,'CodeGenComplexDataType'
           );

use Data::Dumper;
use Element;

#
# use superclass new constructor
#

#
#  Overridden methods
#

sub _initElementsAndAttributes {

  my $self = shift;	
  my $rh= shift;

  my $rhRestrictions = $rh->{'xs:restriction'};
  if ( defined $rhRestrictions ) {

     my $sBase = $rhRestrictions->{'base'};

     if ( defined $sBase ) {

	 my $rhElem;
         my $pElement;	 

	    # 3.1 superclass name
	 my $typeNS = $sBase;
	 $typeNS = $self->validateType ( $typeNS );
	 $self->setSuperclassName( $typeNS );


	    # 3.2  elements
	    
           # each SimpleDataType type has just a value. 
	   # Value can be either a Primitive type or an Enum
           #   example: ItemIDType
           # Type value is defined by 'base' attribute
           #   generate setter/getter for value
           
           #  'content' property is a special property
           #    getValue and setValue are setters for 'content' property	 
	 my $internalName = 'content';
         $rhElem = {
		       'name'   => $internalName
                      ,'type' => $typeNS
		      ,'xs:annotation' => undef
		      ,'maxOccurs'    => undef
                   };		 

	 $pElement = Element->new( $rhElem );
         my @aElements = ();	      
	 push @aElements, $pElement;

	 $self->setElements (\@aElements );
     }
  }
}

1;
