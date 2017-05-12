package # put package name on different line to skip pause indexing
    CodeGenComplexDataType;

use strict;
use warnings;

use Exporter;
use BaseCodeGenDataType;
our @ISA = ('Exporter'
	    ,'BaseCodeGenDataType'
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

  #print Dumper($rh);

     # 1. elements

  my $raProperties = [];

  my $rhSequence = $rh->{'xs:sequence'};
  if ( defined $rhSequence ) {

     my $raElements = $rhSequence->{'xs:element'};	      

     my @arr = ();
     foreach my $rhElem (@$raElements) {

        my $pElement = Element->new( $rhElem );
        push @arr, $pElement;
     }

     $self->setElements (\@arr );
  }

	    # 2. attributes
  my $raAttributes = $rh->{'xs:attribute'};	      
  if ( (defined $raAttributes) && (scalar @$raAttributes) > 0) {

      my @arr = ();
      foreach my $rhElem (@$raAttributes) {

            my $pElement = Element->new( $rhElem );
            push @arr, $pElement;
      }
      $self->setAttributes (\@arr );
  }
}

#
# auxilary methods
#

sub _determineFullPackageName {
   
   my $self = shift;	
   
   my $str = $self->getRootPackageName()
                 . '::' . 'DataType'
                 . '::' . $self->getName();
   return $str;
}

sub _getSuperClassFullPackageName {
   my $self = shift;
      
   my $str = $self->getRootPackageName()
                 . '::' . 'BaseDataType';
   return $str;
}

sub _getClassBody {

   my $self = shift;
   
   my $sSuperClassPackage = $self->_getSuperClassFullPackageName();
   my $sClassPackage = $self->_determineFullPackageName();
   
   my $raElements   = $self->getElements();
   my $raAttributes = $self->getAttributes();

   my $strElementMethods = $self->_generatePropertyMethods (
	                        'raElements'=> $raElements
					);

   my $strAttributeMethods = $self->_generatePropertyMethods (
	                        'raElements'=> $raAttributes
					);

   my $strElementsList = 
                $self->_generatePropertyList( $raElements );
   my $strAttributesList = 
                $self->_generatePropertyList( $raAttributes );
		
   my @bothElementsAndAttributesPairs = ();
    # I added if (defined .... )
    #  because SearchSortOrderCodeList has undefined raProperties?!?!
   if ( defined $raElements ) {
      push @bothElementsAndAttributesPairs, @$raElements;
   }
   if ( defined $raAttributes ) {
      push @bothElementsAndAttributesPairs, @$raAttributes;
   }


  my $imports = $self->_generateImports(
	  		'raProperties'=>\@bothElementsAndAttributesPairs);

  my $strIsScalarMethod = '';

  my $hasIsScalarMethod = $self->hasIsScalarMethod();
  if ( $hasIsScalarMethod ) {

     my $isScalarDataType = $self->isScalar();
     $strIsScalarMethod = <<"IS_SCALAR";
sub isScalar {
   return $isScalarDataType; 
}
IS_SCALAR
}
  
  my $superDataTypeElements = 
        '@{' . $sSuperClassPackage . '::getPropertiesList()}';
  my $superDataTypeAttributes = 
        '@{' . $sSuperClassPackage . '::getAttributesList()}';


  my $packageBody = <<"PACKAGE_BODY";
=head1 INHERITANCE

$sClassPackage inherits from the L<$sSuperClassPackage> class

=cut

use $sSuperClassPackage;
our \@ISA = ("$sSuperClassPackage");

$imports

my \@gaProperties = ( $strElementsList
                    );
push \@gaProperties, $superDataTypeElements;

my \@gaAttributes = ( $strAttributesList
                    );
push \@gaAttributes, $superDataTypeAttributes;

=head1 Subroutines:

=cut

sub new {
  my \$classname = shift;
  my \%args = \@_;
  my \$self = \$classname->SUPER::new(\%args);
  return \$self;
}

$strIsScalarMethod

$strElementMethods

$strAttributeMethods

##  Attribute and Property lists
sub getPropertiesList {
   my \$self = shift;
   return \\\@gaProperties;
}

sub getAttributesList {
   my \$self = shift;
   return \\\@gaAttributes;
}

PACKAGE_BODY
   return $packageBody;
}

