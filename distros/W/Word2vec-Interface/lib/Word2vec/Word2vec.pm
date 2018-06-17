#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    06/16/2016                                                             #
#    Revised: 11/06/2017                                                             #
#    UMLS Similarity Word2Vec Executable Interface Module                            #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Perl "word2vec" executable interface for UMLS Similarity           #
#    Features:                                                                       #
#    =========                                                                       #
#                 Supports Word2Vec Training Using Standard Options                  #
#                 Conversion of Word2Vec Binary Format To Plain Text And Vice Versa  #
#                 Cosine Similarity Between Two Words                                #
#                 Summed Cosine Similarity                                           #
#                 Average Cosine Similarity                                          #
#                 Multi-Word Cosine Similarity                                       #
#                 Manipulation of Word Vectors (Addition/Subtraction/Average)        #
#                                                                                    #
######################################################################################


package Word2vec::Word2vec;

use strict;
use warnings;

# Standard Package(s)
use Cwd;
use Encode qw( decode encode );


use vars qw($VERSION);

$VERSION = '0.03';


######################################################################################
#    Constructor
######################################################################################

BEGIN
{
    # CONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    Deconstructor
######################################################################################

END
{
    # DECONSTRUCTOR : DO SOMETHING HERE
}


######################################################################################
#    new Class Operator
######################################################################################

sub new
{
    my $class = shift;
    my $self = {
        # Private Member Variables
        _debugLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _writeLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _trainFileName          => shift,               # String
        _outputFileName         => shift,               # String
        _wordVecSize            => shift,               # Int
        _windowSize             => shift,               # Int
        _sample                 => shift,               # Float
        _hSoftMax               => shift,               # Int
        _negative               => shift,               # Int
        _numOfThreads           => shift,               # Int
        _numOfIterations        => shift,               # Int
        _minCount               => shift,               # Int
        _alpha                  => shift,               # Float
        _classes                => shift,               # Int
        _debug                  => shift,               # Int
        _binaryOutput           => shift,               # Boolean (Binary): 0 = False, 1 = True
        _saveVocab              => shift,               # String (File Name To Save To)
        _readVocab              => shift,               # String (File Name To Read From)
        _useCBOW                => shift,               # Boolean (Binary): 0 = Use Skip-Gram Model, 1 = Use CBOW (Default)
        _workingDir             => shift,               # String
        _word2VecExeDir         => shift,               # String
        _hashRefOfWordVectors   => shift,               # Hash Reference of Word2Vec Vectors
        _overwriteOldFile       => shift,               # Boolean (Binary): 0 = False, 1 = True
        _sparseVectorMode       => shift,               # Boolean (Binary): 0 = False, 1 = True
        _vectorLength           => shift,               # Int
        _numberOfWords          => shift,               # Int
        _minimizeMemoryUsage    => shift,               # Boolean (Binary): 0 = False, 1 = True
    };

    # Set debug log variable to false if not defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _trainFileName } = "" if !defined ( $self->{ _trainFileName } );
    $self->{ _outputFileName } = "" if !defined ( $self->{ _outputFileName } );
    $self->{ _wordVecSize } = 100 if !defined ( $self->{ _wordVecSize } );
    $self->{ _windowSize } = 5 if !defined ( $self->{ _windowSize } );
    $self->{ _sample } = 0.001 if !defined ( $self->{ _sample } );
    $self->{ _hSoftMax } = 0 if !defined ( $self->{ _hSoftMax } );
    $self->{ _negative } = 5 if !defined ( $self->{ _negative } );
    $self->{ _numOfThreads } = 12 if !defined ( $self->{ _numOfThreads } );
    $self->{ _numOfIterations } = 5 if !defined ( $self->{ _numOfIterations } );
    $self->{ _minCount } = 5 if !defined ( $self->{ _minCount } );
    $self->{ _classes } = 0 if !defined ( $self->{ _classes } );
    $self->{ _debug } = 2 if !defined ( $self->{ _debug } );
    $self->{ _binaryOutput } = 1 if !defined ( $self->{ _binaryOutput } );
    $self->{ _saveVocab } = "" if !defined ( $self->{ _saveVocab } );
    $self->{ _readVocab } = "" if !defined ( $self->{ _readVocab } );
    $self->{ _useCBOW } = 1 if !defined ( $self->{ _useCBOW } );

    $self->{ _alpha } = 0.05 if ( !defined ( $self->{ _alpha } ) && $self->{ _useCBOW } == 1 );
    $self->{ _alpha } = 0.025 if ( !defined ( $self->{ _alpha } ) && $self->{ _useCBOW } == 0 );

    $self->{ _workingDir } = Cwd::getcwd() if !defined ( $self->{ _workingDir } );

    my %hash = ();
    $self->{ _hashRefOfWordVectors } = \%hash if !defined ( $self->{ _hashRefOfWordVectors } );
    $self->{ _overwriteOldFile } = 0 if !defined $self->{ _overwriteOldFile };
    $self->{ _sparseVectorMode } = 0 if !defined $self->{ _sparseVectorMode };
    $self->{ _vectorLength } = 0 if !defined $self->{ _vectorLength };
    $self->{ _numberOfWords } = 0 if !defined $self->{ _numberOfWords };
    $self->{ _minimizeMemoryUsage } = 1 if !defined $self->{ _minimizeMemoryUsage };


    # Try To Locate Word2Vec Executable Files Path
    for my $dir ( @INC )
    {
        $self->{ _word2VecExeDir } = "$dir/External/Word2vec" if ( -e "$dir/External/Word2vec" );                       # Test Directory
        $self->{ _word2VecExeDir } = "$dir/../External/Word2vec" if ( -e "$dir/../External/Word2vec" );                 # Dev Directory
        $self->{ _word2VecExeDir } = "$dir/../../External/Word2vec" if ( -e "$dir/../../External/Word2vec" );           # Dev Directory
        $self->{ _word2VecExeDir } = "$dir/Word2vec/External/Word2vec" if ( -e "$dir/Word2vec/External/Word2vec" );     # Release Directory
    }

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', 'Word2vecLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );
    $self->WriteLog( "New - Word2Vec Executable Directory Found" ) if defined( $self->{ _word2VecExeDir } );
    $self->WriteLog( "New - Setting Word2Vec Executable Directory To: \"" . $self->{ _word2VecExeDir } . "\"" ) if defined( $self->{ _word2VecExeDir } );

    return $self;
}


######################################################################################
#    DESTROY
######################################################################################

sub DESTROY
{
    my ( $self ) = @_;

    # Close FileHandle
    close( $self->{ _fileHandle } ) if( $self->{ _fileHandle } );
}


######################################################################################
#    Module Functions
######################################################################################

sub ExecuteTraining
{
    my ( $self, $trainFilePath, $outputFilePath, $vectorSize, $windowSize, $minCount, $sample, $negative, $alpha, $hs, $binary, $numOfThreads, $iterations, $useCBOW, $classes, $readVocab, $saveVocab, $debug, $overwrite ) = @_;

    # Pre-Training Check(s)
    my $executableFileDir = $self->GetWord2VecExeDir() . "/word2vec";
    $executableFileDir .= ".exe" if $self->GetOSType() eq  "MSWin32";

    # Override Train File Path Member Variable With Specified Train File Parameter
    $self->WriteLog( "ExecuteTraining - \"TrainFilePath\" Parameter Specified / Overriding Member Variable" ) if defined( $trainFilePath );
    $trainFilePath = $self->GetTrainFilePath() if !defined( $trainFilePath );

    # Override Output File Path Member Variable With Specified Train File Parameter
    $self->WriteLog( "ExecuteTraining - \"OutputFilePath\" Parameter Specified / Overriding Member Variable" ) if defined( $outputFilePath );
    $outputFilePath = $self->GetOutputFilePath() if !defined( $outputFilePath );

    # Override Overwrite Member Variable With Specified Train File Parameter
    $self->WriteLog( "ExecuteTraining - \"Overwrite\" Parameter Specified / Overriding Member Variable" ) if defined( $overwrite );
    $overwrite = $self->GetOverwriteOldFile() if !defined( $overwrite );

    # Check For 'word2vec' Executable and trainFile
    $self->WriteLog( "ExecuteTraining - Error: \"word2vec\" Executable File Cannot Be Found" ) if !( -e "$executableFileDir" );
    return -1 if !( -e "$executableFileDir" );
    $self->WriteLog( "ExecuteTraining - Error: Training File Not Found" ) if !( -e "$trainFilePath" );
    $self->WriteLog( "ExecuteTraining - Error: Training File Size = 0 bytes - No Data In Training File" ) if ( -z "$trainFilePath" );
    return -1 if !( -e "$trainFilePath" ) || ( -z "$trainFilePath" );

    # Checks To See If Training Is Set To Use CBOW or Skip-Gram Model
    $self->WriteLog( "ExecuteTraining - Attn: Continuous Bag Of Words Model = 0, Using Skip-Gram Model" ) if $self->GetUseCBOW() == 0;

    # Checks For Existing Output File And Returns -1 If Overwrite Option Is Not Enabled
    $self->WriteLog( "ExecuteTraining - Warning: \"$outputFilePath\" Already Exists - Canceling Training" ) if ( -e "$outputFilePath" && $overwrite == 0 );
    $self->WriteLog( "ExecuteTraining - Try Enabling \"Overwrite\" Option or Delete \"$outputFilePath\" In Working Directory" ) if ( -e "$outputFilePath" && $overwrite == 0 );
    return -1 if ( -e "$outputFilePath" && $overwrite == 0 );

    # Fetch Other Training Parameters
    $self->WriteLog( "ExecuteTraining - \"VectorSize\" Parameter Defined / Overriding Member Variable" ) if defined( $vectorSize );
    $vectorSize = $self->GetWordVecSize() if !defined( $vectorSize );

    $self->WriteLog( "ExecuteTraining - \"WindowSize\" Parameter Defined / Overriding Member Variable" ) if defined( $windowSize );
    $windowSize = $self->GetWindowSize() if !defined( $windowSize );

    $self->WriteLog( "ExecuteTraining - \"Min-Count\" Parameter Defined / Overriding Member Variable" ) if defined( $minCount );
    $minCount = $self->GetMinCount() if !defined( $minCount );

    $self->WriteLog( "ExecuteTraining - \"Sample\" Parameter Defined / Overriding Member Variable" ) if defined( $sample );
    $sample = $self->GetSample() if !defined( $sample );

    $self->WriteLog( "ExecuteTraining - \"Negative\" Parameter Defined / Overriding Member Variable" ) if defined( $negative );
    $negative = $self->GetNegative() if !defined( $negative );

    $self->WriteLog( "ExecuteTraining - \"Alpha\" Parameter Defined / Overriding Member Variable" ) if defined( $alpha );
    $alpha = $self->GetAlpha() if !defined( $alpha );

    $self->WriteLog( "ExecuteTraining - \"HSoftMax\" Parameter Defined / Overriding Member Variable" ) if defined( $hs );
    $hs = $self->GetHSoftMax() if !defined( $hs );

    $self->WriteLog( "ExecuteTraining - \"Binary\" Parameter Defined / Overriding Member Variable" ) if defined( $binary );
    $binary = $self->GetBinaryOutput() if !defined( $binary );

    $self->WriteLog( "ExecuteTraining - \"NumOfThreads\" Parameter Defined / Overriding Member Variable" ) if defined( $numOfThreads );
    $numOfThreads = $self->GetNumOfThreads() if !defined( $numOfThreads );

    $self->WriteLog( "ExecuteTraining - \"Iterations\" Parameter Defined / Overriding Member Variable" ) if defined( $iterations );
    $iterations = $self->GetNumOfIterations() if !defined( $iterations );

    $self->WriteLog( "ExecuteTraining - \"CBOW\" Parameter Defined / Overriding Member Variable" ) if defined( $useCBOW );
    $useCBOW = $self->GetUseCBOW() if !defined( $useCBOW );

    $self->WriteLog( "ExecuteTraining - \"Classes\" Parameter Defined / Overriding Member Variable" ) if defined( $classes );
    $classes = $self->GetClasses() if !defined( $classes );

    $self->WriteLog( "ExecuteTraining - \"ReadVocab\" Parameter Defined / Overriding Member Variable" ) if defined( $readVocab );
    $readVocab = $self->GetReadVocabFilePath() if !defined( $readVocab );

    $self->WriteLog( "ExecuteTraining - \"SaveVocab\" Parameter Defined / Overriding Member Variable" ) if defined( $saveVocab );
    $saveVocab = $self->GetSaveVocabFilePath() if !defined( $saveVocab );

    $self->WriteLog( "ExecuteTraining - \"Debug\" Parameter Defined / Overriding Member Variable" ) if defined( $debug );
    $debug = $self->GetDebugTraining() if !defined( $debug );

    # Setting Up Command String
    my $command = "\"$executableFileDir\" ";
    $command .= ( "-train \"" . $trainFilePath . "\" " );
    $command .= ( "-output \"" . $outputFilePath . "\" " );
    $command .= ( "-size " . $vectorSize . " " );
    $command .= ( "-window " . $windowSize . " " );
    $command .= ( "-sample " . $sample . " " );
    $command .= ( "-hs " . $hs . " " );
    $command .= ( "-negative " . $negative . " " );
    $command .= ( "-threads " . $numOfThreads . " " );
    $command .= ( "-iter " . $iterations . " " );
    $command .= ( "-min-count " . $minCount . " " );
    $command .= ( "-alpha " . $alpha . " " );
    $command .= ( "-classes " . $classes . " " );
    $command .= ( "-binary " . $binary . " " );
    $command .= ( "-cbow " . $useCBOW . " " );
    $command .= ( "-read-vocab " . $readVocab . " " ) if ( defined( $readVocab ) && $readVocab ne "" );
    $command .= ( "-save-vocab " . $saveVocab . " " ) if ( defined( $saveVocab ) && $saveVocab ne "" );
    $command .= ( "-debug " . $debug . " " );

    $self->WriteLog( "Executing Command: $command" );

    # Execute External System Command To Train "word2vec"
    # Execute command without capturing program output
    my $result = system( "$command" );

    print "\n";

    # Post-Training Check(s)
    $self->WriteLog( "ExecuteTraining - Error: Unable To Spawn Executable File - Try Running '--clean' Command And Re-compile Executables" ) if ( $result == 65280 );

    $self->WriteLog( "ExecuteTraining - Error: Word2Vec Output File Does Not Exist" ) if !( -e "$outputFilePath" );
    $self->WriteLog( "ExecuteTraining - Error: Word2Vec Output File Size = Zero" ) if ( -z "$outputFilePath" );
    $result = -1 if ( !( -e "$outputFilePath" ) || ( -z "$outputFilePath" ) );

    $self->WriteLog( "ExecuteTraining - Training Successful" ) if $result == 0 && ( -e "$outputFilePath" );
    $self->WriteLog( "ExecuteTraining - Training Unsuccessful" ) if $result != 0;

    return $result;
}

