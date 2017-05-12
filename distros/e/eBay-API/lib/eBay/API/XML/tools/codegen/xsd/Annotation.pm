################################################################################
# Location: ............. <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. Annotation.pm
# Original Author: ...... Milenko Milanovic
#
################################################################################

=pod

=head1 Annotation

Generate annotations/documentation for the classes.

=cut

package # put package name on different line to skip pause indexing 
    Annotation;
  
use strict;
use warnings;

use Exporter;

use Data::Dumper;

sub new {

  my $classname = shift;
  my $rhXmlSimple = shift;

  my $self = {};
  bless($self, $classname);

  #print "11.rhAnnotation=|" . Dumper($rhXmlSimple) . "\n";

     # 1. set documentation property
  my $sDocumentation = $rhXmlSimple->{'xs:documentation'};
       # Sometimes XML::Simple returns a hash for documentation:
       #    Example: VerifyAddItemRequestType ( property: 'ExternalProductID'
       # In such cases create sDocumentation by concatenating 
       #  values from the hash.
       #
  if ( defined $sDocumentation && ref($sDocumentation) eq 'HASH' ) {

     my @values = values %$sDocumentation;
     if ( (scalar @values ) == 0 ) {
        $sDocumentation = '';
     } else {
        @values = sort { length($a) <=> length($b) } @values;     
        $sDocumentation = join("\n", @values);
     }
  }
  $self->setDocumentation( $sDocumentation );

     # 2. find all calls and attributes related to them

	  #  sets:
	  #  $self->setCallsInfo( ); an array of CallInfo-s
	  #  $self->setAdditionalAppInfo (); a string
  $self->_initAppInfo( $rhXmlSimple->{'xs:appinfo'} );

  return $self;  
}

sub _initAppInfo {

   my $self = shift;
   my $refAppInfo = shift;
   
   my $rArrObjCallInfo = [];
   my $sAdditionalAppInfo = '';

##############################################   
   if ( defined $refAppInfo ) {

		
      my $rArrHashAppInfo = 
	    $self->getAnnotationAppInfoAsArrayOfCallInfos( $refAppInfo );

      my $addAppInfo = '';	   
      foreach my $rhAppInfo ( @$rArrHashAppInfo ) {

	 my $refCallInfo = $rhAppInfo->{'CallInfo'};	   

	    #
	    # retrieve additional app info for current property
            #  This is really strange: 
            #  I found a few more elements in rhAppInfo hash table:
            #    SiteInfo, Constraint, APIInfo
            #  They are extramly rarely used. I will concatenate them into one
            #    generic variable: 'additionalAppInfo'
	    #
	 delete $rhAppInfo->{'CallInfo'};
	 $sAdditionalAppInfo .= createAddAppInfo (
		                   $rhAppInfo, $sAdditionalAppInfo );

	  # Sometimes 'refCallInfo' contain an array of elements
	  #   and sometimes it contains just one element
	  #   'CallInfo' => {
	  #                  'CallName' => 'GetMyeBayBuying',
	  #                  'RequiredInput' => 'No',
	  #                  'Context' => 'WatchList'
	  #                  }
	  #   So if a hash ref is returned, added it to an array.
			
	 if ( ! defined $refCallInfo ) {
  	    next;	      
	 }	      

	 my $raCallInfo = hashMakeSureItsArray ( $refCallInfo,
	'WARNING: refCallInfo IS NEITHER ref to a hash NOR  a ref to an array!?'
					);

	 foreach my $rhCallInfo ( @$raCallInfo ) {

	    # pass a hash, rather then a hash ref
	    my $pCallInfo = Annotation::CallInfo->new ( %$rhCallInfo );	      
	    push @$rArrObjCallInfo, $pCallInfo;
	 }
      }	   
   }

##############################################   

   $self->setAdditionalAppInfo($sAdditionalAppInfo);
   
   $self->setCallsInfo( $rArrObjCallInfo );
}

=head2 createAddAppInfo()

Some times there are a few more elements in rhAppInfo hash table:

   SiteInfo, Constraint, APIInfo

They are rarely used. Concatenate them into one
generic variable: 'additionalAppInfo'


