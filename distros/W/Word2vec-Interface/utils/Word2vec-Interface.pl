#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    10/01/2016                                                             #
#    Revised: 06/18/2019                                                             #
#    UMLS Similarity Word2Vec Package Interface Driver                               #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                Perl "word2vec" package interface for UMLS Similarity               #
#    Note:                                                                           #
#    =====                                                                           #
#                This script utilizes command line arguments to execute commands.    #
#                Use "interface.pm" in for object oriented sub-routines.             #
#                                                                                    #
######################################################################################


use strict;
use warnings;

# Standard CPAN Module(s)
use Cwd;

# Word2Vec Module(s)
use Word2vec::Interface;


use vars qw($VERSION);

$VERSION = '0.038';

# Check For No Command-Line Arguments
AskHelp() if @ARGV == 0;
exit if @ARGV == 0;


######################################################################################
#                                                                                    #
#  Process Commands                                                                  #
#                                                                                    #
######################################################################################

# Time Variable(s)
my $startTime = time();

my $debugLog = 0;
my $writeLog = 0;
my $ignoreCompileErrors = 1;
my $ignoreFileChecks = 0;

# Set Global Options
for my $arg ( @ARGV )
{
    $debugLog = 1                   if ( $arg eq "--debuglog" ) || ( $arg eq "--test" );
    $writeLog = 1                   if ( $arg eq "--writelog" );
    $ignoreCompileErrors = 0        if ( $arg eq "--debuglog" );
    $ignoreFileChecks = 1           if ( $arg eq "--ignorefilechecks" ) || ( $arg eq "--help" ) || ( $arg eq "--version" ) || ( $arg eq "--clean" );
}

# Remove Global Options From @ARGV
my $tempParameterStr = join( '<sp>', @ARGV );
$tempParameterStr =~ s/--debuglog//g;
$tempParameterStr =~ s/--writelog//g;
$tempParameterStr =~ s/--ignorecompileerrors//g;
$tempParameterStr =~ s/--ignorefilechecks//g;

@ARGV = split( '<sp>', $tempParameterStr );

# Create new interface.pm Object
my $packageInterface = Word2vec::Interface->new( undef, $debugLog, $writeLog, $ignoreCompileErrors, $ignoreFileChecks );

# Parse and Execute Command-line Arguments
my $argIndex = 0;
my @commandAry = ();

if( $packageInterface->GetExitFlag() == 1 )
{
    for( $argIndex = 0; $argIndex < @ARGV; $argIndex++ )
    {
        my $arg = $ARGV[$argIndex];

        if( $arg eq "--version" )
        {
            ShowVersion();
            exit;
        }
        elsif( $arg eq "--help" )
        {
            ShowHelp();
            exit;
        }

        # Main Commands
        print "Finished Word2Vec File Checks\n"             if( $arg eq "--test"                   );
        CosSim()                                            if( $arg eq "--cos"                    );
        CosMulti()                                          if( $arg eq "--cosmulti"               );
        CosAvg()                                            if( $arg eq "--cosavg"                 );
        CosineSimilarityBetweenTwoFiles()                   if( $arg eq "--cos2v"                  );
        MultiCosUser()                                      if( $arg eq "--multiwordcosuserinput"  );
        AddVectors()                                        if( $arg eq "--addvectors"             );
        SubVectors()                                        if( $arg eq "--subtractvectors"        );
        W2VTrain()                                          if( $arg eq "--w2vtrain"               );
        W2PTrain()                                          if( $arg eq "--w2ptrain"               );
        CleanText()                                         if( $arg eq "--cleantext"              );
        CompileTextCorpus()                                 if( $arg eq "--compiletextcorpus"      );
        ConvertBinToText()                                  if( $arg eq "--converttotextvectors"   );
        ConvertTextToBin()                                  if( $arg eq "--converttobinaryvectors" );
        ConvertTextToSparse()                               if( $arg eq "--converttosparsevectors" );
        CompoundifyFile()                                   if( $arg eq "--compoundifyfile"        );
        FindSimilarTerms()                                  if( $arg eq "--findsimilarterms"       );
        Similarity()                                        if( $arg eq "--similarity"             );
        Spearmans()                                         if( $arg eq "--spearmans"              );
        SortVectorFile()                                    if( $arg eq "--sortvectorfile"         );
        WSD()                                               if( $arg eq "--wsd"                    );
        $packageInterface->CleanWord2VecDirectory()         if( $arg eq "--clean"                  );
    }

    PrintElapsedTime();
}
else
{
    print "Error: Exiting Script\n";
}

undef $packageInterface;
print "~Fin\n";


######################################################################################
#                                                                                    #
#   Sub-Routines                                                                     #
#                                                                                    #
######################################################################################

sub GetCommandOptions
{
    my $startIndex = shift;

    # Push First Element Off Of The Array
    shift( @ARGV );

    my $endCmdOptions = FindNextCommandIndex( $startIndex );

    # Decrement $argIndex If Next Command Found To Process Next Command
    $argIndex -= 2 if $endCmdOptions != -1;

    # Check(s)
    $endCmdOptions = @ARGV if $endCmdOptions == -1;

    # Compiling Command Options
    my @tempAry = splice( @ARGV, $startIndex, $endCmdOptions );
    my $hashRef = ParseOptions( join( '<sp>', @tempAry ) );

    undef( $endCmdOptions );
    undef( @tempAry );

    return $hashRef;
}

sub FindNextCommandIndex
{
    my $startindex = shift;

    for( my $i = $startindex; $i < @ARGV; $i++ )
    {
        return $i if $ARGV[$i] eq "--test";
        return $i if $ARGV[$i] eq "--cos";
        return $i if $ARGV[$i] eq "--cosmulti";
        return $i if $ARGV[$i] eq "--cosavg";
        return $i if $ARGV[$i] eq "--cos2v";
        return $i if $ARGV[$i] eq "--multiwordcosuserinput";
        return $i if $ARGV[$i] eq "--addvectors";
        return $i if $ARGV[$i] eq "--subtractvectors";
        return $i if $ARGV[$i] eq "--w2vtrain";
        return $i if $ARGV[$i] eq "--w2ptrain";
        return $i if $ARGV[$i] eq "--cleantext";
        return $i if $ARGV[$i] eq "--compiletextcorpus";
        return $i if $ARGV[$i] eq "--converttotextvectors";
        return $i if $ARGV[$i] eq "--converttobinaryvectors";
        return $i if $ARGV[$i] eq "--converttosparsevectors";
        return $i if $ARGV[$i] eq "--compoundifyfile";
        return $i if $ARGV[$i] eq "--findsimilarterms";
        return $i if $ARGV[$i] eq "--similarity";
        return $i if $ARGV[$i] eq "--spearmans";
        return $i if $ARGV[$i] eq "--sortvectorfile";
        return $i if $ARGV[$i] eq "--wsd";
        return $i if $ARGV[$i] eq "--clean";
    }

    return -1;
}

sub ParseOptions
{
    my $optionsStr = shift;

    my %options;
    my @optionsAry = split( '<sp>', $optionsStr );
    my $i = 0;

    while( $i < @optionsAry )
    {
        if( $i + 1 < @optionsAry && index( $optionsAry[$i+1], "-" ) != 0 )
        {
            $options{ $optionsAry[$i] } = $optionsAry[$i+1];
            $i += 2;
        }
        else
        {
            $options{ $optionsAry[$i] } = undef;
            $i++;
        }
    }

    # Print Options Hash
    #for my $option ( keys %options )
    #{
    #    print "Option: $option - Setting: $options{$option}\n" if defined( $option );
    #}

    return \%options;
}