#
#  START 
#     methods used to generate DataType getters/setters (property methods)
#
#
sub _generatePropertyMethods {

  my $self = shift;
  my %args = @_;

  my $raElements      = $args{'raElements'};

  my $strProperties = '';
  foreach my $pElem ( @$raElements ) {

    my $name    = $pElem->getName();
    my $typeNS  = $pElem->getTypeNS();
    my $isArray = $pElem->isArray();

    my $pAnnotation = $pElem->getAnnotation();


    my $fullPackageName = '';   
    my $mustInstantiate = 0;
    
        # if it is an array, it does not make sense to instantiate 
	#    an object in a getter -- see 10 lines below for 
	#    'mustInstantiate' description

    if ( ! $isArray ) {

       my $pGenClass = $self->getDataTypeByDataTypeWithNS($typeNS);
       
       if ( defined $pGenClass  ) {

            # When retrieving a NON Scalar DataType property via its getter,
	    #  instantiate it if it is not already instantiated (defined).
	    #  Why?
	    # Basically that behavior allows the following usage:
	    #    my $sSellerId = $pItem->getSeller()->getUserID();
	    #
	    #  For more detailed explanation see:
	    #       BaseDataType::_getDataTypeInstance method for further 
	    #
         if ( ! $pGenClass->isScalar() ) {	 

	    $mustInstantiate = 1;
            $fullPackageName = $pGenClass->getFullPackageName();
         }
       }
    }

    my $internalName = $name;
       # special handling for 'content' property
    if ( $name eq 'content' ) {
       $name = 'value';
    }

    #
    #$type = validateType ($type);
    #
    $strProperties .= $self->_generateProperty('name'=>$name
	                       , 'typeNS'=>$typeNS
	                       , 'isArray'=>$isArray
        			       , 'pAnnotation' => $pAnnotation
	                       , 'fullPackageName'=>$fullPackageName
                           , 'mustInstantiate' => $mustInstantiate
	                       , 'internalName'=> $internalName) . "\n";
  }

  return $strProperties;
}

sub _generateProperty {

  my $self = shift;	
  my %args = @_;

  my $externalName = $args{'name'};
  my $typeNS       = $args{'typeNS'};
  my $isArray      = $args{'isArray'};
  my $pAnnotation  = $args{'pAnnotation'};
  my $fullPackageName = $args{'fullPackageName'};
  my $mustInstantiate = $args{'mustInstantiate'};
  my $internalName    = $args{'internalName'};

  if ( ! defined $internalName ) {
     $internalName = $externalName;
  }

  my $setterName = $self->getSetterName( $externalName );
  my $getterName = $self->getGetterName ($externalName, $typeNS );

  my $setterComment = $self->getSetterGetterComment(
                                    'propertyType'   => $typeNS
                                   ,'isArray'        => $isArray
			                       ,'pAnnotation'    => $pAnnotation
                                   ,'methodName'     => $setterName
                                   ,'setterOrGetter' => 'setter'
	                                           );

  my $getterComment = $self->getSetterGetterComment(
                                    'propertyType'   => $typeNS
                                   ,'isArray'        => $isArray
			                       ,'pAnnotation'    => $pAnnotation
                                   ,'methodName'     => $getterName
                                   ,'setterOrGetter' => 'getter'
	                                           );

  my $setterLine = "\$self->{'$internalName'} = shift";
     ## Use 'convertArray_To_RefToArrayIfNeeded method in order to 
     #  to be able to support the following types of parameters:
     #    a) reference to arrays 
     #          - for array properties programmers should always pass
     #            references to arrays
     #            still we support the two more types of parameters
     #    b) scalars   - internaly converted to a ref to an array  
     #    c) arrays    - internaly converted to a ref to an array
  if ( $isArray ) {
     $setterLine = "\$self->{'$internalName'} = \n\t\t" . 
     		'$self->convertArray_To_RefToArrayIfNeeded(@_);';
  }

  my $getterLine = "return \$self->{'$internalName'};";

     ## Use '_getDataTypeArray' method in order to gurantee 
     #  that a defined array will be returned.
     #  This allows us not to check whether the array is defined or not.
  if ( $isArray ) {

     $getterLine = "return \$self->_getDataTypeArray('$internalName');";
  } elsif ( $mustInstantiate == 1 ) {

     ## Use '_getDataTypeInstance' method in order to 
     #  to instantiate DataType properties on the fly
     #    See BaseDataType::_getDataTypeInstance

     $getterLine = "return \$self->_getDataTypeInstance( '$internalName'" .
	            "\n\t\t,'$fullPackageName');";
  }
  
  my $property = <<"PROP";

$setterComment
sub $setterName {
  my \$self = shift;
  $setterLine
}

$getterComment
sub $getterName {
  my \$self = shift;
  $getterLine
}
PROP

   return $property;
}

