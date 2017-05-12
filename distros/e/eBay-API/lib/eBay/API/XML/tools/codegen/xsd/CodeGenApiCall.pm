################################################################################
# Location: ............. <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. CodeGenApiCall.pm
# Original Author: ...... Milenko Milanovic
#
################################################################################

package # put package name on different line to skip pause indexing
    CodeGenApiCall;

use strict;
use warnings;

use Exporter;
use BaseCodeGenDataType;
our @ISA = ('Exporter'
	    ,'BaseCodeGenDataType'
	   );

use Data::Dumper;

sub new {
	
   my $classname = shift;	
   my %args = @_;

   my $self = {};
   bless($self, $classname);

      # 
      #  initialize properties
      # 

     # 1. 
   $self->{'requestCodeGen'}  = $args{'requestCodeGen'};
   $self->{'responseCodeGen'} = $args{'responseCodeGen'};

     # 2. name
   my $name = $args{'callName'};
   $self->setName($name);
   
     # 3. fullPackageName
   my $fullPackageName = $self->_determineFullPackageName();
   $self->setFullPackageName ( $fullPackageName );   

   return $self;
}

sub _determineFullPackageName {

   my $self = shift;

   my $str = $self->getRootPackageName()
                     . '::' . 'Call'
                     . '::' . $self->getName();
   return $str;
}

sub _getSuperClassFullPackageName {
   my $self = shift;

   my $str = $self->getRootPackageName()
                     . '::' . 'BaseCall';
   return $str;
}
		  
sub _getClassBody {
	
  my $self = shift;
  my %args = @_;

  my $sCallName    = $self->getName();
  my $pRequestGen  = $self->{'requestCodeGen'};
  my $pResponseGen = $self->{'responseCodeGen'};

  my $sClassPackage = $self->_determineFullPackageName();
  
  my $sSuperClassPackage  = $self->_getSuperClassFullPackageName();
  
  my $sRequestFullPackageName = $pRequestGen->getFullPackageName();
  my $sResponseFullPackageName = $pResponseGen->getFullPackageName();
				   
  my $imports = "use $sRequestFullPackageName;\n";
  $imports   .= "use $sResponseFullPackageName;\n";

    # Find element names that exists both for Request and Response
    # In case we have an element that exists for both Request and Response
    #   we will add a 'Request' and 'Response' prefix respectivly to that name
    #    (in order to avoid conflict in those names)
  my %hSameNames = ();  # for Api Calls we generate only setters for Request
                        #  and getters for Response, so we do not need to add prefix

     ## create input/output properties
  my $inputProperties = $self->getApiGettersSetters (
	                            'pCodeGenClass' => $pRequestGen
                               ,'sRequestOrResponse'=> 'Request'
                               ,'rhSameNames' => \%hSameNames
                               ,'createSetters'=> 1
                               ,'createGetters'=> 0
	                                     );
  my $outputProperties = $self->getApiGettersSetters (
	                            'pCodeGenClass' => $pResponseGen
                               ,'sRequestOrResponse'=> 'Response'
                               ,'rhSameNames' => \%hSameNames
                               ,'createSetters'=> 0
                               ,'createGetters'=> 1
	                                     );

  my $packageBody = <<"PACKAGE_BODY";
=head1 INHERITANCE

$sClassPackage inherits from the L<$sSuperClassPackage> class

=cut

use $sSuperClassPackage;
our \@ISA = ("$sSuperClassPackage");

$imports

=head1 Subroutines:

=cut

sub getApiCallName {
   return '$sCallName';
}
sub getRequestDataTypeFullPackage {
   return '$sRequestFullPackageName';
}
sub getResponseDataTypeFullPackage {
   return '$sResponseFullPackageName';
}

#
# input properties
#

$inputProperties

#
# output properties
#

$outputProperties

PACKAGE_BODY

  return $packageBody;

}