sub ExecuteStringTraining
{
    my ( $self, $trainingStr, $outputFilePath, $vectorSize, $windowSize, $minCount, $sample, $negative, $alpha, $hs, $binary,
         $numOfThreads, $iterations, $useCBOW, $classes, $readVocab, $saveVocab, $debug, $overwrite ) = @_;

    # Check(s)
    $self->WriteLog( "ExecuteStringTraining - Error: Training String Is Not Defined" ) if !defined( $trainingStr );
    return -1 if !defined( $trainingStr );

    $self->WriteLog( "ExecuteStringTraining - Error: Training String Is Empty" ) if ( $trainingStr eq "" );
    return -1 if ( $trainingStr eq "" );

    # Save Training String To Temporary File
    my $result = 0;

    $self->WriteLog( "ExecuteStringTraining - Saving Training String To Temporary File At Working Directory: \"" . $self->GetWorkingDir() . "\"" );

    my $tempFilePath = $self->GetWorkingDir() . "/w2vtemp.txt";
    open( my $fileHandle, ">:encoding(utf8)", "$tempFilePath" ) or $result = -1;

    $self->WriteLog( "ExecuteStringTraining - Error Creating File Handle : $!" ) if ( $result == -1 );
    return -1 if ( $result == -1 );

    # Print Training String Data To File
    print( $fileHandle "$trainingStr" ) if defined( $fileHandle );

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "ExecuteStringTraining - Temporary Training String File Saved" );

    $result = $self->ExecuteTraining( $tempFilePath, $outputFilePath, $vectorSize, $windowSize,
                                      $minCount, $sample, $negative, $alpha, $hs, $binary, $numOfThreads,
                                      $iterations, $useCBOW, $classes, $readVocab, $saveVocab, $debug, $overwrite );

    $self->WriteLog( "ExecuteStringTraining - Removing Temporary Training String Data File" );
    unlink( $tempFilePath );

    $self->WriteLog( "ExecuteStringTraining - Finished" ) if ( $result == 0 );
    $self->WriteLog( "ExecuteStringTraining - Finished With Errors" ) if ( $result == -1 && $self->GetWriteLog() == 0 );
    $self->WriteLog( "ExecuteStringTraining - Finished With Errors / See Log File For Details" ) if ( $result == -1 && $self->GetWriteLog() == 1 ) ;

    return $result;
}

sub ComputeCosineSimilarity
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "ComputeCosineSimilarity - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "ComputeCosineSimilarity - Error: Function Requires Two Arguments (Words)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    $self->WriteLog( "ComputeCosineSimilarity - Computing Cosine Similarity Of Words: \"$wordA\" and \"$wordB\"" );

    my @wordAVtr = ();
    my @wordBVtr = ();


    # Search Dictionary For Specified Words
    my $wordAData = $self->GetWordVector( $wordA );
    my $wordBData = $self->GetWordVector( $wordB );
    @wordAVtr = split( ' ', $wordAData ) if defined( $wordAData );
    @wordBVtr = split( ' ', $wordBData ) if defined( $wordBData );

    # Post Search Check(s)
    $self->WriteLog( "ComputeCosineSimilarity - Error: \"$wordA\" Not In Dictionary" ) if @wordAVtr == 0;
    $self->WriteLog( "ComputeCosineSimilarity - Error: \"$wordB\" Not In Dictionary" ) if @wordBVtr == 0;
    return undef if @wordAVtr == 0 || @wordBVtr == 0;

    # Remove Word From Vector To Compute Cosine Similarity Based On Vector Values
    shift( @wordAVtr );
    shift( @wordBVtr );
    my $wordAVtrSize = @wordAVtr;
    my $wordBVtrSize = @wordBVtr;

    # Check(s)
    $wordAVtrSize = 0 if !defined( $wordAVtrSize );
    $wordBVtrSize = 0 if !defined( $wordBVtrSize );

    $self->WriteLog( "ComputeCosineSimilarity - Words Present In Dictionary" );

    # Cosine Similarity => cos(angle) =       ->      ->
    #                                         A   *   B
    #                                    -------------------
    #                                        ->        ->
    #                                     || A || * || B ||
    #
    # Explanation: Dot Product Of VectorA By VectorB, Divided By The Square Root Of Dot Product Of Vector A Multiplied By Square Root Of Dot Product Of Vector B

    my $dpA = 0;
    my $dpB = 0;
    my $ldpA = 0;
    my $ldpB = 0;
    my $dpAB = 0;

    # Compute Dot Product Of VectorA
    for my $value ( @wordAVtr )
    {
        $dpA += ( $value * $value );
    }

    # Compute Dot Product Of VectorB
    for my $value ( @wordBVtr )
    {
        $dpB += ( $value * $value );
    }

    # Compute $ldpA & $ldpB
    $ldpA = sqrt( $dpA );
    $ldpB = sqrt( $dpB );

    # Compute Cosine Similarity Between Vector A & Vector B
    for( my $i = 0; $i < $wordAVtrSize; $i++ )
    {
        # Compute Value If Not Dividing By Zero
        $dpAB += ( ( $wordAVtr[$i] / $ldpA ) * ( $wordBVtr[$i] / $ldpB ) ) if ( $ldpA != 0 && $ldpB != 0 );
    }

    # Return Value Cosine Similarity Value Rounded To Six Decimal Places
    return sprintf( "%.6f", $dpAB );
}

sub ComputeAvgOfWordsCosineSimilarity
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Error: Function Requires Two Arguments (Words)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Error: One Or More Arguments Consisting Of Empty String" ) if ( $wordA eq "" || $wordB eq "" );
    return undef if ( $wordA eq "" || $wordB eq "" );


    my @wordAAry = split( ' ', $wordA );
    my @wordBAry = split( ' ', $wordB );

    # Check(s)
    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Error: One Or More Arguments Contains No Data" ) if ( @wordAAry == 0 || @wordBAry == 0 );
    return undef if ( @wordAAry == 0 || @wordBAry == 0 );

    $wordA = $self->ComputeAverageOfWords( \@wordAAry );
    $wordB = $self->ComputeAverageOfWords( \@wordBAry );

    # Check(s)
    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Unable To Compute Average Of Word(s): \"@wordAAry\"" ) if !defined( $wordA );
    $self->WriteLog( "ComputeAvgOfWordsCosineSimilarity - Unable To Compute Average Of Word(s): \"@wordBAry\"" ) if !defined( $wordB );
    return undef if !defined( $wordA ) || !defined( $wordB );

    my @avgAVtr = split( ' ', $wordA );
    my @avgBVtr = split( ' ', $wordB );
    my $avgAVtrSize = @avgAVtr;
    my $avgBVtrSize = @avgBVtr;

    # Check(s)
    $avgAVtrSize = 0 if !defined( $avgAVtrSize );
    $avgBVtrSize = 0 if !defined( $avgBVtrSize );

    undef( $wordA );
    undef( $wordB );

    # Compute Cosine Similarity Between Word Averages

    # Cosine Similarity => cos(angle) =       ->      ->
    #                                         A   *   B
    #                                    -------------------
    #                                        ->        ->
    #                                     || A || * || B ||
    #
    # Explanation: Dot Product Of VectorA By VectorB, Divided By The Square Root Of Dot Product Of Vector A Multiplied By Square Root Of Dot Product Of Vector B

    my $dpA = 0;
    my $dpB = 0;
    my $ldpA = 0;
    my $ldpB = 0;
    my $dpAB = 0;

    # Compute Dot Product Of VectorA
    for my $value ( @avgAVtr )
    {
        $dpA += ( $value * $value );
    }

    # Compute Dot Product Of VectorB
    for my $value ( @avgBVtr )
    {
        $dpB += ( $value * $value );
    }

    # Compute $ldpA & $ldpB
    $ldpA = sqrt( $dpA );
    $ldpB = sqrt( $dpB );

    # Compute Cosine Similarity Between Vector A & Vector B
    for( my $i = 0; $i < $avgAVtrSize; $i++ )
    {
        # Compute Value If Not Dividing By Zero
        $dpAB += ( ( $avgAVtr[$i] / $ldpA ) * ( $avgBVtr[$i] / $ldpB ) ) if ( $ldpA != 0 && $ldpB != 0 );
    }

    # Return Value Cosine Similarity Value Rounded To Six Decimal Places
    return sprintf( "%.6f", $dpAB );
}

sub ComputeMultiWordCosineSimilarity
{
    my ( $self, $wordA, $wordB, $allWordsMustExist ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: Function Requires Two Arguments (Words)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Warning: \"All Words Must Exist\" Parameter Not Specified / Default = False" ) if !defined( $allWordsMustExist );
    $allWordsMustExist = 0 if !defined( $allWordsMustExist );

    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Computing Cosine Similarity Of Words: \"$wordA\" and \"$wordB\"" );

    my @wordAVtr = ();
    my @wordBVtr = ();


    # Split Words To Check For Existence In Dictionary
    my @wordAAry = split( ' ', $wordA );
    my @wordBAry = split( ' ', $wordB );
    my $wordsFoundA = "";
    my $wordsFoundB = "";

    # Check(s)
    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: One Or More Arguments Contains No Data" ) if ( @wordAAry == 0 || @wordBAry == 0 );
    return undef if ( @wordAAry == 0 || @wordBAry == 0 );

    # Search Dictionary For Specified Words
    for my $word ( @wordAAry )
    {
        my $wordData = $self->GetWordVector( $word );

        if( defined( $wordData ) )
        {
            my @wordVtr = split( ' ', $wordData );
            push( @wordAVtr, [ @wordVtr ] );
            $wordsFoundA .=  ( " " . $word );
        }
    }

    for my $word ( @wordBAry )
    {
        my $wordData = $self->GetWordVector( $word );

        if( defined( $wordData ) )
        {
            my @wordVtr = split( ' ', $wordData );
            push( @wordBVtr, [ @wordVtr ] );
            $wordsFoundB .=  ( " " . $word );
        }
    }


    # Post Search Check(s)
    my $error = 0;
    for( my $i = 0; $i < @wordAAry; $i++ )
    {
        $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: \"" . $wordAAry[$i] . "\" Not In Dictionary" ) if index( $wordsFoundA, $wordAAry[$i] ) == -1;
        $error = 1 if index( $wordsFoundA, $wordAAry[$i] ) == -1 && $allWordsMustExist == 1;
    }

    for( my $i = 0; $i < @wordBAry; $i++ )
    {
        $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: \"" . $wordBAry[$i] . "\" Not In Dictionary" ) if index( $wordsFoundB, $wordBAry[$i] ) == -1;
        $error = 1 if index( $wordsFoundB, $wordBAry[$i] ) == -1 && $allWordsMustExist == 1;
    }

    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Error: Comparing Empty String / No Found Words" ) if ( $wordsFoundA eq "" || $wordsFoundB eq "" );
    $error = 1 if ( $wordsFoundA eq "" || $wordsFoundB eq "" );

    return undef if $error != 0;


    $self->WriteLog( "ComputeMultiWordCosineSimilarity - Words Present In Dictionary" );

    # Remove Words From Word Vectors
    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        my @tempAry = @{ $wordAVtr[$i] };
        shift( @tempAry );
        $wordAVtr[$i] = \@tempAry;
    }

    for( my $i = 0; $i < @wordBVtr; $i++ )
    {
        my @tempAry = @{ $wordBVtr[$i] };
        shift( @tempAry );
        $wordBVtr[$i] = \@tempAry;
    }


    # Compute Sum Of Compound Words
    my @wordASumAry = ();
    my @wordBSumAry = ();

    my $wordVtrASize = @{ $wordAVtr[0] };
    my $wordVtrBSize = @{ $wordBVtr[0] };

    for( my $i = 0; $i < $wordVtrASize; $i++ )
    {
        my $value = 0;

        for my $aryRef ( @wordAVtr )
        {
            $value += $aryRef->[$i];
        }

        push( @wordASumAry, $value );
    }

    for( my $i = 0; $i < $wordVtrBSize; $i++ )
    {
        my $value = 0;

        for my $aryRef ( @wordBVtr )
        {
            $value += $aryRef->[$i];
        }

        push( @wordBSumAry, $value );
    }


    # Cosine Similarity => cos(angle) =       ->      ->
    #                                         A   *   B
    #                                    -------------------
    #                                        ->        ->
    #                                     || A || * || B ||
    #
    # Explanation: Dot Product Of VectorA By VectorB, Divided By The Square Root Of Dot Product Of Vector A Multiplied By Square Root Of Dot Product Of Vector B

    my $dpA = 0;
    my $dpB = 0;
    my $ldpA = 0;
    my $ldpB = 0;
    my $dpAB = 0;

    # Compute Dot Product Of VectorA
    for my $value ( @wordASumAry )
    {
        $dpA += ( $value * $value );
    }

    # Compute Dot Product Of VectorB
    for my $value ( @wordBSumAry )
    {
        $dpB += ( $value * $value );
    }

    # Compute $ldpA & $ldpB
    $ldpA = sqrt( $dpA );
    $ldpB = sqrt( $dpB );

    # Compute Cosine Similarity Between Vector A & Vector B
    for( my $i = 0; $i < $wordVtrASize; $i++ )
    {
        # Compute Value If Not Dividing By Zero
        $dpAB += ( ( $wordASumAry[$i] / $ldpA ) * ( $wordBSumAry[$i] / $ldpB ) ) if ( $ldpA != 0 && $ldpB != 0 );
    }

    # Return Value Cosine Similarity Value Rounded To Six Decimal Places
    return sprintf( "%.6f", $dpAB );
}

sub ComputeCosineSimilarityOfWordVectors
{
    my ( $self, $wordAData, $wordBData ) = @_;

    # Check(s)
    $self->WriteLog( "ComputeCosineSimilarityOfWordVectors - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordAData ) || !defined ( $wordBData );
    return undef if !defined ( $wordAData ) || !defined ( $wordBData );

    $self->WriteLog( "ComputeCosineSimilarityOfWordVectors - Error: One Or More Word Vectors Consist Of No Data" ) if ( $wordAData eq "" || $wordBData eq "" );
    return undef if ( $wordAData eq "" || $wordBData eq "" );

    $self->WriteLog( "ComputeCosineSimilarityOfWordVectors - Computing Cosine Similarity Of Word Vectors: \"$wordAData\" and \"$wordBData\"" );

    my @wordAVtr = split( ' ', $wordAData );
    my @wordBVtr = split( ' ', $wordBData );

    undef( $wordAData );
    undef( $wordBData );

    my $wordAVtrSize = @wordAVtr;
    my $wordBVtrSize = @wordBVtr;

    # Check(s)
    $wordAVtrSize = 0 if !defined( $wordAVtrSize );
    $wordBVtrSize = 0 if !defined( $wordBVtrSize );

    $self->WriteLog( "ComputeCosineSimilarityOfWordVectors - Words Present In Dictionary" );

    # Cosine Similarity => cos(angle) =       ->      ->
    #                                         A   *   B
    #                                    -------------------
    #                                        ->        ->
    #                                     || A || * || B ||
    #
    # Explanation: Dot Product Of VectorA By VectorB, Divided By The Square Root Of Dot Product Of Vector A Multiplied By Square Root Of Dot Product Of Vector B

    my $dpA = 0;
    my $dpB = 0;
    my $ldpA = 0;
    my $ldpB = 0;
    my $dpAB = 0;

    # Compute Dot Product Of VectorA
    for my $value ( @wordAVtr )
    {
        $dpA += ( $value * $value );
    }

    # Compute Dot Product Of VectorB
    for my $value ( @wordBVtr )
    {
        $dpB += ( $value * $value );
    }

    # Compute $ldpA & $ldpB
    $ldpA = sqrt( $dpA );
    $ldpB = sqrt( $dpB );

    # Compute Cosine Similarity Between Vector A & Vector B
    for( my $i = 0; $i < $wordAVtrSize; $i++ )
    {
        # Compute Value If Not Dividing By Zero
        $dpAB += ( ( $wordAVtr[$i] / $ldpA ) * ( $wordBVtr[$i] / $ldpB ) ) if ( $ldpA != 0 && $ldpB != 0 );
    }

    # Return Value Cosine Similarity Value Rounded To Six Decimal Places
    return sprintf( "%.6f", $dpAB );
}

sub CosSimWithUserInput
{
    my ( $self ) = @_;

    # Check
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "CosSimWithUserInput - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    my $exit = 0;

    $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 );
    print( "Input (Type \"EXIT\" to exit): " ) if $self->GetDebugLog() == 0;

    while ( my $input = <STDIN> )
    {
        chomp( $input );
        return if $input eq "EXIT";

        my @wordAry = split( ' ', $input );
        $self->WriteLog( "Warning: Requires two words for input - ex \"man woman\"" ) if @wordAry == 0 || @wordAry == 1;
        $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 ) if @wordAry == 0 || @wordAry == 1;

        # Print Data To Console When DebugLog == 0
        print( "Warning: Requires two words for input - ex \"man woman\" \n" ) if ( $self->GetDebugLog == 0 && ( @wordAry == 0 || @wordAry == 1 ) );
        print( "Input (Type \"EXIT\" to exit): " ) if ( $self->GetDebugLog == 0 && ( @wordAry == 0 || @wordAry == 1 ) );
        next if ( @wordAry == 0 || @wordAry == 1 );

        my $value = $self->ComputeCosineSimilarity( $wordAry[0], $wordAry[1] );
        $self->WriteLog( "Result: $value" ) if defined ( $value );
        $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 );

        # Print Data To Console When DebugLog == 0
        print( "Error: One Or More Words Not Present In Dictionary\n" ) if ( !defined ( $value ) && $self->GetDebugLog() == 0 );
        print( "Result: $value\n" ) if ( defined ( $value ) && $self->GetDebugLog == 0 );
        print( "Input (Type \"EXIT\" to exit): " ) if $self->GetDebugLog == 0;
    }
}

