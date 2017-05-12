#!/usr/bin/perl -w


################################################################################
# Location: ......................... 
# File: ....................... genEBayApiData.pl
# Original Author: ............ Milenko Milanovic
# Last Modified By: ........... Jeff Nokes
# Last Modified: .............. 03/06/2007 @ 17:11
#
# Description:
# This is a script used to auto-generate the call and datatype classes for
# the eBay Perl SDK.  It is user interactive; to see usage, just execute the
# script with no arguments.  Also, referecne README for more information.
################################################################################


=pod

=head1 genEBayApiData.pl

This is a script used to auto-generate the call and datatype classes for
the eBay Perl SDK.  It is user interactive; to see usage, just execute the
script with no arguments.  Also, referecne README for more information.

=cut



# Required Includes
# ------------------------------------------------------------------------------
  use strict;
  use warnings;

  use Getopt::Long;
  use Cwd;
  use LWP::UserAgent;
  use XML::Simple ":strict";
  use IO::File;
  use File::Spec;
  use Data::Dumper;

  use BaseCodeGenDataType;
  use CodeGenReleaseClass;
  use CodeGenBaseCallGenClass;
  use CodeGenRequestResponseType;
  use CodeGenNonCallRequestResponseType; # example: NotificationMessageType
  use CodeGenComplexDataType;       # examples: ItemType
  use CodeGenComplexSimpleDataType; # examples: AmountType
  use CodeGenSimpleDataType;        # examples: ItemIDType, UserIdType
  use CodeGenEnumDataType;          # examples: AckDataType
  use CodeGenApiCall;





# Variable Declarations
# ------------------------------------------------------------------------------
# Constants
  # none

# Globals
  # none

# Script Lexicals
  my $gsRootPackageName = "eBay::API::XML";
  my $ghRootOutputDir = undef;
  my @gaClasses = ();          # element = class instance
  my %ghCallNames = ();        # key = 'api call name', value = undef
  my $gsStepNdx = 1;           # used for logStep;






# Main Script
# ------------------------------------------------------------------------------
  main();

=head2 usage()

=cut 

