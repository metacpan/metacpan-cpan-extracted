################################################################################
#
# Module: ............... <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. BaseCodeGenDataType.pm
# Original Author: ...... Milenko Milanovic
#
################################################################################

package # put package name on different line to skip pause indexing
    BaseCodeGenDataType;

=pod

=head1 BaseCodeGenDataType

Base class for generating the data type classes.

=cut


use strict;
use warnings;

use Exporter;

use IO::File;
use File::Spec;
use File::Path 'mkpath';

use Time::localtime;

use Data::Dumper;
use Scalar::Util 'blessed';

use Annotation;

my $gsRootPackageName = undef;

## hash that provides typeNS to DataType class mapping
my %ghDataTypeClasses = ();   # # key = typeNS, value = class instance

my $gsReleaseNumber;
my $gsReleaseType = '';

#
#  this class should extend: CodeGenRequestResponseType.pm
#
sub new {

  my $classname = shift;
  my $rhXmlSimple = shift;

  my $self = {};
  bless($self, $classname);

  $self->{'name'} = undef;
  $self->{'rhAnnotation'} = undef;
  $self->{'raElements'}   = [];
  $self->{'raAttributes'} = [];
  $self->{'raEnums'}      = [];
  $self->{'fullPackageName'} = '';

      # 'typeNS' is a key to find a property's full package name
  $self->{'typeNS'}    = undef;

       # All Core DataTypes have 'hasIsScalarMethod'
       #     Request and Response Data Types do not have 'hasIsScalarMethod'
  $self->{'hasIsScalarMethod'} = 1;
       # Only Enum DataTypes are considered to be scalars
       #    All other types have to be instantiated
  $self->{'isScalar'}          = 0;

  $self->_init( $rhXmlSimple );


  return $self;  
}

sub setReleaseNumber {
   $gsReleaseNumber = shift;	
}
sub setReleaseType {
   $gsReleaseType = shift;	
}

sub setTypeNSToGenDataTypeMapping {

   my $rhTypeNStoClasses = shift;	

   %ghDataTypeClasses = %$rhTypeNStoClasses;
}

sub getDataTypeByDataTypeWithNS {

   my $self = shift;	
   	
   my $typeNS = shift;	
   my $pGenClassInstance = $ghDataTypeClasses{ $typeNS }; 

   #print "typeNS=|$typeNS|, pGenClassInstance=|$pGenClassInstance|\n";
   return $pGenClassInstance;
}

sub getRootPackageName {

   my $self = shift;
   if ( ! defined $gsRootPackageName ) {
      print "BaseCodeGenDataType::getRootPackageName failed:\n"
              . " $gsRootPackageName must be set!\n";
      exit;
   }
   
   return $gsRootPackageName;
}

sub setRootPackageName {
   $gsRootPackageName = shift;
}

sub _init {

  my $self = shift;	
  my $rh= shift;

     # 1. name
  my $name = $rh->{'name'};
  $self->setName($name);

  my $fullPackageName = $self->_determineFullPackageName();
  $self->setFullPackageName ( $fullPackageName );
  
  $self->setTypeNS ( 'ns:' . $name );

     # 2. Annotations

  my $rhAnnotation = $rh->{'xs:annotation'};
  my $pAnnotation;
  if ( defined $rhAnnotation ) {     
     $pAnnotation = Annotation->new ( $rhAnnotation );
  }

  $self->setAnnotation( $pAnnotation );

     # 3. superclass name and properties

  $self->_initElementsAndAttributes( $rh );
}

sub getName {
  my $self = shift;
  return $self->{'name'};
}
sub setName {
  my $self = shift;
  $self->{'name'} = shift;  
}

sub getAnnotation {
  my $self = shift;
  return $self->{'pAnnotation'};
}
sub setAnnotation {
  my $self = shift;
  $self->{'pAnnotation'} = shift;  
}

sub getSuperclassName {
  my $self = shift;
  return $self->{'superclassName'};
}
sub setSuperclassName {
  my $self = shift;
  $self->{'superclassName'} = shift;  
}

sub getElements {
  my $self = shift;
  return $self->{'raElements'};
}
sub setElements {
  my $self = shift;
  my $ra   = shift;
  $self->{'raElements'} = _sortElementArray ($ra);  
}