sub MultiWordCosSimWithUserInput
{
    my ( $self ) = @_;

    # Check
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "CosSimWithUserInput - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    my $exit = 0;

    $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 );
    print( "Input (Type \"EXIT\" to exit): " ) if $self->GetDebugLog() == 0;

    while ( my $input = <STDIN> )
    {
        chomp( $input );
        return if $input eq "EXIT";

        my @wordAry = split( ' ', $input );
        $self->WriteLog( "Warning: Requires two words for input - ex \"man woman\"" ) if @wordAry == 0 || @wordAry == 1;
        $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 ) if @wordAry == 0 || @wordAry == 1;

        # Print Data To Console When DebugLog == 0
        print( "Warning: Requires two words for input - ex \"man woman\"\n" ) if ( $self->GetDebugLog == 0 && ( @wordAry == 0 || @wordAry == 1 ) );
        print( "Input (Type \"EXIT\" to exit): " ) if ( $self->GetDebugLog == 0 && ( @wordAry == 0 || @wordAry == 1 ) );
        next if @wordAry == 0 || @wordAry == 1;

        my @wordArg1 = split( ':', $wordAry[0] );
        my @wordArg2 = split( ':', $wordAry[1] );
        my $arg1 = join( ' ', @wordArg1 );
        my $arg2 = join( ' ', @wordArg2 );
        my $value = $self->ComputeMultiWordCosineSimilarity( $arg1, $arg2 );
        $self->WriteLog( "Result: $value" ) if defined ( $value );
        $self->WriteLog( "Input (Type \"EXIT\" to exit): ", 0 );

        # Print Data To Console When DebugLog == 0
        print( "Error: One Or More Words Not Present In Dictionary\n" ) if ( !defined ( $value ) && $self->GetDebugLog() == 0 );
        print( "Result: $value\n" ) if ( defined ( $value ) && $self->GetDebugLog() == 0 );
        print( "Input (Type \"EXIT\" to exit): " ) if $self->GetDebugLog() == 0;
    }
}

sub ComputeAverageOfWords
{
    my ( $self, $wordAryRef ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "ComputeAverageOfWords - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "Error: Method Requires Array Reference Argument / Argument Not Defined" ) if !defined( $wordAryRef );
    return undef if !defined( $wordAryRef );

    my @wordAry = @{ $wordAryRef };

    my @foundWords = ();
    my @foundWordData = ();
    my @resultAry = ();

    my $wordDataSize = 0;

    $self->WriteLog( "ComputeAverageOfWords - Locating Words In Vocabulary/Dictionary" );

    # Normal Memory Usage Mode
    if( $self->GetMinimizeMemoryUsage() == 0 )
    {
        # Find Words
        for my $word ( @wordAry )
        {
            # Dense Vector Data Algorithm
            if( $self->GetSparseVectorMode() == 0 )
            {
                # Fetch Word From Vocabulary/Dictionary
                my $result = $self->GetWordVector( $word );

                # Store Found Word
                push( @foundWords, $word ) if defined( $result );

                # Store Found Word Vector Data
                my @wordData = split( ' ', $result ) if defined( $result );
                push( @foundWordData, [ @wordData ] ) if @wordData > 0;

                $wordDataSize = @wordData - 1 if $wordDataSize == 0 && defined( $result );
            }
            # Sparse Vector Data Algorithm
            else
            {
                # Fetch Word From Vocabulary/Dictionary
                my $result = $self->GetWordVector( $word, 1 );

                # Store Found Word
                push( @foundWords, $word ) if defined( $result );

                # Store Found Word Vector Data
                push( @foundWordData, $self->ConvertRawSparseTextToVectorDataHash( $result ) ) if defined( $result );

                $wordDataSize = $self->GetVectorLength() if $wordDataSize == 0 && defined( $result );
            }
        }

        $self->WriteLog( "ComputeAverageOfWords - Found: \"" . @foundWords . "\" Of \"" . @wordAry . "\" Words" );
        $self->WriteLog( "ComputeAverageOfWords - Computing Average Of Found Word(s): @foundWords" ) if @foundWords > 0;

        # Clear Found Words (Strings)
        undef( @foundWords );
        @foundWords = ();

        # Compute Average Of Vector Data For Found Words,
        # Sum Values Of All Found Word Vectors / Dense Vector Format
        if( $self->GetSparseVectorMode() == 0 )
        {
            for( my $i = 0; $i < $wordDataSize; $i++ )
            {
                my $value = 0;

                for( my $j = 0; $j < @foundWordData; $j++ )
                {
                    $value += $foundWordData[$j]->[$i+1];
                }

                # Compute Average
                $value /= @foundWordData;

                # Round Decimal Places Greater Than Six
                $value = sprintf( "%.6f", $value );

                # Store Value In Resulting Array
                push( @resultAry, $value );
            }
        }
        # Sum Values Of All Found Word Vectors / Sparse Vector Format
        else
        {
            # Create And Zero Fill The Result Vector
            @resultAry = ( "0.000000" ) x $wordDataSize;

            for( my $i = 0; $i < @foundWordData; $i++ )
            {
                for my $key ( keys( %{ $foundWordData[$i] } ) )
                {
                    $resultAry[$key-1] += sprintf( "%.6f", $foundWordData[$i]->{$key} );
                }
            }

            # Compute Average Of All Result Vector Elements
            if( @foundWordData > 1 )
            {
                for( my $i = 0; $i < @resultAry; $i++ )
                {
                    $resultAry[$i] /= @foundWordData;
                    $resultAry[$i] = sprintf( "%.6f", $resultAry[$i] );
                }
            }
        }

        # Clear Vector Data For Found Words
        if( $self->GetSparseVectorMode() == 0 )
        {
            for( my $i = 0; $i < @foundWordData; $i++ )
            {
                $foundWordData[$i] = [];
            }
        }
        else
        {
            for( my $i = 0; $i < @foundWordData; $i++ )
            {
                $foundWordData[$i] = {};
            }
        }

        # Clear Found Word Data
        undef( @foundWordData );
        @foundWordData = ();
    }
    # Minimal Memory Usage Mode
    else
    {
        # Find Words
        for my $word ( @wordAry )
        {
            # Dense Vector Format / Minimal Memory Usage Mode
            if( $self->GetSparseVectorMode() == 0 )
            {
                # Fetch Word From Vocabulary/Dictionary
                my $result = $self->GetWordVector( $word );

                next if !defined( $result );

                # Store Found Word
                push( @foundWords, $word ) if defined( $result );

                # Split Found Word Vector Data Into An Array
                my @wordData = split( ' ', $result ) if defined( $result );

                # Set Word Vector Length
                $wordDataSize = @wordData - 1 if ( $wordDataSize == 0 && defined( $result ) );

                # Create And Zero Fill The Result Vector If Not Already Done
                @resultAry = ( "0.000000" ) x $wordDataSize if ( @resultAry == 0 && @resultAry != $wordDataSize );

                for( my $i = 1; $i < @wordData; $i++ )
                {
                    my $value = $wordData[$i];

                    # Round Decimal Places Greater Than Six
                    $value = sprintf( "%.6f", $value );

                    $resultAry[$i-1] += $value;
                }

                $result = "" if ( defined( $result ) && $result ne "" );

                undef( @wordData );
                @wordData = ();
            }
            # Sparse Vector Format / Minimal Memory Usage Mode
            else
            {
                # Create And Zero Fill The Result Vector If Not Already Done
                @resultAry = ( "0.000000" ) x $self->GetVectorLength() if @resultAry == 0;

                # Fetch Word From Vocabulary/Dictionary
                my $result = $self->GetWordVector( $word, 1 );

                # Store Found Word
                push( @foundWords, $word ) if defined( $result );

                # Store Found Word Vector Data
                my $wordData = $self->ConvertRawSparseTextToVectorDataHash( $result ) if defined( $result );

                # Copy Hash Element Data To Defined Array Indices
                for my $key ( keys( %{ $wordData } ) )
                {
                    $resultAry[$key-1] += sprintf( "%.6f", $wordData->{$key} );
                }

                # Clear Hash Data
                $wordData = {};
                undef( %{ $wordData } );
                $result = "";
            }
        }

        $self->WriteLog( "ComputeAverageOfWords - Found: \"" . @foundWords . "\" Of \"" . @wordAry . "\" Words" );
        $self->WriteLog( "ComputeAverageOfWords - Computing Average Of Found Word(s): @foundWords" ) if @foundWords > 0;

        # Compute Average Of All Result Vector Elements
        if( @foundWords > 1 )
        {
            for( my $i = 0; $i < @resultAry; $i++ )
            {
                $resultAry[$i] /= @foundWords;
                $resultAry[$i] = sprintf( "%.6f", $resultAry[$i] );
            }
        }

        # Clear Found Words (Strings)
        undef( @foundWords );
        @foundWords = ();
    }

    $self->WriteLog( "ComputeAverageOfWords - Complete" ) if @resultAry > 0;
    $self->WriteLog( "ComputeAverageOfWords - Completed With Errors" ) if @resultAry == 0;

    my $returnStr = join( ' ', @resultAry ) if @resultAry > 0;
    $returnStr = undef if @resultAry == 0;
    undef( @resultAry );
    return $returnStr;
}

sub AddTwoWords
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "AddTwoWords - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "AddTwoWords - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    my $wordAData = $self->GetWordVector( $wordA );
    my $wordBData = $self->GetWordVector( $wordB );

    $self->WriteLog( "AddTwoWords - Error: \"$wordA\" Not In Dictionary" ) if !defined( $wordAData );
    $self->WriteLog( "AddTwoWords - Error: \"$wordB\" Not In Dictionary" ) if !defined( $wordBData );
    return undef if  !defined( $wordAData ) || !defined( $wordBData );

    my @wordAVtr = split( ' ', $wordAData );
    my @wordBVtr = split( ' ', $wordBData );

    # More Check(s)
    $self->WriteLog( "AddTwoWords - Cannot Add Two Word Vectors / Vtr Sizes Not Equal" ) if ( @wordAVtr != @wordBVtr ) ;
    return undef if ( @wordAVtr != @wordBVtr );

    # Remove Word From Word Vector (First Element)
    shift( @wordAVtr );
    shift( @wordBVtr );

    $self->WriteLog( "AddTwoWords - Adding Two Word Vectors" );

    my @resultVtr = ();

    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        push( @resultVtr, $wordAVtr[$i] + $wordBVtr[$i] );
    }

    my $resultStr = join( ' ', @resultVtr );
    undef( @resultVtr );

    $self->WriteLog( "AddTwoWords - Complete" );

    return $resultStr;
}

sub SubtractTwoWords
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "AddTwoWords - Error: Dictionary Is Empty / No Vector Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    $self->WriteLog( "SubtractTwoWords - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    my $wordAData = $self->GetWordVector( $wordA );
    my $wordBData = $self->GetWordVector( $wordB );

    $self->WriteLog( "SubtractTwoWords - Error: \"$wordA\" Not In Dictionary" ) if !defined( $wordAData );
    $self->WriteLog( "SubtractTwoWords - Error: \"$wordB\" Not In Dictionary" ) if !defined( $wordBData );
    return undef if  !defined( $wordAData ) || !defined( $wordBData );

    my @wordAVtr = split( ' ', $wordAData );
    my @wordBVtr = split( ' ', $wordBData );

    # More Check(s)
    $self->WriteLog( "SubtractTwoWords - Cannot Add Two Word Vectors / Vtr Sizes Not Equal" ) if ( @wordAVtr != @wordBVtr ) ;
    return undef if ( @wordAVtr != @wordBVtr );

    # Remove Word From Word Vector (First Element)
    shift( @wordAVtr );
    shift( @wordBVtr );

    $self->WriteLog( "SubtractTwoWords - Subtracting Two Word Vectors" );

    my @resultVtr = ();

    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        push( @resultVtr, $wordAVtr[$i] - $wordBVtr[$i] );
    }

    my $resultStr = join( ' ', @resultVtr );
    undef( @resultVtr );

    $self->WriteLog( "SubtractTwoWords - Complete" );

    return $resultStr;
}

sub AddTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "AddTwoWordVectors - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    my @wordAVtr = split( ' ', $wordA );
    my @wordBVtr = split( ' ', $wordB );

    # More Check(s)
    $self->WriteLog( "AddTwoWordVectors - Cannot Add Two Word Vectors / Vtr Sizes Not Equal" ) if ( @wordAVtr != @wordBVtr ) ;
    return undef if ( @wordAVtr != @wordBVtr );

    $self->WriteLog( "AddTwoWordVectors - Adding Two Word Vectors" );

    my @resultVtr = ();

    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        push( @resultVtr, $wordAVtr[$i] + $wordBVtr[$i] );
    }

    my $resultStr = join( ' ', @resultVtr );
    undef( @resultVtr );

    $self->WriteLog( "AddTwoWordVectors - Complete" );

    return $resultStr;
}

sub SubtractTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "SubtractTwoWordVectors - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    my @wordAVtr = split( ' ', $wordA );
    my @wordBVtr = split( ' ', $wordB );

    # More Check(s)
    $self->WriteLog( "SubtractTwoWordVectors - Cannot Subtract Two Word Vectors / Vtr Sizes Not Equal" ) if ( @wordAVtr != @wordBVtr ) ;
    return undef if ( @wordAVtr != @wordBVtr );

    $self->WriteLog( "SubtractTwoWordVectors - Subtracting Two Word Vectors" );

    my @resultVtr = ();

    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        push( @resultVtr, $wordAVtr[$i] - $wordBVtr[$i] );
    }

    my $resultStr = join( ' ', @resultVtr );
    undef( @resultVtr );

    $self->WriteLog( "SubtractTwoWordVectors - Complete" );

    return $resultStr;
}

