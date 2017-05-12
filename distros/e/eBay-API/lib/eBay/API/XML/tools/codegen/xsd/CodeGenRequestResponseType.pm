################################################################################
# Location: ............. <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. CodeGenEnumDataType.pm
# Original Author: ...... Milenko Milanovic
#
################################################################################

=pod

=head1 CodeGenRequestResponseType

Generate code for the call response types.

=cut

package # remove from indexing
    CodeGenRequestResponseType;

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

  #print Dumper($rh);

     # 3. superclass name and properties

  my $raProperties = [];

  my $rhComplexContent = $rh->{'xs:complexContent'};
  if ( defined $rhComplexContent ) {

     my $rhExtension = $rhComplexContent->{'xs:extension'};

     if ( defined $rhExtension ) {

	    # 3.1 superclass name
         $self->setSuperclassName( $rhExtension->{'base'});

	    # 3.1  properties
         my $rhSequence = $rhExtension->{'xs:sequence'}; 
         if ( defined $rhSequence ) {

            my $raElements = $rhSequence->{'xs:element'};	      

	    my @arr = ();
	    foreach my $rhElem (@$raElements) {

	       my $pElement = Element->new( $rhElem );
	       push @arr, $pElement;
	    }

	    $self->setElements (\@arr );
         }
     }
  }
}

#
# auxilary methods
#

sub getReType  {

   my $self = shift;
   my $name = $self->getName();

   my $sReType = $name;
   if ( $sReType =~ m/RequestType$/ ) {
      $sReType = 'request';
   } else {
      $sReType = 'response';
   }

   return $sReType; 
}

sub getCallName {

   my $self = shift;
   my $name = $self->getName();

   my $callName = getCallNameStatic ($name);
}

sub getCallNameStatic {

    my $sRequestResponseName = shift;
    my $sTmpName = $sRequestResponseName;

    if ( $sTmpName =~ m/RequestType$/ ) {
      $sTmpName =~ s/RequestType$//; 
    } elsif ( $sTmpName =~ m/ResponseType$/ ) {
      $sTmpName =~ s/ResponseType$//; 
    }

    my $sName = '';
    if ( $sRequestResponseName ne $sTmpName) {
        $sName = $sTmpName;
    }
    return $sName;
}

sub _determineFullPackageName {
   
   my $self = shift;	
   
   my $str = $self->getRootPackageName()
                 . '::' . 'Call' 
                 . '::' . $self->getCallName()
                 . '::' . $self->getName();
    
   return $str;
}

sub _getSuperClassFullPackageName {
	
   my $self = shift;

   my $superClass;

   my $sReType = $self->getReType();
   if ( $sReType eq 'request' ) {

      $superClass = 'RequestDataType';
   } else {
      $superClass = 'ResponseDataType';
   }

   my $str = $self->getRootPackageName()
                    . '::' . $superClass;
   return $str;
}

=head2  getPropertyToCallInfo()

CallInfo is a package defined in Annotation.pm file.
The packageName is: Annotation::CallInfo

NOTE: This method overrides the same method in BaseCodeGenDataType.pm.
It overrides it because for Api calls we do not display 
name of calls for which the property is used (since THIS generates
a property for currently generated API call 

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
