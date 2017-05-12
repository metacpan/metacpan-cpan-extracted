#!/usr/bin/perl -w

###############################################################################
#
# Module: ............... <user defined location>eBay/API/XML
# File: ................. BaseDataType.pm
# Original Author: ...... Milenko Milanovic
# Last Modified By: ..... Robert Bradley / Jeff Nokes
# Last Modified: ........ 03/06/2007 @ 16:47
#
###############################################################################

package eBay::API::XML::BaseDataType;

#
# BUG FIXES:
#  1.  XML:Simple parses empty tags into a hash reference?!?!
#          <Location> </Location> converted into 'Location' => {}
#       Changed _formatScalarIfNeeded to convert such tags into 
#             an empty string
#    

use strict;

use Exporter;
our @ISA = ('Exporter');

use Data::Dumper;
use Scalar::Util 'blessed';
use XML::Writer;
use XML::Simple;
use Encode;

    # During deserialization, convert boolean string values 'true' and 'false' 
    #   to 1 and 0, respectively
use constant DESERIALIZE_BOOLEAN_STRING_TO_NUMBER => 1;

    # During deserialization, print to stdout object instantiantiation tree
use constant DISPLAY_RECURSION => 0;

# $] variable returns perl version.
#  For further description of $gsTurnOffUtf8OnSerializedString variable
#  see comments at the place the variable is being used.
my $gsTurnOffUtf8OnSerializedString = ($] eq '5.008001');

=head1 Subroutines:

=cut

=head2 new()

=cut

sub new {
  my $classname = shift;
  my $self = {};
  bless ($self, $classname);
  $self->_init( @_ );
  return $self;
}

sub _init {
  my $self = shift;
   
  if ( @_ ) {
     my %extra = @_;
     @$self{ keys %extra } = values %extra;
  }
}


=head2 serialize()

=cut

sub serialize {
   my $self    = shift;
   my $tagName = shift;

   if (! defined $tagName ) {
      $tagName = $self;
   }

   my $strOutput = '';
   
   my $pXmlWriter = XML::Writer->new(   OUTPUT => \$strOutput
#	                              , DATA_MODE => 'true'
#	   			      , DATA_INDENT => 2 
			           );
     # add '<?xml version="1.0" encoding="utf-8"?>'
     #  at the top of document, otherwise API call throws 
     #  'soapenv:Body must be terminated by the matching end-tag 
     #              "</soapenv:Body>"' error!!!
   $pXmlWriter->xmlDecl("UTF-8");				   
   my $isTopLevel = 1;
   $self->_serializeInner( $tagName, $pXmlWriter, $isTopLevel);
   $pXmlWriter->end();

        # I had to add this Encode stuff. 
        # Without this when I serialize datatypes containing Chinese signs
        # I get '500 Wide character in syswrite' error on production machines 
        # running Perl 5.8.1 on RedHat 7.2
        # This is not needed when running on Perl 5.8.7  
        #  That is why I dynamicly determine whether to use 'Encode::_utf8_off'
        #  or not.
        #     mmilanovic, 06/11/2006, 20:00
   if ($gsTurnOffUtf8OnSerializedString) {
        Encode::_utf8_off($strOutput);
   }

   return $strOutput;
}

#
# protected
#
sub _serializeInner {

  my $self    = shift;
  my $tagName = shift;
  my $pXmlWriter = shift;
  my $isTopLevel =  shift || 0;

  my $raProperties  = $self->getPropertiesList();
  my $raAttributes  = $self->getAttributesList();
   
    # Do not serialize DataType property that has no
    #   properties (keys in its hash).
    #   We should not serialize a data type object whose tree is 
    #     completely empty (we should not have empty tags in generated
    #     XML document. 
    #   Well, I think verifing that an object has no properties is a 
    #   good enough verification. 
  if ( ! $isTopLevel ) {
     if ( (scalar (keys %$self)) == 0 ) {
    	return;
     }     
  }     

   #  1. serialize attributes
  my %hAttr = ();
  foreach my $raAttr (@$raAttributes) {
      my $key = $raAttr->[0];
      my $value = $self->{$key};
      if ( defined $value ) {
    	 $hAttr{$key} = $value;
      }
  }
  $pXmlWriter->startTag($tagName, %hAttr);

    # 2. serialize properties
  foreach my $prop (@$raProperties) {

      my $key = $prop->[0];
      my $value = $self->{$key};
     
      if ( $key ne 'content' ) {
         if ( defined $value ) {
           if ( ref($value) eq 'ARRAY' ) {
             foreach my $elem (@$value) {
                _serializeValue( $key, $elem, $pXmlWriter);
             }
           } else {
                _serializeValue( $key, $value, $pXmlWriter);
           }
         }
      }
  }

   # 3. serialize content
     # It is possible that element has some primitive value and attributes
     # In our case this happens to types like AmountType 
  my $content = $self->{'content'};
  if ( defined $content ) {
    $pXmlWriter->characters( $content  );
  }

  $pXmlWriter->endTag();
}