sub AverageOfTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "AverageOfTwoWordVectors - Error: Function Requires Two Arguments (Word Vectors)" ) if !defined ( $wordA ) || !defined ( $wordB );
    return undef if !defined ( $wordA ) || !defined ( $wordB );

    my @wordAVtr = split( ' ', $wordA );
    my @wordBVtr = split( ' ', $wordB );

    # More Check(s)
    $self->WriteLog( "AverageOfTwoWordVectors - Cannot Compute Average Of Word Vectors / Vtr Sizes Not Equal" ) if ( @wordAVtr != @wordBVtr ) ;
    return undef if ( @wordAVtr != @wordBVtr );

    $self->WriteLog( "AverageOfTwoWordVectors - Averaging Two Word Vectors" );

    my @resultVtr = ();

    for( my $i = 0; $i < @wordAVtr; $i++ )
    {
        push( @resultVtr, ( $wordAVtr[$i] - $wordBVtr[$i] ) / 2 );
    }

    my $resultStr = join( ' ', @resultVtr );
    undef( @resultVtr );

    $self->WriteLog( "AverageOfTwoWordVectors - Complete" );

    return $resultStr;
}

sub GetWordVector
{
    my ( $self, $searchWord, $returnRawSparseText ) = @_;

    $returnRawSparseText = 1 if defined( $returnRawSparseText );
    $returnRawSparseText = 0 if !defined( $returnRawSparseText );

    # Check(s)
    print( "Error: Dictionary Is Empty / No Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 && $self->IsVectorDataInMemory() == 0 );
    $self->WriteLog( "GetWordVector - Error: No Vector Data In Memory - Cannot Fetch Word Vector Data" ) if ( $self->IsVectorDataInMemory() == 0 );
    return undef if ( $self->IsVectorDataInMemory() == 0 );

    my $wordVectorData = $self->GetVocabularyHash->{ $searchWord };

    $self->WriteLog( "GetWordVector - Warning: \"$searchWord\" Not Found In Dictionary" ) if !defined( $wordVectorData );

    return undef if !defined( $wordVectorData );

    my $returnStr = "";

    # Convert Sparse Format To Regular Format
    if( $self->GetSparseVectorMode() == 1 )
    {
        if( $returnRawSparseText == 1 )
        {
            return $searchWord . " " . $wordVectorData;
        }

        my $vectorSize = $self->GetVectorLength();

        # Check
        $self->WriteLog( "GetWordVector - Error: Cannot Convert Sparse Data To Dense Format / Vector Length = 0 - Expects Vector Length >= 1" ) if ( $vectorSize == 0 );
        return undef if ( $vectorSize == 0 );

        my @data = split( ' ', $wordVectorData );

        # Make Array Of Vector Size With All Zeros
        my @wordVector = ( "0.000000" ) x $vectorSize if ( $vectorSize != 0 );

        for( my $i = 0; $i < @data; $i++ )
        {
            # If The Index ($i) Is Even, Then The Element Is An Index
            my $index = $data[$i] if ( $i % 2 == 0 );

            # If The Index Is Defined, Then Next Element Is An Index Element
            my $element = $data[$i+1] if defined( $index );

            # Assign The Correct Index Element To The Specified Index
            $wordVector[$index] = $element if defined( $index ) && defined( $element );
        }

        # Assign New Standard Format Word Vector To $returnStr
        $returnStr = $searchWord . " " . join( ' ', @wordVector );

        # Clear Array
        undef( @data );
        @data = ();
        undef( @wordVector );
        @wordVector = ();
    }
    else
    {
        $returnStr = $searchWord . " " . $wordVectorData;
    }

    return $returnStr;
}

sub IsVectorDataInMemory
{
    my ( $self ) = @_;

    my $numberOfWordsInMemory = scalar keys %{ $self->GetVocabularyHash() };
    return 1 if $numberOfWordsInMemory > 0;

    return 0;
}

sub IsWordOrCUIVectorData
{
    my ( $self ) = @_;

    # Check(s)
    $self->WriteLog( "isWordOrCUIVectorData - Error: No Vector Vocabulary Data In Memory" ) if $self->IsVectorDataInMemory() == 0;
    return undef if $self->IsVectorDataInMemory() == 0;

    my @vocabularyWords = keys %{ $self->GetVocabularyHash() };
    @vocabularyWords = sort( @vocabularyWords );

    # Choose Random Word, Avoiding First Three Vector Elements
    my $term = $vocabularyWords[ rand( @vocabularyWords - 2 ) + 2 ];

    # Clean Up
    undef( @vocabularyWords );

    # Perform Check
    $term = lc( $term );
    my @terms = split( 'c', $term );

    # Return Word Term If There Are Not Two Elements After Splitting
    return "word" if( @terms != 2 );

    # If $term Is CUI, Then First Element Should Be Empty String
    return "word" if ( $terms[0] ne "" );

    # Remove Numbers From Second Element
    $terms[1] =~ s/[0-9]//g;

    # If $term Is CUI, Then After Removing All Number From Second Element An Empty String Is All That Is Left
    return "word" if ( $terms[1] ne "" );

    return "cui";
}

sub IsVectorDataSorted
{
    my ( $self, $aryRef ) = @_;

    my $vocabHashRef = $self->GetVocabularyHash() if !defined( $aryRef );
    $vocabHashRef = $aryRef if defined( $aryRef );

    $self->WriteLog( "IsVectorDataSorted - Error: No Vector Data In Memory" ) if ( keys %{ $vocabHashRef } == 0 );
    return -1 if ( keys %{ $vocabHashRef } == 0 );

    my $numOfWords = $self->GetNumberOfWords();
    my $vectorLength = $self->GetVectorLength();

    return 1 if defined( $vocabHashRef->{ $numOfWords } ) && $vocabHashRef->{ $numOfWords } eq "$vectorLength #\$\@RTED#";
    return 0;
}

sub CheckWord2VecDataFileType
{
    my ( $self, $fileDir ) = @_;

    # Check(s)
    $self->WriteLog( "CheckWord2VecDataFileType - Error: File Path Not Defined" ) if !defined( $fileDir );
    return undef if !defined( $fileDir );

    $self->WriteLog( "CheckWord2VecDataFileType - Error: File Cannot Be Found / Does Not Exist" ) if !( -e $fileDir );
    return undef if !( -e $fileDir );


    # Check Word Vector File Format
    my $fileType = "";
    my $numOfWordVectors = 0;
    my $sizeOfVectors = 0;
    my $sparseVectorsFlag = 0;

    open( my $fh, "<:", "$fileDir" ) or $self->WriteLog( "CheckWord2VecDataFileType - Error Opening File : $!" );

    for( my $i = 0; $i < 2; $i++ )
    {
        my $data = <$fh>;

        # Store Number Of Word Vectors And Vector Size
        if( $i == 0 )
        {
            my @dimensionsAry = split( ' ', $data );

            # Fetch Number Of Word Vectors
            $numOfWordVectors = $dimensionsAry[0] if ( @dimensionsAry >= 2 );

            # Fetch Size Of Vectors
            $sizeOfVectors = $dimensionsAry[1] if ( @dimensionsAry >= 2 );

            # Skip First Line (First Line Is Always Plain Text Format)
            next;
        }

        # Check Second Line Of File To Determine Whether File Is Text Or Binary Format
        my $oldData = $data;
        my $newData = Encode::decode( "utf8", $data, Encode::FB_QUIET );
        $fileType = "text" if length( $oldData ) == length( $newData );
        $fileType = "binary" if length( $oldData ) != length( $newData );

        # Check Second Line For Sparse Vector
        my @dataAry = split( ' ', $oldData ) if defined( $oldData );
        $sparseVectorsFlag = 1 if defined( $oldData ) && ( @dataAry - 1 != $sizeOfVectors );
    }

    # Read A Couple Lines To Determine Whether Vectors Are 'Sparse' Or 'Full' Plain Vectors
    if( $fileType eq "text" )
    {
        my $checkLength = 50 if ( $numOfWordVectors > 50 );
        $checkLength = $numOfWordVectors if ( $numOfWordVectors < 50 );

        # Read Data From File To Check For Sparse Vectors
        for( my $i = 0; $i < $checkLength - 2; $i++ )
        {
            my $data = <$fh>;
            my @dataAry = split( ' ', $data ) if defined( $data );
            $sparseVectorsFlag = 1 if defined( $data ) && ( @dataAry - 1 != $sizeOfVectors );
        }

        $fileType = "sparsetext" if ( $sparseVectorsFlag == 1 );
    }

    close( $fh );
    undef( $fh );

    return $fileType;
}

sub ReadTrainedVectorDataFromFile
{
    my ( $self, $fileDir, $searchWord ) = @_;

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Reading File \"$fileDir\"" );

    # Check(s)
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Directory Not Defined" ) if !defined ( $fileDir );
    return -1 if !defined ( $fileDir );

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Directory/File Does Not Exist" ) if !( -e "$fileDir" );
    return -1 if !( -e "$fileDir" );

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Vector Data File Size = 0 bytes / File Contains No Data" ) if ( -z "$fileDir" );
    return -1 if ( -z "$fileDir" );

    my $numberOfWordsInMemory = $self->GetNumberOfWords();
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Module Already Contains Vector Training Data In Memory" ) if $numberOfWordsInMemory > 0;
    return -1 if $numberOfWordsInMemory > 0;

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Searching For Word \"$searchWord\" In Vector Data File \"$fileDir\"" )       if defined( $searchWord );
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Warning: Vector Data Will Be Cleared From Memory After Search Is Complete" ) if defined ( $searchWord );

    # Check To See If File Data Is Binary Or Text
    my $fileType = $self->CheckWord2VecDataFileType( $fileDir );

    # Check
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Unable To Determine Vector Data Format" ) if !defined( $fileType );
    return -1 if !defined( $fileType );

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Detected File Type As \"Plain Text Format\"" ) if $fileType eq "text" ;
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Detected File Type As \"Sparse Vector Text Format\"" ) if $fileType eq "sparsetext" ;
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Detected File Type As \"Word2Vec Binary Format\"" ) if $fileType eq "binary" ;

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Setting \"Sparse Vector Mode\" = True" ) if $fileType eq "sparsetext" ;
    $self->SetSparseVectorMode( 1 ) if $fileType eq "sparsetext";
    $self->SetSparseVectorMode( 0 ) if $fileType ne "sparsetext";

    $self->WriteLog( "ReadTrainedVectorDataFromFile - Reading Data" );


    # Read Trained Vector Data From File To Memory
    my $fileHandle;

    # Read Plain Text Data Format From File
    if ( $fileType eq "text" )
    {
        my $lineCount = 0;
        open( $fileHandle, '<:encoding(UTF-8)', "$fileDir" );

        while( my $row = <$fileHandle> )
        {
            chomp $row;
            $row = lc( $row );

            # Progress Percent Indicator - Print Percentage Of File Loaded
            print( int( ( $lineCount / $self->GetNumberOfWords() ) * 100 ) . "%" ) if ( $self->GetNumberOfWords() > 0 );

            # Skip If Line Is Empty
            next if( length( $row ) == 0 );

            if( $lineCount == 0 )
            {
                my @data = split( ' ', $row );

                # Check(s)
                if( @data < 2 )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: File Does Not Contain Header Information / NumOfWords & VectorLength" );
                    close( $fileHandle );
                    return -1;
                }

                $self->SetNumberOfWords( $data[0] );
                $self->SetVectorLength( $data[1] );
            }

            # Search For Search Word And Return If Found
            if ( defined( $searchWord ) )
            {
                my @data = split( ' ', $row );

                if ( $data[0] eq $searchWord )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Search Word Found / Clearing Variables" );
                    $self->ClearVocabularyHash();
                    close( $fileHandle );
                    return join( ' ', @data );
                }
            }
            # Store Vector Data In Memory
            else
            {
                $self->AddWordVectorToVocabHash( $row );
            }

            # Progress Percent Indicator - Return To Beginning Of Line
            print( "\r" ) if ( $self->GetNumberOfWords() > 0 );

            $lineCount++;
        }

        close( $fileHandle );
    }
    # Read Spare Text Format From File
    elsif( $fileType eq "sparsetext" )
    {
        my $lineCount = 0;
        my $numOfWordVectors = 0;
        my $vectorSize = 0;

        open( $fileHandle, '<:encoding(UTF-8)', "$fileDir" );

        while( my $row = <$fileHandle> )
        {
            chomp $row;
            $row = lc( $row );

            # Progress Percent Indicator - Print Percentage Of File Loaded
            print( int( ( $lineCount / $self->GetNumberOfWords() ) * 100 ) . "%" ) if ( $self->GetNumberOfWords() > 0 );

            # Skip If Line Is Empty
            next if( length( $row ) == 0 );

            # Skip First Line ( First Line Holds Number Of Word Vectors And Vector Size / Is Always Even )
            if( $lineCount == 0 )
            {
                my @data = split( ' ', $row );

                # Check(s)
                if( @data < 2 )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: File Does Not Contain Header Information / NumOfWords" );
                    close( $fileHandle );
                    return -1;
                }

                $numOfWordVectors = $data[0];
                $vectorSize = $data[1] - 1;

                $self->SetNumberOfWords( $numOfWordVectors );
                $self->SetVectorLength( $vectorSize + 1 );

            }
            elsif( $lineCount > 0 )
            {
                my @data = split( ' ', $row );

                # If Array Size Is Odd, Then Error Out
                # Explanation: ie. - $dataAry[1] = "heart 1 0.002323 4 0.124342 16 0.005610 17"
                #              There Are Four Indices And Three Index Elements, There Should Be
                #              One Index Per Index Element. A Proper Sparse Vector Should Look As Follows.
                #              ie. - $dataAry[1] = "heart 1 0.002323 4 0.124342 16 0.005610 17 0.846613"
                #              With The Word Included In The Word Vector, The Vector Size Should Always
                #              Be Odd By Nature.
                #
                if ( @data > 2 && @data % 2 == 0 )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: Improper Sparse Vector Format - Index/Index Element Number Mis-Match" );
                    $self->WriteLog( "ReadTrainedVectorDataFromFile -        Occured At Line #$lineCount: \"$row\"" );
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Clearing Vocabulary Array" );
                    $self->ClearVocabularyHash();
                    return -1;
                }

                # Fetch String Word In First Element
                $self->WriteLog( "ReadTrainedVectorDataFromFile - Error: First Element Of Data Array (Word) Not Defined - Line: $lineCount" ) if !defined( $data[0] );
                return -1 if !defined( $data[0] );

                # Clear Array
                @data = ();
            }

            # Search For Search Word And Return If Found
            if ( defined( $searchWord ) )
            {
                my @data = split( ' ', $row );

                if ( $data[0] eq $searchWord )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Search Word Found / Clearing Variables" );
                    $self->ClearVocabularyHash();
                    close( $fileHandle );
                    return join( ' ', @data );
                }
            }
            # Store Vector Data In Memory
            else
            {
                $self->AddWordVectorToVocabHash( $row );
            }

            # Progress Percent Indicator - Return To Beginning Of Line
            print( "\r" ) if ( $self->GetNumberOfWords() > 0 );

            $lineCount++;
        }

        close( $fileHandle );
    }
    # Read Word2Vec Binary Data Format From File
    elsif( $fileType eq "binary" )
    {
        open( $fileHandle, "$fileDir" );
        binmode $fileHandle;

        my $buffer = "";
        my $word = "";
        my $wordVectorData = "";

        # Fetch "Number Of Words" and "Word Vector Size" From First Line
        my $row = <$fileHandle>;
        chomp( $row );

        # Skip If Line Is Empty
        next if( length( $row ) == 0 );

        my @strAry = split( ' ', $row );

        # Check(s)
        return if @strAry < 2;


        my $wordCount = $strAry[0];
        my $wordSize = $strAry[1];
        my $count = 1;
        $word = "";

        $self->SetNumberOfWords( $wordCount );
        $self->SetVectorLength( $wordSize );

        # Add Word Count & Word Vector Size To Memory
        $self->AddWordVectorToVocabHash( "$row" );

        # Begin Fetching Data From File
        while( $count < $wordCount + 1 )
        {
            my $cont = 1;

            # Progress Percent Indicator - Print Percentage Of File Loaded
            print( int( ( $count / $self->GetNumberOfWords() ) * 100 ) . "%" ) if ( $self->GetNumberOfWords() > 0 );

            # Fetch Word
            while( $cont == 1 )
            {
                # Fetch Word
                chomp( $buffer = getc( $fileHandle ) );
                $word .= $buffer if $buffer ne " " && defined( $buffer );

                # Check(s)
                $cont = 0 if eof;
                $cont = 0 if $buffer eq " ";
                $self->WriteLog( "ReadTrainedVectorDataFromFile - ERROR: Unexpectedly Reached End Of File" ) if eof;
                $self->WriteLog( "                                       Expected Word Count / Vector Size") if eof;
                $self->WriteLog( "                                                $wordCount / $wordSize" ) if eof;
                $self->WriteLog( "                                       Current Word Count" ) if eof;
                $self->WriteLog( "                                                   $count" ) if eof;
                $count = $wordCount + 1 if eof;
                next if eof;
            }

            # Fetch Word Vector Float Values
            for( my $i = 0; $i < $wordSize; $i++ )
            {
                # Read Specified Bytes Amount From File
                read( $fileHandle, $buffer, 4 );                                                # Assumes size of floating point is 4 bytes
                chomp( $buffer );

                # Check(s)
                $i = $wordSize + 1 if !defined( $buffer ) || $buffer eq 0;
                next if !defined( $buffer ) || $buffer eq 0;

                if( defined( $buffer ) && $buffer ne "" )
                {
                    # Convert Binary Values To Float
                    $buffer = unpack( "f", $buffer );                                           # Unpacks/convert 4 byte string to floating point
                    $wordVectorData .= ( " " . sprintf( "%.6f", $buffer ) );                    # Round Decimal At Sixth Place
                }
            }

            # Word Vector = Word + WordVectorData
            $word .= $wordVectorData;

            # Search For Search Word And Return If Found
            if ( defined( $searchWord ) )
            {
                my @data = split( ' ', $word );

                if ( $data[0] eq $searchWord )
                {
                    $self->WriteLog( "ReadTrainedVectorDataFromFile - Search Word Found / Clearing Variables" );
                    $self->ClearVocabularyHash();
                    close( $fileHandle );
                    return join( ' ', @data );
                }
            }
            # Store Vector Data In Memory
            else
            {
                # Add Word Vector To Memory
                $self->AddWordVectorToVocabHash( $word ) if $word ne "";
            }

            # Clear Variables
            $word = "";
            $wordVectorData = "";
            $buffer = "";

            $count++;

            # Progress Percent Indicator - Return To Beginning Of Line
            print( "\r" ) if ( $self->GetNumberOfWords() > 0 );
        }

        close( $fileHandle );
    }

    my $numberOfWords = keys %{ $self->GetVocabularyHash() } if defined( $self->GetVocabularyHash() );
    $numberOfWords = 0 if !defined( $numberOfWords );
    $self->WriteLog( "ReadTrainedVectorDataFromFile - Reading Data Complete" );
    $self->WriteLog( "ReadTrainedVectorDataFromFile - $numberOfWords Word Vectors Stored In Memory" );

    # Used To Print New Line For Progress Percent Indicator
    print( "\n" );

    # Cannot Find Search Word In File
    return -1 if ( defined( $searchWord ) );

    return 0;
}