=cut

sub createAddAppInfo {
	
   my $rhAppInfo = shift; 
   my $sResult   = shift;

   my @keys = keys %$rhAppInfo;
   if ( (scalar @keys) > 0 ) {

      foreach my $key ( @keys ) {

	 $sResult .= "$key: ";	   
         my $value = $rhAppInfo->{$key};
         if ( ref ($value) eq 'ARRAY' ) {

	     my $cnt = 0;
             foreach my $elem ( @$value ) {
		if ( $cnt > 0 ) {
                   $sResult .= ", ";			
		}
		if ( ref($elem) eq 'HASH' ) {
                   $sResult = createAddAppInfo ( $elem, $sResult );
	        } else {
                   $sResult .= $elem;	      
		}
		$cnt++;
	     }		  
	     $sResult .= "\n";
         } elsif ( ref ($value) eq 'HASH' ) {
   
             $sResult = createAddAppInfo ( $value, $sResult );
         } else {
   
            $sResult .= $value . "\n";	      
         }
      }
   }

   return $sResult;
}

sub getAnnotationAppInfoAsArrayOfCallInfos {
	
   my $self = shift;	
   my $refAppInfo = shift;  # reference to a structure containing property's
                            #  AppInfo. The structure can be either
			    #  a ref to a hash or a ref to an array

     #
     # In a very few cases, xs:appinfo can be an array
     #  Actually I found only one such case:
     #    CategoryType.NumOfItems
     # This means that we have to assume that array is always returned
     #



#       All except one case have 'xs:appinfo' as a ref to a hash
#       convert the following into an array
# $VAR1 = {
#           'CallInfo' => {
#                         'CallName' => 'AddDispute',
#                         'RequiredInput' => 'Yes'
#                         }
#         };


#       This is already an array, nothing to do!!
#       The only property that has 'xs:appinfo' as array is:

#          CategoryType.NumOfItems
# $VAR1 = [
#           {
#             'CallInfo' => {
#                           'Returned' => 'Conditionally',
#                           'CallName' => [
#                                         'GetCategoryListings',
#                                         'GetSearchResults'
#                                       ],
#                           'Context' => 'CategoryArray'
#                         }
#           },
#           {
#             'CallInfo' => {
#                           'Returned' => 'Conditionally',
#                           'CallName' => 'GetCategoryListings',
#                           'Context' => 'CategoryArray'
#                         }
#           }
#         ];


   my $rArrHashCallInfo = hashMakeSureItsArray ( 
	                      $refAppInfo,
      'WARNING: refAppInfo IS NEITHER ref to a hash NOR  a ref to an array!?');	   
   return $rArrHashCallInfo;
}

=head2 hashMakeSureItsArray()

Arguments: 

  1. [R] Either a hash ref or an array ref
  2. [0] Warning message if previous parameter is not a reference.

Returns: 

  an array ref

Description: 

If there are multiple elements with a same name, XML:Simple return
them as a reference to an array, otherwise it returns a
value.

The problem is that for some XML document, the element appears only
once in the structure, while for other documents, more
than once.

Here, we make sure that such elements are returned in a array
even in cases when there is only one element. 
Obviously we do this only for elements that we know can be returned
as an array.

=cut 

sub hashMakeSureItsArray {

   my $ref = shift;
   my $notArefMessage = shift;

   my $ra;
   if ( ref ( $ref ) eq 'HASH' ) {
	   
      $ra = [ $ref ];	   
   } elsif ( ref ( $ref ) eq 'ARRAY' ) {

      $ra = $ref;	   
   }

   if ( ! defined $ra && defined $notArefMessage ) {
      print "$notArefMessage\n";
      #print Dumper( $ref );
      #$ra = [];	   
   }

   return $ra;
}

=head2 scalarMakeSureItsArray()

Argument: 

  1. [R] Either an array ref or a scalar

Returns: 

  an array ref

Description: 

If there are multiple elements with a same name, XML:Simple
return them as a reference to an array, otherwise it returns
a value.

The problem is that for some XML document, the element appears
only once in the structure, while for other documents, more than
once.