sub CosSim
{
    my $vectorDataFile  = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $wordB           = $ARGV[$argIndex+3];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFile ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --cos vector_data_file_path wordA wordB\n";
        return;
    }

    my $value           = $packageInterface->CLComputeCosineSimilarity( $vectorDataFile, $wordA, $wordB );
    print "Cosine Similarity Between: \"$wordA\" and \"$wordB\": $value\n" if defined( $value );
    print "Error: Cosine Similarity Between: \"$wordA\" and \"$wordB\" - Cannot Be Computed\n" if !defined( $value );
    print "See log files for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub CosMulti
{
    my $vectorDataFile  = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $wordB           = $ARGV[$argIndex+3];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFile ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --cosmulti vector_data_file_path wordA1:wordA2 wordB1:wordB2\n";
        print "Note: This supports an unlimited amount of \"compounded\" words separated by ':' (colon character)\n";
        return;
    }

    my $value           = $packageInterface->CLComputeMultiWordCosineSimilarity( $vectorDataFile, $wordA, $wordB );
    print "Multi-Word Cosine Similarity Between: \"$wordA\" and \"$wordB\": $value\n" if defined( $value );
    print "Error: Multi-Word Cosine Similarity Between: \"$wordA\" and \"$wordB\" - Cannot Be Computed\n" if !defined( $value );
    print "See log files for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub CosAvg
{
    my $vectorDataFile  = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $wordB           = $ARGV[$argIndex+3];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFile ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --cosavg vector_data_file_path wordA1:wordA2 wordB1:wordB2\n";
        print "Note: This supports an unlimited amount of \"compounded\" words separated by ':'\n";
        return;
    }

    my $value           = $packageInterface->CLComputeAvgOfWordsCosineSimilarity( $vectorDataFile, $wordA, $wordB );
    print "Average Cosine Similarity Between: \"$wordA\" and \"$wordB\": $value\n" if defined( $value );
    print "Error: Average Cosine Similarity Between: \"$wordA\" and \"$wordB\" - Cannot Be Computed\n" if !defined( $value );
    print "See log files for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub CosineSimilarityBetweenTwoFiles
{
    my $vectorDataFileA = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $vectorDataFileB = $ARGV[$argIndex+3];
    my $wordB           = $ARGV[$argIndex+4];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFileA ) || !defined( $vectorDataFileB ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --cos vector_data_fileA_path wordA vector_data_fileB_path wordB\n";
        return;
    }

    my $wordAVector     = $packageInterface->W2VReadTrainedVectorDataFromFile( $vectorDataFileA, $wordA );
    my $wordBVector     = $packageInterface->W2VReadTrainedVectorDataFromFile( $vectorDataFileB, $wordB );
    $wordAVector        = $packageInterface->W2VRemoveWordFromWordVectorString( $wordAVector );
    $wordBVector        = $packageInterface->W2VRemoveWordFromWordVectorString( $wordBVector );
    my $value           = $packageInterface->W2VComputeCosineSimilarityOfWordVectors( $wordAVector, $wordBVector );
    print "Cosine Similarity Between: \"$wordA\" and \"$wordB\": $value\n" if defined( $value );
    print "Error: Cosine Similarity Between: \"$wordA\" and \"$wordB\" - Cannot Be Computed\n" if !defined( $value );
    print "See log files for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub MultiCosUser
{
    my $vectorDataFile  = $ARGV[$argIndex+1];

    if( !defined( $vectorDataFile ) )
    {
        print "Warning: Improper format\n";
        print "Format: --multiwordcosuserinput vector_data_file_path\n";
        return;
    }

    $packageInterface->CLMultiWordCosSimWithUserInput( $vectorDataFile );
}

sub AddVectors
{
    my $vectorDataFile  = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $wordB           = $ARGV[$argIndex+3];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFile ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --addvectors vector_data_file_path wordA wordB\n";
        return;
    }

    my $value           = $packageInterface->CLAddTwoWordVectors( $vectorDataFile, $wordA, $wordB );
    print "Result: $value\n" if defined( $value );
    print "Error: Vector Addition Cannot Be Computed\n" if !defined( $value );
    print "See \"Word2vecLog.txt\" log file for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub SubVectors
{
    my $vectorDataFile  = $ARGV[$argIndex+1];
    my $wordA           = $ARGV[$argIndex+2];
    my $wordB           = $ARGV[$argIndex+3];

    # Checks to see if required options have been specified
    if( !defined( $vectorDataFile ) || !defined( $wordA ) || !defined( $wordB ) )
    {
        print "Warning: Improper format\n";
        print "Format: --subtractvectors vector_data_file_path wordA wordB\n";
        return;
    }

    my $value           = $packageInterface->CLSubtractTwoWordVectors( $vectorDataFile, $wordA, $wordB );
    print "Result: $value\n" if defined( $value );
    print "Error: Vector Subtraction Cannot Be Computed\n" if !defined( $value );
    print "See \"Word2vecLog.txt\" log file for details\n" if !defined( $value ) && $packageInterface->GetWriteLog() == 1;
}