sub SaveTrainedVectorDataToFile
{
    my ( $self, $savePath, $saveFormat ) = @_;

    # Check(s)
    $self->WriteLog( "SaveTrainedVectorDataToFile - Error: No Save Path Defined" ) if !defined( $savePath );
    return -1 if !defined ( $savePath );

    $saveFormat = 0 if !defined ( $saveFormat );

    # Save Data To File
    my $fileHandle;

    # Save Vector Data In Plain Text Format
    if ( $saveFormat == 0 )
    {
        $self->WriteLog( "SaveTrainedVectorDataToFile - Saving Word2Vec Data To Text File: \"$savePath\"" );

        open( $fileHandle, ">:encoding(utf8)", "$savePath" ) or return -1;
        my $vocabHashRef = $self->GetVocabularyHash();
        my @dataAry = sort( keys %{ $vocabHashRef } );

        if( $self->GetSparseVectorMode() == 1 )
        {
            my $numOfWords = $self->GetNumberOfWords();
            my $vectorSize = $self->GetVectorLength();

            for( my $i = 0; $i < @dataAry; $i++ )
            {
                # Progress Percent Indicator - Print Percentage Of File Loaded
                print( int( ( $i / $numOfWords ) * 100 ) . "%" ) if ( $numOfWords > 0 );

                my $wordVectorData = $dataAry[$i] . " " . $vocabHashRef->{ $dataAry[$i] };

                # Check(s)
                $self->WriteLog( "SaveTrainedVectorDataToFile - Warning: Word Vector Contains No Data / Empty String - Line: $i" ) if ( $wordVectorData eq "" );
                next if ( $wordVectorData eq "" );

                if( $i == 0 )
                {
                    print( $fileHandle "$wordVectorData\n" )
                }
                else
                {
                    my @data = split( ' ', $wordVectorData );

                    # Get Word
                    my $word = $data[0];

                    # Make Array Of Vector Size With All Zeros
                    my @wordVector = ( "0.000000" ) x $vectorSize if ( $vectorSize != 0 );

                    for( my $j = 1; $j < @data; $j++ )
                    {
                        # If The Index ($i) Is Odd, Then The Element Is An Index
                        my $index = $data[$j] if ( $j % 2 == 1 );

                        # If The Index Is Defined, Then Next Element Is An Index Element
                        my $element = $data[$j+1] if defined( $index );

                        # Assign The Correct Index Element To The Specified Index
                        $wordVector[$index] = $element if defined( $index ) && defined( $element );
                    }

                    # Generate Regular Formatted Word Vector
                    $word = $word . " " . join( ' ', @wordVector );

                    # Print Dictionary/Vocabulary Vector Data To File
                    print( $fileHandle "$word \n" );

                    # Clear Array
                    @data = ();
                    @wordVector = ();
                }

                # Progress Percent Indicator - Return To Beginning Of Line
                print( "\r" ) if ( $numOfWords > 0 );
            }
        }
        else
        {
            # Get Number Of Word Vectors and Vector Array Size
            my $numOfWords = $self->GetNumberOfWords();
            my $vectorSize = $self->GetVectorLength();

            # Print Dictionary/Vocabulary Vector Data To File
            for( my $i = 0; $i < @dataAry; $i++ )
            {
                # Progress Percent Indicator - Print Percentage Of File Loaded
                print( int( ( $i / $numOfWords ) * 100 ) . "%" ) if ( $numOfWords > 0 );

                my $data = $dataAry[$i] . " " . $vocabHashRef->{ $dataAry[$i] };
                print( $fileHandle "$data\n" ) if ( $i == 0 );
                print( $fileHandle "$data \n" ) if ( $i > 0 );

                # Progress Percent Indicator - Return To Beginning Of Line
                print( "\r" ) if ( $numOfWords > 0 );
            }
        }

        close( $fileHandle );
        undef( $fileHandle );

        $self->WriteLog( "SaveTrainedVectorDataToFile - File Saved" );
    }
    # Save Vector Data In Word2Vec Binary Format
    elsif ( $saveFormat == 1 )
    {
        $self->WriteLog( "SaveTrainedVectorDataToFile - Saving Word2Vec Data To Binary File: \"$savePath\"" );

        # Get Vocabulary and Vector Sizes
        my $vocabHashRef = $self->GetVocabularyHash();
        my @dataAry = sort( keys %{ $vocabHashRef } );

        # Check(s)
        $self->WriteLog( "SaveTrainedVectorDataToFile - Error: No Word2Vec Vector Data In Memory / Vocabulary Size == 0" ) if @dataAry == 0;
        return -1 if @dataAry == 0;

        open( $fileHandle, ">:raw", "$savePath" ) or return -1;
        binmode( $fileHandle );                                         # Not necessary as ":raw" implies binmode.

        my $headerStr = $dataAry[0] . " " . $vocabHashRef->{ $dataAry[0] };
        my @headerAry = split( ' ', $headerStr );
        return -1 if ( @headerAry < 2 );

        my $numOfWords = $headerAry[0];
        my $windowSize = $headerAry[1];
        @headerAry = ();
        undef( @headerAry );

        # Print Vocabulary and Windows Sizes To File With Line Feed
        print( $fileHandle "$headerStr\n" );

        # Print Word2Vec Vocabulary and Vector Data To File With Line Feed(s)
        for( my $i = 0; $i < @dataAry; $i++ )
        {
            # Progress Percent Indicator - Print Percentage Of File Loaded
            print( int( ( $i / $numOfWords ) * 100 ) . "%" ) if ( $numOfWords > 0 );

            my $data = $dataAry[$i] . " " . $vocabHashRef->{ $dataAry[$i] };

            # Check(s)
            next if ( $i == 0 );

            # Convert Sparse Vector Data To Dense Vector Format
            if ( $self->GetSparseVectorMode() == 1 )
            {
                my @tempAry = split( ' ', $data );
                my $word = $tempAry[0];
                @tempAry = ();
                @tempAry = @{ $self->ConvertRawSparseTextToVectorDataAry( $data ) };
                $data = "$word " . join( ' ', @tempAry );
                undef( @tempAry );
            }

            my @ary = split( ' ', $data );
            next if @ary < $windowSize;

            # Separate "Word" From "Vector Data"
            my $word = shift( @ary ) . " ";
            my $arySize = @ary;

            # Print Word To File
            print( $fileHandle $word );

            # Print Word Vector Data To File
            for my $value ( @ary )
            {
                print( $fileHandle pack( 'f', $value ) );           # Packs String Data In Decimal Binary Format
            }

            # Add Line Feed To End Of Word + Vector Data
            print( $fileHandle "\n" );

            # Progress Percent Indicator - Return To Beginning Of Line
            print( "\r" ) if ( $numOfWords > 0 );
        }

        close( $fileHandle );
        undef( $fileHandle );

        $self->WriteLog( "SaveTrainedVectorDataToFile - File Saved" );
    }
    # Save Vectors In Sparse Vector Format
    elsif ( $saveFormat == 2 )
    {
        $self->WriteLog( "SaveTrainedVectorDataToFile - Saving Word2Vec Data To Sparse Text File: \"$savePath\"" );

        open( $fileHandle, ">:encoding(utf8)", "$savePath" ) or return -1;
        my $vocabHashRef = $self->GetVocabularyHash();
        my @dataAry = sort( keys( %{ $vocabHashRef } ) );

        if( $self->GetSparseVectorMode() == 1 )
        {
            for my $data ( @dataAry )
            {
                print( $fileHandle $data . " " . $vocabHashRef->{ $data } . "\n" );
            }
        }
        else
        {
            # Get Number Of Word Vectors and Vector Array Size
            my $numOfWords = $self->GetNumberOfWords();
            my $vectorSize = $self->GetVectorLength();

            # Print Dictionary/Vocabulary Vector Data To File
            for( my $i = 0; $i < @dataAry; $i++ )
            {
                # Progress Percent Indicator - Print Percentage Of File Loaded
                print( int( ( $i / $numOfWords ) * 100 ) . "%" ) if ( $numOfWords > 0 );

                my $data = $dataAry[$i] . " " . $vocabHashRef->{ $dataAry[$i] };
                print( $fileHandle "$data\n" ) if ( $i == 0 );

                if( $i > 0 && defined( $data ) )
                {
                    my @wordAry = split( ' ', $data );

                    my $word = $wordAry[0];

                    # Print The Vector Word To The File
                    print( $fileHandle "$word" );

                    # Print Vector Data To File
                    for( my $j = 1; $j < @wordAry; $j++ )
                    {
                        my $index = $j - 1;
                        my $value = $wordAry[$j];
                        print( $fileHandle " $index $value" ) if ( $value != 0 );
                    }

                    print( $fileHandle " \n" );
                }

                # Progress Percent Indicator - Return To Beginning Of Line
                print( "\r" ) if ( $numOfWords > 0 );
            }
        }

        close( $fileHandle );
        undef( $fileHandle );

        $self->WriteLog( "SaveTrainedVectorDataToFile - File Saved" );
    }

    # Used To Print New Line For Progress Percent Indicator
    print( "\n" );

    return 0;
}

sub StringsAreEqual
{
    my ( $self , $strA, $strB ) = @_;

    $strA = lc( $strA );
    $strB = lc( $strB );

    return 0 if length( $strA ) != length( $strB );
    return 0 if index( $strA, $strB ) != 0;

    return 1;
}

sub RemoveWordFromWordVectorString
{
    my ( $self, $dataStr ) = @_;

    # Check(s)
    return undef if !defined( $dataStr );

    # shift @tempAry Also Works As Well
    my @tempAry = split( ' ', $dataStr, 2 );
    $dataStr = $tempAry[1];

    undef( @tempAry );

    return $dataStr;
}

sub ConvertRawSparseTextToVectorDataAry
{
    my ( $self, $rawSparseText ) = @_;

    # Check(s)
    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: No Sparse Text Defined" ) if !defined( $rawSparseText );
    return () if !defined( $rawSparseText );

    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: Sparse Text String Empty" ) if ( $rawSparseText eq "" );
    return () if ( $rawSparseText eq "" );

    my $vectorSize = $self->GetVectorLength();

    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: Vector Size == 0" ) if ( $vectorSize == 0 );
    return () if ( $vectorSize == 0 );

    # Begin Data Conversion
    my @data = split( ' ', $rawSparseText );

    # Make Array Of Vector Size With All Zeros
    my @wordVector = ( "0.000000" ) x $vectorSize;

    for( my $i = 0; $i < @data; $i++ )
    {
        # Skip First Element / First Element Contains Word
        next if $i == 0;

        # If The Index ($i) Is Odd, Then The Element Is An Index
        my $index = $data[$i] if ( $i % 2 == 1 );

        # If The Index Is Defined, Then Next Element Is An Index Element
        my $element = $data[$i+1] if defined( $index );

        # Assign The Correct Index Element To The Specified Index
        $wordVector[$index] = $element if defined( $index ) && defined( $element );
    }

    # Clear Data
    undef( @data );
    @data = ();
    $rawSparseText = undef;

    return \@wordVector;
}