Here, we make sure that such elements are returned in a array
even in cases when there is only one element. 
Obviosly we do this only for elements that we know can be returned
as an array.

=cut 

sub scalarMakeSureItsArray {
	
   my $ref = shift;

   my $ra;
   if ( defined $ref ) {

	if ( ref ($ref) ne 'ARRAY' ) {

	    $ra= [ $ref];
        } else {
	    $ra= $ref;
	}	
   }

   return $ra;
}

sub getDocumentation {
  my $self = shift;
  return $self->{'sDocumentation'};
}

sub setDocumentation {
  my $self = shift;
  $self->{'sDocumentation'} = shift;  
}

sub getAdditionalAppInfo {
  my $self = shift;
  return $self->{'sAdditionalAppInfo'};
}

sub setAdditionalAppInfo {
  my $self = shift;
  $self->{'sAdditionalAppInfo'} = shift;  
}

sub getCallsInfo {
  my $self = shift;
  return $self->{'raCallInfo'};
}

sub setCallsInfo {
  my $self = shift;
  $self->{'raCallInfo'} = shift;  
}

sub getCallsInfoInput {
  my $self = shift;
  return $self->_getCallsInfoByType('isInputArgument');
}

sub getCallsInfoOutput {
  my $self = shift;
  return $self->_getCallsInfoByType('isOutputProperty');
}

sub _getCallsInfoByType {
  my $self = shift;
  my $sTestMethodName = shift;

  my $raCallsInfo = $self->getCallsInfo();
  my @arr = ();
  foreach my $pCallInfo (@$raCallsInfo) {
     
     my $isType = $pCallInfo->$sTestMethodName();
     
     if ( $isType ) {
        push @arr, $pCallInfo;	     
     }
  }
  
  return \@arr;
}


#
# END package 'Annotation'
#


#
# package Annotation::CallInfo;
#

=pod

=head1 Annotation::CallInfo

Manage call information for the annotations.

=cut


package #
    Annotation::CallInfo;

use Data::Dumper;

=head2 new()

Arguments: 

     a hash containing the following values:

     1.  'CallName' and 'Context' are arrays

         'Returned' => 'Conditionally',
         'CallName' => [
                'GetBidderList',
                'GetItem',
               ],
          'Context' => [
               'BidList',
               'LostList',
               'WonList'
              ] 
          'MaxLength' => '32',

      2.  'CallName' and 'Context' are just scalars
          'Returned' => 'Conditionally',
          'CallName' => 'GetBidderList',
          'MaxLength' => '32',
          'Context' => 'WatchList'

NOTE: 'CallName' and 'Context' can be either an array or a scalar. 

This structure has to be converted into a set with 3 elements:

  a) callNames   - array ref
  b) attributes  - hash ref ('RequiredInput', 'Returned', 'MaxLength')
  c) context     - array ref

=cut

sub new {
	
   my $classname = shift;	
   my %args      = @_;

   my $self = {};
   bless( $self, $classname );

      # 1. initialize object properties
      
   my $raCallNames  = undef;
   my $raContext    = undef;
   my $rhAttributes = {};

        # 1.1  callNames
   my $refCallNames = $args{'CallName'};
   $raCallNames = Annotation::scalarMakeSureItsArray ( $refCallNames );
		
	# 1.2. find attributes

   my @keys = keys %args;
   foreach my $key (@keys) {

      if ( $key ne 'CallName' && $key ne 'Context' ) {
	   $rhAttributes->{ $key } = $args{$key}; 
      }
   }	

	# 1.3. context(s)
   my $refContext = $args{'Context'};
   $raContext = Annotation::scalarMakeSureItsArray ( $refContext );
   
   $self->_setCallNames( $raCallNames );
   $self->_setAttributes( $rhAttributes);
   $self->_setContext( $raContext );

   $self->_setIsInputArgument ( 0 );
   $self->_setIsOutputProperty ( 0 );
   
     # 2. Run additional logic to separate Input/Output arguments/properties
     #    from the rest of attributes

      # Set type!!
      #
        # Type can have two values: 'input' or 'output'
        # 'input'  - property is used as an argument for listed calls
        # 'output' - property is being retrieved by listed calls

	     # RequiredInput  - input argument
	     # Returned       - output property
   my $isTypeSet = 0;
       
   if ( exists ($rhAttributes->{'RequiredInput'}) ) {
      $self->_setIsInputArgument ( 1 );
      $isTypeSet = 1;
   } 

   if ( exists ( $rhAttributes->{'Returned'} ) ) {
      $self->_setIsOutputProperty ( 1 );
      $isTypeSet = 1;
   } 

   if (  ! $isTypeSet ) {
      my @keys = keys %$rhAttributes;
      #print Dumper($rhAttributes);
      #print "Annotations: cannot determine type from following keys:\n"
      #       . "\t" . join (',', @keys);
   }

   return $self;
}