sub getAttributes {
  my $self = shift;
  return $self->{'raAttributes'};
}
sub setAttributes {
  my $self = shift;
  my $ra   = shift;
  $self->{'raAttributes'} = _sortElementArray ($ra);  
}

sub getEnums {
  my $self = shift;
  return $self->{'raEnums'};
}
sub setEnums {
  my $self = shift;
  $self->{'raEnums'} = shift;
}

#
# derived properties
# 
sub getDocumentation {	
  my $self = shift;

  my $rhAnnotation = $self->getAnnotation();

  my $documenation = '';
  if ( defined $rhAnnotation ) {
     $documenation = $rhAnnotation->{'xs:documentation'};
  }
}

sub setFullPackageName {
  my $self = shift;
  $self->{'fullPackageName'} = shift;  
}
sub getFullPackageName {
  my $self = shift;
  return $self->{'fullPackageName'};  
}

sub getTypeNS {
  my $self = shift;
  return $self->{'typeNS'};
}
sub setTypeNS {
  my $self = shift;
  $self->{'typeNS'} = shift;  
}

sub hasIsScalarMethod {
  my $self = shift;
  return $self->{'hasIsScalarMethod'};
}
sub setHasIsScalarMethod {
  my $self = shift;
  $self->{'hasIsScalarMethod'} = shift;  
}

sub isScalar {
  my $self = shift;
  return $self->{'isScalar'};
}
sub setScalar {
  my $self = shift;
  $self->{'isScalar'} = shift;  
}

#
# auxilary methods
#

sub _sortElementArray {
  
   my $ra = shift;	
   if ( ! defined $ra ) {
     return $ra;	   
   }
   
   my @arr = sort { $a->getName() cmp $b->getName() } @$ra;	
   return \@arr;
}

=head2 getGetterName()

=cut

sub getGetterName {

  my $self = shift;	
  my $propName = shift;
  my $typeNS = shift;
  
  if ( ! defined $typeNS ) {
      print "propName=|" . $propName . ", typeNS not defined, aborting..\n";
      exit;
  }

  my $sGetterName = "\u$propName";
  if ($typeNS eq 'xs:boolean') {
      $sGetterName = "is$sGetterName";
  } else {
      $sGetterName = "get$sGetterName";
  }
  return $sGetterName;
}

=head2 getSetterName()

=cut

sub getSetterName {

  my $self = shift;	
  my $propName = shift;

  my $name = "set\u$propName";
  return $name;
}

=head2 _getSetterComment()

This method is used from within 'getSetterGetterComment' method

=cut

sub _getSetterComment {
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
  my $strCallInfoInputArgs   = $self->_getSetterCallsInfo( $pAnnotation );

     # 3. type description
     #
  my $typeComment = $self->_getTypeComment(
                               'isArray' => $isArray
                              ,'propertyType'  => $propertyType
                              ,'sDescriptionKey' => 'Argument'
	                                  );
					  
     # 4. additional app info in annotations
     #     very rarely used
     #
  my $sAdditionalAppInfo = $self->_getAdditionalAppInfo( $pAnnotation );
  
  my $strComment = $annDoc;	  

  $strComment .= $sAdditionalAppInfo;

  $strComment .= $strCallInfoInputArgs;	  

  $strComment .= $typeComment;


  return $strComment;
}

sub _getAdditionalAppInfo {
   my $self = shift;
   my $pAnnotation = shift;  
   
   my $str = '';
   if ( defined $pAnnotation ) {
      $str = $pAnnotation->getAdditionalAppInfo();
      if ( length($str) > 0 ) {
         $str = "$str\n";
      }
   }
   return $str;
}

sub _getSetterCallsInfo {
  my $self = shift;
  my $pAnnotation = shift;  

  my $strCallInfoInputArgs = '';
  if ( defined $pAnnotation ) {

     my $raCallInfoInput = $pAnnotation->getCallsInfoInput();
     $strCallInfoInputArgs = $self->getPropertyToCallInfo( $raCallInfoInput );
  }
  return $strCallInfoInputArgs;
}

=head2 _getGetterComment()

This method is used from within 'getSetterGetterComment' method

=cut