sub ConvertRawSparseTextToVectorDataHash
{
    my ( $self, $rawSparseText ) = @_;

    # Check(s)
    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: No Sparse Text Defined" ) if !defined( $rawSparseText );
    return () if !defined( $rawSparseText );

    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: Sparse Text String Empty" ) if ( $rawSparseText eq "" );
    return () if ( $rawSparseText eq "" );

    my $vectorSize = $self->GetVectorLength();

    $self->WriteLog( "ConvertRawSparseTextToVectorDataAry - Error: Vector Size == 0" ) if ( $vectorSize == 0 );
    return () if ( $vectorSize == 0 );

    # Begin Data Conversion
    my @data = split( ' ', $rawSparseText );

    my %wordHash;

    for( my $i = 0; $i < @data; $i++ )
    {
        # Skip First Element / First Element Contains Word
        next if $i == 0;

        # If The Index ($i) Is Odd, Then The Element Is An Index
        my $index = $data[$i] if ( $i % 2 == 1 );

        # If The Index Is Defined, Then Next Element Is An Index Element
        my $element = $data[$i+1] if defined( $index );

        # Assign The Correct Index Element To The Specified Index
        $wordHash{$index} = $element if defined( $index ) && defined( $element );
    }

    # Clear Data
    undef( @data );
    @data = ();
    $rawSparseText = undef;

    return \%wordHash;
}

sub GetOSType
{
    my ( $self ) = @_;
    return $^O;
}


######################################################################################
#    Accessors
######################################################################################

sub GetDebugLog
{
    my ( $self ) = @_;
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    return $self->{ _debugLog };
}

sub GetWriteLog
{
    my ( $self ) = @_;
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    return $self->{ _writeLog };
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = undef if !defined ( $self->{ _fileHandle } );
    return $self->{ _fileHandle };
}

sub GetTrainFilePath
{
    my ( $self ) = @_;
    $self->{ _trainFileName } = "" if !defined ( $self->{ _trainFileName } );
    return $self->{ _trainFileName };
}

sub GetOutputFilePath
{
    my ( $self ) = @_;
    $self->{ _outputFileName } = "" if !defined ( $self->{ _outputFileName } );
    return $self->{ _outputFileName };
}

sub GetWordVecSize
{
    my ( $self ) = @_;
    $self->{ _wordVecSize } = 100 if !defined ( $self->{ _wordVecSize } );
    return $self->{ _wordVecSize };
}

sub GetWindowSize
{
    my ( $self ) = @_;
    $self->{ _windowSize } = 5 if !defined ( $self->{ _windowSize } );
    return $self->{ _windowSize };
}

sub GetSample
{
    my ( $self ) = @_;
    $self->{ _sample } = 0.001 if !defined ( $self->{ _sample } );
    return $self->{ _sample };
}

sub GetHSoftMax
{
    my ( $self ) = @_;
    $self->{ _hSoftMax } = 0 if !defined ( $self->{ _hSoftMax } );
    return $self->{ _hSoftMax };
}

sub GetNegative
{
    my ( $self ) = @_;
    $self->{ _negative } = 5 if !defined ( $self->{ _negative } );
    return $self->{ _negative };
}

sub GetNumOfThreads
{
    my ( $self ) = @_;
    $self->{ _numOfThreads } = 12 if !defined ( $self->{ _numOfThreads } );
    return $self->{ _numOfThreads };
}

sub GetNumOfIterations
{
    my ( $self ) = @_;
    $self->{ _numOfIterations } = 5 if !defined ( $self->{ _numOfIterations } );
    return $self->{ _numOfIterations };
}

sub GetMinCount
{
    my ( $self ) = @_;
    $self->{ _minCount } = 5 if !defined ( $self->{ _minCount } );
    return $self->{ _minCount };
}

sub GetAlpha
{
    my ( $self ) = @_;
    $self->{ _alpha } = 0.05 if ( !defined ( $self->{ _alpha } ) && $self->GetUseCBOW() == 1 );
    $self->{ _alpha } = 0.025 if ( !defined ( $self->{ _alpha } ) && $self->GetUseCBOW() == 0 );
    return $self->{ _alpha };
}

sub GetClasses
{
    my ( $self ) = @_;
    $self->{ _classes } = 0 if !defined ( $self->{ _classes } );
    return $self->{ _classes };
}

sub GetDebugTraining
{
    my ( $self ) = @_;
    $self->{ _debug } = 2 if !defined ( $self->{ _debug } );
    return $self->{ _debug };
}

sub GetBinaryOutput
{
    my ( $self ) = @_;
    $self->{ _binaryOutput } = 1 if !defined ( $self->{ _binaryOutput } );
    return $self->{ _binaryOutput };
}

sub GetSaveVocabFilePath
{
    my ( $self ) = @_;
    $self->{ _saveVocab } = "" if !defined ( $self->{ _saveVocab } );
    return $self->{ _saveVocab };
}

sub GetReadVocabFilePath
{
    my ( $self ) = @_;
    $self->{ _readVocab } = "" if !defined ( $self->{ _readVocab } );
    return $self->{ _readVocab };
}

sub GetUseCBOW
{
    my ( $self ) = @_;
    $self->{ _useCBOW } = 1 if !defined ( $self->{ _useCBOW  } );
    return $self->{ _useCBOW };
}

sub GetWorkingDir
{
    my ( $self ) = @_;
    $self->{ _workingDir } = Cwd::getcwd() if !defined ( $self->{ _workingDir } );
    return $self->{ _workingDir };
}

sub GetWord2VecExeDir
{
    my ( $self ) = @_;
    $self->{ _word2VecExeDir } = "" if !defined( $self->{ _word2VecExeDir } );
    return $self->{ _word2VecExeDir };
}

sub GetVocabularyHash
{
    my ( $self ) = @_;
    $self->{ _hashRefOfWordVectors } = undef if !defined ( $self->{ _hashRefOfWordVectors } );
    return $self->{ _hashRefOfWordVectors };
}

sub GetOverwriteOldFile
{
    my ( $self ) = @_;
    $self->{ _overwriteOldFile } = 0 if !defined ( $self->{ _overwriteOldFile } );
    return $self->{ _overwriteOldFile };
}

sub GetSparseVectorMode
{
    my ( $self ) = @_;
    $self->{ _sparseVectorMode } = 0 if !defined ( $self->{ _sparseVectorMode } );
    return $self->{ _sparseVectorMode };
}

sub GetVectorLength
{
    my ( $self ) = @_;
    $self->{ _vectorLength } = 0 if !defined ( $self->{ _vectorLength } );
    return $self->{ _vectorLength };
}

sub GetNumberOfWords
{
    my ( $self ) = @_;
    $self->{ _numberOfWords } = 0 if !defined ( $self->{ _numberOfWords } );
    return $self->{ _numberOfWords };
}

sub GetMinimizeMemoryUsage
{
    my ( $self ) = @_;
    $self->{ _minimizeMemoryUsage } = 1 if !defined ( $self->{ _minimizeMemoryUsage } );
    return $self->{ _minimizeMemoryUsage };
}


######################################################################################
#    Mutators
######################################################################################

sub SetTrainFilePath
{
    my ( $self, $str ) = @_;
    return $self->{ _trainFileName } = $str;
}

sub SetOutputFilePath
{
    my ( $self, $str ) = @_;
    return $self->{ _outputFileName } = $str;
}

sub SetWordVecSize
{
    my ( $self, $value ) = @_;
    return $self->{ _wordVecSize } = $value;
}

sub SetWindowSize
{
    my ( $self, $value ) = @_;
    return $self->{ _windowSize } = $value;
}

sub SetSample
{
    my ( $self, $value ) = @_;
    return $self->{ _sample } = $value;
}

sub SetHSoftMax
{
    my ( $self, $value ) = @_;
    return $self->{ _hSoftMax } = $value;
}

sub SetNegative
{
    my ( $self, $value ) = @_;
    return $self->{ _negative } = $value;
}

sub SetNumOfThreads
{
    my ( $self, $value ) = @_;
    return $self->{ _numOfThreads } = $value;
}

sub SetNumOfIterations
{
    my ( $self, $value ) = @_;
    return $self->{ _numOfIterations } = $value;
}

sub SetMinCount
{
    my ( $self, $value ) = @_;
    return $self->{ _minCount } = $value;
}

sub SetAlpha
{
    my ( $self, $value ) = @_;
    return $self->{ _alpha } = $value;
}

sub SetClasses
{
    my ( $self, $value ) = @_;
    return $self->{ _classes } = $value;
}

sub SetDebugTraining
{
    my ( $self, $value ) = @_;
    return $self->{ _debug } = $value;
}

sub SetBinaryOutput
{
    my ( $self, $value ) = @_;
    return $self->{ _binaryOutput } = $value;
}

sub SetSaveVocabFilePath
{
    my ( $self, $str ) = @_;
    return $self->{ _saveVocab } = $str;
}

sub SetReadVocabFilePath
{
    my ( $self, $str ) = @_;
    return $self->{ _readVocab } = $str;
}

sub SetUseCBOW
{
    my ( $self, $value ) = @_;
    return $self->{ _useCBOW } = $value;
}

sub SetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->{ _workingDir } = $dir;
}

sub SetWord2VecExeDir
{
    my ( $self, $dir ) = @_;
    return $self->{ _word2VecExeDir } = $dir;
}

sub SetVocabularyHash
{
    my ( $self, $ref ) = @_;
    return if !defined( $ref );
    return $self->{ _hashRefOfWordVectors } = $ref;
}

sub ClearVocabularyHash
{
    my ( $self ) = @_;

    $self->SetNumberOfWords( 0 );
    $self->SetVectorLength( 0 );

    undef( %{ $self->{ _hashRefOfWordVectors } } );

    my %hash;
    return $self->{ _hashRefOfWordVectors } = \%hash;
}

sub AddWordVectorToVocabHash
{
    my ( $self, $wordVectorStr ) = @_;
    return if !defined( $wordVectorStr );
    my @tempAry = split( ' ', $wordVectorStr, 2 );

    # Check(s)
    return if !defined( $self->{ _hashRefOfWordVectors } );
    return if ( @tempAry != 2 );

    $self->{ _hashRefOfWordVectors }->{ $tempAry[0] } = $tempAry[1];
}

sub SetOverwriteOldFile
{
    my ( $self, $temp ) = @_;
    return $self->{ _overwriteOldFile } = $temp;
}

sub SetSparseVectorMode
{
    my ( $self, $temp ) = @_;
    return $self->{ _sparseVectorMode } = $temp;
}

sub SetVectorLength
{
    my ( $self, $temp ) = @_;
    return $self->{ _vectorLength } = $temp;
}

sub SetNumberOfWords
{
    my ( $self, $temp ) = @_;
    return $self->{ _numberOfWords } = $temp;
}

sub SetMinimizeMemoryUsage
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "SetMinimalMemoryUsage - Normal Memory Mode Enabled" ) if ( $temp == 0 );
    $self->WriteLog( "SetMinimalMemoryUsage - Low Memory Mode Enabled" ) if ( $temp == 1 );
    return $self->{ _minimizeMemoryUsage } = $temp;
}


######################################################################################
#    Debug Functions
######################################################################################

sub GetTime
{
    my ( $self ) = @_;
    my( $sec, $min, $hour ) = localtime();

    if( $hour < 10 )
    {
        $hour = "0$hour";
    }

    if( $min < 10 )
    {
        $min = "0$min";
    }

    if( $sec < 10 )
    {
        $sec = "0$sec";
    }

    return "$hour:$min:$sec";
}

sub GetDate
{
    my ( $self ) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    $mon += 1;
    $year += 1900;

    return "$mon/$mday/$year";
}