sub W2VTrain
{
    my $optionsHashRef   = GetCommandOptions( $argIndex );
    my %optionsHash      = %{ $optionsHashRef };

    # Argument Check(s)
    print "Error: \"-trainfile\" Not Defined\n" if( !defined( $optionsHash{ "-trainfile" } ) );
    print "Error: \"-outputfile\" Not Defined\n" if( !defined( $optionsHash{ "-outputfile" } ) );

    if( !defined( $optionsHash{ "-trainfile" } ) || !defined( $optionsHash{ "-outputfile" } ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --w2vtrain -trainfile text_corpus -outputfile word2vec_binary_filename -size _ -window _ -sample _ -negative _ -hs _ -binary _ -threads _ -iter _ -cbow _ -overwrite _\n\n";
        print "Minimal Requirements: -trainfile & -outputfile\n\n";
        print "Note: All options not specified will result in word2vec training using default options.\n";
        return;
    }

    my $result            = $packageInterface->CLStartWord2VecTraining( $optionsHashRef );
    print "Word2Vec Training Successful\n" if $result == 0;
    print "Word2Vec Training Not Successful\n" if $result != 0;
    print "See \"Word2vecLog.txt\" log file for details\n" if $result != 0 && $packageInterface->GetWriteLog() == 1;
}

sub W2PTrain
{
    my $optionsHashRef    = GetCommandOptions( $argIndex );
    my %optionsHash       = %{ $optionsHashRef };

    # Argument Check(s)
    print "Error: \"-trainfile\" Not Defined\n" if( !defined( $optionsHash{ "-trainfile" } ) );
    print "Error: \"-outputfile\" Not Defined\n" if( !defined( $optionsHash{ "-outputfile" } ) );

    if( !defined( $optionsHash{ "-trainfile" } ) || !defined( $optionsHash{ "-outputfile" } ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --w2ptrain -trainfile text_corpus -outputfile phrase_text_file -min-count _ -threshold _ -debug _ -overwrite _\n\n";
        print "Minimal Requirements: -trainfile & -outputfile\n\n";
        print "Note: All options not specified will result in word2phrase training using default options.\n";
        return;
    }

    my $result            = $packageInterface->CLStartWord2PhraseTraining( $optionsHashRef );
    print "Word2Phrase Training Successful\n" if $result == 0;
    print "Word2Phrase Training Not Successful - See \"Word2phraseLog.txt\" For Details\n" if $result != 0;
}

sub CleanText
{
    my $optionsHashRef    = GetCommandOptions( $argIndex );
    my %optionsHash       = %{ $optionsHashRef };
    
    # Argument Check(s)
    print "Error: \"-inputfile\" Not Defined" if( !defined( $optionsHash{ "-inputfile" } ) );
    
    if( !defined( $optionsHash{ "-inputfile" } ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --cleantext -inputfile _ -outputfile _\n\n";
        print "Minimal Requirements: -cleantext\n\n";
        print "Note: All options not specified will result in text corpus compilation using default options.\n";
        return;
    }
    
    my $result           = $packageInterface->CLCleanText( $optionsHashRef );
    print "Finished Text Cleaning\n" if $result == 0;
    print "Error Cleaning Text\n" if $result == -1;
    print "See \"util.txt\" log file for details\n" if $result == -1 && $packageInterface->GetWriteLog() == 1;
}

sub CompileTextCorpus
{
    my $optionsHashRef    = GetCommandOptions( $argIndex );
    my %optionsHash       = %{ $optionsHashRef };

    # Argument Check(s)
    print "Error: \"-workdir\" Not Defined\n" if( !defined( $optionsHash{ "-workdir" } ) );

    if( !defined( $optionsHash{ "-workdir" } ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --compiletextcorpus -workdir _ -savedir _ -startdate _ -enddate _ -title _ -abstract _ -qparse _ -compwordfile _ -sentenceperline _ -threads _ -overwrite _\n\n";
        print "Minimal Requirements: -workdir\n\n";
        print "Note: All options not specified will result in text corpus compilation using default options.\n";
        return;
    }

    my $result           = $packageInterface->CLCompileTextCorpus( $optionsHashRef );
    print "Finished Text Corpus Compilation\n" if $result == 0;
    print "Error Compiling Text Corpus\n" if $result == -1;
    print "See \"Xmltow2vLog.txt\" log file for details\n" if $result == -1 && $packageInterface->GetWriteLog() == 1;
}

sub ConvertBinToText
{
    my $fileToConvert   = $ARGV[$argIndex+1];
    my $saveName        = $ARGV[$argIndex+2];

    # Argument Check(s)
    print "Error: \"input_file\" Not Defined\n" if !defined( $fileToConvert );
    print "Error: \"output_file\" Not Defined\n" if !defined( $saveName );

    if( !defined( $fileToConvert ) || !defined( $saveName ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --converttotextvectors input_file output_file\n\n";
        return;
    }

    my $result          = $packageInterface->CLConvertWord2VecVectorFileToText( $fileToConvert, $saveName );
    print "Finished Conversion\n" if $result == 0;
    print "Unsuccessful Conversion\n" if $result == -1;
    print "See \"Word2vecLog.txt\" log file for details\n" if $result == -1 && $packageInterface->GetWriteLog() == 1;
}

sub ConvertTextToBin
{
    my $fileToConvert   = $ARGV[$argIndex+1];
    my $saveName        = $ARGV[$argIndex+2];

    # Argument Check(s)
    print "Error: \"input_file\" Not Defined\n" if !defined( $fileToConvert );
    print "Error: \"output_file\" Not Defined\n" if !defined( $saveName );

    if( !defined( $fileToConvert ) || !defined( $saveName ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --converttobinaryvectors input_file output_file\n\n";
        return;
    }

    my $result          = $packageInterface->CLConvertWord2VecVectorFileToBinary( $fileToConvert, $saveName );
    print "Finished Conversion\n" if $result == 0;
    print "Unsuccessful Conversion - See\"Word2vecLog.txt\" For Details\n" if $result == -1;
}

sub ConvertTextToSparse
{
    my $fileToConvert   = $ARGV[$argIndex+1];
    my $saveName        = $ARGV[$argIndex+2];

    # Argument Check(s)
    print "Error: \"input_file\" Not Defined\n" if !defined( $fileToConvert );
    print "Error: \"output_file\" Not Defined\n" if !defined( $saveName );

    if( !defined( $fileToConvert ) || !defined( $saveName ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --converttosparsevectors input_file output_file\n\n";
        return;
    }

    my $result          = $packageInterface->CLConvertWord2VecVectorFileToSparse( $fileToConvert, $saveName );
    print "Finished Conversion\n" if $result == 0;
    print "Unsuccessful Conversion - See\"Word2vecLog.txt\" For Details\n" if $result == -1;
}

sub CompoundifyFile
{
    my $fileToCompoundify = $ARGV[$argIndex+1];
    my $saveName          = $ARGV[$argIndex+2];
    my $compoundWordFile  = $ARGV[$argIndex+3];

    # Argument Check(s)
    print "Error: \"input_file\" Not Defined\n" if !defined( $fileToCompoundify );
    print "Error: \"output_file\" Not Defined\n" if !defined( $saveName );
    print "Error: \"compound_word_file\" Not Defined\n" if !defined( $compoundWordFile );

    if( !defined( $fileToCompoundify ) || !defined( $saveName ) || !defined( $compoundWordFile ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --compoundifyfile input_file output_file compound_word_file\n\n";
        return;
    }

    my $result           = $packageInterface->CLCompoundifyTextInFile( $fileToCompoundify, $saveName, $compoundWordFile );
    print "Finished Compoundify\n" if $result == 0;
    print "Error Compoundifying File\n" if $result == -1;
    print "See \"Xmltow2vLog.txt\" log file for details\n" if $result == -1 && $packageInterface->GetWriteLog() == 1;
}

sub SortVectorFile
{
    my $optionsHash = GetCommandOptions( $argIndex );
    my %options = %{ $optionsHash };

    # Check(s)
    print( "Error: No Options Specified\n" ) if scalar keys( %options ) == 0;

    if( !defined( $options{ "-filepath" } ) )
    {
        print "\nWarning: Improper Format\n";
        print "Format: --sortvectorfile -filepath file_path -overwrite _\n\n";
        print "Minimal Requirements: -filepath\n\n";
        print "Note: -overwrite option is optional. Replaced old file when enabled.\n";
        return;
    }

    return if scalar keys( %options ) == 0;

    my $result = $packageInterface->CLSortVectorFile( $optionsHash );
    print "Finished Sort And Save\n" if $result == 0;
    print "Finished - File Skipped\n" if $result == 1;
    print "Error Sorting And Saving File\n" if $result == -1;
    print "See \"Word2vecLog.txt\" log file for details\n" if $result == -1 && $packageInterface->GetWriteLog() == 1;
}

sub FindSimilarTerms
{
    my $optionsHash = GetCommandOptions( $argIndex );
    my %options     = %{ $optionsHash };

    # Check(s)
    if( scalar keys %options == 0 || !defined( $options{ "-vectors" } ) || !defined( $options{ "-term" } ) )
    {
        print "Warning: Improper format\n";
        print "Format: --findnearestterms -vectors vector_binary_file_path -term term -neighbors #_of_neighbors #_of_threads\n";
        return;
    }
    
    my $result = $packageInterface->W2VReadTrainedVectorDataFromFile( $options{ "-vectors" } );

    # Check(s)
    print "Error Reading Vector Binary File: \"" . $options{ "-vectors" } ."\"\n" if $result == -1;
    return if $result == -1;

    my $neighbors = $packageInterface->CLFindSimilarTerms( $options{ "-term" }, $options{ "-neighbors" }, $options{ "-threads" } );
    
    print "Error Finding Similar Terms\n" if !defined( $neighbors );
    return                                if !defined( $neighbors );

    # Results
    print "\n===========\n";
    print "- Results -\n";
    print "===========\n";

    for my $neighboringTerm ( @{ $neighbors } )
    {
        print "$neighboringTerm\n";
    }

    print "\n";
}

sub Spearmans
{
    my $svalFileA     = $ARGV[ $argIndex + 1 ];
    my $svalFileB     = $ARGV[ $argIndex + 2 ];

    # Check(s)
    if( !defined( $svalFileA ) || !defined( $svalFileB ) || $svalFileA eq "" || $svalFileB eq "" )
    {
        print "Warning: Improper format\n";
        print "Format: --spearmans file_path_a file_path_b\n";
        print "Note: Specifying \"-n\" will include N counts.\n";
        return;
    }

    my $optionsHash = GetCommandOptions( $argIndex );
    my %options = %{ $optionsHash };

    my $includeCounts = 1 if exists $options{ "-n" };

    # Check(s)
    print "Error: SVAL File Not Defined\n" if !defined( $svalFileA );
    print "Error: SVAL FIle Not Defined\n" if !defined( $svalFileB );
    return if !defined( $svalFileA ) || !defined( $svalFileB );

    print "Error: \"$svalFileA\" Cannot Be Found\n" if defined( $svalFileA ) && !( -e $svalFileA );
    print "Error: \"$svalFileB\" Cannot Be Found\n" if defined( $svalFileB ) && !( -e $svalFileB );
    return if ( defined( $svalFileA ) && !( -e $svalFileA ) ) || ( defined( $svalFileB ) && !( -e $svalFileB ) );

    # Calculate Spearman's Rank Correlation Score
    my $score = $packageInterface->SpCalculateSpearmans( $svalFileA, $svalFileB, $includeCounts );

    print "Spearman's Rank Correlation Score: $score\n"            if defined( $score );
    print "Spearman's Rank Correlation Score Cannot Be Computed\n" if !defined( $score );
}

sub Similarity
{
    my $optionsHash = GetCommandOptions( $argIndex );
    my %options = %{ $optionsHash };

    # Check(s)
    if( !defined( $options{ "-vectors" } ) || $options{ "-vectors" } eq "" )
    {
        print "Warning: Improper format\n";
        print "Format: --similarity -sim similarity_file_or_directory -vectors vector_data_file_path\n";
        print "Note: Not specifying \"-sim\" implies performing comparisons against all standardized files.\n";
        print "    : Using directory option, files must have \".sim\" extension.\n";
        print "    : \"-a\", \"-s\", \"-c\" or \"-all\" options can be added to determine which calculations are computed.\n";
        print "      No specified options implies \"-all\".\n";
        return;
    }

    return if keys( %options ) == 0;

    my $similarityFilePath    = $options{ "-sim" };
    my $vectorBinFilePath     = $options{ "-vectors" };

    print "Warning: Similarity File Or Directory Not Specified - Using Default Setting\n" if !defined( $similarityFilePath );
    $similarityFilePath = "./../Similarity/" if !defined( $similarityFilePath );

    # Check To See If Similarity And Vector Binary Files Exists
    print "Error: Similarity File Cannot Be Found\n" if !( -e $similarityFilePath );
    print "Error: Vector Binary File Cannot Be Found\n" if !( -e $vectorBinFilePath );
    return if !( -e $similarityFilePath ) || !( -e $vectorBinFilePath );

    my $averageOptionEnabled  = 0;
    my $compoundOptionEnabled = 0;
    my $summedOptionedEnabled = 0;

    # Check For Similarity Options
    my $endCmdOptionIndex = FindNextCommandIndex( $argIndex+1 );

    $endCmdOptionIndex = @ARGV if $endCmdOptionIndex == -1;

    $averageOptionEnabled  = 1 if( exists $options{ "-a" } ) || ( exists $options{ "-all" } );
    $compoundOptionEnabled = 1 if( exists $options{ "-c" } ) || ( exists $options{ "-all" } );
    $summedOptionedEnabled = 1 if( exists $options{ "-s" } ) || ( exists $options{ "-all" } );

    # Check For No Specified Options And Set "-all" If None Found
    if( $averageOptionEnabled == 0 && $compoundOptionEnabled == 0 && $summedOptionedEnabled == 0 )
    {
        $averageOptionEnabled  = 1;
        $compoundOptionEnabled = 1;
        $summedOptionedEnabled = 1;
    }

    # Load Vector Data
    print "Reading Vector Data File\n";
    my $success = $packageInterface->W2VReadTrainedVectorDataFromFile( $vectorBinFilePath );

    print "Finished Reading Vector Data File\n" if ( $success == 0 );
    print "Error Reading Vector Data File\n"    if ( $success != 0 );
    return                                      if ( $success != 0 );

    my $isWordOrCUIVectorData = $packageInterface->W2VIsWordOrCUIVectorData();
    print "CUI Term Vector Data Detected\n"     if ( $isWordOrCUIVectorData eq "cui" );
    print "Word Term Vector Data Detected\n"    if ( $isWordOrCUIVectorData eq "word" );

    print "Starting Similarity Computations\n";

    # Compute Cosine Similarity Based On Options
    my $isFileOrDir = $packageInterface->IsFileOrDirectory( $similarityFilePath );

    if( $isFileOrDir eq "dir" && $success == 0 )
    {
        my $listOfSimilarityFilesStr = $packageInterface->GetFilesInDirectory( $similarityFilePath, ".sim" );
        my @filesToParse = split( ' ', $listOfSimilarityFilesStr );

        for my $file ( @filesToParse )
        {
            print "Processing File: $file\n";

            my $isFileWordOrCUIFile = $packageInterface->SpIsFileWordOrCUIFile( "$similarityFilePath/$file" );

            if( $isFileWordOrCUIFile eq $isWordOrCUIVectorData )
            {
                my $result = 0;
                $result = $packageInterface->CLSimilarityAvg( "$similarityFilePath/$file" ) if ( $averageOptionEnabled == 1 );
                print "Error Processing File\n" if $result == -1;

                $result = $packageInterface->CLSimilarityComp( "$similarityFilePath/$file" ) if ( $compoundOptionEnabled == 1 );
                print "Error Processing File\n" if $result == -1;

                $result = $packageInterface->CLSimilaritySum( "$similarityFilePath/$file" ) if ( $summedOptionedEnabled == 1 );
                print "Error Processing File\n" if $result == -1;
            }
            else
            {
                print "Warning: Vector Vocabulary Data Detected As \"$isWordOrCUIVectorData\" Terms and Similarity File Detected As \"$isFileWordOrCUIFile\" Terms - Cannot Compare Files\n";
            }
        }
    }
    elsif( $isFileOrDir eq "file" && $success == 0 )
    {
        my $isFileWordOrCUIFile = $packageInterface->SpIsFileWordOrCUIFile( $similarityFilePath );

        if( $isFileWordOrCUIFile eq $isWordOrCUIVectorData )
        {
            $success = $packageInterface->CLSimilarityAvg( $similarityFilePath ) if ( $averageOptionEnabled == 1 );
            print "Error Processing File\n" if $success == -1;

            $success = $packageInterface->CLSimilarityComp( $similarityFilePath ) if ( $compoundOptionEnabled == 1 );
            print "Error Processing File\n" if $success == -1;

            $success = $packageInterface->CLSimilaritySum( $similarityFilePath ) if ( $summedOptionedEnabled == 1 );
            print "Error Processing File\n" if $success == -1;
        }
        else
        {
            print "Warning: Vector Vocabulary Data Detected As \"$isWordOrCUIVectorData\" Terms and Similarity File Detected As \"$isFileWordOrCUIFile\" Terms - Cannot Compare Files\n";
            $success = -1;
        }
    }

    # Clean Up
    $packageInterface->W2VClearVocabularyHash();


    # Perform Spearman's Rank Correlation Score Calculations
    if( defined( $isWordOrCUIVectorData ) && $isFileOrDir eq "dir" )
    {
        my %results = ();
        $similarityFilePath = Cwd::getcwd();

        print "Starting Spearman's Rank Correlation Score Calculations\n";

        # CUI Term Files
        if( $isWordOrCUIVectorData eq "cui" )
        {
            $results{ "MayoSRS.cuis.avg_results"                 }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.cuis.avg_results"            , "./../Similarity/MayoSRS.cuis.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.cuis.avg_results"             && $averageOptionEnabled  == 1 );
            $results{ "MayoSRS.cuis.comp_results"                }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.cuis.comp_results"           , "./../Similarity/MayoSRS.cuis.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.cuis.comp_results"            && $compoundOptionEnabled == 1 );
            $results{ "MayoSRS.cuis.sum_results"                 }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.cuis.sum_results"            , "./../Similarity/MayoSRS.cuis.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.cuis.sum_results"             && $summedOptionedEnabled == 1 );
            $results{ "MiniMayoSRS.cuis.coders.avg_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.avg_results"        , "./../Similarity/MiniMayoSRS.cuis.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.avg_results"         && $averageOptionEnabled  == 1 );
            $results{ "MiniMayoSRS.cuis.coders.comp_results"     }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.comp_results"       , "./../Similarity/MiniMayoSRS.cuis.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.comp_results"        && $compoundOptionEnabled == 1 );
            $results{ "MiniMayoSRS.cuis.coders.sum_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.sum_results"        , "./../Similarity/MiniMayoSRS.cuis.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.sum_results"         && $summedOptionedEnabled == 1 );
            $results{ "MiniMayoSRS.cuis.physicians.avg_results"  }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.avg_results"        , "./../Similarity/MiniMayoSRS.cuis.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.avg_results"         && $averageOptionEnabled  == 1 );
            $results{ "MiniMayoSRS.cuis.physicians.comp_results" }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.comp_results"       , "./../Similarity/MiniMayoSRS.cuis.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.comp_results"        && $compoundOptionEnabled == 1 );
            $results{ "MiniMayoSRS.cuis.physicians.sum_results"  }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.cuis.sum_results"        , "./../Similarity/MiniMayoSRS.cuis.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.cuis.sum_results"         && $summedOptionedEnabled == 1 );
            $results{ "UMNSRS_reduced_rel.cuis.avg_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.cuis.avg_results" , "./../Similarity/UMNSRS_reduced_rel.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.cuis.avg_results"  && $averageOptionEnabled  == 1 );
            $results{ "UMNSRS_reduced_rel.cuis.comp_results"     }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.cuis.comp_results", "./../Similarity/UMNSRS_reduced_rel.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.cuis.comp_results" && $compoundOptionEnabled == 1 );
            $results{ "UMNSRS_reduced_rel.cuis.sum_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.cuis.sum_results" , "./../Similarity/UMNSRS_reduced_rel.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.cuis.sum_results"  && $summedOptionedEnabled == 1 );
            $results{ "UMNSRS_reduced_sim.cuis.avg_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.cuis.avg_results" , "./../Similarity/UMNSRS_reduced_sim.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.cuis.avg_results"  && $averageOptionEnabled  == 1 );
            $results{ "UMNSRS_reduced_sim.cuis.comp_results"     }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.cuis.comp_results", "./../Similarity/UMNSRS_reduced_sim.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.cuis.comp_results" && $compoundOptionEnabled == 1 );
            $results{ "UMNSRS_reduced_sim.cuis.sum_results"      }   = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.cuis.sum_results" , "./../Similarity/UMNSRS_reduced_sim.cuis.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.cuis.sum_results"  && $summedOptionedEnabled == 1 );
        }
        # Word Term Files
        elsif( $isWordOrCUIVectorData eq "word" )
        {
            $results{ "MayoSRS.terms.avg_results"                 }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.terms.avg_results"            , "./../Similarity/MayoSRS.terms.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.terms.avg_results"             && $averageOptionEnabled  == 1 );
            $results{ "MayoSRS.terms.comp_results"                }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.terms.comp_results"           , "./../Similarity/MayoSRS.terms.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.terms.comp_results"            && $compoundOptionEnabled == 1 );
            $results{ "MayoSRS.terms.sum_results"                 }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MayoSRS.terms.sum_results"            , "./../Similarity/MayoSRS.terms.gold"                , 1 ) if ( -e "$similarityFilePath/MayoSRS.terms.sum_results"             && $summedOptionedEnabled == 1 );
            $results{ "MiniMayoSRS.terms.coders.avg_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.avg_results"        , "./../Similarity/MiniMayoSRS.terms.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.avg_results"         && $averageOptionEnabled  == 1 );
            $results{ "MiniMayoSRS.terms.coders.comp_results"     }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.comp_results"       , "./../Similarity/MiniMayoSRS.terms.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.comp_results"        && $compoundOptionEnabled == 1 );
            $results{ "MiniMayoSRS.terms.coders.sum_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.sum_results"        , "./../Similarity/MiniMayoSRS.terms.coders.gold"     , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.sum_results"         && $summedOptionedEnabled == 1 );
            $results{ "MiniMayoSRS.terms.physicians.avg_results"  }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.avg_results"        , "./../Similarity/MiniMayoSRS.terms.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.avg_results"         && $averageOptionEnabled  == 1 );
            $results{ "MiniMayoSRS.terms.physicians.comp_results" }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.comp_results"       , "./../Similarity/MiniMayoSRS.terms.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.comp_results"        && $compoundOptionEnabled == 1 );
            $results{ "MiniMayoSRS.terms.physicians.sum_results"  }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/MiniMayoSRS.terms.sum_results"        , "./../Similarity/MiniMayoSRS.terms.physicians.gold" , 1 ) if ( -e "$similarityFilePath/MiniMayoSRS.terms.sum_results"         && $summedOptionedEnabled == 1 );
            $results{ "UMNSRS_reduced_rel.terms.avg_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.terms.avg_results" , "./../Similarity/UMNSRS_reduced_rel.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.terms.avg_results"  && $averageOptionEnabled  == 1 );
            $results{ "UMNSRS_reduced_rel.terms.comp_results"     }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.terms.comp_results", "./../Similarity/UMNSRS_reduced_rel.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.terms.comp_results" && $compoundOptionEnabled == 1 );
            $results{ "UMNSRS_reduced_rel.terms.sum_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_rel.terms.sum_results" , "./../Similarity/UMNSRS_reduced_rel.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_rel.terms.sum_results"  && $summedOptionedEnabled == 1 );
            $results{ "UMNSRS_reduced_sim.terms.avg_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.terms.avg_results" , "./../Similarity/UMNSRS_reduced_sim.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.terms.avg_results"  && $averageOptionEnabled  == 1 );
            $results{ "UMNSRS_reduced_sim.terms.comp_results"     }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.terms.comp_results", "./../Similarity/UMNSRS_reduced_sim.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.terms.comp_results" && $compoundOptionEnabled == 1 );
            $results{ "UMNSRS_reduced_sim.terms.sum_results"      }  = $packageInterface->SpCalculateSpearmans( "$similarityFilePath/UMNSRS_reduced_sim.terms.sum_results" , "./../Similarity/UMNSRS_reduced_sim.terms.gold"     , 1 ) if ( -e "$similarityFilePath/UMNSRS_reduced_sim.terms.sum_results"  && $summedOptionedEnabled == 1 );
        }

        my @scores = sort keys( %results );

        if( scalar @scores > 0 )
        {
            print "Finished Spearman's Rank Correlation Score Calculations\n";
            print "Printing Spearman's Rank Correlation Scores\n";
            print "\n--------------------------------------------\n\n";

            for my $score ( @scores )
            {
                print( "$score -> Score: " . $results{ $score } . "\n" ) if defined( $results{ $score } );
            }

            print "\n--------------------------------------------\n\n";

            # Print Spearman's Correlation Rank Score Results To File
            open( FILE, ">:", Cwd::getcwd . "/SpearmanScores.txt" ) or print "Error: Unable To Save Results\n" if scalar @scores > 0;

            for my $score ( @scores )
            {
                print( FILE "$score -> Score: " . $results{ $score } . "\n" ) if defined( $results{ $score } );
            }

            close( FILE );
            undef( @scores );
        }
        else
        {
            print "Warning: Cannot Compute Spearman's Correlation Rank Score(s)\n";
        }
    }

    print "Finished Similarity Computations\n" if ( $success == 0 );
    print "Finished Similarity With Error(s)\n" if ( $success != 0 );
    print "See \"InterfaceLog.txt\" and \"Word2vecLog.txt\" log files for details\n" if ( $success != 0 && $packageInterface->GetWriteLog() == 1 );
}

sub WSD
{
    my $result = 0;

    my $optionsHash = GetCommandOptions( $argIndex );
    my %options = %{ $optionsHash };

    my $instancesFilePath = "";
    my $sensesFilePath = "";
    my $vectorBinFilePath = "";
    my $stopListFilePath = "";
    my $listOfFilesPath = "";
    my $lowMemoryOption = 1;
    my @listOfFilesAry = ();
    my @instanceAry = ();
    my @senseAry = ();

    # Retrieve "instances" and "senses" file paths
    if( keys( %options ) == 0 )
    {
        print "No command line arguments - Type \"EXIT\" at any point to exit\n";
        print "Enter \"Instance File Path\" or \"Directory Of Files\" path: ";
        $instancesFilePath = <STDIN>;
        chomp( $instancesFilePath );

        return if $instancesFilePath eq "EXIT";

        if( $packageInterface->IsFileOrDirectory( $instancesFilePath ) eq "file" )
        {
            print "Enter \"Senses\" file path: ";
            $sensesFilePath = <STDIN>;
            chomp( $sensesFilePath );

            return if $sensesFilePath eq "EXIT";
        }
        elsif( $packageInterface->IsFileOrDirectory( $instancesFilePath ) eq "dir" )
        {
            ;
        }
        else
        {
            print( "Error: Erroneous Input\n" );
            return;
        }

        print "Enter \"vector binary\" file path: ";
        $vectorBinFilePath = <STDIN>;
        chomp( $vectorBinFilePath );

        return if $vectorBinFilePath eq "EXIT";

        print "Enter \"stoplist\" file path: ";
        $stopListFilePath = <STDIN>;
        chomp( $stopListFilePath );

        return if $stopListFilePath eq "EXIT";

        print "Use \"minimize memory usage\"? (Y/N): ";
        $lowMemoryOption = <STDIN>;
        chomp( $lowMemoryOption );
        return if $lowMemoryOption eq "EXIT";
        $lowMemoryOption = lc( $lowMemoryOption );
        $lowMemoryOption = 1 if $lowMemoryOption eq "y";
        $lowMemoryOption = 0 if $lowMemoryOption ne "y" && $lowMemoryOption ne 1;

        $packageInterface->W2VSetMinimizeMemoryUsage( $lowMemoryOption );
        $packageInterface->CLWordSenseDisambiguation( $instancesFilePath, $sensesFilePath, $vectorBinFilePath, $stopListFilePath, $listOfFilesPath );
    }
    else
    {
        for my $option ( keys %options )
        {
            $instancesFilePath  = $options{$option} if ( ( $option eq "-instances" ) || ( $option eq "-dir" ) );
            $sensesFilePath     = $options{$option} if ( $option eq "-senses" );
            $vectorBinFilePath  = $options{$option} if ( $option eq "-vectors" );
            $stopListFilePath   = $options{$option} if ( $option eq "-stoplist" );
            $listOfFilesPath    = $options{$option} if ( $option eq "-list" );
            $lowMemoryOption    = $options{$option} if ( $option eq "-lowmemusage" );
        }

        # Check(s)
        if( !defined( $instancesFilePath ) || !defined( $vectorBinFilePath ) || $instancesFilePath eq "" || $vectorBinFilePath eq "" )
        {
            print "Error: Instance File Path Or Directory Path Not Defined\n" if !defined( $instancesFilePath );
            print "Error: Vector File Path Not Defined\n" if !defined( $vectorBinFilePath );
            print "Error: Instance File Path Or Directory = Empty String\n" if ( defined( $instancesFilePath ) && $instancesFilePath eq "" );
            print "Error: Vector File Path = Empty String\n" if ( defined( $vectorBinFilePath ) && $vectorBinFilePath eq "" );
            return;
        }

        # Set Low Memory Option
        $packageInterface->W2VSetMinimizeMemoryUsage( $lowMemoryOption );

        # Process Specified Directory of 'SVAL' Files
        if( $options{ "-dir" } )
        {
            $result = $packageInterface->CLWordSenseDisambiguation( $instancesFilePath, $sensesFilePath, $vectorBinFilePath, $stopListFilePath, undef );
        }
        else
        {
            # Process Specified Instance/Sense Files
            $result = $packageInterface->CLWordSenseDisambiguation( $instancesFilePath, $sensesFilePath, $vectorBinFilePath, $stopListFilePath, undef ) if( $listOfFilesPath eq "" );

            # Process Instance/Sense Files In List
            $result = $packageInterface->CLWordSenseDisambiguation( undef, undef, $vectorBinFilePath, $stopListFilePath, $listOfFilesPath ) if ( $listOfFilesPath ne "" );
        }
    }

    print "Finished Word Sense Disambiguation\n" if $result == 0;
    print "Word Sense Disambiguation Script Finished With Error(s)\n" if $result != 0;
    print "See \"InterfaceLog.txt\" and \"Word2vecLog.txt\" log files for details\n" if $result != 0 && $packageInterface->GetWriteLog() == 1;
}

sub PrintElapsedTime
{
    my $endTime = time();
    my $elapsedTime =  $endTime - $startTime;
    print( "Elapsed Time: $elapsedTime Second(s)\n" )                                     if ( $elapsedTime < 60 );
    print( "Elapsed Time: " . sprintf( "%.2f", $elapsedTime / 60 )    . " Minute(s)\n" )  if ( $elapsedTime >= 60 ) && ( $elapsedTime < 3600 );
    print( "Elapsed Time: " . sprintf( "%.2f", $elapsedTime / 3600 )  . " Hours(s)\n" )   if ( $elapsedTime >= 3600 ) && ( $elapsedTime < 86400 );
    print( "Elapsed Time: " . sprintf( "%.2f", $elapsedTime / 86400 ) . " Day(s)\n" )     if ( $elapsedTime >= 86400 );
}


######################################################################################
#                                                                                    #
#   Help Routines                                                                    #
#                                                                                    #
######################################################################################

sub ShowHelp
{

    print "\nThis package provides word2vec utilities for Natural Language Processing Use.\n";
    print "Note: Running a command with no arguments will list command options.\n";
    print "    : Commands can be combined to run sequentially.\n";
    print "    : Use \"interface.pm\" in for object oriented sub-routines.\n\n";

    print "Usage: Word2vec-Interface.pl [OPTIONS] \n\n";

    print "OPTIONS:\n\n";

    print "--version                    Prints version information \n\n";
    print "--test                       Executes word2vec file and run-time checks \n\n";
    print "--cos                        Computes cosine similarity of two words given a \n
                             trained vector file \n\n";
    print "--cosmulti                   Computes cosine similarity between multiple words \n
                             given a trained vector file \n\n";
    print "--cosavg                     Computes cosine similarity average between multiple\n
                             words given a trained vector file \n\n";
    print "--cos2v                      Computes cosine similarity between two words, each\n
                             in a differing trained vector data file\n\n";
    print "--multiwordcosuserinput      Computes cosine similarity based on user input on a\n
                             trained vector file \n\n";
    print "--addvectors                 Adds two word vectors and outputs the value \n\n";
    print "--subtractvectors            Subtracts two word vectors and outputs the value \n\n";
    print "--w2vtrain                   Executes word2vec training based on \n
                             user-specified options \n\n";
    print "--w2ptrain                   Executes word2phrase conversion based on\n
                             user-specified options and text corpus \n\n";
    print "--cleantext                  Cleans text within a user specified input file\n
                             and writes line-by-line to an output file\n\n";
    print "--compiletextcorpus          Executes Medline XML-To-W2V text corpus \n
                             generation based on user-specified options \n\n";
    print "--converttotextvectors       Converts user-specified word2vec binary \n
                             formatted file to human-readable text \n\n";
    print "--converttobinaryvectors     Converts user-specified vector text data \n
                             to word2vec binary formatted file \n\n";
    print "--converttosparsevectors     Converts user-specified vector text data \n
                             to sparse word vector formatted file \n\n";
    print "--compoundifyfile            Compoundifies file based on user-specified\n
                             compound word file \n\n";
    print "--findsimilarterms           Prints N-Nearest terms using cosine similarity \n
                             metric \n\n";
    print "--similarity                 Computes Similarity For SVL Formatted Files \n\n";
    print "--spearmans                  Computes Spearman's Rank Correlation Score
                             between two files \n\n";
    print "--sortvectorfile             Sorts vector data file and saves to specified\n
                             directory.\n\n";
    print "--wsd                        Word Sense Disambiguation: Assigns a sense\n
                             to an instance using word2vec trained data \n\n";

    print "Debugging Options:\n";
    print "=-=-=-=-=-=-=-=-=-\n\n";
    print "--debuglog                   Prints debugging statements to the console \n
                             window \n\n";
    print "--writelog                   Writes debugging statements to log module files \n\n";
    print "--clean                      Deletes word2vec executable and C object files \n
                             in word2vec directory \n\n";
    print "Note: Debugging commands can be added before or after your main commands \n\n";
    print "  Ex: --debuglog --cos vectors.bin heart attack \n\n";
    print "      --w2vtrain -trainfile \"textcorpus.txt\" -outputfile \"vectors.bin\" --writelog \n";
}

######################################################################################
#                                                                                    #
#   Version                                                                          #
#                                                                                    #
######################################################################################

sub ShowVersion
{
    print 'Word2vec-Interface.pl, v 0.37 2017/11/14 13:04 cuffyca';
    print "\nCopyright (c) 2016- Bridgett McInnes, Clint Cuffy\n";
}

######################################################################################
#                                                                                    #
#   Help                                                                             #
#                                                                                    #
######################################################################################

sub AskHelp
{
    print STDERR "Type \"Word2vec-Interface.pl --help\" for help.\n";
}


__END__

=head1 NAME

Word2vec-Interface.pl - Word2Vec Package Driver

=head1 SYNOPSIS

This program houses a set of functions and utilities for use with UMLS Similarity.

=head1 USAGE

Usage: Word2vec-Interface.pl [OPTIONS]

=head2 Command-Line Arguments

Displays the quick summary of the program options.

=head3 --test

Description:

 Executes word2vec file and run-time checks.

Parameters:

 None

Output:

 None

Example:

 interface.pm --test

=head3 --cos

Description:

 Computes cosine similarity of two words given a trained vector file.

Parameters:

 vector_binary_path (String)
 wordA              (String)
 wordB              (String)

Output:

 Cosine Similarity Value

Example:

 Word2vec-Interface.pl --cos "samples/samplevectors.bin" heart angina

=head3 --cosmulti

Description:

 Computes cosine similarity between multiple words given a trained vector file.

 Note: There is no limit to the number of words that can be concatenated with the colon character for each parameter.

   ie: --cosmulti "vectors.bin" acute:heart:attack chronic:obstructive:pulmonary:disease

Parameters:

 vector_binary_path (String)
 wordA1:wordA2      (String)
 wordB1:wordB2      (String)

Output:

 Cosine Similarity Value

Example:

 Word2vec-Interface.pl --cosmulti "samples/samplevectors.bin" heart:attack myocardial:infarction

=head3 --cosavg

Description:

 Computes cosine similarity average between multiple words given a trained vector file.

 Note: There is no limit to the number of words that can be concatenated with the colon character for each parameter.

   ie: --cosavg "vectors.bin" heart:attack six:sea:snakes:were:sailing

Parameters:

 vector_binary_path (String)
 wordA1:wordA2      (String)
 wordB1:wordB2      (String)

Output:

 Cosine Similarity Value

Example:

 Word2vec-Interface.pl --cosavg "samples/samplevectors.bin" heart:attack myocardial:infarction

=head3 --cos2v

Description:

 Computes cosine similarity between two words, each in differing trained vector data files.

Parameters:

 vector_data_fileA_path (String)
 wordA                  (String)
 vector_data_fileB_path (String)
 wordB                  (String)

Output:

 Cosine Similarity Value

Example:

 Word2vec-Interface.pl --cos2v "samples/medline_vectors.bin" heart "samples/pubmed_vectors.bin" infarction

=head3 --multiwordcosuserinput

Description:

 Computes cosine similarity based on user input on a trained vector file.

 Note: There is no limit to the number of words that can be concatenated with the colon character for each comparison string.

Parameters:

 vector_binary_path

Output:

 None

Example:

 Word2vec-Interface.pl --multiwordcosuserinput "samples/samplevectors.bin"

=head3 --addvectors

Description:

 Adds two word vectors and prints the value.

Parameters:

 vector_binary_path (String)
 wordA              (String)
 wordB              (String)

Output:

 Summed word vectors string

Example:

 Word2vec-Interface.pl --addvectors "samples/samplevectors.bin" heart attack

=head3 --subtractvectors

Description:

 Subtracts two word vectors and outputs the value.

Parameters:

 vector_binary_path (String)
 wordA              (String)
 wordB              (String)

Output:

 Difference between word vectors string.

Example:

 Word2vec-Interface.pl --subtractvectors "vectors.bin" heart attack

=head3 --w2vtrain

Description:

 Executes word2vec training based on user-specified options.

Parameters:

 -trainfile       file_path         (String)
 -outputfile      file_path         (String)
 -size            x                 (Integer)
 -window          x                 (Integer)
 -mincount        x                 (Integer)
 -sample          x.x               (Float)
 -negative        x                 (Integer)
 -alpha           x.x               (Float)
 -hs              x                 (Integer)
 -binary          x                 (Integer)
 -threads         x                 (Integer)
 -iter            x                 (Integer)
 -cbow            x                 (Integer)
 -classes         x                 (Integer)
 -read-vocab      file_path         (String)
 -save-vocab      file_path         (String)
 -debug           x                 (Integer)
 -overwrite       x                 (Integer)

 Note: Minimal required parameters to run are -trainfile and -outputfile. All other parameters not specified will be set to default settings.

Output:

 None

Example:

 Word2vec-Interface.pl --w2vtrain -trainfile "../../samples/textcorpus.txt" -outputfile "../../samples/tempvectors.bin" -size 200 -window 8 -sample 0.0001 -negative 25 -hs 0 -binary 0 -threads 20 -iter 15 -cbow 1 -overwrite 1

=head3 --w2ptrain

Description:

 Executes word2phrase conversion based on user-specified options and text corpus.

Parameters:

 -trainfile     file_path       (String)
 -outputfile    file_path       (String)
 -mincount      x               (Integer)
 -threshold     x               (Integer)
 -debug         x               (Integer)
 -overwrite     x               (Integer)

 Note: Minimal required parameters to run are -trainfile and -outputfile. All other parameters not specified will be set to default settings.

Example:

 Word2vec-Interface.pl --w2ptrain -trainfile "../../samples/textcorpus.txt" -outputfile "../../samples/phrasecorpus.txt" -min-count 10 -threshold -200 -overwrite 1

=head3 --cleantext

Description:

 Cleans text based on XML-to-W2V text corpus generation text normalization methods.
   - All Text Conveted To Lowercase
   - Duplicate White Spaces Removed
   - "'s" (Apostrophe 's') Characters Removed
   - Hyphen "-" Replaced With Whitespace
   - All Characters Outside Of "a-z" and NewLine Characters Are Removed
   - Lastly, Whitespace Before And After Text Is Removed

Parameters:

 -inputfile       file_path       (String)
 -outputfile      file_path       (String)

 Note: Minimal required parameter to run is "-inputfile". All other parameters not specified will be set to default settings.

Example:

 Word2vec-Interface.pl --cleantext -inputfile "../../samples/text.txt"
 Word2vec-Interface.pl --cleantext -inputfile "../../samples/text.txt" -outputfile "../../samples/cleaned_text.txt"

=head3 --compiletextcorpus

Description:

 Executes Medline XML-To-W2V text corpus generation based on user-specified options.

Parameters:

 -workdir       file_path       (String)
 -savedir       file_path       (String)
 -startdate     "XX/XX/XXXX"    (String)
 -enddate       "XX/XX/XXXX"    (String)
 -title         x               (Integer)
 -abstract      x               (Integer)
 -qparse        x               (Integer)
 -compwordfile  file_path       (String)
 -threads       x               (Integer)
 -overwrite     x               (Integer)

 Note: Minimal required parameter to run is "-workdir". All other parameters not specified will be set to default settings.

Example:

 Word2vec-Interface.pl --compiletextcorpus -workdir "../../samples"
 Word2vec-Interface.pl --compiletextcorpus -workdir "../../samples" -savedir "../../samples/textcorpus.txt" -startdate 01/01/1900 -enddate 99/99/9999 -title 1 -abstract 1 -qparse 1 -compwordfile "../../samples/compoundword.txt" -threads 2 -overwrite 1

=head3 --converttotextvectors

Description:

 Converts user-specified word2vec binary formatted file to human-readable text.

 Note: This will freely convert all formats to plain text format.

Parameters:

 input_file_path  (String)
 output_file_path (String)

Output:

 None

Example:

 Word2vec-Interface.pl ---converttotextvectors "binaryvectors.bin" "textvectors.bin"

=head3 --converttobinaryvectors

Description:

 Converts user-specified vector text data to word2vec binary formatted file.

 Note: This will freely convert all formats to word2vec binary format.

Parameters:

 input_file_path  (String)
 output_file_path (String)

Output:

 None

Example:

 Word2vec-Interface.pl ---converttobinaryvectors "textvectors.bin" "binaryvectors.bin"

=head3 --converttosparsevectors

Description:

 Converts user-specified vector text data to sparse vector data formatted file.

 Note: This will freely convert all formats to sparse vector data format.

Parameters:

 input_file_path  (String)
 output_file_path (String)

Output:

 None

Example:

 Word2vec-Interface.pl ---converttosparsevectors "textvectors.bin" "sparsevectors.bin"

=head3 --compoundifyfile

Description:

 Compoundifies file based on user-specified compound word file.

Parameters:

 input_file             (String)
 output_file            (String)
 compound_word_file     (String)

Output:

 Compoundified file using 'compound_word_file' data at 'output_file' path.

Example:

 Word2vec-Interface.pl --compoundifyfile "samples/textcorpus.txt" "samples/compoundedtext.txt" "samples/compoundword.txt"

=head3 --sortvectorfile

Description:

 Sorts specified vector file in alphanumeric order.

Parameters:

 input_file                                           (String)
 -overwrite    1 = Overwrite / 0 = Save to new file   (Integer)

Output:

 Generates a sorted vector file consisting either replacing the old file or saving to the file "sortedvectors.bin".

Example:

 Word2vec-Interface.pl --sortvectorfile "vectors.bin"

 Or

 Word2vec-Interface.pl --sortvectorfile "vectors.bin" -overwrite 1

 Or

 Word2vec-Interface.pl --sortvectorfile "vectors.bin" -overwrite 0

=head3 --findsimilarterms

Description:

 Prints the nearest n terms using cosine similarity as the metric of determining similar terms.

Parameters:

 -vectors   vector_binary_file          (String)
 -term      term                        (String)
 -neighbors number_of_similar_neighbors (Integer)

 ( Optional Parameter(s) )
 -threads   number of threads           (Integer)

Output:

 "number_of_similar_neighbors" value nearest similar terms using cosine similarity.

Example:

 Word2vec-Interface.pl --findsimilarterms -vectors vectors.bin -term heart -neighbors 10

=head3 --spearmans

Description:

 Computes Spearman's Rank Correlation Score between two files of a specific format.

 File Format:
 "score(float)<>term1<>term2"
 "score(float)<>term3<>term4"

 Note: Optional Parameters: -n -> Prints N value with Spearman's Rank Correlation Score

Parameters:

 input_file_a     (String)
 input_file_b     (String)
 (Optional Parameters)

Output:

 Spearman's Rank Correlation Score.

Example:

 Word2vec-Interface.pl --spearmans "samples/MiniMayoSRS.terms.comp_results" "Similarity/MiniMayoSRS.terms.coders"

 Or

 Word2vec-Interface.pl --spearmans "samples/MiniMayoSRS.terms.comp_results" "Similarity/MiniMayoSRS.terms.coders" -n

=head3 --similarity

Description:

 Computes average, compound and summed cosine similarity values for a list of word comparisons in a specified file or directory.
 When using a directory of files, files to be parsed must end with ".sim" extension.

 Note: Optional Parameters: -all -> Computes Average, Compound and Summed files
                            -a   -> Only computes Average file
                            -c   -> Only computes Compound file
                            -s   -> Only computes Summed file

       Specifying no optional parameters imples "-all". Parameters can be combined to produce multiple results. See examples below.

Parameters:

 -sim     input_file             (String)
 -vectors vector_binary_file     (String)
 (Optional Parameters)

Output:

 Generates a text file with a list of cosine similarity values followed by the word pairs.

Example:

 Word2vec-Interface.pl --similarity -sim "samples/MiniMayoSRS.terms" -vectors "vectors.bin"

 Or

 Word2vec-Interface.pl --similarity -sim "samples/MiniMayoSRS.terms" -vectors "vectors.bin" -all

 Or

 Word2vec-Interface.pl --similarity -sim "samples/MiniMayoSRS.terms" -vectors "vectors.bin" -a -s

 Or

 Word2vec-Interface.pl --similarity -sim "samples/MiniMayoSRS.terms" -vectors "vectors.bin" -c

=head3 --wsd

Description:

 Word Sense Disambiguation: Reads an instance and sense file in SVL format, removes stop words using the user specified stoplist and assigns a sense
 identification number to an instance identification number using cosine similarity to compare all sense ids to an instance. The highest cosine
 similarity value between a specific sense and instance is assigned to that particular instance.

 Warning: WSD instance and sense files must be in SVL format.

Parameters:

 No parameters        <- This will prompt the user to input required files for WSD processing. (Must be in SVL format)

 Or

 -instances  file_path              (String)
 -senses     file_path              (String)
 -vectors    vector_binary_file     (String)
 -stoplist   file_path              (String) <- (Not required)

 Or

 -dir        directory_of_files     (String)
 -vectors    vector_binary_file     (String)
 -stoplist   file_path              (String) <- (Not required)

 Or

 -list       file_path              (String)

 Note: "-list" parameter requires the input file to meet format specifications for use. See example "samples/wsdlist.txt" for details.
 Note: "-dir" parameter requires the user to specify the "-vectors" file path. "-stoplist" parameter is not requried.

Output:

 None

Examples:

 Word2vec-Interface.pl --wsd -instances "ACE.instances.sval" -senses "ACE.senses.sval" -vectors "vectors.bin"
 Word2vec-Interface.pl --wsd -instances "ACE.instances.sval" -senses "ACE.senses.sval" -vectors "vectors.bin" -stoplist "stoplist"

 Word2vec-Interface.pl --wsd -dir "../../wsd" -vectors vectors.bin
 Word2vec-Interface.pl --wsd -dir "../../wsd" -vectors vectors.bin -stoplist "../../stoplist"

 Word2vec-Interface.pl --wsd -list "../../wsd/abbrevlist.txt"
 Word2vec-Interface.pl --wsd -list "../../wsd/abbrevlist.txt" -vectors vectors.bin
 Word2vec-Interface.pl --wsd -list "../../wsd/abbrevlist.txt" -vectors vectors.bin -stoplist "../../wsd/stoplist"

=head3 --clean

Description:

 Cleans up word2vec directory. Removes C object and executable files.

 This is useful when moving the development directory between computers with different CPU architectures (x86/x64) and attempting to run word2vec executable files.
 Errors could occur when trying to run a 64-bit executable on a 32-bit machine. Cleaning up the word2vec directory and re-building the executable files
 resolves this issue.

Parameters:

 None

Output:

 None

Example:

 Word2vec-Interface.pl --clean

=head3 --version

Description:

 Displays the version information.

Parameters:

 None

Output:

 Displays version information to the console.

 Note: '--debuglog' and '--writelog' can also be combined to print debug statements to the console and write to their log files.

Example:

 Word2vec-Interface.pl --version

=head3 --help

Description:

 Displays the quick summary of program options.

Parameters:

 None

Output:

 Displays help information to the console.

Example:

 Word2vec-Interface.pl --help

=head2 Debugging Arguments

List of debugging options.

=head3 --debuglog

Description:

 Prints debugging statements to the console window.

 Note: This parameter can be specified anywhere within the parameter string.

Parameters:

 None

Output:

 Prints real-time debug log to the console window.

Examples:

 Word2vec-Interface.pl --test --debuglog

 Word2vec-Interface.pl --debuglog --test

 Word2vec-Interface.pl --debuglog --wsd -list "samples/wsd/abbrevlist.txt"

 Word2vec-Interface.pl --debuglog --w2vtrain "samples/textcorpus.txt" "samples/tempvectors.bin"

=head3 --writelog

Description:

 Writes debugging statements to log module files.

 Note: This parameter can be specified anywhere within the parameter string.

Parameters:

 None

Output:

 Writes debug log statements to specified log files. Each module will write to its respective log file.
 ie. 'interface.pm' module will write to log file 'InterfaceLog.txt'.

Examples:

 Word2vec-Interface.pl --test --writelog

 Word2vec-Interface.pl --writelog --test

 Word2vec-Interface.pl --writelog --wsd -list "samples/wsd/abbrevlist.txt"

 Word2vec-Interface.pl --writelog --w2vtrain -trainfile "samples/textcorpus.txt" -outputfile "samples/tempvectors.bin"

=head2 Command-Line Notes

Note that when using command-line parameters, multiple commands are supported.

ie. Word2vec-Interface.pl --compiletextcorpus -workdir "samples" -savedir "samples/textcorpus.txt" --w2vtrain -trainfile "samples/textcorpus.txt" -outputfile "samples/tempvectors.bin" --cos "samples/tempvectors.bin" of the

This string of commands instructs the script to compile a text corpus of the Medline XML files in the "samples" directory.
Initiate word2vec training based on the newly compiled text corpus and create a word2vec trained word vector file in the
specified directory. Then subsequently use the newly trained vector data to compute the cosine similarity between the words
"of" and "the".

This scripts supports as many continous commands as the user wishes to impose. All commands are checked for errors and the script will exit gracefully if such an event takes place.
To obtain a better understanding of any errors, '--debuglog' or '--writelog' commands must be enabled.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.24.0 or better) - http://www.perl.org

=back

=head1 CONTACT US

    If you have trouble installing and executing Word2vec-Interface.pl,
    please contact us at

    cuffyca at vcu dot edu.

=head1 Author

 Clint Cuffy, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2016

 Bridget T McInnes, Virginia Commonwealth University
 btmcinnes at vcu dot edu

 Clint Cuffy, Virginia Commonwealth University
 cuffyca at vcu dot edu

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