#
# protected
#
sub _serializeValue {
   my $key   = shift;
   my $value = shift;
   my $pXmlWriter = shift;
   
   my $isRef = ref($value);
   if ( $isRef ) {
     $value->_serializeInner($key, $pXmlWriter);
   } else {
     $pXmlWriter->startTag( $key );
     $pXmlWriter->characters( $value );
     $pXmlWriter->endTag( );
   }
}


=head2 deserialize()

parameters:

   1. rhXmlSimple    - Data structure created by parsing an XML str with
                       XML::Simple

   2. recursionLevel - Level of recursion, this is an optional argument
                       and it is used for debuging purposes only. 
                       If constant DISPLAY_RECURSION is set to 1, 
                       recursionLevel is used to pretty print the output
		       tracing the recursion.

   3. sRawXmlString  - XML string used to set objects properties. The string is
                       first parsed by XML::Simple. Data structure that is 
                       received after parsing is used to populate object's
                       properties (it overrides 'rhXmlSimple' parameter). 
		       'sRawXmlString' parameter should be used for test 
		       purposes only!!

=cut

sub deserialize {

  my $self = shift;
  my %args = @_;

  my $raAttributes  = $self->getAttributesList();
  my $raProperties  = $self->getPropertiesList();

  my $rhXmlSimple = $args { 'rhXmlSimple' };

    # 'sRawXmlStr' parameter overrides 'rhXmlSimple' parameter and
    #  it should be used for test purposes only
  my $sRawXmlStr  = $args { 'sRawXmlString' };
  if  ( defined $sRawXmlStr ) {
      eval {
         $rhXmlSimple = XMLin( $sRawXmlStr,
                              ,forcearray => []
                              ,keyattr => [] );
      };
      if ( $@ ) {
         print $@ . "\n";
	 print "error during XML parsing, object "
	       . blessed ($self) 
	       . " not properly deserilized\n";
            # This piece of code is should be used for testing purposes ONLY!!
	    #	       
         return;	 
      }
  }
   ### print recursion is used only for debug purpose
  my $recursionLevel = $args {'recursionLevel'};
  if ( ! defined $recursionLevel ) {
    $recursionLevel = 1;
  }
  

  #print 'Deser: ' . Dumper($self);
  if ( DISPLAY_RECURSION == 1 ) {
    my $ident = ($recursionLevel-1) * 2;
    my $tmpStr = pack("c$ident", 32);
    print $tmpStr . "Deserializing {$recursionLevel}-> " 
    					. blessed($self) . "\n";
  }
  # 1. deserialize all properties

  foreach my $prop (@$raProperties) {

    my $key                  = $prop->[0];
    my $typeNS               = $prop->[1];
    my $isArrayInMetaData    = $prop->[2];
    my $sPropertyPackageName = $prop->[3];
    my $isComplexDataType    = $prop->[4];

    my $value = $rhXmlSimple->{$key};

    if ( defined $value ) {

      my $isArrayInXml = (ref($value) eq 'ARRAY');
      my $isArray = ($isArrayInXml || $isArrayInMetaData);

	  ## AmountType might be both, scalar and DataType
	  #   if it is a scalar process it like a scalar

      my $isScalar = isScalar ( $value, $isComplexDataType );

      if ( $isArray ) {                      ### 1. array

	 my @inputArray = undef;
	 
	 if ( $isArrayInXml ) {
		 
	    @inputArray = @$value;
         } elsif ($isArrayInMetaData ) {            ### property is an array
		                                    ### but there is only
						    ### one element in that
						    ### array
	    @inputArray = ( $value );
	 }
	 
         my @arr = ();
	 foreach my $elem ( @inputArray ) {

	    if ( isScalar ($elem, $isComplexDataType ) ) {
                                                    ### 1.1 array of scalars
	       push @arr, _formatScalarIfNeeded ($elem, $typeNS);
	    } else {
                                                    ### 1.2 array of objects
	       my $pTmpType = $self->deserializeObject(
		                                  $sPropertyPackageName
						, $elem
	                                        , $recursionLevel);

	       push @arr, $pTmpType;
            }	    
         }
	 $self->{$key} = \@arr;

      } elsif ( $isScalar ) {                 ### 2. scalar

         $self->{$key} = _formatScalarIfNeeded( $value, $typeNS) ;
      } else {                                ### 3. object

	 my $pTmpType = $self->deserializeObject (
		                           $sPropertyPackageName, $value
	                                  ,$recursionLevel);
         $self->{$key} =  $pTmpType; 
      }
    }
  }


  # 2. get attributes
  foreach my $raAttr (@$raAttributes) {
      my $key = $raAttr->[0];
      my $value = $rhXmlSimple->{$key};
      if ( defined $value ) {
	 $self->{ $key } = $value;
      }
  }

  # 3. get content
  	# not needed, it will be read within 1.
  #my $content = $rhXmlSimple->{'content'};
  #if ( defined $content ) {
  #   $self->setValue($content);
  #}
}