sub _getGetterComment {
  my $self = shift;
  my %args = @_;

  my $propertyType   = $args{'propertyType'};
  my $isArray        = $args{'isArray'};
  my $pAnnotation    = $args{'pAnnotation'};

     # 1.  annotation callInfo documentation (input arguments)
     #
  my $strCallInfoOutputProps   = $self->_getGetterCallsInfo( $pAnnotation );

     # 2. type description
     #
  my $typeComment = $self->_getTypeComment(
                               'isArray' => $isArray
                              ,'propertyType'  => $propertyType
                              ,'sDescriptionKey' => 'Returns'
	                                  );
  my $strComment = '';
  
  $strComment .= $strCallInfoOutputProps;	  
  $strComment .= $typeComment;

  return $strComment;
}

sub _getGetterCallsInfo {
  my $self = shift;	
  my $pAnnotation = shift;  

  my $strCallInfoOutputProps = '';
  if ( defined $pAnnotation ) {

     my $raCallInfoInput = $pAnnotation->getCallsInfoOutput();
     $strCallInfoOutputProps = $self->getPropertyToCallInfo( $raCallInfoInput );
  }
  return $strCallInfoOutputProps;
}

=head2 getTypeComment()

Used in _getGetterComment and in _getSetterComment methods

=cut

sub _getTypeComment {
  my $self = shift;	
  my %args = @_;

  my $isArray = $args{'isArray'};
  my $typeNS  = $args{'propertyType'};
  my $sDescKey = $args{'sDescriptionKey'};
  
  my $typeComment = '';
  if ( $isArray ) {  # array property

     $typeComment =<<"ARR_COMMENTS_GETTER_x";
#    $sDescKey: reference to an array  
                      of '$typeNS'
ARR_COMMENTS_GETTER_x
  } else {      # scalar property 

     $typeComment =<<"SCALAR_COMMENTS_GETTER_x";
#    $sDescKey: '$typeNS'
SCALAR_COMMENTS_GETTER_x
  }
  return $typeComment;
}


=head2 getSetterGetterComment()

=cut

sub getSetterGetterComment() {
  my $self = shift;
  my %args = @_;

  my $propertyType   = $args{'propertyType'};
  my $isArray        = $args{'isArray'};
  my $pAnnotation    = $args{'pAnnotation'};
  my $methodName     = $args{'methodName'};
  my $setterOrGetter = $args{'setterOrGetter'};

  my $strComment = '';
  if ( $setterOrGetter eq 'getter' ) {

     $strComment = $self->_getGetterComment(
	                            'propertyType'   => $propertyType
	                           ,'isArray'        => $isArray
		                   ,'pAnnotation'    => $pAnnotation
	                                   );
  } else {
	  
     $strComment = $self->_getSetterComment(
	                            'propertyType'   => $propertyType
	                           ,'isArray'        => $isArray
		                   ,'pAnnotation'    => $pAnnotation
	                                   );
  }

  my $str = <<"SET_COMMENTS";
=head2 $methodName()

$strComment
=cut
SET_COMMENTS

  return $str;
}

=head2  getPropertyToCallInfo()

CallInfo is a package defined in Annotation.pm file.
The packageName is: Annotation::CallInfo

=cut

sub getPropertyToCallInfo {

   my $self = shift;
   my $raCallInfo = shift;

   my $str = '';
   if ( defined $raCallInfo ) {
	   
      foreach my $pCallInfo (@$raCallInfo ) {	   

         $str .= $self->getPropertyToCallInfo_Calls( $pCallInfo );

	 $str .= $self->getPropertyToCallInfo_Attributes( $pCallInfo );

	 $str .= $self->getPropertyToCallInfo_Context( $pCallInfo );

         $str .= "\n";
      }
   }

   return $str;
}

sub getPropertyToCallInfo_Calls {
   my $self = shift;
   my $pCallInfo = shift;   

   my $str = "  Calls: ";
   my $raCallNames  = $pCallInfo->getCallNames();
   my $cnt = 0;
   foreach my $callName (@$raCallNames) {

      if ( $cnt != 0 ) {		 
        $str .= "         ";
      }
      $str .= "$callName\n";
      $cnt++;
   }

   return $str;	 
}