sub usage {

   my $filename = shift;
   my $url      = shift;

   if ( length($filename) == 0 
	   && length($url) == 0 ) {

     my $scriptName = $0;   # script name
        # $scriptName = "./genEBayApiDataTypes.pl"
	#     remove everything except the script name.
     if ( $scriptName =~ /\// ) {
        my @arr = split(/\//, $scriptName);
        $scriptName = $arr[-1];
     }
     my $msg = <<"USAGE";

usage:      
    $scriptName --file=s --url=s --outputDir=s

      arguments:
          file      - Read eBay API xsd schema from a specified path/file.
          url       - Read eBay API xsd schema from a specified URL.
                      The retrieved content is saved into a file into the
                      current directory. The file is named after the URL's
                      document name.
          outputDir - Root output directory for generated classes.
                      If 'outputDir' is not specified then this script
                      will look for the first existence of the path
                      'eBay/API/XML' up from the current directory.  If
                      there is more than one instance of 'eBay/API/XML'
                      found, then it will attempt to use the deepest one.
                      If 'eBay/API/XML' path DOES NOT exist, generated 
                      classes are stored in the current directory.  If
                      a path is specified and it does not currently
                      exist, it will be created for you.  If a path is
                      specified and it does exist, the auto-generated
                      code will be placed under that path.

      notes:
         * Either 'file' or 'url' argument must be set. 'file' option takes
           precedence over 'url' option.

USAGE
    print $msg;
    exit;
   }
}

=head2 main()

=cut 




# Subroutine Definitions
# ------------------------------------------------------------------------------

sub main {

   my $filename  = '';       #
   my $url       = '';       #
   my $outputDir = undef;      # default value, output to current working dir
   
   GetOptions (  'file=s' => \$filename
                ,'url=s' => \$url
                ,'outputDir=s' => \$outputDir );

   usage ( $filename, $url);	

   BaseCodeGenDataType::setRootPackageName( $gsRootPackageName );

   $ghRootOutputDir = determineOutputDir( $outputDir );


   logStep ("", 0);      # just add yet another empty row
   logStep ("S T A R T \n", 0);     
   my $rsXmlString;

   my $inputDocName = '';
   if ( defined $filename && length($filename) > 0 ) {

      $inputDocName = $filename;
      $rsXmlString  = readWsdlFromFile($filename);	   
      
   } else {
      logStep ("F E T C H I N G input document from\n\t$url");	   

      $inputDocName = $url;
      $rsXmlString  = readWsdlFromUrl($url);	   

      my @arr = split(/\//, $url);
      my $fileName = $arr[-1];
      writeStringToFile ( $fileName, $$rsXmlString);

      logStep ("F E T C H I N G   - DONE, DATA saved to $fileName!");
   }

   
   logStep ("P A R S I N G        input document");

   my $rhXmlSimple = getRhXmlSimple( $rsXmlString );	

   #print Dumper($rhXmlSimple);

   my $inputDocType = getInputDocumentType($inputDocName);
   my $rhTypes;
   my $sReleaseNumber = '';
   if ( $inputDocType eq 'wsdl' ) {

      ### /wsdl:definitions/wsdl:types/xs:schema
      $rhTypes = $rhXmlSimple->{'wsdl:types'}->{'xs:schema'};

      $sReleaseNumber = _getReleaseNumber( 'rhXmlSimple' => $rhXmlSimple );
   } else {

      ### /xs:schema/xs:complexType
      $rhTypes = $rhXmlSimple;
      
      $sReleaseNumber = _getReleaseNumber( 'rsXmlString' => $rsXmlString );
   }

   my $sReleaseType = _getReleaseType( $inputDocName );
   BaseCodeGenDataType::setReleaseNumber( $sReleaseNumber );
   BaseCodeGenDataType::setReleaseType( $sReleaseType );

   generateReleaseClass ( $sReleaseNumber, $sReleaseType);

   processTypes($rhTypes);	

   generateBaseCallGenClass ();
}

sub _getReleaseType {

   my $inputDocName = shift;
   my $sReleaseType;
   if ( $inputDocName =~ m/private/ ) {
      $sReleaseType = 'private';	      
   } else {
          $sReleaseType = 'public';	      
   }
   return $sReleaseType;  
}

sub _getReleaseNumber {

   my %args = @_;   

   my $rhXmlSimple = $args{'rhXmlSimple'};
   my $rsXmlString = $args{'rsXmlString'};

   my $sReleaseNumber = '';
   if ( defined $rhXmlSimple ) {    # WSDL based generation

      ### /wsdl:definitions/wsdl:service/wsdl:documentation

      $sReleaseNumber 
                 = $rhXmlSimple->{'wsdl:service'}->{'wsdl:documentation'};

   } elsif ( defined $rsXmlString ) {   # XSD based code generation
	   
         # In XSD file, version is kept in comments at the top of 
	 # the document:
	 # 
	 # <!-- Version 449 -->
	 # <!-- Copyright (c) 2003-2006 eBay Inc. All Rights Reserved. -->
	 #
	 # So take first 1000 chars (just play it safe) and
	 #   extract the version number.
	 
      my $str = $$rsXmlString;	 
      $sReleaseNumber = substr ( $str, 0, 200);
      $sReleaseNumber =~ s/^.*\<!--\s+(Version \d+)\s+--\>.*$/$1/gsm;
   } else {
       print "\nWARNING: Cannot determine release number\n\n";	   
   }
   
   $sReleaseNumber =~ s/[^0-9]//g;

   return $sReleaseNumber;
}

sub generateReleaseClass {
	
   my $sReleaseNumber = shift;
   my $sReleaseType   = shift;   

   my $CodeGenClass = CodeGenReleaseClass->new ( 
	                                      name => 'Release'
	                                     ,'number' => $sReleaseNumber
	                                     ,'type'   => $sReleaseType
	                                      );

   $CodeGenClass->genCode( 'rootOutputDir' => $ghRootOutputDir );
}

sub generateBaseCallGenClass {

    my $pRequestCodeGenClass;
    my $pResponseCodeGenClass;
    foreach my $pClass ( @gaClasses) {

        my $sClassFullPackage = $pClass->getFullPackageName();

        if ($sClassFullPackage eq 'eBay::API::XML::DataType::AbstractRequestType') {
            $pRequestCodeGenClass = $pClass;
        }
        if ($sClassFullPackage eq 'eBay::API::XML::DataType::AbstractResponseType') {
            $pResponseCodeGenClass = $pClass;
        }

        if ( $pRequestCodeGenClass && $pResponseCodeGenClass) {
            last;
        }
    }

    if  (!( $pRequestCodeGenClass && $pResponseCodeGenClass)) {
        print "Could not find AbstractResponseType and AbstractRequestType" 
                 . " needed for BaseCallGen class to be generated\n";
        print "Aborting code gen.\n";
        exit;
    }
    my $pCodeGenClass = CodeGenBaseCallGenClass->new( 
                    'callName'        => 'BaseCallGen'
			       ,'requestCodeGen'  => $pRequestCodeGenClass
			       ,'responseCodeGen' => $pResponseCodeGenClass
		                           );
    $pCodeGenClass->genCode( 'rootOutputDir' => $ghRootOutputDir );     
}

=head2 determineOutputDir()

Arguments: 01 [S] Scalar string representing the root output directory for
              generated code. If the argument value is not defined a
	      special logic is used to determine root output directory.

Returns: Scalar string representing the root output directory for 
         generated code.

Description:
          The following logic is used to determine root output directory:

	  1. If 'outputDir' argument is defined - use it.
	  2. If 'eBay/API/XML' path exists for current working directory
	     use parent directory of 'eBay' directory as root output directory
	     If there more than one 'eBay/API/XML' then use the deepest one
          3. Otherwise use the current directory as root output directory.	     
Notes:

=cut 

sub determineOutputDir {
   my $outputDir = shift;

   #
   # 1. If outputDir is defined, then use it.
   #
   if ( defined $outputDir ) {
      return $outputDir;	   
   }

   # 2. Check if there is "eBay\API\XML" in current path
   #    If "eBay\API\XML" exists use the parent of "eBay" directory 
   #     as $outputDir.
   #     If there are more than one "eBay\API\XML" in the path, use the 
   #     lowest one.
   #     

   my $pwd = getcwd;
   my $no_file = 1;
   my ($volume, $directories, $file) = File::Spec->splitpath( $pwd, $no_file );
   my @arr = File::Spec->splitdir ( $directories );

   my @matchPath = split(/::/, $gsRootPackageName);
   #my @matchPath = ( 'eBay', 'API', 'XML');
   
   my $matchNdx  = 0;
   my $raPossibleRootPaths = [];
   my @rootPath = ();

   foreach my $dir ( @arr ) {

      push @rootPath, $dir;
      if ( $dir eq $matchPath[ $matchNdx ] ) {
          $matchNdx++;	      
      }	else {
          $matchNdx = 0;	      
      }

      if ( $matchNdx == (scalar @matchPath) ) {
         my @newArr = @rootPath;	      
	   # Remove "eBay/API/XML" component, because we want "eBay" parent
	   #   directory to be the root output directory.
	 @newArr = @rootPath;
	 my $numToRemove = scalar @matchPath;  
	 for ( my $i=0; $i < $numToRemove; $i++) {
	    pop @newArr;
	 }
         push @$raPossibleRootPaths, \@newArr;
         @rootPath = ();	 
	 $matchNdx = 0;
      }
   }

   my $raRootPath = undef;
   if ( (scalar @$raPossibleRootPaths ) > 0 ) {

	   # If there is more than one (eBay/API/XML) sequence in the
	   # path, take the deepest one.
      $raRootPath = $raPossibleRootPaths->[-1]; 
   }
   if ( defined $raRootPath ) {
       my $dirPath = File::Spec->catdir( @$raRootPath);	   
       $outputDir = File::Spec->catpath($volume, $dirPath, $file);
   }

   #
   # 3. If you could not find "eBay/API/XML" in the current path
   #    then output generated files to the current directory.
   #

   if (  ! defined $outputDir ) {
      $outputDir = ".";
   }

   return $outputDir;
}

=head2 logStep()

=cut 

sub logStep {
   
   my $msg = shift;
   my $includeNumber = shift;

   if ( ! defined $includeNumber ) {
      $includeNumber = 1;
   }

   if ( $includeNumber ) {
      $msg = " $gsStepNdx. $msg\n";	   
      $gsStepNdx++;
   } else {
      $msg = "    $msg\n";	   
   }

   print $msg;
}

=head2 getInputDocumentType()

=cut 

sub getInputDocumentType {
   
   my $docName = shift;	

   my $docType;
   if ( $docName =~ m/wsdl$/i ) {
	   
	 $docType = 'wsdl';
   } elsif ( $docName =~ m/xsd$/i ) {

         $docType = 'xsd';	      
   } else {

         print "Unknown input document type.\n"
	      . "\tIt has to be either wsdl or xsd document!\n";
	 exit;
   }

   return $docType;      
}

=head2 processTypes()

=cut 

sub processTypes {
  
  my $rhWsdlTypes = shift;	

  #print Dumper($rhWsdlTypes);

  #foreach my $key ( keys %$rhWsdlTypes ) { print "key=|$key|\n"; }

     #
     #  1. Find metadata for following data types:
     #       Request/Response Types,  - VerifyAddItemRequest.xsd
     #       Complex DataTypes        - ItemType.xsd
     #       Complex Simple DataTypes - AmountType.xsd

  logStep("G A T H E R I N G    'xs:complexType' metadata");     

  my $raComplexTypes = $rhWsdlTypes->{'xs:complexType'};
  processComplexTypes($raComplexTypes);


     #
     #  2. Find metadata for following data types:
     #       Simple types  -  ItemIDType (only one property: 'value')
     #       Simple types  -  enums

  logStep("G A T H E R I N G    'xs:simpleType' metadata");     

  my $raSimpleTypes  = $rhWsdlTypes->{'xs:simpleType'};
  processSimpleTypes($raSimpleTypes);

     #
     #  3. 
     #
  my %hDataTypeClasses = ();     # key = typeNS, value = class instance
  foreach my $pClassCodeGen ( @gaClasses) {
     my $typeNS = $pClassCodeGen->getTypeNS();
     $hDataTypeClasses { $typeNS } = $pClassCodeGen;
  }
  BaseCodeGenDataType::setTypeNSToGenDataTypeMapping( \%hDataTypeClasses );

  
     #
     #  4. Generate Core DataTypes and Request/Response DataTypes
     #
  logStep("G E N E R A T I N G   Core, Request, and Response DataTypes"); 

  foreach my $pClassCodeGen ( @gaClasses ) {

     my $fullPackageName = $pClassCodeGen->getFullPackageName();
     #print "$fullPackageName\n";
     $pClassCodeGen->genCode( 'rootOutputDir' => $ghRootOutputDir );
  }

     #
     #  5. Generate API calls
     #
  logStep("G E N E R A T I N G   API calls");  
  
  my $numOfErrors = 0;
  foreach my $sCallName ( sort keys %ghCallNames ) {


     my $rhCallRe = $ghCallNames {$sCallName };
     my $pRequestCodeGenClass  = $rhCallRe->{'requestCodeGen'};
     my $pResponseCodeGenClass = $rhCallRe->{'responseCodeGen'};

     my $logMsg = "    $sCallName\n";

     my $ok = 1; 
     $logMsg .= "\t1. ";
     if ( !defined  $pRequestCodeGenClass ) {
        $logMsg .= "ERROR: Request code gen class does not exist.\n";
        $logMsg .= "\t\tMost likely it is not defined in the input document.\n";
    	$ok = 0;
     } else {
        $logMsg .= " " . $pRequestCodeGenClass->getName() . "\n";
     }

     $logMsg .= "\t2. ";
     if ( !defined  $pResponseCodeGenClass ) {
        $logMsg .= "ERROR: Response code gen class not defined\n";
        $logMsg .= "\t\tMost likely it is not defined in the input document.\n";
	    $ok = 0;
     } else {
        $logMsg .= " " . $pResponseCodeGenClass->getName() . "\n";
     }
     if ( ! $ok ) {
        print $logMsg;	     
    	$numOfErrors++;
        next;	     
     }
     my $pApiClassGen = CodeGenApiCall->new( 
	                        'callName'        => $sCallName
			       ,'requestCodeGen'  => $pRequestCodeGenClass
			       ,'responseCodeGen' => $pResponseCodeGenClass
		                           );
     $pApiClassGen->genCode( 'rootOutputDir' => $ghRootOutputDir );     
  }

  if ( $numOfErrors > 0 ) {

     my $errorsWord = 'error';
     if ( $numOfErrors > 1 ) {
        $errorsWord = 'errors';
     }
     
     logStep( "G E N E R A T I N G   API calls - DONE, "
	                       . "$numOfErrors $errorsWord encountered." , 0);  
  }


  logStep ("", 0);      # just add yet another empty row
  logStep("D O N E !", 0);

}

=head2 processComplexTypes()

=cut 

sub processComplexTypes {

	# the following complexType(s) exist

# xs:complexContent, name
# xs:complexContent, xs:annotation, name
# xs:sequence, name
# xs:sequence, name, xs:attribute
# xs:sequence, xs:annotation, name
# xs:sequence, xs:annotation, name, abstract
# xs:sequence, xs:annotation, name, xs:attribute
# xs:simpleContent, name
# xs:simpleContent, xs:annotation, name

#  which basicaly comes to the following list:
# xs:complexContent, name
# xs:sequence, name
# xs:simpleContent, name
#  	

   my $raComplexTypes = shift;

        # 1. instantiate classes that generate API Request/Response 
   my @aApiCalls = findApiCalls ( $raComplexTypes );
   my %hApiCalls = ();
   foreach my $sApiCallName ( @aApiCalls ) {
       $hApiCalls{$sApiCallName} = '';
   }
   foreach my $rhElem (@$raComplexTypes) {

      if ( exists ($rhElem->{'xs:complexContent'}) ) {

          my $sName = $rhElem->{'name'};
          $sName = CodeGenRequestResponseType::getCallNameStatic( $sName );
          if ( ! (exists $hApiCalls{$sName}) ) {
               next;
          }

          my $pClassCodeGen = instantiateRequestResponseClassGenerator ( $rhElem );
          push @gaClasses, $pClassCodeGen;
      }   
   }

        # 2. Instantiate classes that generate API DataTypes
            #    I had to separate steps 1 nad 2 because 
            #    NotificationMessageType extends AbstractRequestType but it is not
            #    Request part of any API call.

            # Do not swap order of 1. and 2. (Request/Response and DataTypes)
            #   because code that instantiate DataTypes depends on code that
            #   instantitate Request/Response classes.
   foreach my $rhElem (@$raComplexTypes) {

            # If this is a call's request/response skip it.
            # That will be generated with the call.
       my $sName = $rhElem->{'name'};
       $sName = CodeGenRequestResponseType::getCallNameStatic( $sName );
       if ( $ghCallNames{$sName} ) {
            next;
       }

      my $pClassCodeGen = instantiateComplexTypeClassGenerator($rhElem);
      push @gaClasses, $pClassCodeGen;
   }
}

=head2 findApiCalls()

=cut

#
# eBay API wsdl file has explicit information about API calls
#  while in case of eBay API xsd file there is only an implicit information about API calls
# So since I want to be able to use both WSDL and XSD files to generate Perl SDK API 
#   I use the 'implicit' way to find list of eBay API calls.
#
sub findApiCalls {
   my $raComplexTypes = shift;

   my %hApiCalls = ();
   foreach my $rhElem (@$raComplexTypes) {

       if ( exists ($rhElem->{'xs:complexContent'}) ) {

           my $name = $rhElem->{'name'};

           my $callName = $name;
           $callName = CodeGenRequestResponseType::getCallNameStatic( $name );

           if ($callName) {
               $hApiCalls{$callName} = '';
           }
       }
   }

   my @aApiCalls = sort keys %hApiCalls;
   return @aApiCalls;
}

=head2 instantiateRequestResponseClassGenerator()

=cut 

sub instantiateRequestResponseClassGenerator {

    my $rhElem = shift;

    my $pClassCodeGen = CodeGenRequestResponseType->new( $rhElem );

       #
    #  1.1 Set values needed for call generation
    #
    my $callName = $pClassCodeGen->getCallName();

          # we have 2 classes per a call: Request and Response
      #    That is why I put call names into a hash
    my $rhCallRe = $ghCallNames {$callName };
    if ( ! defined $rhCallRe ) {
      $rhCallRe = { 
           'requestCodeGen' => undef
          ,'responseCodeGen' => undef
                };  
      $ghCallNames {$callName } = $rhCallRe;
    }

    my $sReType  = $pClassCodeGen->getReType();
    if ( $sReType eq 'request' ) {

       $rhCallRe->{'requestCodeGen'} = $pClassCodeGen;
    } elsif ( $sReType eq 'response' ) {
       
       $rhCallRe->{'responseCodeGen'} = $pClassCodeGen;
    } else {
       
       print "Generating API calls failed: "
               . $pClassCodeGen->getName() . "\n"
       . " returned invalid reType: "
       . "|$sReType|. Valid values are: 'request', 'response'\n";
       exit;		   
    }

    return $pClassCodeGen;
}

=head2 instantiateComplexTypeClassGenerator()

=cut 

sub instantiateComplexTypeClassGenerator {

   my $rhElem = shift;

   my $pClassCodeGen = undef;
   if ( exists ($rhElem->{'xs:complexContent'}) ) {

       $pClassCodeGen = CodeGenNonCallRequestResponseType->new( $rhElem ); 

   } elsif ( exists ($rhElem->{'xs:sequence'}) ) {

       $pClassCodeGen = CodeGenComplexDataType->new( $rhElem );

   } elsif ( exists ($rhElem->{'xs:simpleContent'}) ) {

       $pClassCodeGen = CodeGenComplexSimpleDataType->new( $rhElem );

   } else {
      print "Cannot find what code class to instantiate for \n"
            . Dumper($rhElem) . "\n"      
	    . "EXITING SCRIPT\n";
   }

   return $pClassCodeGen;
}

=head2 processSimpleTypes()

=cut 

sub processSimpleTypes {

   my $raComplexTypes = shift;

   foreach my $rhElem (@$raComplexTypes) {

      my $pClassCodeGen = instantiateSimpleTypeClassGenerator($rhElem);
      push @gaClasses, $pClassCodeGen;
   }
}

=head2 instantiateSimpleTypeClassGenerator()

=cut 

sub instantiateSimpleTypeClassGenerator {

   my $rhElem = shift;

   my @keys = keys %$rhElem;	   

   my $pClassCodeGen = undef;
   my $rhRestriction = $rhElem->{'xs:restriction'};
   
   if ( exists ($rhRestriction->{'xs:enumeration'}) ) {

       $pClassCodeGen = CodeGenEnumDataType->new( $rhElem );
   } else {  # simple type with some type restriction

       $pClassCodeGen = CodeGenSimpleDataType->new( $rhElem );
   }

   return $pClassCodeGen;
}

=head2 readWsdlFromFile()

=cut 

sub readWsdlFromFile {

   my $filename = shift;
   my $in_fh = IO::File->new( "< $filename ");
   if ( ! defined $in_fh ) {
      my $error = $!;
      print "Cannot open file $filename, error=|$error|\n";
      exit 1;
   }   

   my $keep = $/;
   $/ = undef;
   my $strXML =  <$in_fh>;
   $/ = $keep;

   return \$strXML;
}

=head2 readWsdlFromUrl()

=cut 

sub readWsdlFromUrl {

   my $url = shift;
   
   my $strXML = '';

   my $ua = LWP::UserAgent->new();
   my $response = $ua->get( $url );
 
   if ($response->is_success) {

      $strXML = $response->content();

   } else {
      print "Error fetching $url\n";	   
      print $response->status_line . "\n";
      exit;
   } 

   return \$strXML;   
}

=head2 writeStringToFile()

=cut 

sub writeStringToFile {

   my $fileName = shift;
   my $string   = shift;

   my $out_fh = IO::File->new( "> $fileName ");
   if ( ! defined $out_fh ) {
      print $! . "\n";
      print "Could not create output file $fileName \n";
      exit;      
   }   

   print $out_fh $string;
   $out_fh->close();
}

=head2 getRhXmlSimple()

=cut 

sub getRhXmlSimple {

	   ## $rsXmlString is a reference to a string
   my $rsXmlString = shift;

   my $rhXML;

   eval {
	$rhXML = parseXML ( $$rsXmlString );
   };
   return $rhXML;
}

=head2 parseXML()

=cut 

sub parseXML {

   my $rawXML = shift;
   my $rhXML = XMLin($rawXML 
	   		 # 1. forcearray - even if there is only one 
			 #   a) 'xs:element', an array containing elements 
			 #    will be created. 
			 #    Example: AccountEntriesType have just one 
			 #      'xs:element
			 #   b) 'xs:attribute', an array containing elements 
			 #    will be created. 
			 # 2. keyattr => [] - disable array folding
			 # see:
			 #  http://www.perlmonks.org/index.pl?node_id=218480
	              , forcearray => [  'xs:element'
		                        ,'xs:attribute' 
					#,'xs:complexType'
					#,'xs:simpleType'
				      ]
	              , keyattr => [] );
   return $rhXML;
}