=pod

=head2 _formatScalarIfNeeded

Access level: private

1. 'xs:boolean'

XML schema API calls for boolean values return 'true' and 'false'. During
deserilization we convert API boolean values to perl's boolean values:

    1 (true) and 0 (false).

2.  XML:Simple parses empty tags into a hash reference?!?!
    <Location> </Location> converted into 'Location' => {} 

=cut


sub _formatScalarIfNeeded {
   my $value = shift;
   my $typeNS = shift;

   my $ret = $value;

           #
	   #  XML:Simple parses empty tags into a hash reference?!?!
	   #    examples:
	   #  <Location> </Location> 
	   #  <Location></Location> 
	   #  <Location/>
	   #              are parsed into 'Location' => {}
	   #  <Location>test_value</Location>  
	   #              is parsed into 'Location' => 'test_value'
	   #  That is why - if we have a scalar property
	   #     and if XML::Simple parsed that property into a hash ref
	   #       I am converting that property into an empty value.
	   #
   if ( ref($value) eq 'HASH' ) {
        if ( _isEmptyHash($value) ) {
	   $ret = '';
	}
   }
           ## special handling for 'boolean' values
   if ( DESERIALIZE_BOOLEAN_STRING_TO_NUMBER ) {
       if ( $typeNS eq 'xs:boolean' ) {

          if ( $ret eq 'true' ) {
             $ret = 1;
          }	else {
             $ret = 0;
          }
       }
   }
   
   return $ret;
}


sub deserializeObject {

   my $self = shift;	
   my $sObjectPackageName = shift;	
   my $rhInnerXmlSimple   = shift;
   my $recursionLevel = shift || 1;

   $recursionLevel++;

    #  Instantiate a property that is an object
   my $pTmpType = $sObjectPackageName->new(); 

   if ( ref($rhInnerXmlSimple) ne 'HASH' )  {

	 #   This is a HACK to support shorthand SimpleType data type 'value'
	 #            initialization  !!!!
	 #   I consider it to be a dangerous hack but it seems that is working!!
	 #          mmilanovic, 02/20/2006

	 # This code is used by SimpleTypes 
	 #        (those data types have setValue property).
	 # Examples of such data types are: AmountType, UserIDType, ItemIDType.
	 # The code covers a case when a setter receives a scalar value
	 # instead of a real SimpleType data type object. 
	 # In that case we assume that the scalar represents SimpleType 
	 #    data type value!!

	 #  This is covered in Unit test: 
	 #  testBaseDataType.pl
	 #    section: Test Simple type deserilization
	 #       test:	'partial OO test'
	 #
	 
      if ( $pTmpType->can('setValue') ) {	   
         my $value = $rhInnerXmlSimple;	      
         $pTmpType->setValue($value);	   
      }
   } else {

      $pTmpType->deserialize('rhXmlSimple' => $rhInnerXmlSimple
                          ,'recursionLevel' => $recursionLevel); 
   }
   return $pTmpType;
}