#
#  END 
#     methods used to generate DataType getters/setters (property methods)
#

sub _generatePropertyList {

  my $self = shift;	
  my $raElements = shift;

  my $strList = '';
  foreach my $pElem ( @$raElements ) {

    my $name    = $pElem->getName();
    my $typeNS  = $pElem->getTypeNS();
    my $isArray = $pElem->isArray();
    if ( $isArray == 0 ) {
       $isArray = '';	    
    }


    if ( $strList ne '' ) {
       $strList .= "\n\t, ";
    }
    $strList .= "[ '$name', '$typeNS', '$isArray'";

    
    my $pElemGenClass = $self->getDataTypeByDataTypeWithNS($typeNS);
    
    if ( ! defined $pElemGenClass ) {

       my $isComplexDataType = '';
       $strList .= ", '', '$isComplexDataType' ]";
    } else {
	    
       my $isScalar        = $pElemGenClass->isScalar();
       my $fullPackageName = $pElemGenClass->getFullPackageName();
       
       my $isComplexDataType = '';
       if ( $isScalar == 0 ) {
          $isComplexDataType = '1';
       }
       
       $strList .= "\n\t     ,'$fullPackageName', '$isComplexDataType' ]";

       if ( $isScalar ) {

	       # display real property type of given scalar  datatype
	       #   if you can find it.
          my $realPropertyTypeNS = '';

	  my $raElements = $pElemGenClass->getElements();
	  if ( (defined $raElements) && (scalar @$raElements) == 1) {
             my $pElem = $raElements->[0];
             $realPropertyTypeNS = $pElem->getTypeNS();
	  }

	  if ( $realPropertyTypeNS ne '' ) {

              $strList .= "  # " . $realPropertyTypeNS;
          }
       }
    }
  }

  return $strList;
}


sub _generateImports {

  my $self = shift;  
  my %args = @_;

  my $raProperties = $args{'raProperties'};

  my %hFound = ();

  foreach my $pElem ( @$raProperties ) {

     my $name    = $pElem->getName();
     my $typeNS  = $pElem->getTypeNS();

     my $pGenClass = $self->getDataTypeByDataTypeWithNS($typeNS);
     if ( ! defined $pGenClass ) {
        next;	    
     }

     my $fullPackageName = $pGenClass->getFullPackageName();
	    
     my $found = exists ( $hFound{$fullPackageName} );
     if ( $found ) {
        next;	    
     }
	        # put it into the list of already imported packages
     $hFound{$fullPackageName} = undef;
  }

  my @aPackages = sort { cmpUseStatements ($a, $b) } (keys %hFound);

  my $strImports = '';
  foreach my $fullPackageName ( @aPackages ) {

     $strImports .= "use $fullPackageName;\n";
  }

  return $strImports;
}

sub cmpUseStatements {

   my $firstPackage = shift;
   my $secPackage   = shift;

   my $isFirstEnum = ($firstPackage =~ m/::Enum::/o );
   my $isSecEnum   = ($secPackage   =~ m/::Enum::/o );

   if (  ($isFirstEnum && $isSecEnum)
       ||
         ( (!$isFirstEnum) && (!$isSecEnum) )
      ) {

      return ( $firstPackage cmp $secPackage); 	   
   }

   if ( $isFirstEnum && (!$isSecEnum) ) {
      return 1; 	   
   }

   if ( (!$isFirstEnum) && $isSecEnum ) {
      return -1; 	   
   }
   return 0;
}

1;