sub getApiGettersSetters {
  my $self = shift;
  my %args = @_;

  my $pCodeGenClass = $args{'pCodeGenClass'};
        # properties that exist for both Request and Response
  my $rhSameNames   = $args{'rhSameNames'} || {};  
  my $sRequestOrResponse = $args{'sRequestOrResponse'};
  my $createSetters = $args{'createSetters'};
  my $createGetters = $args{'createGetters'};

  #print "createGetters=|$createGetters|, createSetters=|$createSetters|\n";

  my $raElements   = $pCodeGenClass->getElements();
  my $raAttributes = $pCodeGenClass->getAttributes();

  my $str = '';
  my $sReGetterName = 'get' . $sRequestOrResponse . 'DataType';
  my $sReSetterName = 'set' . $sRequestOrResponse . 'DataType';
  foreach my $pElem ( @$raElements ) {

    my $name    = $pElem->getName();
    my $typeNS  = $pElem->getTypeNS();
    my $isArray = $pElem->isArray();
    my $pAnnotation = $pElem->getAnnotation();

    my $pElemGenClass = $self->getDataTypeByDataTypeWithNS($typeNS);

    my $setterVarName = "s$name";
    if ( defined $pElemGenClass ) {

       if ( ! $pElemGenClass->isScalar() ) {	    
            $setterVarName = "p$name";
       }
    }

    my $sWrapperPropertyName = $name;
    if ( exists $rhSameNames->{$name}) {
        $sWrapperPropertyName = "$sRequestOrResponse$name";
    }
    my $sGetterName = $self->getGetterName( $sWrapperPropertyName, $typeNS );
    my $sSetterName = $self->getSetterName( $sWrapperPropertyName );

    my $sInnerGetterName = $self->getGetterName( $name, $typeNS );
    my $sInnerSetterName = $self->getSetterName( $name );

    if ( $createGetters == 1)  {

       my $strComment = $self->getSetterGetterComment(
                                    'propertyType'   => $typeNS
                                   ,'isArray'        => $isArray
				                   ,'pAnnotation'    => $pAnnotation
                                   ,'methodName'     => $sGetterName
                                   ,'setterOrGetter' => 'getter'
                                                   );	  
       $str .=<<"GETTERS";
$strComment       
sub $sGetterName {
   my \$self = shift;
   return \$self->$sReGetterName()->$sInnerGetterName();
}
GETTERS
    }

    if ( $createSetters == 1)  {
	   
           # Do not generate annotation comments for a setter
           # if you have already generated them for a getter
       my $pSetterAnnotation = $pAnnotation;
       if ($createGetters == 1) {
            $pSetterAnnotation = undef;
       }
       my $strComment = $self->getSetterGetterComment(
                                    'propertyType'   => $typeNS
                                   ,'isArray'        => $isArray
				                   ,'pAnnotation'    => $pSetterAnnotation
                                   ,'methodName'     => $sSetterName
                                   ,'setterOrGetter' => 'setter'
                                                   );	  
       $str .=<<"SETTERS";
$strComment       
sub $sSetterName {
   my \$self   = shift;
   my \$$setterVarName = shift;
   \$self->$sReGetterName()->$sInnerSetterName(\$$setterVarName);
}
SETTERS
    }
    $str .= "\n";
  }

  return $str;
}

=head2 _getGetterComment()

This method is used from within 'getSetterGetterComment' method

NOTE: This method overrides the same method in BaseCodeGenDataType.pm
Why? The super method does not display annotation documentation for
getters. For API call properties we display annotation documentation 
even for getters.

=cut

sub _getGetterComment {
  my $self = shift;
  my %args = @_;

  my $propertyType   = $args{'propertyType'};
  my $isArray        = $args{'isArray'};
  my $pAnnotation    = $args{'pAnnotation'};

     # 1. annotation documentation
     #
  my $annDoc = $self->_formatDocumentation( $pAnnotation );
    
     # 2.  annotation callInfo documentation (input arguments)
     #
  my $strCallInfoOutputProps   = $self->_getGetterCallsInfo( $pAnnotation );

     # 3. type description
     #
  my $typeComment = $self->_getTypeComment(
                               'isArray' => $isArray
                              ,'propertyType'  => $propertyType
                              ,'sDescriptionKey' => 'Returns'
	                                  );

  my $strComment = $annDoc;
  
  $strComment .= $strCallInfoOutputProps;	  
  $strComment .= $typeComment;

  return $strComment;
}

=head2  getPropertyToCallInfo()

CallInfo is a package defined in Annotation.pm file.
The packageName is: Annotation::CallInfo

NOTE: This method overrides the same method in BaseCodeGenDataType.pm
It overrides it because for Api calls we do not display 
name of calls for which the property is used (since THIS generates
a property for currently generated API call. 

=cut

sub getPropertyToCallInfo {

   my $self = shift;
   my $raCallInfo = shift;

   my $str = '';
   if ( defined $raCallInfo ) {
	   
      foreach my $pCallInfo (@$raCallInfo ) {	   

        $str .= $self->getPropertyToCallInfo_Attributes( $pCallInfo );
        $str .= $self->getPropertyToCallInfo_Context( $pCallInfo );
      }
   }

   return $str;
}

1;