=head2 _setCallNames()

Arguments: a reference to an array containg scalars (strings)

Description: Array contains names of calls for which the given property is
             used.

=cut

sub _setCallNames {
   my $self = shift;
   $self->{'raCallNames'} = shift;   
}

=head2 getCallNames()

Returns: a reference to an array containg scalars (strings)

Description: Array contains names of calls for which the given property is
             used.

=cut

sub getCallNames {
   my $self = shift;
   return $self->{'raCallNames'};   
}


=head2 _setAttributes()

Arguments: a reference to a hash. 
           Hash element definition:
	      key   - attribute name (scalar string
	      value - attribute value (scalar string)

Description: Hash contains all attributes common for all calls defined with
             current instance of CallInfo

=cut

sub _setAttributes {
   my $self = shift;
   $self->{'rhAttributes'} = shift;   
}

=head2 getAttributes()

Arguments: a reference to a hash. 

Description: see getAttributes

=cut

sub getAttributes {
   my $self = shift;
   return $self->{'rhAttributes'};   
}

=head2 _setContext()

Arguments: a reference to an array containg scalars (strings)

Description: Array contains context names in which the given property is
             being used.

=cut

sub _setContext {
   my $self = shift;
   $self->{'raContext'} = shift;   
}

=head2 getContext()

Returns: a reference to an array containg scalars (strings)

Description: Array contains context names in which a given property is
             being used.

=cut

sub getContext {
   my $self = shift;
   return $self->{'raContext'};   
}

=head2 getInputOutputAttribute()

Returns: reference to a hash
         The hash contains either all Input/Output attributes
         of all calls contained in this CallInfo instance. 

Attribute can be both, input argument and output property

1. For calls where the property is used as an input argument 
       return: 'RequiredInput' attribute name

2. For calls where the property is used as an output property 
       return: 'Returned' attribute name

=cut

sub getInputOutputAttributeName {

   my $self = shift;

   my $rhAttributes = $self->getAttributes();

   my @aInputOutputAttrNames = ('RequiredInput', 'Returned');
   my %hIO = ();
   foreach my $attrName ( @aInputOutputAttrNames ) {
      $hIO { $attrName } = $rhAttributes->{$attrName };
   }

   return \%hIO;
}

=head2 getNonInputOutputAttribute()

Returns: reference to a hash
         The hash contains all attributes except Input/Output related 
         attributes.
See 'getInputOutputAttribute' method above for definition of Input/Output
attributes.

=cut

sub getNonInputOutputAttributes {
   my $self = shift;

   my $rhInputOutputAttributes = $self->getInputOutputAttributeName();

   my $rhAllAttributes = $self->getAttributes();
   my %hNonIO = %$rhAllAttributes;

   if ( defined $rhInputOutputAttributes ) {
      foreach my $key ( keys %$rhInputOutputAttributes ) {
         delete $hNonIO{$key};	      
      }
   }
   return \%hNonIO
}


sub _setIsInputArgument {
   my $self = shift;
   $self->{'isInputArgument'} = shift;
}

sub isInputArgument {
   my $self = shift;
   return $self->{'isInputArgument'};
}

sub _setIsOutputProperty {
   my $self = shift;
   $self->{'isOutputProperty'} = shift;
}
sub isOutputProperty {
   my $self = shift;
   return $self->{'isOutputProperty'};
}


1;