sub getPropertyToCallInfo_Attributes {
   my $self = shift;
   my $pCallInfo = shift;   

   my $str = '';
   my @arr = (
	  $pCallInfo->getInputOutputAttributeName()
	 ,$pCallInfo->getNonInputOutputAttributes()
             );

   foreach my $rhAttrs ( @arr ) {		   

      foreach my $key ( sort keys %$rhAttrs) {
         my $value = $rhAttrs->{$key};	 
         if ( defined $value ) {

            my $strKey = "  $key: ";
            my $sValue = '';
                # in some cases - value is a hash reference
                #   so print whatever is in that hash. Usually it is an empty hash
            if ( ref($value) eq 'HASH' ) {

                my ($sLev2Key, $sLev2Val);
                while (($sLev2Key, $sLev2Val) = ( each %$value )) {
                    if ($sValue ne '') {
                        $sValue .= ', ';
                    }
                    $sValue .= "$sLev2Key: $sLev2Val"; 
                }
            } elsif ( ref($value) eq 'ARRAY' ) {

                my $sCntTmp = 0;
                my $sTmpLen = length($strKey);
                my $template = "A$sTmpLen";
                my $ident = pack($template,'');

                foreach my $sTmp ( @$value) {
                    if ( $sCntTmp > 0 ) {
                        $sValue .= $ident;
                    }
                    $sValue .= "$sTmp\n"; 
                    $sCntTmp++;
                }
            } else {
                $sValue = $value;
            }
	        $str .= "$strKey$sValue\n";
         }
      }
   }
   return $str; 
}

sub getPropertyToCallInfo_Context {
   my $self = shift;
   my $pCallInfo = shift;   

   my $raContext = $pCallInfo->getContext();
   my $str = "";
   if ( defined $raContext ) {

      my $cnt = 0;
      $str .= "  Context: ";
      foreach my $sContext ( @$raContext ) {
         if ( $cnt != 0 ) {		 
	    $str .= "           ";
	 }
	 $str .= "$sContext\n";
	 $cnt++;
      }		    
   }

   return $str;
}

sub trim {
  my $str = shift;
  $str =~ s/^\s+//g;
  $str =~ s/\s+$//g;
  return $str;
}

sub _formatDocumentation {
  my $self = shift;	
  my $pAnnotation = shift;

  my $annDoc  = '';
  if ( defined $pAnnotation ) {
	  
     $annDoc = $pAnnotation->getDocumentation();

     if ( ! defined $annDoc ) {
       $annDoc = '';	  
     } else {
   
       if ( ref($annDoc) eq 'HASH' ) {
	   $annDoc = Dumper( $annDoc );
	   #return $annDoc;
       }	    
     }


     $annDoc = trim ($annDoc);
     $annDoc =~ s/^\s+//gms;
     
        ## keep this if we decide to wrap paragraphs
     #$Text::Wrap::columns = 80;
     #my @text = split(/\n/, $str);
     #$str = wrap('', '', @text);

     if ( length($annDoc) > 0 ) {
	       $annDoc .= "\n\n";
     }
  }	

  return $annDoc;
}
sub validateType  {
  my $self = shift;	
  my $type = shift;

  # exceptions
  #  some types in properties do not start with "ns:"
  #   so I am fixing that here
  if ( ($type =~ m/Type$/) && ! ($type =~ m/^ns:/) ) {

    $type = "ns:$type";
  }
  return $type;
}

sub _initElementsAndAttributes {
 	
   my $self = shift;	
   my $packageName = blessed $self;
   print "_initElementsAndAttributes must be implemented in package" .
      " $packageName\n";

   exit;
}

sub _determineFullPackageName {
   
   my $self = shift;	
   my $packageName = blessed $self;
   print "_determineFullPackageName must be implemented in package" .
      " $packageName\n";

   exit;
}

=head2 _getClassBody()

Must be implemented in each class that extends this class

=cut

sub _getClassBody {

   my $self = shift;

   my $packageName = blessed $self;
   print "_getClassBody must be implemented in package" .
      " $packageName\n";

   exit;
}

sub _getRelativeOutputDir {
   my $self = shift;
   my $fullPackageName = shift;

   my @dirs = split(/::/, $fullPackageName );
     # remove class name from the path.   
   my $latsNdx = $#dirs;
   $#dirs = $latsNdx - 1;
   
   my $path = File::Spec->catdir(@dirs);
   return $path;
}