sub isScalar {
   my $value                = shift;
   my $isComplexDataType    = shift;

      # Complex data is any DataType which is being generated
      #  and does not contain "::Enum::" in its full package name

   if ( $isComplexDataType ) {
      return 0;
   }

   return 1;      
}


sub getPropertiesList {
  return [];  # reference to an array
}

sub getAttributesList {
  return [];  # reference to an array
} 

=head2 convertArray_To_RefToArrayIfNeeded()

Some DataType setters set reference to an array and this function is used in
such setters to convert passed paremeter to 'a reference to an array' if one
is not passed. 

Example: 

     DataType: FeesType.pm has 'setFee' setter. This setter expects 
               a reference to an array to be passed.

Still, we will support 3 types of parameters:

  1. parameter is a reference to an array, no conversion (just as should be)

  2. parameter is an array, convert it to a reference to an array

  3. parameter is a scalar, create an array with one element and
         then create a reference to that array

This method is used in setters that expect a parameter of
'a reference to an array' type

The generated setters look like the following one:

 sub setProperty {
    my $self = shift;
    $self->{'property'} = $self->convertArray_To_RefToArrayIfNeeded(@_);
 }

=cut 

sub convertArray_To_RefToArrayIfNeeded {
  my $self = shift;
  my @arr  = @_;
  my $testElem = $_[0];

  my $ra = undef;
  if ( defined $testElem ) {   # if there is at least one parameter
     
     my $length = scalar @arr;
     if ( $length == 1 ) {     # there is only one parameter
        my $elem = $arr[0];
        if ( ref($elem) eq 'ARRAY' ) { # the parameter is an array ref
           $ra = $elem;
        } else {
           $ra = [ $elem ];            # the parameter is a scalar
        }
     } else {                  # there are more than one parameter
        $ra = \@arr;                   # consider that an array has been passed
     }
  }
  return $ra;
}

=pod

=head2 _getDataTypeInstance()

Used in getters that return a BaseDataType object.
If the object is not defined, it instantiate it.

This allows the following syntax:

     my $sSellerId = $pItem->getSeller()->getUserID();

Otherwise we would have to write something like this:

     my $pSeller = $pItem->getSeller();
     if ( defined $pSeller ) {
        $SellerId = $pSeller->getUserID();
     }

=cut



sub _getDataTypeInstance {
   my $self = shift;

   my $propertyName            = shift;
   my $propertyFullPackageName = shift;
	        
   my $pObj = $self->{$propertyName};
   if ( ! defined $pObj ) {
      $pObj = $propertyFullPackageName->new();
      $self->{$propertyName} = $pObj;
   }
   return $pObj;
}

=head2 _getDataTypeArray()

Used in getters that return an array.

If the array is not defined instantiate it.

Internally all arrays are stored as references to an array.
Depending on calling context, this method returns either an array or
a reference to an array, which means we can use both of the following syntaxes:

 my $ra = $pType->_getDataTypeArray();  # returns a ref to an array
 my @a = $pType->_getDataTypeArray();   # returns an array

=cut

sub _getDataTypeArray {
   my $self = shift;

   my $propertyName            = shift;
	        
   my $ra = $self->{$propertyName};
   if ( ! defined $ra) {
      $ra = [];
      $self->{$propertyName} = $ra;
   }
   return wantarray ? @$ra : $ra;
}

=head2 isEmpty()

Returns: 

	1 - If hash containing object properties is empty.

        0 - If hash conatining object properties is not empty

Basically this means that:

        "scalar (keys @$self )" returns 0

        or "scalar %$self" returns 1

=cut

sub isEmpty {
   my $self = shift;
   return _isEmptyHash( $self);
}

sub _isEmptyHash {
   my $rh = shift;
   
     # scalar %hash returns a true value if hash has elements defined
   my $ret = scalar %$rh;

   return ! $ret;
}
1;
