package OpenStatisticalServices;

our $VERSION = '0.022';

use 5.008008;
use strict;
use warnings;
 
use File::Find;
use Math::Expression;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	Util_convertToLambdaExpression
	Util_convertLambdaExpressionToCSVForm
	Util_convertNONMEMInputFileToCSVForm
	Util_convertDirectoryOfNONMEMInputFilesToCSVForm
	Util_convertDirectoryOfTypedLambdaCalculusFilesToCSVForm
	Util_convertDirectoryOfNONMEMInputFilesToStatML
	Util_convertDirectoryOfStatMLDataFilesToTypedLambdaCalculus
    Util_optimizeDirectoryOfTypedLambdaCalculusFiles
	Util_convertNONMEMDataFilesToTypedLambdaCalculus
	Util_convertStatMLDataToTypedLambdaCalculus
	Util_getSomeTypeOfDataFromStatMLInDirectory
	Util_convertStatMLDataToCSVForm
    Util_isInList
	TLC_getModel
	TLC_getSetOfEquations
	TLC_getExpression
	TLC_getSubExpression
	TLC_getVector
	TLC_getSetOfVectors
	TLC_getSingleVector
	TLC_getLengthOfFirstDimension
	TLC_OptimizeTLCFile
	PK_regularizeFileName
	PK_regularizeFileNamesInGivenDirectory
	NONMEM_convertCSVDataToNONMEMForm
	NONMEM_doSetOfRuns
	NONMEM_getHypernormalizedVersionOfDatasets
	NONMEM_convertParsedNONMEMOutputsToTypedLambdaCalculus
	NONMEM_removeHeaderlinesFromTABFiles
	MONOLIX_splitModelsAccordingToDosing
	MONOLIX_formatMonolixFilesInGivenDirectory
	parseModelFile
);

# Preloaded methods go here.

=head1 NAME

OpenStatisticalServices - Perl extension for representation and use of systems of statistical models using algebraic methods.

=head1 SYNOPSIS

  use OpenStatisticalServices;
  
=head1 DESCRIPTION

This module gives a set of tools for representing and using statistical models using algebraic theories; we also make use of
what is called the functorial semantics of algebraic theories.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

Please see the web site http://openServices.SourceForge.net for details.

=head1 AUTHOR

Rich Haney<lt>@rhaney@cellularStatistics.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 - 2008 by Rich Haney

All rights reserved.

You may freely distribute and/or modify this module under the terms of the GNU General Public License (GPL).

=cut

#-----------------------------------------------------------------------


sub new {
  my $package = shift;
  return bless({}, $package);
}

sub verbose {
  my $self = shift;
  if ($_) {
    $self->{'verbose'} = shift;
  }
  return $self->{'verbose'};
}

sub hoot {
  my $self = shift;
  return "Don't pollute!" if $self->{'verbose'};
  return;
}

#---------------------------------------------------------------------------------

my $improveThis; #this is an indication that I need to improve some aspect of coding.

#---------------------------------------------------------------------------------
#package OpenStatisticalServices::Util

sub Util_optimizeDirectoryOfTypedLambdaCalculusFiles
{
    if ( scalar(@_) < 4 ) 
    {
        print "Sorry, error - usage is Util_optimizeDirectoryOfTypedLambdaCalculusFiles(inputsDirectory,extension,outputsDirectory,outExtension)\n";
        exit;
    }
    my ( $inputsDirectory,$extension,$outputsDirectory, $outExtension ) = @_;
    
    my $oldFileInputSeparator = $/;
    
    $/ = "\n";
    
    opendir(RUNDIR,$inputsDirectory) or die("Could not open run directory $inputsDirectory\n");
    my @files = grep ( /\.$extension/i, readdir(RUNDIR));
    close(READDIR);
    
    foreach my $fileIn ( @files )
    {
	    print $fileIn,"\n";
        my $fileOut = $fileIn;
        $fileOut =~ s/\.$extension/\.$outExtension/ig;
        TLC_OptimizeTLCFile("$inputsDirectory/$fileIn","$outputsDirectory/$fileOut");
    }
    
    $/ = $oldFileInputSeparator;
    
}

sub Util_convertDirectoryOfNONMEMInputFilesToStatML
{
    if ( scalar(@_) < 3 ) 
    {
        print "Sorry, error - usage is Util_convertDirectoryOfNONMEMInputFilesToStatML(inputsDirectory,extension,outputsDirectory)\n";
        exit;
    }
    my ( $inputsDirectory,$extension,$outputsDirectory ) = @_;
    
    my $oldFileInputSeparator = $/;
    
    $/ = "\n";
    
    opendir(RUNDIR,$inputsDirectory) or die("Could not open run directory $inputsDirectory\n");
    my @files = grep ( /$extension$/i, readdir(RUNDIR));
    close(READDIR);
    
    foreach my $fileIn ( @files )
    {
	    print $fileIn,"\n";
        my $fileOut = $fileIn;
        $fileOut =~ s/$extension$/\.xml/ig;
        $fileOut =~ s/\.\./\./g;
        Util_convertNONMEMInputFileToStatML("$inputsDirectory/$fileIn",$outputsDirectory, "$fileOut");
    }
    
    $/ = $oldFileInputSeparator;
    
}

sub Util_convertNTupleAsStringToVector
{
    my $infoString = $_[0];
    $infoString =~ s/.*=//g;
    $infoString =~ s/\[|\]//g;
    $infoString =~ s/,/ /g;
    $infoString =~ s/^\s+|\s+$//g;
    my @parameters = split(/\s+/,$infoString);
    return (@parameters);
    
}


sub Util_convertNONMEMInputFileToStatML
{
    my ( $file, $outputsDirectory, $fileOut ) = @_;

    my @overallDatasetTypes = ("primary","secondary");
    my @overallFieldTypes = ("observations","inputs");
    
	open (INPUTFILE,"$file") or die ("Could not open input file $file\n");
	
    my @data = <INPUTFILE>;
    chomp @data;
    close(INPUTFILE);
	
    $| = 1;
	
    my @dataLinesSplitRefs = ();
    my @firstLineForSubject;
    my $iSubject = -1;

    $data[0]	 =~ s/^[\s#]+//g;
    $data[0]     = uc ($data[0]);
    my @headerHere = split(/\s+|,/,$data[0]);

    my $items = scalar(@headerHere);
	
    my $iEventFieldId = -1;
    my $iDoseFieldId = -1;
    my $iRateFieldId = -1;
    my @inputs = ();

    my @outputs = ();
    my @rates = ();
    my @excluded = ();
    my @fieldLengths = ();
    my @isVector = ();
    my @fieldTypes = ();
    my @attributeStringsForSubjects = ();
    my @dataIsDifferentForIndividuals = ();

    for ( my $iHeader = 0; $iHeader < $items; $iHeader++ )
    {
	    $isVector[$iHeader] = 0;
	    $excluded[$iHeader] = 0;
	    $fieldTypes[$iHeader] = 'fn(AMT) ';
	    $fieldLengths[$iHeader] = 3;
	    $dataIsDifferentForIndividuals[$iHeader] = 0;

        my $headerLabel = uc($headerHere[$iHeader]);
        
	    if (  $headerLabel   =~ /EVID.*/i )
	    {
		    $iEventFieldId = $iHeader;
		    $excluded[$iHeader] = 1;
	    }
	    elsif ( $headerLabel   =~ /MDV.*/i )
	    {
		    $excluded[$iHeader] = 1;
	    }
	    elsif ( $headerLabel =~ /TIME.*/i )
	    {
		    $fieldTypes[$iHeader] = "indepen ";
		    $isVector[$iHeader] = 1;
		    push(@inputs, $iHeader);
		    push(@outputs,$iHeader);
	    }
	    elsif ( $headerLabel =~ /AMT.*/i )
	    {
		    $iDoseFieldId = $iHeader;
		    $fieldTypes[$iHeader] = "ind(TIME)";
		    push(@inputs,$iDoseFieldId);
	    }
	    elsif ( $headerLabel =~ /RATE.*/i )
	    {
		    $iRateFieldId = $iHeader;
		    $fieldTypes[$iHeader] = "ind(TIME)";
		    push(@inputs,$iRateFieldId);
		    $dataIsDifferentForIndividuals[$iHeader] = 1;
	    }
	    elsif ( $headerLabel =~ /LNDV.*/i )
	    {
		    $fieldTypes[$iHeader] = "fn(DV)";
		    push(@outputs,$iHeader);
	    }
	    else
	    {
		    push(@outputs,$iHeader);
	    }
    }
	
    my $iMaxSubject = 0;
    my $iMaxLines = 0;
    my $zeroSubject = 0;
	
    for ( my $i = 0; $i <= $#data; $i++ )
    {
	    my @eachLine;
	    next unless $data[$i] =~ /\w/;
		
	    $data[$i]	 =~ s/^[\s#]+//g;
	    @eachLine	 = split(/\s+|,/,$data[$i]);
	    $dataLinesSplitRefs[$iMaxLines] = \@eachLine;
	    if ( $eachLine[0] eq '0' )
	    {
		    if ( $zeroSubject == 0 )
		    {
			    $zeroSubject = $iMaxSubject+1;
		    }
		    $eachLine[0] = $zeroSubject;
	    }
	    if ( $iEventFieldId > -1 && $eachLine[$iEventFieldId] eq '2' )
	    {
		    $eachLine[$iEventFieldId] = 0;
	    }
	    my $iSubjectHere = $eachLine[0];
	    if ( $iSubject ne $iSubjectHere )
	    {
		    $iSubject = $iSubjectHere;
		    push(@firstLineForSubject,$iMaxLines);
	    }
	    $dataLinesSplitRefs[$iMaxLines] = \@eachLine;
	    if ( $iSubject =~ /\d+/ && $iSubject > $iMaxSubject )
	    {
		    $iMaxSubject = $iSubject;
	    }
	    $iMaxLines++;
    }

    my @subjects;
    for ( my $iSubject1 = 1; $iSubject1 <= $iMaxSubject; $iSubject1++)
    {
	    $subjects[$iSubject1] = $iSubject1;
    }
	
    push ( @firstLineForSubject, $iMaxLines);
		
    my $lastLineRef = $dataLinesSplitRefs[$#dataLinesSplitRefs];
    my @lastLine    = @$lastLineRef;
		
    my @firstDoseForIndividuals = ();

    for ( my $iEventId = 0; $iEventId <= 1; $iEventId++ )
    {   
	    for ( my $id = 1; $id <= $iMaxSubject; $id++)
	    {
		    for ( my $iField = 0; $iField < $items; $iField++ )
		    {
			    my $aName = $headerHere[$iField];
			    $aName =~ s/\"//g;
			    my $iFirstLine = $firstLineForSubject[$id];
			    my $lineRef = $dataLinesSplitRefs[$iFirstLine];
			    unless ( $lineRef =~ /ARRAY/)
			    {
				    print "Error at subject $id, field $iField, lineRef $lineRef \n";
				    exit;
			    }
			    my @dataForLine    = @$lineRef;
			    my @inputsHere = $dataForLine[$iDoseFieldId];
			    if ( $iRateFieldId > -1 )
			    {
			        push(@inputsHere, $dataForLine[$iRateFieldId]);
			    }
			    
			    $firstDoseForIndividuals[$id-1] = \@inputsHere;
			    my $iLastLine = $firstLineForSubject[$id+1]-1;
			    my $numItems = $iLastLine - $iFirstLine + 1;
			    my @dataList = ();

			    my $value = "";
			    for ( my $iLine = $iFirstLine; $iLine <= $iLastLine; $iLine++ )
			    {
				    my $lineNextRef = $dataLinesSplitRefs[$iLine];
				    my @dataForNextLine    = @$lineNextRef;
				    my $iEventIdForLine = 0;
				    if ( $iEventFieldId > -1 )
				    {
				        $iEventIdForLine = toInteger($dataForNextLine[$iEventFieldId]);
				    }
				    next unless ( $iEventIdForLine eq $iEventId);

				    my $datum = $dataForNextLine[$iField];
				    
				    if ( $value eq "" )
				    {	
					    $value = $datum;
					    next;	
				    }
				    elsif ( $value ne $datum)
				    {
					    $isVector[$iField] = 1;
				    }
				    my $len = length($datum);
				    if ( $len > $fieldLengths[$iField])
				    {
					    $fieldLengths[$iField] = $len;
				    }
			    }
		    }
	    }
    }

    my $recordsPerSubject = $firstLineForSubject[2] - $firstLineForSubject[1];
    for ( my $iEventId = 0; $iEventId <= 1; $iEventId++ )
    {
	    for ( my $iField = 0; $iField < $items; $iField++ )
	    {
		    for ( my $iLine = 1; $iLine <= $recordsPerSubject; $iLine++ )
		    {
			    my $value = "";

			    for ( my $iSubject = 1; $iSubject <= $iMaxSubject; $iSubject++ )
			    {
				    my $i = $iLine + ($iSubject-1) * $recordsPerSubject;
				    my $lineRef = $dataLinesSplitRefs[$i];
				    unless ( $lineRef =~ /ARRAY/)
				    {
					    $dataIsDifferentForIndividuals[$iField] = 1;
					    last;
				    }
				    my @data    = @$lineRef;
				    my $iEventIdForLine = 0;
				    if ( $iEventFieldId > -1 )
				    {
				        $iEventIdForLine = toInteger($data[$iEventFieldId]);
				    }

				    next unless ($iEventIdForLine eq $iEventId);

				    my $datum = $data[$iField];
				    if ( $value eq "" )
				    {	
					    $value = $datum;
					    next;	
				    }
				    elsif ( $value ne $datum)
				    {
					    $dataIsDifferentForIndividuals[$iField] = 1;
					    last;
				    }
			    }
			    last if ( $dataIsDifferentForIndividuals[$iField]);
		    }
	    }
    }
	
	my $alsoWriteXMLTabFile = 0;
	if ( $alsoWriteXMLTabFile )
	{
        open(IFILETAB,">$outputsDirectory/$fileOut.tab" ) or die("Count not open data file\n");
        print IFILETAB join("\t",@headerHere),"\n";
    	
        for ( my $i = 1; $i <= $#dataLinesSplitRefs; $i++ )
        {
	        my @data = @{$dataLinesSplitRefs[$i]};
	        for ( my $j = 0; $j < scalar(@data);$j++)
	        {
		        if ( $data[$j] eq "." )
		        {
			        $data[$j] = "nan";
		        }
	        }
	        print IFILETAB join("\t",@data),"\n";
        }
        close(IFILETAB);
    }
        		
    open(IFILE,">$outputsDirectory/$fileOut" ) or die("Count not open data file $file.xml for outputs in $outputsDirectory\n");
	
    print IFILE <<TOP;
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <statml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="statml.xsd">
TOP

    for ( my $iDatasetType = 0; $iDatasetType <=1; $iDatasetType++ )
    {
        my $indentForDataset = "";
        if ( $iDatasetType == 1 )
        {
	        $indentForDataset = "    ";
	        print IFILE q(<Secondary Type="terse">),"\n";
        }
    	
        for ( my $iEventType = 1; $iEventType >= 0; $iEventType-- )
        {
	        my @fields;
	        if ( $iEventType eq 1 )
	        {
		        @fields = @inputs;	
	        }
	        else
	        {
		        @fields = @outputs;
	        }

	        print IFILE $indentForDataset,"<", $overallFieldTypes[$iEventType], ">\n";
	        my $iNumHereLast = 0;
    		
	        my $doCompress = 0;
    		
	        for ( my $iFieldInList = 0 ; $iFieldInList < scalar(@fields); $iFieldInList++ )
	        {

		        my $iField = $fields[$iFieldInList];
		        my $aName = $headerHere[$iField];

                #rph note -- used to have TIME here.
		        next if ( $aName ne "TIME" && ( $iEventType == 1 && ( $iDatasetType == $dataIsDifferentForIndividuals[$iField])));
		        for ( my $id = 1; $id <= $iMaxSubject; $id++)
		        {
		            #Next is for vectors.
			        next unless ( $isVector[$iField] == 1) || $iEventType == 1;
    				
			        last if ( $id > 1 && ! $dataIsDifferentForIndividuals[$iField] );
    				
			        $aName =~ s/\"//g;
			        my $iFirstLine = $firstLineForSubject[$id];
			        my $iLastLine  = $firstLineForSubject[$id+1]-1;
    				
			        my $numItems = $iLastLine - $iFirstLine + 1;
			        my @dataList = ();
    				
			        my @dataHere;
    			
			        for ( my $i = $iFirstLine; $i <= $iLastLine; $i++ )
			        {
				        @dataHere = @{$dataLinesSplitRefs[$i]};
				        my $iSubject = $dataHere[0];
				        my $iEvent   = $dataHere[$iEventFieldId];
 				        my $iEventIdForLine = 0;
				        if ( $iEventFieldId > -1 )
				        {
				            $iEventIdForLine = toInteger($dataHere[$iEventFieldId]);
				        }

				        next unless ($iEventIdForLine eq $iEventType);
 				        my $datum = $dataHere[$iField];
				        push(@dataList,$datum);
			        }
    				
			        my $aLine = "";
			        my $numHere = $#dataList+1;
			        my $iFieldLength = $fieldLengths[$iField];
			        if ( $iEventType == 0 )
			        {
				        $iFieldLength = 8;
			        }
    				
			        #$aLine .= "\n";
			        my $bNotFirst = 0;
                    if ( $numHere > 1 )
                    {
	                    $aLine .= "\[ ";
                    }

			        for ( my $i = 0; $i <= $numHere; $i++ )
			        {
				        my $datum = $dataList[$i];
    
						
    					if ( defined($datum))
    					{
    					    my $aFormattedDatum = sprintf("%10.2f",$datum);

				            my $strlen = $iFieldLength - length($aFormattedDatum)+1;
				            if ( $strlen < 1 )
				            {
					            $strlen = 1;
				            }
				            if ( $doCompress & ( $bNotFirst && ! $isVector[$iField]))
				            {
					            $aFormattedDatum = ' ' x length($aFormattedDatum);
				            }
				            else
				            {
					            $bNotFirst = 1;
				            }
				            $aLine .= " " x $strlen;
				            $aLine .= $aFormattedDatum;
				        }
			        }
                    if ( $numHere > 1 )
                    {
	                    $aLine .= "\] ";
                    }
    				
			        if ( $iNumHereLast == 0 )
			        {
				        $iNumHereLast = $numHere;
			        }
			        if ( $iNumHereLast != $numHere )
			        {
				        #print IFILE "\n";
				        $iNumHereLast = $numHere;
			        }

			        print IFILE
				        q(	<vector );

			        my $aName = $headerHere[$iField];
			        my $iPaddingForName = 4 - length($aName);
			        print IFILE "name", 
				        "=",
				        q("),
				        $aName,
				        ' ' x $iPaddingForName,
				        q(" );

			        my $idToUse = $id;
			        if ( ! $dataIsDifferentForIndividuals[$iField] )
			        {
				        $idToUse = "*";
			        }
			        my $iPaddingForID = 3 - length($idToUse);
    				
			        print IFILE "ID", 
				        "=",
				        q("),
				        $idToUse,
				        ' ' x $iPaddingForID,
				        q(" );
    				 
			        my $aString = "";
			        for ( my $iField1 = 0; $iField1 < scalar(@headerHere); $iField1++ )
			        {
				        next if $isVector[$iField1];
				        next if $excluded[$iField1];
				        next if $dataHere[$iField1] eq ".";
				        my $aName = $headerHere[$iField1];
				        if ( ! defined($aName))
				        {
				            print "Warning - no name for field $iField1\n";
				        }
				        #Improve this.
				        next if $aName eq "ID";
				        
				        my $iPaddingForName  = 4 - length($aName);
				        if ( ! defined($dataHere[$iField1] ))
				        {
				            $dataHere[$iField1] = "";
				        }

                        my $aFormattedDatum = sprintf("%10.2f",$dataHere[$iField1]);
				        my $iPaddingForValue = $fieldLengths[$iField1] - length($aFormattedDatum);
					        
					    my $totalPaddingForValue = "";
					    if ( $iPaddingForValue > 0 )
					    {
					        $totalPaddingForValue = ' ' x $iPaddingForValue;
                        }
                        

				        $aString .=  $aName .
					        "=" .
					        q(") .
					        $aFormattedDatum . 
					        $totalPaddingForValue .
					        q(" );
			        }
			        $attributeStringsForSubjects[$id] = $aString;
    				
			        if ( $dataIsDifferentForIndividuals[$iField])
			        {
				        print IFILE $aString;
			        }
			        elsif ( $iEventType == 0 )
			        {
				        print IFILE ' ' x length($aString);
			        }
				        
			        my $iPadding = 3 - length($numHere);
			        my $iPaddingForType = 8 - length($fieldTypes[$iField]);
			        print IFILE
				        q(type="),
				        $fieldTypes[$iField],
				        ' ' x $iPaddingForType,
				        q(" ),
				        q(format="float" dim="), 
				        $numHere, 
				        ' ' x $iPadding,
				        q(");
    					
			        print IFILE
				        q(>),
				        $aLine;

			        print IFILE 
				         " </vector>\n";
    		
    				
			        unless ( $dataIsDifferentForIndividuals[$iField])
			        {
				        if ( $iEventType > 0 && $iDatasetType == 1)
				        {
    				
					        for ( my $iDatum = 0; $iDatum <= 1; $iDatum++)
					        {
    					
						        my $inputField = $iDoseFieldId;
						        if ( $iDatum > 0 )
						        {
							        if ( $iRateFieldId == 0 )
							        {
								        next;
							        }

							        $inputField = $iRateFieldId;
						        }
						        my $aLine = Util_getNONMEMDataLine(\@firstDoseForIndividuals,$iDatum,$iFieldLength);
						        my $numHere = scalar(@firstDoseForIndividuals);
    									
						        my $iFieldLength = $fieldLengths[$iDoseFieldId];
    							
						        if ( $iNumHereLast == 0 )
						        {
							        $iNumHereLast = $numHere;
						        }
						        if ( $iNumHereLast != $numHere )
						        {
							        print IFILE "\n";
							        $iNumHereLast = $numHere;
						        }
						        print IFILE
							        q(	<vector );

						        my $aName = $headerHere[$inputField];
						        my $iPaddingForName = 4 - length($aName);
						        print IFILE "name", 
							        "=",
							        q("),
							        $aName,
							        ' ' x $iPaddingForName,
							        q(" ),
							        q(ID="*  " );
    	
						        my $iPaddingHere = 3 - length($numHere);
						        my $iPaddingForField = 8 - length($fieldTypes[$inputField]);
						        print IFILE
							        q(type="),
							        $fieldTypes[$inputField],
							        ' ' x $iPaddingForField,
							        q(" ),
							        q(format="float" dim="), 
							        $numHere,
							        ' ' x $iPaddingHere , 
							        q(");

						        print IFILE
							        q(>),
							        $aLine;

						        print IFILE 
							        "	</vector>\n";
    								
						        if ( 0 )
						        {
							        open(CSVFILE,">$file.inputs.csv" ) or die("Count not open csv file\n");
							        print CSVFILE $aName,
    		
							        my $iPadding = 3 - length($numHere);
    								
							        print CSVFILE
								        q(format="float" dim="), 
								        $numHere,
								        ' ' x $iPadding, 
								        q(");

							        print CSVFILE
								        q(>),
								        $aLine;

							        print CSVFILE 
								        "	</vector>\n";
						        }			

					        }
				        }
			        }
		        }
	        }
	        print IFILE "$indentForDataset</", $overallFieldTypes[$iEventType], ">\n\n";
        }
	
        print IFILE $indentForDataset, q(<attributesSet field="ID">),"\n";
        foreach my $iSubjectAttributes ( @subjects )
        {
            if ( defined($iSubjectAttributes) )
            {
                if ( defined($attributeStringsForSubjects[$iSubjectAttributes])) #improve this
                {
	                if (  $attributeStringsForSubjects[$iSubjectAttributes] ne "" )
	                {
		                print IFILE "	<attributes         $attributeStringsForSubjects[$iSubjectAttributes] ></attributes>\n";
	                }
	            }
	        }
        }
        print IFILE "$indentForDataset</attributesSet>\n\n";
        print IFILE "$indentForDataset<constraints>\n";

        print IFILE "	$indentForDataset<equation> TIME      >= 0               >  </equation>\n";
        print IFILE "	$indentForDataset<equation> DV        >= 0               >  </equation>\n";

        print IFILE "	$indentForDataset<equation> LNDV(TIME) = ln (DV(TIME))   >  </equation>\n";
        print IFILE "	$indentForDataset<equation> DV(TIME)   = exp(LNDV(TIME)) >  </equation>\n";
        print IFILE "	$indentForDataset<equation> DOSE(ID)   = AMT(ID)         >  </equation>\n";

        print IFILE $indentForDataset,"</constraints>\n\n";
        if ( $iDatasetType == 1 )
        {
            print IFILE <<MATHML;
	
    <expressions>
        <expression type="string" name="AMT ">  AMT*(delta(0)+delta(72)+delta(96)+delta(120)+delta(144)+delta(168)+delta(192)+delta(216)) </expression>
        <expression type="MathML">
    <math xmlns='http://www.w3.org/1998/Math/MathML'>
    <semantics>
        <mrow xref='id27'>
          <mi xref='id1'>AMT</mi>
          <mo>ApplyFunction;</mo>
          <mfenced>
            <mrow xref='id26'>
              <mrow xref='id4'>
                <mi xref='id2'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id3'>0</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id7'>
                <mi xref='id5'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id6'>72</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id10'>
                <mi xref='id8'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id9'>96</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id13'>
                <mi xref='id11'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id12'>120</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id16'>
                <mi xref='id14'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id15'>144</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id19'>
                <mi xref='id17'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id18'>168</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id22'>
                <mi xref='id20'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id21'>192</mn>
                </mfenced>
              </mrow>
              <mo>+</mo>
              <mrow xref='id25'>
                <mi xref='id23'>delta;</mi>
                <mo>ApplyFunction;</mo>
                <mfenced>
                  <mn xref='id24'>216</mn>
                </mfenced>
              </mrow>
            </mrow>
          </mfenced>
        </mrow>
        <annotation-xml encoding='MathML-Content'>
          <apply id='id27'>
            <ci id='id1'>AMT</ci>
            <apply id='id26'>
              <plus/>
              <apply id='id4'>
                <ci id='id2'>delta</ci>
                <cn id='id3' type='integer'>0</cn>
              </apply>
              <apply id='id7'>
                <ci id='id5'>delta</ci>
                <cn id='id6' type='integer'>72</cn>
              </apply>
              <apply id='id10'>
                <ci id='id8'>delta</ci>
                <cn id='id9' type='integer'>96</cn>
              </apply>
              <apply id='id13'>
                <ci id='id11'>delta</ci>
                <cn id='id12' type='integer'>120</cn>
              </apply>
              <apply id='id16'>
                <ci id='id14'>delta</ci>
                <cn id='id15' type='integer'>144</cn>
              </apply>
              <apply id='id19'>
                <ci id='id17'>delta</ci>
                <cn id='id18' type='integer'>168</cn>
              </apply>
              <apply id='id22'>
                <ci id='id20'>delta</ci>
                <cn id='id21' type='integer'>192</cn>
              </apply>
              <apply id='id25'>
                <ci id='id23'>delta</ci>
                <cn id='id24' type='integer'>216</cn>
              </apply>
            </apply>
          </apply>
        </annotation-xml>
        <annotation encoding='Maple'>AMT(delta(0)+delta(72)+delta(96)+delta(120)+delta(144)+delta(168)+delta(192)+delta(216))</annotation>
      </semantics>
    </math>
   </expression>
</expressions>

MATHML

	        print IFILE "</Secondary>\n\n";
        }
    }	

    print IFILE q(<Secondary type="NONMEM">);
    foreach my $line ( @data )
    {
	    print IFILE $line, "\n";
    }
    print IFILE q(</Secondary>),"\n";

    print IFILE "</statml>\n";

    close(IFILE);

}

sub Util_convertNONMEMDataFilesToTypedLambdaCalculus
{
    Util_convertDirectoryOfNONMEMInputFilesToStatML("/oss/runs/","DATA", "/oss/runs/","model");

    Util_getSomeTypeOfDataFromStatML("inputs","","xml1");
    Util_getSomeTypeOfDataFromStatML("obs","","xml1","append");
    Util_convertStatMLDataToTypedLambdaCalculus("c:/oss/winBUGS/theo.xml1","c:/oss/winBUGS/theo.tlc","model");
}

sub Util_convertStatMLDataToTypedLambdaCalculus
{

    my ( $fileInput, $fileOutput, $criterion ) = @_;
    
    open(FILE,$fileInput) or die("Could not open file $fileInput\n");
    open(FILEOUTPUT,">$fileOutput") or die("Could not open file $fileOutput\n");
  
    while(<FILE>)
    {
        chomp;

        my ($attributeList,$vector) = split(/\>/,$_);
        $attributeList =~ s/\<vector\s+|\>//g;
        $vector =~ s/\<\/vector//g;
        my $overallType = "";
        if ( $attributeList =~ /$criterion\=\"(.*)\"\s+/ )
        {
            $overallType = $1;
            $attributeList =~ s/$criterion\=\".*\"\s+//;
        }
        
        $attributeList =~ s/\s+\"/\"/g;
        my @attributes = split(/\"\s+/,$attributeList);

        my @rhs = @attributes;
        my @lhs = @attributes;

        my @vectorOfAttributesAndData = ();
        for ( my $i = 0; $i < scalar(@attributes); $i++)
        {
	        $rhs[$i] =~ s/.*=|\"//g;
	        $lhs[$i] =~ s/=.*|//g;
	        $rhs[$i] =~ s/\s+//g;
	        if ( $i > 1 && ! ( $rhs[$i] =~ /[a-zA-Z]/ ) )
	        {
	            push(@vectorOfAttributesAndData,$rhs[$i]);
	        }
        }
        $vector =~ s/\[|\]//g;
        $vector =~ s/^\s+|\s+$//g;

        my $vectorOfAll = "";
        my $attributesFlag = "";
        if ( $vector =~ /\w/)
        {
            $vectorOfAll = $vector;
        }
        else
        {        
            $vectorOfAll = join(" ",@vectorOfAttributesAndData);
            $attributesFlag = "Attributes";
        }
        $vectorOfAll =~ s/\s+/ /g;
        if ( ! defined($rhs[0]) )
        {
            $rhs[0] = "";
        } 
        if ( ! defined($rhs[1]) )
        {
            $rhs[1] = "";
        } 
        if ( ! defined($vectorOfAll))
        {
            $vectorOfAll = "";
        }           
        if ( ! defined($overallType))
        {
            $overallType = "";
        } 
		#hack
		$rhs[0] =~ s/AMT/ID/g;
        print FILEOUTPUT "$rhs[0]$attributesFlag\[$rhs[1]\]:$overallType$attributesFlag = [ $vectorOfAll ] ";

        print FILEOUTPUT "\n";
    }
}
sub Util_convertStatMLDataToCSVForm
{

    my ( $fileInput, $fileOutput, $criterion ) = @_;
    
    open(FILE,$fileInput) or die("Could not open file $fileInput\n");
    open(FILEOUTPUT,">$fileOutput") or die("Could not open file $fileOutput\n");
  
    print FILEOUTPUT "Modelname, FieldName, SubjectID, AsFunction, ElementType, Length, Vector\n";

    while(<FILE>)
    {
        chomp;

        my ($attributeList,$vector) = split(/\>/,$_);
        $attributeList =~ s/\<vector\s+|\>//g;
        $vector =~ s/\<\/vector//g;
        my $overallType = "";
        if ( $attributeList =~ /$criterion\=\"(.*)\"\s+/ )
        {
            $overallType = $1;
            $attributeList =~ s/$criterion\=\".*\"\s+//;
        }
        
        $attributeList =~ s/\s+\"/\"/g;
        my @attributes = split(/\"\s+/,$attributeList);

        my @rhs = @attributes;
        my @lhs = @attributes;

		print FILEOUTPUT $overallType;

        my $attributesFlag = "";
        if ( $vector =~ /\w/)
        {
        }
        else
        {        
            $attributesFlag = "Attributes";
        }
        print FILEOUTPUT ",$rhs[0]$attributesFlag";
	
        for ( my $i = 1; $i < scalar(@attributes); $i++)
        {
	        $rhs[$i] =~ s/.*=|\"//g;
	        $lhs[$i] =~ s/=.*|//g;
	        print FILEOUTPUT ",", $rhs[$i];
        }

        print FILEOUTPUT q(,"\[), $vector, q(\]");

        print FILEOUTPUT "\n";
    }
}

sub Util_getSomeTypeOfDataFromStatMLInDirectory 
{
    if ( scalar(@_) < 5 )
    {
        print "Sorry, usage is Util_getSomeTypeOfDataFromStatML(wordForTypeOfData,useFileInsteadOfWord,extension, possibleSecondaryData,fileExtensionForOutput,append)\n";
        return;
    }
        
    my ( $wordForTypeOfData, $useFileInsteadOfWord, $extension, $possibleSecondaryData, $fileExtensionForOutput, $append )= @_;
    
    if ( ! defined($possibleSecondaryData) )
    {
        $possibleSecondaryData = "";
    }
    
    my $doAppend = 0;
    if ( defined($append) && $append =~ /^append/i)
    {
        $doAppend = 1;
    }

    my $ignoreSecondaryData = 1;
    my $secondaryFilterToUse = 1;
    if( $possibleSecondaryData =~ /"Secondary"/i ) 
    {
        $ignoreSecondaryData = 0;
        #In this case, get both primary and secondary by default.
        $secondaryFilterToUse = 1;
    }
    
    my $primaryFilterToUse = 0;

    foreach my $fileIn( <*.xml>)
    {

        my $modelName = $fileIn;
        $modelName =~ s/\.xml//g;

        my $fileOut = $fileIn;
        $fileOut =~ s/\.xml/\.$fileExtensionForOutput/g;

        my $modelNameToUse = $modelName;
        if ( $useFileInsteadOfWord)
        {
            $modelNameToUse = $modelName;
        }
        else
        {
            $modelNameToUse = "";
        }
        Util_getSomeTypeOfDataFromStatML($fileIn, $fileOut,$modelNameToUse, $extension, $wordForTypeOfData, $possibleSecondaryData, $append);

    }
}

sub Util_getSomeTypeOfDataFromStatML
{
    if ( scalar(@_) < 4 )
    {
        print "Sorry, usage is Util_getSomeTypeOfDataFromStatML(...)";
        return;
    }
        
    my ( $fileIn, $fileOut, $modelNameToUse, $extension, $wordForTypeOfData, $possibleSecondaryData,  $append ) = @_;
    
    if ( ! defined($possibleSecondaryData) )
    {
        $possibleSecondaryData = "";
    }
    
    my $doAppend = 0;
    if ( defined($append) && $append =~ /^append/i)
    {
        $doAppend = 1;
    }

    my $ignoreSecondaryData = 1;
    my $secondaryFilterToUse = 1;
    if( $possibleSecondaryData =~ /"Secondary"/i ) 
    {
        $ignoreSecondaryData = 0;
        #In this case, get both primary and secondary by default.
        $secondaryFilterToUse = 1;
    }
    
    my $primaryFilterToUse = 0;

    open(FILE,$fileIn) or die("Could not open file $fileIn\n");
    
    if ( $doAppend )
    {
        open(FILEOUT,">>$fileOut") or die("Could not open file $fileOut\n");
    }
    else
    {
        open(FILEOUT,">$fileOut") or die("Could not open file $fileOut\n");
    }
    
    while(<FILE>)
    {
        if ( /^\<\/$wordForTypeOfData/ )
        {
	        $primaryFilterToUse = 0;
        }

        if ( /^\<Secondary/ )
        {
            unless ( $ignoreSecondaryData )
            {
                $secondaryFilterToUse = 0;
            }
         }
        if ( /^\<\/Secondary/ )
        {
            unless ( $ignoreSecondaryData )
            {
                $secondaryFilterToUse = 1;
            }
        }

        if ( $primaryFilterToUse && $secondaryFilterToUse )
        {
        
            s/^.*\<vector/\<vector/o;
            if ( $modelNameToUse ne "" )
            {
                s/\>/ modelName=\"$modelNameToUse\" modelType=\"$extension\" \>/i;
	        }
	        else
	        {
	            s/\>/ stage=\"$wordForTypeOfData\" \>/i;
	        }
	        print FILEOUT $_;
        }
        
        if ( /^\<$wordForTypeOfData/ )
        {
	        $primaryFilterToUse = 1;
        }

    }
    close(FILE);
    close(FILEOUT);
}

sub getCSVFromStatML
{

    my ($fileInput,$fileOutput) = $_;
    
    open(FILE,$fileInput) or die("Could not open file $fileInput\n");
    open(FILEOUTPUT,">fileOutput") or die("Could not open file $fileOutput\n");
  
    print FILEOUTPUT "Modelname, FieldName, SubjectID, AsFunction, ElementType, Length, Vector\n";

    while(<FILE>)
    {
        chomp;

        my ($file,$attributeList,$vector) = split(/\<vector|\<\/vector|\>/);

        $file =~ s/\_data.txt.*//g;

        $attributeList =~ s/^\s+|\s+$|vector\s+//g;
        my @attributes = split(/\"\s+/,$attributeList);

        my @rhs = @attributes;
        my @lhs = @attributes;

        for ( my $i = 0; $i < scalar(@attributes); $i++)
        {
	        $rhs[$i] =~ s/.*=|\"//g;
	        $lhs[$i] =~ s/=.*|//g;
	        print FILEOUT ",", $rhs[$i];
        }
        
        print FILEOUT q(,"),$vector, q(");
        print FILEOUT "\n";

    }
    close(FILE);
    close(FILEOUTPUT);
}

sub createCSVForConstraintsFromStatML
{

    my ($fileInput,$fileOutput) = $_;
    
    open(FILE,$fileInput) or die("Could not open file $fileInput\n");
    open(FILEOUTPUT,">fileOutput") or die("Could not open file $fileOutput\n");

    my $oldFile = "";
    my $iNumber = 0;

    print FILEOUTPUT "ModelName, Numer, Constraint\n";

    while(<FILE>)
    {
        chomp;

        my ($file,$equation,$extra) = split(/\<equation\>|[\>\s+]*\<\/equation\>/,$_,3);
        my $attributeList = "";

        $file =~ s/\_data.txt.*//g;

        if ( $oldFile ne $file )
        {
	        $oldFile = $file ;
	        $iNumber = 1;
        }
        	
        print FILEOUTPUT $file, ", ", $iNumber++;

        $attributeList =~ s/^\s+|\s+$|equation\s+//g;
        my @attributes = split(/\"\s+/,$attributeList);

        my @rhs = @attributes;
        my @lhs = @attributes;

        for ( my $i = 0; $i < scalar(@attributes); $i++)
        {
	        $rhs[$i] =~ s/.*=|\"//g;
	        $lhs[$i] =~ s/=.*|//g;
	        print ",", $rhs[$i];
        }
	    print FILEOUTPUT q(,"),$equation, q(");
	    print FILEOUTPUT "\n";

    }

    close(FILE);
    close(FILEOUTPUT);

}



sub Util_getNONMEMDataLine
{
    my ($firstDoseForIndividuals,$iDatum,$iFieldLength ) = @_;
    my @firstDoseForIndividuals = @$firstDoseForIndividuals;
    my $numHere = scalar(@firstDoseForIndividuals);
    my $aLine = "";
    if ( $numHere > 1 )
    {
	    $aLine .= "\[ ";
    }
    
    for ( my $i = 0; $i < $numHere; $i++ )
    {
	    my $datumRef = $firstDoseForIndividuals[$i];
	    my (@datums) = @$datumRef;
	    if ( $iDatum <= $#datums)
	    {
	        my $datum = $datums[$iDatum];
	        if ( defined($datum) && $datum ne "" )
	        {
	            my $strlen = $iFieldLength - length($datum)+1;
	            if ( $strlen < 1 )
	            {
	            
		            $strlen = 1;
	            }
	            $aLine .= " " x $strlen;
	            
	            $aLine .= $datum;
	        }
	    }
    }
    if ( $numHere > 1 )
    {
	    $aLine .= "\] ";
    }

    return ( $aLine);
}

sub Util_convertDirectoryOfNONMEMInputFilesToCSVForm
{
	my ( $inputDirectory, $outputDirectory ) = @_;

    opendir(READDIR,"$inputDirectory");
    my @files = grep { /\.txt/ } readdir(READDIR);
    close(READDIR);

    for my $fileIn ( <@files>)
    {
	    my $fileOut = $fileIn;
	    $fileOut =~ s/txt/csv/g;

	    print $fileIn, "\n";
    	
	    Util_convertNONMEMInputFileToCSVForm("$inputDirectory/$fileIn","$outputDirectory/$fileOut");
    }

}


sub NONMEM_removeHeaderLineFromTABFiles
{
	my ( $inputDirectory, $extension, $outputDirectory ) = @_;

    opendir(READDIR,"$inputDirectory") or die("Could not open input directory $inputDirectory\n");
    
    if ( $extension =~ /^\./)
    {
        $extension =~ s/\.//g;
    }
    
    my @files = grep { /\.$extension/ } readdir(READDIR);
    close(READDIR);

    for my $fileIn ( <@files>)
    {
	    my $fileOut = $fileIn;

	    open(FILE,$fileIn) or die("Could not read in input file $fileIn\n");
    	my @lines = <FILE>;
    	close(FILE);
    	
        my $iStartingLine = 0;
        if ( $lines[0] =~ /TABLE/i)
        {
            $iStartingLine = 1;
        }
        if ( $iStartingLine == 1 or ( $inputDirectory ne $outputDirectory ) )
        {
    	    open(FILEOUT,">$fileOut") or die("Could not open output file $fileOut\n");
    	    print FILEOUT @lines[$iStartingLine .. $#lines];
    	    close(FILEOUT);
    	}
    }

}


sub Util_convertNONMEMInputFileToCSVForm
{

	my ( $fileInput, $fileOutput ) = @_;

    open(FILE,$fileInput) or die("Could not open file\n");
    open(FILEOUTPUT,">$fileOutput") or die("Could not open output file\n");

    my @data = <FILE>;
    $data[0] =~ s/^[\s|\#]+//g;
    $data[0] =~ s/\,/ /g;

    my @headerHere = split(/\s+|\,/,$data[0]);

    print FILEOUTPUT join(",",@headerHere), "\n";
	for ( my $i = 1; $i <= $#data; $i++ )
	{

		my $line = $data[$i];
		$line =~ s/^\s+|\#|\[|\]|\"|,/ /g;
		my @dataHere = split(/\s+/,$line);
		print FILEOUTPUT join(",",@dataHere),"\n";
	}
	
    close(FILE);
    close(FILEOUTPUT);

}

sub Util_isInList
{
    my ( $variable, @variables ) = @_;
    my $iFound = -1;

    my $iVar = 0;
    for my $testVar ( @variables )
    {
        if ( $variable eq $testVar )
        {
            $iFound = $iVar;
        }
        $iVar++;
    }
    return ($iFound);
}

sub Util_stripPrefixes
{
    my $iFound = -1;
    my ( $variablesRef, $prefix ) = @_;
    
    my @newVariables = ();
    
    my $iVar = 0;
    my @variables = @$variablesRef;
    for my $testVar ( @variables )
    {
        $testVar =~ s/^$prefix//ig;
        push(@newVariables,$testVar);
    }
    return (\@newVariables);
}

#Hack - use grep.
sub Util_isInListWithPrefix
{
    my $iFound = -1;
    my ( $variable, $prefix, @variables ) = @_;
    my $iVar = 0;
    for my $testVar ( @variables )
    {
        if ( uc($prefix . $testVar) eq uc($variable) )
        {
            $iFound = $iVar;
        }
        $iVar++;
    }
    return ($iFound);
}

sub Util_convertLambdaExpressionToCSVForm
{
    my ( $lambdaExpression ) = $_[0];

    my $CSVForm = "";
    
    my $relationalOperator = "\=";
    if ( $lambdaExpression =~ /\~/)
    {
		$relationalOperator = "\~";
	}
	my @parts = split(/$relationalOperator/,$lambdaExpression,2);
	if ( ! defined($parts[1]))
	{
	    $parts[1] = "";
	}
	
    my ($name,$type);
    if ( defined($parts[0]))
    {
        ($name,$type) = split(/:/,$parts[0]);
    }
    if ( !defined($name))
    {
        return "";
    }    
    if ( !defined($type))
    {
        return "";
    }
    
    $CSVForm = $type . ", " . $name . "," . $relationalOperator . "," . "\"" . $parts[1] . "\"" ;
     
    return $CSVForm;
}


sub Util_convertToLambdaExpression
{
    my ( $string ) = $_[0];
    
    my $lambdaExpressions = "";
   
    if ( $string =~ /[a-zA-Z]/)
    {
        my @strings = split(/\n/, $string);

        foreach my $string1 ( @strings )
        {
            $string1 =~ s/^\s+|\s+$//g;
            $string1 =~ s/\"//g;
            my $lambdaExpression = $string1;
            unless ( $string1 =~ /:/)
            {
                my @parts = split(/,/,$string1,4);
                my $nParts = scalar(@parts);
 
                if ( ! defined($parts[0]))
                {
                    $parts[0] = "";
                }
                if ( ! defined($parts[1]))
                {
                    $parts[1] = "";
                }
                if ( ! defined($parts[2]))
                {
                    $parts[2] = "";
                }
                if ( ! defined($parts[3]))
                {
                    $parts[3] = "";
                }
                if ( $parts[1] eq "" )
                {
                    $parts[1] = $parts[0];
                }
                if ( $nParts > 0 )
                {
                    $parts[0] =~ s/^\s+|\s$//g;
                    if ( $nParts > 1 )
                    {
                        $parts[1] =~ s/^\s+|\s$//g;
                        if ( $nParts > 2 )
                        {
                            $parts[2] =~ s/^\s+|\s$//g;
                            if ( $nParts > 3 )
                            {
                                $parts[3] =~ s/^\s+|\s$//g;
                                $improveThis = 1;
                                $parts[3] =~ s/^,//g;
                                $parts[3] =~ s/,\s+\]/\]/g;
                            }
                        }
                    }
                }
                
                $lambdaExpression = "$parts[1]:$parts[0]$parts[2]$parts[3]\n";
                
            }
            
            $lambdaExpressions .= $lambdaExpression;
        }
    }
    return $lambdaExpressions;
}



#-----------------------------------------------------------------------
#package PK

sub PK_sortVariableNamesInDottedList
{
    my $variablesInDottedList = $_[0];
         
    my $UCVariablesInDottedList = uc ($variablesInDottedList);
    
    my @variables = split(/\./,$UCVariablesInDottedList);

    my @newVariables = PK_sortVariableNames(@variables);
    
    my $newDotList = join(".",@newVariables);

    return ( $newDotList );

}

sub PK_sortVariableNames
{
    my @variables = @_;
    my @orderOfVariables = ("ALPHA","BETA","AB", "A","B","TI", "D1", "TLAG", "ALAG1","V", "V1", "V2", "V3",  "KA",   "Q", "CL", "K", "K12","VM","KM","K21","W","RSV","IND");

    my @newVariables = ();
    
    my $VFound  = Util_isInList("V", @variables);
    my $V1Found = Util_isInList("V1",@variables);
    my $V2Found = Util_isInList("V2",@variables);
    my $V3Found = Util_isInList("V3",@variables);
   
    my $myList = join(",", @variables);
     
    foreach my $variable ( @orderOfVariables )
    {
        my $variableUsed = $variable;
        my $iFound = Util_isInList($variableUsed,@variables );
        
        if ( $variableUsed eq "V1" && ($VFound) < 0 && ($V2Found < 0) )
        {
            $variableUsed = "V";
        }

        if ( $variableUsed eq "V2" && ($VFound) < 0 && ( $V1Found < 0 ) && ( $V3Found >= 0 ))
        {
            $variableUsed = "V1";
        }
        if ( $variableUsed eq "V3" && ($VFound) < 0 && ( $V1Found < 0 ) && ( $V2Found >= 0 ))
        {
            $variableUsed = "V2";
        }
        
        if ( $variableUsed eq "V2" && ($VFound) < 0 && ( $V1Found < 0 ) && ( $V3Found < 0 ))
        {
            $variableUsed = "V";
        }
  
        if ( $variableUsed eq "ALAG1")
        {
            $variableUsed = "TLAG";
        }      

        if ( $iFound >= 0)
        {  
            push(@newVariables,$variableUsed);     
        }
    }
    return ( @newVariables);

}

sub PK_regularizeFileNamesInGivenDirectory
{

    my ( $inputDirectory, $extension ) = @_;
    
    opendir(RUNDIR,$inputDirectory) or die("Could not open input directory $inputDirectory\n");
    my @files = grep ( /\.$extension/i, readdir(RUNDIR));
    close(READDIR);
     
    foreach my $fileName ( @files )
    {
	    my $newName = uc(PK_regularizeFileName($fileName,".$extension"));

	    if ( $fileName ne $newName)
	    {
		    print "mv $inputDirectory\\$fileName $inputDirectory\\$newName\n"; 
	    }

    }
}

sub MONOLIX_formatMonolixFilesInGivenDirectory
{

    my ( $directoryToUse, $replaceFunctionsWithFunctionContents ) = @_;
    
    my @files = <*.M>;

    my @functionNames = @files;
    my %actualFileNames = ();

    my $oldSeparator =  $/;
    $/ = "\n";

	my $functionName;

    for ( my $i = 0; $i < scalar(@functionNames); $i++ )
    {
	    my $fileName = $functionNames[$i];
	    $functionName = $fileName;
	    $functionName =~ s/\.m//ig;
	    $functionName =~ s/\_SD|\_MD|\_SS//ig;
	    $functionName =~ s/\.//g;
	    $functionNames[$i] = $functionName;
	    $actualFileNames{$functionName} = $fileName;
    	
    }
    foreach my $file ( @files )
    {

        print $file, "\n";
        $functionName = $file;
        
        my $firstFunction = 1;

	    $functionName =~ s/\.m//ig;
	    my $dosingType = substr($functionName,length($functionName)-2,2);
	    if ( $dosingType ne "SD" && $dosingType ne "MD" && $dosingType ne "SS" )
	    {
	        $dosingType = "SD";
	    }
	    if ( $dosingType ne "" )
	    {
	        $dosingType = "_" . $dosingType;
	    }
 
        $/ = "\n";
        open(FILE,$file) or die ("Could not open $file\n");
        my @lines = <FILE>;
        close(FILE);

        my @newLines = ();
        my $lastLine;
        
        my $alreadyReplacedAFunction = 0;

        foreach my $line ( @lines)
        {
	        next if $line =~ /\-\-\-\-\-\-\-\-\-\-\-\-/;
	        $line =~ s/^\s+//g;
            $line =~ s/\%.*//g;
	        unless ( $line =~ /\w/)
	        {
		        unless ( $lastLine =~ /\w/ )
		        {
			        next;
		        }
	        }
        	
	        $line =~ s/^\s+|\s+$//g;
    	    
	        if ( $line =~ /^function/ && $firstFunction )
	        {
	            unless ( $dosingType eq "" or $line =~ /\_$dosingType/)
	            {
	                $line =~ s/\(/\_$dosingType\(/o;
	            }
		        $firstFunction = 0;
		        $line =~ s/\_\_/\_/g;

	        }
	        elsif ( ( ! $firstFunction ) && $replaceFunctionsWithFunctionContents && ( ! $alreadyReplacedAFunction) )
	        {
                if ( $line =~ /VK12/i)
                {
                    #$line =~ s/[V]+K12/VKK12/i;
                }
                my $lineBeforeComment = $line;
                $lineBeforeComment =~ s/\%.*//g;
		        foreach $functionName ( @functionNames )
		        {
			        if ( $lineBeforeComment =~ /$functionName/i )
			        {
			           my $fileName = $actualFileNames{$functionName};
			           $fileName = substr($fileName,0,length($fileName)-5);
			           my $completeName ="${fileName}${dosingType}.M";
				       print ", function: $functionName,filename: $completeName\n";
				       open(FILEINPUT,$completeName) or die("Could not open $completeName for $file");
				       my @otherFunctionLines = <FILEINPUT>;
				   
				       if ( scalar(@otherFunctionLines) > 1 )
				       {
				            for ( my $iNew = 1; $iNew < scalar(@otherFunctionLines); $iNew++ )
				            {
				                push(@newLines,$otherFunctionLines[$iNew]);
				            }
				            #Forget the original line;
				            $line = "";
				       }
				       $alreadyReplacedAFunction = 1;
				       last;
			        }
		        }
		        $line = "\t" . $line;

	        }

	        $line .= "\n";
	        push(@newLines,$line);

	        $lastLine = $line;
        }

        open(FILE,">$file") or die("Could not open output\n");
        print FILE @newLines;
        close(FILE);

    }
    
    $/ = $oldSeparator;

}

 
sub PK_regularizeFileName
{
    my ($newName, $extension ) = @_;

    $newName =~ s/$extension$//ig;
    if ( $newName =~ /\.$/)
    {
        $newName =~ s/\.$//g;
    }
    if ( $newName =~ /\_$/)
    {
        $newName =~ s/\_$//g;
    }
    $newName = uc($newName);

    $newName =~ s/(ALPHA|BETA|TLAG|KA|K12|VM|K21|TI|TK0|KA|CL|V1|V2|KM|EMAX|GAMMA|IMAX|BMAX|PK|PD|VK)/\.$1\./g;
    $newName =~ s/\.VK\./\.V\.K\./g;
    $newName =~ s/\.VK\_/\.V\.K\_/g;
    #Replace instances of K together with K21, with K12 and K21
    if ( $newName =~ /K21/)
    {
        if ( $newName =~ /K\./)
        {
            unless( $newName =~ /K12/)
            {
                $newName =~ s/K\./K12\./g;
            }
        }
    }
    $newName =~ s/\.\_|\_\./\_/g;
    $newName =~ s/\.\./\./g;

    $newName =~ s/\.$//g;

    my @nameParts = split(/\_/,$newName);
    my $routing = $nameParts[0];
    my $compartments = $nameParts[1];
    my $dosingType = $nameParts[$#nameParts];

    if ( $dosingType ne "SD" && $dosingType ne "MD" && $dosingType ne "SS" )
    {
	    $dosingType = "";
    }
    else
    {
	    $dosingType = "_" . $dosingType;
    }
    my $parameters = $nameParts[2];

    my $revisedParameters = "";

    my $reviseParameters = 1;
    if ( $reviseParameters )
    {
        $revisedParameters = PK_sortVariableNamesInDottedList($parameters);
    }
    else
    {
        $revisedParameters = $parameters;
    }
    
    if ( $revisedParameters ne "" )
    {
        $revisedParameters = "_" . $revisedParameters;
    }
    
    $newName = "${routing}_${compartments}${revisedParameters}${dosingType}";

    $newName .= ".$extension";
    $newName =~ s/\.\./\./g;
    $newName =~ s/\_\.|\.\_/\_/g;

    $newName = uc($newName);

    return $newName;

}

#------------------------------------------------------------------------------
#package OpenStatisticalServices::NONMEM

#Add MDV, EVID and possibly other elements to data that is not in "NONMEM" form.
sub NONMEM_convertCSVDataToNONMEMForm
{
    my ($fileIn, $fileOut) = @_;
    
    open(FILE,$fileIn) or die("Could not open $fileIn\n");
    open(FILEOUT,">$fileOut") or die("Could not open $fileOut\n");
   
    my $header = <FILE>;
    chomp $header;
    print FILEOUT "$header AMT MDV EVID\n";
    my $iSubject = 0;
    while(<FILE>)
    {
	    chomp;
	    my @data = split(/\s+/,$_);

	    if ( $data[1] ne $iSubject )
	    {
		    $data[5] = 0;
		    my $newData = join(" ",@data[1 .. $#data]);
		    print FILEOUT "$newData $data[3] 1 1\n";
		    $iSubject = $data[1];
		    next;
	    }
	    my $newData = join(" ",@data[1 .. $#data]);

	    print FILEOUT "$newData 0 0 0\n";
    }
    
    close(FILE);
    close(FILEOUT);

}

sub NONMEM_convertParsedNONMEMOutputsToTypedLambdaCalculus
{
    my $fileOfAllResults = $_[0];

    my $currentModel = "";
    my $objectiveFunction = 0;
    my @parameterNames = ();
    my @thetaValues = ();
    my @etaValues   = ();
    my @sigmaValues = ();
    my @sigmaErrors = ();
    my @thetaErrors = ();
    my @etaErrors   = ();
    my @covrMatrix  = ();
    my @corrMatrix  = ();
    my @invMatrix   = ();

    open(FILEOFALLRESULTS,$fileOfAllResults ) or die ("Could not open file of all results\n");
    while(my $line = <FILEOFALLRESULTS>)
    {
        $line =~ s/\s+//g;
        my @parts = split(/,/,$line);
        
        my $model = $parts[0];
        $model =~ s/\.out//i;
        
        if ( $model ne $currentModel)
        {
            if ( $currentModel ne "" )
            {
                print "$model, Objective Function,=, $objectiveFunction\n";
                print "$model, Parameters,=,\"  \[ ", join(", ", @parameterNames) , "\]\"\n";
                print "$model, Fixed Effects,=,\"  \[ ", join(", ", @thetaValues), "\]\"\n";
                print "$model, Covariance Matrix for Random Effects - Etas,=,\"  \[ ", join(", ", @etaValues), "\]\"\n";
                print "$model, Sigmas,=,\"  \[ ", join(", ", @sigmaValues) , "\]\"\n";
                print "$model, Theta - Standard Errors for Estimates,=,\"  \[ ", join(", ", @thetaErrors), "\]\"\n";
                print "$model, Omega - Standard Errors for Random Effects,=,\"  \[ ", join(", ", @etaErrors), "\]\"\n";
                print "$model, Sigma - Covariance Matrix,=,\"  \[ ", join(", ", @sigmaErrors) , "\]\"\n";
                print "$model, Covariance Matrix for Random Effects,=,\"  \[ ", join(", ", @covrMatrix), "\]\"\n";
                print "$model, Correlation Matrix of Estimate,=,\"  \[ ", join(", ", @corrMatrix), "\]\"\n";
                print "$model, Inverse Covariance Matrix of Estimate,=,\"  \[ ", join(", ", @invMatrix), "\]\"\n";
            }
            
            $objectiveFunction = 0;
            @parameterNames = ();
            @thetaValues = ();
            @etaValues   = ();
            @sigmaValues = ();
            @sigmaErrors = ();
            @thetaErrors = ();
            @etaErrors   = ();
            @covrMatrix  = ();
            @corrMatrix  = ();
            @invMatrix   = ();
            
            $currentModel = $model;

        }
        
        my $outputType = $parts[1];
        my $token = $parts[2];
        my $runNumber = $parts[3];
        my $iLength = $parts[4];
        my @vector = @parts[5 .. $#parts];
        
        if ( $token eq "OBJ" )
        {
               $objectiveFunction = $vector[0];
        }
        if ( $token eq "PRED_LABELS" )
        {
               @parameterNames = @vector;
        }    
        if ( $token eq "THETA" )
        {
            if ( $outputType eq "1" )
            {
                @thetaValues = @vector;
            }
            else
            {
                @thetaErrors = @vector;
            }
            
        }
        if ( $token eq "OMEGA" )
        {
            if ( $outputType eq "2" )
            {
                @etaValues = @vector;
            }
            else
            {
                @etaErrors = @vector;
            }
        }
        if ( $token eq "SIGMA" )
        {
            if ( $outputType eq "1" )
            {
                @sigmaValues = @vector;
            }
            else
            {
                @sigmaErrors = @vector;
            }
        }
        if ( $token eq "COVR" )
        {
            @covrMatrix = @vector;
        }
        if ( $token eq "CORR" )
        {
            @corrMatrix = @vector;
        }
        if ( $token eq "CORR" )
        {
            @invMatrix = @vector;
        }


    }
}

sub NONMEM_doSetOfRuns
{

    my $oldSeparator = $/;
    $/ = "\n";

	my ($directoryWithControlFiles, $NONMEMRunDirectory, $targetDirectory ) = @_;
  
    if ( $improveThis )
    {
        `cd $directoryWithControlFiles`;
    }
    
    my @files = <*.ctl>;

    foreach my $file ( @files )
    {

	    open(INPUTFILE,"$file") or die("Could not open file name for input $file\n");
	    my @copy = <INPUTFILE>;
	    close(INPUTFILE);

	    my $dataFileName = "";
	    my $regularizedFilename = "";
	    foreach my $line ( @copy )
	    {
		    if ( $line =~ /^\$DATA/)
		    {
			    my @parts = split(/\s+/,$line);
			    $dataFileName = $parts[1];
			    $regularizedFilename = $dataFileName;
			    unless ( open(DATAFILE,$dataFileName))
			    {
				     unless ( open(DATAFILE,"../data/$dataFileName"))
				     {
                   	    my $regularizedFilename = PK_regularizeFileName($dataFileName,".data.txt");
        			    unless ( open(DATAFILE,"../data/$regularizedFilename"))
                        {
                            die("Could not open data file $dataFileName or $regularizedFilename for $file\n");
                        } 
                     }
                     
                    print "Copying file $NONMEMRunDirectory\\$regularizedFilename to $dataFileName\n";
                    my $ok = `copy /y \\oss\\data\\$regularizedFilename $dataFileName`;
                    
                    print $ok;
                    print "done\n";
			    }
    			
			    $/ = "\n";
    			
			    my @dataLines = <DATAFILE>;
			    close(DATAFILE);
    			
			    $dataLines[0] =~ s/^[\s]*[\#]*[\s]*//g;
			    my $header = $dataLines[0];
			    
			    unless ( $dataLines[0] =~ /\#/)
			    {
			        open(DATAFILE,">$dataFileName") or die("Could not open data file to write\n");
			        $dataLines[0] = "\# " . $dataLines[0];
			        print DATAFILE @dataLines;
			        #print DATAFILE "\n";
			        close(DATAFILE);
			    }
		    }
	    }
	    
	    my $generateInvalidModelToTestEngines = 0;
	    if ( $generateInvalidModelToTestEngines )
	    {
	        #This generated a bogus ( additive type ) model in order to see if the 
            #see if the engine can process it without hanging.
	        for ( my $i = 0; $i < scalar(@copy); $i++ )
	        {
	            if  ( $copy[$i] =~ /\*EXP/)
	            {
	                $copy[$i] =~ s/\*EXP/\+EXP/g;
	            }
	        }
	    }
	    open(INPUTFILE,">$file") or die("Could not open file name for input $file\n");
	    print INPUTFILE @copy;
	    close(INPUTFILE);

	    if ( $dataFileName eq "" )
	    {
		    print "Could not find input file for $file with contents\n@copy\n";
		    exit;	
	    }
    	
	    #print "Running $file\n";

	    #my $message = `nmfe6.bat $file $file.out > $file.log`;
	    print "nmfe6.bat $file $file.out > $file.log \n";

    }
    
    $/ = $oldSeparator;
}

sub NONMEM_getHypernormalizedVersionOfDatasets
{

    use Text::CSV::Simple;
    use integer;

    my ( $dataType, $extension ) = @_;
    
    my $iHeaderLine = 0;
    my $iTime = 2;
    my @files = <*.$extension>;
    my $runType = "NONMEM";

    if ( $dataType =~ "Input" )
    {
        $extension = "data";
        $dataType  = "Inputs";
        $iHeaderLine = 0;
        $iTime = 1;
        @files = <*.$extension>;
        $runType = "NONMEM";

    }

    my @headers = ();

    print "Study, Model, ModelType, RunType, ID, Field, Time, Value\n"; 

    foreach my $file ( @files )
    {
	    my @fields = split(/\_/,$file);

	    open(FILE,$file) or die("Could not open file\n");
    	
	    $file =~ s/\.$extension//ig;
	    my @data = <FILE>;

            for ( my $i = $iHeaderLine; $i < $iHeaderLine+1; $i++ )
	    {
		    my $line = $data[$i];
		    $line =~ s/\#|^\s+//g;
		    $line =~ s/\#|^\s+//g;

		    @headers = split(/\s+/,$line);
		    #print $file,",", join(",", @headers);
		    #print "\n";

	    }

        for ( my $i = $iHeaderLine+1; $i < scalar(@data); $i++ )
	    {
		    my $line = $data[$i];
		    $line =~ s/\#|^\s+//g;
		    $line =~ s/\#|^\s+//g;

		    my @items = split(/\s+/,$line);
		    for ( my $j = $iTime+1; $j < scalar(@items); $j++ )
		    {
			    my $iSubject = sprintf("%d",$items[0]);
			    my $time = sprintf("%10.2f",$items[$iTime]);
			    next if ( $items[$j] eq "." );
			    my $datum = sprintf("%f", $items[$j]);

			    print "$file, $file, $runType, $dataType, $iSubject, $headers[$j], $time, $datum\n";
		    }

	    }
    }
}

sub MONOLIX_installMatlabMFiles
{
    my ( $outputDirectory ) = $_[0];
    
    open ( MFILE, "$outputDirectory/parseMonolixDotMatFiles.m");
    
    print MFILE <<END_OF_MFILE;

function matFileNames = parseMonolixDotMatFiles(directory)

matFiles = dir

doseTypes = {'sd','md','ss'};

iDoseTypeFound = 0;
iDoseType = 1;
for iName = 1: length(matFiles)
    aName = matFiles(iName).name;
        doseType = doseTypes(iDoseType);
        if regexp(aName,'mexw3')
            ;
        elseif regexp(aName,'.mat')
            modelName = strrep(aName,'.mat','')
            my = load(aName);
            modelInfoFileName = strcat('c:/monolix/modelInfo/',modelName,'.data')
            fid = fopen(modelInfoFileName,'wt');
            if ( fid > 0 ) 
                fprintf(fid,'%s\n','-------------------------Data-----------------');
                fprintf(fid,'nb_param=%i\n', my.nb_param);
                fprintf(fid,'logstruct=%s\n',mat2str(my.logstruct));
                fprintf(fid,'nb_varex=%i\n',my.nb_varex);

                fprintf(fid,'desc=''%s''\n',my.desc);
                temp = joinStrings(my.phi_names)
                fprintf(fid,'phi_names=[%s]\n',strcat(temp)); 
                if isfield(my,'phi_tex')
                    fprintf(fid,'tex_names=[%s]\n',strcat(joinStrings(my.phi_tex)));
                end;
                if isfield(my,'tex_names')
                    fprintf(fid,'tex_names=[%s]\n',strcat(joinStrings(my.tex_names)));
                end;
                if isfield(my,'phi_names')
                    fprintf(fid,'phi_names=[%s]\n',strcat(joinStrings(my.phi_names)));  
                end;
                if isfield(my,'nb_outputs')
                    fprintf(fid,'nb_outputs=%i\n',my.nb_outputs);  
                end;

                fprintf(fid,'dose=%i\n',my.dose);
                fprintf(fid,'ode=%i\n',my.ode);
                fprintf(fid,'cat_model=%s\n',my.cat_model);
                fprintf(fid,'nb_ode=%i\n',my.nb_ode);
                
                fclose(fid);
            end;
      
        elseif regexp(aName,'.m')
            modelName = strrep(aName,'.m','')
            modelInfoFileName = strcat('c:/monolix/modelInfo/',modelName,'.txt')
            fid = fopen(modelInfoFileName,'wt');

            fid1 = fopen(aName);
            if ( fid > 0 && fid1 > 0 )
               fprintf(fid,'%s\n','-------------------------Model-----------------')
               %---------------------------------------------------------------------
               %Note on the coding here: I do the real splitting of models by dosing 
               %( sd, md, ss ) using PERL.  However, for the time being, I am keeping
               %this code here in case it is helpful to make use of later -- rph
               %---------------------------------------------------------------------
                while 1,
                    aCharacterString = fgetl(fid1);
                    if ferror(fid) ~= 0
                        break;
                    end;    
                    if aCharacterString == -1
                        break;
                    end
                    regExpPattern = strcat('if.*','''',doseType,''''); 
                    aString = strvcat(aCharacterString);
                    regFound = regexp(aString,regExpPattern);
                   if length(regFound ) > 0
                       iDoseTypeFound = iDoseType;
                        %continue;
                   end
                   elseFound = regexp(aString,'else');
                   if (length(elseFound)>0)
                       iDoseTypeFound = 3;
                       % continue;
                   end
                   %if ( iDoseTypeFound == iDoseType )
                        fprintf(fid,'%s',aString);
                        fprintf(fid,'\n');
                   %end
                end;
               fclose(fid1);
               fclose(fid);
            end;
           
        end;
    matFileNames = 'OK';
end

END_OF_MFILE

close(MFILE);

open(MFILE, "$outputDirectory/getAsciiVersionsOfAllDotMatFiles.m" ) or die("Could not open  file in M-file output directory\n");

print MFILE <<END_OF_MFILE1;

function [files] = getAsciiVersionsOfAllMonolixDotMatFiles

files = dir('*.mat');
mSizes = size(files);
msize = mSizes(1)*mSizes(2);

for i = 1:msize
    file = files(i);
    fileName = file.name;
    
    fileName
    
    myData = load(fileName)
    fileExport = strrep(fileName,'.mat','')
    fileExport = strcat(fileExport,'.csv')
    saveSAEMFields(fileName,fileExport)
   
end

END_OF_MFILE1

close(MFILE);

open(MFILE, "$outputDirectory/getMonolixDataStruct.m" ) or die("Could not open  file in M-file output directory\n");

print MFILE <<END_OF_MFILE2;

function [vData] = getMonolixDataStruct(arrayOfCells,fieldName,fieldType)

[rows, cols] = size(arrayOfCells);

iIndex = 0;
thisData = 0;

for i = 1:rows
    
    item = arrayOfCells(i,1);
    item1 = item{1};
    
    if ( ischar(item1))
        charItem = char(item1);
        if (strcmp(charItem,fieldName ) == 1)
            iIndex = i;
         end
    end   
 
end

if ( strcmp(fieldType,'char') == 1 )
    vData = getCharArray(arrayOfCells,iIndex);
else
    vData = getNumericArray(arrayOfCells,iIndex);
end

function [vData] = getNumericArray(arrayOfCells,iIndex)

vData = 0;

 if ( iIndex > 0 )
    thisArray = arrayOfCells(iIndex,1:4);
    thisData  = thisArray{1,4};

   if (iscellstr(thisData))

        myLength = numel(thisData);

        vData = 0;
        vData = zeros(1,myLength);
        for i = 1:myLength
             temp = char(thisData(i))
             vData(1,i) = str2num(temp)
        end
   elseif (iscell(thisData))

        myLength = numel(thisData);

        vData = 0;
        vData = zeros(1,myLength);
        for i = 1:myLength
            vData(i) = str2num(thisData{i});
        end
    else

        myLength = 1

        vData = 0;
        vData = zeros(1,myLength);
        for i = 1:myLength
            vData(i) = str2num(thisData);
        end
    end
 end
 
function [vData] = getCharArray(arrayOfCells,iIndex)

vData = 0;

 if ( iIndex > 0 )
    thisArray = arrayOfCells(iIndex,1:4);
    thisData  = thisArray{1,4};

     if (iscell(thisData))

         vData = thisData{1}
         cellData = textscan(vData,'%s','delimiter',',')
         vData = cellData{1}

     end
end

END_OF_MFILE2

open(MFILE, "$outputDirectory/getMonolixProjectInfo.m" ) or die("Could not open  file in M-file output directory\n");

print MFILE <<END_OF_MFILE3;

function [newArray] = getMonolixProjectInfo(fileName)

fid = fopen(fileName);
info = textscan(fid, '%q', 'delimiter', ',');
lines = info{1};
    
j = 1

lineSize = size(lines);
numLines = lineSize(1) * lineSize(2);
newArrayDim = lineSize/4+10;
newArray = cell(newArrayDim,4);

k = 0
for i = 1:numLines
    
    k = k + 1;
    if k > newArrayDim
        break
    end
    if j > numLines
        break
    end
    Fieldname = lines(j);
    Fieldname
    
    if class(Fieldname) ~= 'char'
        break
    end 
    if ( strcmp(Fieldname,''))
        k = k - 1;
        j = j + 2;
        continue
    end
 
    if isEOL(Fieldname)
        j = j + 1;
        continue
    end
  
    newArray(k,1) = Fieldname;
    
    FieldType = lines(j+1);
    
    if isEOL(FieldType)
        j = j + 1;
        continue
    end
    newArray(k,2) = FieldType;
    
    FieldLength = lines(j+2);
    
    if isEOL(FieldLength)
        j = j + 1;
        continue
    end
    newArray(k,3) = FieldLength;
    
    length = str2num(FieldLength{1});
    
    j = j + 3;
    
    if ( length == 1 )
        aString = lines(j);
        newArray(k,4) = aString;
    elseif (length > 1 )
        myArray = lines(j:(j+length-1));
        newArray(k,4) = {myArray};
    end
    
    j = j + length;
  
    if ( j > numLines)
        break
    end
    
    while ( j > 0 )
        aCell = lines(j);
        if isEOL(aCell)
            break;
        end
        j = j - 1;
    end
    
    j = j + 1;
    
end

newArray = newArray(1:k-1,1:4)

fclose(fid);

function [result] = isEOL(aCell)

    result = 0;

    if numel(aCell) > 0
        
        aString = aCell{1};

        if class(aString) == 'char'
            if strcmp(aString, 'EOL')
                result = 1;
            end
        end
    end
 
END_OF_MFILE3
 
}

sub MONOLIX_splitModelsAccordingToDosing
{

    my ( $inputDirectory, $outputDirectory ) = @_;
    
    opendir(RUNDIR,$inputDirectory) or die("Could not open input directory $inputDirectory\n");
    my @files = grep ( /\.m/i, readdir(RUNDIR));
    close(READDIR);
    my $dose = '';
    foreach my $file ( @files )
    {
        
        my $sd = '';
        my $md = '';
        my $ss = '';

        open(INPUT,"$inputDirectory/$file") or die("Could not open input file $file in $inputDirectory\n");

        while(<INPUT>)
        {

	        next if /^\%/g;
	        if (/.*if.*X\.type_dose.*\'sd\'.*/)
	        {
		        $dose = 'SD' ; next;
	        }

	        if (/.*elseif.*X.*type_dose.*\'md\'.*/)
	        {
		        $dose = 'MD'; next;
	        }
         
	        if (/.*if.*X\.type_dose.*\'ss\'|else\W.*/)
	        {
		        $dose = 'SS'; next;
	        } 

	        if (/^end\W/)
	        {
		        $dose = '';next;
	        } 
        	
	        $sd .= $_ if ( $dose eq 'SD' or $dose eq '' );
	        $md .= $_ if ( $dose eq 'MD' or $dose eq '');
	        $ss .= $_ if ( $dose eq 'SS' or $dose eq '');
        }
        
        $file =~ s/\.m//g;
        
        $file = uc( $file);
        
        open(FILE,">$outputDirectory/${file}_SD.M");
        print FILE $sd;
        close( FILE);

        open(FILE,">$outputDirectory/${file}_MD.M");
        print FILE $md;
        close(FILE);

        open(FILE,">$outputDirectory/${file}_SS.M");
        print FILE $ss; 
        close(FILE);
    }
}


#---------------------------------------------------------------------------
#Package Models


#-----------------Some variables for parsing -----------------------

    $improveThis = 1; #limitation of variables 1-9.

    $| = 1;	

    my @DATAAttributes = ("IGNORE");
    my @SUBROUTINEAttributes = ("TOL");
    my $state = "None";
    my $columnString = "";
    my %globalAST;
    my $globalASTRef = \%globalAST;

    my %derivationsForVariables;
    my $derivationsForVariablesRef;

    my %reverseDerivationsForVariables = ();

    my %IfThenExpressionsForVariables;
    my $IfThenExpressionsForVariablesRef;

    my %variablesWithNumericSuffixes ;
    my $variablesWithNumericSuffixesRef;
    my %variablesWithoutNumericSuffixes ;
    my $variablesWithoutNumericSuffixesRef;

    my %logitFunctions;
    my %inverseLogitFunctions;

    my $commentCharacter;
    my $patternForFileName;
    my $patternForDirectoryName;
    my $assignmentOperator;
    my $leftParens;
    my $rightParens;
    my $lineSeparator;

    my @arrayOfInfoAsSideEffectsYesThisIsBad = ();

    my $modelType = "";
    my $notFirstProblem = 0;

    my $runsDirectory;

    my $writeNonmem;
    my $writeMaple;
    my $writeAsAlgebraicTheory;
    my $writeWinbugs;
    my $useWinBugs;
    my $writeTLC;
    my $useMATLAB;

    my $outputFileHandle = "";
    my $logFileHandle = "";
    my $mapleFileHandle = "";
    my $printHandle = "";

    my $debug = 1;

    my 	$NONMEMSourceDirectory = '/oss/';
    my  $dataDirectory         = '/oss/data';
    my  $NONMEMDataFilesDirectory = 'c:/monolix/';

    #$patternForDirectoryName = "WINBUGS";
    #$patternForDirectoryName = "both";

    #$patternForFileName = ".*CTL";
    $runsDirectory = '/oss/runs';

    my  $monolixSourceDirectory = 'c:/monolix/monolix_V23_1/libraries';
    my  $monolixTargetDirectory = '/oss/monolixModels/';

#-----------------------------------------------------------------------

sub parseModelFile
{

    my $selfRef;
    ( $patternForFileName, $patternForDirectoryName, 
        $writeNonmem, $writeMaple, $writeAsAlgebraicTheory, $writeWinbugs, $writeTLC, 
        $useWinBugs, $useMATLAB ) = @_;
    
    if ( $useWinBugs )
    {
	    $commentCharacter = ";\#";
	    #$patternForFileName = "\.bugs";
	    #$patternForFileName = "model1\*";
	    $assignmentOperator = "\<\-|\~|=";
	    $leftParens = "\(";
	    $rightParens = "\)";
	    $lineSeparator = "\\n|;";
	    $modelType = "WinBUGS";
	    #$patternForDirectoryName = "";
	    $runsDirectory = 'c:/algebraic/algebraicNONMEM/winRuns';
    }
    elsif ( $useMATLAB )
    {
	    $commentCharacter = "%";
	    #$patternForFileName = "sd\.m";
	    #$patternForDirectoryName = ".";
	    $assignmentOperator = "=";
	    $leftParens = "\(";
	    $rightParens = "\)";
	    $lineSeparator = "\\n";
	    $modelType = "MATLAB";
	    $runsDirectory = 'runs';
	    $useWinBugs = 0;

    }
    else{
    
    	$/ = "\$";

	    $commentCharacter = ";";
	    $assignmentOperator = "=";
	    $leftParens = "\(";
	    $rightParens = "\)";
	    $lineSeparator = "\\n";
	    $modelType = "NONMEM";
	    $useWinBugs = 0;
    }

    #find(\&getNONMEMDataFiles,$NONMEMDataFilesDirectory,    $patternForFileName);
    find(\&getNONMEMControlFiles,$NONMEMSourceDirectory, $patternForFileName);
    #find(\&getMonolixModelFiles,$monolixSourceDirectory, $monolixTargetDirectory);

 }
 
 
 
 sub getRegularizedModelName
 {
    
    my $problemText = getSubTree($globalASTRef,"PROBLEM");
  
    my $modelName = $problemText;
    $modelName =~ s/ .*//g;
    #*Improve this* - should have dosing from data file...
    my $route = $problemText;
    $route =~ s/\_.*//g;
    if ( $route eq "ORAL" )
    {
        $route = "ORAL1";
    }
    
    my @modelParts = split(/\_/,$modelName);
    my $compartmentType = $modelParts[1];
    my $dosingType = $modelParts[$#modelParts];
    
    if ( $dosingType ne "SD" && $dosingType ne "MD" && $dosingType ne "SS" )
    {
        $dosingType = "SD";
    }

    my $PKVariableNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES_FROM_DEPENDENCIES");
    my @PKVariableNames    = @$PKVariableNamesRef;
    
    my $PKVariableNamesConcatenated = join("\.",@PKVariableNames);
    $PKVariableNamesConcatenated = PK_sortVariableNamesInDottedList($PKVariableNamesConcatenated);
    $globalASTRef = insertSubTree($globalASTRef,"PK_VARIABLE_NAMES_CONCATENATED",\$PKVariableNamesConcatenated);
    
    my $subroutineInfoRef = getSubTree($globalASTRef,"SUBROUTINE");
    my @subroutineInfo = @$subroutineInfoRef;
    if ( $subroutineInfo[0] eq "ADVAN1" or $subroutineInfo[1] eq "ADVAN2" )
    {
        $compartmentType = "1CPT"; 
    }
    elsif ($subroutineInfo[0] eq "ADVAN3" or $subroutineInfo[1] eq "ADVAN4" )
    {
        $compartmentType = "2CPT";
    }
    
    my $completeFileName = "${route}_${compartmentType}_${PKVariableNamesConcatenated}_${dosingType}";
 
    return $completeFileName;
    
}

sub insertFileContentsIntoAbstractSyntaxTree
{
    my ( $potentialFileNamesRef, $astRef, $token) = @_;
    
    my @potentialFileNames = @$potentialFileNamesRef;
    
    my $linesFound = 0;
    my $fileFound = open(INPUTFILE,$potentialFileNames[0]);
    if ( ! $fileFound )
    {
        $fileFound = open(INPUTFILE,$potentialFileNames[1]);
        if ( ! $fileFound )
        {
            print("Could not open file to insert into AST\n");
        }
    }
    
    if ( $fileFound )
    {
    	my $oldSeparator =  $/;
        $/ = "\n";
        
        my @lines = <INPUTFILE>;
      
        my $joinedLines = join("\n", @lines);
        my ( $parseTreeRef, $stateForParseDEQ ) = parseEquations($joinedLines,"OK");
        
        $/ = $oldSeparator;

        $astRef = insertSubTree($astRef,$token,$parseTreeRef,);
        $linesFound = scalar(@lines);
    }
 
    return($astRef);
    
}


sub copyFileToAlgebraicTheoryLines
{
    my ( $inputFileName, $AlgebraicTheoryHandle, $token) = @_;
    
    my $linesFound = 0;
    my $fileFound = open(INPUTFILE,$inputFileName);
       
    if ( $fileFound )
    {
        my $oldSeparator = $/;
    	$/ = "\n";

        my @lines = <INPUTFILE>;
        foreach my $line ( @lines )
        {
            chomp $line;
            next unless $line =~ /\w/;
            $line =~ s/\s+//g;
            my @parts = split(/=/,$line);
            
            my $relationalOp = "=";
            
            my $string = "$token,$parts[0],$relationalOp,$parts[1]";
            
            print $AlgebraicTheoryHandle Util_convertToLambdaExpression($string) . "\n";
        }
        
        close(INPUTFILE);
        $/ = $oldSeparator;

        $linesFound = scalar(@lines);
    }
    

    return ( $linesFound);
}


sub ParseMATLABMetadataAndModel
{
	my $inputFileHandle  =  $_[0];
	my $outputFileHandle    =  $_[1];
	my $logFileHandle		 = $_[2];
	my $TLCOutputFileName= $_[3];
	my $dataFileName      = $_[4];
	
	my @globalASTLines = <$inputFileHandle>;
	
	my @modelParts = split(/\%[\-]+\w+[\-]+/,$globalASTLines[0]);   
	my $treeRef = "";
	my %treeRefs = ();
	my $iTree = 1;
	
	foreach my $modelPart ( @modelParts )
	{
		next if $modelPart eq "";
		my ($treeRef, $state) = parseMATLABModel($modelPart,$outputFileHandle,$logFileHandle,$TLCOutputFileName,$dataFileName);
		$treeRefs{$iTree++} = $treeRef;
	}
	
	$improveThis = 1;
	unless ( $improveThis )
	{
		printResults($derivationsForVariablesRef, $inputFileHandle,$outputFileHandle,
			$logFileHandle,$TLCOutputFileName,$dataFileName,$useWinBugs,$useMATLAB);
	}	
	
	return ( \%treeRefs, $state );

}

sub parseMATLABModel
{
	my $modelPart  =  $_[0];
	$outputFileHandle    =  $_[1];
	$logFileHandle		 = $_[2];
	my $TLCOutputFileName= $_[3];
	my $dataFileName      = $_[4];
	
	my $i = 0;
	my $state = "NULL";

	my $parseRoutine = "parsePK";
	my $myTimes = 0;
	
	my $iLine = 1;
	
	$improveThis = 1; # just handle as a single line [ maybe?]
	my @globalASTLines = split(/\n/,$modelPart);

	my $reassembledModel = "";
	foreach my $line ( @globalASTLines )
	{
		$improveThis = 1;
		if ( $line =~ /\[/)
		{

			$line =~ s/\[\s*/bracket\(/g;
			$line =~ s/\s+/\,/g;
			$line =~ s/,\)/\)/g;
			$line =~ s/\s*\]/\)/g;
		}
		if ( $improveThis )
		{
			$line =~ s/\.\*/\*/g;
			$line =~ s/\.\//\//g;
			$line =~ s/([A-Za-z]+)\.([A-Za-z])+/$1_$2/g;
			$line =~ s/\:/colon/g;
		}
		$line =~ s/;//g;
		$line =~ s/\(\)/\(NULL\)/g;
		
		if ( $improveThis )
		{
			if ( $line =~ /function\s+/)
			{
			 	my @lineParts = split(/function/,$line);
			 	$line = "function=givenNext\n$lineParts[0] $lineParts[1]";
			
			}

		}
		
		$reassembledModel .= $line . "\n";
	}
	
	my $parseTreeRef = "";
	($parseTreeRef,$state) = parseEquations($reassembledModel);

	return($parseTreeRef,"OK");

}

sub ParseNONMEMFile
{
	my $inputFileHandle  =  $_[0];
	$outputFileHandle    =  $_[1];
	$logFileHandle		 = $_[2];
	my $TLCOutputFileName= $_[3];
	my $dataFileName      = $_[4];
	
	my $i = 0;
	my $state = "NULL";

	my %headerAbbreviations = 
	(
		"PROBLEM"	=> "PROBLEM",
		"PROB"	    => "PROBLEM",
		"COMMENT"	=> "COMMENT",
		"DATA"		=> "DATA",
		"INPUT"		=> "INPUT",
		"SUBR"      => "SUBROUTINE",
		"SUBROUTINE"=> "SUBROUTINE",
		"SUBROUTINES"=>"SUBROUTINE",
		"SUB"       => "SUBROUTINE",
		"MODEL"     => "MODEL",
		"PK"		=> "PK",
		"PRED"		=> "PRED",
		"DES"		=> "DES",
		"ERROR"		=> "ERROR",
		"THETA"		=> "THETA",
		"OMEGA"		=> "ETA",
		"SIGMA"		=> "SIGMA",
		"SCAT"		=> "SCAT",
		"EST"		=> "ESTIMATION",
		"ESTIMATION" => "ESTIMATION",
		"COVA"		=> "COVA",
		"COVR"		=> "COVA",
		"COV"		=> "COVA",
		"TAB"		=> "TABLE",
		"TABLE"		=> "TABLE",
		"model"		=> "WinBUGSModel",
		"list"		=> "ListStatement",
		"Dog"       	=> "Dog"

	);

	my %parseRoutines = 
	(
		"PROBLEM"	=> \&parsePROBLEM,
		"COMMENT"	=> \&parseCOMMENT,
		"DATA"		=> \&parseDATA,
		"INPUT"		=> \&parseINPUT,
		"SUBROUTINE"=> \&parseSUBROUTINE,
		"MODEL"     => \&parseMODEL,
		"PK"		=> \&parsePK,
		"PRED"		=> \&parsePRED,
		"DES"		=> \&parseDES,
		"ERROR"		=> \&parseERROR,
		"THETA"		=> \&parseTHETA,
		"ETA"		=> \&parseETA,
		"SIGMA"		=> \&parseSIGMA,
		"SCAT"		=> \&parseSCAT,
		"ESTIMATION" => \&parseEST,
		"COVA"		=> \&parseCOVA,
		"TABLE"		=> \&parseTAB,
		"model"		=> \&parseWinBUGSModel,
		"list"		=> \&parseListStatement,
		"Dog"       => \&parseDog

	);

	my %tokenAttributes = 
	(
		"DATA"	     => \@DATAAttributes,
		"SUBROUTINE" => \@SUBROUTINEAttributes,
		"SUB"        => \@SUBROUTINEAttributes
	);

	my $parseRoutine = "";
	my $myTimes = 0;
	
	my @globalASTLines = <$inputFileHandle>;

	my $lastChar = "";
	for ( my $i = 0; $i < scalar(@globalASTLines); $i++)
	{
	
		$_ = $globalASTLines[$i];
		
		print $logFileHandle $_;
		
		chomp;
		next unless /\w/;
		my $nextLastChar = substr($_,-1);
		
		my $ref = "NULL";
		my $state = "NULL";	

		my $keepSeparator = 1;
		my $headAndTailRef;
		( $headAndTailRef, $state) = parseHeadAndTail($_,"\\s+|\\(",$keepSeparator);
		my %headAndTail = %$headAndTailRef;
		
		$improveThis = 1; #Should map head to common head first.
		my $head = $headAndTail{"head"};
		my $tail = $headAndTail{"tail"};
		my $rightTree = $headAndTail{"right"};
		
		if ( $head eq "PROB" or $head eq "PROBLEM" )
		{
			if ( $notFirstProblem )
			{
			    $globalASTRef = \%globalAST;
				printResults($derivationsForVariablesRef, 
					$inputFileHandle,$printHandle,$logFileHandle,$TLCOutputFileName,$dataFileName,$useWinBugs,$useMATLAB);
				reinitStates();
			}
			$notFirstProblem = 1;

		}
		
		if ( $head eq "" )
		{
			print "Blank line or comment found, $_\n";
			next;
		}
		
		if ( $debug )
		{
			print $logFileHandle "\n----------------------\n",$head,"\n----------------------\n";
		}
		
		my $finalHead    = $headerAbbreviations{$head};
		my $parseRoutine = $parseRoutines{$finalHead};
		
		if ( $finalHead eq "" or $parseRoutine eq "" )
		{
			print "Error -- No such token $head\n";
			return;
		}
		$improveThis =1; #Use separate variable name here.
		$head = $finalHead;
		
		my $attributes   = $tokenAttributes{$head};
		
		($ref,$state) = $parseRoutine->($tail,$state,$attributes);
		
		if ( ref($ref) && $ref =~ /.*HASH.*/)
		{
			my %parseTreeForRef = %$ref;
			$rightTree = $parseTreeForRef{"right"};
		
			unless ( $rightTree eq "" )
			{
				$i--;
				$globalASTLines[$i] = $rightTree;
				$parseTreeForRef{"right"} = "";
				$ref = \%parseTreeForRef;
			}
		}
				
		if ( $lastChar eq ";" )
		{
			$globalAST{";" . $head} .= $ref;
		}
		else
		{
			$globalAST{$head} = $ref;
	    }
	    $lastChar = $nextLastChar;
	    
	    if ( $debug )
		{
		    my @myKeys = keys ( %$globalASTRef );
		    if ( scalar(@myKeys) > 0 )
		    {
		        foreach my $key ( @myKeys  )
		        {
		            print $key;
		            print ", ";
		        }
		        print "\n";
			    print $logFileHandle "----------------------------\n";
			    printTree(\%globalAST, 0,$logFileHandle,"");
			    print $logFileHandle "\n--------------------------\n";
			}
		}
		

	}

    $globalASTRef = \%globalAST;
  
	printResults($derivationsForVariablesRef, $inputFileHandle,$outputFileHandle,
		$logFileHandle,$TLCOutputFileName,$dataFileName,$useWinBugs,$useMATLAB);
}

sub derivativeFilter
{
	my $hashTreeRef  = $_[0];
	
	if ( $debug )
	{
		printTree($hashTreeRef,0,$logFileHandle,"");
	}
	
	if ( ! ref($hashTreeRef) || $hashTreeRef !~ /HASH/)
	{
		return 0;
	}

	my %hashTree = %$hashTreeRef;
	
	if ( $hashTree{"oper"} eq "func" && $hashTree{"fname"} eq "D" )
	{
		return(1);
	}
	return(0);

}

sub obtainDerivatives
{
	my $hashTreeRef  = $_[0];

	my @array = ();
	
	#Check pre-conditions
	if ( ref($hashTreeRef) && $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;
		my $hashTreeLeftRef = $hashTree{"left"};
		
		if ( ref($hashTreeLeftRef) && $hashTreeLeftRef =~ /HASH/)
		{
			my %hashTreeLeft = %$hashTreeLeftRef;
			if ( $hashTreeLeft{"oper"} eq "func" && $hashTreeLeft{"fname"} eq "D" )
			{
				$array[0] = $hashTreeRef;
			}
		}
	}
	return(\@array,"OK");

}

sub doReplacements
{
	my $parseTreeRef = $_[0];
	my $variableNamesRef = $_[1];
	my $aliasesRef;
	my $aliases1Ref;
	
	$improveThis = 1; #nparams should not be set.
	my $nParams = 10;
	
	my @variableNames = @$variableNamesRef;
	
	my %inverseMapOfParameters = ();
	my $inverseMapOfParametersRef = \%inverseMapOfParameters;
	foreach my $variableName ( @variableNames )
	{
	    my %tags = ( label => $variableName, startTag => $variableName, endTag => "\n", routine => \&obtainInverseHashOfValues, subRoutine => \&dummy);
	    ($inverseMapOfParametersRef,$state) = obtainInverseHashOfValues($derivationsForVariablesRef,\%tags, 0,\%inverseMapOfParameters );
	    %inverseMapOfParameters = %$inverseMapOfParametersRef; 
    }

    if ( 1 )
    {
        open(DOG,">>dog.txt");
        print DOG "000000000000000000000000000000000000000000000000000000000000000\n";
        printTree($inverseMapOfParametersRef,0,*DOG,"");
    }
    
    my $justModifyRHS = 1;
  # ($parseTreeRef,$state)  = modifyTree($parseTreeRef,\&checkForNames,\&replaceNamesUsingInverseMap,$inverseMapOfParametersRef,"",0,100,$justModifyRHS);
 
    if ( 0 )
    {
        printTree($parseTreeRef,0,*DOG,"");
        close(DOG);
    }
    
    my $mapToUseOfVectors = 0;

    if ( $mapToUseOfVectors )
    {
        my %inverseMap1OfParameters = ();

	    my $inverseMap1OfParametersRef = \%inverseMap1OfParameters;
	    foreach my $variableName ( @variableNames )
        {
	        ($inverseMap1OfParametersRef,$state ) = mapNamesToUseOfVectors($inverseMapOfParametersRef,$variableName,$nParams );
	        %inverseMap1OfParameters = %$inverseMap1OfParametersRef; 
	    }
     
 	    ($parseTreeRef,$state)  = modifyTree($parseTreeRef,\&checkForNames,\&replaceNames,$inverseMap1OfParametersRef,"",0,100,$justModifyRHS);

        if ( 0 )
        {
            open(DOG,">>dog.txt");
            print DOG "1111111111111111111111111111111111111111111111111111111111111111111\n";
            printTree($parseTreeRef,0,*DOG,"");
            close(DOG);
        }
    }
    
	return ( $parseTreeRef, $state );
}

sub doReplacementsForMaple
{
	my $parseTreeRef = $_[0];
	my $tag = $_[1];
	my $useJetNotation = $_[2];
	
	my $aliasesRef;
	my $aliases1Ref;
	
	my $nParams = 10;
	my %tags = ( label => $tag, startTag => $tag, endTag => "\n", routine => \&obtainInverseHashOfValuesForMaple, subRoutine => \&dummy);

    #Improve this -- I don't use it now...
	($aliasesRef,$state) = getInfoFromTree($derivationsForVariablesRef,\%tags,0);

	if ( $tag eq "DADT" )
	{
		if ( $useJetNotation )
		{
			($aliases1Ref,$state ) = mapNamesOfDifferentialsToUseOfJetNotation($aliasesRef,$tag,$nParams );
		}
		else
		{
			($aliases1Ref,$state ) = mapNamesOfDifferentialsToUseOfVectors($aliasesRef,$tag,$nParams );
		}
	}
	elsif ( $tag eq "A")
	{
		if ( $useJetNotation )
		{
			($aliases1Ref,$state ) = mapNamesToUseOfJetNotation($aliasesRef,$tag,$nParams );
		}
		else
		{

			($aliases1Ref,$state ) = mapNamesToUseOfMapleVectors($aliasesRef,$tag,$nParams );
		}
	}
	else
	{
		($aliases1Ref,$state ) = mapNamesToUseOfVectors($aliasesRef,$tag,$nParams );
	}
	
	($parseTreeRef,$state)  = modifyTree($parseTreeRef,\&checkForNames,\&replaceNames,$aliases1Ref,"",0,100,0);

	if ( $debug )
	{
		printTree($parseTreeRef,0,*STDOUT,"");
	}
	
	return ( $parseTreeRef, $state );
}

sub getHashValues
{
	my $hashTreeRef = $_[0];
	
	if ( ref($hashTreeRef ) && $hashTreeRef =~ /HASH/ )
	{
		return $hashTreeRef;
	}
	else
	{
		return "";
	}
}

sub getHashOfFunctions
{
	my $hashTreeRef = $_[0];
	my $tagsRef = $_[1];
	
	my %tags = %$tagsRef;
	my $startTag = $tags{"startTag"};
	my $endTag   = $tags{"endTag"};
	my $separator = $tags{"separator"};

	my $string = "";
	if ( ref($hashTreeRef ) && $hashTreeRef =~ /HASH/ )
	{
		$string = $startTag;

		my %hashTree = %$hashTreeRef;
		my $first = 1;
		foreach my $key ( keys( %hashTree))
		{
			$string .= $separator	unless ( $first );
			$string .= "$key = $hashTree{$key}";
			$first = 0;
		}
		
		$string .= $endTag;
	}
	
	return ( $string, "OK");
}

sub writeMonolixDataFile
{
	my $TLCOutputFileName   = $_[1];
	my $dataFileName         = $_[2];
	
	my %processingMethods = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getNonmemIfThenExpression,
			modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
			getForLoopExpression                 => \&getNonmemForLoopExpression,*
			assignmentOperator					 => " = "
		);
	
	my $NonmemFileName = $TLCOutputFileName;
	$NonmemFileName =~ s/\.TLC/\.MONOLIXEXTRA/ig;
	
	open(NonmemFILE,">>$NonmemFileName" ) or die("Could not open Nonmem file $NonmemFileName\n");
	my $NONMEMFileHandle = *NonmemFILE;
	$printHandle = $NONMEMFileHandle;
	
	my $variablesCountTreeRef = getSubTree($globalASTRef,"NB_COUNT");
	my %variablesCountTree = %$variablesCountTreeRef;
 
    print $printHandle "cat_model=","pk", "\n";
   
    my $problemText = getSubTree($globalASTRef,"PROBLEM");

    print $printHandle "desc=", "'", $problemText, "'", "\n";
    print $printHandle "dose=", 1,"\n";
 
    my $LHSPKDependenciesRef = getSubTree($globalASTRef,"LHS_DEPENDENCIES");
    my %LHSPKDependencies    = %$LHSPKDependenciesRef;

    my @logStruct = ();

    my $foundExponentiationAndMultiplication = 0;
    
    my $PKVariableNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES");
    my @PKVariableNames    = @$PKVariableNamesRef;
    
    foreach my $variableName ( @PKVariableNames )
    {
        my $VTreeRef =  $LHSPKDependencies{$variableName};
       
        if ( ref($VTreeRef) && $VTreeRef =~ /HASH/)
        {
            my %VTree   = %$VTreeRef;
            my $operatorsString = $VTree{"operators"};
            $foundExponentiationAndMultiplication = $operatorsString =~ /\^/ && $operatorsString =~ /\*/;
        }
        push(@logStruct,$foundExponentiationAndMultiplication);
       
    }
    
    print $printHandle  "logStruct=[", join(" ", @logStruct), "]\n";
    
    my $numDifferentialEquationsRef = getSubTree($globalASTRef,"NUM_DIFFERENTIAL_EQUATIONS");
    my $numDifferentialEquations = $$numDifferentialEquationsRef;
    
    print $printHandle  "nb_ode=", $numDifferentialEquations,"\n";
    print $printHandle  "nb_param=", $variablesCountTree{"length"},"\n";
    print $printHandle  "nb_varex=1\n";
    print $printHandle  "ode=", 0,"\n";
    print $printHandle  "phi_names=[", join(",", @PKVariableNames), "]\n";
    print $printHandle  "tex_names=[", join(",", @PKVariableNames), "]\n";
    
    my @xNames;
    my @yNames;
    
    push(@xNames,"time");
    push(@yNames,"concentration");
    print $printHandle  "r=[ ", join(",", @xNames), "]\n";
    print $printHandle  "y_names=[ ", join(",", @yNames), "]\n";
 
    close($printHandle);

}

sub getNumberOfParams
{
	my ( $hashOfAllArraysRef,$variableName) = @_;
	my %hashOfAllArrays = %$hashOfAllArraysRef;
	my $thisArrayRef    = $hashOfAllArrays{$variableName};
	
	my $iCount = 0;
	if ( ref($thisArrayRef) && $thisArrayRef =~ /ARRAY/)
	{
		my @array = @$thisArrayRef;
		$iCount = scalar(@array);
	}	
	
	return ( $iCount);
	
}
 
sub writeMonolixModel
{
	my $TLCOutputFileName   = $_[1];
	my $dataFileName         = $_[2];
	
	my %processingMethods = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getNonmemIfThenExpression,
			modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
			getForLoopExpression                 => \&getNonmemForLoopExpression,*
			assignmentOperator					 => " = "
		);
	
	my $NonmemFileName = $TLCOutputFileName;
	$NonmemFileName =~ s/\.TLC/\.MONOLIX/ig;
	
	open(NonmemFILE,">>$NonmemFileName" ) or die("Could not open Nonmem file $NonmemFileName\n");
	my $NONMEMFileHandle = *NonmemFILE;
	$printHandle = $NONMEMFileHandle;
	
	my $variablesCountTreeRef = getSubTree($globalASTRef,"NB_COUNT");
	my %variablesCountTree = %$variablesCountTreeRef;
   
    my $monolixFileName = getRegularizedModelName();
    my $fileRoot = "/oss/models/monolix/versionsSplitByDosing/";
    
    my $fileFound = 1;
    unless ( open(MONOLIX,"$fileRoot$monolixFileName.M"))
    {
         $fileFound = 0;
    }

   $NonmemFileName =~ s/.*both\_//g;
   $NonmemFileName =~ s/\.Monolix/\.CTL/ig;
   
   if ( $fileFound )
   {
        open(LOGSSHERE, ">>ErrorsFile.parseLog") or die("Could not open errors file\n");
        print LOGSSHERE "$monolixFileName $NonmemFileName\n";
        close(LOGSSHERE);
   }   
   else
   {
        open(ERRORSHERE, ">>ErrorsFile.err") or die("Could not open errors file\n");
        my $varNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES_ORIGINAL");
        my @varNames = @$varNamesRef;
        print ERRORSHERE "$monolixFileName $NonmemFileName", join(",",@varNames), "\n";
        close(ERRORSHERE);


   }

    if ( $fileFound )
    {
        my @monolixLines = <MONOLIX>;
        print $printHandle @monolixLines;
    }
    
    close($printHandle);

}


sub printResults
{
	my ( $derivationsForVariablesRef, $inputFileHandle, $outputFileHandle, 
		$logFileHandle, $TLCOutputFileName, $dataFileName, $useWinBugs,$useMATLAB ) = @_;
	
	$improveThis = 1;
	
	my $derivativesRef = "";
	
	#Improve this;
	my $nameOfModelAccordingToFile = $TLCOutputFileName;
    $nameOfModelAccordingToFile =~ s/\.*\///g;
    $nameOfModelAccordingToFile =~ s/\.*\\//g;

	$nameOfModelAccordingToFile =~ s/\.[a-zA-Z]+$//i;
	#Improve this -- remove the preliminary "Study" name that goes with this model.
	$nameOfModelAccordingToFile =~ s/.*both\_//i;
	$globalASTRef = insertSubTree($globalASTRef,"MODEL_NAME_FROM_FILE",\$nameOfModelAccordingToFile);
	
	if ( $modelType eq "WinBUGS")
	{
	
		my @subTreeNames = ("list", "middle", "left", "right");
		my %tags = ( label  => "MODEL ", startTag => "", endTag  => "\n", separator => "\n", routine => \&getSingleString,subRoutine => \&dummy );
		my $arrayOfSubstitionsRef;
		( $arrayOfSubstitionsRef, $state ) = getArrayOfInfoFromSubTree($globalASTRef,\@subTreeNames,\%tags,0);
		my @arrayOfSubstitions = @$arrayOfSubstitionsRef;
		my $substitutionsRef = $arrayOfSubstitions[0];
		
		my @names = ( "model");
		($globalASTRef,$state)  = modifySubTree($globalASTRef,\@names,\&checkForNames,\&replaceNames,$substitutionsRef,"",0,100,0);
		
		my %processingMethods = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getNonmemIfThenExpression 
		);
		
		my $problem = ";\#	PBPK system equations specified via BUGS language";
		$globalASTRef = insertSubTree($globalASTRef,"PROBLEM", \$problem);

		my $variableName = "C";
		my $newVariableName = "A";
		($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForUseOfVector,\&renameFunction,$variableName,$newVariableName,0,100,0);

		my @variableNames = ("A","KI","KO","V");
		for my $variableName (@variableNames )
		{
			($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForUseOfVector,\&replaceUseOfFunctionWithScalar,$variableName,"",0,100,0);
		}
	
		%tags = ( label  => "Derivatives ", startTag => "\$MODEL\n", endTag  => "\n", separator => "\n", routine => \&obtainDerivatives,subRoutine => \&dummy );
		my $arrayOfDerivativesRef;
		( $arrayOfDerivativesRef, $state ) = getArrayOfInfoFromSubTree($globalASTRef,"model",\%tags,0);

		%tags = ( label  => "DerivativesHash", startTag => "", separator => "", endTag  => "",routine => \&getHashTreeOfDifferentialEquation, getLeftRightOrBothSides => 'Both', ignoreDifferentialEquations => 0, processingMethods => \%processingMethods, subRoutine => "" );
		my $winBugsEquationsRef;
		( $winBugsEquationsRef, $state ) = getArrayOfInfoFromTree($arrayOfDerivativesRef,\%tags,0);

		%tags = ( label  => "NonDerivativesHash", startTag => "\$PK\n", endTag  => "\n", separator => "\n", routine => \&getHashTreeOfDifferentialEquation, ignoreDifferentialEquations => 2, subRoutine => \&dummy );
		my $arrayOfNonDerivativesRef;
		( $arrayOfNonDerivativesRef, $state ) = getArrayOfInfoFromTree($globalASTRef,\%tags,0);

		my @treeAddress = ("DES");
		$globalASTRef = insertSubTree($globalASTRef,\@treeAddress,$winBugsEquationsRef);

		@treeAddress = ("PK");
		$globalASTRef = insertSubTree($globalASTRef,\@treeAddress,$arrayOfNonDerivativesRef);

	}
	else
	{

		my @variableNames = ("THETA","ETA","A","ERR","DADT");
	
		for my $variableName (@variableNames )
		{
			($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForUseOfVector,\&replaceUseOfVectorWithScalar,$variableName,"",0,100,0);
		}

		my %arrayOfAllBounds = ();
		
		my @arrayOfThetaBounds = ();
		my %tags = ( label  => "THETA", startTag => "\$THETA\n	", separator =>"\n	", endTag  => "\n", routine => \&fillInArrayOfValuesInParentheses, subRoutine => \&getThetaBoundsAsValues );
		( $arrayOfAllBounds{"THETA"}, $state ) = fillInArrayOfInfoFromSubTree($globalASTRef,"THETA",\%tags,\@arrayOfThetaBounds,0);
		
		my @arrayOfOmegaBounds = ();
		%tags = ( label  => "ETA", startTag => "\$OMEGA ", separator =>" ", endTag  => "\n", routine => \&fillInArrayOfValuesInParentheses, subRoutine => \&getOmegaBoundsAsValues );
		( $arrayOfAllBounds{"ETA"}, $state ) = fillInArrayOfInfoFromSubTree($globalASTRef,"ETA",\%tags,\@arrayOfOmegaBounds,0);
		
		my @arrayOfSigmaBounds = ();
		%tags = ( label  => "SIGMA", startTag => "\$SIGMA ", separator =>" ", endTag  => "\n",routine => \&fillInArrayOfValuesInParentheses, subRoutine => \&getOmegaBoundsAsValues );
		( $arrayOfAllBounds{"SIGMA"}, $state ) = fillInArrayOfInfoFromSubTree($globalASTRef,"ERROR",\%tags,\@arrayOfSigmaBounds,0);

		$globalASTRef = insertSubTree($globalASTRef,"THETA_BOUNDS",\%arrayOfAllBounds);
		
		@variableNames = ("THETA","ETA","A","ERR");
	
		my %allExponentialDependencies;
		 
		for my $variableName (@variableNames )
		{
			
			my $iNumberOfParams = getNumberOfParams(\%arrayOfAllBounds,$variableName);
			
			for my $subTreeName ( "PK") #, "PRED", "DES")
			{
				my $subTree = getSubTree($globalASTRef,$subTreeName);
		    	traverseTreeForVectorItemDependencies($subTree,$variableName,0);
				
			}
			($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForUseOfVector,\&replaceUseOfVectorWithScalar,$variableName,"",0,100,0);

			for ( my $iNumber = 1; $iNumber <= $iNumberOfParams; $iNumber++ )
			{
				my %tags = ( label  => "ParameterDependencies", startTag => "\$exponentialDependencies\n", endTag  => "\n", separator => "\n", routine => \&checkForUseOfFunctionAndVariable, nameOfFunction => "exp", nameOfVariable => $variableName . $iNumber, subRoutine => \&dummy );
				my( $exponentialDependenciesRef, $state ) = getArrayOfInfoFromTree($globalASTRef,\%tags,0);
				$allExponentialDependencies{$variableName . $iNumber} = $exponentialDependenciesRef;
			}
		}
   
	 	$globalASTRef = insertSubTree($globalASTRef,"VECTOR_VARIABLE_DEPENDENCIES",$derivationsForVariablesRef);

        if ( 0 )
        {
		    open(DOG,">>dog.txt" );
    		
		    printSubTree($globalASTRef,"PK",0,*DOG);
	        printSubTree($globalASTRef,"DES",0,*DOG);

		    printTree($derivationsForVariablesRef,0,*DOG,"");
		    close(DOG);
		}
		
		$globalASTRef = insertSubTree($globalASTRef,"EXPONENTIAL_DEPENDENCIES",\%allExponentialDependencies);
	    
   
		my %processingMethodsForStateVariables = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getNonmemIfThenExpression,
			modifyDifferentialExpression		 => \&adaptDifferentialExpressionForStateVariable,
			assignmentOperator                   => " = "
		);

		my $stateVariablesRef = "";
		
		if ( doesSubTreeExist($globalASTRef,"DES") )
		{
			%tags = ( label  => "DES", startTag => "", separator => ",", endTag  => "", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
			( $stateVariablesRef, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
		}
		else
		{
			my $subroutineSubTreeRef = getSubTree($globalASTRef,"SUBROUTINE");
			if ( ref($subroutineSubTreeRef) && $subroutineSubTreeRef =~ /ARRAY/ )
			{
				my @subroutines = @$subroutineSubTreeRef;
				my $modelType = $subroutines[0];
				my $parameterization = $subroutines[1];
				my $equations = "";
				my $stateVariables = "";
				if ( $modelType eq "ADVAN1" )
				{
					if ( $parameterization eq "TRANS1" )
					{
						$equations = "DADT(1) = -K*A(1)\n";
					}
					elsif ( $parameterization eq "TRANS2" )
					{
							$equations = "DADT(1) = -(CL/V)*A(1)\n";
					}
					$stateVariables = "A1";
				}
				if ( $modelType eq "ADVAN2"  )
				{
					$stateVariables = "A1";
				}

			    if ( $modelType eq "ADVAN3" or $modelType eq "ADVAN4" )
				{
					$stateVariables = "A1,A2";
				}

				my $DESRef;
			    ( $DESRef, $state ) = parseDES($equations);
				$globalASTRef = insertSubTree($globalASTRef,"DES",$DESRef);
				$stateVariablesRef = \$stateVariables;
			}
		}
			
		$globalASTRef = insertSubTree($globalASTRef,"PK_STATE_VARIABLES",$stateVariablesRef);
		
		my $priorsStringForThetas = constructPriorsForThetas(\%arrayOfAllBounds,\%allExponentialDependencies);
		$globalASTRef = insertSubTree($globalASTRef,"PRIORS",\$priorsStringForThetas);

		my @priorsStringsForEtas = constructPriorsForEtas(\%arrayOfAllBounds,\%allExponentialDependencies);
		$globalASTRef = insertSubTree($globalASTRef,"PRIORSForEtas",\@priorsStringsForEtas);
		
		#($globalASTRef,$state)  = modifyTree($globalASTRef,,\&identityFunction,"exp","ETA1",0,100,0);

		$stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
		
		$globalASTRef = copySubTree($globalASTRef,"PK","PKScaleFactors");
		$globalASTRef = modifySubTree($globalASTRef,"PKScaleFactors",\&checkForLHSVariableAbsent,\&deleteIfLHSVariableAbsent,"S\\d");
		
		%tags = ( label  => "PKScaleFactors", startTag => "", separator => ",", endTag  => "", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
		my $pkScaleFactorsRef;
		( $pkScaleFactorsRef, $state ) = getInfoFromSubTree($globalASTRef,"PKScaleFactors",\%tags,0);
		$globalASTRef = insertSubTree($globalASTRef,"PK_SCALE_FACTORS",$pkScaleFactorsRef);
		
		my $observationFunctionsRef = constructObservationFunctions($stateVariablesRef,$pkScaleFactorsRef);
		
		$globalASTRef = insertSubTree($globalASTRef,"OBSERVATION_FUNCTIONS",$observationFunctionsRef);
		
#		for my $variableName (@variableNames )
#		{
#			($globalASTRef,$state)  = doReplacements($globalASTRef,$variableName);
#		}
		 
		 my %processingMethods;
	 
		 if ( $useWinBugs )
		 {
			 %processingMethods = (
				getLanguageSpecificVersionOfVariable => \&getWinbugsVersionOfVariable,
				getIfThenExpression                  => \&getWinbugsIfThenExpression 
			);
		}
		else
		{
			 %processingMethods = (
				getLanguageSpecificVersionOfVariable => \&getMapleVersionOfVariable,
				getIfThenExpression                  => \&getMapleIfThenExpression 
			);
		}

		($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForTautology,\&deleteTautology,"","",0,100,0);
		($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForIFStatement,\&consolidateAsIfThenExpression,"","",0,100,0);
	
		 my @analysisNames = ("PRED", "DES","PK");
		 for my $aName ( @analysisNames )
		 {
			($globalASTRef,$state)  = modifySubTree($globalASTRef,$aName, \&checkForArray,\&analyzeLHSVariables,\%processingMethods,"",0,100,0);
			#($globalASTRef,$state)  = modifySubTree($globalASTRef,$aName,\&checkForVariable,\&analyzeVariable,"","",0,100,0);
		 }
		 
		($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForArrayWithOneElement,\&deleteUseOfArrayWithOneElement,"","",0,100,0);

		if ( $debug )
		{
			printTree($globalASTRef,0,$logFileHandle,"");
		}
	}
	
	if ( $debug )
	{
		print $logFileHandle "\n-----------------------------------------------------\n";
		print $logFileHandle "Additional derived information\n"; 
	}
	
	if ( 0 )
	{
		my %completeParseTree = %$globalASTRef;
		my $PREDTreeRef = $completeParseTree{"PRED"};
		modifyTree($PREDTreeRef,\&checkForAssignment,\&storeAssignment,"","",0,100,1);
		($PREDTreeRef,$state)  = modifyTree($PREDTreeRef,\&checkForNames,\&replaceNameWithParseTree,$derivationsForVariablesRef,"",0,100,1);
		$completeParseTree{"PRED"} = $PREDTreeRef;
		$globalASTRef = \%completeParseTree;
	}
	
	my $CATEGORICAL_VARIABLES = determineCATEGORICAL_VARIABLES( $globalASTRef );
	$globalASTRef = insertSubTree($globalASTRef,"CATEGORICAL_VARIABLES", \$CATEGORICAL_VARIABLES);

	my $priorsForThetasAsString = getPriorsForThetasAsString( $globalASTRef );
	$globalASTRef = insertSubTree($globalASTRef,"PRIORSFORTHETAS", \$priorsForThetasAsString);

	if ( $writeWinbugs )
	{
		writeWinbugsOut( $globalASTRef, $TLCOutputFileName );
	}
	
	my %processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getNonmemIfThenExpression,
		modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
		assignmentOperator					 => " = "
	);	

	if ( $writeNonmem )
	{
	
        my %processingMethodsForDependencies = (
            getLanguageSpecificVersionOfVariable => \&getLanguageIndependentVersionOfVariable,
            getIfThenExpression                  => \&getNonmemIfThenExpression,
            modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
            assignmentOperator					 => " = "
        );	
	
		my $useJetNotation = 0;
		
		#Hack/question: should I handle ERR1 and A at this time as well?
		my @variableNames = ("THETA","ETA");

        my $PKTreeRef = getSubTree($globalASTRef,"PK");
        @arrayOfInfoAsSideEffectsYesThisIsBad = ();
		($PKTreeRef,$state)  = doReplacements($PKTreeRef,\@variableNames,$useJetNotation);
 
 		$globalASTRef = insertSubTree($globalASTRef,"PK",$PKTreeRef);
        
        if ( 0 )
        {
            my $desRef = getSubTree($globalASTRef,"DES");
		    ($desRef,$state)  = doReplacements($desRef,\@variableNames,$useJetNotation);
		    $globalASTRef = insertSubTree($globalASTRef,"DES",$desRef);
        }
        
        my %LHSDependencies = ();
	    my %tags = ( label => "PK", startTag => "", endTag => "\n", processingMethods => \%processingMethodsForDependencies, routine => \&getLHSDependencies, subRoutine => \&dummy);
		$PKTreeRef = getSubTree($globalASTRef,"PK");
		my $dependenciesOnVectorsRef;
		($dependenciesOnVectorsRef,$state) = getHashOfInfoFromTree($PKTreeRef,\%tags, 0, \%LHSDependencies );
 
	    $globalASTRef = insertSubTree($globalASTRef,"LHS_DEPENDENCIES",$dependenciesOnVectorsRef);
	    @arrayOfInfoAsSideEffectsYesThisIsBad = ();
	   	($PKTreeRef,$state)  = modifyTree($PKTreeRef,\&checkForNamesUsingOddRules,\&replacePKNamesUsingOddRules,$dependenciesOnVectorsRef,"",0,100,1);
        foreach my $variableToDelete ( @arrayOfInfoAsSideEffectsYesThisIsBad )
        {
    		($PKTreeRef,$state) = modifyTree($PKTreeRef,\&checkForLHSVariableAbsent,\&deleteIfLHSVariablePresent,$variableToDelete,"",0,100);
        }

       	$globalASTRef = insertSubTree($globalASTRef,"PK",$PKTreeRef);

        my %DESLHSDependencies = ();
        my $DESTreeRef = getSubTree($globalASTRef,"DES");
		%tags = ( label => "DES", startTag => "", endTag => "\n", processingMethods => \%processingMethodsForDependencies, routine => \&getLHSDependencies, subRoutine => \&dummy);
		my ($DESdependenciesRef,$state) = getHashOfInfoFromTree($DESTreeRef,\%tags, 0, \%DESLHSDependencies );
	    $globalASTRef = insertSubTree($globalASTRef,"DES_LHS_DEPENDENCIES",$DESdependenciesRef);
	    
	   	%tags = ( label => "DES", startTag => "", endTag => "\n", processingMethods => \%processingMethodsForDependencies, routine => \&getFullRHSForVariable, subRoutine => \&dummy);
		my $DESExpandedTreeRef = getSubTree($globalASTRef,"DES");
	
	   	($DESExpandedTreeRef,$state)  = modifyTree($DESExpandedTreeRef,\&checkForNames,\&replaceNamesAndStoreThoseUsed,$dependenciesOnVectorsRef,"",0,100,0);
       	$globalASTRef = insertSubTree($globalASTRef,"PK",$PKTreeRef);
 
		($PKTreeRef,$state) = modifyTree($DESExpandedTreeRef,\&checkForLHSVariableAbsent,\&deleteIfLHSVariableAbsent,"DADT","",0,100);
        $globalASTRef = insertSubTree($globalASTRef,"JUST_DIFFERENTIAL_EQUATIONS",$DESExpandedTreeRef);
		
		my $numDifferentialEquations = 0;
		if ( ref($DESExpandedTreeRef) && $DESExpandedTreeRef =~ /HASH/)
		{
		    my %DESExpandedTree = %$DESExpandedTreeRef;
		    $numDifferentialEquations = scalar(keys(%DESExpandedTree));
		}
		elsif ( ref($DESExpandedTreeRef) && $DESExpandedTreeRef =~ /ARRAY/)
		{
		    my @DESEquations = @$DESExpandedTreeRef;
		    $numDifferentialEquations = scalar(@DESEquations);
		}
		$globalASTRef = insertSubTree($globalASTRef,"NUM_DIFFERENTIAL_EQUATIONS",\$numDifferentialEquations);

		my $mapleFileName = $TLCOutputFileName;
		
		$improveThis = 1;
		#Not sure when to do this,actually
		if ( $improveThis )
		{
			$globalASTRef = copySubTree($globalASTRef,"PRED","PK");
		}
		
	    #%tags = ( label  => "PKScaleFactors", startTag => "", separator => ",", endTag  => "", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
		#my ( $pkScaleFactorsRef, $state ) = getInfoFromSubTree($globalASTRef,"PKScaleFactors",\%tags,0);
     
	    my $derivationsRef = getSubTree($globalASTRef,"VECTOR_VARIABLE_DEPENDENCIES");
        
        my $useThetas = 0; 
        my $useEtas = 1;
        my @PKVariableNames = ();
        if ( $useThetas )
        {
            my $subTreeForThetaRef     = getSubTree($derivationsRef,"THETA");
            my %subTreeForTheta        = %$subTreeForThetaRef;
            foreach my $key ( keys(%subTreeForTheta ))
            {
                my $value = $subTreeForTheta{$key};
                push(@PKVariableNames,$value);
            }
	    }
	    
	    if ( $useEtas )
	    {
	        my $subTreeForEtaRef     = getSubTree($derivationsRef,"ETA");
	        my %subTreeForEta        = %$subTreeForEtaRef;
	        foreach my $key ( keys(%subTreeForEta ))
	        {
	            my $value = $subTreeForEta{$key};
	            push(@PKVariableNames,$value);
	        }
        }
        
	    $globalASTRef = insertSubTree($globalASTRef,"PK_VARIABLE_NAMES_ORIGINAL",\@PKVariableNames);
	    
	    @PKVariableNames = PK_sortVariableNames(@PKVariableNames);
	    $globalASTRef = insertSubTree($globalASTRef,"PK_VARIABLE_NAMES",\@PKVariableNames);
	    
	    my $variablesCount = scalar(@PKVariableNames);
	    my %variablesCountTree = ();
        $variablesCountTree{length} = $variablesCount;
        $globalASTRef = insertSubTree($globalASTRef,"NB_COUNT",\%variablesCountTree);
 
        #improve this
 	    my $arrayOfPKNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES_ORIGINAL");
        my $defaultPrefix = 'tv';
        my $vectorVariableDependenciesRef = getSubTree($globalASTRef,"VECTOR_VARIABLE_DEPENDENCIES");
        my $PKNamesForThetasRef = getPKVariableNamesFromDependencies($vectorVariableDependenciesRef, "THETA", $arrayOfPKNamesRef, $defaultPrefix );
        $globalASTRef = insertSubTree($globalASTRef,"PK_VARIABLE_NAMES_FROM_DEPENDENCIES",$PKNamesForThetasRef);

        my $DESFileName = getRegularizedModelName();
        $globalASTRef = insertSubTree($globalASTRef,"REGULARIZED_MODEL_NAME",\$DESFileName);
        my $routing = $DESFileName;
        my $dosing  = $DESFileName;
        $dosing =~ s/.*\_//g;
        $routing =~ s/\_.*//g;
        $globalASTRef = insertSubTree($globalASTRef,"ROUTING",\$routing);
        $globalASTRef = insertSubTree($globalASTRef,"DOSING",\$dosing);

        $routing =~ s/.*\_//g;
        $globalASTRef = insertSubTree($globalASTRef,"ROUTING",\$routing);
        
        my $fileRoot = "\\oss\\models\\DifferentialEquations\\";
        my $DESModelNameFromFileRef = getSubTree($globalASTRef,"MODEL_NAME_FROM_FILE");
        my $DESModelNameFromFile = $$DESModelNameFromFileRef;
        
        my @potentialFileNames = ("$fileRoot$DESFileName.DES","$fileRoot$DESModelNameFromFile.DES");
        $globalASTRef = insertFileContentsIntoAbstractSyntaxTree(\@potentialFileNames,$globalASTRef,"DESMASTER","");

        writeMonolixModel($globalASTRef,$TLCOutputFileName,$dataFileName);     
        writeMonolixDataFile($globalASTRef,$TLCOutputFileName,$dataFileName);
   		
   		writeNonmemFile($globalASTRef,$TLCOutputFileName,$dataFileName);

	    $improveThis = 1; # should be separate from nonmem file.
		
		if ( $writeAsAlgebraicTheory )
		{
			writeAsAlgebraicTheory($globalASTRef,$TLCOutputFileName,$dataFileName);
		}
	}
	if ( $writeMaple )
	{
	
		my @variableNames = ("THETA","ETA","A","ERR","DADT");
	
		for my $variableName (@variableNames )
		{
			($globalASTRef,$state)  = modifyTree($globalASTRef,\&checkForUseOfVector,\&replaceUseOfVectorWithScalar,$variableName,"",0,100,0);
		}

		$globalASTRef = modifySubTree($globalASTRef,"DES",\&checkForAssignment,\&storeAssignment,"",0,100,0);
	
		$globalASTRef = modifySubTree($globalASTRef,"DES",\&checkForNames,&replaceNameWithParseTree,$derivationsForVariablesRef,"",0,100,0);
	
		my $useJetNotation = 0;
		for my $variableName (@variableNames )
		{
			($globalASTRef,$state)  = doReplacementsForMaple($globalASTRef,$variableName,$useJetNotation);
		}

		$globalASTRef = modifySubTree($globalASTRef,"DES",\&checkForLHSVariableAbsent,\&deleteIfLHSVariableAbsent,"diff");

		my $mapleFileName = $TLCOutputFileName;
		
		writeMapleFile($globalASTRef,$TLCOutputFileName,$dataFileName);

	}
	
	if ( $writeTLC )
	{
	    my $infoString;
	    my $state;
	    
		( $infoString, $state ) = getInfoFromTree($globalASTRef,"PROB",0, "PROBLEM", \&reportProblemTLC,"");
		( $infoString, $state ) = getInfoFromTree($globalASTRef,"THETA",0, "THETA",  \&reportHashOfArrayOfValuesInParentheses,\&reportThetaBounds,\&dummy);
		( $infoString, $state ) = getInfoFromTree($globalASTRef,"THETA",0, "THETA",  \&reportHashOfArrayOfValuesInParentheses,\&reportThetaInitialValues);
		( $infoString, $state ) = getInfoFromTree($globalASTRef,"OMEGA",0, "OMEGA",  \&reportHashOfArrayOfValues,\&reportOmegaInitialValues);
		( $infoString, $state ) = getInfoFromTree($globalASTRef,"SIGMA",0, "ERRORS", \&reportHashOfArrayOfValues,\&reportOmegaInitialValues);
		my $DESTempRef = getSubTree($globalASTRef,"DES");

		($DESTempRef,$state)  = modifyTree($DESTempRef,\&reportDifferentialEquations,\&indentityTransform,"A","",0,100,0);

		#For outputs...
		( $infoString, $state ) = getInfoFromTree($derivationsForVariablesRef,"THETA",0, "ThetaNames", \&reportHashOfValues, \&dummy);
		( $infoString, $state ) = getInfoFromTree($derivationsForVariablesRef,"ETA",  0, "EtaNames",   \&reportHashOfValues, \&dummy);
		( $infoString, $state ) = getInfoFromTree($derivationsForVariablesRef,"ERR",  0, "ErrNames",   \&reportHashOfValues, \&dummy);
		( $infoString, $state ) = getInfoFromTree($derivationsForVariablesRef,"ERR",  0, "ErrNames",   \&reportHashOfValues, \&dummy);
		( $infoString, $state ) = getInfoFromTree($derivationsForVariablesRef,"THETA",0, "ThetaNames", \&reportHashOfValues, \&dummy);

	}

}

sub MAPLE_getInitialConditionsString
{
    my ($differentialEquationsRef, $iDosingCompartment, $dosingType, $routingType ) = @_;
    my @differentialEquations = @$differentialEquationsRef;
    
    my $initialConditionsString = "";
    
    $initialConditionsString .= "ics:=[	";

    my $iEquation = 1;
    for ( my $i = 0; $i < scalar(@differentialEquations); $i++)
    {
        my $equation = $differentialEquations[$i];
        next unless ( $equation =~ /diff/i );

        my $datum = 0;
        if ( $iEquation eq $iDosingCompartment && $dosingType ne "MD" && $routingType ne "INFUSION" )
        {
            $datum = "AMT";
        }
        if ( $iEquation == 1 )
        {
	            $initialConditionsString .= " A$iEquation(0)	 = $datum\n";
        }
        else
        {
            $initialConditionsString .= "     ,A$iEquation(0) = $datum\n";
        }
        $iEquation++;
    }
    $initialConditionsString .= "];";
    
    return $initialConditionsString;
    
}


	
sub modifySubTree
{

	my $treeRef				= $_[0];
	my $subTreeName         = $_[1];
	my $filterFunctionRef	= $_[2];
	my $functionRef			= $_[3];
	my $char1				= $_[4];
	my $char2				= $_[5];
	my $iTreeLevel			= $_[6];
	my $iTotalLevels        = $_[7];
	my $justModifyRightSide = $_[8];

	my $subTreeRef = getSubTree($treeRef,$subTreeName);
	if ( &$filterFunctionRef($subTreeRef,$char1,$char2))
	{
		($subTreeRef,$state) = &$functionRef($subTreeRef,$char1,$char2);
	}

	($subTreeRef, $state ) = modifyTree($subTreeRef, $filterFunctionRef, $functionRef,$char1,$char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
	
	unless ( ref($treeRef) )
	{
		print "Possible error in modifyTree for $treeRef\n";
		return;
	}
	my %tree = %$treeRef;
	$improveThis = 1; #allow 2+ levels here USE inSERT INTO TREE INSTEAD.

	if ( $subTreeName =~ /ARRAY/)
	{
		my @subTreeNames = @$subTreeName;
		$subTreeName = $subTreeNames[0];
	}
	$tree{$subTreeName} = $subTreeRef;
	
	$treeRef = \%tree;
	
	return ( $treeRef);
}


sub printSubTree
{
	my $subTreeRef			= $_[0];
	my $subTreeName         = $_[1];
	my $iStartLevel			= $_[2];
	my $fileHandle			= $_[3];
	my $title				= $_[4];
	
	$subTreeRef = getSubTree($subTreeRef,$subTreeName);
	printTree($subTreeRef,$iStartLevel,$fileHandle,$title,"");
}


sub copySubTree
{
	my $treeRef				= $_[0];
	my $subTreeName         = $_[1];
	my $subTreeCopyName		= $_[2];

	unless ( ref($treeRef ) )
	{
		print "Possible error in copySubtree for $treeRef\n";
		return;
	}
	my %completeParseTree = %$treeRef;
	my $DESTreeRef = $completeParseTree{$subTreeName};
	
	my $treePossiblyExists = ref($completeParseTree{$subTreeCopyName});
	if ( $treePossiblyExists )
	{
		print "Possible error - tree $subTreeCopyName already exists -- not overwriting with $subTreeName\n";
	}
	else
	{
		if ( ref($DESTreeRef))
		{
			if ( $DESTreeRef =~ /HASH/)
			{
				my %DESTree = %$DESTreeRef;
				$completeParseTree{$subTreeCopyName} = \%DESTree;
			}
			elsif ($DESTreeRef =~ /ARRAY/)
			{
				my @DESTree = @$DESTreeRef;
				$completeParseTree{$subTreeCopyName} = \@DESTree;
			}
		}
		else
		{
			$completeParseTree{$subTreeCopyName} = $DESTreeRef;
		}
		
		$globalASTRef = \%completeParseTree;
	}
	
	return ( $globalASTRef);
}


sub getInfoFromSubTree
{
	
	my ($localParseTreeRef, $subTreeName, $tagsRef, $iTreeLevel) = @_;
	
	my %localParseTree = %$localParseTreeRef;
	my %tags          = %$tagsRef;
	
	my $DESTreeRef = $localParseTree{$subTreeName};
	my $functionRef   = $tags{"routine"};
	if ( $functionRef eq "" )
	{
		print "Error in tags -- no function given for $subTreeName call\n";
		exit;
	}

	if ( ! ref ( $DESTreeRef ) )
	{
		print "Note -- use of default in getSubTree for $subTreeName\n";
		my $startTag = $tags{"startTag"};
		my $endTag = $tags{"endTag"};
		my $stringIsHere = $startTag . $DESTreeRef . $endTag;
		return ( $stringIsHere );
	}
	
	my $valuesString = "";
	if ( $subTreeName eq $tags{"label"} )
	{
		my ($valuesStringTemp,$state) = &$functionRef($DESTreeRef,\%tags,$iTreeLevel+1);
		if ( ref($valuesStringTemp) && $valuesStringTemp =~ /HASH/)
		{
			$valuesString = $valuesStringTemp;
		} 
		else
		{
			$valuesString = $valuesStringTemp;
		}
	}
	
	$improveThis = 1; #hack noted since hash values or strings could be involved, or multiple hash trees.
	my($valuesStringTemp, $state ) = getInfoFromTree($DESTreeRef, $tagsRef, $iTreeLevel);
	
	if (defined($valuesStringTemp))
	{
	    if ( ref($valuesStringTemp) && $valuesStringTemp =~ /HASH/)
	    {
		    $valuesString = $valuesStringTemp;
	    } 
	    else
	    {
		    $valuesString .= $valuesStringTemp;
	    }
    }	
	return ( $valuesString );
}


sub fillInArrayOfInfoFromSubTree
{
	
	my($ParseTreeRef, $subTreeName, $tagsRef, $arrayOfInfoRef,$iTreeLevel) = @_;
	
	if ( ref($ParseTreeRef) && $ParseTreeRef =~ /HASH/)
	{
		my %ParseTree = %$ParseTreeRef;
		my %tags          = %$tagsRef;
		
		my $DESTreeRef = $ParseTree{$subTreeName};
		my $functionRef   = $tags{"routine"};
		if ( $functionRef eq "" )
		{
			print "Error in tags -- no function given for $subTreeName call\n";
			exit;
		}

		if ( ! ref ( $DESTreeRef ) )
		{
			print "Note -- use of default in getSubTree for $subTreeName\n";
			return ( $tags{"startTag"} . $DESTreeRef . $tags{"endTag"});
		}
		
		my $valuesString = "";
		if ( $subTreeName eq $tags{"label"} )
		{
			($arrayOfInfoRef,$state) = &$functionRef($DESTreeRef,\%tags,$arrayOfInfoRef,$iTreeLevel+1);
		}
		
		$improveThis = 1; #hack noted since hash values or strings could be involved, or multiple hash trees.
		($arrayOfInfoRef, $state ) = fillInArrayOfInfoFromTree($DESTreeRef, $tagsRef, $arrayOfInfoRef,$iTreeLevel);
	}
		
	return ( $arrayOfInfoRef, "OK" );
}

sub getArrayOfInfoFromSubTree
{
	
	my ($subTreeRef, $subTreeName, $tagsRef, $iTreeLevel) = @_;
	my %subTree       = %$subTreeRef;
	my %tags          = %$tagsRef;

	$subTreeRef = getSubTree($subTreeRef,$subTreeName);
		
	my $functionRef   = $tags{"routine"};
	
	my ($arrayRef,$state) = &$functionRef($subTreeRef,\%tags,$iTreeLevel+1);
	my $arrayTempRef;
	($arrayTempRef, $state ) = getArrayOfInfoFromTree($subTreeRef, $tagsRef, $iTreeLevel);
	
	my @array = ();
	if ( ref($arrayRef) )
	{
		if ( $arrayRef =~ /ARRAY/)
		{
			@array = @$arrayRef;
		}
		else
		{	
			$array[0] = $arrayRef;
		}
	}
	elsif ( $arrayRef ne "" )
	{
		$array[0] = $arrayRef;
	}
	
	my @arrayTemp = @$arrayTempRef;
	push(@array,@arrayTemp);
	
	return (\@array);
}

sub getHashOfInfoFromSubTree
{	
	my ($subTreeRef, $subTreeName, $tagsRef, $iTreeLevel,$hashRef) = @_;
	my %tags          = %$tagsRef;

	$subTreeRef = getSubTree($subTreeRef,$subTreeName);
		
	my $functionRef   = $tags{"routine"};
	
	my $state = "";
	
    ($hashRef,$state) = &$functionRef($subTreeRef,\%tags,$iTreeLevel+1,$hashRef);
    $improveThis = 0;
    if ( $improveThis )
    {
        ($hashRef, $state ) = getHashOfInfoFromTree($subTreeRef, $tagsRef, $iTreeLevel,$hashRef);
    }
	return ($hashRef);
}

sub indentityTransform
{
	return ($_[0],"OK");
}

sub doesSubTreeExist
{
	my ( $subTreeRef,$subTreeName) = @_;
	
	my $iFound = 0;
	
	my @arrayOfNames = ();
	unless ( $subTreeName =~ /ARRAY/)
	{
		$arrayOfNames[0] = $subTreeName;
	}
	else
	{
		@arrayOfNames = @$subTreeName;
	}
	
	for  ( my $iName =0; $iName <= $#arrayOfNames; $iName++ )
	{
	
		my %subTree;

		my $subTreeName = $arrayOfNames [$iName];
		if ( ref($subTreeRef))
		{
			if ( $subTreeRef =~ /ARRAY/ && $subTreeName =~ /^\d+$/)
			{
					my @subTrees = @$subTreeRef;
					$subTreeRef = $subTrees[$subTreeName];
			}
			elsif ( $subTreeRef =~ /HASH/)
			{
				%subTree    = %$subTreeRef;
				$subTreeRef = $subTree{$subTreeName};
			}
		}
	
		if ( ref($subTreeRef))
		{
			$iFound = 1;
		}
	}
	return ( $iFound);
}

sub getSubTree
{
	my ( $subTreeRef,$subTreeNameRef) = @_;
	
	my @arrayOfNames = ();
	unless ( $subTreeNameRef =~ /ARRAY/)
	{
		$arrayOfNames[0] = $subTreeNameRef;
	}
	else
	{
		@arrayOfNames = @$subTreeNameRef;
	}
	
	
	for  ( my $iName =0; $iName <= $#arrayOfNames; $iName++ )
	{
	
		my %subTree;

		my $subTreeName = $arrayOfNames [$iName];
		if ( ref($subTreeRef))
		{
			if ( $subTreeRef =~ /ARRAY/ && $subTreeName =~ /^\d+$/)
			{
					my @subTrees = @$subTreeRef;
					$subTreeRef = $subTrees[$subTreeName];
			}
			elsif ( $subTreeRef =~ /HASH/)
			{
				%subTree    = %$subTreeRef;
				$subTreeRef = $subTree{$subTreeName};
			}
		}
	
		if ( ref($subTreeRef) && $subTreeRef =~ /HASH/ )
		{
			%subTree = %$subTreeRef;
		}
		elsif ( $iName < $#arrayOfNames )
		{
			my @myKeys = keys(%subTree);
			print "\n-----------------------------------------------\n";
			print "Error in getSubTree\n";
			print "available keys are:", join(",", @myKeys), "\n";
			print "\nYou asked for ", join(",",@arrayOfNames), " and currently ", $subTreeName, "for: ", $subTreeRef, "\n";
			print "\n-----------------------------------------------\n";
		}
	}
	return ( $subTreeRef);
}

sub insertSubTree
{
	my ( $treeRef,$subTreeName,$newTreeRef) = @_;
	
	if ( ! ref($treeRef) or ! ($treeRef =~ /HASH/) )
	{
	    print "Error in insertSubTree\n";
	    exit;
	}
	my @arrayOfNames = ();
	unless ( $subTreeName =~ /ARRAY/)
	{
		push(@arrayOfNames, $subTreeName);
	}
	else
	{
		@arrayOfNames = @$subTreeName;
	}
	
	my %subTree = %$treeRef;
	
	for  ( my $iName =0; $iName < $#arrayOfNames; $iName++ )
	{
		my $subTreeName = $arrayOfNames [$iName];
		my $subTreeRef = $subTree{$subTreeName};
		if ( ref($subTreeRef) && $subTreeRef =~ /HASH/ )
		{
			%subTree = %$subTreeRef;
		}
		else
		{
			my @myKeys = keys(%subTree);
			print "\n-----------------------------------------------\n";
			print "Error in insertSubTree\n";
			print "available keys are:", join(",", @myKeys), "\n";
			print "\nYou asked for ", join(",",@arrayOfNames), " and currently ", $subTreeName, "for: ", $subTreeRef, "\n";
			print "\n-----------------------------------------------\n";
		}
	}
	my %tree = %$treeRef;
	$tree{$arrayOfNames[0]} = $newTreeRef;
	
	return ( \%tree);
}



sub getDifferentialEquations
{
	my $arrayRef    = $_[0];
	my %tags        = %{$_[1]};
	
	my $routine		= $tags{"routine"};
	my $expression = "";
	my $startTag = $tags{"startTag"};
	my $processingMethodsRef = $tags{"processingMethods"};
	my %processingMethods = ();
	if ( $processingMethodsRef )
	{
		%processingMethods    = %$processingMethodsRef;
	}

	my $getLeftRightOrBothSides   = $tags{"getLeftRightOrBothSides"};

	my @array;
	if ( ref($arrayRef))
	{
		if ($arrayRef =~ /ARRAY/)
		{
			@array = @$arrayRef;
		}
		else
		{
			$array[0] = $arrayRef;
		}
	}
	my $string = "";
	
	my $first = 1;
	
	for my $hashTreeRef ( @array )
	{
	
	#	if ( ! ref ( $hashTreeRef ) || ! $hashTreeRef =~ /HASH/)
	#	{
	#		$expression .= $hashTreeRef;
	#	}

		my %hashTree = %$hashTreeRef;
			
		if ( $hashTree{"oper"} =~ /$assignmentOperator/ )
		{
			if ( $first )
			{
				$expression  = $startTag;
			}
			unless ( $first )
			{
				$expression .= $tags{"separator"};
			}
			$first = 0;

			my $iLevel = 2;

			my $expressionLeft = "";
			my $expressionRight = "";
			
			unless ( defined($getLeftRightOrBothSides) && ( $getLeftRightOrBothSides eq "Right"))
			{
				$expressionLeft = getExpression($hashTree{"left"},$processingMethodsRef);
				my $modifyDifferentialExpressionRef = $processingMethods{"modifyDifferentialExpression"};
				if ( $modifyDifferentialExpressionRef )
				{
					$expressionLeft = &$modifyDifferentialExpressionRef($expressionLeft);
				}
			}
			
			unless ( defined($getLeftRightOrBothSides) && ( $getLeftRightOrBothSides eq "Right" or $getLeftRightOrBothSides eq "Left"))
			{
				my $oper = $hashTree{"oper"};
				if ( $oper =~ /$assignmentOperator/)
				{
					$oper = $tags{"assignmentOperator"};
				}
				$improveThis = 1;
				if ( $improveThis )
				{
					if ( ( ! defined($oper) ) or ( $oper eq "" ) )
					{
						$oper = " = ";
					}
				}

				$expressionLeft .= $oper;
			}
			
			unless ( defined($getLeftRightOrBothSides) && ($getLeftRightOrBothSides eq "Left"))
			{
				$expressionRight = getExpression($hashTree{"right"},$processingMethodsRef,$expressionLeft);
				my $modifyDifferentialExpressionRef = $processingMethods{"modifyDifferentialExpression"};
				if ( $modifyDifferentialExpressionRef )
				{
					$expressionRight = &$modifyDifferentialExpressionRef($expressionRight);
				}
			}
			my @names = ("right","fname");
			my $forLoopOrIfThen = getSubTree($hashTreeRef,\@names);
			if ( ( defined($forLoopOrIfThen) ) && ( $forLoopOrIfThen eq "FORLOOP" or $forLoopOrIfThen eq "IF" ))
			{
				$expression .= $expressionRight;
			}
			else
			{
				$expression .= $expressionLeft . $expressionRight;
			}
		}
	}
	
	$expression .= $tags{"endTag"};
	
	return ( $expression );

}


sub getLHSDependencies
{
	my $arrayRef    = $_[0];
	my %tags        = %{$_[1]};
	my $iLevel      = $_[2];
	my $allVariablesRef = $_[3];
	
    my  %allVariables = %$allVariablesRef;

	my $routine		= $tags{"routine"};
	my $expression = "";
	my $startTag = $tags{"startTag"};
	my $processingMethodsRef = $tags{"processingMethods"};
	my %processingMethods = ();
	if ( $processingMethodsRef )
	{
		%processingMethods    = %$processingMethodsRef;
	}

	my $getLeftRightOrBothSides   = $tags{"getLeftRightOrBothSides"};

	my @array;
	if ( ref($arrayRef))
	{
		if ($arrayRef =~ /ARRAY/)
		{
			@array = @$arrayRef;
		}
		else
		{
			$array[0] = $arrayRef;
		}
	}
	my $string = "";
	
	my $first = 1;
	for my $hashTreeRef ( @array )
	{
	
		my %hashTree = %$hashTreeRef;
			
		if ( $hashTree{"oper"} =~ /$assignmentOperator/ )
		{
			my $expressionLeft = "";
			my $expressionRight = "";
			
			$expressionLeft  = getExpression($hashTree{"left"}, $processingMethodsRef);				
			$expressionRight = getExpression($hashTree{"right"},$processingMethodsRef,$expressionLeft);
			my @variables = split(/\[|\+|\-|\/|\*|\(|\)|\[|\]|\+|exp|EXP/,$expressionRight);
	   	    my $allVariablesString = join(",", @variables);
	        #hack on next line -- this should not be necessary.
			$allVariablesString  =~ s/[\,]+/\,/g;
						
			my @operators = ();
			if ( $expressionRight =~ /\Wexp\W/i)
			{
			    push(@operators,"^");
			}
			if ( $expressionRight =~ /\*/)
			{
			    push(@operators,"\*");
			}
			if ( $expressionRight =~ /\+/)
			{
			    push(@operators,"\+");
			}
			
			my $allOperators = join(",", @operators);
			
			my %allForThisLHS = ();
		    $allForThisLHS{"operators"} = $allOperators;
		    $allForThisLHS{"variables"} = $allVariablesString;

            $allVariables{$expressionLeft} = \%allForThisLHS;
		
		}
	}
	
    return ( \%allVariables,"OK");

}


sub getFullRHSForVariable
{
	my $arrayRef    = $_[0];
	my %tags        = %{$_[1]};
	my $iLevel      = $_[2];
	my $fullDependenciesRef = $_[3];
	
	my %fullDependencies = %$fullDependenciesRef;
	
	my $routine		= $tags{"routine"};
	my $expression = "";
	my $startTag = $tags{"startTag"};
	my $processingMethodsRef = $tags{"processingMethods"};
	my %processingMethods = ();
	if ( $processingMethodsRef )
	{
		%processingMethods    = %$processingMethodsRef;
	}

	my $getLeftRightOrBothSides   = $tags{"getLeftRightOrBothSides"};

	my @array;
	if ( ref($arrayRef))
	{
		if ($arrayRef =~ /ARRAY/)
		{
			@array = @$arrayRef;
		}
		else
		{
			$array[0] = $arrayRef;
		}
	}
	
	my $string = "";
	my $first = 1;
	
	for my $hashTreeRef ( @array )
	{
	
		my %hashTree = %$hashTreeRef;
		if ( $hashTree{"oper"} =~ /$assignmentOperator/ )
		{
			my $expressionLeft = "";
			my $expressionRight = "";
			
			$expressionLeft  = getExpression($hashTree{"left"}, $processingMethodsRef);				
			$expressionRight = getExpression($hashTree{"right"},$processingMethodsRef,$expressionLeft);

            $fullDependencies{$expressionLeft} = $expressionRight;
		
		}
	}
	
    return ( \%fullDependencies,"OK");

}




sub getDifferentialEquation
{
	my $hashTreeRef    = $_[0];
	my %tags        = %{$_[1]};
	
	my $routine		= $tags{"routine"};
	my $expression  = $tags{"startTag"};
	my $processingMethodsRef = $tags{"processingMethods"};
	my %processingMethods = ();
	
	if ( $processingMethodsRef )
	{
		%processingMethods    = %$processingMethodsRef;
	}

	my $getLeftRightOrBothSides   = $tags{"getLeftRightOrBothSides"};
	
	if ( ref ( $hashTreeRef ) && $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;
	
		if ( $hashTree{"oper"} =~ /$assignmentOperator/)
		{
			$expression = $tags{"startTag"};

			my $iLevel = 2;

			unless ( $getLeftRightOrBothSides eq "Right")
			{
				my $expressionTemp .= getExpression($hashTree{"left"},$processingMethodsRef);
				my $modifyDifferentialExpressionRef = $processingMethods{"modifyDifferentialExpression"};
				if ( $modifyDifferentialExpressionRef )
				{
					$expressionTemp = &$modifyDifferentialExpressionRef($expressionTemp);
				}
				$expression .= $expressionTemp;

			}
			
			unless ( $getLeftRightOrBothSides eq "Right" or $getLeftRightOrBothSides eq "Left")
			{
				my $oper = $hashTree{"oper"};
				if ( $oper =~ /$assignmentOperator/)
				{
					$oper = $tags{"assignmentOperator"};
					$improveThis = 1;
					if ( $improveThis )
					{
						if ( $oper eq "" )
						{
							$oper = " = ";
						}
					}
				}
				$expression .= $oper;
			}
			
			unless ( $getLeftRightOrBothSides eq "Left")
			{
				my $expressionTemp .= getExpression($hashTree{"right"},$processingMethodsRef);
				my $modifyDifferentialExpressionRef = $processingMethods{"modifyDifferentialExpression"};
				if ( $modifyDifferentialExpressionRef )
				{
					$expressionTemp = &$modifyDifferentialExpressionRef($expressionTemp);
				}
				
				$improveThis = 0;
				#Ignores the possible use of non-nested parentheses.
				if ( $improveThis )
				{
					if ( substr($expressionTemp,0,1) eq "\(" && substr($expressionTemp,-1) eq "\)" )
					{
						$expressionTemp = substr($expressionTemp,1,length($expressionTemp)-2);
					}
				}
				$expression .= $expressionTemp;
			}
			
			$expression .= $tags{"endTag"};
		}
	}
	return ( $expression );

}
sub getHashTreeOfDifferentialEquation
{
	my $hashTreeRef     = $_[0];
	my %tags			= %{$_[1]};
	
	my $routine		= $tags{"routine"};
	my $expression  = $tags{"startTag"};
	my $processingMethodsRef = $tags{"processingMethods"};
	my %processingMethods = ();
	
	if ( $processingMethodsRef )
	{
		%processingMethods    = %$processingMethodsRef;
	}

	my $getLeftRightOrBothSides     = $tags{"getLeftRightOrBothSides"};
	my $ignoreDifferentialEquations = $tags{"ignoreDifferentialEquations"};
	
	$expression = "";
	
	my $hashTreeToReturn = "";
	if ( ref ( $hashTreeRef ) && $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;
	
		my $hashTreeLeftRef = $hashTree{"left"};
		if ( ref ( $hashTreeLeftRef ) && $hashTreeLeftRef =~ /HASH/)
		{
			
			my %hashTreeLeft       = %$hashTreeLeftRef;
			
			if ( ( $hashTreeLeft{"oper"} eq "func" && $hashTreeLeft{"fname"} eq "D" ) xor $ignoreDifferentialEquations ) 
			{
				$hashTreeToReturn = $hashTreeRef;
			}
		}
	}
	return ( $hashTreeToReturn );

}


sub checkForAssignment
{
	my $hashTreeRef     = $_[0];
	my $tag				= $_[1];
	my $routine			= $_[2];

	my $iFound = 0;
	
	if ( ref($hashTreeRef ) && $hashTreeRef =~ /HASH/ )
	{
		my %hashTree = %$hashTreeRef;
		if ( $hashTree{"oper"} eq "=" )
		{
			$iFound = 1;
		}
	}
	return($iFound);
}

sub storeAssignment
{
	my $hashTreeRef     = $_[0];
	my $tag				= $_[1];
	my $routine			= $_[2];

	my $iFound = 0;
	
	my %hashTree = %$hashTreeRef;
	
	if ( $hashTree{"oper"} eq "=" )
	{
		my $hashTreeLeftRef = $hashTree{"left"};
		my %hashTreeLeft = %$hashTreeLeftRef;
		my $oper = $hashTreeLeft{"oper"};
		my $name = $hashTreeLeft{"name"};

		if ( $oper eq "var")
		{
			$derivationsForVariables{$name} = $hashTree{"right"};
		}
	}
	
	return($hashTreeRef);
								
}								

sub printExpression
{
	my $hashTreeRef = $_[0];
	my $iLevel =      $_[1];
	
	my $stringRef = "";
	
	if ( !ref($hashTreeRef ) )
	{
		print $printHandle $hashTreeRef;
	}
	elsif ($hashTreeRef =~ /SCALAR/)
	{
		print $printHandle $$hashTreeRef;
	}
	elsif ( $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;

		my $infixOperator   = $hashTree{"oper"};
		my $unaryOperator   = $hashTree{"monop"};
		my $prefixOperator  = $hashTree{"fname"};
		
		my $leftRef            = $hashTree{"left"};
		my $rightRef           = $hashTree{"right"};
		
		if ( $infixOperator eq "," or $infixOperator eq "." )
		{
			printExpression($leftRef,0);
			print $printHandle $infixOperator;
			printExpression($rightRef,0);
		}
		elsif ($leftRef ne "" && $rightRef ne "" )
		{
			if ( ref($leftRef )  && $leftRef =~ /HASH/ &&
			     ref($rightRef ) && $rightRef =~ /HASH/ )
			{     
				my %leftTree           = %$leftRef;
				my %rightTree          = %$rightRef;

				if ($leftTree{"left"} ne "") { print $printHandle "(" };
				printExpression($leftRef,0);
				if ($leftTree{"left"} ne "") { print $printHandle ")" };
				print $printHandle $infixOperator;
				if ($rightTree{"right"} ne ""){ print $printHandle "(" };
				printExpression($rightRef,0);
				if ($rightTree{"right"} ne "") { print $printHandle ")" };
			}
			else
			{
				print "Error in printExpression routine\n";
				printTree($hashTreeRef,0,*STDOUT,"");
				print "End of error in printExpression routine\n";
			}
		}

		elsif ( $prefixOperator ne "" && $prefixOperator ne "const" && $prefixOperator ne "var" )
		{
			print $printHandle $prefixOperator;
			print $printHandle "(";
			printExpression($rightRef);
			print $printHandle ")";
		}
		elsif ( $unaryOperator ne "" )
		{
			print $printHandle $hashTree{"monop"};
			printExpression( $rightRef,$iLevel+1);
		}
		else
		{
			print $printHandle  $hashTree{"name"};
			print $printHandle  $hashTree{"val"};
		}
		
		if ( 0 )
		{
			foreach my $key ( keys(%hashTree))
			{
				print $printHandle "\nKey: ", $key, " ";
				printExpression($hashTree{$key},$iLevel+1);
			}
			print $printHandle "(";
			my $hashTreeRightRef = $hashTree{"right"};
			printExpression($hashTreeRightRef,$iLevel+1);
			print $printHandle ")";
		}
	}
	
	return $stringRef;
	
}

sub dummy
{
}

sub getSingleString
{
	my $value = $_[0];
	my %tags  = %{$_[1]};
	my $indentLevel = $_[2];
	my $routineRef = $tags{"subRoutine"};
	my $expressionRef = &$routineRef($value,\%tags);
	
	my $expression = "";
	if ( ref($expressionRef) && $expressionRef =~ /SCALAR/)
	{
		$expression = $$expressionRef;
	}
	else
	{
		$expression = $expressionRef;
	}
	return ( $expression, "OK" );

}

sub getDefaultIfThenExpression 
{
	my $rightRef = $_[0];
	my $processingMethodsRef = $_[1];
	my $expressionSoFar = $_[2];
	my $string = "";

	printTree($rightRef,0,*STDOUT,"If then expression");
	
	my @nameAddresses			= ("left","left","name");
	my @valAddresses			= ("left","right","val");
	my @secondResultAddresses	= ("right","left");
	my @firstResultAddresses	= ("right","right");
	my @testExpressionAddresses = ("left");
	
	my $name		= getSubTree($rightRef,		\@nameAddresses); 
	my $testExpression = getExpression(getSubTree($rightRef,  \@testExpressionAddresses));
	
	my $testVal		= getExpression(getSubTree($rightRef,		\@valAddresses)); 
	my $firstResult = getExpression(getSubTree($rightRef,		\@firstResultAddresses));
	my $secondResult= getExpression(getSubTree($rightRef,		\@secondResultAddresses));
	
	$string .= "\n\tIF	($testExpression)	\n	THEN	$firstResult	ELSE	$secondResult\n	END	IF\n";
	return $string;
}

sub getMapleIfThenExpression 
{
	my $rightRef = $_[0];
	my $processingMethodsRef = $_[1];
	my $expressionSoFar = $_[2];
	my $string = "";

	
	my @nameAddresses			= ("left","left","name");
	my @valAddresses			= ("left","right","val");
	my @secondResultAddresses	= ("right","left");
	my @firstResultAddresses	= ("right","right");
	my @testExpressionAddresses = ("left");
	
	my $name		= getSubTree($rightRef,		\@nameAddresses); 
	my $testExpression = getExpression(getSubTree($rightRef,  \@testExpressionAddresses));
	
	my $testVal		= getExpression(getSubTree($rightRef,		\@valAddresses)); 
	my $firstResult = getExpression(getSubTree($rightRef,		\@firstResultAddresses));
	my $secondResult= getExpression(getSubTree($rightRef,		\@secondResultAddresses));

	$string .= "\n\t$expressionSoFar (1-Heaviside($name-10e-6))*$secondResult + Heaviside($name-10e-6)($firstResult)";
	
	return $string;
}


sub getNonmemIfThenExpression 
{
	my $rightRef = $_[0];
	my $processingMethodsRef = $_[1];
	my $expressionSoFar = $_[2];
	my $string = "";

	my @nameAddresses			= ("left","left","name");
	my @valAddresses			= ("left","right","val");
	my @secondResultAddresses	= ("right","left");
	my @firstResultAddresses	= ("right","right");
	my @testExpressionAddresses = ("left");
	
	my $name		= getSubTree($rightRef,		\@nameAddresses); 
	my $testExpression = getExpression(getSubTree($rightRef,  \@testExpressionAddresses));
	#Improve this-- handle other operators.
	$testExpression =~ s/\>/\.GT\./g;
	
	my $testVal		= getExpression(getSubTree($rightRef,		\@valAddresses)); 
	my $firstResult = getExpression(getSubTree($rightRef,		\@firstResultAddresses));
	my $secondResult= getExpression(getSubTree($rightRef,		\@secondResultAddresses));
	
	$string .= "$expressionSoFar $firstResult";
	$string  .= "\n	IF ($testExpression) $expressionSoFar $secondResult\n";		
	return $string;
}

sub getExpression
{
	my $hashTreeRef = $_[0];
	my $processingMethodsRef = $_[1];
	my $expressionSoFar = $_[2];
	
	my %processingMethods = ();
	my $getLanguageSpecificVersionOfVariableRef = "";
	if ( $processingMethodsRef )
	{
		%processingMethods = %$processingMethodsRef;
		$getLanguageSpecificVersionOfVariableRef = $processingMethods{"getLanguageSpecificVersionOfVariable"};
	}
	
	my $string      = "";
	
	if ( !ref($hashTreeRef ) )
	{
		$string = $hashTreeRef;
	}
	elsif ($hashTreeRef =~ /SCALAR/)
	{
		$string = $$hashTreeRef;
	}
	elsif ( $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;

		my $infixOperator   = $hashTree{"oper"};
		my $unaryOperator   = $hashTree{"monop"};
		my $prefixOperator  = $hashTree{"fname"};
		
		my $leftRef            = $hashTree{"left"};
		my $rightRef           = $hashTree{"right"};
		
		if ( defined($infixOperator) && length($infixOperator) > 0 && ( $infixOperator eq ","  or $infixOperator eq "." ))
		{
			$string .= getExpression($leftRef,$processingMethodsRef,$string);
			$string .= $infixOperator;
			$string .= getExpression($rightRef,$processingMethodsRef,$string);
		}
		elsif ( defined($leftRef ) &&  $leftRef ne "" && defined($rightRef) && $rightRef ne "" )
		{
			my %leftTree           = %$leftRef;
			my %rightTree          = %$rightRef;

			if (defined($leftTree{"left"}) && $leftTree{"left"} ne "") { $string .= "(" };
			$string .= getExpression($leftRef,$processingMethodsRef,$string);
			if (defined($leftTree{"left"}) && $leftTree{"left"} ne "") { $string .= ")" };
			$string .= $infixOperator;
			if (defined($rightTree{"right"}) && $rightTree{"right"} ne ""){ $string .= "(" };
			$string .= getExpression($rightRef,$processingMethodsRef,$string);
			if (defined($rightTree{"right"}) && $rightTree{"right"} ne "") { $string .= ")" };
		}
		elsif ( defined($prefixOperator) && ( $prefixOperator ne "" ) && $prefixOperator ne "const" && $prefixOperator ne "var" )
		{
		
			my $ifThenElseExpression;

			if ( $prefixOperator eq "IF")
			{
			
				my %right = %$rightRef;
				my $rightLeftRef = $right{"left"};
				my $rightLeftExpression = getExpression($rightLeftRef,$processingMethodsRef,$string);
				if ( !defined( $rightLeftExpression) )
				{
				    $rightLeftExpression = "";
				}
				my $stepMethodRef = $processingMethods{"getStepExpression"};
				if ( $stepMethodRef ne "" && $rightLeftExpression =~ /(.*)\.GT\.0(.*)/)
				{
				
					my $variable = $1;
					my $result   = $2;
					my $expression = &$stepMethodRef($variable,"GT", 0, $result, $expressionSoFar);
					$string .= $expressionSoFar . $expression;
				}
				else
				{
					my $getIfThenExpressionRef = $processingMethods{"getIfThenExpression"};
					if ( ! defined ( $getIfThenExpressionRef ) )
					{
						print "ERROR: No method for handling if-then expressions\n";
						exit;
					}
					if ( $getIfThenExpressionRef eq "" )
					{	
						$getIfThenExpressionRef = \&getDefaultIfThenExpression;
					}
					$string = &$getIfThenExpressionRef($rightRef,$processingMethodsRef,$expressionSoFar);
				}
			}
			elsif ( defined($prefixOperator ) && ( $prefixOperator eq "FORLOOP") )
			{
				my @subNames = ("right","left","left","name");
				my $varName = getSubTree($hashTreeRef,\@subNames);
				
				@subNames = ("right","left","right","left","name");
				my $iStartNumber = getSubTree($hashTreeRef,\@subNames);
				@subNames = ("right","left","right","right","name");
				my $iEndNumber = getSubTree($hashTreeRef,\@subNames);

				@subNames = ("right","right");
				my $leftVarRef = getSubTree($hashTreeRef,\@subNames);
				my $expression = getExpression($leftVarRef,\%processingMethods,$string);

				my @arrayOfExpressionsSoFar = split(/\n/,$expressionSoFar);
				my $lastExpression = $arrayOfExpressionsSoFar[$#arrayOfExpressionsSoFar];
				$lastExpression = $expressionSoFar;
				#$lastExpression =~ s/=//g;
				for ( my $iNumber = $iStartNumber; $iNumber <= $iEndNumber; $iNumber++)
				{
					my $newExpressionSoFar = $lastExpression;
					$newExpressionSoFar =~ s/\($varName\)/$iNumber/ig;
					$newExpressionSoFar =~ s/$varName/$iNumber/ig;
					
					my $newExpression = $expression;
					$newExpression =~ s/\($varName\)/$iNumber/g;
					$newExpression =~ s/$varName/$iNumber/g;
					
					my $finalExpression = "$newExpressionSoFar$newExpression";
					
					$string .= "$finalExpression\n	";
				}
				
				my %right = %$rightRef;
				my $rightLeftRef = $right{"left"};
				my $rightLeftExpression = getExpression($rightLeftRef,$processingMethodsRef,$string);
				
				if ( $rightLeftExpression =~ /(.*)\.GT\.0(.*)/)
				{		
					my $variable = $1;
					my $result   = $2;
					my $ifThenMethodRef = $processingMethods{"getIfThenExpression"};
					my $expression = &$ifThenMethodRef($variable, "GT", 0, $result, $expressionSoFar);
					$string .= $expression;
				}
				else
				{
					my %rightLeft = %$rightLeftRef;
					my $rightRightRef = $right{"right"};
					my %rightRight    = %$rightRightRef;
					my $rightRightExpression = getExpression($rightRightRef,$processingMethodsRef,$string);
					$string .= $expressionSoFar . " = " . $expression;
				}
			}

			else
			{
				my $expression = getExpression($rightRef,$processingMethodsRef,$string);
							
				$string .= $prefixOperator;
				$string .= "(";
				$string .= $expression;
				$string .= ")";
			}
		}
		elsif ( defined($unaryOperator) && ( $unaryOperator ne "" ) )
		{
			$string .= $hashTree{"monop"};
			$string .= getExpression( $rightRef,$processingMethodsRef,$string);
		}
		else
		{
			my $name = $hashTree{"name"};
			if ( ! defined($name) )
			{
				#Improve -- do this only if infix operator is "const".
				my $val = $hashTree{"val"};
				if ( defined($hashTree{"val"}))
				{
					$string .=  $hashTree{"val"};
				}
			}
			else
			{
				if ( $getLanguageSpecificVersionOfVariableRef )
				{
					$name =  &$getLanguageSpecificVersionOfVariableRef($name);
				}
    			
				$string .=  $name;
				#Improve -- check to see if this needs to be done at all.
				if ( defined($hashTree{"val"}))
				{
					$string .=  $hashTree{"val"};
				}
			}
		}
	}
	
	return $string;
	
}

sub processIfThenExpression
{
	my $variable = $_[0];
	#my $winbugsVariable = getWinbugsVersionOfVariable($variable);
	my $expression = "step\($variable-eps\)";
	return $expression;

}

sub getNonmemStepExpression
{
	my $variable		= $_[0];
	my $stepCondition   = $_[1];
	my $dataCondition   = $_[2];
	my $result          = $_[3];
	my $expressionSoFar = $_[4];
	
	my $expression = "$expressionSoFar 0; \n\tif ( $variable.$stepCondition.$dataCondition ) then $expressionSoFar $result";
	return $expression;

}

sub getWinbugsIfThenExpression
{
	my $variable = $_[0];
	#my $winbugsVariable = getWinbugsVersionOfVariable($variable);
	my $expression = "step\($variable-eps\)";
	return $expression;

}

sub getHashOfArrayOfValuesInParentheses
{
	my $valueRef= $_[0];
	my %tags    = %{$_[1]};
	my $startTag = $tags{"startTag"};
	my $label    = $tags{"label"};
	my $routine	 = $tags{"subRoutine"};
	
	my $expression = getStartTag($startTag," ");
	
	my @allHashTrees;
	if ( ref($valueRef) && $valueRef =~ /ARRAY/)
	{
		@allHashTrees  = @$valueRef;
	}
	else
	{
		$allHashTrees[0] = $valueRef;
	}
	
	my $iTheta = 0;
	my $first = 1;
	
	foreach my $hashTreeRef ( @allHashTrees)
	{
		next unless (ref($hashTreeRef) && $hashTreeRef =~ /HASH/);
		
		my %hashTreeForVariable = %$hashTreeRef;
		my $hashTreeSetRef = $hashTreeForVariable{"variable"};
		if ( defined($hashTreeSetRef) && $hashTreeSetRef eq "" )
		{
			$hashTreeSetRef = $hashTreeForVariable{"vector"};
		}
		my @hashTreeSet;
		if ( ref($hashTreeSetRef) && $hashTreeSetRef =~ /ARRAY/)
		{
			@hashTreeSet = @{$hashTreeSetRef};
		}
		else
		{
			$hashTreeSet[0] = $hashTreeSetRef;
		}
		foreach my $unknownRef ( @hashTreeSet )
		{
			my @array;
			if ( ref($unknownRef) && $unknownRef =~ /ARRAY/)
			{
				@array = @$unknownRef;
			}
			else
			{
				$array[0] = $unknownRef;
			}
			
			foreach my $unknownRef1 ( @array )
			{
				$iTheta++;
				if ( ref($unknownRef1) && $unknownRef1 =~ /HASH/)
				{
					my %hash = %$unknownRef1;
					
					my @arrayOfValues = $hash{"middle"};
					$tags{"label"} = "$label$iTheta";
					
					unless($first)
					{
						$expression .= $tags{"separator"};
					}
					$first = 0;
					
					$expression .= &$routine(@arrayOfValues,\%tags);
				}
				else
				{
				    if ( defined($unknownRef1) )
				    {
					    $expression .= " " . $unknownRef1;
					}
				}
			}
		}
	}
	$expression .=  getEndTag($tags{"endTag"}," ");
	return($expression);
}

sub fillInArrayOfValuesInParentheses
{
	my $valueRef = $_[0];
	my %tags     = %{$_[1]};
	my $arrayOfValuesRef = $_[2];

	my $routine  = $tags{"subRoutine"};
	my @arrayOfValues = @$arrayOfValuesRef;
	
	my @allHashTrees;
	if ( ref($valueRef) && $valueRef =~ /ARRAY/)
	{
		@allHashTrees  = @$valueRef;
	}
	else
	{
		$allHashTrees[0] = $valueRef;
	}
	
	my $iTheta = 0;
	foreach my $hashTreeRef ( @allHashTrees)
	{
		next unless (ref($hashTreeRef) && $hashTreeRef =~ /HASH/);
		
		my %hashTreeForVariable = %$hashTreeRef;
		my $hashTreeSetRef = $hashTreeForVariable{"variable"};
		if ( defined($hashTreeSetRef) && $hashTreeSetRef eq "" )
		{
			$hashTreeSetRef = $hashTreeForVariable{"vector"};
		}

		my @hashTreeSet;
		if ( ref($hashTreeSetRef) && $hashTreeSetRef =~ /ARRAY/)
		{
			@hashTreeSet = @{$hashTreeSetRef};
		}
		else
		{
			$hashTreeSet[0] = $hashTreeSetRef;
		}
		foreach my $unknownRef ( @hashTreeSet )
		{
			my @array;
			if ( ref($unknownRef) && $unknownRef =~ /ARRAY/)
			{
				@array = @$unknownRef;
			}
			else
			{
				$array[0] = $unknownRef;
			}
			foreach my $unknownRef1 ( @array )
			{
			    if ( defined($unknownRef1 ) )
			    {
				    if ( ref($unknownRef1) )
				    {
				        if ( $unknownRef1 =~ /HASH/)
				        {
					        my %hash = %$unknownRef1;
					        my @vector = $hash{"middle"};
					        $arrayOfValues[$iTheta++] = &$routine(@vector,\%tags);
					    }
				    }
				    elsif ( $unknownRef1 =~ /\w/)
				    {
					    $arrayOfValues[$iTheta++] = $unknownRef1;
				    }
				}
			}
		}
	}
	return(\@arrayOfValues);
}



sub getHashOfArrayOfValues
{
	my $valueRef= $_[0];
	my %tags    = %{$_[1]};
	
	my $tag = $tags{"startTag"};
	my $routine	= $tags{"subRoutine"};
	
	my $expression = getStartTag($tag," ");
	
	my @vector;
	
	if ( ref($valueRef) )
	{
		if ( $valueRef =~ /HASH/)
		{
			my %hashTable =  %$valueRef;
			my $vectorRef = $hashTable{"vector"};
			if ( ref($vectorRef) && $vectorRef =~ /ARRAY/ )
			{
				@vector = @$vectorRef;
			}
			else
			{
				print "probable error in reportHashOfArrayOfValues\n";
				print "probable error in reportHashOfArrayOfValues\n";
				return;
			} 
		}
		elsif ( $valueRef =~ /ARRAY/)
		{
			@vector = @{$valueRef};
			my $vector0 = $vector[0];
			if ( ref($vector0) && $vector0 =~ /HASH/)
			{
				my %hash = %$vector0;
				@vector = @{$hash{"vector"}};
			}
		}
	}
	else
	{
		$vector[0] = $valueRef;
	}

	for ( my $iTheta = 0; $iTheta <= $#vector; $iTheta++)
	{
		my $iThetaBase1 = $iTheta + 1;
		$expression .= $tags{"separator"} if $iTheta > 0;
		#printStartTag("$tag$iThetaBase1",1);
		#"$tag$iThetaBase1"
		$improveThis = 1;
		$tags{"iNumber"} = $iThetaBase1;
		$expression .= &$routine($vector[$iTheta],\%tags);

		#printEndTag("$tag$iThetaBase1",1);

	}

	$expression .= $tags{"endTag"};
}


sub getArrayOfValues
{
	my $valueRef= $_[0];
	my %tags    = %{$_[1]};
	
	my $startTag  = $tags{"startTag"};
	my $routine	  = $tags{"subRoutine"};
	my $separator = $tags{"separator"};
	
	my $expression = getStartTag($startTag," ");
	
	if (ref($valueRef ) && $valueRef =~ /ARRAY/)
	{
		
		my @vector    = @{$valueRef};
		my $iFound = 0;
		
		for ( my $iTheta = 0; $iTheta <= $#vector; $iTheta++)
		{
			if ( $iFound )
			{
				$expression .= $separator;
			}
			$iFound = 1;
			my $iThetaBase1 = $iTheta + 1;
			
			$tags{"internalStartTag"} = " "; #	"$startTag$iThetaBase1";
			$expression .=  &$routine($vector[$iTheta],\%tags);

			#printEndTag("$tag$iThetaBase1",1);

		}
	}
	else
	{
		$tags{"startTag"} = " " ; #"${startTag}1";
		$expression .= &$routine($valueRef,\%tags);

	}
	
	$expression .= getEndTag($tags{"endTag"}," ");
	return($expression,"OK");
}


sub fillInArrayOfValues
{
	my $valueRef= $_[0];
	my %tags    = %{$_[1]};
	my $arrayOfValuesRef = $_[2];
	my @arrayOfValues = @$arrayOfValuesRef;
	
	my $routine	  = $tags{"subRoutine"};
	
	my $iTheta = 0;
	if (ref($valueRef ) && $valueRef =~ /ARRAY/)
	{
		
		my @vector    = @{$valueRef};
		for ( my $iTheta = 0; $iTheta <= $#vector; $iTheta++)
		{
			$arrayOfValues[$iTheta] = &$routine($vector[$iTheta],\%tags);
			$iTheta++;
		}
	}
	else
	{
		$arrayOfValues[0] = &$routine($valueRef,\%tags);
	}
	
	
	return(\@arrayOfValues,"OK");
}


sub mapNamesToUseOfVectors
{
	my $hashTreeRef  =$_[0];
	my $tag			= $_[1];
	my $nParams     = $_[2];

	my %mapOfNames = ();
	for ( my $key = 1; $key < $nParams; $key++)
	{
		my $iFound = 0;
		my $name = "$tag$key";
		$mapOfNames{$name} = $tag . "(" . $key . ")";
	}
	return ( \%mapOfNames, "OK");
}



sub mapNamesOfDifferentialsToUseOfVectors
{
	my $hashTreeRef  =$_[0];
	my $tag			= $_[1];
	my $nParams     = $_[2];

	my %mapOfNames = ();
	for ( my $key = 1; $key < $nParams; $key++)
	{
		my $iFound = 0;
		my $name = "$tag$key";
		my $variable = $name;
		$variable =~ s/^D|DT[\d]+$//g;
		$mapOfNames{$name} = "diff(" . $variable.$key . "(t),t)";
	}
	return ( \%mapOfNames, "OK");
}

sub mapNamesToUseOfMapleVectors
{
	my $hashTreeRef = $_[0];
	my $tag			= $_[1];
	my $nParams     = $_[2];

	my %mapOfNames = ();
	for ( my $key = 1; $key < $nParams; $key++)
	{
		my $iFound = 0;
		my $name = "$tag$key";
		$mapOfNames{$name} = "$tag$key" . "(t)";
	}
	
	return ( \%mapOfNames, "OK");
}


sub mapNamesOfDifferentialsToUseOfJetNotation
{
	my $hashTreeRef  =$_[0];
	my $tag			= $_[1];
	my $nParams     = $_[2];

	my %mapOfNames = ();
	for ( my $key = 1; $key < $nParams; $key++)
	{
		my $iFound = 0;
		my $name = "$tag$key";
		my $variable = $name;
		$variable =~ s/^D|DT[\d]+$//g;
		$mapOfNames{$name} = "$variable$key" . "[t]";
	}
	return ( \%mapOfNames, "OK");
}

sub mapNamesToUseOfJetNotation
{
	my $hashTreeRef = $_[0];
	my $tag			= $_[1];
	my $nParams     = $_[2];

	my %mapOfNames = ();
	for ( my $key = 1; $key < $nParams; $key++)
	{
		my $iFound = 0;
		my $name = "$tag$key";
		$mapOfNames{$name} = "$tag$key" . "[]";
	}
	
	return ( \%mapOfNames, "OK");
}

sub obtainInverseHashOfValues
{
	my $hashTreeRef  = $_[0];
	my %tags         = %{$_[1]};
	my $iLevel       = $_[2];
	my $mapOfNamesRef = $_[3];
	my %mapOfNames    = %$mapOfNamesRef;

 #   VECTOR_VARIABLE_DEPENDENCIES => 
  #   HASH = (
  #       A => 
  #       HASH = (
  #           1 => 'CL'
  #           2 => 'V'
   #      )
   #      ETA => 
   #      HASH = (
   #          1 => 'CL'
   #          2 => 'V'
   #      )
    #     THETA => 
    #     HASH = (
    #         1 => 'TVCL'
    #         2 => 'TVV'
    #     )
      
      	
	if ( ref($hashTreeRef ) && $hashTreeRef =~ /HASH/)
    {
        my %hashTree = %$hashTreeRef;
	    my $tag			= $tags{"label"};
    	
    	my $treeForThisTagRef = $hashTree{$tag};
    	my %treeForThisTag    = %$treeForThisTagRef;
    	
	    for ( my $key = 1; ; $key++)
	    {
		    my $value = $treeForThisTag{"$key"};
		    last if ( ! defined($value) ) or $value eq ""; 
		    
		    my $keyPlusValue = $tag . $key;
		    my $previous = $mapOfNames{$value};
		    
		    if ( defined($previous ) )
		    {
		        my @previousOnes = split(/,/,$previous);
		        my $previouslyThere = 0;
		        foreach my $previousOne ( @previousOnes)
		        {
		            if ( $previousOne eq $keyPlusValue)
		            {   
		                $previouslyThere = 1;
		            }
		        }
		        next if $previouslyThere;
		        if ( $previous )
		        {
		            $mapOfNames{$value} = $previous . "," . $keyPlusValue;
		        }  
		        else
		        {
		            $mapOfNames{$value} = $keyPlusValue;
		        }  
	        }
	     }
	}
	
	return(\%mapOfNames,"OK");

}

sub obtainInverseHashOfValuesForMaple
{
	my %hashTree  = %{$_[0]};
	my %tags      = %{$_[1]};
	
	my $tag			= $tags{"label"};

	my %mapOfNames = ();
	
	for ( my $key = 1; ; $key++ )
	{
		my $value = $hashTree{"$key"};
		last if ( ! defined($value) ) or $value eq "";
		$mapOfNames{$value} = $tag . $key;
	}
	
	return(\%mapOfNames,"OK");

}

sub obtainHashOfValues
{
	my %hashTree  = %{$_[0]};
	my $tag			= $_[1];

	my %mapOfNames = ();
	
	for ( my $key = 1; ; $key++)
	{
		my $value = $hashTree{"$key"};
		last if $value eq "";
		$mapOfNames{$tag . $key} = $value;
	}
	
	my $state = "OK";
	return(\%mapOfNames,$state);

}

sub printTagAndValueOld
{
	my $tag = $_[0];
	my $indentLevel = $_[1];
	my $value = $_[2];
	
	print $printHandle "\n", " " x ( 4 * $indentLevel );
	print $printHandle "<$tag>";
	
	print $printHandle "\n", " " x ( 4 * ( $indentLevel + 1));
	print $printHandle $value;
	
	print $printHandle "\n", " " x ( 4 * $indentLevel) ;
	print $printHandle "</$tag>";
}

sub printTagAndValue
{
	my $tag = $_[0];
	my $indentLevel = $_[1];
	my $value = $_[2];
	
	print $printHandle "\n", " " x ( 4 * $indentLevel );
	my $separator = "=";
	if ($indentLevel == 0)
	{
		$separator = " ";
	}

	print $printHandle "$tag$separator$value";
}

sub getMainTagAndValue
{
	my $value = $_[0];
	my %tags  = %{$_[1]};
	
	if ( ref($value ) && $value =~ /SCALAR/)
	{
		$value = $$value;
	}
	
	my $startTag = $tags{"startTag"};
	if ( ! defined($startTag) )
	{
	    $startTag = "";
	}
	my $separator = $tags{"separator"};
	if ( ! defined($separator) )
	{
	    $separator = "";
	}
	my $endTag = $tags{"endTag"};
	if ( ! defined($endTag) )
	{
	    $endTag = "";
	}
	
	my $expression = $startTag . $separator . $value . $separator  . $endTag;
	return ( $expression );
	
}

sub getTagAndValue
{
	my $value = $_[0];
	my %tags  = %{$_[1]};
	
	my $expression = $tags{"startTag"} . $tags{"separator"} . $value . $tags{"separator"}  . $tags{"endTag"};
	return ( $expression );
}


sub getTagAndValueOrHashGeneral
{
	my $tag = $_[0];
	my $indentLevel = $_[1];
	my $value = $_[2];
	
	my $expression = "";

	my $separator = "=";
	if ($indentLevel == 0)
	{
		$separator = " ";
	}

	if ( ref($tag ) && $tag =~ /HASH/)
	{
		my %hashTree = %$tag;
		foreach my $key ( keys ( %hashTree ))
		{
			$expression .= "$key=$hashTree{$key} ";
		}
	}
	elsif ( ref($tag) && $tag =~ /SCALAR/)
	{
		$expression .=  "$$tag";
	}
	elsif ( ref($tag) && $tag =~ /ARRAY/)
	{
		my @array = @$tag;
		my $iFirst = 1;
		$separator = " ";
		foreach my $arrayElement( @array )
		{
			unless ($iFirst)
			{
				$expression .=  $separator;
			}
			$iFirst = 0;
			$expression .=  $arrayElement;
		}	
		#print "\n";
	}
	else 
	{
		$expression .=  "$tag";
	}

	return($expression);
}



sub getTagAndValueOrExpressionGeneral
{
	my $tag = $_[0];
	my $indentLevel = $_[1];
	my $value = $_[2];

	my $separator = "=";
	my $expression = "";
	
	if ($indentLevel == 0)
	{
		$separator = " ";
	}

	if ( ref($tag ) && $tag =~ /HASH/)
	{
		$expression .= getExpression($tag,0);
	}
	elsif( ref($value ) && $value =~ /HASH/)
	{
		$expression .= getExpression($value,0);
	}
	else
	{
		$expression .=  "$tag$separator$value";
	}
	return($expression);
	
}

sub printStartTag
{
	my $tag = $_[0];
	my $delimiter = $_[1];
	print  $printHandle "$tag";
}

sub getStartTag
{
	my $tag = $_[0];
	my $delimiter = $_[1];
	my $expression = "$tag";
	return ( $expression);
}

sub printValue
{
	my $value = $_[0];
	print $printHandle $value;
}

sub getEndTag
{
	my $tagRef = $_[0];
	my $tag;
	if ( ref($tag))
	{
		$tag = $$tagRef;
	}
	else
	{
		$tag = $tagRef;
	}
	
	my $expression = $tag;
	return ( $expression);

}

sub printEndTag
{
	my $tagRef = $_[0];
	my $tag;
	if ( ref($tag))
	{
		$tag = $$tagRef;
	}
	else
	{
		$tag = $tagRef;
	}
	print $printHandle $tag;

}

sub getThetaGeneral
{
	my @arrayOfValues = @{$_[0]};
	my $tag           = $_[1];
	
	my $iLengthOfTheta = scalar(@arrayOfValues);
	
	my $lowValue;
	my $mediumValue;
	my $highValue;
	
	my $expression;
	if ( $iLengthOfTheta == 1 )
	{
		$lowValue   = 0;
		$mediumValue = $arrayOfValues[0];
		$expression = " $mediumValue";
	}
	else
	{
		$lowValue		= $arrayOfValues[0];
		$lowValue       = "" if ! defined( $lowValue );
	
		$mediumValue    = $arrayOfValues[1];
		$mediumValue       = "" if ! defined( $mediumValue );

		$highValue		= $arrayOfValues[$iLengthOfTheta-1];
		$highValue       = "" if ! defined( $highValue );
		
		$expression = "( $lowValue, $mediumValue, $highValue ) ";

	}
	
	return ( $expression);

}

sub getThetaBounds
{
	my @arrayOfValues = @{$_[0]};
	my %tags = %{$_[1]};
	
	my $label       = $tags{"label"};
	my $indentLevel = $tags{"indentLevel"};
		
	my $lowValue     = $arrayOfValues[0];
	
	my $iLengthOfTheta = $#arrayOfValues;
	my $highValue    = $arrayOfValues[$iLengthOfTheta];
	
	my $expression =  "\n" . " " x ( 4 * $indentLevel );

	$expression .=  "$lowValue < $label, $label < $highValue";
	return ( $expression);
	
}


sub getThetaBoundsForAlgebraicTheories
{
	my @arrayOfValues = @{$_[0]};
	my %tags = %{$_[1]};
	
	my $label       = $tags{"label"};
	my $indentLevel = $tags{"indentLevel"};
		
	my $lowValue     = $arrayOfValues[0];
	
	my $iLengthOfTheta = $#arrayOfValues;
	my $highValue    = $arrayOfValues[$iLengthOfTheta];
	
	$improveThis =1 ; #do this better...
	my $baseLabel  = substr($label,0,length($label)-1);
	my $iNumber    = substr($label,-1);
	
	$improveThis = 1;
	my $lcBaseLabel = lc($baseLabel);
	$lcBaseLabel = $baseLabel;
	
	my $expression =  "$baseLabel, $lcBaseLabel\[$iNumber\] \> $lowValue\n";
	$expression   .=  "$baseLabel, $lcBaseLabel\[$iNumber\] \< $highValue\n";

	return ( $expression);

}

sub getPKVariableNamesOriginal 
{
    my $arrayRef = $_[0];
    my @arrayOfNames = @$arrayRef;

    my $listOfVariables = join(",", @arrayOfNames);
    my $expression =  "VARIABLE_NAMES_ORIGINAL,PK, =, [ $listOfVariables ]\n";

    return ( $expression);
}

sub getPKVariableNames 
{
    my $arrayRef = $_[0];
    my @arrayOfNames = @$arrayRef;

    my $listOfVariables = join(",", @arrayOfNames);
    my $expression =  "VARIABLE_NAMES,PK, =, [ $listOfVariables ]\n";

    return ( $expression);
}

sub getPKVariableNamesFromGlobal() 
{
    my $arrayRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES");
    my @arrayOfNames = @$arrayRef;
    return(\@arrayOfNames);
}

sub getPKVariableDependencies
{
	my ( $treeRef, $parameter, $arrayOfPKNamesRef, $defaultPrefix ) = @_;

	my %tree = %$treeRef;

	my $treeForParameterRef = $tree{$parameter};
	my %treeForParameter    = %$treeForParameterRef;
    my @arrayOfPKNames      = @$arrayOfPKNamesRef;
    
    my $expression;
    
    for my $key ( sort(keys ( %treeForParameter ) ))
    {
        my $variable  = $treeForParameter{$key};
        
        my $variableToUse = "";
        my $iVariable = Util_isInList($variable,@arrayOfPKNames);
        if ( $iVariable == -1 )
        {   
            $iVariable = Util_isInListWithPrefix($variable,$defaultPrefix,@arrayOfPKNames);
        }
        $variableToUse = $variable;
        if ( $iVariable > -1 )
        {
            $variableToUse = $defaultPrefix . $arrayOfPKNames[$iVariable];
        }
        my $lcParameter = lc($parameter);
        $improveThis = 1;
        $lcParameter = lc($parameter);
 	    $expression  .=  "PK_VARIABLE_NAMES," . $lcParameter . "[$key\], =, $variableToUse\n";
    }

	return ( $expression);
	
}

sub getPKVariableNamesFromDependencies
{
	my ( $treeRef, $parameter, $arrayOfPKNamesRef, $defaultPrefix ) = @_;

	my %tree = %$treeRef;

	my $treeForParameterRef = $tree{$parameter};
	my %treeForParameter    = %$treeForParameterRef;
    my @arrayOfPKNames      = @$arrayOfPKNamesRef;
    
    my $lcParameter = lc($parameter);
    $improveThis = 1;
    $lcParameter = $parameter;
    
    my @namesFound = ();
    my @keys = sort ( keys ( %treeForParameter ) );
    for my $key ( @keys  )
    {
        my $variable  = $treeForParameter{$key};
        
        my $variableToUse = "";
        my $iVariable = Util_isInList($variable,@arrayOfPKNames);
        if ( $iVariable == -1 )
        {   
            $iVariable = Util_isInListWithPrefix($variable,$defaultPrefix,@arrayOfPKNames);
        }
        $variableToUse = $variable;
        if ( $iVariable > -1 )
        {
            $variableToUse = $arrayOfPKNames[$iVariable];
        }
        
        #Still dumb enough to try the same:
        my $lengthOfPrefix = length($defaultPrefix);
        if ( uc(substr($variableToUse,0,$lengthOfPrefix)) eq uc($defaultPrefix))
        {
            $variableToUse = substr($variableToUse,$lengthOfPrefix,length($variableToUse)-2);  
        } 
        #check for Duplicate
        my $alreadyHere = Util_isInList($variableToUse,$defaultPrefix,@namesFound);
        if ( $alreadyHere < 0 )
        {
 	        push(@namesFound,$variableToUse);
 	    }

    }

	return ( \@namesFound);
	
}

sub getPKVariableNamesAsNTuple
{
	my ( $treeRef, $parameter, $arrayOfPKNamesRef, $defaultPrefix ) = @_;

	my %tree = %$treeRef;

	my $treeForParameterRef = $tree{$parameter};
	my %treeForParameter    = %$treeForParameterRef;
    my @arrayOfPKNames      = @$arrayOfPKNamesRef;
    
    my $lcParameter = lc($parameter);
    $improveThis = 1;
    $lcParameter = $parameter;
    
    my $expression  = "PK_VARIABLE_NAMES, " . $lcParameter  . ', = , [ ';

    my $comma = " ";
    my @keys = sort(keys ( %treeForParameter ));
    for my $key ( @keys )
    {
        my $variable  = $treeForParameter{$key};
        
        my $variableToUse = "";
        my $iVariable = Util_isInList($variable,@arrayOfPKNames);
        if ( $iVariable == -1 )
        {   
            $iVariable = Util_isInListWithPrefix($variable,$defaultPrefix,@arrayOfPKNames);
        }
        $variableToUse = $variable;
        if ( $iVariable > -1 )
        {
            $variableToUse = $arrayOfPKNames[$iVariable];
        }
        
        #Still dumb enough to try the same:
        my $lengthOfPrefix = length($defaultPrefix);
        if ( uc(substr($variableToUse,0,$lengthOfPrefix)) eq uc($defaultPrefix))
        {
            $variableToUse = substr($variableToUse,$lengthOfPrefix,length($variableToUse)-2);  
        } 
 	    $expression  .= $comma . $variableToUse;
 	    $comma = ", ";
    }

    $expression .=  " ]\n";
	return ( $expression);
	
}

sub getThetaBoundsAsValues
{
	my @arrayOfValues = @{$_[0]};
	my %tags          = %{$_[1]};
	
	my $label       = $tags{"label"};
	my $indentLevel = $tags{"indentLevel"};
		
	my $lowValue     = $arrayOfValues[0];
	
	my $iLengthOfTheta = $#arrayOfValues;
	my $highValue      = $arrayOfValues[$iLengthOfTheta];

	my @twoValues = ( $lowValue, $highValue);
	return (\@twoValues);
	
}

sub getThetaInitialValues
{
	my @arrayOfValues = @{$_[0]};
	my $indentLevel   = $_[1];
	my $tag           = $_[2];
	
	my $iLengthOfTheta = scalar(@arrayOfValues);
	my $middleValue;
	
	if ( $iLengthOfTheta > 2 )
	{
		$middleValue  = $arrayOfValues[1];
	} 
	elsif ( $iLengthOfTheta == 2 )
	{
		#$middleValue  = ($arrayOfValues[0]+$arrayOfValues[1])/2;
		$middleValue  = ".";

	}
	else
	{
		$middleValue = $arrayOfValues[0];
	}

	my $expression = getTagAndValue($tag,1, $middleValue);
	return ( $expression);

}


sub getThetaBoundsAndInitialValuesForAlgebraicTheories
{
	my @arrayOfValues = @{$_[0]};
	my %tags = %{$_[1]};
	
	my $label       = $tags{"label"};
	my $indentLevel = $tags{"indentLevel"};
		
	my $lowValue     = $arrayOfValues[0];
	
	my $iLengthOfTheta = $#arrayOfValues;
	my $highValue    = $arrayOfValues[$iLengthOfTheta];
	
	$improveThis =1 ; #do this better...
	my $baseLabel  = substr($label,0,length($label)-1);
	my $iNumber      = substr($label,-1);
    $iLengthOfTheta = scalar(@arrayOfValues);
	my $middleValue;
	
	if ( $iLengthOfTheta > 2 )
	{
		$middleValue  = $arrayOfValues[1];
	} 
	elsif ( $iLengthOfTheta == 2 )
	{
		#$middleValue  = ($arrayOfValues[0]+$arrayOfValues[1])/2;
		$middleValue  = ".";

	}
	else
	{
		$middleValue = $arrayOfValues[0];
	}
	
	$improveThis = 1;
	my $lowerCaseLabel = $baseLabel;
	my $expression =  "${baseLabel}BoundsAndInitialValue, " . $lowerCaseLabel . "[$iNumber\], =, [ $lowValue, $middleValue, $highValue]\n";

	return ( $expression);

}

sub getThetaInitialValuesForAlgebraicTheories
{
	my @arrayOfValues = @{$_[0]};
	my %tags = %{$_[1]};
	
	my $label       = $tags{"label"};
	my $indentLevel = $tags{"indentLevel"};
		
	my $lowValue     = $arrayOfValues[0];
	
	my $iLengthOfTheta = $#arrayOfValues;
	my $highValue    = $arrayOfValues[$iLengthOfTheta];
	
	$improveThis =1 ; #do this better...
	my $baseLabel  = substr($label,0,length($label)-1);
	my $iNumber      = substr($label,-1);
	$iLengthOfTheta = scalar(@arrayOfValues);
	my $middleValue;
	
	if ( $iLengthOfTheta > 2 )
	{
		$middleValue  = $arrayOfValues[1];
	} 
	elsif ( $iLengthOfTheta == 2 )
	{
		#$middleValue  = ($arrayOfValues[0]+$arrayOfValues[1])/2;
		$middleValue  = ".";

	}
	else
	{
		$middleValue = $arrayOfValues[0];
	}
	my $lcBaseLabel = lc($baseLabel);
	my $expression =   "${baseLabel}InitialValue," . "${lcBaseLabel}\[$iNumber\][0], =, $middleValue\n";

	return ( $expression);

}

sub getOmegaInitialValues
{
	my $value = $_[0];
	my $tag   = $_[1];

	my $expression = getTagAndValue($tag,1, $value);
	return ( $expression);

}

sub getOmegaInitialValuesGeneral
{
	my $value = $_[0];
	my $tag   = $_[1];
	
	my $expression = $value;

	return($expression);
}

sub getOmegaInitialValuesAsValues
{
	my $value = $_[0];
	my $tagsRef  = $_[1];
	my %tags = %$tagsRef;
	my $tag = $tags{"label"};
	
	my $expression = $value;

	return($expression);
}


sub getOmegaInitialValuesForAlgebraicTheories
{
	my $value = $_[0];
	my $tagsRef  = $_[1];
	my %tags = %$tagsRef;
	my $tag = lc($tags{"label"});
	my $iNumber = $tags{"iNumber"};
	
	my $expression = "${tag}," . "${tag}I[$iNumber] ,=, $value";

	return($expression);
}

sub getOmegaInitialValuesAsListForAlgebraicTheories
{
	my $value = $_[0];
	my $tagsRef  = $_[1];
	my %tags = %$tagsRef;
	my $tag = lc($tags{"label"});
	my $iNumber = $tags{"iNumber"};
	
	my $expression = "$value ";

	return($expression);
}

sub getOmegaBoundsAsValues
{
	my $value = $_[0];
	my $tag   = $_[1];
	
	return($value);
}

sub getNONMEMControlFiles 
{
	if ( ( $_ =~ /$patternForFileName/i )  )
    {
        #&& ( ! /\.CTL$|\.bugs$|\.m$/i )
	    #next unless $File::Find::dir =~ /other/i;
    	unless ( $File::Find::dir =~ /run/ )
    	{
        	
	        my $inputFileNameComplete = $File::Find::name;

	        next if $inputFileNameComplete =~ /\.*TLC/i;

	        my $nameForCopyOfFile = $inputFileNameComplete;
	        $nameForCopyOfFile    = substr($nameForCopyOfFile,length($NONMEMSourceDirectory));
	        $nameForCopyOfFile =~ s/\/|\\/_/g;
	        $nameForCopyOfFile =~ s/^[\.]//;$nameForCopyOfFile =~ s/^_//i;

	        if ( $nameForCopyOfFile =~ /$patternForDirectoryName/i )
	        {

	            print $inputFileNameComplete,"\n";

	            $nameForCopyOfFile = "$runsDirectory/" . $nameForCopyOfFile;
            	
	            my $TLCOutputFileName = $nameForCopyOfFile;
	            if ( $TLCOutputFileName =~ /\.CTL/i)
	            {
		            $TLCOutputFileName	=~ s/\.CTL/\.TLC/ig;
	            }
	            else
	            {
		            $TLCOutputFileName	= $TLCOutputFileName . "\.TLC";
	            }

	            my $dataFileName = "";
            	
	            #print $inputFileNameComplete,"\n";

	            $improveThis = 1;
	            $inputFileNameComplete =~ s/\.\/both/D:\\monolixParsing\\both/g;
	            $inputFileNameComplete =~ s/\//\\/g;
	            open(INPUTFILE,"$inputFileNameComplete") or die("Could not open NONMEM control file for input $inputFileNameComplete\n");
	            my @copy = <INPUTFILE>;
	            close(INPUTFILE);
            	
	            foreach my $line ( @copy )
	            {
		            if ( $line =~ /^DATA/)
		            {
			            my @parts = split(/\s+/,$line);
			            $dataFileName = $parts[1];
            			
			            unless ( open(DATAFILE,$dataFileName))
			            {
				             unless ( open(DATAFILE,"$dataDirectory/$dataFileName"))
				             {
				                my $revisedDataFileName = PK_regularizeFileName($dataFileName,".data");
				                open(DATAFILE,"$dataDirectory/$revisedDataFileName") or die("Could not open $dataDirectory/$revisedDataFileName for $inputFileNameComplete\n");
                            }
			            }
                        #Also make a copy in directory of regularized file names, one per model.
                             		
                        my $oldSeparator = $/;      			
			            $/ = "\n";
			            my @dataLines = <DATAFILE>;
			            close(DATAFILE);
            			$/ = $oldSeparator;
            			
			            $dataLines[0] =~ s/^[\s]*[;\#]*[\s]*//g;
			            my $header = $dataLines[0];
            			
			            my @headers = split(/\s+/,$header);
            			
			            my $iId = 0;
			            my $iEvid = 0;
			            my $iTime = 0;
			            my $iAmt = 0;
			            my $iDoseFieldId = 0;
            			
			            my $minTime = 10000;
            			
			            for ( my $i = 0; $i <= $#headers; $i++)
			            {
				            if ( $headers[$i] eq 'EVID')
				            {
					            $iEvid = $i;
				            }
				            if ( $headers[$i] eq 'ID')
				            {
					            $iId = $i;
				            }
				            if ( $headers[$i] eq 'TIME')
				            {
					            $iTime = $i;
				            }

				            if ( $headers[$i] eq 'AMT')
				            {
					            $iAmt = $i;
				            }
				            if ( $headers[$i] eq 'DOSE')
				            {
					            $iDoseFieldId = $i;
				            }
			            }
            			
			            for ( my $i = 1; $i <= $#dataLines; $i++)
			            {
				            $dataLines[$i] =~ s/^\s+//g;
				            my @values = split(/\s+/,$dataLines[$i]);
				            next if ($values[$iTime] eq "." );
            				
				            if ( $minTime > $values[$iTime] )
				            {
					            $minTime = $values[$iTime];
				            }
			            }
			     
			            my $dataFileWithSameBasicNameAsModel = $nameForCopyOfFile;
			            $dataFileWithSameBasicNameAsModel =~ s/.*\///g;
			            $dataFileWithSameBasicNameAsModel =~ s/\.CTL/\_DATA\.TXT/g;
            		    
            		    $oldSeparator = $/;
			     	    $/ = "\n";
            			open(DATACOPY,">/oss/dataRegularizedNames/$dataFileWithSameBasicNameAsModel") 
            			    or die("Could not open output data file /openStatisticalServices/dataRegularizedNames/$dataFileWithSameBasicNameAsModel\n");
                        print DATACOPY @dataLines;
                        close(DATACOPY);
			            $/ = $oldSeparator;
                
			            open(DATAOUT,">$runsDirectory/$dataFileName.inputs") 
			                or die("Could not open output data file $runsDirectory/$dataFileName.input for $inputFileNameComplete\n");
			            print DATAOUT "$headers[$iId],$headers[$iTime],$headers[$iAmt],$headers[$iDoseFieldId]\n";
			            close(DATAOUT);
 		            }

	            }

	            open(COPYFILE,">$nameForCopyOfFile") or die("Could not open file $nameForCopyOfFile for copy\n");
	            #print COPYFILE ";----------------------------------------------------------------------\n";
	            print COPYFILE @copy;
	            print COPYFILE "\n";
	            #print COPYFILE ";----------------------------------------------------------------------\n";
	            close(COPYFILE);

	            open(INPUTFILE,"$inputFileNameComplete") or die("Could not open file name: $inputFileNameComplete\n");
	            my $inputFileHandle = \*INPUTFILE;
	            print $inputFileNameComplete,"\n";

	            open(OUTPUTFILE,">$TLCOutputFileName") or die("Could not open output file $TLCOutputFileName\n");
	            my $outputFileHandle = \*OUTPUTFILE;

	            my $logFileName = $TLCOutputFileName;
	            $logFileName	=~ s/\.TLC/\.parseLog/i;

	            open(LOGFILE,">$logFileName");
	            my $logFileHandle = \*LOGFILE;

	            reinitStates();

	            if ( $useMATLAB )
	            {
		            &ParseMATLABMetadataAndModel($inputFileHandle,$outputFileHandle,$logFileHandle,$TLCOutputFileName,$dataFileName);
	            }
	            else
	            {
		            &ParseNONMEMFile($inputFileHandle,$outputFileHandle,$logFileHandle,$TLCOutputFileName,$dataFileName);
	            }
	        }
	    }
	}
}

sub getNONMEMDataFiles 
{
	next unless /data*.txt/i;

	my $inputFileNameComplete = $File::Find::name;
	
	next if $inputFileNameComplete =~ /TLC|runs/i;

	print $inputFileNameComplete,"\n";
	
	my $inputFileName = $_;

	my $TLCOutputFileName = $inputFileName;

	my $dataFileName = "";

	open(INPUTFILE,$inputFileName) or die("Could not open file name -- $inputFileName\n");
	my @copy = <INPUTFILE>;
	close(INPUTFILE);

	open(COPYFILE,">$runsDirectory/$inputFileName") or die("Could not open file $runsDirectory/$inputFileName for copy\n");
	print COPYFILE @copy;
	close(COPYFILE);
	
	#Also make a copy of the file as a "regularized" file name
	my $newName = PK_regularizeFileName($inputFileName,"_data.txt");
	
	open(COPYFILE,">/openStatisticalServices/dataRegularizedNames/$newName") or die("Could not open file /oss/dataRegularizedNames/$newName for copy\n");
	print COPYFILE @copy;
	close(COPYFILE);
	

}

sub getMonolixModelFiles 
{
	next unless  $_ =~ /.*\.m/i;

	my $inputFileNameComplete = $File::Find::name;
	
	print $inputFileNameComplete,"\n";
	
	my $inputFileName = $_;

	my $TLCOutputFileName = $inputFileName;

	my $dataFileName = "";

	open(INPUTFILE,$inputFileName) or die("Could not open file name -- $inputFileName\n");
	my @copy = <INPUTFILE>;
	close(INPUTFILE);

	open(COPYFILE,">$monolixTargetDirectory/$inputFileName") or die("Could not open file $monolixTargetDirectory/$inputFileName for copy\n");
	print COPYFILE @copy;
	close(COPYFILE);

}

sub parsePROBLEM
{
	my $string = $_[0];
	my $state  = $_[1];
	
	$string =~ s/\n//g;

	$state = "PROBLEM";
	return ( $string, $state);
}

sub reinitStates
{
	%globalAST = ();
	$globalASTRef = \%globalAST;
	
	%derivationsForVariables = ();
	$derivationsForVariablesRef = \%derivationsForVariables;

	%reverseDerivationsForVariables = ();

	%IfThenExpressionsForVariables = ();
	$IfThenExpressionsForVariablesRef = \%IfThenExpressionsForVariables;

	%variablesWithNumericSuffixes = ();
	$variablesWithNumericSuffixesRef = \%variablesWithNumericSuffixes;
	%variablesWithoutNumericSuffixes = ();
	$variablesWithoutNumericSuffixesRef = \%variablesWithoutNumericSuffixes;

	%logitFunctions = ();
	%inverseLogitFunctions = ();
	
	$notFirstProblem = 0;
}

sub parseCOMMENT
{

	my $string = $_[0];
	my $state  = $_[1];
	
	return ( $string, $state);
}

sub parseDATA
{
	my ($listRef,$state) = parseList(\$_[0],"\\s+");
	
	my $DATARef;
	($DATARef,$state) = parseAttributeValuePairsInList($listRef);
	
	$state = "DATA";
	
	return ( $DATARef, $state );
}



sub parseETA
{
	my ( $listRef, $state ) =  parseLinesOfLists($_[0]);

    my $OMEGARef;
	($OMEGARef,$state) = parseAttributeValuePairsInList($listRef);
	
	my @addresses = (0,"vector");
	my $arrayRef = getSubTree($OMEGARef,\@addresses);
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/)
	{
		my @array = @$arrayRef;
		my $one   = $array[0];
		my $fixed = $array[1];
		if ( $one == 1.0 && $fixed =~ /fixed/i )
		{
			my %tree = (
				fixed => $array[0]
			);
			insertSubTree($globalASTRef,"FixedEta",\%tree);
		}
	}
	
	$state = "ETA";
	return ( $OMEGARef, $state );
}

sub parseMODEL
{
	my ($treeRef,$state) = parseExpressions($_[0]);
	$state = "OK";
	return ( $treeRef, $state );

}

sub parsePK
{

	my ($treeRef, $state) = parseEquations($_[0]);
	return ( $treeRef, $state );

}


sub parseWinBUGSModel
{

	my $treeRef = $_[0];
	my $state = "";
	my $modifiedTreeRef;
	($modifiedTreeRef,$state)  = modifyTree($treeRef,        \&checkForCharactersGiven,\&parseOneCharacterPair,"\{","\}",0,1,0);
	my $modifiedTree1Ref;
	($modifiedTree1Ref,$state) = modifyTree($modifiedTreeRef,\&checkForCharactersGiven,\&replaceBrackets,      "\[","\]",0,100,0);
	
	my %modifiedTree1 = %$modifiedTree1Ref;
	my $middleRef = $modifiedTree1{"middle"};
	
	my $iTotalLevels = 10;
	$improveThis = 1;
	if ( $improveThis )
	{
		$iTotalLevels = 1;
	}
	
	my $middle1Ref = "";
	($middle1Ref,$state) = modifyTree($middleRef,\&checkForCharactersGiven,\&parseEquations,$assignmentOperator,"",0,$iTotalLevels,0);
	   
	$modifiedTree1{"middle"} = $middle1Ref;
	
	$state = "WinBUGSModelStatement";
	
	return ( \%modifiedTree1, $state );
	

}

sub parseListStatement
{
	my $treeRef = $_[0];
	my $state;
     
     my $tree1Ref;
	($tree1Ref,$state) = modifyTree($treeRef, \&checkForCharactersGiven,\&parseOneCharacterPair,"\(","\)",0,10,0);
	
	my $tree2Ref;
	($tree2Ref,$state) = modifyTree($tree1Ref,\&checkForCharactersGiven,\&parseOneSetOfCommas,",","",0,100,0);
	
	$state = "List";
	return ( $tree2Ref, $state );

}

sub checkForComma
{
	my $string = $_[0];
	my $iFound = 0;
	
	if ( ! ref($string) )
	{
		if( grep(/,/,$string))
		{
			$iFound = 1;
		}
	}
	return($iFound);
}


sub replaceBrackets
{
	my $string = $_[0];
	my $iFound = 0;
	my $state = "OK";
	
	if ( ! ref($string) )
	{
		$string =~ s/\[/\(/g;
		$string =~ s/\]/\)/g;
	}
	return($string,$state);
}


sub checkForIFStatement
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	
	my $iFound = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = $#anArray; $i >= 0; $i--)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( defined($hashTree{"oper"} ) && ($hashTree{"oper"} eq "=" ))
				{
					my $hashTreeRightRef = $hashTree{"right"};
				    unless ( ref($hashTreeRightRef) && $hashTreeRightRef =~ /HASH/)
				    {
				        print "Possible error in checkForIfStatement\n";
				        printTree($arrayRef,0,*STDOUT,"Check for if statement\n");
				    }
				    unless ( defined ( $hashTreeRightRef ) and $hashTreeRightRef =~ /HASH/)
				    {
						printTree($globalASTRef,0,*STDOUT,"Here was the complete tree\n");
				        printTree($arrayRef,0,*STDOUT,"Check for if statement\n");
				        printTree($arrayRef,0,*STDOUT,"This was the problematic line\n");
						exit;
					}
					my %hashTreeRight    = %$hashTreeRightRef;
					if ( defined($hashTreeRight{"fname"}) && $hashTreeRight{"fname"} eq "IF" )
					{
						$iFound = 1;
					}
				}
			}
		}
	}
	
	return ( $iFound);
}

sub checkForArray
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	
	my $iFound = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		$iFound = 1;
	}
	
	return ( $iFound);
}


sub checkForTautology
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	
	my $iFound = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = $#anArray; $i >= 0; $i--)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
		
				if ( scalar(keys(%hashTree)) == 0 )
				{
					$iFound = 1;
					print "Internal error in CheckForTautology\n";
					exit;
				}
				
				if ( defined($hashTree{"oper"}) && ( $hashTree{"oper"} eq $assignmentOperator))
				{
					my $rightTreeRef = $hashTree{"right"};
					if ( !ref ( $rightTreeRef ) )
					{
						return 0;
					}
					my %rightTree = %$rightTreeRef;

					my $leftTreeRef = $hashTree{"left"};
					if ( !ref ( $leftTreeRef ) )
					{
						return 0;
					}
					my %leftTree = %$leftTreeRef;

					my $leftVariableName  = $leftTree{"name"};
					my $rightVariableName = $rightTree{"name"};


					if ( defined($leftVariableName) && $leftVariableName ne "" && defined($rightVariableName) && $leftVariableName eq $rightVariableName )
					{
						$iFound = 1;
					}
					
				}
				
			}
		}
	}
	
	return ( $iFound);
}

sub checkForLHSVariable
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = $_[2];
	
	my $iFound = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = $#anArray; $i >= 0; $i--)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( $hashTree{"oper"} eq "=" )
				{
					my $hashTreeLeftRef = $hashTree{"left"};
					my %hashTreeLeft    = %$hashTreeLeftRef;
					if ( $hashTreeLeft{"name"} =~ /$name/ xor $absence )
					{
						$iFound = 1;
						last;
					}
				}
			}
		}
	}
	
	return ( $iFound);
}

sub checkForLHSVariablePresent
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = 0;
	
	return ( checkForLHSVariable($arrayRef,$name,$absence));
}

sub checkForLHSVariableAbsent
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = 1;
	
	return ( checkForLHSVariable($arrayRef,$name,$absence));
}


sub deleteIfLHSVariablePresent
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = 0;
	
	return ( deleteIfLHSVariablePresentOrAbsent($arrayRef,$name,$absence));
}

sub deleteIfLHSVariableAbsent
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = 1;
	
	return ( deleteIfLHSVariablePresentOrAbsent($arrayRef,$name,$absence));
}



sub deleteIfLHSVariablePresentOrAbsent
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	my $absence  = $_[2];
	
	my $iFound = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = $#anArray; $i >= 0; $i--)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( $hashTree{"oper"} eq "=" )
				{
					my $hashTreeLeftRef = $hashTree{"left"};
					my %hashTreeLeft    = %$hashTreeLeftRef;
					if ( $hashTreeLeft{"name"} =~ /$name/ xor $absence )
					{
						$iFound = 1;
						splice(@anArray,$i,1);
					}
				}
			}
		}
		if ( $iFound )
		{
			$arrayRef = \@anArray;
		}
	}

	
	return ( $arrayRef);
}


sub consolidateAsIfThenExpression
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	
	my $iFoundOneIfStatement = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = 0; $i <= $#anArray; $i++)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( $hashTree{"oper"} eq "=" )
				{
					my $hashTreeRightRef = $hashTree{"right"};
					my %hashTreeRight    = %$hashTreeRightRef;
					my $name = "";
					
					if ( $hashTreeRight{"fname"} eq "IF" )
					{
						my $hashTreeLeftRef = $hashTree{"left"};
						my %hashTreeLeft    = %$hashTreeLeftRef;
						if ( $hashTreeLeft{"oper"} eq "var" )
						{
							$name = $hashTreeLeft{"name"};
						
							my $hashTreeRightRef = $hashTree{"right"};
							my %hashTreeRight   = %$hashTreeRightRef;
							
							my $hashTreeRight2Ref = $hashTreeRight{"right"};
							my %hashTreeRight2    = %$hashTreeRight2Ref;
							
							my $hashTreeRight3Ref = $hashTreeRight2{"right"};
							
							my $iFound = 0;	
							my $j;	
							for ( $j = $i - 1; $j >= 0; $j--)
							{
								my $hashTreeForElseRef = $anArray[$j];
								if (ref($hashTreeForElseRef) && $hashTreeForElseRef =~ /HASH/ ) 
								{
									my %hashTreeForElse = %$hashTreeForElseRef;
									if ( $hashTreeForElse{"oper"} eq "=" )
									{
										my $hashTreeForElseLeftRef = $hashTreeForElse{"left"};
										my %hashTreeForElseLeft    = %$hashTreeForElseLeftRef;
										if ( $hashTreeForElseLeft{"oper"} eq "var" )
										{
											if ( $hashTreeForElseLeft{"name"} eq $name )
											{
												$iFound = 1;
												
												my $hashTreeForElseRightRef = $hashTreeForElse{"right"};
												my %hashTreeRight3 = (
														oper  => ',',
														left  => $hashTreeRight3Ref,
														right => $hashTreeForElseRightRef
												);
												$hashTreeRight2{"right"} = \%hashTreeRight3;
												$hashTreeRight{"right"} = \%hashTreeRight2;
												$hashTree{"right"} = \%hashTreeRight;
												$anArray[$i] = \%hashTree;
												last;
											} # end if
										} #end if
									} #end if
								} #end if
							} #end for ( my $j = $i - 1; $j >= 0; $j--)
							
							if ( $iFound )
							{
								splice(@anArray,$j,1);
								$iFoundOneIfStatement = 1;
								$i = $i - 1;
							}
						} #if ( $hashTreeRight{"fname"} eq "IF" )
					} # if ( $hashTree{"oper"} eq "=" )
				}
			}
		}
		
		if ( $iFoundOneIfStatement )
		{
			$arrayRef = \@anArray;
			( $arrayRef, $name ) = obtainCategoricalVariableFromSetOfIfStatements($arrayRef,$name);
		}
	}

	
	return ( $arrayRef, "OK");
}


sub obtainCategoricalVariableFromSetOfIfStatements
{
	
	my $arrayRef = $_[0];
	my $name     = $_[1];
	
	my $iFoundOneIfStatement = 0;
	
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = 0; $i <= $#anArray; $i++)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( $hashTree{"oper"} eq "=" )
				{
					my $hashTreeRightRef = $hashTree{"right"};
					my %hashTreeRight    = %$hashTreeRightRef;
					my $name = "";
					
					if ( $hashTreeRight{"fname"} eq "IF" )
					{
						my $hashTreeLeftRef = $hashTree{"left"};
						my %hashTreeLeft    = %$hashTreeLeftRef;
												
						my $hashTreeRightRef = $hashTree{"right"};

						if ( $hashTreeLeft{"oper"} eq "var" )
						{
						    printTree($hashTreeRightRef, 0, *STDOUT, "Right Tree to check");
						    printTree($hashTreeLeftRef, 0, *STDOUT, "Left Tree to check");
						    
						    $name = getSubTree($hashTreeLeftRef,"name");
						    my @treeLocation = ("right","left","left","name");
							my $varName   = getSubTree($hashTreeRightRef,\@treeLocation);
							@treeLocation = ("right","right","left");
							my $valResult = getSubTree($hashTreeRightRef,\@treeLocation);
							@treeLocation = ("right","left","right","val");
							my $testVal   = getSubTree($hashTreeRightRef,\@treeLocation);
							
							my %treeForThisInstance = (
								varName   => $varName,
								valResult => $valResult
							);
							
							my %treeForVariable = ();
							
							unless ( $IfThenExpressionsForVariables{$name} )
							{
								$IfThenExpressionsForVariables{$name} =  \%treeForVariable;
							}
							else
							{
								my $treeForVariableRef = $IfThenExpressionsForVariables{$name};
								%treeForVariable = %$treeForVariableRef;
							}
							
							$treeForVariable{$testVal} = \%treeForThisInstance;
							$IfThenExpressionsForVariables{$name}  = \%treeForVariable;
							
						} #if ( $hashTreeRight{"fname"} eq "IF" )
					} # if ( $hashTree{"oper"} eq "=" )
				}
			}
		}
		
		if ( $iFoundOneIfStatement )
		{
			$arrayRef = \@anArray;	
		}
	}
	
	return ( $arrayRef, "OK");
}

					
sub addNumericVariable 
{
	my ( $varNameWithoutSuffix, $iNumber, $valueToAdd ) = @_;
	 
	my $treeForVariableRef = $variablesWithNumericSuffixes{$varNameWithoutSuffix};

	my %treeForVariable = ();
	unless ( $treeForVariableRef )
	{
		$treeForVariableRef = \%treeForVariable;
	}
	else
	{
		%treeForVariable = %$treeForVariableRef;
	}
	
	$treeForVariable{$iNumber} = $valueToAdd;
	$variablesWithNumericSuffixes{$varNameWithoutSuffix}  = \%treeForVariable;
	
	if ( $varNameWithoutSuffix eq "ERR" )
	{
		my $completeVariableName = $varNameWithoutSuffix . $iNumber;
		$variablesWithNumericSuffixes{$completeVariableName}++;
	}

}
						

sub analyzeLHSVariables
{
	
	my $arrayRef = $_[0];
	my $processingMethodsRef = $_[1];
		
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
	
		my @anArray = @$arrayRef;
		for ( my $i = 0; $i <= $#anArray; $i++)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
				my %hashTree = %$hashRef;
				
				if ( $hashTree{"oper"} eq "=" )
				{
					my $hashTreeRightRef = $hashTree{"right"};
					my %hashTreeRight    = %$hashTreeRightRef;
					my $name = "";
					
					my $hashTreeLeftRef = $hashTree{"left"};
					my %hashTreeLeft    = %$hashTreeLeftRef;
											
					if ( $hashTreeLeft{"oper"} eq "var" )
					{					
						#Name of variable.		
						my $varName = $hashTreeLeft{"name"};
						$varName =~ s/\(\{\}\)//g;
						my $varNameWithoutSuffix = substr($varName,0,length($varName)-1);
						my $lastCharacter = substr($varName,-1);
						unless ( $lastCharacter =~ /\d/ )
						{
							$variablesWithoutNumericSuffixes{$varName} = 1;
							next;
						}
						
						addNumericVariable($varNameWithoutSuffix,$lastCharacter,$hashTreeRightRef);
						
						my $expression = getExpression($hashTreeRightRef,$processingMethodsRef);
						
						#Do this in the Winbugs plane...
						if ( $expression =~ /1\/\(1\+\(EXP\(\-(.*)\)\)\)/ )
						{
							my $variableFound = $1;
							$logitFunctions{$variableFound} = $varName;
							$variableFound =~ s/\[iObs,|\]//g;
							$logitFunctions{$variableFound} = $varName;
							#hack on 01/20
							$varName = substr($varName,0,length($varName)-1);
							$inverseLogitFunctions{$varName} = $variableFound;
						}
						
					} # if ( $hashTree{"oper"} eq "=" )
				}
			}
		}
	}
	
	return ( $arrayRef, "OK");
}


sub checkForVariable
{
	
	my $hashTreeRef = $_[0];
	my $iFound = 0;
	
	if ( ref($hashTreeRef) && $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;
		if ( $hashTree{"oper"} eq "var" )
		{					
			#Name of variable.		
			my $varName = $hashTree{"name"};
			$iFound = 1;
		}
	}	
	
	return ( $iFound);
}

sub analyzeVariable
{
	my $hashTreeRef = $_[0];
	
	if ( ref($hashTreeRef ) && $hashTreeRef =~ /HASH/)
	{
		my %hashTree = %$hashTreeRef;

		if ( $hashTree{"oper"} eq "var" )
		{	
			my $varNameWithoutSuffix;
			my $lastCharacter;
							
			#Name of variable.		
			my $varName = $hashTree{"name"};
			if ($varName =~ /diff\((.*)\((.*)\)/)
			{
				$varName = $1;
			}
			if ( $varName =~ /\)|\)|\[|\]/)
			{
				$varNameWithoutSuffix = $varName;
				$varNameWithoutSuffix =~ s/\((.*)\)//g;
				$lastCharacter = $1;
			}
			else
			{
				$lastCharacter = substr($varName,-1);
				if ( $lastCharacter =~ /\d/ )
				{
					$varNameWithoutSuffix = substr($varName,0,length($varName)-1);
				}
			}
			
			if ( $varNameWithoutSuffix )
			{
				addNumericVariable($varNameWithoutSuffix,$lastCharacter,1);
			}
			else
			{
				$variablesWithoutNumericSuffixes{$varName}++;
			}
		}	
	}
	
	return ( $hashTreeRef, "OK");
}

sub checkForArrayWithOneElement
{
	my $arrayRef = $_[0];
	my $name        = $_[1];
	
	my $iFound = 0;
	if ( ref($arrayRef) )
	{
		if ( $arrayRef =~ /ARRAY/ )
		{
			my @array = @$arrayRef;
			if (scalar(@array) == 1 )
			{
				if ( ref($array[0]))
				{
					$iFound = 1;
					if ( $debug )
					{
						print "Just one array item here\n";
					}
				}
			}
		}
		elsif( $arrayRef =~ /HASH/ )
		{
			my %hashTable = %$arrayRef;
			if (scalar(keys(%hashTable)) == 1 )
			{
				if ( $hashTable{"vector"} )
				{
					$iFound = 1;
					if ( $debug )
					{
						print "Just one hash item here\n";
					}

				}
			}
		}
	}
	return($iFound);
}


sub deleteTautology
{
	my $arrayRef = $_[0];
	my $name        = $_[1];
	
	my $iFound = 0;
	if ( ref($arrayRef) && $arrayRef =~ /ARRAY/ )
	{
		my @anArray = @$arrayRef;
		for ( my $i = $#anArray; $i >= 0; $i--)
		{
			my $hashRef = $anArray[$i];
			if (ref($hashRef) && $hashRef =~ /HASH/ ) 
			{
	
				my %hashTree = %$hashRef;
		
				if ( scalar(%hashTree) == 0 )
				{
					$iFound = 1;
					print "Error in delete Tautology routine\n";
					exit;
				}
				
				if ( $hashTree{"oper"} eq $assignmentOperator)
				{
					my $rightTreeRef = $hashTree{"right"};
					if ( !ref ( $rightTreeRef ) )
					{
						return ( $arrayRef, "OK");
					}
					my %rightTree = %$rightTreeRef;

					my $leftTreeRef = $hashTree{"left"};
					if ( !ref ( $leftTreeRef ) )
					{
						return ( $arrayRef, "OK")
					}
					my %leftTree = %$leftTreeRef;

					my $leftVariableName  = $leftTree{"name"};
					my $rightVariableName = $rightTree{"name"};

					if ( $leftVariableName ne "" && $leftVariableName eq $rightVariableName )
					{
						splice(@anArray,$i,1);
						$iFound = 1;
					}
				}
				
			}
		}
		
		if ( $iFound )
		{
			$arrayRef = \@anArray;
		}	

	}
	return ( $arrayRef, "OK");
}


sub deleteUseOfArrayWithOneElement
{
	my $arrayRef    = $_[0];
	my $name        = $_[1];
	
	if ( ref($arrayRef))
	{
		if ($arrayRef =~ /ARRAY/ )
		{
			my @anArray = @$arrayRef;
			my $hashRef = $anArray[0];
			$arrayRef = $hashRef;
		}
		elsif ($arrayRef =~ /HASH/)
		{
			my %myHash = %$arrayRef;
			my $tempRef = $myHash{"vector"};
			if ( $tempRef ne "" )
			{
				$arrayRef = $tempRef;
				if ( $debug )
				{
					print "did not delete 1 element array";
				}

			}
		}
	}
	
	return ( $arrayRef, "OK");
}


sub checkForNames
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
		
	my $iFound = 0;
		
	if ( ref($hashRef) && $hashRef =~ /HASH/ && ref($mapOfNames) )
	{
		
		my %hashTree = %$hashRef;
		my %hashOfNames = %$mapOfNames;
		my $name = $hashTree{"name"};
		
		if ( defined($name) && $name ne "" )
		{
			if ( defined($hashOfNames{$name}) && $hashOfNames{$name} ne "" )
			{
				$iFound = 1;
			}
		}
	}
	
	return ( $iFound);
}

sub checkForNamesUsingOddRules
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
		
	my $iFound = 0;
		
	if ( ref($hashRef) && $hashRef =~ /HASH/ && ref($mapOfNames) )
	{
		
		my %hashTree = %$hashRef;
		my %hashOfNames = %$mapOfNames;
		my $name = $hashTree{"name"};

	    if ( defined($name) && ( $name ne "" )  )
		{ 
		    unless ( $name =~ /^S\d/)
		    {
			    if ( defined( $hashOfNames{$name}) && ($hashOfNames{$name} ne "" ) )
			    {
			        my $variablesTreeRef = $hashOfNames{$name};
			        my %variablesTree    = %$variablesTreeRef;
			        my $variable         = $variablesTree{"variables"};
			        unless ( $variable =~ /,/)
			        {
				        $iFound = 1;
				    }
			    }
		    }
		}
	}
	
	return ( $iFound);
}


sub replaceNames
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
	
	my %hashTree = %$hashRef;
	my %hashOfNames = %$mapOfNames;
	
	my $iFound = 0;
	
	my $name = $hashTree{"name"};
	
	if ( $name ne "" )
	{
		if ( $hashOfNames{$name} ne "" )
		{
			$hashTree{"name"} = $hashOfNames{$name};
			$iFound = 1;
		}
	}
	
	if ( $iFound )
	{
		$hashRef = \%hashTree;
	}
	
	return ( $hashRef, "OK" )
}

sub replaceNamesAndStoreThoseUsed
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
	
	my %hashTree = %$hashRef;
	my %hashOfNames = %$mapOfNames;
	
	my $iFound = 0;
	
	my $name = $hashTree{"name"};

	if ( $name ne "" )
	{
		if ( $hashOfNames{$name} ne "" )
		{
			$hashTree{"name"} = $hashOfNames{$name};
			push(@arrayOfInfoAsSideEffectsYesThisIsBad,$name);
			$iFound = 1;
		}
	}
	
	if ( $iFound )
	{
		$hashRef = \%hashTree;
	}
	
	return ( $hashRef, "OK" )
}

sub replacePKNamesUsingOddRules
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
	
	my %hashTree = %$hashRef;
	my %hashOfNames = %$mapOfNames;
	
	my $iFound = 0;
	
	my $name = $hashTree{"name"};

	if ( $name ne "" )
	{
		if ( $hashOfNames{$name} ne "" )
		{
			$hashTree{"name"} = $hashOfNames{$name};
			push(@arrayOfInfoAsSideEffectsYesThisIsBad,$name);
			$iFound = 1;
		}
	}
	
	if ( $iFound )
	{
		if ( $name ne ""  )
		{ 
		    unless ( $name =~ /^S\d/)
		    {
			    if ( $hashOfNames{$name} ne "" )
			    {
			        my $variablesTreeRef = $hashOfNames{$name};
			        my %variablesTree    = %$variablesTreeRef;
			        my $variable         = $variablesTree{"variables"};
			        unless ( $variable =~ /,/)
			        {
				        $iFound = 1;
				        $hashTree{"name"} = $variable;
                        $hashRef = \%hashTree;
				    }
			    }
		    }
		}

	}
	
	return ( $hashRef, "OK" )
}


sub replaceNamesUsingInverseMap
{
	my $hashRef = $_[0];
	my $mapOfNamesRef = $_[1];

	my %hashTree = %$hashRef;
	my %mapOfNames = %$mapOfNamesRef;
	
	my $iFound = 0;
	
	my $name = $hashTree{"name"};
	
		
	#skip observations.
	unless ( $name =~ /^S.*/)
	{

	    if ( $name ne "" )
	    {
		    if ( $mapOfNames{$name} ne "" )
		    {
			    $hashTree{"name"} = $mapOfNames{$name};
			    push(@arrayOfInfoAsSideEffectsYesThisIsBad,$name);
			    $iFound = 1;
		    }
	    }
    	
	    if ( $iFound )
	    {
		    $hashRef = \%hashTree;
	    }
    }
    	
	return ( $hashRef, "OK" )
}


sub replaceNameWithParseTree
{
	my $hashRef = $_[0];
	my $mapOfNames = $_[1];
	
	my %hashTree = %$hashRef;
	
	if ( ref($mapOfNames) && $mapOfNames =~ /HASH/ )
	{
	    my %hashOfNames = %$mapOfNames;
    	
	    my $name = $hashTree{"name"};
    	
	    if ( $name ne "" )
	    {
		    if ( $hashOfNames{$name} ne "" )
		    {
			    $hashRef =  $hashOfNames{$name};
		    }
	    }
	}
	else
	{
	    print "Problem in replace names with trees\n";
	    print "-------------------------------------\n";
	}
	return ( $hashRef, "OK" )
}



sub checkForUseOfVector
{

    if ( scalar(@_) < 2 )
    {
        print "Oops\n";
        exit;
    }
	my $hashTreeRef = $_[0];
	my $name        = $_[1];
	
	my $iFound = 0;
	if ( ref($hashTreeRef) && $hashTreeRef =~ /HASH/ )
	{
		my %hashTree = %$hashTreeRef;
		if ( defined($hashTree{"fname"}) && $hashTree{"fname"} eq $name )
		{
			$iFound = 1;
		}
		else
		{
			my $nameToExamine = $hashTree{"name"};
			if ( defined($nameToExamine))
			{
			    $nameToExamine =~ s/[\(\]\.*|[\)\]].*//g;
			    if ( $nameToExamine eq $name )
			    {
				    $iFound = 1;
			    }
			}
		}
	}
	return ( $iFound);
}


sub checkForUseOfFunction
{
	my $hashTreeRef = $_[0];
	my $name        = $_[1];
	
	my $iFound = 0;
	if ( ref($hashTreeRef) && $hashTreeRef =~ /HASH/ )
	{
		my %hashTree = %$hashTreeRef;
		if ( $hashTree{"fname"} eq $name )
		{
			$iFound = 1;
		}
		else
		{
			my $nameToExamine = $hashTree{"name"};
			$nameToExamine =~ s/[\(\]\.*|[\)\]].*//g;
			if ( $nameToExamine eq $name )
			{
				$iFound = 1;
			}
		}
	}
	return ( $iFound);
}

sub checkForUseOfFunctionAndVariable
{
	my $hashTreeRef		= $_[0];
	my $tagsRef         = $_[1];
	
	my %tags            = %$tagsRef;
	
	my $nameOfFunction  = $tags{"nameOfFunction"};
	my $nameOfVariable  = $tags{"nameOfVariable"};
	my $nameFound       = "";
	
	my $iFound = 0;
	if ( ref($hashTreeRef) && $hashTreeRef =~ /HASH/ )
	{
		my %hashTree = %$hashTreeRef;
		if ( defined($hashTree{"fname"}) && ( $hashTree{"fname"} =~ /^$nameOfFunction$/i ) )
		{
			$iFound = 1;
		}
		else
		{
			my $nameToExamine = $hashTree{"name"};
			if ( defined($nameToExamine) )
			{
			    $nameToExamine =~ s/[\(\]\.*|[\)\]].*//g;
			    if ( ( $nameToExamine eq $nameOfFunction ) )
			    {
				    $iFound = 1;
			    }
			}
		}
		if ( $iFound )
		{
			my $expression = getExpression($hashTreeRef,"");
			if ( $expression =~ /\W$nameOfVariable\W/)
			{
				$nameFound = $nameOfVariable;
			}
		}
	}
	return ( $nameFound);
}

sub checkForCharactersGiven
{
	my $string = $_[0];
	my $char1  = $_[1];
	my $char2  = $_[2];
	my $iFound = 0;
	
	if ( ! ref($string) )
	{
		my $charWithBackslash = '\\' . $char1;
		if( grep(/$charWithBackslash/,$string))
		{
			$iFound = 1;
		}
	}
	return($iFound);
}


sub parsePRED
{

	my ($treeRef, $state ) = parseEquations($_[0]);

	return ( $treeRef, $state );

}

sub parseDES
{

	my ($ref, $state ) = parseEquations($_[0]);
	
	return ( $ref, $state );

}

sub parseSCAT
{
	my $string = $_[0];
	
	my ($ref,$state) = parseListStatement(\$string);
	return ($ref,"SCAT");


}

sub parseERROR
{

	my $errorLines = $_[0];
	if ( $errorLines =~ m/ONLY OBSERVATIONS/)
	{
		print "Only observations for errors\n";
		$errorLines =~ s/\(ONLY OBSERVATIONS\)//g;
	}
	
	my ($ref, $state ) = parseEquations($errorLines);
	$state = "ERROR";
		
	return ( $ref, $state );

}

sub parseTHETA
{
	my ($treeRef, $state) = parseSetsOfParentheses($_[0]);
	
	traverseTreeParseParentheses($treeRef,"",0);

	return ( $treeRef,$state);

}

sub parseSIGMA
{
	my ( $treeRef, $state ) = parseLinesOfLists($_[0]);
	return ( $treeRef, $state );

}

sub parseSetsOfParentheses
{
	my $string    = $_[0];
	my $state     = $_[1];
	
	my $separator = "\n";
	my (@lines ) = split(/$separator/,$string);
	my @expressions = ();
	
	my @trees = ();
	
	my $iLine = 0;

	foreach my $line ( @lines)
	{
		my ( $headAndTailRef,$state) = parseHeadAndTail($line,$commentCharacter,0);
		my %headAndTail = %$headAndTailRef;
		my $expr    = $headAndTail{"head"};
		my $comment = $headAndTail{"tail"};
		 
		my %tree = ();
		
		if ( defined($expr) && $expr ne "" )
		{
			if ( $expr =~ /\(/)
			{
				 (my $treeForExpressionRef, $state) = parseParentheses($expr);

		 		 %tree = (
					"variable"   => $treeForExpressionRef,
					"comment"    => $comment
				);
			}
			else 
			{
				my %treeForExpression =
				(
					"left"			=> "0",
					"right"			=> "",
					"middle"		=> $expr,
					"terminal"		=> $expr,
					"oper"			=> "PARENS"
				);
				%tree = (
					"variable"   => \%treeForExpression,
					"comment"    => $comment
				);

			}
		}
		else 
		{
		 	 %tree = (
				"comment" => $comment
			);		
		}
		
		$trees[$iLine] = \%tree;
		$iLine++;

    }
	
	return ( \@trees, $state );

}


sub parseListOfValues
{
	my $string    = $_[0];
	my $state     = $_[1];
	
	my $separator = "\\n";
	my (@lines ) = split(/$separator/,$string);
	my @expressions = ();
	
	my @trees = ();
	my $iLine = 0;

	foreach my $line ( @lines)
	{
		my ( $headAndTailRef,$state ) = parseHeadAndTail($line,$commentCharacter,0);
		my %headAndTail = %$headAndTailRef;
		my $expr = $headAndTail{"head"};
		my $comment = $headAndTail{"tail"};
				 
		 #Modify the NONMEM line so that it can be defined in terms of a context free grammar.  Here '*' denotes monoid composition,
		 #that is, * as concatentation of lists
		 $expr =~ s/\)\(/\)\*\(/g;
		 
		 my %tree = ();
		 
		 if ( $expr ne "" )
		 {
			 my $ArithEnv = new Math::Expression;
			 my $treeForExpression = $ArithEnv->Parse($expr);
		 	 %tree = (
				"variable"   => $treeForExpression,
				"comment" => $comment
			);
		} else {
		 	 %tree = (
				"comment" => $comment
			);		
		}
		$trees[$iLine] = \%tree;
		$iLine++;

    }
	return ( \@trees, $state );

}


sub parseLinesOfLists
{
	my $string    = $_[0];
	my $state     = $_[1];
	
	my $separator = "\\n";
	my @lines = split(/$separator/,$string);
	
	my @trees = ();
	
	my $iLine = 0;
	foreach my $line ( @lines)
	{
		my ( $headAndTailRef,$state ) = parseHeadAndTail($line,$commentCharacter,0);
		my %headAndTail = %$headAndTailRef;
		my $expr =    $headAndTail{"head"};
		my $comment = $headAndTail{"tail"};
		
		my $listRef;
		($listRef,$state) = parseList(\$expr,"\\s+");
		my %tree = ();

		my $used = 0;
		if ( scalar(@$listRef) > 0 )
		{
			$tree{"vector"} = $listRef;
			$used++;
		}
		
		if ( $comment ne "" )
		{
			$tree{"comment"} = $comment;
			$used++;
		}
		
		if ( $used > 0)
		{
			$trees[$iLine] = \%tree;
			$iLine++;
		}
		else
		{
			;
		}

    }
    
	return ( \@trees, $state );

}

sub parseSUBROUTINE
{
    my ($listRef,$state) = parseList(\$_[0], "\\s+|,");
    
    my $ref;
	($ref,$state) = parseAttributeValuePairsInList($listRef);
	$state = "SUBROUTINE";
	return ( $ref, $state );

}

sub parseHeadAndTail
{
	my $string    = $_[0];
	my $separator = $_[1];
	my $keepSeparator = $_[2];
	
	my $comment = "";
	my $head = "";
	my $tail = "";
	my $right = "";
	
	$string =~ s/^[\s+|\n]*//g;
	while ( substr($string,0,1) eq $commentCharacter )
	{
		my @commentLines = split(/\n/,$string, 2);
		$comment = $commentLines[0];
		if ( scalar(@commentLines) > 1 )
		{
		    $string = $commentLines[1];
		    $string =~ s/^[\s+|\n]*//g;
		}
		else
		{
		    $string = "";
		}
	}
	
	my @headAndTail = split(/$separator/,$string, 2);
	
	if ( scalar(@headAndTail) >= 2 )
	{
        ( $head, $tail ) = @headAndTail;
    }
    else
    {
        $head = $headAndTail[0];
    }
    
	if ( $keepSeparator )
	{
		$tail = substr($string,length($head));
	}
		
		
	$tail=~ s/^[\s+|\n]*//g;
	
	my $state = "OK";

	my %tree =
	(
		head => $head,
		tail => $tail,
		right => $right
	);
	
	return (\%tree,$state);
}

sub parseList
{
	my $stringRef = $_[0];
	my $separator = $_[1];
	my $state = "OK";
	
	my $string = $$stringRef;
	
	my @list = ();
	if ( defined($string))
	{
	    $string =~ s/^\s+//g;
	    @list = split(/$separator/,$$stringRef);
	}    
	return (\@list,"OK");

}

sub parseAttributeValuePairsInList
{

	my $listRef = $_[0];
	my %attributes = ();
	my $used = 0;
	my $iListLength = scalar(@$listRef);
	for ( my $iList = $iListLength-1; $iList >= 0; $iList--)
	{
		if ( @$listRef[$iList] =~ /=/ )
		{
			my ( $attribute, $value ) = split($assignmentOperator,@$listRef[$iList]);
			$attributes{$attribute} = $value;
			splice(@$listRef,$iList,1);
			$used++;
		}
	}
	
	if ( $used == $iListLength )
	{
		$listRef = \%attributes;
	}
	elsif ( $used > 0 )
	{
		push(@$listRef,\%attributes);
	}

	my $state = "OK";
	return ($listRef,$state);

}

sub parseFunctionCall
{
	my $stringRef = $_[0];
	my $state     = $_[1];
	
	my $separator = "\\(";
	my ($functionName, $argumentsAndParens ) = split(/$separator/,$$stringRef);

	$separator = "\\)";
	my ($arguments ) = split(/$separator/,$argumentsAndParens);
	
	$separator = ",";
	my @list = split(/$separator/,$arguments);
	
	my @tree = (
		$functionName,\@list);
	
	return (\@tree,"OK");

}

sub parseAttributeValuePairs
{
	my $pairsRef = $_[0];
	my $attributesRef = $_[1];
	my %attributeValues = ();
	
	foreach my $pair (@$pairsRef)
	{
		 my ( $attribute, $value ) = split(/=/,$pair);
		 $attributeValues{$attribute} = $value;
	}

	return ( \%attributeValues,"OK");
}

sub parseExpressions
{
	my $stringRef = \$_[0];
	my $state     = $_[1];
	
	my $separator = "\\n|\\s+";
	
	my (@lines ) = split(/$separator/,$$stringRef);
	my @expressions = ();

	my $ArithEnv = new Math::Expression;

	foreach my $rightSide ( @lines)
	{
		
		$rightSide =~ s/^\s*|\s*$//g;
		
		#Remove equals signs and spaces.
		$rightSide =~ s/=|\s+//g;
		next if $rightSide eq "";
		
		my $tree2 = $ArithEnv->Parse($rightSide);

		if ( !ref($tree2) )
		{
			print "ERROR in right side: $rightSide\n";
		}

		push(@expressions,$tree2);
	}
	return ( \@expressions,"state");

}

sub isStatement
{
	my $line = $_[0];
	my $isStatement = 0;
	if ( $line =~ m/IF[\W]|$assignmentOperator|ENDIF|ELSE|EXIT/)
	{
		$isStatement = 1;
	}
	return($isStatement);

}

sub parseEquations
{
	my $stringRef = \$_[0];
	my $state     = $_[1];
	
	print STDOUT "In parse equations ", $$stringRef, "\n";
	
	my (@lines ) = split(/$lineSeparator/,$$stringRef);
	my @equations = ();
	my $separator = $assignmentOperator;

	my $ArithEnv = new Math::Expression;

	my $conditional = "";
	my %forLoop = ();
	
	foreach ( my $iLine = 0; $iLine < scalar(@lines); $iLine++)
	{
		my $lineAndComment = $lines[$iLine];
		
		my ( $line, $comment ) =split($commentCharacter,$lineAndComment); 
		
		next unless defined($line);
		
		if ( $line =~ /ENDIF/i)
		{
			$conditional = "";
			next;
		} 
		elsif ($line =~ /ELSE/i)
		{
			$conditional = "NOT\(" . $ conditional . "\)";
			next;
		}
		elsif ($line =~ /EXIT/i)
		{
			print "Error - Exit not yet handled\n";
			next;
		}
		
		if ( $line =~ /\}/i)
		{
			%forLoop = ();
			next;
		}
		
		$line =~ s/^\s*|\s*$//g;
		
		next unless ( $line =~ /\w/);
	
		my ( $leftSide, $rightSide ) = split($assignmentOperator,$line);
		$line=~ m/($assignmentOperator)/;
		my $assignmentOperatorUsed = $1;
		
		while ( my $extraLineAndComment = $lines[$iLine+1] )  #To do: Handle additional comments.
		{
			last unless ( $extraLineAndComment =~ /[a-zA-Z]/);
			my ( $extraLine, $extraComment ) =split($commentCharacter,$extraLineAndComment); 
			last if &isStatement($extraLine);
			$rightSide .= $extraLine;
			$iLine++;
		}
		
		if ( $leftSide eq "" or $rightSide eq "" )
		{
			if ( $leftSide =~ /.*IF\s*\((.*)\)\s*THEN/i)
			{
				$conditional = $1;
			}
			elsif ( $leftSide =~ /.*FOR\s*\((.*)\).*/i)
			{
				my $forLoopConditional = $1;
				$forLoop{"conditional"} = $forLoopConditional;
				if ( $forLoopConditional =~ /(.*)\s+in\s+(.*)/g)
				{
					$forLoop{"loopVariable"}  = $1;
					$forLoop{"setForForLoop"} = $2;
				}
				else
				{
					print "Internal error when handling for loop\n";
					printTree($stringRef,0,$printHandle,"");
					exit;
				}
			}
			elsif ( $leftSide =~ /\w/)
			{
				print "Note on line: $line -- no equation given in this line, in $$stringRef\n";
				#printTree($stringRef,0,$printHandle,"");
			}
			next;
		}	
		
		my $temporaryConditional = 0;
		if ( $leftSide =~ /.*IF\s*\((.*)\)(.*)/)
		{
			$temporaryConditional = 1;
			$conditional = $1;
			$leftSide  = $2;
			if ( $leftSide =~ /.*THEN.*/)
			{
				print "Internal Error:\n";
				print $leftSide;
				exit;
			}
		}	
		
		if ( $conditional ne "" )
		{
			$conditional =~ s/\.GT\./\>/g;
			$rightSide = "IF(" . $conditional . ", " . $rightSide . ")";	
			my $rhsTreeRef = $ArithEnv->Parse($rightSide);
			if ( $rhsTreeRef eq "" or ! ( $rhsTreeRef =~ /HASH/))
			{
				print "Error when handling if-then conditional\n";
				exit;
			}

		}
		
		if ( scalar(%forLoop) != 0 )
		{
			$rightSide = "FORLOOP(" . $forLoop{"loopVariable"} . "," . $forLoop{"setForForLoop"} . "," . $rightSide . ")";	
		}
		if ( $temporaryConditional > 0 )
		{
			$conditional = "";
		}

		my $tree1 = $ArithEnv->Parse($leftSide);
		my $tree2 = $ArithEnv->Parse($rightSide);
		
		if ( ! ref($tree1) )
		{
			print "ERROR in left side: $line\n";
		}
		elsif ( !ref($tree2) )
		{
			print "ERROR in line $line, within right side $rightSide\n";
			#Check for use of . without a zero or other number ahead of it.
			if ( $rightSide =~ /[^0-9]\./)
			{
			    #rph improve this -- add check for decimal before . in the replacement. 

			    my $modifiedRightSide = $rightSide;
			    $modifiedRightSide =~ s/\./ 0\./;
			    $tree2 = $ArithEnv->Parse($modifiedRightSide);
			    if ( ! ref ( $tree2 ) )
			    {
			    	print "Was not able to fix this by prepending a 0 to a decimal point\n";
					print $rightSide, "\n";
					$tree2 = $rightSide;
			    }
			    else
			    {
				    print "Believed this was resolved by prepending a 0 to a decimal point\n";
			    }
		    }
		    else
		    {
		        #rph improve this -- try anyway.
			    $rightSide =~ s/\./ 0\./;
			    $tree2 = $ArithEnv->Parse($rightSide);
			    if ( ! ref ( $tree2 ) )
			    {
			        
			    }
			    else
			    {
				    print "Believed this was resolved by prepending a 0 to a decimal point\n";
			    }
		    }
		}
			
		my %equation =
		(
			'left'  => $tree1,
			'right' => $tree2,
			'oper'  => $assignmentOperatorUsed
		);
		
		push(@equations,\%equation);
	}
	return ( \@equations, $state);

}

sub parseOneCharacterPair
{
	my $rightSide    = $_[0];
	my $leftParens   = $_[1];
	my $rightParens  = $_[2];
			
	my @leftParensSet = ();
	my $iLeftParens = 0;
	my @rightParensSet = ();
	my $iRightParens = 0;
	my @parenthesesLevelLeft = ();
	my @parenthesesLevelRight = ();
	
	my $iLevel = 0;	

	my @letters = split("",$rightSide);

	for ( my $i = 0; $i <= $#letters; $i++)
	{
		my $letter = $letters[$i];
		if ( $letter eq $leftParens)
		{
			$parenthesesLevelLeft[$iLeftParens] = ++$iLevel;
			$leftParensSet[$iLeftParens++] = $i;
		}
		if ( $letter eq $rightParens)
		{
			$parenthesesLevelRight[$iRightParens] = $iLevel--;
			$rightParensSet[$iRightParens++] = $i;
		}
	}
		
	my $iRightMatch;
	for ($iRightMatch = 0; $iRightMatch <= $#parenthesesLevelRight; $iRightMatch++)
	{
		last if ( $parenthesesLevelRight[$iRightMatch] == 1);
	}
	
	my $iLocationOfLeftParens  = $leftParensSet[0];

	my $iLocationOfRightParens = $rightParensSet[$iRightMatch];
	
	my $iLength = $iLocationOfRightParens - $iLocationOfLeftParens -1;
						
	my $firstString  = substr($rightSide,0,$iLocationOfLeftParens);
	my $middleString = substr($rightSide,$iLocationOfLeftParens+1,$iLength);
	my $lastString   = substr($rightSide,$iLocationOfRightParens+1);

	my %expressionTree = 
	(
		"left"			=> $firstString,
		"right"			=> $lastString,
		"middle"		=> $middleString,
		"oper"			=> "Bracket"
	);

	my $state = "OK";
	return (\%expressionTree,$state);
}

sub parseOneSetOfCommas
{
	my $rightSide = $_[0];
			
	my @leftParensSet = ();
	my $iLeftParens = 0;
	my @rightParensSet = ();
	my $iRightParens = 0;
	my @parenthesesLevelLeft = ();
	my @parenthesesLevelRight = ();
	
	my $iLevel = 0;	

	$rightSide =~ s/\s+|^,//g;
	my @parts = split(/,/,$rightSide);

	my ($arrayWithValuePairsRef, $state ) = parseAttributeValuePairsInList(\@parts);

	my %expressionTree = 
	(
		"right"			=> $arrayWithValuePairsRef,
		"oper"			=> "COMMA"
	);

	$state = "OK";
	
	return (\%expressionTree,$state);
}

sub parseParentheses
{
	my $rightSide = $_[0];
			
	my @leftParensSet = ();
	my $iLeftParens = 0;
	my @rightParensSet = ();
	my $iRightParens = 0;
	my @parenthesesLevelLeft = ();
	my @parenthesesLevelRight = ();
	my @rightParensForLeft = ();
	my @firstChildForParens = ();
	
	my $iLevel = 0;	
	
	my @letters = split("",$rightSide);
	
	my @lastParensAtThisLevel = ();
	my @parentParens = ();
	my @nextParensAtThisLevel   = ();

	for ( my $i = 0; $i <= $#letters; $i++)
	{
		my $letter = $letters[$i];
		if ( $letter eq $leftParens)
		{
			$parenthesesLevelLeft[$iLeftParens] = ++$iLevel;
			$firstChildForParens[$iLeftParens] = -1;
			$lastParensAtThisLevel[$iLeftParens] = -1;
			$parentParens[$iLeftParens] = -1;
			$nextParensAtThisLevel[$iLeftParens] = -1;
			$rightParensForLeft[$iLeftParens] = -1;
			$leftParensSet[$iLeftParens++] = $i;
	
		}
		if ( $letter eq $rightParens)
		{
			$parenthesesLevelRight[$iRightParens] = $iLevel--;
			$rightParensSet[$iRightParens++] = $i;
		}
	}
	
	for ( my $iParens = 1; $iParens < $iLeftParens; $iParens++)
	{
		my $iParensLevel1 = $parenthesesLevelLeft[$iParens];
		for ( my $iParens2 = $iParens - 1; $iParens2 >= 0; $iParens2--)
		{
			if ( $parenthesesLevelLeft[$iParens2] == $iParensLevel1 )
			{
				if ( $nextParensAtThisLevel[$iParens] == -1 )
				{
					$nextParensAtThisLevel[$iParens2] = $iParens;
					if ( $lastParensAtThisLevel[$iParens] == -1)
					{
						$lastParensAtThisLevel[$iParens]  = $iParens2;
						#print "stuff: $iParensLevel1, $iParens, $iParens2\n";
						last;
					}
				}
			}
			elsif ( $parenthesesLevelLeft[$iParens2] < $iParensLevel1 )
			{
				if ( $parentParens[$iParens] == -1 )
				{
					$parentParens[$iParens] = $iParens2;
				}
				if ( $firstChildForParens[$iParens] == -1 )
				{
					$firstChildForParens[$iParens2] = $iParens;
					#$lastParensAtThisLevel[$iParens2] = -1;
				}
				last;
			}
		}
	}
	
	for ( my $iParens = 0; $iParens < $iLeftParens; $iParens++ )
	{
		$iLevel = $parenthesesLevelLeft[$iParens];
		my $iLocationForLeft = $leftParensSet[$iParens];
		for ( my $iParens2 = 0; $iParens2 < $iRightParens; $iParens2++)
		{ 
			my $iRightLocation = $rightParensSet[$iParens2];
			if ( $iLevel        == $parenthesesLevelRight[$iParens2] 
			&&	 $rightParensForLeft[$iParens] == -1
			&&   $iRightLocation > $iLocationForLeft )
			{
				$rightParensForLeft[$iParens] = $iParens2;
			}
		}
	}
	
	my @trees = ();
	my $iTree = 0;
	for ( my $iCurrentLevel = 1; $iCurrentLevel <= 1; $iCurrentLevel++ )
	{
		my @tree = ();

		for ( my $iParens = 0; $iParens <= $#parenthesesLevelLeft; $iParens++ )  
		{
			if ( $iCurrentLevel == $parenthesesLevelLeft[$iParens])
			{
				my $iLocationRightParens = $rightParensSet[$rightParensForLeft[$iParens]];
				#print "$iParens,$rightParensForLeft[$iParens],$rightParensSet[0]\n";
				my $iLength      = $iLocationRightParens - $leftParensSet[$iParens] - 1;

				my $iParent = $parentParens[$iParens];
				
				my	$iStartForParent = 0;
				my	$iEndForParent   = length($rightSide);
				
				if ( $iParent > -1 )
				{
					$iStartForParent = $leftParensSet[$iParent]+1;
					$iEndForParent   = $rightParensSet[$rightParensForLeft[$iParent]]-1;

				}
				if ( $lastParensAtThisLevel[$iParens] > -1 )
				{
					$iStartForParent = $rightParensSet[$rightParensForLeft[$lastParensAtThisLevel[$iParens]]]+1;
					#print "$iCurrentLevel, $iParens, $lastParensAtThisLevel[$iParens], $iStartForParent\n";
				}
				if ( $nextParensAtThisLevel[$iParens] > -1 )
				{
					$iEndForParent = $leftParensSet[$nextParensAtThisLevel[$iParens]]-1;
				}
				my $iStartOfWhatFollows = $iLocationRightParens + 1;
				
				my $firstString  = substr($rightSide,$iStartForParent,$leftParensSet[$iParens]-$iStartForParent);
				my $middleString = substr($rightSide,$leftParensSet[$iParens]+1,$iLength);
				my $lastString   = substr($rightSide,$iStartOfWhatFollows,$iEndForParent-$iStartOfWhatFollows+1);

				my %expressionTree = 
				(
					"left"			=> $firstString,
					"right"			=> $lastString,
					"middle"		=> $middleString,
					"terminal"		=> $middleString,
					"oper"			=> "PARENS"
				);
							
				push(@tree,\%expressionTree);
					
			}

		}
		$trees[$iTree++] = \@tree;

	}
	
	my $state = "OK";
	return (\@trees,$state);
}


sub printTree
{
	my $treeRef				= $_[0];
	my $iTreeLevel			= $_[1];
	my $temporaryFileHandle = $_[2];
	my $title				= $_[3];
	
	if ( $iTreeLevel == 0 )
	{ 
		if ( $temporaryFileHandle eq "" )
		{
			print "Possible error -- no file handle given in printTree\n";
			$temporaryFileHandle = *STDOUT;
		}
		print $temporaryFileHandle "\nStart of tree-------------------------\n";
		
		if ( defined($title))
		{
		    print $title;
		}
	}

	if (!ref($treeRef ) )
	{
	    if ( defined($treeRef) )
	    {
		    chomp $treeRef;
		    print $temporaryFileHandle "\n", " " x (4*$iTreeLevel);
		    print $temporaryFileHandle q('), $treeRef, q(');
		}
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			print $temporaryFileHandle "\n", " " x (4*$iTreeLevel);
			print $temporaryFileHandle "ARRAY = [";
			my $iElement = 0;
			foreach my $subTreeRef ( @$treeRef )
			{
				&printTree($subTreeRef,$iTreeLevel+1,$temporaryFileHandle,"");
				print $temporaryFileHandle ",", unless ++$iElement == scalar(@$treeRef);

			}
			print $temporaryFileHandle "\n", " " x (4*$iTreeLevel);
			print $temporaryFileHandle "]";
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
			print $temporaryFileHandle &$treeRef;
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			print $temporaryFileHandle "\n", " " x (4*($iTreeLevel)),  "HASH = (";
			foreach my $key ( keys(%hashTree)) 
			{
				print $temporaryFileHandle "\n", " " x (4*($iTreeLevel+1));
				print $temporaryFileHandle "$key => ";
				if (!ref($hashTree{$key} ))
				{
				    if ( defined($hashTree{$key}))
				    {
					    print $temporaryFileHandle q('),$hashTree{$key},q(');
					}
				}
				else
				{
					&printTree($hashTree{$key},$iTreeLevel+1,$temporaryFileHandle,"");
				}
			}
			print $temporaryFileHandle "\n", " " x (4*$iTreeLevel),")";

		}
		elsif ($treeRef =~ /.*SCALAR.*/)
		{
			print $temporaryFileHandle "\n", " " x (4*($iTreeLevel));
			if ( defined($$treeRef))
			{
			    print $temporaryFileHandle "$$treeRef";
			}
		}
		else 
		{
			print $temporaryFileHandle "\nError: $treeRef\n";
			print STDOUT "\nError: $treeRef\n";
			exit;

		}

	}
	
	if ( $iTreeLevel == 0 )
	{
		if (defined($title ))
		{
		    print $title;
		}
		print $temporaryFileHandle "\nEnd of tree-------------------------\n";
	}
}

sub traverseTreeForVectorItemDependencies
{
	my $treeRef       = $_[0];
	my $name	   = $_[1];
	my $iTreeLevel = $_[2];
	
	if (!ref($treeRef ))
	{
		;
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			foreach my $subTreeRef ( @$treeRef )
			{
				&traverseTreeForVectorItemDependencies($subTreeRef,$name, $iTreeLevel+1);
			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			foreach my $key ( keys(%hashTree)) 
			{
				if (!ref($hashTree{$key} ))
				{
					my $iScalar = 0;
					if ($key eq "oper" && $hashTree{$key} =~ /$assignmentOperator/)
					{
						my $rightTreeRef = $hashTree{"right"};
						
		
						if ( !ref ($rightTreeRef) )
						{
							return;
						}
						my %rightTree = %$rightTreeRef;

						my $leftTreeRef = $hashTree{"left"};
						if ( ! ref($leftTreeRef) )
						{
							return;
						}
						my %leftTree = %$leftTreeRef;
						
						print "----------About to call subtree dependencies\n";
						my $leftVariableName = $leftTree{"name"};
						print $leftVariableName,"\n";
						printTree(\%rightTree,0,*STDOUT,"");
						print "----------have called  subtree dependencies\n";
						
						checkSubTreeForDependencies(\%rightTree,$name,$leftVariableName);
					}

				}
				else {
						&traverseTreeForVectorItemDependencies($hashTree{$key},$name, $iTreeLevel+1); 
				}
			}
		}
		elsif ($treeRef =~ /.*SCALAR.*/)
		{
			;
		}
		else 
		{
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			exit;
		}
	}
}



sub traverseTreeParseParentheses
{
	my $treeRef       = $_[0];
	my $name	   = $_[1];
	my $iTreeLevel = $_[2];
	
	my %hashTreeCopy = ();
	
	if (!ref($treeRef ))
	{
		;
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			foreach my $subTreeRef ( @$treeRef )
			{
				&traverseTreeParseParentheses($subTreeRef,$name, $iTreeLevel+1);
			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			%hashTreeCopy = %$treeRef;
			foreach my $key ( keys(%hashTreeCopy)) 
			{
				if (!ref($hashTreeCopy{$key} ))
				{
					my $iScalar = 0;
					if ($key eq "oper" && $hashTreeCopy{$key} eq "PARENS")
					{
						my $terminalExpression = $hashTreeCopy{"terminal"};
						$hashTreeCopy{"terminal"} = "";
						my $separator = ",";
						($hashTreeCopy{"middle"},$state) =  parseList(\$terminalExpression,$separator);
						%$treeRef = %hashTreeCopy;
					}
				}
				else 
				{
						&traverseTreeParseParentheses($hashTreeCopy{$key},$name, $iTreeLevel+1); 
				}
			}
		} else {
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			exit;
		}
	}

}

sub storeLHSVariableDerivation
{
	my $name    = $_[0];
	my $iScalar = $_[1];
	my $leftVariableName = $_[2];
  	
    #Reverse table is here:
	my $reverseDerivationsForThisVariableRef = $reverseDerivationsForVariables{$leftVariableName};
	my %reverseDerivationsForThisVariable = ();
	if ( ! ref ( $reverseDerivationsForThisVariableRef ) )
	{
		$reverseDerivationsForVariables{$leftVariableName} = \%reverseDerivationsForThisVariable;						
	}
	else
	{
		%reverseDerivationsForThisVariable = %$reverseDerivationsForThisVariableRef;
	}
	
	$reverseDerivationsForThisVariable{$name . $iScalar} = $reverseDerivationsForThisVariable{$name . $iScalar} + 1;
	
	$reverseDerivationsForVariables{$leftVariableName} = \%reverseDerivationsForThisVariable;
	
	print "=------------------------------------\n";
	print $leftVariableName, "\n";
	printTree(\%reverseDerivationsForVariables,0,*STDOUT,"");							
    print "=------------------------------------\n";
	
}	

sub storeVariableDerivation
{
	my $name    = $_[0];
	my $iScalar = $_[1];
	my $leftVariableName = $_[2];

    print "=------------------------------------\n";
	print $leftVariableName, $name, $iScalar, "\n";
	printTree(\%reverseDerivationsForVariables,0,*STDOUT,"");							
    print "=------------------------------------\n";
    
	my $derivationsForThisVariableRef = $derivationsForVariables{$name};
	my %derivationsForThisVariable;
	if ( ! ref ( $derivationsForThisVariableRef ) )
	{
		%derivationsForThisVariable = ();	
		$derivationsForVariables{$name} = \%derivationsForThisVariable;						
	}
	else
	{
		%derivationsForThisVariable = %$derivationsForThisVariableRef;
	}
	
	$derivationsForThisVariable{$iScalar} = $leftVariableName;
	$derivationsForVariables{$name} = \%derivationsForThisVariable;

}	

sub checkSubTreeForDependencies
{
	my %hashTree			= %{$_[0]};
	my $name                = $_[1];
	my $leftVariableName    = $_[2];
	
	my $iScalar = 0;
	
	if ( defined($hashTree{"fname"}) && ( $hashTree{"fname"} eq $name ) )
	{
		
		my %rightRightTree = %{$hashTree{"right"}};
		if ( $rightRightTree{"oper"} eq "const" )
		{
			my $iScalar = $rightRightTree{"val"};
			storeVariableDerivation($name,$iScalar,$leftVariableName);
		}
		elsif ( $rightRightTree{"oper"} eq "var" )
		{
			my $iScalar = $rightRightTree{"val"};
			if ( $iScalar =~ /^\d$/)
			{
				storeVariableDerivation($name,$iScalar,$leftVariableName);
			}
		}

	}
	
	my $nameVariable = $hashTree{"name"};
	if ( $hashTree{"oper"} eq "var" && $nameVariable =~ /$name\d+/ )
	{

		my $iScalar = substr($nameVariable,-1); #hack -- only 1-9 supported.
		if ( $iScalar =~ /^\d$/)
		{
			storeVariableDerivation($name,$iScalar,$leftVariableName);
		}

	}
	
	my $goMoreThanOneLevelDeep = 1;
	
	if ( $goMoreThanOneLevelDeep )
	{
		#-------------------------------Handle subtrees----------------------
		if ( ref( $hashTree{"left"} ))
		{
			$iScalar = checkSubTreeForDependencies($hashTree{"left"},$name,$leftVariableName);
		}
		if ( ref( $hashTree{"right"}))
		{
			$iScalar = checkSubTreeForDependencies($hashTree{"right"},$name,$leftVariableName);
		}
		#-------------------------------andle subtrees------------------------

	}
		
	return $iScalar;

	
}

sub replaceUseOfVectorWithScalar
{
	my %hashTree			= %{$_[0]};
	my $name                = $_[1];
	
	my $iScalar = 0;
	my %tree = %hashTree;
	
	if ( ref($hashTree{"right"} ) )
	{
		my %rightRightTree = %{$hashTree{"right"}};
		if ( $rightRightTree{"oper"} eq "const"  )
		{
			$iScalar = $rightRightTree{"val"};
			%tree = (
				'oper' => 'var',
				'name' => $name . $iScalar
			);
		}
	}
	else
	{
		my $nameToExamine = $hashTree{"name"};
		$nameToExamine =~ s/\(|\)|\[|\]//g;
		%tree = (
			'oper' => 'var',
			'name' => $nameToExamine
		);

	}
	

	return (\%tree,"OK");

}

sub replaceUseOfFunctionWithScalar
{
	my %hashTree			= %{$_[0]};
	my $name                = $_[1];
	
	my $iScalar = 0;
	my %tree = %hashTree;
	
	if ( ref($hashTree{"right"} ) )
	{
		my %rightRightTree = %{$hashTree{"right"}};
		if ( $rightRightTree{"oper"} eq "var" )
		{
			$iScalar = $rightRightTree{"name"};
			%tree = (
				'oper' => 'var',
				'name' => $name . $iScalar
			);
		}
	
	}
	else
	{
		my $nameToExamine = $hashTree{"name"};
		$nameToExamine =~ s/\(|\)|\[|\]//g;
		%tree = (
			'oper' => 'var',
			'name' => $nameToExamine
		);

	}
	

	return (\%tree,"OK");

}

sub renameFunction
{
	my %hashTree			= %{$_[0]};
	my $name                = $_[1];
	
	my $iScalar = 0;
	
	$improveThis = 1; #a is hardwired.
	if ( $hashTree{"fname"} eq $name )
	{
		$hashTree{"fname"} = "A";
	}
	
	return (\%hashTree,"OK");

}


sub parseINPUT
{
	my $string = $_[0];
	
	my $separator = "\\s+|\\n";
	my ($ref,$state) = parseList(\$string,$separator);
	return ($ref,"INPUT");

}

sub parseEST
{
	my $string = $_[0];
	
	my $separator = ",|\\n";
	my ($ref,$state) = parseList(\$string,$separator);


	return ($ref,"EST");

}

sub parseCOVA
{
	my $string = $_[0];
	
	my $separator = ",";
	my ($ref,$state) = parseList(\$string,$separator);
	return ($ref,"INPUT");

}


sub parseTAB
{
	my $string = $_[0];
	
	my ($ref, $state) = parseLinesOfLists($string);

	return ($ref,"TAB");

}	


sub modifyTree
{
	my $treeRef				= $_[0];
	my $filterFunctionRef	= $_[1];
	my $functionRef			= $_[2];
	my $char1				= $_[3];
	my $char2				= $_[4];
	my $iTreeLevel			= $_[5];
	my $iTotalLevels        = $_[6];
	my $justModifyRightSide = $_[7];
	
	my @results				= ();
	
	$iTreeLevel++;
	
	if ( $iTreeLevel >  $iTotalLevels )
	{
		return ($treeRef,"complete");
	}
	
	if ( 0 )
	{
	    open(DOG,">>dog.txt" );
	    print DOG "-------------TO START---------------------\n";
	    printTree($treeRef,0,*DOG,"");
        print DOG "-------------END START---------------------\n";

	    close(DOG);
	}
	
	my @treeArray;
	my %tree;
	
	my $valuesRef = "";
	
	if ( !ref($treeRef) )
	{
		if ( &$filterFunctionRef($treeRef,$char1,$char2))
		{
			($treeRef,$state) = &$functionRef($treeRef,$char1,$char2);
			($treeRef,$state) = modifyTree($treeRef,$filterFunctionRef, $functionRef,$char1,$char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
		}
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			if ( &$filterFunctionRef($treeRef,$char1,$char2))
			{
				($treeRef,$state) = &$functionRef($treeRef,$char1,$char2);
			}
			my $iElement = 0;
			if ( ref($treeRef) && $treeRef =~ /ARRAY/)
			{
				@treeArray = @$treeRef;
				foreach my $subTreeRef ( @treeArray )
				{
					if ( &$filterFunctionRef($subTreeRef,$char1,$char2))
					{
						($subTreeRef,$state) = &$functionRef($subTreeRef,$char1,$char2);
					}
					elsif ( ref($subTreeRef ))
					{
						($subTreeRef,$state) = &modifyTree($subTreeRef,$filterFunctionRef, $functionRef,$char1,$char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
					}
					$treeArray[$iElement++] = $subTreeRef;
				}
				$treeRef = \@treeArray;
			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my $iElement = 0;
			%tree = %$treeRef;
			foreach my $key ( keys(%tree) )
			{
				my $subTreeRef = $tree{$key};
				
				if ( $justModifyRightSide )
				{
					if ( $tree{"oper"} eq "=" && $key eq "left" )
					{
						next;
					}  
				}
				
				if ( &$filterFunctionRef($subTreeRef,$char1,$char2))
				{
					($subTreeRef,$state) = &$functionRef($subTreeRef,$char1, $char2);
					($subTreeRef,$state) = modifyTree($subTreeRef,$filterFunctionRef, $functionRef,$char1, $char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
				}
				elsif ( ref($subTreeRef))
				{
					($subTreeRef, $state ) = &modifyTree($subTreeRef,$filterFunctionRef, $functionRef,$char1, $char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
				}
				$tree{$key} = $subTreeRef;
			}
			$treeRef = \%tree;
		}
		elsif ($treeRef =~ /.*SCALAR.*/)
		{
			if ( &$filterFunctionRef($treeRef,$char1,$char2))
			{
				($treeRef,$state) = &$functionRef($treeRef,$char1, $char2);
				($treeRef,$state) = modifyTree($treeRef,$filterFunctionRef, $functionRef, $char1, $char2,$iTreeLevel,$iTotalLevels,$justModifyRightSide);
			}
		}
		else
		{
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			printTree($treeRef,0,$printHandle,"");
			exit;
		}
	}
	
	$iTreeLevel--;

    if ( 0 )
    {
	    open(DOG,">>dog.txt" );
	    print DOG "-------------NOW DONE---------------------\n";
	    printTree($treeRef,0,*DOG,"");
	    print DOG "-------------END DONE---------------------\n";

	    close(DOG);
    }
    	
	return ($treeRef,"OK");
}

sub getInfoFromTree
{
	my $treeRef       = $_[0];
	my $tagsRef       = $_[1];
	if ( ! ref ( $tagsRef ) || (! ( $tagsRef =~ /HASH/)) )
	{
	    print "Error in getInfoFromTree\n";
	    printTree($globalASTRef,0,*STDOUT,"\nGlobal Tree\n");
	    printTree($treeRef,0,*STDOUT,"\nLocal Tree\n");
	    print $tagsRef, "\n";
	    exit;
	}
	my %tags          = %{$_[1]};
	my $iTreeLevel	  = $_[2];
	
	my $label         = $tags{"label"};
	my $functionRef   = $tags{"routine"};
	
	my $valuesString;
	
	if (!ref($treeRef ))
	{
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			my $iElement = 0;
			foreach my $subTreeRef ( @$treeRef )
			{
				my ($valuesStringTemp, $state) = getInfoFromTree($subTreeRef,\%tags, $iTreeLevel+1);
				if ( defined($valuesStringTemp))
				{
				    if ( ref($valuesStringTemp) && $valuesStringTemp =~ /HASH/)
				    {
					    $valuesString = $valuesStringTemp;
				    } 
				    else
				    {
					    $valuesString .= $valuesStringTemp;
				    }
				}
			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			foreach my $key ( keys(%hashTree)) 
			{
				if ( $key eq $label )
				{
					my ($valuesStringTemp,$state) = &$functionRef($hashTree{$key},\%tags,$iTreeLevel+1);
					if ( defined($valuesStringTemp ) )
					{
					    if ( ref($valuesStringTemp) && $valuesStringTemp =~ /HASH/)
					    {
						    $valuesString = $valuesStringTemp;
					    } 
					    else
					    {
						    $valuesString .= $valuesStringTemp;
					    }
					}
				}
				if (!ref($hashTree{$key} ))
				{
				}
				else
				{
					my ($valuesStringTemp, $state) = getInfoFromTree($hashTree{$key},\%tags,$iTreeLevel+1);
					if ( defined($valuesStringTemp))
					{
					    if ( ref($valuesStringTemp) && $valuesStringTemp =~ /HASH/)
					    {
						    $valuesString = $valuesStringTemp;
					    } 
					    else
					    {
						    $valuesString .= $valuesStringTemp;
					    }
                    }
				}
			}
		}
		elsif ( $treeRef =~ /.*SCALAR.*/)
		{
			;
		}
		else
		{
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			printTree($treeRef,0,$printHandle,"");
			exit;
		}
	}

	return ($valuesString,"OK");
}

sub getArrayOfInfoFromTree
{
	my $treeRef       = $_[0];
	my %tags          = %{$_[1]};
	my $iTreeLevel	  = $_[2];
	
	my $label         = $tags{"label"};
	my $functionRef   = $tags{"routine"};
	
	my @arrayOfInfo = ();
	
	if (!ref($treeRef ))
	{
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			my $iElement = 0;
			foreach my $subTreeRef ( @$treeRef )
			{
				my ($arrayOfInfoRefTemp,$state) = &$functionRef($subTreeRef,\%tags,$iTreeLevel+1);
				if ( $arrayOfInfoRefTemp =~ /ARRAY/)
				{
					push(@arrayOfInfo, @$arrayOfInfoRefTemp);
				}
				elsif ( $arrayOfInfoRefTemp =~ /\w/ )
				{
					push(@arrayOfInfo, $arrayOfInfoRefTemp);
				}

				($arrayOfInfoRefTemp, $state) = getArrayOfInfoFromTree($subTreeRef,\%tags, $iTreeLevel+1);
				if ( $arrayOfInfoRefTemp =~ /ARRAY/)
				{
					push(@arrayOfInfo, @$arrayOfInfoRefTemp);
				}
				elsif ( $arrayOfInfoRefTemp =~ /\w/ )
				{
					push(@arrayOfInfo, $arrayOfInfoRefTemp);
				}

			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			foreach my $key ( keys(%hashTree)) 
			{
				my ($arrayOfInfoRefTemp,$state) = &$functionRef($hashTree{$key},\%tags,$iTreeLevel+1);
				if ( $arrayOfInfoRefTemp =~ /ARRAY/)
				{
					push(@arrayOfInfo, @$arrayOfInfoRefTemp);
				}
				elsif ( $arrayOfInfoRefTemp =~ /\w/ )
				{
					push(@arrayOfInfo, $arrayOfInfoRefTemp);
				}
				
				if (!ref($hashTree{$key} ))
				{
				}
				else
				{
					my ($arrayOfInfoRefTemp, $state) = getArrayOfInfoFromTree($hashTree{$key},\%tags,$iTreeLevel+1);
					if ( $arrayOfInfoRefTemp =~ /ARRAY/)
					{
						push(@arrayOfInfo, @$arrayOfInfoRefTemp);
					}
					elsif ( $arrayOfInfoRefTemp =~ /\w/ )
					{
						push(@arrayOfInfo, $arrayOfInfoRefTemp);
					}
				}
			}
		}
		elsif ( $treeRef =~ /.*SCALAR.*/)
		{
			;
		}
		else
		{
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			printTree($treeRef,0,$printHandle,"");
			exit;
		}
	}

	if ( 0 && scalar(@arrayOfInfo) )
	{
		printTree(\@arrayOfInfo,0,*STDOUT,"");
	}
	
	return (\@arrayOfInfo,"OK");
}

sub getHashOfInfoFromTree
{
	my $treeRef       = $_[0];
	my %tags          = %{$_[1]};
	my $iTreeLevel	  = $_[2];
	my $hashRef       = $_[3];
	
	my $label         = $tags{"label"};
	my $functionRef   = $tags{"routine"};
	
	my @arrayOfInfo = ();
	
	if (ref($treeRef ))
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			my $iElement = 0;
			foreach my $subTreeRef ( @$treeRef )
			{
			    my $state = "";
				($hashRef,$state) = &$functionRef($subTreeRef,\%tags,$iTreeLevel+1,$hashRef);
			    ($hashRef, $state) = getHashOfInfoFromTree($subTreeRef,\%tags, $iTreeLevel+1,$hashRef);

			}
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			foreach my $key ( keys(%hashTree)) 
			{
			    my $state = "";
			    ($hashRef,$state) = &$functionRef($hashTree{$key},\%tags,$iTreeLevel+1,$hashRef);
				
				if (ref($hashTree{$key} ))
				{
					($hashRef, $state) = getHashOfInfoFromTree($hashTree{$key},\%tags,$iTreeLevel+1,$hashRef);
				}
			}
		}
	}
	return ($hashRef,"OK");
}

sub fillInArrayOfInfoFromTree
{
	my $treeRef        = $_[0];
	my %tags           = %{$_[1]};
	my $arrayOfInfoRef = $_[2];
	my $iTreeLevel	   = $_[3];
	
	my $label         = $tags{"label"};
	my $functionRef   = $tags{"routine"};
	my $state         = "OK";
	
	if (!ref($treeRef ))
	{
	}
	else
	{
		if ( $treeRef =~ /.*ARRAY.*/)
		{
			my $iElement = 0;
			foreach my $subTreeRef ( @$treeRef )
			{
				($arrayOfInfoRef, $state) = &$functionRef($subTreeRef,\%tags,$arrayOfInfoRef,$iTreeLevel+1);
				($arrayOfInfoRef, $state) = fillInArrayOfInfoFromTree($subTreeRef,\%tags,$arrayOfInfoRef, $iTreeLevel+1);
 			}
		}
		elsif ( $treeRef =~ /.*CODE.*/)
		{
		}
		elsif ( $treeRef =~ /.*HASH.*/)
		{
			my %hashTree = %$treeRef;
			foreach my $key ( keys(%hashTree)) 
			{
				($arrayOfInfoRef,$state) = &$functionRef($hashTree{$key},\%tags,$arrayOfInfoRef,$iTreeLevel+1);
				if (!ref($hashTree{$key} ))
				{
				}
				else
				{
					($arrayOfInfoRef, $state) = fillInArrayOfInfoFromTree($hashTree{$key},\%tags,$arrayOfInfoRef,$iTreeLevel+1);
				}
			}
		}
		elsif ( $treeRef =~ /.*SCALAR.*/)
		{
			;
		}
		else
		{
			print $printHandle "Error: \n";
			print $printHandle $treeRef;
			printTree($treeRef,0,$printHandle,"");
			exit;
		}
	}

	return ($arrayOfInfoRef,"OK");
}

sub constructObservationFunctions
{
	my ( $stateVariablesRef, $pkScaleFactors ) = @_;
	
	my %observationFunctions = ();
	
	my $stateVariables = "";
	if ( ref($stateVariablesRef ))
	{
		$stateVariables = $$stateVariablesRef;
	}
	else
	{
		$stateVariables = $stateVariablesRef; #$improveThis =1; #should pass in always as ref.
	}
	
	my @states = split(/,/,$stateVariables);
	my @pkScaleFactors = split(/,/,$pkScaleFactors);
	
	my $iStateNumber = 1;
	my $iDefaultObservation = 1; #hack rph **************************************** 2008/01/22
	
	$pkScaleFactors =~ s/S/V/g;
	for ( my $i = 1; $i <= scalar(@states); $i++ )
	{
		my $stateVariable = "F" . $iStateNumber;
		$observationFunctions{$stateVariable} = "$states[$i-1]\/V$i";
		if ( $iStateNumber == $iDefaultObservation )
		{
			$observationFunctions{"F"} = "$states[$i-1]\/V  ;\#Default Observation(should duplicate another)";
		}	
		$iStateNumber++;
	}

	return ( \%observationFunctions);

}

sub constructPriorsForThetas
{
	my ($arraysOfBoundsRef, $exponentialDependenciesRef ) = @_;
	
	my %arraysOfBounds = %$arraysOfBoundsRef;
	my %exponentialDependencies = %$exponentialDependenciesRef;
	
	my $priorsString = "";
	
	my $defaultMean      = "0.0";
	my $defaultPrecision = "0.0001";
	my $defaultRange     = "100";
	my $defaultPositivityConstraint = "";
	
	my $arrayOfBoundsForThisParameterRef = $arraysOfBounds{"THETA"};
	
	if ( ref( $arrayOfBoundsForThisParameterRef ) && $arrayOfBoundsForThisParameterRef =~ /ARRAY/)
	{
		my @derivationsForThetas = @$arrayOfBoundsForThisParameterRef;
		
		my @expVars;

		for ( my $i = 1; $i <= scalar(@derivationsForThetas); $i++ )
		{
			my $mean = $defaultMean;
			my $precision = $defaultPrecision;
			my $range = $defaultRange;
			my $pairOfBoundsRef       = $derivationsForThetas[$i-1];
			if ( ref($pairOfBoundsRef) && $pairOfBoundsRef =~ /ARRAY/)
			{
				my ($lowValue,$highValue) = @$pairOfBoundsRef;
				$range = $highValue - $lowValue;
				
				if ($range > 0 )
				{
					$precision = 1/$range;
				}
			}
			
			my $positivityConstraint = $defaultPositivityConstraint;

			my $setOfDependenciesRef = $exponentialDependencies{"THETA" . $i};
			my @setOfDependencies    = @$setOfDependenciesRef;
		
			$improveThis = 1; #Need to simplify this...
			if ( scalar(@setOfDependencies))
			{
				$mean = "-1.0";
				$positivityConstraint = "I(,0)";
			}
			
			$priorsString .= 	"\	theta[$i] ~ dnorm($mean,$range)$positivityConstraint\n";

		}
	}

	return ( $priorsString);

}

sub constructPriorsForEtas
{
	my ($arraysOfBoundsRef, $exponentialDependenciesRef ) = @_;
	
	my %arraysOfBounds = %$arraysOfBoundsRef;
	my %exponentialDependencies = %$exponentialDependenciesRef;
	
	my @allPriorsStrings = ();
	my $priorsString = "";
	
	my $defaultMean      = "0.0";
	my $defaultPrecision = "0.0001";
	my $defaultRange     = 100;
	my $defaultPositivityConstraint = "";
	
	my $arrayOfBoundsForThisParameterRef = $arraysOfBounds{"ETA"};
	
	if ( ref( $arrayOfBoundsForThisParameterRef ) && $arrayOfBoundsForThisParameterRef =~ /ARRAY/)
	{
		my @derivationsForEtas = @$arrayOfBoundsForThisParameterRef;
		
		my @expVars;
		
		my $possiblyFixed = $derivationsForEtas[1];
		my $isFixed = 0;
		if ( $possiblyFixed =~ /FIXED/i)
		{
			$isFixed = 1;
		}
		
		if ( $isFixed )
		{
			my $mean = $derivationsForEtas[0];
			$priorsString = 	"Dirac($mean)";
			$allPriorsStrings[0] = $priorsString;
		}
		else
		{
			for ( my $i = 1; $i <= scalar(@derivationsForEtas); $i++ )
			{
				my $mean = $defaultMean;
				my $precision = $defaultPrecision;
				my $range = $defaultRange;
				my $positivityConstraint = $defaultPositivityConstraint;

				my $setOfDependenciesRef = $exponentialDependencies{"ETA" . $i};
				my @setOfDependencies    = @$setOfDependenciesRef;
			
				$improveThis = 1; #Need to simplify this...
				if ( scalar(@setOfDependencies))
				{
					$mean = "-1.0";
					$positivityConstraint = "I(,0)";
				}
				
				$priorsString = 	"dunif(0,$range)";
				$allPriorsStrings[$i - 1 ] = $priorsString;
			}
		}
	}

	return ( \@allPriorsStrings );

}

sub removeAnyFunctionDependencies
{
	my ( $expressionsList, $variable) = @_;
	my @expressions = split(",", $expressionsList);
	for ( my $i = 0; $i <= $#expressions; $i++ )
	{
		$expressions[$i] =~ s/\($variable\)//g;
	}
	#my @expressionsFinal = map(s/\($variable\)//g,@expressions);
	my $expressionsListFinal = join(",",@expressions);
	return ( $expressionsListFinal);

}

sub writeNonmemFile
{
	my $globalASTRef = $_[0];
	my $TLCOutputFileName   = $_[1];
	my $dataFileName         = $_[2];
	
	my $infoString = "";
	my $state = "";
	
	my %processingMethods = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getNonmemIfThenExpression,
			modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
			getForLoopExpression                 => \&getNonmemForLoopExpression,
			assignmentOperator					 => " = "
		);
	
	my $NonmemFileName = $TLCOutputFileName;
	$NonmemFileName =~ s/\.TLC/\.NONMEM/ig;
	
	open(NonmemFILEParseTree,">>$NonmemFileName.parseTree" ) or die("Could not open Nonmem file $NonmemFileName\n");
	printTree($globalASTRef,0,*NonmemFILEParseTree,"");
	close(NonmemFILEParseTree);
	
	open(NonmemFILE,">>$NonmemFileName" ) or die("Could not open Nonmem file $NonmemFileName\n");
	my $NONMEMFileHandle = *NonmemFILE;
	$printHandle = $NONMEMFileHandle;

	my %tags = ( label => "PROBLEM", startTag => "\$PROBLEM ", endTag  => "\n", separator => " ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"PROBLEM",\%tags,0);
	print $NONMEMFileHandle $infoString;
	
	%tags = ( label  => "INPUT", startTag => "\$INPUT ", endTag  => "\n",internalStartTag => "", internalEndTag => "",routine => \&getArrayOfValues, separator => " ",subRoutine => \&getTagAndValueOrHashGeneral);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"INPUT",\%tags, 0);
	print $NONMEMFileHandle $infoString;
	
	%tags = ( label  => "DATA", startTag => "\$DATA ", endTag  => "\n", routine => \&getArrayOfValues, separator => " ",subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $NONMEMFileHandle );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"DATA",\%tags,0);
	print $NONMEMFileHandle $infoString;
	
	%tags = ( label  => "SUBROUTINE", startTag => "\$SUBROUTINE ", endTag  => "\n", separator => " ", routine => \&getArrayOfValues,subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $NONMEMFileHandle );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"SUBROUTINE",\%tags,0);
	my $subroutineIsDefined = ( $infoString =~ /SUBROUTINE\s+/);
	
	$improveThis = 1; #make showing model contingent on subroutines.
	#%tags = ( label  => "MODEL", startTag => "\$MODEL ", endTag  => "\n",separator => " ",routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrExpressionGeneral);
	#( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"MODEL",\%tags,0);
	
	if ( $subroutineIsDefined )
	{
		#Use ADVAN6 instead, for the time being.
		my $replaceSubroutineWithADVAN6 = 1;
		if ( $replaceSubroutineWithADVAN6) 
		{
			$infoString = "\$SUBROUTINE ADVAN6 TOL=5\n";
		}
		print $NONMEMFileHandle $infoString;
	}
	my $arrayOfModelTreesRef = getSubTree($globalASTRef,"MODEL");
	
	if ( $arrayOfModelTreesRef ne "" )
	{
		print $NONMEMFileHandle "\$MODEL\n";
		unless ( $arrayOfModelTreesRef =~ /ARRAY/)
		{
			my $modelString = getExpression($arrayOfModelTreesRef);
			print $NONMEMFileHandle "\t$modelString\n";
		}
		else
		{
			my @arrayOfModelTrees = @$arrayOfModelTreesRef;
			if ( scalar(@arrayOfModelTrees ) > 0 )
			{	
				foreach my $treeRef ( @arrayOfModelTrees )
				{
					my $modelString = getExpression($treeRef);
					print $NONMEMFileHandle "\t$modelString\n";
				}
			}
		}
	}
	
	my %processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getNonmemIfThenExpression,
		modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
		assignmentOperator					 => " = "
	);

	my $showComments = 0;
	
	%tags = ( label => "CATEGORICAL_VARIABLES", startTag => "\;#CATEGORICAL_VARIABLES\n;#	", endTag  => "\n", separator => " ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"CATEGORICAL_VARIABLES",\%tags,0);
	print $NONMEMFileHandle $infoString if $showComments;

	%tags = ( label => "PK_STATE_VARIABLES", startTag => ";\#PK_STATE_VARIABLES\n;#	", endTag  => "\n", separator => " ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"PK_STATE_VARIABLES",\%tags,0);
	print $NONMEMFileHandle $infoString if $showComments;
	
	my $stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
	my $stateVariables;
	if ( ref($stateVariablesRef))
	{
		$stateVariables = $$stateVariablesRef;
	}
	else
	{
		$stateVariables = $stateVariablesRef;
	}
 	
	my $parameters = join(",", keys(%variablesWithoutNumericSuffixes));
	
	$improveThis = 1;
	if ( $improveThis )
	{
		$parameters .= ",ERR1";
	}

	my $PKNodeName = "PK";
	if ( ! $subroutineIsDefined )
	{
		$PKNodeName = "PRED";
	}
	%tags = ( label  => "PK", startTag => "\$$PKNodeName\n	", separator => "\n	", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	my $PKEquations;
	( $PKEquations, $state ) = getInfoFromSubTree($globalASTRef,"PK",\%tags,0);
	print $NONMEMFileHandle $PKEquations;
	
	my $useMaster = 1;
	%tags = ( label  => "DESMASTER", startTag => "\$DES\n	", separator => "\n	", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethods, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	my $DESEquations;
	( $DESEquations, $state ) = getInfoFromSubTree($globalASTRef,"DESMASTER",\%tags,0);
	
	if ( $subroutineIsDefined )
	{
		print $NONMEMFileHandle $DESEquations;
	}
	
	my $priorsStringRef = getSubTree($globalASTRef,"PRIORS");
	my $priorsString = "";
	$improveThis = 1; #check for type here.
	if ( ref ($priorsStringRef ) && $priorsStringRef =~ /SCALAR/ )
	{
		$priorsString = $$priorsStringRef;
		my @allPriors = split(/\n/,$priorsString);
		my $iTheta = 1;
		for ( my $iPrior = 0; $iPrior < scalar(@allPriors); $iPrior++ )
		{
			my $dist1   = $allPriors[$iPrior];
			$dist1 =~ s/dnorm.*//g;
			my $limits1 = $allPriors[$iPrior];
			$limits1 =~ s/.*\(|\).*//g;
			my ( $low, $high ) = split(/,/,$limits1);
			$allPriors[$iPrior] = "\; $allPriors[$iPrior] . $dist1 . Dirac(Td$iTheta) $low < Td$iTheta < $high )";
			$iTheta++;
		}
		$priorsString = ";\#PRIORSForBUGS\n" . $priorsString;

	}
	$priorsString =~ s/\n^$/\n;\#/g;
	print $NONMEMFileHandle $priorsString if $showComments;
	print $NONMEMFileHandle ";\#PRIORSForNONMEM THETA[i] ~ Dirac(dx);  Use all aspects of data ( ignore no aspects of data )\n" if ( $showComments);
	my @priorsStringsForEtas = ();
	my $priorsForEtasRef = getSubTree($globalASTRef,"PRIORSForEtas");
	if ( ref($priorsForEtasRef) )
	{
		@priorsStringsForEtas = @$priorsForEtasRef;
	}
	
	my $priorsStringForEtas = "";
	for ( my $iLine = 1; $iLine <= scalar(@priorsStringsForEtas); $iLine++)
	{
		my @distributionForEta = $priorsStringsForEtas[$iLine-1];
		$priorsStringForEtas .= "\teta[$iLine]   ~ $distributionForEta[0]\n";
	}
	print $NONMEMFileHandle $priorsStringForEtas if $showComments;
	
	%processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getNonmemIfThenExpression,
		modifyDifferentialExpression		 => \&adaptDifferentialExpressionForStateVariable,
		assignmentOperator                   => " = "
	);

	%tags = ( label  => "DES", startTag => ";\#VECTOR_FIELD\n;#	", separator => "\n;\#	", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Right', subRoutine => "" );
	my $vectorFieldExpressions;
	( $vectorFieldExpressions, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
	print $NONMEMFileHandle $vectorFieldExpressions if $showComments;

	%tags = ( label  => "PKScaleFactors", startTag => ";\#SCALE_FACTORS\n;#	", separator => "\n;\#	", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
	my $PKScaleFactors;
	( $PKScaleFactors, $state ) = getInfoFromSubTree($globalASTRef,"PKScaleFactors",\%tags,0);
	$PKScaleFactors =~ s/\n\s*\n/\n/g;
	print $NONMEMFileHandle $PKScaleFactors if $showComments;

	%tags = ( label => "OBSERVATION_FUNCTIONS", startTag => ";\#OBSERVATION_FUNCTIONS\n;#	", endTag  => "\n", separator => "\n;#	", routine => \&getHashOfFunctions, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"OBSERVATION_FUNCTIONS",\%tags,0);
	print $NONMEMFileHandle $infoString if $showComments;
		
	$improveThis = 1;
	if ( $improveThis == 1 )
	{
		#my $outputExpressions =~ s/EXP\(ERR1\)/ERR1/g;
	}
	%tags = ( label  => "ERROR", startTag => ";\#OBSERVATION_VARIABLES\n;# ", separator =>", ", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethods, getLeftRightOrBothSides => 'Left', subRoutine => "" );
	my $coStateVariables = "";
	( $coStateVariables, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);
	print $NONMEMFileHandle $coStateVariables if $showComments;
	
	my $inputVariables   = "";

	print $NONMEMFileHandle <<NonmemPart1;
NonmemPart1

	%processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getNonmemIfThenExpression 
	);

	#%tags = ( label  => "DES", startTag => "DES", separator =>", ", endTag  => "", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	#my ( $differentialEquations, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
	#print $NONMEMFileHandle $differentialEquations, "\n";
	
	my $allVariables = $stateVariables . ",extra," . $parameters;

	%tags = ( label  => "ERROR", startTag => "\$ERROR\n	", separator =>"\n	", endTag  => "\n",routine => \&getDifferentialEquations, processingMethods => \%processingMethods, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);
	my $hasErrorString = $infoString =~ /ERROR\s+\w/;
	if ( $hasErrorString)
	{
		print $printHandle $infoString;
	}

	%tags = ( label  => "THETA", startTag => "\$THETA\n	", separator =>"\n	", endTag  => "\n", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaGeneral );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"THETA",\%tags,0);
	print $printHandle $infoString;

	%tags = ( label  => "ETA", startTag => "\$OMEGA	", separator =>" ", endTag  => "\n", routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"ETA",\%tags,0);
	print $printHandle $infoString;

	%tags = ( label  => "SIGMA", startTag => "\$SIGMA	", separator =>" ", endTag  => "\n",routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"SIGMA",\%tags,0);
	my $hasSigmaString = $infoString =~ /SIGMA\s+\w/;
	if ( $hasSigmaString )
	{
		print $printHandle $infoString;
	}
	
	%tags = ( label  => "TABLE", startTag => "\$TABLE	", endTag  => "\n", separator => ' ', routine => \&getHashOfArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $printHandle $infoString;

	%tags = ( label  => "COVA", startTag => "\$COVA	", endTag  => "\n", routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $printHandle $infoString;

	%tags = ( label  => "ESTIMATION", startTag => "\$EST	", endTag  => "\n", separator => ' ', routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $printHandle $infoString;

	%tags = ( label  => "SCAT", startTag => "\$SCAT	", endTag  => "\n", routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $printHandle $infoString;

	close($NONMEMFileHandle);
	
}


sub writeAsAlgebraicTheory
{
	my $globalASTRef = $_[0];
	my $TLCOutputFileName   = $_[1];
	my $dataFileName         = $_[2];
	
	my %processingMethods = (
			getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
			getIfThenExpression                  => \&getMapleIfThenExpression,
			modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
			getForLoopExpression                 => \&getNonmemForLoopExpression,
			assignmentOperator					 => " = "
		);
	
	my $AlgebraicTheoryName = $TLCOutputFileName;
	#$AlgebraicTheoryName =~ s/\.TLC/\.AlgebraicTheory/ig;
	
	open(AlgebraicTheory,">$AlgebraicTheoryName" ) or die("Could not open AlgebraicTheory file $AlgebraicTheoryName\n");
	my $AlgebraicTheoryHandle = *AlgebraicTheory;
	$printHandle = *$AlgebraicTheoryHandle;

	my $modelNameFromFileRef = getSubTree($globalASTRef,"MODEL_NAME_FROM_FILE");
	my $modelNameFromFile = $$modelNameFromFileRef;
    my $infoStringForModelNameFromFile = "ModelName:ModelNames=$modelNameFromFile";
    print $AlgebraicTheoryHandle $infoStringForModelNameFromFile,"\n";

	my $regularizedModelNameRef = getSubTree($globalASTRef,"REGULARIZED_MODEL_NAME");
	my $regularizedModelName = $$regularizedModelNameRef;
    my $infoStringForModelName = "ModelName:ModelNames=$regularizedModelName";
    print $AlgebraicTheoryHandle $infoStringForModelName,"\n";

	my $routingRef = getSubTree($globalASTRef,"ROUTING");
	my $routing = $$routingRef;
    my $infoStringForRouting = "Routing:RoutingTypes=$routing";
    print $AlgebraicTheoryHandle $infoStringForRouting,"\n";

	my $dosingRef = getSubTree($globalASTRef,"DOSING");
	my $dosing = $$dosingRef;
    my $infoStringForDosing = "Dosing:DosingTypes=$dosing";
    print $AlgebraicTheoryHandle $infoStringForDosing,"\n";

	my $arrayOfPKNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES_ORIGINAL");
    my $infoStringForPKNames = getPKVariableNames($arrayOfPKNamesRef);
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForPKNames);

 	my $arrayOfPKNamesOriginalRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES");
 	
 	my $infoString;
    $infoString = getPKVariableNamesOriginal($arrayOfPKNamesOriginalRef);
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);
 
 	my $dependenciesOnVectorsRef = getSubTree($globalASTRef,"VECTOR_VARIABLE_DEPENDENCIES");
 
    #improve this -- use data already in the global syntax tree.
 	my $defaultPrefix = 'tv';
    $infoString = getPKVariableNamesAsNTuple($dependenciesOnVectorsRef, "THETA", $arrayOfPKNamesRef, $defaultPrefix );
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

    #improve this -- may not work on complex problems.
 	$defaultPrefix = 'n';
    $infoString = getPKVariableNamesAsNTuple($dependenciesOnVectorsRef, "ETA", $arrayOfPKNamesRef, $defaultPrefix );
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

 	$defaultPrefix = 'tv';
    $infoString = getPKVariableDependencies($dependenciesOnVectorsRef, "THETA", $arrayOfPKNamesRef, $defaultPrefix );
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);
    
 	$defaultPrefix = 'n';
    $infoString = getPKVariableDependencies($dependenciesOnVectorsRef, "ETA", $arrayOfPKNamesRef, $defaultPrefix ) ;
    print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	my %tags = ( label => "PROBLEM", startTag => "PROBLEM, ModelName, =, \"", endTag  => "\"\n", separator => " ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"PROBLEM",\%tags,0);
	my $lambdaExpression = Util_convertToLambdaExpression($infoString);
	print $AlgebraicTheoryHandle $lambdaExpression;
	
	%tags = ( label  => "INPUT", startTag => "INPUT, colNames, =, \" [ ", endTag  => "\]\"\n",internalStartTag => "", internalEndTag => "",routine => \&getArrayOfValues, separator => ", ", subRoutine => \&getTagAndValueOrHashGeneral);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"INPUT",\%tags, 0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);
	
	%tags = ( label  => "DATA", startTag => "DATA,", endTag  => "", routine => \&getArrayOfValues, separator => ", ",subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $AlgebraicTheoryHandle );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"DATA",\%tags,0);
	
	my $infoStringForAlgebraicTheory;
	$infoStringForAlgebraicTheory = splitOutSingleStringAndAttributes("DATA", "DATA", $infoString, "\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
	
	%tags = ( label  => "SUBROUTINE", startTag => "SUBROUTINE, ", endTag  => "\n", separator => ", ", routine => \&getArrayOfValues,subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $AlgebraicTheoryHandle );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"SUBROUTINE",\%tags,0);
	$infoStringForAlgebraicTheory = splitOutSingleStringAndAttributes("SUBROUTINE", "SUBROUTINE", $infoString, "\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);

	%tags = ( label  => "MODEL", startTag => "", endTag  => "\"\n",separator => ",",routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrExpressionGeneral);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"MODEL",\%tags,0);
	$infoStringForAlgebraicTheory = splitOutFunctionAndFunctionValues("MODEL", $infoString, "\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
	
	my %processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getMapleIfThenExpression,
		modifyDifferentialExpression		 => \&useNonmemDifferentialExpression, 
		assignmentOperator					 => " = "
	);

	%tags = ( label => "CATEGORICAL_VARIABLES", startTag => "CATEGORICAL_VARIABLES, CATEGORICAL_VARIABLES, =, [", endTag  => " \]\n", separator => " ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"CATEGORICAL_VARIABLES",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label => "PK_STATE_VARIABLES", startTag => "PK_STATE_VARIABLES, PK_STATE_VARIABLES =, \[ ", endTag  => " ]\n", separator => ", ", routine => \&getSingleString, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"PK_STATE_VARIABLES",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);
	
	my $stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
	my $stateVariables;
	if ( ref($stateVariablesRef))
	{
		$stateVariables = $$stateVariablesRef;
	}
	else
	{
		$stateVariables = $stateVariablesRef;
	}
 	
	my $parameters = join(",", keys(%variablesWithoutNumericSuffixes));
	
	$improveThis = 1;
	if ( $improveThis )
	{
		$parameters .= ",ERR1";
	}

	%tags = ( label  => "PK", startTag => "PK, ", separator => "\nPK, ", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	my $PKEquations;
	( $PKEquations, $state ) = getInfoFromSubTree($globalASTRef,"PK",\%tags,0);
	my $PKEquationsAsAlgebraicTheory = splitLabelAndEquations("PK", $PKEquations,"\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($PKEquationsAsAlgebraicTheory);
	
	%tags = ( label  => "DES", startTag => "DES, ", separator => "\nDES, ", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	my $DESEquations;
	( $DESEquations, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
	my $DESEquationsAsAlgebraicTheory = splitLabelAndEquations("DES", $DESEquations,"\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($DESEquationsAsAlgebraicTheory);

    #Improve this -- make use of DESMASTER already in the AST
    my $DESFileNameRef = getSubTree($globalASTRef,"REGULARIZED_MODEL_NAME");
    my $DESFileName = $$DESFileNameRef;
    
    my $fileRoot = "\\oss\\models\\DifferentialEquations\\";
    my $fileFound = 1;

    my $linesFound = copyFileToAlgebraicTheoryLines("$fileRoot$DESFileName.DES",$AlgebraicTheoryHandle,"DESMASTER");
    if ( $linesFound == 0 )
    {
        my $modelNameFromFileRef = getSubTree($globalASTRef,"MODEL_NAME_FROM_FILE");
        my $modelNamefromFile = $$modelNameFromFileRef;
        $linesFound = copyFileToAlgebraicTheoryLines("$fileRoot$modelNamefromFile.DES",$AlgebraicTheoryHandle,"DESMASTER");
    }
    
    copyFileToAlgebraicTheoryLines("$fileRoot$DESFileName.PK",$AlgebraicTheoryHandle,"PKMASTER");
 
	my $priorsStringRef = getSubTree($globalASTRef,"PRIORS");
	my $priorsString = $$priorsStringRef;
	my $priorsAsAlgebraicTheory = splitEquations("PRIORS", $priorsString,"\~");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($priorsAsAlgebraicTheory);

	my @priorsStringsForEtas = ();
	my $priorsForEtasRef = getSubTree($globalASTRef,"PRIORSForEtas");
	if ( ref($priorsForEtasRef) )
	{
		@priorsStringsForEtas = @$priorsForEtasRef;
	}
	
	my $firstLine = 1;
	my $priorsStringForEtas = "";
	for ( my $iLine = 1; $iLine <= scalar(@priorsStringsForEtas); $iLine++)
	{
		my @distributionForEta = $priorsStringsForEtas[$iLine-1];
		$priorsStringForEtas .= "PRIORSForEta, ";
		$priorsStringForEtas .= "eta[$iLine], ~, \"$distributionForEta[0]\"\n";
	}
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($priorsStringForEtas);
	
	%processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getNonmemIfThenExpression,
		modifyDifferentialExpression		 => \&adaptDifferentialExpressionForStateVariable,
		assignmentOperator                   => " = "
	);
 
	%tags = ( label  => "DES", startTag => "VECTOR_FIELD, VECTOR_FIELD, = , \[", separator => ",", endTag  => " \]\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Right', subRoutine => "" );
	
	my $vectorFieldExpressions = "";
	( $vectorFieldExpressions, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($vectorFieldExpressions);	

	%tags = ( label  => "PKScaleFactors", startTag => "SCALE_FACTORS, SCALE_FACTORS, =, \[", separator => " ", endTag  => " ]\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
	my $PKScaleFactors;
	( $PKScaleFactors, $state ) = getInfoFromSubTree($globalASTRef,"PKScaleFactors",\%tags,0);
	$PKScaleFactors =~ s/\n\s*\n/\n/g;
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($PKScaleFactors);

	%tags = ( label => "OBSERVATION_FUNCTIONS", startTag => "", endTag  => "\n", separator => "\n", routine => \&getHashOfFunctions, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"OBSERVATION_FUNCTIONS",\%tags,0);
	$infoStringForAlgebraicTheory = splitEquations("OBSERVATION_FUNCTIONS",$infoString,"=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
		
	$improveThis = 1;
	if ( $improveThis == 1 )
	{
		my $outputExpressions =~ s/EXP\(ERR1\)/ERR1/g;
	}
	%tags = ( label  => "ERROR", startTag => "OBSERVATION_VARIABLES, OBSERVATION_VARIABLES, =, \"\[ ", separator =>", ", endTag  => "\]\"\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
	my ( $coStateVariables, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($coStateVariables);
	
	my $inputVariables   = "";

	print $AlgebraicTheoryHandle <<AlgebraicTheoryPart1;
AlgebraicTheoryPart1

	%processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getNonmemVersionOfVariable,
		getIfThenExpression                  => \&getWinbugsIfThenExpression 
	);

	#%tags = ( label  => "DES", startTag => "DES, ", separator =>"\nDES, ", endTag  => "", routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Both', subRoutine => "" );
	#my ( $differentialEquations, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
	#print $AlgebraicTheoryHandle $differentialEquations, "\n";
	
	my $allVariables = $stateVariables . ",extra," . $parameters;

	%tags = ( label  => "ERROR", startTag => "ERROR, ", separator =>"\nERROR, ", endTag  => "\n",routine => \&getDifferentialEquations, processingMethods => \%processingMethods, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);
	$infoStringForAlgebraicTheory = splitLabelAndEquations("ERROR",$infoString,"\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
   
	%tags = ( label  => "THETA", startTag => "", separator =>"\n", endTag  => "", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaBoundsForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"THETA",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "THETA", startTag => "", separator =>"", endTag  => "", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaInitialValuesForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"THETA",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

    %tags = ( label  => "THETA", startTag => "", separator =>"", endTag  => "", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaBoundsAndInitialValuesForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"THETA",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "ETA", startTag => "", separator =>"\n", endTag  => "\n", routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"ETA",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "ETA", startTag => "ETAInitial,EtaInitial, =, \[ ", separator =>", ", endTag  => "]\"\n", routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesAsListForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"ETA",\%tags,0);
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "SIGMA", startTag => "SIGMAInitial, ", separator =>", ", endTag  => "\n", routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesForAlgebraicTheories );
	( $infoString, $state ) = getInfoFromSubTree($globalASTRef,"SIGMA",\%tags,0);
	$improveThis = 1;
	$infoString =~ s/,sigma//;
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "TABLE", startTag => "TABLE, ", endTag  => "\n", separator => ' ', routine => \&getHashOfArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	$infoStringForAlgebraicTheory = splitOutVectorAndAttributePairs("TABLE", "colNames", $infoString,"\=");
	print $AlgebraicTheoryHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);

	%tags = ( label  => "COVA", startTag => "COVA, ", endTag  => "\n", routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $printHandle Util_convertToLambdaExpression($infoString);

	%tags = ( label  => "ESTIMATION", startTag => "ESTIMATION, ", endTag  => "\n", separator => ' ', routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	$infoStringForAlgebraicTheory = splitOutVectorAndAttributePairs("ESTIMATION","ESTIMATION", $infoString,"\=");
	print $printHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
	
	%tags = ( label  => "SCAT", startTag => "SCAT, ", endTag  => "\]\n", routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	$infoStringForAlgebraicTheory = splitOutVectorAndAttributePairs("SCAT","SCAT", $infoString,"\=");
	print $printHandle Util_convertToLambdaExpression($infoStringForAlgebraicTheory);
	
	close($AlgebraicTheoryHandle);
	
}

$improveThis = 1; #should not need this routine.
sub splitLabelAndEquations
{
	my ($label, $equationString, $separator) = @_;
	my $finalString = "";
	
	my @labelsAndEquations = split(/\n/,$equationString);
	
	foreach my $labelAndEquation ( @labelsAndEquations)
	{
		my ( $label, $equation ) = split(", ", $labelAndEquation);
		my ( $lhs, $rhs) = split(/=|\~/,$equation);
		$finalString .= $label . ", " .  $lhs . ", " . $separator . ", " . "\"" . $rhs . "\"" . "\n";
	}
	return ( $finalString);
	
}

$improveThis = 1; #should not need this routine.
sub splitEquations
{
	my ($label, $equationString, $separator) = @_;
	my $finalString = "";
	
	my @labelsAndEquations = split(/\n/,$equationString);
	
	foreach my $equation ( @labelsAndEquations)
	{
		my ( $lhs, $rhs) = split(/=|\~/,$equation);
		$finalString .= $label . ", "  . $lhs . ", " . $separator . ", " . "\"" . $rhs . "\"" . "\n";
	}
	return ( $finalString);
	
}


sub splitOutFunctionAndFunctionValues
{
	my ($label, $equationString, $separator) = @_;
	my $finalString = "";
	
	my @labelsAndEquations = split(/\n/,$equationString);
	
	foreach my $equation ( @labelsAndEquations)
	{
		$equation =~ s/\s+//g;
		my ( $lhs, $center, $blank) = split(/\(|\)/,$equation);
		if ( defined($center))
		{
		    my @params = split(/,/,$center);
		    $params[1] =~ s/DEF//g;
		    $finalString .= $label . ", " . $params[1] . "(" . $params[0] . ")" . ", " . "=" . ", " . "TRUE";
		    $finalString .= "\n";
		}
	}
	return ( $finalString);
	
}

sub splitOutSingleStringAndAttributes
{
	my ($label, $label1, $equationString, $separator) = @_;
	my $finalString = "";
	
	my ($lhs, $rhs, @equations ) = split(/,/,$equationString);
	
	$finalString .= $lhs . ", " . $label1 . ", " . "\=" . ", " . $rhs . "\n";
	
	foreach my $equation ( @equations)
	{
		my ( $lhs, $rhs) = split(/=/,$equation);
		if ( ! defined($lhs))
		{
		    $lhs = "";
		}
		if ( ! defined($rhs))
		{
		    $rhs = "";
		}
		
		$finalString .= $label . ", " . $lhs . ", " . "\"" . q(=) . "\""  . ", " . $rhs . "\n";
	}
	return ( $finalString);
	
}

sub splitOutVectorAndAttributePairs
{
	my ($label, $label1, $equationString, $separator) = @_;
	my $finalString = "";
	
	my ($lhs, @equations ) = split(/,|\s+/,$equationString);
	
	$finalString .= $lhs . ", " . $label1 . ", " . "\=" . " , " . " [ ";
	my $optionsBegun = 0;
	foreach my $equation ( @equations)
	{
		if ( $equation =~ /ONEHEADER/)
		{
			$optionsBegun = 1;
			$finalString .= " ]\n"; 
			$finalString .= $lhs . ", " . "options" . ", " . "\=" . " , " . " [ ";
		}
		
		unless ( $equation =~ /=/)
		{
			 $finalString .= " " . $equation;
		}
		else
		{
			my ( $lhs, $rhs) = split(/=/,$equation);
			$finalString .= " ]\n"; 
			$finalString .= $label . ", " . $lhs . ", " . "\"" . q(=) . "\""  . ", " . $rhs . "\n";
		}
	}
	return ( $finalString);
	
}


sub writeMapleFile
{
	my $globalASTRef = $_[0];
	my $TLCOutputFileName   = $_[1];
	my $dataFileName         = $_[2];
	
	my %processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getMapleVersionOfVariable,
		getIfThenExpression                  => \&getMapleIfThenExpression 
	);

	my $mapleFileName = $TLCOutputFileName;
	$mapleFileName =~ s/\.TLC/\.mpl/ig;
	#$mapleFileName =~ s/\.TLC/\.ctl/ig;
	
	open(MAPLEFILE,">$mapleFileName" ) or die("Could not open Maple file $mapleFileName\n");
	$mapleFileHandle = *MAPLEFILE;
	#$mapleFileHandle = *STDOUT;
	
	print $mapleFileHandle "#---------------------------------------------------------------------\n";

	$printHandle = $mapleFileHandle;
	
	my %tags = (	label    => "PROBLEM ", startTag => ";\#PROBLEM", endTag  => "\n", separator => " ", printHandle => $mapleFileHandle, routine => \&getSingleString, subRoutine => \&reportMainTagAndValue);
	
	my $infoString;
	
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "INPUT ", startTag => "\#INPUT", endTag  => "\n",internalStartTag => "", internalEndTag => "",routine => \&reportArrayOfValues, separator => " ",subRoutine => \&reportTagAndValueOrHashGeneral, printHandle => $mapleFileHandle);
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags, 0);

	%tags = ( label  => "DATA ", startTag => "\#DATA", endTag  => "\n", routine => \&reportArrayOfValues, separator => " ",subRoutine => \&reportTagAndValueOrHashGeneral, printHandle => $mapleFileHandle );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "SUBROUTINE ", startTag => "\#SUBROUTINE", endTag  => "\n", separator => " ", routine => \&reportArrayOfValues,subRoutine => \&reportTagAndValueOrHashGeneral, printHandle => $mapleFileHandle );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "MODEL ", startTag => "\#MODEL", endTag  => "\n", printHandle => $mapleFileHandle, separator => " ",routine => \&reportArrayOfValues, subRoutine => \&reportTagAndValueOrExpressionGeneral);
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	my %processingMethodsForStateVariables = (
		getLanguageSpecificVersionOfVariable => \&getJetVersionOfVariable,
		getIfThenExpression                  => \&getMapleIfThenExpression,
		modifyDifferentialExpression		 => \&modifyDifferentialExpression,
		assignmentOperator                   => " = "

	);

	%tags = ( label  => "PK", startTag => "\n	", separator => "\n	,", endTag  => "",  routine => \&getDifferentialEquations, getLeftRightOrBothSides => 'Both', processingMethods => \%processingMethodsForStateVariables, subRoutine => "" );
	my ( $PKEquations, $state ) = getInfoFromSubTree($globalASTRef,"PK",\%tags,0);

	%tags = ( label  => "DES", startTag => "", separator => "\n	,", endTag  => "\n", printHandle => $mapleFileHandle, routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForStateVariables, getLeftRightOrBothSides => 'Right', subRoutine => "" );
	my $vectorFieldExpressions;
	( $vectorFieldExpressions, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
		
	%tags = ( label  => "DES", startTag => "\nS:=[\n	", separator => "\n	", endTag  => "\n];\n", routine => \&getDifferentialEquations, getLeftRightOrBothSides => 'Both', processingMethods => \%processingMethods, subRoutine => "" );
	$vectorFieldExpressions = removeAnyFunctionDependencies( $vectorFieldExpressions,"t");
	my $parameters = join(",", keys(%variablesWithoutNumericSuffixes));
	
	$improveThis = 0; #rph not sure, 02/08
	if ( $improveThis )
	{
		$parameters .= ",ERR1";
	}

#	my $observationFunctionsRef = getSubTree($globalASTRef,"OBSERVATION_FUNCTIONS");
#	($globalASTRef,$state)  = modifySubTree($globalASTRef,"ERROR",\&checkForNames,\&replaceNames,$observationFunctionsRef,"",0,100,0);

	my %processingMethodsForJetVariables = (
		getLanguageSpecificVersionOfVariable => \&getJetVersionOfVariable,
		getIfThenExpression                  => \&getMapleIfThenExpression,
		modifyDifferentialExpression		 => \&modifyDifferentialExpression,
		assignmentOperator                   => " = "
 
	);
	
	%processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getMapleVersionOfVariable,
		getIfThenExpression                  => \&getWinbugsIfThenExpression 
	);

	my $useMine = 0; #improve this -- temporarily, just use masters.
	
	my @mapleDifferentialEquations = ();
	if ( $useMine )
    {	
	    %tags = ( label  => "DES", startTag => "\nS:=[\n	", separator => ",\n	", endTag  => "\n];\n", 
	        printHandle => $mapleFileHandle, routine => \&getDifferentialEquations, 
	        getLeftRightOrBothSides => 'Both', processingMethods => \%processingMethods, subRoutine => "" );
	    my $differentialEquations;
	    ( $differentialEquations, $state ) = getInfoFromSubTree($globalASTRef,"DES",\%tags,0);
		print $mapleFileHandle $differentialEquations, "\n";

	}
	
	my $useMaster = 1; #improve this
	if ( $useMaster )
    {	
	    %tags = ( label  => "DESMASTER", startTag => "\nS:=[\n	", separator => ",\n	", endTag  => "\n];\n", 
	        printHandle => $mapleFileHandle, routine => \&getDifferentialEquations, 
	        getLeftRightOrBothSides => 'Both', processingMethods => \%processingMethods, subRoutine => "" );
	    my $differentialEquationsMaster;
	    ( $differentialEquationsMaster, $state ) = getInfoFromSubTree($globalASTRef,"DESMASTER",\%tags,0);
		@mapleDifferentialEquations = split(/\n/,$differentialEquationsMaster);
		
		my $dosingRef = getSubTree($globalASTRef,"DOSING");
		my $dosing = $$dosingRef;

		my $routingRef = getSubTree($globalASTRef,"ROUTING");
		my $routing = $$routingRef;
		
		my $dosingExpression = "";
		if ( $routing eq "INFUSION" )
		{
		     $dosingExpression = "AMT*(Heaviside(t) - Heaviside(t-1))";
        }
        elsif ( $dosing eq "MD"  )
        {
            $dosingExpression = "sum(AMT*Dirac(24*day-t), day = 3 .. 9)";
        }
        elsif ( $dosing eq "SS"  )
        {
            $dosingExpression = "";
        }

        if ( $dosingExpression ne "" )
        {
            for ( my $i = 0; $i < scalar(@mapleDifferentialEquations); $i++ )
            {
                if ( $mapleDifferentialEquations[$i] =~ /diff/)
                {
                    chomp $mapleDifferentialEquations[$i];
                    my $addComma = 0;
                    if ( $mapleDifferentialEquations[$i] =~ /,\s*$/)
                    {
                       $mapleDifferentialEquations[$i] =~ s/,\s*$//g;
                       $addComma = 1;
                    }
                    $mapleDifferentialEquations[$i] .= ' ' . '+ ' . $dosingExpression;
                    if ( $addComma )
                    {
                        $mapleDifferentialEquations[$i] .= ", ";
                    }    
                    $differentialEquationsMaster = join("\n",@mapleDifferentialEquations);
                    last;
                }
            }
        }
        print $mapleFileHandle $differentialEquationsMaster, "\n";
  
	}
	
	%tags = ( label  => "ERROR", startTag => "", separator => "\n	,", endTag  => "\n", printHandle => $mapleFileHandle, routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForJetVariables, getLeftRightOrBothSides => 'Right', subRoutine => "" );
	my $outputExpressions;
	( $outputExpressions, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);

	$improveThis = 1;
	if ( $improveThis )
	{
		$outputExpressions =~ s/EXP\(ERR1\)/ERR1/g;
	}
	%tags = ( label  => "ERROR", startTag => "", separator => ",", endTag  => "", printHandle => $mapleFileHandle, routine => \&getDifferentialEquations, processingMethods => \%processingMethodsForJetVariables, getLeftRightOrBothSides => 'Left', subRoutine => "" );
	my $coStateVariables;
	( $coStateVariables, $state ) = getInfoFromSubTree($globalASTRef,"ERROR",\%tags,0);
	
	my $inputVariables   = "";
	
	my $stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
	my $stateVariables;
	if ( ref($stateVariablesRef))
	{
		$stateVariables = $$stateVariablesRef;
	}
	else
	{
		$stateVariables = $stateVariablesRef;
	}

	my @allStateVariables = split(/\[s,]+/,$stateVariables);
	
	my $stateDependencies = "";

	foreach my $stateVariable ( @allStateVariables )
	{
		$stateDependencies .= "$stateVariable(t)";
	}
	$stateDependencies .= ", extra(t), myDenom(t)";

	print $mapleFileHandle <<maplePart1;

\#Define dependencies
#declare($stateDependencies):

\#Define Assumptions 
maplePart1

    if ( 0 )
    {
	    %tags = ( label  => "THETA", startTag => "assume(", endTag  => "\n):\n", separator => ", ", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaBounds, indentLevel => 1 );
	    ( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	    print $mapleFileHandle $infoString;
    	
	    %tags = ( label  => "OMEGA", startTag => "assume(", endTag  => "\):\n", separator => ", ", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaBounds, indentLevel => 1 );
	    ( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	    print $mapleFileHandle $infoString;
    }
    
	my $first = 1;
	my %variablesWithoutSuffixes = %$variablesWithoutNumericSuffixesRef; 
	
	my $dependenciesOnVectorsRef = getSubTree($globalASTRef,"VECTOR_VARIABLE_DEPENDENCIES");
    #improve this -- use data already in the global syntax tree.
 	my $defaultPrefix = 'tv';
 	my $arrayOfPKNamesRef = getSubTree($globalASTRef,"PK_VARIABLE_NAMES_ORIGINAL");
    $infoString = getPKVariableNamesAsNTuple($dependenciesOnVectorsRef, "THETA", $arrayOfPKNamesRef, $defaultPrefix );
    my @variables = Util_convertNTupleAsStringToVector($infoString);
    my @variablesWithoutNumericSuffixes =  keys ( %variablesWithoutSuffixes );
    my @allAssumptions = sort (@variables, @variablesWithoutNumericSuffixes);
    
    my $lastVar = "";
	foreach my $key ( @allAssumptions )
	{	
	    next if $lastVar eq $key;
	    
		if ( $first )
		{
			print	$mapleFileHandle "assume(\n\t 0 < $key";
			$first = 0;
		}
		else
		{
			print $mapleFileHandle "\n	,0 < $key"; 
		}
	    $lastVar = $key;

	}
	
	#rph Improve this 05/21/08 -- determine the maximum dose time here and use instead of 288.
	print $mapleFileHandle "\n\t,0<= t\n	,t < 288\n\t,0<= AMT\n\t,0 <= myDenom(t)\n):";

    #hack 05/30/08 -- need to define dosing compartment.
    my $iDosingCompartment = 1;
    my $routingRef = getSubTree($globalASTRef,"ROUTING");
    my $routing = $$routingRef;
    my $dosingRef = getSubTree($globalASTRef,"DOSING");
    my $dosing = $$dosingRef;
   
    my $initialConditionsString = MAPLE_getInitialConditionsString(\@mapleDifferentialEquations,$iDosingCompartment,$dosing,$routing);
print $mapleFileHandle <<maplePart1b;

\#Define initial conditions
	$initialConditionsString

\#Define the basic differential equations
maplePart1b
	
	my $allVariables = $stateVariables . ",extra," . $parameters;
	
	my $iFirst = 1;
	my $appendOrNot = "";

	my $mapleFileNameForLatex = "$mapleFileName.tex";
    $mapleFileNameForLatex =~ s/\//\\\\/g;
	foreach my $DEQ ( @mapleDifferentialEquations)
    {
        print $mapleFileHandle <<maplePart1c;

\#Save Latex versions of differential equations
	latex(S, "$mapleFileNameForLatex"$appendOrNot);

maplePart1c

        $appendOrNot = ",append";
    }
    
	my $fileNameForDEQs = "$mapleFileName.DEQS";
	$fileNameForDEQs =~ s/\//\\\\/g;
	
    my $fileNameForExplicitSolution = "$mapleFileName.integrated";
	$fileNameForExplicitSolution =~ s/\//\\\\/g;

	print $mapleFileHandle <<maplePart1c;

\#Consolidate the basic equations and the initial conditions.
SandICS := [op(S), op(ics)]:

\#Solve the basic system
mySol := simplify(dsolve(SandICS));

maplePart1c

	if ( $dosing eq "SS" )
	{
		print $mapleFileHandle <<maplePart1d;

\#Use one particular approach for obtaining steady state results...
myLhs := lhs(mySol);
myRhs := rhs(mySol);
myRhs := simplify(sum(myRhs, t = 0 .. infinity ));
mySol := myLhs = myRhs;
		
maplePart1d

	}

	print $mapleFileHandle <<maplePart2;
		
stringForSolution := simplify(convert(mySol,string)):

S := simplify(S);
results := dpolyform(S);

save mySol, S, results, "$fileNameForDEQs";
save stringForSolution, "$fileNameForExplicitSolution";

latex(mySol, "$mapleFileNameForLatex", 'append');

\#--------------------------------------------------------------------------------
\#Convert to polynomial form, and remove the denominators
\#Step 1: remove the denominators.
myRhs := 1:
for i to nops(S) do 
	x := op(i, S):
	for j to nops(x) do 
		y1 := op(j, x); y := simplify(y1):
		if denom(y) <> 1 then 
			myDenom := denom(y):
			k1 := algsubs(denom(y) = 1, y):
			myRhs := subsop(j = numer(y)*extra(t), x):
			iSave1 := i; iSave2 := j:
			S[iSave1] := myRhs :
		end if;
	end do;
end do;

\#Step 2: The next step is to add in an additional variable
eqExtra := 'diff(extra(t), t)' = 'extra(t)^2'*(diff(myDenom, t)):
for k to nops(S) do 
	eqExtra := algsubs(lhs(S[k]) = rhs(S[k]), eqExtra) 
end do:
S := [op(S), eqExtra]:

\#Step 3: add in an additional initial condition for the additional variable.
extraCondition := extra(0) = 1/myDenom;
extraCondition := algsubs(t = 0, extraCondition);
for k to nops(ics) do 
	extraCondition := algsubs(lhs(ics[k]) = 0, extraCondition) 
end do;
ics := [ics, extraCondition];
\#--------------------------------------------------------------------------------

\#Construct the differential ring needed to find the characteristic set.
SAsDifferentialRing := S;
for k to nops(S) do 
	SAsDifferentialRing[k] := lhs(S[k])-rhs(S[k]) 
end do;
R := differential_ring(ranking = [$allVariables], derivations = [t], notation = 'diff');

\#Finally, compute the characteristic set ( does not work yet )
Results := Rosenfeld_Groebner(SAsDifferentialRing, R);
\#--------------------------------------------------------------------------------

\#Construct the differential ring needed to find the characteristic set.
SAsDifferentialRing := S:
for k to nops(S) do 
	SAsDifferentialRing[k] := lhs(S[k])-rhs(S[k]) 
end do:

\#Finally, compute the characteristic sets
Results := Rosenfeld_Groebner(SAsDifferentialRing, R);

maplePart2

	%tags = ( label  => "ERROR", startTag => "\#ERROR ", separator =>"; ", endTag  => "\n", routine => \&getDifferentialEquations, processingMethods => \%processingMethods, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;

	%tags = ( label  => "THETA", startTag => "\#THETA ", separator =>" ", endTag  => "\n", routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;

	%tags = ( label  => "ETA", startTag => "\#OMEGA ", separator =>" ", endTag  => "\n", routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;
	
	%tags = ( label  => "SIGMA", startTag => "\#SIGMA ", separator =>" ", endTag  => "\n", printHandle => $mapleFileHandle, routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;

	%tags = ( label  => "TAB", startTag => "\#TAB ", endTag  => "\n", separator => ' ', printHandle => $mapleFileHandle, routine => \&getHashOfArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	if ( defined($infoString))
	{
	    print $mapleFileHandle $infoString;
    }
	%tags = ( label  => "COVA", startTag => "\#COVA ", endTag  => "\n", printHandle => $mapleFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;
	
	%tags = ( label  => "EST", startTag => "\#EST ", endTag  => "\n", separator => ' ', printHandle => $mapleFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	if ( defined($infoString))
	{
	    print $mapleFileHandle $infoString;
    }
    
	%tags = ( label  => "SCAT", startTag => "\#SCAT ", endTag  => "\n", printHandle => $mapleFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	print $mapleFileHandle $infoString;

	$stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
	
	if ( ref($stateVariablesRef) )
	{
		$stateVariables = $$stateVariablesRef;
	}
	else
	{
		$stateVariables = $stateVariablesRef;
	}
	
print $printHandle <<Sedaglovic;

##-----------------------------------------------------------------------------#
\##								     	System 
# Description 	: 
\# Result	:
\#
\#-----------------------------------------------------------------------------#
infolevel[observabilityTest] := 1 :
infolevel[observabilitySymmetries] := 1 :
t := 't':
\#-----------------------------------------------------------------------------#
\# Bibliography : see Monolix standard
\#-----------------------------------------------------------------------------#
\# We assume that diff(Variables[i],t) = VectorsField[i]
VectorField:= [
	$vectorFieldExpressions
]:  
   	
\# We assume that OutputsVariables[i] = OutputSystem[i].
OutputSystem := [
	$outputExpressions
] :

\#-----------------------------------------------------------------------------#
OutputsVariables:= [$coStateVariables] 					:
Inputs 		:= [$inputVariables] 					:
Parameters 	:= [$parameters]					:
\# The variables have to be ordered as the vectors field.
Variables 	:= [$stateVariables] 					:
\#-----------------------------------------------------------------------------#
NonObservable := observabilityTest(	VectorField	,
					Variables	,
					OutputSystem	,
					Parameters	,
					Inputs			) :
print(%) :					
GroupInfGen := observabilitySymmetries(	VectorField	,
					Variables	,
					OutputSystem	,
					Parameters	,
					Inputs		,
					NonObservable		) :
print(%) :
\#-----------------------------------------------------------------------------#

Sedaglovic

close($mapleFileHandle);
	
}

sub getLanguageIndependentVersionOfBaseVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ( $name eq "I" || $name eq "DV" )
	{
		$outName = "IVar";
	}
	return ( $outName);
}

sub getMapleVersionOfBaseVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ( $name eq "I" || $name eq "DV" )
	{
		$outName = "IVar";
	}
	return ( $outName);
}

sub getNonmemVersionOfBaseVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ( $name eq "I" || $name eq "DV" )
	{
		$outName = "IVar";
	}
	$outName =~ s/\./\_/g;
	return ( $outName);
}

sub getWinbugsVersionOfBaseVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ( $name eq "I" || $name eq "DV" )
	{
		$outName = "IVar";
	}
	return ( $outName);
}

sub modifyDifferentialExpression 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ($name =~ /diff\((.*)\((.*)/)
	{
		$outName = $1;
	}
	return ( $outName);
}

sub adaptDifferentialExpressionForStateVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ($name =~ /diff\((.*)\((.*)/)
	{
		$outName = $1;
	}

	if ($name =~ /diff\((.*)\)/)
	{
		$outName = $1;
		$outName =~ s/,t//g;
	}

	if ($name =~ /DADT(\d+)/)
	{
		$outName = "A$1";
	}
			
	if ($name =~ /D\((.*)\)/)
	{
		$outName = $1;
		$outName =~ s/,t//g;
	}
	
	if ( $name eq "DADT")
	{
		$outName = "A1";
	}

	return ( $outName);
}

sub useNonmemDifferentialExpression 
{
	my $name = $_[0];
	my $outName = $name;
	
	if ($name =~ /D\(A(\d).*/)
	{
		$outName = "DADT($1)";
	}
	
	if ($name =~ /diff\(A(\d).*/i)
	{
		$outName = "DADT($1)";
	}

	return ( $outName);
}

sub getWinbugsVersionOfVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	my $baseVariable = substr($outName,0,length($outName)-1);
	my $suffix       = substr($outName,-1);
	
	my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
	
	if ( $treeForThisVariableRef )
	{
		my $iOffsetForUseOf0 = getOffsetForPossibleUseOfZero($treeForThisVariableRef );
		$suffix += $iOffsetForUseOf0;
		$baseVariable = getWinbugsVersionOfBaseVariable($baseVariable);
		if ( $outName =~ /^eta/i)
		{
			$outName = "$baseVariable\[iSubject,$suffix\]";
		}
		else
		{
			$outName = "$baseVariable\[iObs,$suffix\]";
		}
		if ( $logitFunctions{$name} )
		{
			my $winbugsName = getWinbugsVersionOfVariable($logitFunctions{$name});
			$outName = "logit\($winbugsName\)";
		}
	}
	elsif ( $outName =~ /\(/)
	{
		$outName =~ s/\((.*)\)/\[$1\]/g;

		if ( $outName =~ /^eta/i )
		{
			$outName =~ s/ETA\[(.*)\]/ETA\[Subject\[iObs\],$1\]/ig;
		}
	}
	elsif ( $outName =~ /TIME|DOSE/)
	{
		$outName = "$outName\[iObs\]";
	}
	return ( $outName);
}

sub getNonmemVersionOfVariable 
{
	my $name = $_[0];
	
	my $outName = $name;
	
	if ( defined($outName) )
	{
    	
	    my $baseVariable = substr($outName,0,length($outName)-1);
	    my $suffix       = substr($outName,-1);
    	
	    my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
    	
	    if ( $treeForThisVariableRef )
	    {
		    my $iOffsetForUseOf0 = getOffsetForPossibleUseOfZero($treeForThisVariableRef );
		    $suffix += $iOffsetForUseOf0;
		    $outName = getNonmemVersionOfBaseVariable($baseVariable);
		    $outName = $outName . $suffix;

	    }
	    elsif ( $outName =~ /\[|\(/)
	    {
		    $outName =~ s/\[(.*)\]/\($1\)/g;
		    $outName =~ s/\(t\)//g;
		    $outName =~ s/\,t//g;

	    }
	    elsif ( $outName =~ /TIME|DOSE/)
	    {
	    }
	
	    $outName =~ s/\./\_/g;
    }
    
	return ( $outName);
}

sub getLanguageIndependentVersionOfVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	$outName =~ s/\(|\)|\]\)//g;
	
	my $baseVariable = substr($outName,0,length($outName)-1);
	my $suffix       = substr($outName,-1);
	
	my $treeForThisVariableRef = "";
	
	if ( $suffix =~ /\d+/ )
	{
	    $treeForThisVariableRef  = $variablesWithNumericSuffixes{$baseVariable};
    	    
    	if ( $treeForThisVariableRef )
	    {
		    my $iOffsetForUseOf0 = getOffsetForPossibleUseOfZero($treeForThisVariableRef );
		    $suffix += $iOffsetForUseOf0;
		    $outName = getLanguageIndependentVersionOfBaseVariable($baseVariable);
	    }
	}
	elsif ( $outName =~ /\[/)
	{
		$outName =~ s/\[(.*)\]/\($1\)/g;
	}
	elsif ( $outName =~ /TIME|DOSE/)
	{
	}
	return ( $outName);
}

sub getMapleVersionOfVariable 
{
	my $name = $_[0];
	my $outName = $name;
	
	#Improve this;
	unless ( $name =~ /^K\d+/)
	{
	    my $baseVariable = substr($outName,0,length($outName)-1);
	    my $suffix       = substr($outName,-1);
    	
	    my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
    	
	    if ( $treeForThisVariableRef )
	    {
		    my $iOffsetForUseOf0 = getOffsetForPossibleUseOfZero($treeForThisVariableRef );
		    $suffix += $iOffsetForUseOf0;
		    $outName = getMapleVersionOfBaseVariable($baseVariable);

	    }
	    elsif ( $outName =~ /\[/)
	    {
		    $outName =~ s/\[(.*)\]/\($1\)/g;
	    }
	    elsif ( $outName =~ /TIME|DOSE/)
	    {
	    }
	}
	return ( $outName);
}


sub getJetVersionOfVariable 
{
	my $name = $_[0];
	my $outName = modifyDifferentialExpression($name);	
	#$outName =~ s/\((t)\)//g;
	$outName =~ s/\((\d)\)/$1/g;
	return ( $outName);
}

sub getOffsetForPossibleUseOfZero 
{
	my $treeForUseOfThisVariableRef = $_[0];
	my $iOffset = 0;

	if ( ref($treeForUseOfThisVariableRef) && $treeForUseOfThisVariableRef =~ /HASH/)
	{
		my %treeForUseOfThisVariable = %$treeForUseOfThisVariableRef;
		my @keys = sort(keys(%treeForUseOfThisVariable));
		
		if ( $keys[0] == 0 )
		{
			$iOffset = 1;
		}
	}
	
	return ( $iOffset);
}


sub determineCATEGORICAL_VARIABLES
{

	my $globalASTRef = $_[0];
	
	my %processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getWinbugsVersionOfVariable,
		getIfThenExpression                  => \&getWinbugsIfThenExpression 
	);
	
	my $processingMethodsRef = \%processingMethods;
	
	my $predTreeRef = getSubTree($globalASTRef,"PRED");
	unless ( ref($predTreeRef) && ( $predTreeRef =~ /HASH/ or $predTreeRef =~ /ARRAY/ ))
	{
		print "Possible ERROR since no PRED provided\n";
		return;
	}

	my @predEquations = @$predTreeRef;
	
	my %baseVariablesUsed = ();
	my $additionalString = "";
	
	for ( my $iEquation = $#predEquations; $iEquation >= 0; $iEquation-- )
	{
		my $equationTreeRef = $predEquations[$iEquation];

		my %equation = %$equationTreeRef;
		my $leftSideRef = $equation{"left"};
		my %leftSide = %$leftSideRef;
		my $outName = $leftSide{"name"};
		
		if ( $outName eq "Y" )
		{
			my $varName = "DV";
			my $dataForDVRef = $IfThenExpressionsForVariables{$varName};
			my %dataForDV    = %$dataForDVRef;
			my $nKeys = scalar(keys(%dataForDV));
			$varName = getWinbugsVersionOfBaseVariable($varName);
			$baseVariablesUsed{$varName} = 1;
			$additionalString .= "$outName\[iObs\] ~ dcat\($varName\[iObs,1:$nKeys\]\)";
			next;
		}
		
		my $baseVariable = substr($outName,0,length($outName)-1);
		my $suffix       = substr($outName,-1);
		my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
		if ( $suffix =~ /\d/ && $treeForThisVariableRef  )
		{
			$baseVariable = getWinbugsVersionOfBaseVariable($baseVariable);

			next if ( $baseVariablesUsed{$baseVariable} );
			next if ( $inverseLogitFunctions{$baseVariable} );

			$baseVariablesUsed{$baseVariable} = 1;
			my %treeForThisVariable = %$treeForThisVariableRef;
	
			my $iKeyOffsetForUseOf0 = getOffsetForPossibleUseOfZero(\%treeForThisVariable);
			foreach my $key ( sort(keys(%treeForThisVariable )))
			{
				my $rightTreeRef = $treeForThisVariable{$key};
				my $rightHandExpression = getExpression($rightTreeRef,$processingMethodsRef);
				my $variable = $baseVariable . $key;
				my $winBugsVariable = getWinbugsVersionOfVariable($variable);
				#$additionalString .= "		$winBugsVariable <- $rightHandExpression\n";
			}
			#$additionalString .= "\n";
		}
		else
		{
			my %equationTree = %$equationTreeRef;
			my $leftSide     = getExpression($equationTree{"left"},$processingMethodsRef);
			my $oper         = getExpression($equationTree{"oper"},$processingMethodsRef);
			$oper            = "\<\-";
			my $rightSide    = getExpression($equationTree{"right"},$processingMethodsRef);
			#$additionalString .= "		$leftSide $oper $rightSide\n";
		
		}	
	}
	
	#$additionalString .= <<WinBugsEnd;
	#}
#WinBugsEnd

	return ( $additionalString);
	
}

sub getPriorsForThetasAsString
{
	my $globalASTRef = $_[0];
	
	my $additionalString = "";
	
	my $priorsStringRef = getSubTree($globalASTRef,"PRIORS");
	$improveThis = 1; #should not need to do this next step.
	my $localPriorString = $$priorsStringRef;
	$localPriorString =~ s/;\#//g;
	$additionalString .=  $localPriorString;

	return ( $additionalString);	
	
}

sub writeWinbugsOut
{

	$globalASTRef = $_[0];
	my $TLCOutputFileName   = $_[1];
	
	my %processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getWinbugsVersionOfVariable,
		getIfThenExpression                  => \&getWinbugsIfThenExpression 
	);
	
	my $processingMethodsRef = \%processingMethods;
	
	my $predTreeRef = getSubTree($globalASTRef,"PRED");
	unless ( ref($predTreeRef) && ( $predTreeRef =~ /HASH/ or $predTreeRef =~ /ARRAY/ ))
	{
		print "Possible ERROR since no PRED provided\n";
		$globalASTRef = copySubTree($globalASTRef,"PK","PRED");
		$improveThis =1; #do for DES as well (?)
		$predTreeRef = getSubTree($globalASTRef,"PRED");
	}

	my $WinbugsFileName = $TLCOutputFileName;
	$WinbugsFileName =~ s/\.TLC/\.bugs/ig;
	
	open(WinbugsFILE,">$WinbugsFileName" ) or die("Could not open Winbugs file $WinbugsFileName\n");
	print WinbugsFILE "---------------------------------------------------------------------\n";
	my $winbugsFileHandle = *WinbugsFILE;
	
	$printHandle = $winbugsFileHandle;

	my @priorsStringsForEtas = ();
	my $priorsStringsForEtasRef = getSubTree($globalASTRef,"PRIORSForEtas");
	if ( ref($priorsStringsForEtasRef) )
	{
		@priorsStringsForEtas = @$priorsStringsForEtasRef;
	}
	
	print $printHandle <<WinBugs1;

model {

	for (iSubject in 1:nSubjects)
	{
WinBugs1
	
	for (my $i = 1; $i <= scalar(@priorsStringsForEtas);$i++)
	{
		my $LHSString = "ETA[iSubject,$i] ~ ";
		print $printHandle <<WinBugs1a;
		$LHSString $priorsStringsForEtas[$i-1]
WinBugs1a
	}

print $printHandle <<WinBugs1b;
	}
	
	for (iObs in 1:nObs) 
	{
WinBugs1b

	my @predEquations = @$predTreeRef;
	
	my %baseVariablesUsed = ();
	
	for ( my $iEquation = $#predEquations; $iEquation >= 0; $iEquation-- )
	{
		my $equationTreeRef = $predEquations[$iEquation];

		my %equation = %$equationTreeRef;
		
		my $leftSideRef = $equation{"left"};
		my %leftSide = %$leftSideRef;
		my $outName = $leftSide{"name"};
		if ( $outName eq "Y" )
		{
			my $varName = "DV";
			my $dataForDVRef = $IfThenExpressionsForVariables{$varName};
			my %dataForDV    = %$dataForDVRef;
			my $nKeys = scalar(keys(%dataForDV));
			$varName = getWinbugsVersionOfBaseVariable($varName);
			$baseVariablesUsed{$varName} = 1;
			print $printHandle <<IfThenExpressionsAsDCAT;
		$outName\[iObs\] ~ dcat\($varName\[iObs,1:$nKeys\]\)
		
IfThenExpressionsAsDCAT
	
			next;
		}
		
		my $baseVariable = substr($outName,0,length($outName)-1);
		my $suffix       = substr($outName,-1);
		my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
		if ( $suffix =~ /\d/ && $treeForThisVariableRef  )
		{
			$baseVariable = getWinbugsVersionOfBaseVariable($baseVariable);

			next if ( $baseVariablesUsed{$baseVariable} );
			next if ( $inverseLogitFunctions{$baseVariable} );

			$baseVariablesUsed{$baseVariable} = 1;
			my %treeForThisVariable = %$treeForThisVariableRef;
	
			my $iKeyOffsetForUseOf0 = getOffsetForPossibleUseOfZero(\%treeForThisVariable);
			foreach my $key ( sort(keys(%treeForThisVariable )))
			{
				my $rightTreeRef = $treeForThisVariable{$key};
				my $rightHandExpression = getExpression($rightTreeRef,$processingMethodsRef);
				my $variable = $baseVariable . $key;
				my $winBugsVariable = getWinbugsVersionOfVariable($variable);
				print $printHandle "		$winBugsVariable <- $rightHandExpression\n";
			}
			print $printHandle "\n";
		}
		else
		{
			my %equationTree = %$equationTreeRef;
			my $leftSide     = getExpression($equationTree{"left"},$processingMethodsRef);
			my $oper         = getExpression($equationTree{"oper"},$processingMethodsRef);
			$oper            = "\<\-";
			my $rightSide    = getExpression($equationTree{"right"},$processingMethodsRef);
			print $printHandle "		$leftSide $oper $rightSide\n";
		
		}	
	}
	
	print $printHandle <<WinBugsEnd;
	}
WinBugsEnd

	my $priorsStringRef = getSubTree($globalASTRef,"PRIORS");
	$improveThis = 1; #should not need to do this next step.
	my $localPriorString = $$priorsStringRef;
	$localPriorString =~ s/;\#//g;
	print $printHandle $localPriorString;

	print $printHandle <<WinBugsEnd;
}
WinBugsEnd
	return;

}

sub writeWinbugsOutMethod2
{

	$globalASTRef = $_[0];
	my $TLCOutputFileName   = $_[1];
	
	my %processingMethods = (
		getLanguageSpecificVersionOfVariable => \&getWinbugsVersionOfVariable,
		getIfThenExpression                  => \&getWinbugsIfThenExpression 
	);
	
	my $processingMethodsRef = \%processingMethods;
	
	my $predTreeRef = getSubTree($globalASTRef,"PRED");
	unless ( ref($predTreeRef) && ( $predTreeRef =~ /HASH/ or $predTreeRef =~ /ARRAY/ ))
	{
		print "Possible ERROR since no PRED provided\n";
		$globalASTRef = copySubTree($globalASTRef,"PK","PRED");
		$improveThis =1; #do for DES as well (?)
		$predTreeRef = getSubTree($globalASTRef,"PRED");
	}

	my $WinbugsFileName = $TLCOutputFileName;
	$WinbugsFileName =~ s/\.TLC/\.bugs/ig;
	
	open(WinbugsFILE,">$WinbugsFileName" ) or die("Could not open Winbugs file $WinbugsFileName\n");
	print WinbugsFILE "---------------------------------------------------------------------\n";
	my $winbugsFileHandle = *WinbugsFILE;
	
	$printHandle = $winbugsFileHandle;

	my @priorsStringsForEtas = ();
	my $priorsStringsForEtasRef = getSubTree($globalASTRef,"PRIORSForEtas");
	if ( ref($priorsStringsForEtasRef) )
	{
		@priorsStringsForEtas = @$priorsStringsForEtasRef;
	}
	
	print $printHandle <<WinBugs1;

model {

	for (iSubject in 1:nSubjects)
	{
WinBugs1

	
	for (my $i = 1; $i <= scalar(@priorsStringsForEtas);$i++)
	{
		my $LHSString = "ETA[iSubject,$i] ~ ";
		print $printHandle <<WinBugs1a;
		$LHSString $priorsStringsForEtas[$i-1]
WinBugs1a
	}

print $printHandle <<WinBugs1b;
	}
	
	for (iObs in 1:nObs) 
	{
WinBugs1b

	my @predEquations = @$predTreeRef;
	
	my %baseVariablesUsed = ();
	
	for ( my $iEquation = $#predEquations; $iEquation >= 0; $iEquation-- )
	{
		my $equationTreeRef = $predEquations[$iEquation];

		my %equation = %$equationTreeRef;
		
		my $leftSideRef = $equation{"left"};
		my %leftSide = %$leftSideRef;
		my $outName = $leftSide{"name"};
		if ( $outName eq "Y" )
		{
			my $varName = "DV";
			my $dataForDVRef = $IfThenExpressionsForVariables{$varName};
			my %dataForDV    = %$dataForDVRef;
			my $nKeys = scalar(keys(%dataForDV));
			$varName = getWinbugsVersionOfBaseVariable($varName);
			$baseVariablesUsed{$varName} = 1;
			print $printHandle <<IfThenExpressionsAsDCAT;
		$outName\[iObs\] ~ dcat\($varName\[iObs,1:$nKeys\]\)
		
IfThenExpressionsAsDCAT
	
			next;
		}
		
		my $baseVariable = substr($outName,0,length($outName)-1);
		my $suffix       = substr($outName,-1);
		my $treeForThisVariableRef = $variablesWithNumericSuffixes{$baseVariable};
		if ( $suffix =~ /\d/ && $treeForThisVariableRef  )
		{
			$baseVariable = getWinbugsVersionOfBaseVariable($baseVariable);

			next if ( $baseVariablesUsed{$baseVariable} );
			next if ( $inverseLogitFunctions{$baseVariable} );

			$baseVariablesUsed{$baseVariable} = 1;
			my %treeForThisVariable = %$treeForThisVariableRef;
	
			my $iKeyOffsetForUseOf0 = getOffsetForPossibleUseOfZero(\%treeForThisVariable);
			foreach my $key ( sort(keys(%treeForThisVariable )))
			{
				my $rightTreeRef = $treeForThisVariable{$key};
				my $rightHandExpression = getExpression($rightTreeRef,$processingMethodsRef);
				my $variable = $baseVariable . $key;
				my $winBugsVariable = getWinbugsVersionOfVariable($variable);
				print $printHandle "		$winBugsVariable <- $rightHandExpression\n";
			}
			print $printHandle "\n";
		}
		else
		{
			my %equationTree = %$equationTreeRef;
			my $leftSide     = getExpression($equationTree{"left"},$processingMethodsRef);
			my $oper         = getExpression($equationTree{"oper"},$processingMethodsRef);
			$oper            = "\<\-";
			my $rightSide    = getExpression($equationTree{"right"},$processingMethodsRef);
			print $printHandle "		$leftSide $oper $rightSide\n";
		
		}	
	}
	
	print $printHandle <<WinBugsEnd;
	}
WinBugsEnd

	my $priorsStringRef = getSubTree($globalASTRef,"PRIORS");
	$improveThis = 1; #should not need to do this next step.
	my $localPriorString = $$priorsStringRef;
	$localPriorString =~ s/;\#//g;
	print $printHandle $localPriorString;

	print $printHandle <<WinBugsEnd;
}
WinBugsEnd
	return;
	
	my $infoString = "";
	
	my %tags = ( label    => "PROBLEM", startTag => "\$PROBLEM ", endTag  => "\n", separator => " ", printHandle => $winbugsFileHandle, routine => \&getProblemGeneral, subRoutine => \&getMainTagAndValue);
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "INPUT", startTag => "\$INPUT ", endTag  => "\n",internalStartTag => "", internalEndTag => "",routine => \&getArrayOfValues, separator => " ",subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $winbugsFileHandle);
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags, 0);

	%tags = ( label  => "DATA", startTag => "\$DATA ", endTag  => "\n", routine => \&getArrayOfValues, separator => " ",subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $winbugsFileHandle );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "SUBROUTINE", startTag => "\$SUBROUTINE ", endTag  => "\n", separator => " ", routine => \&getArrayOfValues,subRoutine => \&getTagAndValueOrHashGeneral, printHandle => $winbugsFileHandle );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "MODEL", startTag => "\$MODEL ", endTag  => "\n",printHandle => $winbugsFileHandle, separator => " ",routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrExpressionGeneral);
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "PK", startTag => "\$PK ", endTag  => "\n", separator => "\n", printHandle => $winbugsFileHandle, routine => \&getDifferentialEquations, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "PRED", startTag => "\$PRED\n", endTag  => "\n", separator => "\n", printHandle => $winbugsFileHandle, routine => \&getDifferentialEquations, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "DES", startTag => "\$DES ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getDifferentialEquations, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "ERROR", startTag => "\$ERROR\n", separator =>"\n", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getDifferentialEquations, subRoutine => \&dummy );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "THETA", startTag => "\$THETA\n", separator =>" ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getHashOfArrayOfValuesInParentheses, subRoutine => \&getThetaGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "ETA", startTag => "\$OMEGA ", separator =>" ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "SIGMA", startTag => "\$SIGMA ", separator =>" ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getHashOfArrayOfValues, subRoutine => \&getOmegaInitialValuesGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "TAB", startTag => "\$TAB ", endTag  => "\n", separator => ' ', printHandle => $winbugsFileHandle, routine => \&getHashOfArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "COVA", startTag => "\$COVA ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
	
	%tags = ( label  => "EST", startTag => "\$EST ", endTag  => "\n", separator => ' ', printHandle => $winbugsFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);

	%tags = ( label  => "SCAT", startTag => "\$SCAT ", endTag  => "\n", printHandle => $winbugsFileHandle, routine => \&getArrayOfValues, subRoutine => \&getTagAndValueOrHashGeneral );
	( $infoString, $state ) = getInfoFromTree($globalASTRef,\%tags,0);
		 
}

#---------------------------------------------------------------------------------------------------------

#package TLC

sub Util_convertDirectoryOfTypedLambdaCalculusFilesToCSVForm
{
    if ( scalar(@_) < 3 )
    {
        return "Sorry, not enough arguments\n";
    }
    my ( $inputsDirectory, $extension, $outputsDirectory ) = @_;
    
    my $oldSeparator = $/;
    
    $/ = "\n";
    
    opendir(RUNDIR,$inputsDirectory) or die("Could not open run directory $inputsDirectory\n");
    my @files = grep ( /\.$extension/i, readdir(RUNDIR));
    close(READDIR);
    
    foreach my $fileIn ( @files )
    {
	    print $fileIn,"\n";
        my $fileOut = $fileIn;
        $fileOut =~ s/\.$extension/\.CSV/ig;
        Util_convertStatMLAlgebraicTheoryFileToCSVForm("$inputsDirectory/$fileIn","$outputsDirectory/$fileOut");
    }
    
    $/ = $oldSeparator;
    
}

sub Util_convertStatMLAlgebraicTheoryFileToCSVForm
{
    my ( $fileIn,  $fileOut ) = @_;

    my $oldSeparator = $/;
    $/ = "\n";
    
	open (INPUTFILE,"$fileIn") or die ("Could not open input file $fileIn\n");
	
    my @data = <INPUTFILE>;
    chomp @data;
    close(INPUTFILE);

    my @newData = ();
    foreach my $datum ( @data )
    {
        my $CSVExpression = Util_convertLambdaExpressionToCSVForm($datum);
        push(@newData,$CSVExpression);
	}
	
	open (OUTPUTFILE,">$fileOut") or die ("Could not open input file $fileOut\n");
    print OUTPUTFILE  join("\n",@newData);
    close(OUTPUTFILE);
    
    $/ = $oldSeparator;

}

sub TLC_OptimizeTLCFile
{
    my ( $fileIn,  $fileOut ) = @_;

    my $oldFileInputSeparator = $/;
    $/ = "\n";
    
	open (INPUTFILE,"$fileIn") or die ("Could not open input file $fileIn\n");
	
    my @data = <INPUTFILE>;
    chomp @data;
    close(INPUTFILE);

    #First get all of the types in use.
    my @typesInUse = ();
    foreach my $lambdaExpression ( @data )
    {
        
        my $relationalOperator = "\=";
        if ( $lambdaExpression =~ /\~/)
        {
		    $relationalOperator = "\~";
	    }
	    my @parts = split(/$relationalOperator/,$lambdaExpression,2);
	    if ( ! defined($parts[1]))
	    {
	        $parts[1] = "";
	    }
    	
        my ($name,$type);
        if ( defined($parts[0]))
        {
            ($name,$type) = split(/:/,$parts[0]);
        }
        if ( Util_isInList($type,@typesInUse ) < 0 )
        {
            push(@typesInUse,$type);
        }

	}
	
	my @lambdaExpressions = ();
	foreach my $typeToCheck ( @typesInUse )
	{
	    my @dataForThisType = ();
	    my $allRHSAreScalars = 1;
	    my @pastLambdaExpressionsForThisType = ();

	    foreach my $lambdaExpression ( @data )
        {
            
            my $relationalOperator = "\=";
            if ( $lambdaExpression =~ /\~/)
            {
		        $relationalOperator = "\~";
	        }
	        my @parts = split(/$relationalOperator/,$lambdaExpression,2);
	        if ( ! defined($parts[1]))
	        {
	            $parts[1] = "";
	        }
        	
            my ($name,$type);
            if ( defined($parts[0]))
            {
                ($name,$type) = split(/:/,$parts[0]);
            }
            
            if ( ! defined($type) or $type eq "" )
            {
                next;
            }
            if ( $type ne $typeToCheck )
            {
                next;
            }
            my $vector = $parts[1];
            $vector =~ s/\"|\[|\]//g;
            $vector =~ s/^\s+|\s+$//g;
            my @data = split(/,|\s+/,$vector);
            if ( scalar(@data) == 1 && $data[0] =~ /^[\d\.]*$/ && $allRHSAreScalars )
            {
                push(@dataForThisType,$data[0]);
                push(@pastLambdaExpressionsForThisType,$lambdaExpression); 
            }
            else
            {
                if ( $allRHSAreScalars == 1 && scalar(@pastLambdaExpressionsForThisType ) > 0 )
                {
                    push(@lambdaExpressions,@pastLambdaExpressionsForThisType);
                    @pastLambdaExpressionsForThisType = ();
                }
                $allRHSAreScalars = 0;
                push(@lambdaExpressions,$lambdaExpression); 
            }
	    }
	    
	    if ( $allRHSAreScalars )
	    {
	        my $dataForThisTypeString = join(",", @dataForThisType);
	        my $totalLambdaExpression = $typeToCheck . ":" . $typeToCheck . "=" . "[ " . $dataForThisTypeString . " ] ";
	        push(@lambdaExpressions,$totalLambdaExpression); 
        }
    }
	
	open (OUTPUTFILE,">$fileOut") or die ("Could not open input file $fileOut\n");
    print OUTPUTFILE  join("\n",@lambdaExpressions);
    close(OUTPUTFILE);
    
    $/ = $oldFileInputSeparator;

}



sub Util_convertDirectoryOfStatMLDataFilesToTypedLambdaCalculus
{
    if ( scalar(@_) < 4 )
    {
        return "Sorry, not enough arguments\n";
    }
    my ( $inputsDirectory, $extension, $outputsDirectory, $outputExtension, $criterion ) = @_;
    
    my $oldFileInputSeparator = $/;
    
    $/ = "\n";
    
    opendir(RUNDIR,$inputsDirectory) or die("Could not open run directory $inputsDirectory\n");
    my @files = grep ( /\.$extension/i, readdir(RUNDIR));
    close(READDIR);
    
    foreach my $fileIn ( @files )
    {
	    print $fileIn,"\n";
        my $fileOut = $fileIn;
        $fileOut =~ s/\.$extension/\.$outputExtension/ig;
        Util_convertStatMLDataToTypedLambdaCalculus("$inputsDirectory/$fileIn","$outputsDirectory/$fileOut",$criterion);
    }
    
    $/ = $oldFileInputSeparator;
    
}



#---------------------------------------------------------------------------


sub TLC_getModel
{
    my ($fileIn) = @_;
    
    open(FILE,$fileIn) or die("Could not open $fileIn\n");

    my %abstractSyntaxTree = ();
    
	while(<FILE>)
	{
		chomp;
		next unless (/\w/);
		my @data = split(/,/,$_,4);
		for ( my $i = 0; $i < scalar(@data); $i++ )
		{
			$data[$i] =~ s/^\s+|\s+$//g;
		}

		my $initialField = $data[0];

		my ( $mainField, $subField ) = split(/\(|\[/,$data[1]);
		if ( defined($subField))
		{
			$subField =~ s/\)|\]//g;
		}
		my $expression = "";
		my $comment = "";
		
		my $relationalOp = $data[2];
		if ( $data[3] =~ /\#/)
		{
			if ( $data[3] =~ /^\s*\#\s*$/)
			{	
				$expression = $data[3];
				$comment = "";
			}
			else
			{
				( $expression, $comment ) = split(/\#/,$data[3]);
				$expression .= "\"";
				$comment = "\"" . $comment;
			}
		}
		else
		{
			$expression = $data[3];
		}

		$expression =~ s/\#|\"|\[|\]//g;
		$expression =~ s/^\s+|\s$//g;
		my @fieldNames = split(/[\s,]+/,$expression);

		my %tree = (
			mainField  => $mainField,
			subField   => $subField,
			relationalOp=>$relationalOp,
			expression => $expression,
			comment    => $comment 
		);

		my @arrayOfTrees = ();
		my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
		if ( defined($arrayOfTreesRef) && $arrayOfTreesRef ne "" )
		{
			@arrayOfTrees = @$arrayOfTreesRef;
		}
		else
		{
			@arrayOfTrees = ();
		}
		push(@arrayOfTrees,\%tree);

		$abstractSyntaxTree{$initialField} = \@arrayOfTrees;
	}
	close(FILE);
	
	return (\%abstractSyntaxTree);
}

sub Util_reformatMatlabCodeInDirectory
{
	use strict;
	my @files = <*.M>;
	my $iLineReset = 0;
	foreach my $file ( @files)
	{
		open(FILE,$file) or die("Could not open monolix file $file");
		open(FILEOUT,">indented/$file");
		my @lines = <FILE>;
		my $indents = "";
		for ( my $iLine = 0; $iLine < scalar(@lines); $iLine++)
		{
			$_ = $lines[$iLine];
			chomp;
			if (/^\s*function.*=/)
			{
				$indents = "";
				$iLineReset = 0;
			}

			if (/^end\s+/)
			{
				$indents =~ s/    //o;
			}
			if (/^end\s+/)
			{
				$indents =~ s/    //o;
			}
			$_ =~ s/^\s+//g;
			$_ =~ s/^\t//g;

			print FILEOUT $indents;
			print FILEOUT $_;
			if (/^\s*for.*=/)
			{
				$indents .= "    ";
			}
			if ( $iLineReset == 0 )
			{
				$indents = "    ";
			}
			print FILEOUT "\n";
		}
		close(FILEOUT);
	}
}

sub TLC_getExpression
{
	my ($abstractSyntaxTreeRef, $initialField) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};

	my @arrayOfTrees = @$arrayOfTreesRef;

	my $treeRef = $arrayOfTrees[0];

	my %tree    = %$treeRef;

	my $expression = $tree{"expression"};

	$expression =~ s/\#|\"|\[|\]//g;
			
	return ($expression);
}

sub TLC_getVector
{
	my ($abstractSyntaxTreeRef, $initialField, $subField) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	unless (defined($arrayOfTreesRef) && $arrayOfTreesRef =~ /ARRAY/)
	{
	    print "Error in TLC_getVector - no vector data found for $initialField\n";
	    return("")
	}
	my @arrayOfTrees    = @$arrayOfTreesRef;

    my $expression = "";
	for ( my $i = 0; $i < scalar(@arrayOfTrees); $i++ )
	{

		my $treeRef = $arrayOfTrees[$i];
		my %tree    = %$treeRef;
		
		my $subFieldHere   = $tree{"mainField"};
		
		if ( !defined($subField) or $subField eq "" or $subFieldHere =~ /^$subField$/i )
		{
		    $expression = $tree{"expression"};
		    last;
        }
	}

	$expression =~ s/\#|\"|\[|\]//g;
	$expression =~ s/^\s+|\s$//g;
	my @fieldNames = split(/[\s,]+/,$expression);
			
	return (\@fieldNames);
}

sub TLC_getSetOfVectors
{
	my ($abstractSyntaxTreeRef, $initialField,$subField ) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	my @arrayOfArrays = ();
	unless ( $arrayOfTreesRef =~ /ARRAY/)
	{
		print "No set of vectors found for $initialField\n";
		return ( \@arrayOfArrays);
	}
	my @arrayOfTrees    = @$arrayOfTreesRef;

	for ( my $i = 0; $i < scalar(@arrayOfTrees); $i++ )
	{

		my $treeRef = $arrayOfTrees[$i];
		my %tree    = %$treeRef;
		my $expression = $tree{"expression"};

		$expression =~ s/\#|\"|\[|\]//g;
		$expression =~ s/^\s+|\s$//g;
		my @fieldNames = split(/[\s,]+/,$expression);
			
		push(@arrayOfArrays,\@fieldNames);

	}

	return (\@arrayOfArrays);
}

sub TLC_getLengthOfFirstDimension
{
	my ($abstractSyntaxTreeRef, $initialField ) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;
	
	my $sizeOfDimension = 0;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	
	if ( defined($arrayOfTreesRef ) && $arrayOfTreesRef =~ /ARRAY/)
	{
	    my @arrayOfTrees    = @$arrayOfTreesRef;
	    $sizeOfDimension = scalar(@arrayOfTrees);
    }
    else
    {
        print "ERROR: No array info found for $initialField\n";
        return ("");
    }
    
	return ($sizeOfDimension);
}

sub TLC_getSingleVector
{
	my ($abstractSyntaxTreeRef, $initialField,$subField ) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	
    my @singleArray           = ();

	if ( defined($arrayOfTreesRef ) && $arrayOfTreesRef =~ /ARRAY/)
	{
	    my @arrayOfTrees    = @$arrayOfTreesRef;

	    for ( my $i = 0; $i < scalar(@arrayOfTrees); $i++ )
	    {

		    my $treeRef = $arrayOfTrees[$i];
		    my %tree    = %$treeRef;
		    my $expression = $tree{"expression"};

		    $expression =~ s/\#|\"|\[|\]//g;
		    $expression =~ s/^\s+|\s$//g;
		    my @fieldNames = split(/[\s,]+/,$expression);
    			
		    push(@singleArray,@fieldNames);

	    }
    }
    else
    {
        print "ERROR: No array info found for $initialField\n";
        return ("");
    }
    
	return (\@singleArray);
}



sub TLC_getSetOfEquations
{
	my ($abstractSyntaxTreeRef, $initialField) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

    my @arrayOfArrays = ();

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	if ( ref($arrayOfTreesRef) && $arrayOfTreesRef =~ /ARRAY/ )
	{
	    my @arrayOfTrees    = @$arrayOfTreesRef;


	    for ( my $i = 0; $i < scalar(@arrayOfTrees); $i++ )
	    {

		    my $treeRef = $arrayOfTrees[$i];
		    my %tree    = %$treeRef;
		    my $expression = $tree{"expression"};

            my @parts;
            $parts[0] = $tree{"mainField"};
            $parts[1] = $tree{"subField"};
            $parts[2] = $tree{"relationalOp"};
            $parts[3] = $tree{"expression"};
            $parts[4] = $tree{"comment"};
            
		    push(@arrayOfArrays,\@parts);

	    }
    }
    
	return (\@arrayOfArrays);
}


sub TLC_getSubExpression
{
	my ($abstractSyntaxTreeRef, $initialField, $subField) = @_;

	my %abstractSyntaxTree = %$abstractSyntaxTreeRef;

	my $arrayOfTreesRef = $abstractSyntaxTree{$initialField};
	my @arrayOfTrees    = @$arrayOfTreesRef;

    my $expression = "";
	for ( my $i = 0; $i < scalar(@arrayOfTrees); $i++ )
	{

		my $treeRef = $arrayOfTrees[$i];
		my %tree    = %$treeRef;
		
		my $subFieldHere   = $tree{"mainField"};
		
		if ( $subFieldHere eq $subField )
		{
		    $expression = $tree{"expression"};
		    last;
        }
	}

	return ($expression);
}

sub deletedCode
{


	my $stateVariablesRef = getSubTree($globalASTRef,"PK_STATE_VARIABLES");
	if ( ref($stateVariablesRef) )
	{
		my $stateVariables = $$stateVariablesRef;
	}
	else
	{
		my $stateVariables = $stateVariablesRef;
	}

}

sub toInteger
{
    my $num = $_[0];
	my $iNum = sprintf("%d",$num);
    return ( $iNum );
}

1;


#---------------------------------------------------------------------------

1;
__END__

#----------------------------------------------------------------------------