sub WriteLog
{
    my ( $self ) = shift;
    my $string = shift;
    my $printNewLine = shift;

    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );


    if( $self->GetDebugLog() )
    {
        if( ref ( $self ) ne "Word2vec::Word2vec" )
        {
            print( GetDate() . " " . GetTime() . " - Word2vec: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - Word2vec::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Word2vec" )
        {
            print( GetDate() . " " . GetTime() . " - Word2vec: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - Word2vec::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Word2vec - word2vec wrapper module.

=head1 SYNOPSIS

 # Parameters: Enabled Debug Logging, Disabled Write Logging
 my $w2v = Word2vec::Word2vec->new( 1, 0 );             # Note: Specifiying no parameters implies default settings.

 $w2v->SetTrainFilePath( "textCorpus.txt" );
 $w2v->SetOutputFilePath( "vectors.bin" );
 $w2v->SetWordVecSize( 200 );
 $w2v->SetWindowSize( 8 );
 $w2v->SetSample( 0.0001 );
 $w2v->SetNegative( 25 );
 $w2v->SetHSoftMax( 0 );
 $w2v->SetBinaryOutput( 0 );
 $w2v->SetNumOfThreads( 20 );
 $w2v->SetNumOfIterations( 12 );
 $w2v->SetUseCBOW( 1 );
 $w2v->SetOverwriteOldFile( 0 );

 $w2v->ExecuteTraining();

 undef( $w2v );

 # or

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();             # Note: Specifying no parameters implies default settings.

 $w2v->ExecuteTraining( $trainFilePath, $outputFilePath, $vectorSize, $windowSize, $minCount, $sample, $negative,
                        $alpha, $hs, $binary, $numOfThreads, $iterations, $useCBOW, $classes, $readVocab,
                        $saveVocab, $debug, $overwrite );

 undef( $w2v );

=head1 DESCRIPTION

Word2vec::Word2vec is a word2vec package tool that trains text corpus data using the word2vec tool, provides multiple avenues for cosine
similarity computation, manipulation of word vectors and conversion of word2vec's binary format to human readable text.

=head2 Main Functions

=head3 new

Description:

 Returns a new "Word2vec::Word2vec" module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog                    = 0
    writeLog                    = 0
    trainFileName               = ""
    outputFileName              = ""
    wordVecSize                 = 100
    sample                      = 5
    hSoftMax                    = 0
    negative                    = 5
    numOfThreads                = 12
    numOfIterations             = 5
    minCount                    = 5
    alpha                       = 0.05 (CBOW) or 0.025 (Skip-Gram)
    classes                     = 0
    debug                       = 2
    binaryOutput                = 1
    saveVocab                   = ""
    readVocab                   = ""
    useCBOW                     = 1
    workingDir                  = Current Directory
    hashRefOfWordVectors        = ()
    overwriteOldFile            = 0

Input:

 $debugLog                    -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. (1 = True / 0 = False)
 $trainFileName               -> Specifies the training text corpus file path. (String)
 $outputFileName              -> Specifies the word2vec post training output file path. (String)
 $wordVecSize                 -> Specifies word2vec word vector parameter size.(Integer)
 $sample                      -> Specifies word2vec sample parameter value. (Integer)
 $hSoftMax                    -> Specifies word2vec HSoftMax parameter value. (Integer)
 $negative                    -> Specifies word2vec negative parameter value. (Integer)
 $numOfThreads                -> Specifies word2vec number of threads parameter value. (Integer)
 $numOfIterations             -> Specifies word2vec number of iterations parameter value. (Integer)
 $minCount                    -> Specifies word2vec min-count parameter value. (Integer)
 $alpha                       -> Specifies word2vec alpha parameter value. (Integer)
 $classes                     -> Specifies word2vec classes parameter value. (Integer)
 $debug                       -> Specifies word2vec debug training parameter value. (Integer: '0' = No Debug, '1' = Debug, '2' = Even more debug info)
 $binaryOutput                -> Specifies word2vec binary output mode parameter value. (Integer: '1' = Binary, '0' = Plain Text)
 $saveVocab                   -> Specifies word2vec save vocabulary file path. (String)
 $readVocab                   -> Specifies word2vec read vocabulary file path. (String)
 $useCBOW                     -> Specifies word2vec CBOW algorithm parameter value. (Integer: '1' = CBOW, '0' = Skip-Gram)
 $workingDir                  -> Specifies module working directory. (String)
 $hashRefOfWordVectors        -> Storage location for loaded word2vec trained vector data file in memory. (Hash)
 $overwriteOldFile            -> Instructs the module to either overwrite any existing data with the same output file name and path. ( '1' or '0' )

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested.

Output:

 Word2vec::Word2vec object.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();

 undef( $w2v );

=head3 DESTROY

Description:

  Removes member variables and file handle from memory.

Input:

 None

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->DESTROY();

 undef( $w2v );

=head3 ExecuteTraining

 Executes word2vec training based on parameters. Parameter variables have higher precedence
 than member variables. Any parameter specified will override its respective member variable.

 Note: If no parameters are specified, this module executes word2vec training based on preset
 member variables. Returns string regarding training status.

Input:

 $trainFilePath  -> Specifies word2vec text corpus training file in a given path. (String)
 $outputFilePath -> Specifies word2vec trained output data file name and save path. (String)
 $vectorSize     -> Size of word2vec word vectors. (Integer)
 $windowSize     -> Maximum skip length between words. (Integer)
 $minCount       -> Disregard words that appear less than $minCount times. (Integer)
 $sample         -> Threshold for occurrence of words. Those that appear with higher frequency in the training data will be randomly down-sampled. (Float)
 $negative       -> Number of negative examples. (Integer)
 $alpha          -> Set that start learning rate. (Float)
 $hs             -> Hierarchical Soft-max (Integer)
 $binary         -> Save trained data as binary mode. (Integer)
 $numOfThreads   -> Number of word2vec training threads. (Integer)
 $iterations     -> Number of training iterations to run prior to completion of training. (Integer)
 $useCBOW        -> Enable Continuous Bag Of Words model or Skip-Gram model. (Integer)
 $classes        -> Output word classes rather than word vectors. (Integer)
 $readVocab      -> Read vocabulary from file path without constructing from training data. (String)
 $saveVocab      -> Save vocabulary to file path. (String)
 $debug          -> Set word2vec debug mode. (Integer)
 $overwrite      -> Instructs the module to either overwrite any existing text corpus files or append to the existing file. ( '1' = True / '0' = False )

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested.

Output:

 $value          -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetTrainFilePath( "textcorpus.txt" );
 $w2v->SetOutputFilePath( "vectors.bin" );
 $w2v->SetWordVecSize( 200 );
 $w2v->SetWindowSize( 8 );
 $w2v->SetSample( 0.0001 );
 $w2v->SetNegative( 25 );
 $w2v->SetHSoftMax( 0 );
 $w2v->SetBinaryOutput( 0 );
 $w2v->SetNumOfThreads( 20 );
 $w2v->SetNumOfIterations( 15 );
 $w2v->SetUseCBOW( 1 );
 $w2v->SetOverwriteOldFile( 0 );
 $w2v->ExecuteTraining();

 undef( $w2v );

 # or

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ExecuteTraining( "textcorpus.txt", "vectors.bin", 200, 8, 5, 0.001, 25, 0.05, 0, 0, 20, 15, 1, 0, "", "", 2, 0 );

 undef( $w2v );

=head3 ExecuteStringTraining

 Executes word2vec training based on parameters. Parameter variables have higher precedence
 than member variables. Any parameter specified will override its respective member variable.

 Note: If no parameters are specified, this module executes word2vec training based on preset
 member variables. Returns string regarding training status.

Input:

 $trainingStr    -> String to train with word2vec.
 $outputFilePath -> Specifies word2vec trained output data file name and save path. (String)
 $vectorSize     -> Size of word2vec word vectors. (Integer)
 $windowSize     -> Maximum skip length between words. (Integer)
 $minCount       -> Disregard words that appear less than $minCount times. (Integer)
 $sample         -> Threshold for occurrence of words. Those that appear with higher frequency in the training data will be randomly down-sampled. (Float)
 $negative       -> Number of negative examples. (Integer)
 $alpha          -> Set that start learning rate. (Float)
 $hs             -> Hierarchical Soft-max (Integer)
 $binary         -> Save trained data as binary mode. (Integer)
 $numOfThreads   -> Number of word2vec training threads. (Integer)
 $iterations     -> Number of training iterations to run prior to completion of training. (Integer)
 $useCBOW        -> Enable Continuous Bag Of Words model or Skip-Gram model. (Integer)
 $classes        -> Output word classes rather than word vectors. (Integer)
 $readVocab      -> Read vocabulary from file path without constructing from training data. (String)
 $saveVocab      -> Save vocabulary to file path. (String)
 $debug          -> Set word2vec debug mode. (Integer)
 $overwrite      -> Instructs the module to either overwrite any existing text corpus files or append to the existing file. ( '1' = True / '0' = False )

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested.

Output:

 $value          -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetOutputFilePath( "vectors.bin" );
 $w2v->SetWordVecSize( 200 );
 $w2v->SetWindowSize( 8 );
 $w2v->SetSample( 0.0001 );
 $w2v->SetNegative( 25 );
 $w2v->SetHSoftMax( 0 );
 $w2v->SetBinaryOutput( 0 );
 $w2v->SetNumOfThreads( 20 );
 $w2v->SetNumOfIterations( 15 );
 $w2v->SetUseCBOW( 1 );
 $w2v->SetOverwriteOldFile( 0 );
 $w2v->ExecuteStringTraining( "string to train here" );

 undef( $w2v );

 # or

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ExecuteStringTraining( "string to train here", "vectors.bin", 200, 8, 5, 0.001, 25, 0.05, 0, 0, 20, 15, 1, 0, "", "", 2, 0 );

 undef( $w2v );

=head3 ComputeCosineSimilarity

Description:

 Computes cosine similarity between two words using trained word2vec vector data. Returns
 float value or undefined if one or more words are not in the dictionary.

 Note: Supports single words only and requires vector data to be in memory with ReadTrainedVectorDataFromFile() prior to function execution.

Input:

 $string -> Single string word
 $string -> Single string word

Output:

 $value  -> Float or Undefined

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"of\" and \"the\": " . $w2v->ComputeCosineSimilarity( "of", "the" ) . "\n";

 undef( $w2v );

=head3 ComputeAvgOfWordsCosineSimilarity

Description:

 Computes cosine similarity between two words or compound words using trained word2vec vector data.
 Returns float value or undefined.

 Note: Supports multiple words concatenated by ' ' and requires vector data to be in memory prior
 to method execution. This method will not error out when a word is not located within the dictionary.
 It will take the average of all found words for each parameter then cosine similarity of both word vectors.

Input:

 $string -> string of single or multiple words separated by ' ' (space).
 $string -> string of single or multiple words separated by ' ' (space).

Output:

 $value  -> Float or Undefined

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"heart attack\" and \"acute myocardial infarction\": " .
       $w2v->ComputeAvgOfWordsCosineSimilarity( "heart attack", "acute myocardial infarction" ) . "\n";

 undef( $w2v );

=head3 ComputeMultiWordCosineSimilarity

Description:

 Computes cosine similarity between two words or compound words using trained word2vec vector data.

 Note: Supports multiple words concatenated by ' ' (space) and requires vector data to be in memory prior to method execution.
 If $allWordsMustExist is set to true, this function will error out when a specified word is not found and return undefined.

Input:

 $string            -> string of single or multiple words separated by ' ' (space).
 $string            -> string of single or multiple words separated by ' ' (space).
 $allWordsMustExist -> 1 = True, 0 or undef = False

Output:

 $value             -> Float or Undefined

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"heart attack\" and \"acute myocardial infarction\": " .
       $w2v->ComputeMultiWordCosineSimilarity( "heart attack", "acute myocardial infarction" ) . "\n";

 undef( $w2v );

=head3 ComputeCosineSimilarityOfWordVectors

Description:

 Computes cosine similarity between two word vectors.
 Returns float value or undefined if one or more words are not in the dictionary.

 Note: Function parameters require actual word vector data with words removed.

Input:

 $string -> string of word vector representation data separated by ' ' (space).
 $string -> string of word vector representation data separated by ' ' (space).

Output:

 $value  -> Float or Undefined

Example:

 use Word2vec::Word2vec;

 my $word2vec = Word2vec::Word2vec->new();
 $word2vec->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $vectorAData = $word2vec->GetWordVector( "heart" );
 my $vectorBData = $word2vec->GetWordVector( "attack" );

 # Remove Words From Data
 $vectorAData = RemoveWordFromWordVectorString( $vectorAData );
 $vectorBData = RemoveWordFromWordVectorString( $vectorBData );

 print "Cosine similarity between words: \"heart\" and \"attack\": " .
       $word2vec->ComputeCosineSimilarityOfWordVectors( $vectorAData, $vectorBData ) . "\n";

 undef( $word2vec );

=head3 CosSimWithUserInput

Description:

 Computes cosine similarity between two words using trained word2vec vector data based on user input.

 Note: No compound word support.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 None

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $w2v->CosSimWIthUserInputTest();

 undef( $w2v );

=head3 MultiWordCosSimWithUserInput

Description:

 Computes cosine similarity between two words or compound words using trained word2vec vector data based on user input.

 Note: Supports multiple words concatenated by ':'.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 None

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $w2v->MultiWordCosSimWithUserInput();

 undef( $w2v );


=head3 ComputeAverageOfWords

Description:

 Computes cosine similarity average of all found words given an array reference parameter of
 plain text words. Returns average values (string) or undefined.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 $arrayReference -> Array reference of words

Output:

 $string         -> String of word2vec word average values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );
 my $data = $w2v->ComputeAverageOfWords( "of", "the", "and" );
 print( "Computed Average Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 AddTwoWords

Description:

 Adds two word vectors and returns the result.

 Warning: This method also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to add
 $string -> Word to add

Output:

 $string -> String of word2vec summed word values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );

 my $data = $w2v->AddTwoWords( "heart", "attack" );
 print( "Computed Sum Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 SubtractTwoWords

Description:

 Subtracts two word vectors and returns the result.

 Warning: This method also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to subtract
 $string -> Word to subtract

Output:

 $string -> String of word2vec difference between word values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );

 my $data = $w2v->SubtractTwoWords( "king", "man" );
 print( "Computed Difference Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 AddTwoWordVectors

Description:

 Adds two vector data strings and returns the result.

 Warning: Text word must be removed from vector data prior to calling this method. This method
 also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word2vec word vector data (with string word removed)
 $string -> Word2vec word vector data (with string word removed)

Output:

 $string -> String of word2vec summed word values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );
 my $wordAData = $w2v->GetWordVector( "of" );
 my $wordBData = $w2v->GetWordVector( "the" );

 # Removing Words From Vector Data Array
 $wordAData = RemoveWordFromWordVectorString( $wordAData );
 $wordBData = RemoveWordFromWordVectorString( $wordBData );

 my $data = $w2v->AddTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Sum Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 SubtractTwoWordVectors

Description:

 Subtracts two vector data strings and returns the result.

 Warning: Text word must be removed from vector data prior to calling this method. This method
 also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word2vec word vector data (with string word removed)
 $string -> Word2vec word vector data (with string word removed)

Output:

 $string -> String of word2vec difference between word values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );
 my $wordAData = $w2v->GetWordVector( "of" );
 my $wordBData = $w2v->GetWordVector( "the" );

 # Removing Words From Vector Data Array
 $wordAData = RemoveWordFromWordVectorString( $wordAData );
 $wordBData = RemoveWordFromWordVectorString( $wordBData );

 my $data = $w2v->SubtractTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Difference Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 AverageOfTwoWordVectors

Description:

 Computes the average of two vectors and returns the result.

 Warning: Text word must be removed from vector data prior to calling this method. This method
 also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word2vec word vector data (with string word removed)
 $string -> Word2vec word vector data (with string word removed)

Output:

 $string -> String of word2vec average between word values

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );
 my $wordAData = $w2v->GetWordVector( "of" );
 my $wordBData = $w2v->GetWordVector( "the" );

 # Removing Words From Vector Data Array
 $wordAData = RemoveWordFromWordVectorString( $wordAData );
 $wordBData = RemoveWordFromWordVectorString( $wordBData );

 my $data = $w2v->AverageOfTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Difference Of Words: $data" ) if defined( $data );

 undef( $w2v );

=head3 GetWordVector

Description:

 Searches dictionary in memory for the specified string argument and returns the vector data.
 Returns undefined if not found.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to locate in word2vec vocabulary/dictionary

Output:

 $string -> Found word2vec word + word vector data or undefined.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "sample/samplevectors.bin" );
 my $wordData = $w2v->GetWordVector( "of" );
 print( "Word2vec Word Data: $wordData\n" ) if defined( $wordData );

 undef( $w2v );

=head3 IsVectorDataInMemory

Description:

 Checks to see if vector data has been loaded in memory.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $result = $w2v->IsVectorDataInMemory();

 print( "No vector data in memory\n" ) if $result == 0;
 print( "Yes vector data in memory\n" ) if $result == 1;

 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 print( "No vector data in memory\n" ) if $result == 0;
 print( "Yes vector data in memory\n" ) if $result == 1;

 undef( $w2v );

=head3 IsWordOrCUIVectorData

Description:

 Checks to see if vector data consists of word or CUI terms.

Input:

 None

Output:

 $string -> 'cui', 'word' or undef

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $isWordOrCUIData = $w2v->IsWordOrCUIVectorData();

 print( "Vector Data Consists Of \"$isWordOrCUIData\" Terms\n" ) if defined( $isWordOrCUIData );
 print( "Cannot Determine Type Of Terms\n" ) if !defined( $isWordOrCUIData );

 undef( $w2v );

=head3 IsVectorDataSorted

Description:

 Checks to see if vector data header is signed as sorted in memory.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 my $result = $w2v->IsVectorDataSorted();

 print( "No vector data is not sorted\n" ) if $result == 0;
 print( "Yes vector data is sorted\n" ) if $result == 1;

 undef( $w2v );

=head3 CheckWord2VecDataFileType

Description:

 Checks specified file to see if vector data is in binary or plain text format. Returns 'text'
 for plain text and 'binary' for binary data.

Input:

 $string -> File path

Output:

 $string -> File Type ( "text" = Plain text file / "binary" = Binary data file )

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $fileType = $w2v->CheckWord2VecDataFileType( "samples/samplevectors.bin" );

 print( "FileType: $fileType\n" ) if defined( $fileType );

 undef( $fileType );

=head3 ReadTrainedVectorDataFromFile

Description:

 Reads trained vector data from file path in memory or searches for vector data from file. This function supports and
 automatically detects word2vec binary, plain text and sparse vector data formats.

 Note: If search word is undefined, the entire vector file is loaded in memory. If a search word is defined only the vector data is returned or undef.

Input:

 $string     -> Word2vec trained vector data file path
 $searchWord -> Searches trained vector data file for specific word vector

Output:

 $value      -> '0' = Successful / '-1' = Un-successful

Example:

 # Loading data in memory
 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $result = $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 print( "Success Loading Data\n" ) if $result == 0;
 print( "Un-successful, Data Not Loaded\n" ) if $result == -1;

 undef( $w2v );

 # or

 # Searching vector data file for a specific word vector
 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $result = $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin", "medical" );

 print( "Found Vector Data In File\n" ) if $result != -1;
 print( "Vector Data Not Found\n" )     if $result == -1;

 undef( $w2v );