sub genCode {
	
  my $self = shift;	
  my %args = @_;

  my $rootOutputDir   = $args{'rootOutputDir'};

  my $fullPackageName = $self->getFullPackageName();
  my $relOutputDir = $self->_getRelativeOutputDir( $fullPackageName );
  my $outputDir = File::Spec->catdir( $rootOutputDir, $relOutputDir);


  my $classHeader = $self->_genClassHeader();
  my $classBody   = $self->_getClassBody();
  my $classFooter = $self->_genClassFooter();
  $classBody = $classHeader . "\n" . $classBody . "\n" . $classFooter;


  my $sClassFileName   = $self->_getFileName();
  $self->createDirIfNotExists( $outputDir );
  $self->writeFile ( 'outputDir'     => $outputDir
                    ,'outputFileName'=> $sClassFileName
                    ,'sContent'      => $classBody );  
}

sub _getFileName {
	
  my $self = shift;	
  my $sClassFileName   = $self->getName() . '.pm';
  return $sClassFileName;
}

sub _genClassFooter {
   return <<"FOOTER";

1;   
FOOTER
}
sub _genClassHeader {

  my $self = shift;	

  my $rootPackage = $self->getRootPackageName();
  my @arr = split(/::/, $rootPackage);
  my $packagePath = File::Spec->catdir (@arr);
  
  my $fileName    = $self->_getFileName();
  my $fullPackageName = $self->getFullPackageName();

  my $tm = localtime;
  my $timeStamp   = sprintf("%02d/%02d/%04d %02d:%02d"
	                       ,$tm->mon+1
			       ,$tm->mday
			       ,$tm->year+1900
			       ,$tm->hour
			       ,$tm->min
		       );
			       
  my $pAnnotation  = $self->getAnnotation();
  my $sDescription = '';
  if ( defined $pAnnotation ) {
     $sDescription = $self->_formatDocumentation( $pAnnotation );
  }

  my $str = <<"HEADER";
#!/usr/bin/perl

package $fullPackageName;

use strict;
use warnings;  

##########################################################################
#
# Module: ............... <user defined location>$packagePath
# File: ................. $fileName
# Generated by: ......... genEBayApiDataTypes.pl
# Last Generated: ....... $timeStamp
# API Release Number: ... $gsReleaseNumber
#
##########################################################################  

=head1 NAME

$fullPackageName

=head1 DESCRIPTION

$sDescription

=head1 SYNOPSIS

=cut

HEADER

  return $str;
}

sub writeFile {
  my $self = shift;
  my %args = @_;

  my $outputDir      = $args{'outputDir'};
  my $outputFileName = $args{'outputFileName'};
  my $sContent       = $args{'sContent'};

  my $out_filename = File::Spec->catfile($outputDir, $outputFileName);

  if ( -e $out_filename ) {  # check out if the file exists
     if ( ! (-W $out_filename) ) {

       print "File $out_filename is not writtable\n";	   
       print "Please verify that the file is checked out from SCM!\n";	   
       print "Aborting script execution!\n";
       exit;
     }
  }

  my $out_fh = IO::File->new( "> $out_filename");
  if ( ! defined $out_fh ) {
    my $error = $!;
    print "Could not create file '$out_filename', error=|$error|\n";
    print "Aborting script execution!\n";
    exit 1;
  }

  print $out_fh $sContent;
  $out_fh->close();  
}

sub createDirIfNotExists {

   my $self = shift;
   my $outputDir = shift;

       # create output directory if it does not exist!
   my $isOutputDirExist = (-e $outputDir);
   if ( ! defined $isOutputDirExist ) { 
				# if the output directory does not exist
	                        #  create it.
      #print "outputDir =|$outputDir| does not exist\n";
      mkpath($outputDir);
      my $error = $!;
         # For some reason, even though the directory is being created
	 #   I get 'failed to create directory ... No such file or directory'
	 #     error.
     #   see:  http://perldoc.perl.org/File/Path.html
     # "On Windows, if mkpath  gives you the warning: 
     #   No such file or directory, this may mean that you've exceeded 
     #   your filesystem's maximum path length."
     #  So if we get this error, we will just ignore it
      if ( $error && $error ne 'No such file or directory') {
      	print "failed to create directory |$outputDir|, error=|$error|\n";
      	exit 1;
      }
   }
}

1;