=head3 SaveTrainedVectorDataToFile

Description:

 Saves trained vector data at the location specified. Defining 'binaryFormat' parameter will
 save in word2vec's binary format.

Input:

 $string       -> Save Path
 $binaryFormat -> Integer ( '1' = Save data in word2vec binary format / '0' = Save as plain text )

 Note: Leaving $binaryFormat as undefined will save the file in plain text format.

 Warning: If the vector data is stored as a binary search tree, this method will error out gracefully.

Output:

 $value        -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();

 # Instruct the module to store the method as an array, not a BST.
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $w2v->SaveTrainedVectorDataToFile( "samples/newvectors.bin" );

 undef( $w2v );

=head3 StringsAreEqual

Description:

 Compares two strings to check for equality, ignoring case-sensitivity.

 Note: This method is not case-sensitive. ie. "string" equals "StRiNg"

Input:

 $string -> String to compare
 $string -> String to compare

Output:

 $value  -> '1' = Strings are equal / '0' = Strings are not equal

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $result = $w2v->StringsAreEqual( "hello world", "HeLlO wOrLd" );

 print( "Strings are equal!\n" )if $result == 1;
 print( "Strings are not equal!\n" ) if $result == 0;

 undef( $w2v );

=head3 RemoveWordFromWordVectorString

Description:

 Given a vector data string as input, it removed the vector word from its data returning only data.

Input:

 $string          -> Vector word & data string.

Output:

 $string          -> Vector data string.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my $vectorData = $w2v->RemoveWordFromWordVectorString( $str );

 print( "Success!\n" ) if length( vectorData ) < length( $str );

 undef( $w2v );

=head3 ConvertRawSparseTextToVectorDataAry

Description:

 Converts sparse vector string to a dense vector format data array.

Input:

 $string          -> Vector data string.

Output:

 $arrayReference  -> Reference to array of vector data.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my @vectorData = @{ $w2v->ConvertRawSparseTextToVectorDataAry( $str ) };

 print( "Data conversion successful!\n" ) if @vectorData > 0;
 print( "Data conversion un-successful!\n" ) if @vectorData == 0;

 undef( $w2v );

=head3 ConvertRawSparseTextToVectorDataHash

Description:

 Converts sparse vector string to a dense vector format data hash.

Input:

 $string          -> Vector data string.

Output:

 $hashReference  -> Reference to array of hash data.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my %vectorData = %{ $w2v->ConvertRawSparseTextToVectorDataHash( $str ) };

 print( "Data conversion successful!\n" ) if ( keys %vectorData ) > 0;
 print( "Data conversion un-successful!\n" ) if ( keys %vectorData ) == 0;

 undef( $w2v );

=head3 GetOSType

Description:

 Returns (string) operating system type.

Input:

 None

Output:

 $string -> Operating System String

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $os = $w2v->GetOSType();

 print( "Operating System: $os\n" );

 undef( $w2v );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Word2vec object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new()
 my $debugLog = $w2v->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;


 undef( $w2v );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Word2vec object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $writeLog = $w2v->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $w2v );

=head3 GetFileHandle

Description:

 Returns the _fileHandle member variable set during Word2vec::Word2vec object instantiation of new function.

 Warning: This is a private function. File handle is used by WriteLog() method. Do not manipulate this file handle as errors can result.

Input:

 None

Output:

 $fileHandle -> Returns file handle for WriteLog() method or undefined.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $fileHandle = $w2v->GetFileHandle();

 undef( $w2v );

=head3 GetTrainFilePath

Description:

 Returns the _trainFilePath member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns word2vec training text corpus file path.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $filePath = $w2v->GetTrainFilePath();
 print( "Training File Path: $filePath\n" );

 undef( $w2v );

=head3 GetOutputFilePath

Description:

 Returns the _outputFilePath member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns post word2vec training output file path.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $filePath = $w2v->GetOutputFilePath();
 print( "File Path: $filePath\n" );

 undef( $w2v );

=head3 GetWordVecSize

Description:

 Returns the _wordVecSize member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) size of word2vec word vectors. Default value = 100

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetWordVecSize();
 print( "Word Vector Size: $value\n" );

 undef( $w2v );

=head3 GetWindowSize

Description:

 Returns the _windowSize member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec window size. Default value = 5

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetWindowSize();
 print( "Window Size: $value\n" );

 undef( $w2v );

=head3 GetSample

Description:

 Returns the _sample member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec sample size. Default value = 0.001

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetSample();
 print( "Sample: $value\n" );

 undef( $w2v );

=head3 GetHSoftMax

Description:

 Returns the _hSoftMax member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec HSoftMax value. Default = 0

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetHSoftMax();
 print( "HSoftMax: $value\n" );

 undef( $w2v );

=head3 GetNegative

Description:

 Returns the _negative member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec negative value. Default = 5

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetNegative();
 print( "Negative: $value\n" );

 undef( $w2v );

=head3 GetNumOfThreads

Description:

 Returns the _numOfThreads member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec number of threads to use during training. Default = 12

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetNumOfThreads();
 print( "Number of threads: $value\n" );

 undef( $w2v );

=head3 GetNumOfIterations

Description:

 Returns the _iterations member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec number of word2vec iterations. Default = 5

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetNumOfIterations();
 print( "Number of iterations: $value\n" );

 undef( $w2v );

=head3 GetMinCount

Description:

 Returns the _minCount member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec min-count value. Default = 5

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetMinCount();
 print( "Min Count: $value\n" );

 undef( $w2v );

=head3 GetAlpha

Description:

 Returns the _alpha member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec alpha value. Default = 0.05 for CBOW and 0.025 for Skip-Gram.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetAlpha();
 print( "Alpha: $value\n" );

 undef( $w2v );

=head3 GetClasses

Description:

 Returns the _classes member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec classes value. Default = 0

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetClasses();
 print( "Classes: $value\n" );

 undef( $w2v );

=head3 GetDebugTraining

Description:

 Returns the _debug member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 0 = No debug output, 1 = Enable debug output, 2 = Even more debug output

Input:

 None

Output:

 $value -> Returns (integer) word2vec debug value. Default = 2

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetDebugTraining();
 print( "Debug: $value\n" );

 undef( $w2v );

=head3 GetBinaryOutput

Description:

 Returns the _binaryOutput member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 1 = Save trained vector data in binary format, 2 = Save trained vector data in plain text format.

Input:

 None

Output:

 $value -> Returns (integer) word2vec binary flag. Default = 0

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetBinaryOutput();
 print( "Binary Output: $value\n" );

 undef( $w2v );

=head3 GetReadVocabFilePath

Description:

 Returns the _readVocab member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns (string) word2vec read vocabulary file name or empty string if not set.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = $w2v->GetReadVocabFilePath();
 print( "Read Vocab File Path: $str\n" );

 undef( $w2v );

=head3 GetSaveVocabFilePath

Description:

 Returns the _saveVocab member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns (string) word2vec save vocabulary file name or empty string if not set.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = $w2v->GetSaveVocabFilePath();
 print( "Save Vocab File Path: $str\n" );

 undef( $w2v );

=head3 GetUseCBOW

Description:

 Returns the _useCBOW member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 0 = Skip-Gram Model, 1 = Continuous Bag Of Words Model.

Input:

 None

Output:

 $value -> Returns (integer) word2vec Continuous-Bag-Of-Words flag. Default = 1

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetUseCBOW();
 print( "Use CBOW?: $value\n" );

 undef( $w2v );

=head3 GetWorkingDir

Description:

 Returns the _workingDir member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (string) working directory path or current directory if not specified.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = $w2v->GetWorkingDir();
 print( "Working Directory: $str\n" );

 undef( $w2v );

=head3 GetWord2VecExeDir

Description:

 Returns the _word2VecExeDir member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (string) word2vec executable directory path or empty string if not specified.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $str = $w2v->GetWord2VecExeDir();
 print( "Word2Vec Executable File Directory: $str\n" );

 undef( $w2v );

=head3 GetVocabularyHash

Description:

 Returns the _hashRefOfWordVectors member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns array of vocabulary/dictionary words. (Word2vec trained data in memory)

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my @vocabulary = $w2v->GetVocabularyHash();

 undef( $w2v );

=head3 GetOverwriteOldFile

Description:

 Returns the _overwriteOldFile member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns 1 = True or 0 = False.

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 my $value = $w2v->GetOverwriteOldFile();
 print( "Overwrite Exiting File?: $value\n" );

 undef( $w2v );

=head2 Mutator Functions

=head3 SetTrainFilePath

Description:

 Sets member variable to string parameter. Sets training file path.

Input:

 $string -> Text corpus training file path

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetTrainFilePath( "samples/textcorpus.txt" );

 undef( $w2v );

=head3 SetOutputFilePath

Description:

 Sets member variable to string parameter. Sets output file path.

Input:

 $string -> Post word2vec training save file path

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetOutputFilePath( "samples/tempvectors.bin" );

 undef( $w2v );

=head3 SetWordVecSize

Description:

 Sets member variable to integer parameter. Sets word2vec word vector size.

Input:

 $value -> Word2vec word vector size

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetWordVecSize( 100 );

 undef( $w2v );

=head3 SetWindowSize

Description:

 Sets member variable to integer parameter. Sets word2vec window size.

Input:

 $value -> Word2vec window size

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetWindowSize( 8 );

 undef( $w2v );

=head3 SetSample

Description:

 Sets member variable to integer parameter. Sets word2vec sample size.

Input:

 $value -> Word2vec sample size

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetSample( 3 );

 undef( $w2v );

=head3 SetHSoftMax

Description:

 Sets member variable to integer parameter. Sets word2vec HSoftMax value.

Input:

 $value -> Word2vec HSoftMax size

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetHSoftMax( 12 );

 undef( $w2v );

=head3 SetNegative

Description:

 Sets member variable to integer parameter. Sets word2vec negative value.

Input:

 $value -> Word2vec negative value

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetNegative( 12 );

 undef( $w2v );

=head3 SetNumOfThreads

Description:

 Sets member variable to integer parameter. Sets word2vec number of training threads to specified value.

Input:

 $value -> Word2vec number of threads value

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetNumOfThreads( 12 );

 undef( $w2v );

=head3 SetNumOfIterations

Description:

 Sets member variable to integer parameter. Sets word2vec iterations value.

Input:

 $value -> Word2vec number of iterations value

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetNumOfIterations( 12 );

 undef( $w2v );

=head3 SetMinCount

Description:

 Sets member variable to integer parameter. Sets word2vec min-count value.

Input:

 $value -> Word2vec min-count value

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetMinCount( 7 );

 undef( $w2v );

=head3 SetAlpha

Description:

 Sets member variable to float parameter. Sets word2vec alpha value.

Input:

 $value -> Word2vec alpha value. (Float)

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetAlpha( 0.0012 );

 undef( $w2v );

=head3 SetClasses

Description:

 Sets member variable to integer parameter. Sets word2vec classes value.

Input:

 $value -> Word2vec classes value.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetClasses( 0 );

 undef( $w2v );

=head3 SetDebugTraining

Description:

 Sets member variable to integer parameter. Sets word2vec debug parameter value.

Input:

 $value -> Word2vec debug training value.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetDebugTraining( 0 );

 undef( $w2v );

=head3 SetBinaryOutput

Description:

 Sets member variable to integer parameter. Sets word2vec binary parameter value.

Input:

 $value -> Word2vec binary output mode value. ( '1' = Binary Output / '0' = Plain Text )

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetBinaryOutput( 1 );

 undef( $w2v );

=head3 SetSaveVocabFilePath

Description:

 Sets member variable to string parameter. Sets word2vec save vocabulary file name.

Input:

 $string -> Word2vec save vocabulary file name and path.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetSaveVocabFilePath( "samples/vocab.txt" );

 undef( $w2v );

=head3 SetReadVocabFilePath

Description:

 Sets member variable to string parameter. Sets word2vec read vocabulary file name.

Input:

 $string -> Word2vec read vocabulary file name and path.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetReadVocabFilePath( "samples/vocab.txt" );

 undef( $w2v );

=head3 SetUseCBOW

Description:

 Sets member variable to integer parameter. Sets word2vec CBOW parameter value.

Input:

 $value -> Word2vec CBOW mode value.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetUseCBOW( 1 );

 undef( $w2v );

=head3 SetWorkingDir

Description:

 Sets member variable to string parameter. Sets working directory.

Input:

 $string -> Working directory

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetWorkingDir( "/samples" );

 undef( $w2v );

=head3 SetWord2VecExeDir

Description:

 Sets member variable to string parameter. Sets word2vec executable file directory.

Input:

 $string -> Word2vec directory

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetWord2VecExeDir( "/word2vec" );

 undef( $w2v );

=head3 SetVocabularyHash

Description:

 Sets vocabulary/dictionary array to de-referenced array reference parameter.

 Warning: This will overwrite any existing vocabulary/dictionary array data.

Input:

 $arrayReference -> Vocabulary/Dictionary array reference of word2vec word vectors.

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my @vocab = $w2v->GetVocabularyHash();
 $w2v->SetVocabularyHash( \@vocab );

 undef( $w2v );

=head3 ClearVocabularyHash

Description:

 Clears vocabulary/dictionary array.

Input:

 None

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->ClearVocabularyHash();

 undef( $w2v );

=head3 AddWordVectorToVocabHash

Description:

 Adds word vector string to vocabulary/dictionary.

Input:

 $string -> Word2vec word vector string

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();

 # Note: This is representational data of word2vec's word vector format and not actual data.
 $w2v->AddWordVectorToVocabHash( "of 0.4346 -0.1235 0.5789 0.2347 -0.0056 -0.0001" );

 undef( $w2v );

=head3 SetOverwriteOldFile

Description:

 Sets member variable to integer parameter. Enables overwriting output file if one already exists.

Input:

 $value -> '1' = Overwrite exiting file / '0' = Graceful termination when file with same name exists

Output:

 None

Example:

 use Word2vec::Word2vec;

 my $w2v = Word2vec::Word2vec->new();
 $w2v->SetOverwriteOldFile( 1 );

 undef( $w2v );

=head2 Debug Functions

=head3 GetTime

Description:

 Returns current time string in "Hour:Minute:Second" format.

Input:

 None

Output:

 $string -> XX:XX:XX ("Hour:Minute:Second")

Example:

 use Word2vec::Word2vec:

 my $w2v = Word2vec::Word2vec->new();
 my $time = $w2v->GetTime();

 print( "Current Time: $time\n" ) if defined( $time );

 undef( $w2v );

=head3 GetDate

Description:

 Returns current month, day and year string in "Month/Day/Year" format.

Input:

 None

Output:

 $string -> XX/XX/XXXX ("Month/Day/Year")

Example:

 use Word2vec::Word2vec:

 my $w2v = Word2vec::Word2vec->new();
 my $date = $w2v->GetDate();

 print( "Current Date: $date\n" ) if defined( $date );

 undef( $w2v );

=head3 WriteLog

Description:

 Prints passed string parameter to the console, log file or both depending on user options.

 Note: printNewLine parameter prints a new line character following the string if the parameter
 is undefined and does not if parameter is 0.

Input:

 $string -> String to print to the console/log file.
 $value  -> 0 = Do not print newline character after string, all else prints new line character including 'undef'.

Output:

 None

Example:

 use Word2vec::Word2vec:

 my $w2v = Word2vec::Word2vec->new();
 $w2v->WriteLog( "Hello World" );

 undef( $w2v );

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
