#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    06/16/2016                                                             #
#    Revised: 06/25/2019                                                             #
#    UMLS Similarity Word2Vec Package Interface Module                               #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Perl "word2vec" package interface for UMLS Similarity              #
#                                                                                    #
######################################################################################


package Word2vec::Interface;

use strict;
use warnings;

# Standard Package(s)
use Cwd;
use File::Type;
use Sys::CpuAffinity;

# Word2Vec Utility Package(s)
use Word2vec::Lesk;
use Word2vec::Spearmans;
use Word2vec::Word2vec;
use Word2vec::Word2phrase;
use Word2vec::Xmltow2v;
use Word2vec::Wsddata;
use Word2vec::Util;

# Checking For "threads" and "threads::shared" Module(s)
my $threads_module_installed        = 0;
my $threads_shared_module_installed = 0;

eval{ require threads; };
if( !( $@ ) ) { $threads_module_installed        = 1; }

eval{ require threads::shared; };
if( !( $@ ) ) { $threads_shared_module_installed = 1; }


use vars qw($VERSION);

$VERSION = '0.039';


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
        _word2vecDir            => shift,               # String (word2vec package program directory)
        _debugLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _writeLog               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _ignoreCompileErrors    => shift,               # Boolean (Binary): 0 = False, 1 = True
        _ignoreFileChecks       => shift,               # Boolean (Binary): 0 = False, 1 = True
        _exitFlag               => shift,               # Boolean (Binary): 0 = False, 1 = True
        _workingDir             => shift,               # String (current working directory)
        _lesk                   => shift,               # "Word2vec::Lesk" module object
        _spearmans              => shift,               # "Word2vec::Spearmans" module object
        _word2vec               => shift,               # "Word2vec::Word2vec" module object
        _word2phrase            => shift,               # "Word2vec::Word2phrase" module object
        _xmltow2v               => shift,               # "Word2vec::Xmltow2v" module object
        _util                   => shift,               # "Word2vec::Util" module object

        # Word Sense Disambiguation Variables
        _instanceAry            => shift,               # Array Of 'Word2vec::Wsddata' Elements
        _senseAry               => shift,               # Array Of 'Word2vec::Wsddata' Elements
        _instanceCount          => shift,               # Integer
        _senseCount             => shift,               # Integer
    };

    # Set Variable Default If Not Defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _ignoreCompileErrors } = 1 if !defined ( $self->{ _ignoreCompileErrors } );
    $self->{ _ignoreFileChecks } = 0 if !defined ( $self->{ _ignoreFileChecks } );
    $self->{ _exitFlag } = 0 if !defined ( $self->{ _exitFlag } );

    @{ $self->{ _instanceAry } } = () if !defined ( $self->{ _instanceAry } );
    @{ $self->{ _instanceAry } } = @{ $self->{ _instanceAry } } if defined ( $self->{ _instanceAry } );

    @{ $self->{ _senseAry } } = () if !defined ( $self->{ _senseAry } );
    @{ $self->{ _senseAry } } = @{ $self->{ _instanceAry } } if defined ( $self->{ _senseAry } );

    $self->{ _instanceCount } = 0 if !defined ( $self->{ _instanceCount } );
    $self->{ _senseCount } = 0 if !defined ( $self->{ _senseCount } );

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:utf8', 'InterfaceLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }
    else
    {
        $self->{ _fileHandle } = undef;
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );
    $self->WriteLog( "New - No Working Directory Specified - Using Current Directory" ) if !defined( $self->{ _workingDir } );
    $self->{ _workingDir } = Cwd::getcwd() if !defined( $self->{ _workingDir } );
    $self->WriteLog( "New - Setting Working Directory To: \"" . $self->{ _workingDir } . "\"" ) if defined( $self->{ _workingDir } );

    if( !defined( $self->{ _word2vecDir } ) )
    {
        $self->WriteLog( "New - No Word2Vec Directory Specified / Searching For Word2Vec Directory" );

        for my $dir ( @INC )
        {
            $self->{ _word2vecDir } = "$dir/External/Word2vec" if ( -e "$dir/External/Word2vec" );                       # Test Directory
            $self->{ _word2vecDir } = "$dir/../External/Word2vec" if ( -e "$dir/../External/Word2vec" );                 # Dev Directory
            $self->{ _word2vecDir } = "$dir/../../External/Word2vec" if ( -e "$dir/../../External/Word2vec" );           # Dev Directory
            $self->{ _word2vecDir } = "$dir/Word2vec/External/Word2vec" if ( -e "$dir/Word2vec/External/Word2vec" );     # Release Directory
        }

        $self->WriteLog( "New - Word2Vec Executable Directory Found" ) if defined( $self->{ _word2vecDir } );
        $self->WriteLog( "New - Setting Word2Vec Executable Directory To: \"" . $self->{ _word2vecDir } . "\"" ) if defined( $self->{ _word2vecDir } );
    }

    # Initialize "Word2vec::Word2vec", "Word2vec::Word2phrase", "Word2vec::Xmltow2v" and "Word2vec::Util" modules
    my $debugLog            = $self->{ _debugLog };
    my $writeLog            = $self->{ _writeLog };
    $self->{ _lesk }        = Word2vec::Lesk->new( $debugLog, $writeLog )                        if !defined ( $self->{ _lesk } );
    $self->{ _spearmans }   = Word2vec::Spearmans->new( $debugLog, $writeLog )                   if !defined ( $self->{ _spearmans } );
    $self->{ _word2vec }    = Word2vec::Word2vec->new( $debugLog, $writeLog )                    if !defined ( $self->{ _word2vec } );
    $self->{ _word2phrase } = Word2vec::Word2phrase->new( $debugLog, $writeLog )                 if !defined ( $self->{ _word2phrase } );
    $self->{ _xmltow2v }    = Word2vec::Xmltow2v->new( $debugLog, $writeLog, 1, 1, 1, 1, 1, 2 )  if !defined ( $self->{ _xmltow2v } );
    $self->{ _util }        = Word2vec::Util->new( $debugLog, $writeLog )                        if !defined ( $self->{ _util } );

    # Set word2vec Directory In Respective Objects
    $self->{ _word2vec }->SetWord2VecExeDir( $self->{ _word2vecDir } );
    $self->{ _word2phrase }->SetWord2PhraseExeDir( $self->{ _word2vecDir } );

    # Run Word2Vec Package Executable/Source File Checks
    my $result = $self->RunFileChecks( $self->{ _word2vecDir } );

    # Set Exit Flag
    $self->WriteLog( "New - Warning: An Error Has Occurred / Exit Flag Set" ) if $result == 0;
    $self->{ _exitFlag } = $result;

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

sub RunFileChecks
{
    my ( $self ) = shift;
    my $dir = shift;
    my $result = 0;

    if ( $self->GetIgnoreFileChecks() == 1 )
    {
        $self->WriteLog( "RunFileChecks - Warning: Ignore File Checks = TRUE / Skipping File Checks" );
        return 1;
    }

    # Check(s)
    $self->WriteLog( "RunFileChecks - Error: Directory Not Defined" ) if !defined( $dir );
    return 0 if !defined( $dir );

    $self->WriteLog( "RunFileChecks - Error: Directory Does Not Exist" ) if !( -e $dir );
    return 0 if !( -e $dir );

    # OS Check - Ignore Compile Errors If Operating System Is Windows
    $self->SetIgnoreCompileErrors( 1 ) if ( $self->GetOSType() eq "MSWin32" );

    $self->WriteLog( "RunFileChecks - Running Module Check(s)" );
    $self->WriteLog( "RunFileChecks - Word2Vec Dir: $dir" );
    $self->WriteLog( "RunFileChecks - Word2Vec Directory Exists? Y" )         if  ( -e "$dir" );
    $self->WriteLog( "RunFileChecks - Error - Word2Vec Directory Exists? N" ) if !( -e "$dir" );
    return 0 if !( -e "$dir" );

    # List of executable files to check for
    my @fileNameVtr = qw( compute-accuracy distance word2phrase word2vec word-analogy );

    for my $fileName ( @fileNameVtr )
    {
        # Run file checks
        if( $self->_CheckIfExecutableFileExists( $dir, $fileName ) == 0 )
        {
            $result = $self->_CheckIfSourceFileExists( $dir, $fileName );
            $result = $self->_ModifyWord2VecSourceForWindows()               if ( $result == 1 && $self->GetOSType() eq "MSWin32" );
            $result = $self->_CompileSourceFile( $dir, $fileName )           if ( $result == 1 );
            $result = $self->_CheckIfExecutableFileExists( $dir, $fileName ) if ( $result == 1 || $self->GetIgnoreCompileErrors() == 1 );
            $self->_RemoveWord2VecSourceModification()                       if ( $result == 1 && $self->GetOSType() eq "MSWin32" );
        }
        else
        {
            $result = 1;
        }

        $self->WriteLog( "RunFileChecks - Failed Word2Vec File Checks" ) if $result == 0;

        if( $result == 0 && $self->GetOSType() eq "MSWin32" )
        {
            print( "Error: Unable To Build Word2vec Interface Executable File(s)\n" );
            print( "       Try Re-Running With Administrative Permissions To Build Required Executable Files.\n" );
            print( "       Confirm File Checks Pass via \"Word2vec-Interface --test\" Command\n" );
        }
        elsif( $result == 0 && $self->GetOSType() ne "MSWin32" )
        {
            print( "Error: Unable To Build Word2vec Interface Executable File(s)\n" );
            print( "       Try Running \"sudo Word2vec-Interface.pl --test\" Command via Terminal To Build Required Executable Files.\n" );
            print( "       Command Will Report If Files Compiled And Checks Passed\n" );
        }

        return 0 if $result == 0;
    }

    $self->WriteLog( "RunFileChecks - Passed Word2Vec File Checks" );
    return $result;
}

sub _CheckIfExecutableFileExists
{
    my ( $self, $dir, $fileName ) = @_;

    # OS Check
    $fileName .= ".exe" if ( $self->GetOSType() eq "MSWin32" );

    my $filePath = $dir . "/" . $fileName;
    my $result = 0;

    $self->WriteLog( "_CheckIfExecutableFileExists - Checking For \"$fileName\" Executable File" );

    # Check if the directory exists
    $result = 1 if ( -e "$dir" );

    # Continue if directory found
    if ( $result == 1 )
    {
        # Check for executable file
        $result = 0 if !( -e "$filePath" );
        $result = 1 if ( -e "$filePath" );

        # Check file type
        my $fileType = "";
        $fileType = $self->GetFileType( $filePath ) if $result == 1;

        $result = 1 if $fileType eq "application/x-executable-file";
        $self->WriteLog( "_CheckIfExecutableFileExists - Executable File Found" ) if $result == 1;
        $self->WriteLog( "_CheckIfExecutableFileExists - Warning: Executable File Not Found" ) if $result == 0;
        return $result;
    }
    else
    {
        $self->WriteLog( "_CheckIfExecutableFileExists - Specified Directory Does Not Exist" );
    }

    return 0;
}

sub _CheckIfSourceFileExists
{
    my ( $self, $dir, $fileName ) = @_;
    my $filePath = $dir . "/" . $fileName . ".c";
    my $result = 0;

    $self->WriteLog( "_CheckIfSourceFileExists - Checking For \"$fileName.c\" Source File" );

    # Check if the file/directory exists
    $result = 1 if ( -e "$filePath" );
    $self->WriteLog( "_CheckIfSourceFileExists - Warning: File Does Not Exist" ) if $result == 0;
    return 0 if $result == 0;

    # Check file type
    my $fileType = $self->GetFileType( $filePath );

    $result = 1 if $fileType eq "text/cpp";

    $self->WriteLog( "_CheckIfSourceFileExists - File Exists" ) if $result == 1;

    return $result;
}

sub _CompileSourceFile
{
    my ( $self, $dir, $fileName ) = @_;
    my $executablePath = $dir . "/" . $fileName;

    # Check if OS is Windows and adjust accordingly
    $executablePath .= ".exe" if ( $self->GetOSType eq "MSWin32" );

    $self->WriteLog( "_CompileSourceFile - Compiling Source File \"$fileName.c\"" );

    my $sourceName = "/" . $fileName . ".c";
    $dir .= $sourceName;

    my $result = 0;

    # Execute External System Command To Compile "word2vec.c" Source File
    # Execute command without capturing program output
    system( "gcc \"$dir\" -o \"$executablePath\" -lm -pthread -O3 -march=native -funroll-loops -Wno-unused-result -Wno-int-to-pointer-cast" ) if $self->GetIgnoreCompileErrors() == 1;
    system( "gcc \"$dir\" -o \"$executablePath\" -lm -pthread -O3 -march=native -Wall -funroll-loops -Wno-unused-result" ) if $self->GetIgnoreCompileErrors() == 0;
    $result = 1 if ( $self->GetOSType() ne "MSWin32" && -e "$executablePath" && $self->GetFileType( $executablePath ) eq "application/x-executable-file" );
    $result = 1 if ( $self->GetOSType() eq "MSWin32" && -e "$executablePath" && $self->GetFileType( $executablePath ) eq "application/x-ms-dos-executable" );

    $self->WriteLog( "_CompileSourceFile - Compile Failed" ) if $result == 0;
    $self->WriteLog( "_CompileSourceFile - Compiled Successfully") if $result == 1;

    return $result;
}

sub GetFileType
{
    my ( $self, $filePath ) = @_;
    my $ft = File::Type->new();
    my $fileType = $ft->checktype_filename( "$filePath" );
    undef( $ft );

    return $fileType;
}

sub GetOSType
{
    my ( $self ) = @_;
    return $^O;
}

sub _ModifyWord2VecSourceForWindows
{
    my ( $self ) = @_;

    my $result = 1;
    my $tempStr = "";
    my $modifiedCode = "#define posix_memalign(p, a, s) (((*(p)) = _aligned_malloc((s), (a))), *(p) ?0 :errno)\n";
    my $workingDir = $self->GetWord2VecDir();

    # Open "word2vec.c" and add $modifiedCode to list of #define statements
    open( my $fileHandle, "<:", "$workingDir/word2vec.c" ) or $result = 0;

    $self->WriteLog( "_ModifyWord2VecSourceForWindows - Error Opening \"word2vec.c\"" ) if $result == 0;
    exit if $result == 0;

    while( my $line = <$fileHandle> )
    {
        $tempStr .= "$line";
        $tempStr .= $modifiedCode if ( index( $line, "#define MAX_CODE_LENGTH " ) != -1 );
    }

    close( $fileHandle );

    # Write overwrite old file with modified file
    open( $fileHandle, ">:", "$workingDir/word2vec.c" ) or die $self->WriteLog( "_ModifyWord2VecSourceForWindows - Error creating or writing file: \"word2vec.c\"" );
    print $fileHandle $tempStr;
    close( $fileHandle );

    $tempStr = "";

    return $result;
}

sub _RemoveWord2VecSourceModification
{
    my ( $self ) = @_;

    my $result = 1;
    my $tempStr = "";
    my $modifiedCode = "#define posix_memalign(p, a, s) (((*(p)) = _aligned_malloc((s), (a))), *(p) ?0 :errno)\n";
    my $workingDir = $self->GetWord2VecDir();

    # Open "word2vec.c" and remove $modifiedCode to list of #define statements
    open( my $fileHandle, "<:", "$workingDir/word2vec.c" ) or $result = 0;

    $self->WriteLog( "_RemoveWord2VecSourceModification - Error Opening \"word2vec.c\"" ) if $result == 0;
    exit if $result == 0;

    while( my $line = <$fileHandle> )
    {
        $tempStr .= "$line" if $line ne $modifiedCode;
    }

    close( $fileHandle );

    # Write overwrite modified file with original file
    open( $fileHandle, ">:", "$workingDir/word2vec.c" ) or die $self->WriteLog( "_RemoveWord2VecSourceModification - Error creating or writing file: \"word2vec.c\"" );
    print $fileHandle $tempStr;
    close( $fileHandle );

    $tempStr = "";

    return $result;
}


######################################################################################
#    Interface Driver Module Functions
######################################################################################

sub CLComputeCosineSimilarity
{
    my ( $self, $vectorBinaryFile, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "CLComputeCosineSimilarity - Vector Data File Not Specified" ) if !defined( $vectorBinaryFile );
    print( "Error: Vector Data File Does Not Exist\n" ) if !( -e "$vectorBinaryFile" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLComputeCosineSimilarity - Vector Data File: \"$vectorBinaryFile\" Does Not Exist" ) if !( -e "$vectorBinaryFile" );
    $self->WriteLog( "CLComputeCosineSimilarity - Two Words Required To Compute Cosine Similarity" ) if !defined( $wordA ) || !defined( $wordB );
    return -1 if !defined( $vectorBinaryFile ) || !( -e "$vectorBinaryFile" ) || !defined( $wordA ) || !defined( $wordB );

    $self->WriteLog( "CLComputeCosineSimilarity - Preparing To Compute Cosine Similarity Of Word Vectors: \"$wordA\" and \"$wordB\"" );

    # Word2Vec Module Object
    my $word2vec = $self->GetWord2VecHandler();

    # Load vector data file (Binary/Text Data)
    my $dataLoaded = $word2vec->ReadTrainedVectorDataFromFile( $vectorBinaryFile );

    $self->WriteLog( "CLComputeCosineSimilarity - Unable To Load Vector Data From File: \"$vectorBinaryFile\"" ) if $dataLoaded == -1;
    return -1 if $dataLoaded == -1;

    my $value = $word2vec->ComputeCosineSimilarity( lc( $wordA ), lc( $wordB ) );

    $self->WriteLog( "CLComputeCosineSimilarity - Computed Cosine Similarity: $value" ) if defined( $value );
    $self->WriteLog( "CLComputeCosineSimilarity - Error Computing Cosine Similarity" ) if !defined( $value );

    # Clear Vector Data From Memory
    $word2vec->ClearVocabularyHash();

    return $value;
}

sub CLComputeMultiWordCosineSimilarity
{
    my ( $self, $vectorBinaryFile, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Vector Data File Not Specified" ) if !defined( $vectorBinaryFile );
    print( "Error: Vector Data File Does Not Exist\n" ) if !( -e "$vectorBinaryFile" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Vector Data File: \"$vectorBinaryFile\" Does Not Exist" ) if !( -e "$vectorBinaryFile" );
    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Two Words Required To Compute Cosine Similarity" ) if !defined( $wordA ) || !defined( $wordB );
    return -1 if !defined( $vectorBinaryFile ) || !( -e "$vectorBinaryFile" ) || !defined( $wordA ) || !defined( $wordB );

    # Replace ':' With Space
    $wordA =~ s/:/ /g;
    $wordB =~ s/:/ /g;

    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Preparing To Compute Cosine Similarity Of Word Vectors: \"$wordA\" and \"$wordB\"" );

    # Word2Vec Module Object
    my $word2vec = $self->GetWord2VecHandler();

    # Load vector data file (Binary/Text Data)
    my $dataLoaded = $word2vec->ReadTrainedVectorDataFromFile( $vectorBinaryFile );

    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Unable To Load Vector Data From File: \"$vectorBinaryFile\"" ) if $dataLoaded == -1;
    return -1 if $dataLoaded == -1;

    my $value = $word2vec->ComputeMultiWordCosineSimilarity( lc( $wordA ), lc( $wordB ) );

    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Computed Multi-Word Cosine Similarity: $value" ) if defined( $value );
    $self->WriteLog( "CLComputeMultiWordCosineSimilarity - Error Computing Cosine Similarity" ) if !defined( $value );

    # Clear Vector Data From Memory
    $word2vec->ClearVocabularyHash();

    return $value;
}

sub CLComputeAvgOfWordsCosineSimilarity
{
    my ( $self, $vectorBinaryFile, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Vector Data File Not Specified" ) if !defined( $vectorBinaryFile );
    print( "Error: Vector Data File Does Not Exist\n" ) if !( -e "$vectorBinaryFile" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Vector Data File: \"$vectorBinaryFile\" Does Not Exist" ) if !( -e "$vectorBinaryFile" );
    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Two Words Required To Compute Cosine Similarity" ) if !defined( $wordA ) || !defined( $wordB );
    return -1 if !defined( $vectorBinaryFile ) || !( -e "$vectorBinaryFile" ) || !defined( $wordA ) || !defined( $wordB );

    # Replace ':' With Space
    $wordA =~ s/:/ /g;
    $wordB =~ s/:/ /g;

    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Preparing To Compute Cosine Similarity Of Word Vectors: \"$wordA\" and \"$wordB\"" );

    # Word2Vec Module Object
    my $word2vec = $self->GetWord2VecHandler();

    # Load vector data file (Binary/Text Data)
    my $dataLoaded = $word2vec->ReadTrainedVectorDataFromFile( $vectorBinaryFile );

    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Unable To Load Vector Data From File: \"$vectorBinaryFile\"" ) if $dataLoaded == -1;
    return -1 if $dataLoaded == -1;

    my $value = $word2vec->ComputeAvgOfWordsCosineSimilarity( lc( $wordA ), lc( $wordB ) ) if ( defined( $wordA ) && defined( $wordB ) );

    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Computed Average Cosine Similarity: $value" ) if defined( $value );
    $self->WriteLog( "CLComputeAvgOfWordsCosineSimilarity - Error Computing Cosine Similarity" ) if !defined( $value );

    # Clear Vector Data From Memory
    $word2vec->ClearVocabularyHash();

    return $value;
}

sub CLMultiWordCosSimWithUserInput
{
    my ( $self, $vectorBinaryFile ) = @_;

    # Check(s)
    return -1 if !defined( $vectorBinaryFile );

    my $word2vec = $self->GetWord2VecHandler();
    $word2vec->ReadTrainedVectorDataFromFile( $vectorBinaryFile );

    print "Error Loading \"$vectorBinaryFile\"\n" if $word2vec->IsVectorDataInMemory() == 0;
    $self->WriteLog( "CLMultiWordCosSimWithUserInput - Error Loading \"$vectorBinaryFile\"" ) if $word2vec->IsVectorDataInMemory() == 0;
    return -1 if $word2vec->IsVectorDataInMemory() == 0;

    $word2vec->MultiWordCosSimWithUserInput();

    # Clear Vector Data From Memory
    $word2vec->ClearVocabularyHash();

    return 0;
}

sub CLAddTwoWordVectors
{
    my ( $self, $vectorDataFilePath, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "CLAddTwoWordVectors - Error: Word Vector A Not Defined" ) if !defined( $wordA );
    return undef if !defined( $wordA );

    $self->WriteLog( "CLAddTwoWordVectors - Error: Word Vector B Not Defined" ) if !defined( $wordB );
    return undef if !defined( $wordB );

    $self->WriteLog( "CLAddTwoWordVectors - Preparing To Add Two Word Vectors: \"$wordA\" and \"$wordB\"" );

    $self->GetWord2VecHandler()->ReadTrainedVectorDataFromFile( $vectorDataFilePath );
    $wordA = $self->GetWord2VecHandler()->GetWordVector( $wordA );
    $wordB = $self->GetWord2VecHandler()->GetWordVector( $wordB );

    $self->WriteLog( "CLAddTwoWordVectors - Error: Locating Word In Dictionary" ) if !defined( $wordA );
    $self->WriteLog( "CLAddTwoWordVectors - Error: Locating Word In Dictionary" ) if !defined( $wordB );
    return undef if ( !defined( $wordA ) || !defined( $wordB ) );

    # Clear Vector Data From Memory
    $self->GetWord2VecHandler()->ClearVocabularyHash();

    # Removing Words From Vector Data Array
    my @wordAry = split( ' ', $wordA, 2 );
    my $firstWord = shift( @wordAry );
    $wordA = $wordAry[0];

    @wordAry = split( ' ', $wordB, 2 );
    my $secondWord = shift( @wordAry );
    $wordB = $wordAry[0];

    undef( @wordAry );

    $self->WriteLog( "CLAddTwoWordVectors - Adding Two Word Vectors: \n\n$firstWord: $wordA\n\n$secondWord: $wordB\n" ) if ( defined( $wordA ) && defined( $wordB ) );

    return $self->GetWord2VecHandler()->AddTwoWordVectors( $wordA, $wordB ) if ( defined( $wordA ) && defined( $wordB ) );
    return undef;
}

sub CLSubtractTwoWordVectors
{
    my ( $self, $vectorDataFilePath, $wordA, $wordB ) = @_;

    # Check(s)
    $self->WriteLog( "CLSubtractTwoWordVectors - Error: Word Vector A Not Defined" ) if !defined( $wordA );
    return undef if !defined( $wordA );

    $self->WriteLog( "CLSubtractTwoWordVectors - Error: Word Vector B Not Defined" ) if !defined( $wordB );
    return undef if !defined( $wordB );

    $self->WriteLog( "CLSubtractTwoWordVectors - Preparing To Subtract Two Word Vectors: \"$wordA\" and \"$wordB\"" );

    $self->GetWord2VecHandler()->ReadTrainedVectorDataFromFile( $vectorDataFilePath );
    $wordA = $self->GetWord2VecHandler()->GetWordVector( $wordA );
    $wordB = $self->GetWord2VecHandler()->GetWordVector( $wordB );

    $self->WriteLog( "CLSubtractTwoWordVectors - Error: Locating Word In Dictionary" ) if !defined( $wordA );
    $self->WriteLog( "CLSubtractTwoWordVectors - Error: Locating Word In Dictionary" ) if !defined( $wordB );
    return undef if ( !defined( $wordA ) || !defined( $wordB ) );

    # Clear Vector Data From Memory
    $self->GetWord2VecHandler()->ClearVocabularyHash();

    # Removing Words From Vector Data Array
    my @wordAry = split( ' ', $wordA, 2 );
    my $firstWord = shift( @wordAry );
    $wordA = $wordAry[0];

    @wordAry = split( ' ', $wordB, 2 );
    my $secondWord = shift( @wordAry );
    $wordB = $wordAry[0];

    undef( @wordAry );

    $self->WriteLog( "CLSubtractTwoWordVectors - Subtracting Two Word Vectors: \n\n$firstWord: $wordA\n\n$secondWord: $wordB\n" ) if ( defined( $wordA ) && defined( $wordB ) );

    return $self->GetWord2VecHandler()->SubtractTwoWordVectors( $wordA, $wordB ) if ( defined( $wordA ) && defined( $wordB ) );
    return undef;
}

sub CLStartWord2VecTraining
{
    my ( $self, $optionsHashRef ) = @_;

    my %options = %{ $optionsHashRef };

    # Word2Vec Module Object
    my $word2vec = $self->GetWord2VecHandler();

    # Parse and Set Word2Vec Options
    for my $option ( keys %options )
    {
        $word2vec->SetTrainFilePath( $options{$option} )            if $option eq "-trainfile";
        $word2vec->SetOutputFilePath( $options{$option} )           if $option eq "-outputfile";
        $word2vec->SetWordVecSize( $options{$option} )              if $option eq "-size";
        $word2vec->SetWindowSize( $options{$option} )               if $option eq "-window";
        $word2vec->SetSample( $options{$option} )                   if $option eq "-sample";
        $word2vec->SetNegative( $options{$option} )                 if $option eq "-negative";
        $word2vec->SetHSoftMax( $options{$option} )                 if $option eq "-hs";
        $word2vec->SetBinaryOutput( $options{$option} )             if $option eq "-binary";
        $word2vec->SetNumOfThreads( $options{$option} )             if $option eq "-threads";
        $word2vec->SetNumOfIterations( $options{$option} )          if $option eq "-iter";
        $word2vec->SetMinCount( $options{$option} )                 if $option eq "-min-count";
        $word2vec->SetUseCBOW( $options{$option} )                  if $option eq "-cbow";
        $word2vec->SetClasses( $options{$option} )                  if $option eq "-classes";
        $word2vec->SetReadVocabFilePath( $options{$option} )        if $option eq "-read-vocab";
        $word2vec->SetSaveVocabFilePath( $options{$option} )        if $option eq "-save-vocab";
        $word2vec->SetDebugTraining( $options{$option} )            if $option eq "-debug";
        $word2vec->SetOverwriteOldFile( $options{$option} )         if $option eq "-overwrite";
    }

    # Check(s)
    my $trainFile = $word2vec->GetTrainFilePath();
    my $outputFile = $word2vec->GetOutputFilePath();
    $self->WriteLog( "CLStartWord2VecTraining - Error: No Training File Specified" ) if !defined( $trainFile ) || $trainFile eq "";
    return -1 if !defined( $trainFile ) || $trainFile eq "";
    $self->WriteLog( "CLStartWord2VecTraining - Error: Training File: \"$trainFile\" Does Not Exist" ) if !( -e "$trainFile" );
    return -1 if !( -e "$trainFile" );
    $self->WriteLog( "CLStartWord2VecTraining - Error: Training File Exists But Has No Data / File Size = 0 bytes" ) if ( -z "$trainFile" );
    return -1 if ( -z "$trainFile" );
    $self->WriteLog( "CLStartWord2VecTraining - Error: No Output File/Directory Specified" ) if !defined( $outputFile ) || $outputFile eq "";
    return -1 if !defined( $outputFile ) || $outputFile eq "";
    $self->WriteLog( "CLStartWord2VecTraining - Warning: No Word2Vec Options Specified - Using Default Options" ) if ( keys %options ) == 2;

    $self->WriteLog( "CLStartWord2VecTraining - Starting Word2Vec Training" );
    my $result = $word2vec->ExecuteTraining();
    $self->WriteLog( "CLStartWord2VecTraining - Word2Vec Training Successful" ) if $result == 0;
    $self->WriteLog( "CLStartWord2VecTraining - Word2Vec Training Not Successful" ) if $result != 0;
    $self->WriteLog( "CLStartWord2VecTraining - See \"Word2vecLog.txt\" For Details" ) if $result != 0;
    return $result;
}

sub CLStartWord2PhraseTraining
{
    my ( $self, $optionsHashRef ) = @_;

    my %options = %{ $optionsHashRef };

    # Word2Vec Module Object
    my $word2phrase = $self->GetWord2PhraseHandler();

    # Parse and Set Word2Vec Options
    for my $option ( keys %options )
    {
        $word2phrase->SetTrainFilePath( $options{$option} )         if $option eq "-trainfile";
        $word2phrase->SetOutputFilePath( $options{$option} )        if $option eq "-outputfile";
        $word2phrase->SetMinCount( $options{$option} )              if $option eq "-min-count";
        $word2phrase->SetThreshold( $options{$option} )             if $option eq "-threshold";
        $word2phrase->SetW2PDebug( $options{$option} )              if $option eq "-debug";
        $word2phrase->SetOverwriteOldFile( $options{$option} )      if $option eq "-overwrite";
    }

    # Check(s)
    my $trainFile = $word2phrase->GetTrainFilePath();
    my $outputFile = $word2phrase->GetOutputFilePath();
    $self->WriteLog( "CLStartWord2PhraseTraining - Error: No Training File Specified" ) if !defined( $trainFile ) || $trainFile eq "";
    return -1 if !defined( $trainFile ) || $trainFile eq "";
    $self->WriteLog( "CLStartWord2PhraseTraining - Error: Training File: \"$trainFile\" Does Not Exist" ) if !( -e "$trainFile" );
    return -1 if !( -e "$trainFile" );
    $self->WriteLog( "CLStartWord2PhraseTraining - Error: Training File Exists But Has No Data / File Size = 0 bytes" ) if ( -z "$trainFile" );
    return -1 if ( -z "$trainFile" );
    $self->WriteLog( "CLStartWord2PhraseTraining - Error: No Output File/Directory Specified" ) if !defined( $outputFile ) || $outputFile eq "";
    return -1 if !defined( $outputFile ) || $outputFile eq "";
    $self->WriteLog( "CLStartWord2PhraseTraining - Warning: No Word2Phrase Options Specified - Using Default Options" ) if ( keys %options ) == 2;

    $self->WriteLog( "CLStartWord2PhraseTraining - Starting Word2Phrase Training" );
    my $result = $word2phrase->ExecuteTraining();
    $self->WriteLog( "CLStartWord2PhraseTraining - Word2Phrase Training Successful" ) if $result == 0;
    $self->WriteLog( "CLStartWord2PhraseTraining - Word2Phrase Training Not Successful" ) if $result != 0;
    $self->WriteLog( "CLStartWord2PhraseTraining - See \"Word2phraseLog.txt\" For Details" ) if $result != 0;
    return $result;
}

sub CLCleanText
{
    my ( $self, $optionsHashRef ) = @_;

    my %options = %{ $optionsHashRef };

    # Clean Text Variables
    my $inputFile   = undef;
    my $outputFile  = undef;

    # Parse and Set XMLToW2V Options
    for my $option ( keys %options )
    {
        $inputFile  = $options{$option}      if $option eq "-inputfile";
        $outputFile = $options{$option}      if $option eq "-outputfile";
    }

    undef( $optionsHashRef );
    undef( %options );


    # Check(s)
    print( "Input File Not Defined\n" )                                   if !defined( "$inputFile" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCleanText - Warning: Input File Not Defined" )    if !defined( "$inputFile" );

    print( "Input File Does Not Exist\n" )                                if !( -e "$inputFile" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCleanText - Warning: Input File Does Not Exist" ) if !( -e "$inputFile" );

    return -1                                                             if !defined( "$inputFile" ) || !( -e "$inputFile" );

    print( "Warning: Save Directory Not Defined - Using Working Directory / Saving To \"clean_text.txt\"\n" )                       if !defined( $outputFile ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCleanText - Warning: Save Directory Not Defined - Using Working Directory / Saving To \"clean_text.txt\"" ) if !defined( $outputFile );
    $outputFile = "clean_text.txt"                                                                                                  if !defined( $outputFile );

    # Print Status Messages In The Event Debug Logging Is Disabled
    print "Input File: $inputFile\n"   if $self->GetDebugLog() == 0;
    print "Output File: $outputFile\n" if $self->GetDebugLog() == 0;

    $self->WriteLog( "CLCleanText - Input File: \"$inputFile\"" );
    $self->WriteLog( "CLCleanText - Output File: \"$outputFile\"" );

    my $result = 0;

    $self->WriteLog( "CLCleanText - Opening Read File Handle: \"$inputFile\"" );
    open( my $rfh, "<:encoding(utf8)", "$inputFile" )  or $result = -1;

    # Check(s)
    print "Error: Unable To Open Input File \"$inputFile\"\n"                          if $result == -1;
    $self->WriteLog( "CLCleanText - Error: Unable To Open Input File \"$inputFile\"" ) if $result == -1;
    return -1                                                                          if $result == -1;

    $self->WriteLog( "CLCleanText - Opening Write File Handle: \"$outputFile\"" );
    open( my $wfh, ">:encoding(utf8)", "$outputFile" ) or $result = -1;
    # Check(s)
    print "Error: Unable To Create Output File \"$outputFile\"\n"                          if $result == -1;
    $self->WriteLog( "CLCleanText - Error: Unable To Create Output File \"$outputFile\"" ) if $result == -1;
    return -1                                                                              if $result == -1;

    # Read Input File, Clean String Line And Write To Output File
    $self->WriteLog( "CLCleanText - Reading File And Normalizing Text" );

    while( my $line = <$rfh> )
    {
        my $string = $self->CleanText( $line );
        print $wfh "$string";
    }

    $self->WriteLog( "CLCleanText - Cleaning Up" );

    # Clean up
    close( $rfh );
    close( $wfh );
    undef( $rfh );
    undef( $wfh );
    undef( $inputFile );
    undef( $outputFile );

    $self->WriteLog( "CLCleanText - Complete" );

    return $result;
}

sub CLCompileTextCorpus
{
    my ( $self, $optionsHashRef ) = @_;

    my %options = %{ $optionsHashRef };

    # XMLToW2V Option Variables
    my $workingDir              = undef;
    my $saveDir                 = undef;
    my $startDate               = undef;
    my $endDate                 = undef;
    my $storeTitle              = undef;
    my $storeAbstract           = undef;
    my $quickParse              = undef;
    my $compoundWordFile        = undef;
    my $storeAsSentencePerLine  = undef;
    my $numOfThreads            = undef;
    my $overwriteExistingFile   = undef;

    # Parse and Set XMLToW2V Options
    for my $option ( keys %options )
    {
        $workingDir                 = $options{$option}      if $option eq "-workdir";
        $saveDir                    = $options{$option}      if $option eq "-savedir";
        $startDate                  = $options{$option}      if $option eq "-startdate";
        $endDate                    = $options{$option}      if $option eq "-enddate";
        $storeTitle                 = $options{$option}      if $option eq "-title";
        $storeAbstract              = $options{$option}      if $option eq "-abstract";
        $quickParse                 = $options{$option}      if $option eq "-qparse";
        $compoundWordFile           = $options{$option}      if $option eq "-compwordfile";
        $storeAsSentencePerLine     = $options{$option}      if $option eq "-sentenceperline";
        $numOfThreads               = $options{$option}      if $option eq "-threads";
        $overwriteExistingFile      = $options{$option}      if $option eq "-overwrite";
    }

    undef( $optionsHashRef );
    undef( %options );


    # Check(s)
    $self->WriteLog( "CLCompileTextCorpus - Warning: Working Directory Not Defined - Using Default Directory" ) if !defined( $workingDir );
    $workingDir =$self->GetWorkingDirectory() if !defined( $workingDir );
    print( "Warning: Save Directory Not Defined - Using Working Directory / Saving To \"text.txt\"\n" ) if !defined( $saveDir ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCompileTextCorpus - Warning: Save Directory Not Defined - Using Working Directory / Saving To \"text.txt\"" ) if !defined( $saveDir );
    $saveDir = "text.txt" if !defined( $saveDir );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Start Date Not Defined - Using 00/00/0000 By Default" ) if !defined( $startDate );
    $startDate = "00/00/0000" if !defined( $startDate );
    $self->WriteLog( "CLCompileTextCorpus - Warning: End Date Not Defined - Using 99/99/9999 By Default" ) if !defined( $endDate );
    $endDate = "99/99/9999" if !defined( $endDate );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Store Title Not Defined - Storing All Article Title By Default" ) if !defined( $storeTitle );
    $storeTitle = 1 if !defined( $storeTitle );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Store Abstract Not Defined - Storing All Article Abstracts By Default" ) if !defined( $storeAbstract );
    $storeAbstract = 1 if !defined( $storeAbstract );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Quick Parse Option Not Defined - Enabling Quick Parse By Default" ) if !defined( $quickParse );
    $quickParse = 1 if !defined( $quickParse );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Compound Word File Not Defined - Compoundify Option Disabled" ) if !defined( $compoundWordFile );
    $self->XTWSetCompoundifyText( 0 ) if !defined( $compoundWordFile );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Store As Sentence Per Line Not Defined - Store As Sentence Per Line Disabled" ) if !defined( $storeAsSentencePerLine );
    $storeAsSentencePerLine = 0 if !defined( $storeAsSentencePerLine );
    print "Warning: Number Of Working Threads Not Defined - Using 1 Thread Per CPU Core\n" if !defined( $numOfThreads ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCompileTextCorpus - Warning: Number Of Working Threads Not Defined - Using 1 Thread Per CPU Core By Default / " . Sys::CpuAffinity::getNumCpus() . " Threads" ) if !defined( $numOfThreads ) and ( $threads_module_installed == 1 );
    $numOfThreads = Sys::CpuAffinity::getNumCpus() if !defined( $numOfThreads ) and ( $threads_module_installed == 1 );
    print "Warning: Perl Not Build To Support Threads / Using 1 Thread\n" if ( $threads_module_installed == 0 );
    $numOfThreads = 1                                                     if ( $threads_module_installed == 0 );
    print( "Error: File \"$saveDir\" Exists And Overwrite Existing File Option Not Defined\n" ) if !defined( $overwriteExistingFile ) && ( -e "$saveDir" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCompileTextCorpus - Error: File \"$saveDir\" Exists And Overwrite Existing File Option Not Defined" ) if !defined( $overwriteExistingFile ) && ( -e "$saveDir" );
    return -1 if !defined( $overwriteExistingFile ) && ( -e "$saveDir" );
    $self->WriteLog( "CLCompileTextCorpus - Warning: Overwrite Existing File Option Not Defined - Default = 1 / YES" ) if !defined( $overwriteExistingFile ) && !( -e "$saveDir" );
    $overwriteExistingFile = 1 if !defined( $overwriteExistingFile ) && !( -e "$saveDir" );
    print( "Warning: Existing Save File Found / Appending To File\n" ) if defined( $overwriteExistingFile ) && $overwriteExistingFile == 0 && ( -e "$saveDir" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCompileTextCorpus - Warning: Existing Save File Found / Appending To File" ) if defined( $overwriteExistingFile ) && $overwriteExistingFile == 0 && ( -e "$saveDir" );
    print( "Warning: Existing Save File Found / Overwriting File\n" ) if defined( $overwriteExistingFile ) && $overwriteExistingFile == 1 && ( -e "$saveDir" ) && $self->GetDebugLog() == 0;
    $self->WriteLog( "CLCompileTextCorpus - Warning: Existing Save File Found / Overwriting File" ) if defined( $overwriteExistingFile ) && $overwriteExistingFile == 1 && ( -e "$saveDir" );

    $self->WriteLog( "CLCompileTextCorpus - Warning: Working Directory Is Blank - Using \".\" Directory" ) if ( $workingDir eq "" );
    $workingDir = "." if ( $workingDir eq "" );
    $self->WriteLog( "CLCompileTextCorpus - Error: Working Directory: \"$workingDir\" Does Not Exist" ) if !( -e "$workingDir" );
    return -1 if !( -e "$workingDir" );

    $self->WriteLog( "CLCompileTextCorpus - Error: Compound Word File \"$compoundWordFile\" Does Not Exist - Disabling Compoundify Option" ) if $self->XTWGetCompoundifyText() == 1 && !( -e "$compoundWordFile" );
    $self->XTWSetCompoundifyText( 0 ) if $self->XTWGetCompoundifyText() == 1 && !( -e "$compoundWordFile" );

    $self->WriteLog( "CLCompileTextCorpus - Printing Current Xmltow2v Settings" );
    print "Printing Current Xmltow2v Setting(s)\n" if $self->GetDebugLog() == 0;

    # Print Status Messages In The Event Debug Logging Is Disabled
    print "Working Directory: $workingDir\n" if $self->GetDebugLog() == 0;
    print "Save Directory: $saveDir\n"       if $self->GetDebugLog() == 0;
    print "Start Date: $startDate\n"         if $self->GetDebugLog() == 0;
    print "End Date: $endDate\n"             if $self->GetDebugLog() == 0;
    print "Store Title: $storeTitle - ( 0=Disabled / 1=Enabled )\n"         if $self->GetDebugLog() == 0;
    print "Store Abstract: $storeAbstract - ( 0=Disabled / 1=Enabled )\n"   if $self->GetDebugLog() == 0;
    print "Quick Parse: $quickParse - ( 0=Disabled / 1=Enabled )\n"         if $self->GetDebugLog() == 0;
    print "Store As Sentence Per Line $storeAsSentencePerLine - ( 0=Disabled / 1=Enabled )\n" if $self->GetDebugLog() == 0 && $self->XTWGetStoreAsSentencePerLine() == 1;
    print "Warning: No Compound Word File Specified - Compoundify Option Disabled\n"          if $self->GetDebugLog() == 0 && $self->XTWGetCompoundifyText() == 0;
    print "Compound Word File Specified - Compoundify Option Enabled\n"                       if $self->GetDebugLog() == 0 && $self->XTWGetCompoundifyText() == 1;
    print "Compound Word File: $compoundWordFile\n"                                           if $self->GetDebugLog() == 0 && $self->XTWGetCompoundifyText() == 1;

    $self->WriteLog( "CLCompileTextCorpus - Working Directory: \"$workingDir\"" );
    $self->WriteLog( "CLCompileTextCorpus - Save Directory: \"$saveDir\"" );
    $self->WriteLog( "CLCompileTextCorpus - Start Date: $startDate" );
    $self->WriteLog( "CLCompileTextCorpus - End Date: $endDate" );
    $self->WriteLog( "CLCompileTextCorpus - Store Title: $storeTitle" );
    $self->WriteLog( "CLCompileTextCorpus - Store Abstract: $storeAbstract" );
    $self->WriteLog( "CLCompileTextCorpus - Quick Parse: $quickParse" );
    $self->WriteLog( "CLCompileTextCorpus - Number Of Working Threads: $numOfThreads" );
    $self->WriteLog( "CLCompileTextCorpus - Overwrite Previous File: $overwriteExistingFile" );
    $self->WriteLog( "CLCompileTextCorpus - Compoundifying Using File: \"$compoundWordFile\"" ) if $self->XTWGetCompoundifyText() == 1;
    $self->WriteLog( "CLCompileTextCorpus - Store As Sentence Per Line: $storeAsSentencePerLine" );

    my @beginDateAry = split( '/', $startDate );
    my @endDateAry   = split( '/', $endDate );

    $self->WriteLog( "CLCompileTextCorpus - Error: Start Date Range In Wrong Format - XX/XX/XXXX" ) if @beginDateAry < 3;
    return -1 if @beginDateAry < 3;

    $self->WriteLog( "CLCompileTextCorpus - Error: End Date Range In Wrong Format - XX/XX/XXXX" ) if @endDateAry < 3;
    return -1 if @endDateAry < 3;

    undef( @beginDateAry );
    undef( @endDateAry );

    my $result = 0;

    my $xmlconv = $self->GetXMLToW2VHandler();
    $xmlconv->SetStoreTitle( $storeTitle );
    $xmlconv->SetStoreAbstract( $storeAbstract );
    $xmlconv->SetWorkingDir( "$workingDir" );
    $xmlconv->SetSavePath( "$saveDir" );
    $xmlconv->SetBeginDate( $startDate );
    $xmlconv->SetEndDate( $endDate );
    $xmlconv->SetQuickParse( $quickParse );
    $xmlconv->SetNumOfThreads( $numOfThreads );
    $xmlconv->SetOverwriteExistingFile( $overwriteExistingFile );
    $xmlconv->SetStoreAsSentencePerLine( $storeAsSentencePerLine );

    if( defined( $compoundWordFile ) && ( -e "$compoundWordFile" ) )
    {
        $result = $xmlconv->ReadCompoundWordDataFromFile( "$compoundWordFile", 1 );

        # Check
        $self->WriteLog( "CLCompileTextCorpus - Error Loading Compound Word File" ) if ( $result == -1 );
        return -1 if ( $result == -1 );

        $result = $xmlconv->CreateCompoundWordBST() if ( $result == 0 );

        # Check
        $self->WriteLog( "CLCompileTextCorpus - Error Creating Compound Word Binary Search Tree" ) if ( $result == -1 );
        return -1 if ( $result == -1 );
    }

    $result = $xmlconv->ConvertMedlineXMLToW2V( "$workingDir" );

    # Clean up
    $xmlconv->ClearCompoundWordAry();
    $xmlconv->ClearCompoundWordBST();

    return $result;
}

sub CLConvertWord2VecVectorFileToText
{
    my ( $self, $filePath, $savePath ) = @_;

    # Check(s)
    $self->WriteLog( "CLConvertWord2VecVectorFileToText - Specified File: \"$filePath\" Not Defined" ) if !defined( $filePath );
    return -1 if !defined( $filePath );

    $self->WriteLog( "CLConvertWord2VecVectorFileToText - Specified File: \"$filePath\" Does Not Exist" ) if !( -e $filePath );
    return -1 if !( -e $filePath );

    $self->WriteLog( "CLConvertWord2VecVectorFileToText - No Save File Name Specified - Saving To \"convertedvectors.bin\"" ) if !defined( $savePath );
    $savePath = "convertedvectors.bin" if !defined( $savePath );

    my $w2v = $self->GetWord2VecHandler();
    my $previousSetting = $w2v->GetSparseVectorMode();
    my $result = $w2v->ReadTrainedVectorDataFromFile( $filePath );

    # Check
    $self->WriteLog( "CLConvertWord2VecVectorFileToText - Error Reading Vector Data File" ) if ( $result == -1 );
    return -1 if ( $result == -1 );

    $result = $w2v->SaveTrainedVectorDataToFile( $savePath );

    # Check
    $self->WriteLog( "CLConvertWord2VecVectorFileToText - Error Saving Vector Data To File" ) if ( $result == -1 );

    # Clean up
    $w2v->ClearVocabularyHash();
    $w2v->SetSparseVectorMode( $previousSetting );

    $self->WriteLog( "CLConvertWord2VecVectorFileToText - Finished Conversion" );
    return $result;
}

sub CLConvertWord2VecVectorFileToBinary
{
    my ( $self, $filePath, $savePath ) = @_;

    # Check(s)
    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - Specified File: \"$filePath\" Not Defined" ) if !defined( $filePath );
    return -1 if !defined( $filePath );

    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - Specified File: \"$filePath\" Does Not Exist" ) if !( -e $filePath );
    return -1 if !( -e $filePath );

    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - No Save File Name Specified - Saving To \"convertedvectors.bin\"" ) if !defined( $savePath );
    $savePath = "convertedvectors.bin" if !defined( $savePath );

    my $w2v = $self->GetWord2VecHandler();
    my $previousSetting = $w2v->GetSparseVectorMode();
    my $result = $w2v->ReadTrainedVectorDataFromFile( $filePath );

    # Check
    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - Error Reading Vector Data File" ) if ( $result == -1 );
    return -1 if ( $result == -1 );

    $result = $w2v->SaveTrainedVectorDataToFile( $savePath, 1 );

    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - Error Saving Vector Data To File" ) if ( $result == -1 );

    # Clean up
    $w2v->ClearVocabularyHash();
    $w2v->SetSparseVectorMode( $previousSetting );

    $self->WriteLog( "CLConvertWord2VecVectorFileToBinary - Finished Conversion" );
    return $result;
}

sub CLConvertWord2VecVectorFileToSparse
{
    my ( $self, $filePath, $savePath ) = @_;

    # Check(s)
    $self->WriteLog( "CLConvertVectorsToSparseVectors - Specified File: \"$filePath\" Not Defined" ) if !defined( $filePath );
    return -1 if !defined( $filePath );

    $self->WriteLog( "CLConvertVectorsToSparseVectors - Specified File: \"$filePath\" Does Not Exist" ) if !( -e $filePath );
    return -1 if !( -e $filePath );

    $self->WriteLog( "CLConvertVectorsToSparseVectors - No Save File Name Specified - Saving To \"convertedvectors.bin\"" ) if !defined( $savePath );
    $savePath = "convertedvectors.bin" if !defined( $savePath );

    my $w2v = $self->GetWord2VecHandler();
    my $previousSetting = $w2v->GetSparseVectorMode();
    my $result = $w2v->ReadTrainedVectorDataFromFile( $filePath );

    # Check
    $self->WriteLog( "CLConvertVectorsToSparseVectors - Error Reading Vector Data File" ) if ( $result == -1 );
    return -1 if ( $result == -1 );

    $result = $w2v->SaveTrainedVectorDataToFile( $savePath, 2 );

    $self->WriteLog( "CLConvertVectorsToSparseVectors - Error Saving Vector Data To File" ) if ( $result == -1 );

    # Clean up
    $w2v->ClearVocabularyHash();
    $w2v->SetSparseVectorMode( $previousSetting );

    $self->WriteLog( "CLConvertVectorsToSparseVectors - Finished Conversion" );
    return $result;
}

sub CLCompoundifyTextInFile
{
    my ( $self, $filePath, $savePath, $compoundWordFile ) = @_;

    # Check(s)
    $self->WriteLog( "CLCompoundifyTextInFile - No File Specified" ) if !defined( $filePath );
    return -1 if !defined( $filePath );

    $self->WriteLog( "CLCompoundifyTextInFile - Save File Name Not Specified - Saving File To: \"comptext.txt\"" ) if !defined( $savePath );
    $savePath = "comptext.txt" if !defined( $savePath );

    $self->WriteLog( "CLCompoundifyTextInFile - No Compound Word File Specified" ) if !defined( $compoundWordFile );
    return -1 if !defined( $compoundWordFile );

    $self->WriteLog( "CLCompoundifyTextInFile - Specified File: \"$filePath\" Does Not Exist" ) if !( -e $filePath );
    return -1 if !( -e $filePath );

    $self->WriteLog( "CLCompoundifyTextInFile - Specified File: \"$compoundWordFile\" Does Not Exist" ) if !( -e $compoundWordFile );
    return -1 if !( -e $compoundWordFile );


    $self->WriteLog( "CLCompoundifyTextInFile - Compoundifying File: \"$compoundWordFile\"" );

    my $text = "";

    open( my $fileHandle, "<:encoding(utf8)", "$filePath" ) or die "CLCompoundifyTextInFile - Error: Cannot Open Specified File";

    while( my $line = <$fileHandle> )
    {
        chomp( $line );
        $text .= $line;
    }

    close( $fileHandle );

    my $xmltow2v = $self->GetXMLToW2VHandler();

    $self->WriteLog( "CLCompoundifyTextInFile - Cleaning Text Data" );
    $text = $xmltow2v->RemoveSpecialCharactersFromString( $text );

    my $result = $xmltow2v->ReadCompoundWordDataFromFile( $compoundWordFile, 1 );

    $self->WriteLog( "CLCompoundifyTextInFile - An Error Has Occured While Loading Compound Word File" ) if $result == -1;
    return -1 if $result == -1;

    $xmltow2v->CreateCompoundWordBST();

    $self->WriteLog( "CLCompoundifyTextInFile - An Error Has Occured While Creating Compound Word BST" ) if $result == -1;
    return -1 if $result == -1;

    $text = $xmltow2v->CompoundifyString( $text );

    open( $fileHandle, ">:encoding(utf8)", "$savePath" ) or die "CLCompoundifyTextInFile - Error: Cannot Save File - \"$savePath\"";
    print $fileHandle "$text\n";
    close( $fileHandle );
    undef( $fileHandle );

    # Clean up
    $text = "";
    $xmltow2v->ClearCompoundWordAry();
    $xmltow2v->ClearCompoundWordBST();

    $self->WriteLog( "CLCompoundifyTextInFile - Finished Compoundify" );

    return 0;
}

sub CLSortVectorFile
{
    my ( $self, $optionsHashRef ) = @_;

    my %options = %{ $optionsHashRef };

    # Check(s)
    $self->WriteLog( "CLSortVectorFile - Error: No Arguments Specified" ) if keys( %options ) == 0;
    return -1 if keys( %options ) == 0;

    my $vectorDataFilePath = $options{ "-filepath" };
    my $overwriteOldFile   = $options{ "-overwrite" };
    undef( %options );

    # Check(s)
    $self->WriteLog( "CLSortVectorFile - Error: Vector Data File Path Not Specified" ) if !defined( $vectorDataFilePath );
    return -1 if !defined( $vectorDataFilePath );

    $self->WriteLog( "CLSortVectorFile - Error: Specified Vector Data File Not Found" ) if !( -e $vectorDataFilePath );
    return -1 if !( -e $vectorDataFilePath );

    # Check To See If File Is Already Sorted
    my $fileAlreadySorted = 0;

    open( my $fileHandle, "<:", $vectorDataFilePath );

    # Read Vector File Header
    my $headerLine = <$fileHandle>;

    # Check(s)
    $self->WriteLog( "CLSortVectorFile - Error: Header Not Defined" ) if !defined( $headerLine );
    return -1 if !defined( $headerLine );

    # Fetch Number Of Words And Vector Length From Header
    my @headerAry = split( ' ', $headerLine );

    # Check(s)
    $self->WriteLog( "CLSortVectorFile - Error: Invalid Header" ) if ( @headerAry < 2 );
    return -1 if ( @headerAry < 2 );
    my $numberOfWords = $headerAry[0];
    my $vectorLength = $headerAry[1];

    # Check Header String For Sorted Signature
    $fileAlreadySorted = 1 if ( defined( $headerLine ) && index( $headerLine, "#\$\@RTED#" ) != -1 );
    undef( $headerLine );
    undef( $fileHandle );

    $self->WriteLog( "CLSortVectorFile - Checking To See If File Has Been Previously Sorted?" );
    print( "Warning: Vector Data File Is Already Sorted\n" ) if ( $self->GetDebugLog() == 0 && $fileAlreadySorted == 1 );
    $self->WriteLog( "CLSortVectorFile - Warning: Vector Data File Is Already Sorted / Header Signed As Sorted" ) if ( $fileAlreadySorted == 1 );
    return 1 if ( $fileAlreadySorted == 1 );

    $self->WriteLog( "CLSortVectorFile - File Has Not Been Sorted" );
    $overwriteOldFile = 0 if !defined( $overwriteOldFile );
    $self->WriteLog( "CLSortVectorFile - Warning: Overwrite Old File Option Enabled" ) if ( $overwriteOldFile == 1 );
    $self->WriteLog( "CLSortVectorFile - Saving As New File: sortedvectors.bin" ) if ( $overwriteOldFile == 0 );

    $self->WriteLog( "CLSortVectorFile - Beginning Data Format Detection And Sort Routine" );

    # Check Vector File For Vector Data Format
    my $saveFormat = $self->W2VCheckWord2VecDataFileType( $vectorDataFilePath );
    $self->WriteLog( "CLSortVectorFile - Vector File Data Format Detected As: $saveFormat" );

    # Read Vector Data File In Memory
    $self->WriteLog( "CLSortVectorFile - Reading Vector Data File" );
    my $result = $self->W2VReadTrainedVectorDataFromFile( $vectorDataFilePath, 0 ) if defined( $saveFormat );

    # Modify Array Header To Include Sorted Signature
    $self->WriteLog( "CLSortVectorFile - Signing Header" );
    my $vocabularyHashRef = $self->W2VGetVocabularyHash();
    $vocabularyHashRef->{ $numberOfWords } = "$vectorLength #\$\@RTED#" if defined( $vocabularyHashRef->{ $numberOfWords } );

    # Save Array In Word2vec Object
    $self->W2VSetNumberOfWords( $numberOfWords );
    $self->W2VSetVectorLength( $vectorLength );

    # Set File Name If Overwrite Option Is Disabled
    $vectorDataFilePath = "sortedvectors.bin" if $overwriteOldFile == 0;

    # Set Save Format
    if( defined( $saveFormat ) )
    {
        $saveFormat = 0 if ( $saveFormat eq "text" );
        $saveFormat = 1 if ( $saveFormat eq "binary" );
        $saveFormat = 2 if ( $saveFormat eq "sparsetext" );
    }

    # Save Sorted Vector Data To File
    $self->WriteLog( "CLSortVectorFile - Saving New File As: \"$vectorDataFilePath\"" );
    $result = $self->W2VSaveTrainedVectorDataToFile( $vectorDataFilePath, $saveFormat );

    # Clean Up
    $self->W2VClearVocabularyHash();

    $self->WriteLog( "CLSortVectorFile - Complete" );

    return $result;
}

sub CLFindSimilarTerms
{
    my ( $self, $term, $numberOfSimilarTerms, $numberOfThreads ) = @_;

    # Check(s)
    $self->WriteLog( "CLFindSimilarTerms - Error: Term Not Defined" )     if !defined( $term );
    $self->WriteLog( "CLFindSImilarTerms - Error: Term Is Empty String" ) if defined( $term ) && $term eq "";
    return undef if !defined( $term ) || ( defined( $term  ) && $term eq "" );

    $self->WriteLog( "CLFindSimilarTerms - Warning: Number Of Similar Terms Not Defined / Using Default = 10" ) if !defined( $numberOfSimilarTerms );
    $numberOfSimilarTerms = 10 if !defined( $numberOfSimilarTerms );

    $self->WriteLog( "CLFindSimilarTerms - Warning: Number Of Threads Not Defined / Using Default = # Of CPUs" ) if !defined( $numberOfThreads ) and ( $threads_module_installed == 1 );
    $numberOfThreads  = Sys::CpuAffinity::getNumCpus() if !defined( $numberOfThreads ) and ( $threads_module_installed == 1 );
    $self->WriteLog( "CLFindSimilarTerms - Warning: Perl Not Built To Support Threads / Using Default = 1 Thread" ) if ( $threads_module_installed == 0 );
    $numberOfThreads = 1 if ( $threads_module_installed == 0 );

    $self->WriteLog( "CLFindSimilarTerms - Error: Vocabulary Is Empty / No Vector Data In Memory" ) if $self->W2VIsVectorDataInMemory() == 0;
    return undef if $self->W2VIsVectorDataInMemory() == 0;

    # Get Nearest Similar Neighbors
    my @returnWords  = ();
    my $vocabularyHash = $self->W2VGetVocabularyHash();

    # Check To See If The "$term" Parameters Exists Within The Vocabulary
    my $result = $vocabularyHash->{ $term };

    $self->WriteLog( "CLFindSimilarTerms - Error: \"$term\" Does Not Exist Within The Vocabulary" ) if !defined( $result );
    return undef if !defined( $result );

    my @remainingWords   = keys %{ $vocabularyHash };
    my %similarWords     = ();
    my $threadListLength = scalar @remainingWords / $numberOfThreads;

    my $workerThreadFunction = sub
    {
        my ( $comparisonTerm, $comparisonWords ) = @_;

        my @comparisonWords = @{ $comparisonWords };
        my %resultHash      = ();
        my $tid             = threads->tid() if ( $threads_module_installed == 1 );
        $tid                = 1              if ( $threads_module_installed == 0 );

        $self->WriteLog( "CLFindSimilarTerms - Starting Thread: $tid" );

        for( my $index = 0; $index < scalar @comparisonWords; $index++ )
        {
            my $word = $comparisonWords[$index];

            #print "$tid -> Count: $index\n";

            if( defined( $word ) )
            {
                # Skip Number Of Words and Vector Length Information
                next if ( $word eq $self->W2VGetNumberOfWords() );

                my $value = $self->W2VComputeCosineSimilarity( $comparisonTerm, $word );
                $resultHash{ $value } = $word if defined( $value );
            }
        }

        # Clean Up
        undef( @comparisonWords );
        $comparisonWords = undef;

        $self->WriteLog( "CLFindSimilarTerms - Ending Thread: $tid" );
        return \%resultHash;
    };
    
    # Multi-Threaded Support
    if( $threads_module_installed == 1 )
    {
        for( my $i = 0; $i < $numberOfThreads; $i++ )
        {
            my @comparisonWords = splice( @remainingWords, 0, $threadListLength );
            my $thread = threads->create( $workerThreadFunction, $term, \@comparisonWords );
        }
    
        # Join All Running Threads Prior To Termination
        my @threadAry = threads->list();
    
        $self->WriteLog( "CLFindSimilarTerms - Waiting For Threads To Finish" );
    
        for my $thread ( @threadAry )
        {
            my $resultHashRef = $thread->join() if ( $thread->is_running() || $thread->is_joinable() );
            %similarWords = ( %similarWords, %{ $resultHashRef } );
        }
    }
    # Single Threaded Support
    else
    {
        %similarWords = %{ $workerThreadFunction->( $term, \@remainingWords ) };
    }

    $self->WriteLog( "CLFindSimilarTerms - Sorting Results" );

    my @sortedValues = sort { $b <=> $a } keys( %similarWords );

    # Check
    $numberOfSimilarTerms = scalar @sortedValues if scalar @sortedValues < $numberOfSimilarTerms;

    for( 0..$numberOfSimilarTerms - 1 )
    {
        push( @returnWords, $similarWords{ $sortedValues[ $_ ] } . " : " . $sortedValues[ $_ ] );
    }

    $self->WriteLog( "CLFindSimilarTerms - Finished" );

    return \@returnWords;
}

sub CleanWord2VecDirectory
{
    my ( $self ) = @_;

    # Check(s)
    my $directory = $self->GetWord2VecDir();
    $self->WriteLog( "CleanWord2VecDirectory - Word2Vec Directory: \"$directory\" Does Not Exist" ) if !( -e $directory );
    return -1 if !( -e $directory );

    $self->WriteLog( "CleanWord2VecDirectory - Cleaning Up Word2Vec Directory Files" );

    my $word2vec        = $directory . "/word2vec";
    my $word2phrase     = $directory . "/word2phrase";
    my $wordAnalogy     = $directory . "/word-analogy";
    my $distance        = $directory . "/distance";
    my $computeAccuracy = $directory . "/compute-accuracy";

    $self->WriteLog( "CleanWord2VecDirectory - Removing C Object Files" );

    unlink( "$word2vec.o" )        if ( -e "$word2vec.o" );
    unlink( "$word2phrase.o" )     if ( -e "$word2phrase.o" );
    unlink( "$wordAnalogy.o" )     if ( -e "$wordAnalogy.o" );
    unlink( "$distance.o" )        if ( -e "$distance.o" );
    unlink( "$computeAccuracy.o" ) if ( -e "$computeAccuracy.o" );

    $self->WriteLog( "CleanWord2VecDirectory - Removed C Object Files" );
    $self->WriteLog( "CleanWord2VecDirectory - Removing Word2Vec Executable Files" );

    if( $self->GetOSType() eq "MSWin32" )
    {
        unlink( "$word2vec.exe" )        if ( -e "$word2vec.exe" );
        unlink( "$word2phrase.exe" )     if ( -e "$word2phrase.exe" );
        unlink( "$wordAnalogy.exe" )     if ( -e "$wordAnalogy.exe" );
        unlink( "$distance.exe" )        if ( -e "$distance.exe" );
        unlink( "$computeAccuracy.exe" ) if ( -e "$computeAccuracy.exe" );
    }
    else
    {
        unlink( "$word2vec" )        if ( -e "$word2vec" );
        unlink( "$word2phrase" )     if ( -e "$word2phrase" );
        unlink( "$wordAnalogy" )     if ( -e "$wordAnalogy" );
        unlink( "$distance" )        if ( -e "$distance" );
        unlink( "$computeAccuracy" ) if ( -e "$computeAccuracy" );
    }

    print( "Cleaned Word2Vec Directory\n" ) if ( $self->GetDebugLog() == 0 );

    $self->WriteLog( "CleanWord2VecDirectory - Removed Word2Vec Executable Files" );
    return 0;
}

######################################################################################
#    Similarity Functions
######################################################################################

sub CLSimilarityAvg
{
    my ( $self, $similarityFilePath ) = @_;

    my @dataAry = ();

    $self->WriteLog( "CLSimilarityAvg - Error: Specified File: \"$similarityFilePath\" Does Not Exist" ) if !( -e "$similarityFilePath" );
    return -1 if !( -e "$similarityFilePath" );

    $self->WriteLog( "CLSimilarityAvg - Error: No Vector Data In Memory" ) if $self->W2VIsVectorDataInMemory() == 0;
    return -1 if ( $self->W2VIsVectorDataInMemory() == 0 );

    $self->WriteLog( "CLSimilarityAvg - Reading Similarity File Data: $similarityFilePath" );

    open( my $fileHandle, "<:encoding(UTF-8)", "$similarityFilePath" );

    while( my $line = <$fileHandle> )
    {
        chomp( $line );
        push( @dataAry, $line );
    }

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "CLSimilarityAvg - Finished Reading Similarity File Data" );
    $self->WriteLog( "CLSimilarityAvg - Computing File Data Cosine Similarity" );
    print( "Generating Average Cosine Similarity File\n" ) if ( $self->GetDebugLog() == 0 );

    my @resultAry = ();

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        my @searchWords = split( '<>', $dataAry[$i] );

        my $searchWord1 = $searchWords[@searchWords-2];
        my $searchWord2 = $searchWords[@searchWords-1];

        # Check(s)
        $self->WriteLog( "CLSimilarityAvg - Warning: Comparison Contains Less Than Two Words - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" ) if @searchWords < 2;
        $self->WriteLog( "CLSimilarityAvg - Warning: Line Contains Empty Search Term - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" )
                if ( defined( $searchWord1 ) && $searchWord1 eq "" ) || ( defined( $searchWord2 ) && $searchWord2 eq "" );
        $searchWord1 = undef if @searchWords - 2 < 0;
        $searchWord2 = undef if @searchWords - 1 < 0;
        $searchWord1 = undef if defined( $searchWord1 ) && length( $searchWord1 ) == 0;
        $searchWord2 = undef if defined( $searchWord2 ) && length( $searchWord2 ) == 0;
        my $result = -1 if !defined( $searchWord1 ) or !defined( $searchWord2 );

        $result = $self->W2VComputeAvgOfWordsCosineSimilarity( lc( $searchWord1 ), lc( $searchWord2 ) ) if !defined( $result );
        $result = -1 if !defined( $result );
        push( @resultAry, $result );

        $result = undef;

        if( @searchWords == 3 )
        {
            my $start = @searchWords - 2;
            my $end   = @searchWords - 1;
            @searchWords = @searchWords[$start..$end];
            $dataAry[$i] = join( '<>', @searchWords );
        }
    }

    $self->WriteLog( "CLSimilarityAvg - Finished Computing Results" );
    $self->WriteLog( "CLSimilarityAvg - Saving Results In Similarity Format" );

    $similarityFilePath =~ s/\.sim//g;
    my @tempAry = split( '/', $similarityFilePath );
    $similarityFilePath = Cwd::getcwd() . "/" . $tempAry[-1] . ".avg_results";
    undef( @tempAry );

    open( $fileHandle, ">:encoding(utf8)", $similarityFilePath ) or $self->( "CLSimilarityAvg - Error: Creating/Saving Results File" );

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        print $fileHandle $resultAry[$i] . "<>" . $dataAry[$i] . "\n";
    }

    close( $fileHandle );
    undef( $fileHandle );

    undef( @dataAry );
    undef( @resultAry );

    $self->WriteLog( "CLSimilarityAvg - Finished" );

    return 0;
}

sub CLSimilarityComp
{
    my ( $self, $similarityFilePath, $vectorBinFilePath ) = @_;

    my @dataAry = ();

    $self->WriteLog( "CLSimilarityComp - Error: Specified File: \"$similarityFilePath\" Does Not Exist" ) if !( -e "$similarityFilePath" );
    return -1 if !( -e "$similarityFilePath" );

    $self->WriteLog( "CLSimilarityComp - Error: No Vector Data In Memory" ) if $self->W2VIsVectorDataInMemory() == 0;
    return -1 if ( $self->W2VIsVectorDataInMemory() == 0 );

    $self->WriteLog( "CLSimilarityComp - Reading Similarity File Data: $similarityFilePath" );

    open( my $fileHandle, "<:encoding(UTF-8)", "$similarityFilePath" );

    while( my $line = <$fileHandle> )
    {
        chomp( $line );
        push( @dataAry, $line );
    }

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "CLSimilarityComp - Finished Reading Similarity File Data" );
    $self->WriteLog( "CLSimilarityComp - Computing File Data Cosine Similarity" );
    print( "Generating Compound Cosine Similarity File\n" ) if ( $self->GetDebugLog() == 0 );

    my @resultAry = ();

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        my @searchWords = split( '<>', $dataAry[$i] );

        my $searchWord1 = $searchWords[@searchWords-2];
        my $searchWord2 = $searchWords[@searchWords-1];

        $searchWord1 =~ s/ +/_/g if defined( $searchWord1 );
        $searchWord2 =~ s/ +/_/g if defined( $searchWord2 );

        # Check(s)
        $self->WriteLog( "CLSimilarityComp - Warning: Comparison Contains Less Than Two Words - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" ) if @searchWords < 2;
        $self->WriteLog( "CLSimilarityComp - Warning: Line Contains Empty Search Term - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" )
                if ( defined( $searchWord1 ) && $searchWord1 eq "" ) || ( defined( $searchWord2 ) && $searchWord2 eq "" );
        $searchWord1 = undef if @searchWords - 2 < 0;
        $searchWord2 = undef if @searchWords - 1 < 0;
        $searchWord1 = undef if defined( $searchWord1 ) && length( $searchWord1 ) == 0;
        $searchWord2 = undef if defined( $searchWord2 ) && length( $searchWord2 ) == 0;
        my $result = -1 if !defined( $searchWord1 ) or !defined( $searchWord2 );

        $result = $self->W2VComputeCosineSimilarity( lc( $searchWord1 ), lc( $searchWord2 ) ) if !defined( $result );
        $result = -1 if !defined( $result );
        push( @resultAry, $result );

        $result = undef;

        if( @searchWords == 3 )
        {
            my $start = @searchWords - 2;
            my $end   = @searchWords - 1;
            @searchWords = @searchWords[$start..$end];
            $dataAry[$i] = join( '<>', @searchWords );
        }
    }

    $self->WriteLog( "CLSimilarityComp - Finished Computing Results" );
    $self->WriteLog( "CLSimilarityComp - Saving Results In Similarity Format" );

    $similarityFilePath =~ s/\.sim//g;
    my @tempAry = split( '/', $similarityFilePath );
    $similarityFilePath = Cwd::getcwd() . "/" . $tempAry[-1] . ".comp_results";
    undef( @tempAry );

    open( $fileHandle, ">:encoding(utf8)", $similarityFilePath ) or $self->( "CLSimilarityComp - Error: Creating/Saving Results File" );

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        print $fileHandle $resultAry[$i] . "<>" . $dataAry[$i] . "\n";
    }

    close( $fileHandle );
    undef( $fileHandle );

    undef( @dataAry );
    undef( @resultAry );

    $self->WriteLog( "CLSimilarityComp - Finished" );

    return 0;
}

sub CLSimilaritySum
{
    my ( $self, $similarityFilePath, $vectorBinFilePath ) = @_;

    my @dataAry = ();

    $self->WriteLog( "CLSimilaritySum - Error: Specified File: \"$similarityFilePath\" Does Not Exist" ) if !( -e "$similarityFilePath" );
    return -1 if !( -e "$similarityFilePath" );

    $self->WriteLog( "CLSimilaritySum - Error: No Vector Data In Memory" ) if $self->W2VIsVectorDataInMemory() == 0;
    return -1 if ( $self->W2VIsVectorDataInMemory() == 0 );

    $self->WriteLog( "CLSimilaritySum - Reading Similarity File Data: $similarityFilePath" );

    open( my $fileHandle, "<:encoding(UTF-8)", "$similarityFilePath" );

    while( my $line = <$fileHandle> )
    {
        chomp( $line );
        push( @dataAry, $line );
    }

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "CLSimilaritySum - Finished Reading Similarity File Data" );
    $self->WriteLog( "CLSimilaritySum - Computing File Data Cosine Similarity" );
    print( "Generating Summed Cosine Similarity File\n" ) if ( $self->GetDebugLog() == 0 );

    my @resultAry = ();

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        my @searchWords = split( '<>', $dataAry[$i] );

        my $searchWord1 = $searchWords[@searchWords-2];
        my $searchWord2 = $searchWords[@searchWords-1];

        # Check(s)
        $self->WriteLog( "CLSimilaritySum - Warning: Comparison Contains Less Than Two Words - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" ) if @searchWords < 2;
        $self->WriteLog( "CLSimilaritySum - Warning: Line Contains Empty Search Term - Line Number: ". $i+1 . ", Line String: \"" . $dataAry[$i] . "\"" )
                if ( defined( $searchWord1 ) && $searchWord1 eq "" ) || ( defined( $searchWord2 ) && $searchWord2 eq "" );
        $searchWord1 = undef if @searchWords - 2 < 0;
        $searchWord2 = undef if @searchWords - 1 < 0;
        $searchWord1 = undef if defined( $searchWord1 ) && length( $searchWord1 ) == 0;
        $searchWord2 = undef if defined( $searchWord2 ) && length( $searchWord2 ) == 0;
        my $result = -1 if !defined( $searchWord1 ) or !defined( $searchWord2 );

        $result = $self->W2VComputeMultiWordCosineSimilarity( lc( $searchWord1 ), lc( $searchWord2 ), 1 ) if !defined( $result );
        $result = -1 if !defined( $result );
        push( @resultAry, $result );

        $result = undef;

        if( @searchWords == 3 )
        {
            my $start = @searchWords - 2;
            my $end   = @searchWords - 1;
            @searchWords = @searchWords[$start..$end];
            $dataAry[$i] = join( '<>', @searchWords );
        }
    }

    $self->WriteLog( "CLSimilaritySum - Finished Computing Results" );
    $self->WriteLog( "CLSimilaritySum - Saving Results In Similarity Format" );

    $similarityFilePath =~ s/\.sim//g;
    my @tempAry = split( '/', $similarityFilePath );
    $similarityFilePath = Cwd::getcwd() . "/" . $tempAry[-1] . ".sum_results";
    undef( @tempAry );

    open( $fileHandle, ">:encoding(utf8)", $similarityFilePath ) or $self->( "CLSimilaritySum - Error: Creating/Saving Results File" );

    for( my $i = 0; $i < @dataAry; $i++ )
    {
        print $fileHandle $resultAry[$i] . "<>" . $dataAry[$i] . "\n";
    }

    close( $fileHandle );
    undef( $fileHandle );

    undef( @dataAry );
    undef( @resultAry );

    $self->WriteLog( "CLSimilaritySum - Finished" );

    return 0;
}

######################################################################################
#    Word Sense Disambiguation Functions
######################################################################################

sub CLWordSenseDisambiguation
{
    my ( $self, $instancesFilePath, $sensesFilePath, $vectorBinFilePath, $stopListFilePath, $listOfFilesPath ) = @_;

    my $result = 0;
    my %listOfFiles;

    # Check(s)
    $listOfFilesPath = "" if !defined( $listOfFilesPath );

    if( $listOfFilesPath eq "" )
    {
        # Parse Directory Of Files
        if( defined( $instancesFilePath ) && $self->XTWIsFileOrDirectory( $instancesFilePath ) eq "dir" )
        {
            my $hashRef = $self->_WSDParseDirectory( $instancesFilePath );
            %listOfFiles = %{ $hashRef } if defined( $hashRef );

            # Enable List Parsing
            $listOfFilesPath = "directory";
        }
        # Parse Pair Of Files
        else
        {
            $self->WriteLog( "CLWordSenseDisambiguation - Error: \"Instances\" File Not Specified" )     if !defined( $instancesFilePath )    || length( $instancesFilePath ) == 0;
            $self->WriteLog( "CLWordSenseDisambiguation - Error: \"Senses\" File Not Specified" )        if !defined( $sensesFilePath )       || length( $sensesFilePath )    == 0;
            $self->WriteLog( "CLWordSenseDisambiguation - Error: \"vector binary\" File Not Specified" ) if !defined ( $vectorBinFilePath )   || length( $vectorBinFilePath ) == 0;
            $self->WriteLog( "CLWordSenseDisambiguation - Attn: \"stoplist\" File Not Specified" )       if !defined ( $stopListFilePath )    || length( $stopListFilePath )  == 0;
            $self->WriteLog( "CLWordSenseDisambiguation - \"$instancesFilePath\" Does Not Exist" )       if length( $instancesFilePath ) != 0 && !( -e $instancesFilePath );
            $self->WriteLog( "CLWordSenseDisambiguation - \"$sensesFilePath\" Does Not Exist" )          if length( $sensesFilePath )    != 0 && !( -e $sensesFilePath );
            $self->WriteLog( "CLWordSenseDisambiguation - \"$vectorBinFilePath\" Does Not Exist" )       if length( $vectorBinFilePath ) != 0 && !( -e $vectorBinFilePath );
            $self->WriteLog( "CLWordSenseDisambiguation - \"$stopListFilePath\" Does Not Exist" )        if length( $stopListFilePath )  != 0 && !( -e $stopListFilePath );

            print( "CLWordSenseDisambiguation - Error: No Specified Files To Parse\n" ) if ( $self->GetDebugLog() == 0 )
                  && ( !defined( $instancesFilePath ) || !defined( $sensesFilePath ) || !defined( $vectorBinFilePath ) );

            print( "CLWordSenseDisambiguation - Error: Specified File(s) Do Not Exist\n" ) if ( $self->GetDebugLog() == 0 )
                  && ( !( -e $instancesFilePath ) || !( -e $sensesFilePath ) || !( -e $vectorBinFilePath ) );

            return -1 if ( !defined( $instancesFilePath ) || !defined( $sensesFilePath ) || !defined( $vectorBinFilePath ) );
            return -1 if ( !( -e $instancesFilePath ) || !( -e $sensesFilePath ) || !( -e $vectorBinFilePath ) );
        }
    }
    else
    {
        $self->WriteLog( "CLWordSenseDisambiguation - Parsing List Of Files Option Enabled" );

        my $hashRef = $self->_WSDReadList( $listOfFilesPath );
        %listOfFiles = %{ $hashRef } if defined( $hashRef );
    }

    # Continue if files are defined
    if( $listOfFilesPath eq "" )
    {
        $listOfFiles{ $instancesFilePath } = $sensesFilePath;
        $result = $self->_WSDParseList( \%listOfFiles, $vectorBinFilePath, $stopListFilePath );
    }
    elsif( $listOfFilesPath ne "" )
    {
        $vectorBinFilePath = $listOfFiles{ "-vectors" } if !defined( $vectorBinFilePath ) || length( $vectorBinFilePath ) == 0;
        $stopListFilePath = $listOfFiles{ "-stoplist" } if !defined( $stopListFilePath ) || length( $stopListFilePath ) == 0;
        chomp( $vectorBinFilePath ) if defined( $vectorBinFilePath );
        chomp( $stopListFilePath ) if defined( $stopListFilePath );
        delete( $listOfFiles{ "-vectors" } );
        delete( $listOfFiles{ "-stoplist" } );
        $result = $self->_WSDParseList( \%listOfFiles, $vectorBinFilePath, $stopListFilePath );
        $self->_WSDGenerateAccuracyReport( $self->GetWorkingDirectory() ) if $result != -1 && ( keys %listOfFiles ) > 1;
    }

    $self->WriteLog( "CLWordSenseDisambiguation - Finished" ) if ( $result == 0 );
    $self->WriteLog( "CLWordSenseDisambiguation - Script Finished With Errors" ) if ( $result != 0 && $self->GetWriteLog() == 0 );
    $self->WriteLog( "CLWordSenseDisambiguation - Script Finished With Errors, See Logs For Details" ) if ( $result != 0 && $self-GetWriteLog() == 1 );

    print( "Complete\n" ) if ( $self->GetDebugLog() == 0 && $result == 0 );
    print( "Error Processing File(s)\n" ) if ( $self->GetDebugLog() == 0 && $result != 0 );

    return $result;
}

sub _WSDAnalyzeSenseData
{
    my ( $self ) = @_;

    my $senseStrLength = 0;
    my @instanceAry    = $self->GetInstanceAry();
    my @senseAry       = $self->GetSenseAry();

    # Check(s)
    $self->WriteLog( "_WSDAnalyzeSenseData - Senses Array Empty / Has WSD Sense File Been Loaded Into Memory?" ) if @senseAry == 0;
    return -1 if @senseAry == 0;

    # Find Length Of SenseID For Instances
    for( my $i = 0; $i < @instanceAry; $i++ )
    {
        $senseStrLength = length( $instanceAry[$i]->senseID ) if ( length( $instanceAry[$i]->senseID ) > $senseStrLength );
    }

    # Check If Each Expected SenseID Is The Same Length In Sense Objects, Else Expected SenseID Is Probably Supposed To Be The InstanceID
    # ie. Instance->SenseID = C10030234 and Sense->SenseID = M2. Replace Sense->SenseID with Sense->InstanceID
    for( my $i = 0; $i < @senseAry; $i++ )
    {
        my $sense = $senseAry[$i];

        my $instanceID = $sense->instanceID;
        my $answerID   = $sense->answerInstanceID;
        my $senseID    = $sense->senseID;

        # Adjust SenseID If InstanceID Not Equal To SenseID
        if( length( $senseID ) != $senseStrLength && $instanceID ne $senseID )
        {
            $self->WriteLog( "_WSDAnalyzeSenseData - Warning: SenseID Mis-Match - InstanceID: $instanceID Not Equal SenseID: $senseID" );

            $sense->senseID( $instanceID );
            $senseAry[$i] = $sense;

            $self->WriteLog( "                                  Correcting Data - InstanceID: $instanceID  ---->  SenseID: $instanceID" );
        }
    }
}

sub _WSDReadList
{
    my ( $self, $listOfFilesPath ) = @_;

    # Check(s)
    $self->WriteLog( "_WSDReadList - \"$listOfFilesPath\" Does Not Exist" ) if !( -e "$listOfFilesPath" );
    return undef if !( -e "$listOfFilesPath" );

    my %listOfFiles;

    open( my $fileHandle, "<:encoding(utf8)", "$listOfFilesPath" ) or die "Error: Unable To Open File: $listOfFilesPath";

    while( my $line = <$fileHandle> )
    {
        chomp( $line );

        # Skip Commented And Empty Lines
        if( $line eq "" || index( $line, "#" ) != -1 )
        {
            next;
        }
        else
        {
            my @tempAry = split( ' ', $line );

            # Check
            next if @tempAry < 2;

            $listOfFiles{ $tempAry[0] } = $tempAry[1];
            undef( @tempAry );
        }
    }

    close( $fileHandle );

    return \%listOfFiles;
}

sub _WSDParseDirectory
{
    my ( $self, $directory ) = @_;

    # Check(s)
    $self->WriteLog( "_WSDParseDirectory - Directory Not Defined" ) if !defined( $directory );
    return undef if !defined( $directory );

    $self->WriteLog( "_WSDParseDirectory - Specified Directory Does Not Exist" ) if !( -e $directory );
    return undef if !( -e $directory );

    # Set Working Directory
    $self->SetWorkingDirectory( $directory );

    # Read File Name(s) From Specified Directory
    my $result = 0;
    my %listOfFiles;
    opendir( my $dirHandle, "$directory" ) or $result = -1;
    $self->WriteLog( "_WSDParseDirectory - Error: Can't open $directory: $!" ) if $result == -1;
    return -1 if $result == -1;

    for my $file ( readdir( $dirHandle ) )
    {
        # Only Include ".sval" Files ( Omit ".sval.results" Files )
        if ( index( $file, ".sval" ) != -1 && index( $file, ".sval.results" ) == -1 )
        {
            my @fileName = split( '.', $file );

            my $instanceFile = $file;
            my $senseFile = $file;

            $instanceFile =~ s/senses/instances/g;
            $senseFile =~ s/instances/senses/g;

            $listOfFiles{ $instanceFile } = $senseFile if ( !defined( $listOfFiles{ $instanceFile } ) && -f "$directory/$instanceFile" );
        }
    }

    closedir $dirHandle;
    undef $dirHandle;

    return \%listOfFiles;
}

sub _WSDParseList
{
    my ( $self, $hashRef, $vectorBinFilePath, $stopListFilePath ) = @_;

    # Check(s)
    $self->WriteLog( "_WSDParseList - List Of Files Not Defined" ) if !defined( $hashRef );
    return undef  if !defined( $hashRef );

    my %listOfFiles = %{ $hashRef };

    $self->WriteLog( "_WSDParseList - Error: No Files To Compare Listed" ) if ( keys %listOfFiles ) == 0;
    return -1 if ( keys %listOfFiles ) == 0;

    print( "Generating Stop List Regex\n" ) if ( $self->GetDebugLog() == 0 && defined( $stopListFilePath ) && length( $stopListFilePath ) == 0 );

    print( "Attn: Stop List Not Utilized\n" ) if !defined( $stopListFilePath ) || length( $stopListFilePath ) == 0;
    $self->WriteLog( "_WSDParseList - Attn: \"Stop List\" File Not Specified" ) if !defined( $stopListFilePath ) || length( $stopListFilePath ) == 0;
    print( "Warning: Stop List File Does Not Exist\n" ) if defined( $stopListFilePath ) && !( -e $stopListFilePath );
    $self->WriteLog( "Warning: Stop List File Does Not Exist" ) if defined( $stopListFilePath ) && !( -e $stopListFilePath );

    print( "Generating Stop List Regex\n" ) if defined( $stopListFilePath ) && ( -e $stopListFilePath );
    $self->WriteLog( "_WSDParseList - Generating Stop List Regex" ) if defined( $stopListFilePath ) && ( -e $stopListFilePath );
    my $stopListRegex = $self->_WSDStop( $stopListFilePath ) if defined( $stopListFilePath ) && ( -e $stopListFilePath );

    $self->WriteLog( "_WSDParseList - Generated Stop List Regex: $stopListRegex" ) if defined( $stopListRegex );
    $self->WriteLog( "_WSDParseList - Warning: Stop List Regex Generation Failed - Continuing Without Stop List Regex" ) if !defined( $stopListRegex );

    my $word2vec = $self->GetWord2VecHandler();
    my $readFile = 0;

    if( $word2vec->IsVectorDataInMemory() == 0 )
    {
        print( "Reading Vector File: $vectorBinFilePath\n" ) if ( $self->GetDebugLog() == 0 );
        $self->WriteLog( "_WSDParseList - Reading \"Vector Binary\" File: \"$vectorBinFilePath\"" );
        $readFile = $word2vec->ReadTrainedVectorDataFromFile( $vectorBinFilePath );

        print( "Unable To Read Specified Vector Binary File: \"$vectorBinFilePath\"\n" ) if ( $self->GetDebugLog() == 0 && $readFile == -1 );
        $self->WriteLog( "_WSDParseList - Unable To Read Specified Vector Binary File: \"$vectorBinFilePath\"" ) if $readFile == -1;
        return -1 if $readFile == -1;
    }
    elsif( $word2vec->IsVectorDataInMemory() == 1 && defined( $vectorBinFilePath ) )
    {
        print( "Warning: Clearing Previous Vector Data In Memory\n" ) if ( $self->GetDebugLog() == 0 );
        $self->WriteLog("Warning: Clearing Previous Vector Data In Memory" );
        $word2vec->ClearVocabularyHash();

        print( "Reading Vector File: $vectorBinFilePath\n" ) if ( $self->GetDebugLog() == 0 );
        $self->WriteLog( "_WSDParseList - Reading \"Vector Binary\" File: \"$vectorBinFilePath\"" );
        $readFile = $word2vec->ReadTrainedVectorDataFromFile( $vectorBinFilePath );

        print( "Unable To Read Specified Vector Binary File: \"$vectorBinFilePath\"\n" ) if ( $self->GetDebugLog() == 0 && $readFile == -1 );
        $self->WriteLog( "_WSDParseList - Unable To Read Specified Vector Binary File: \"$vectorBinFilePath\"" ) if $readFile == -1;
        return -1 if $readFile == -1;
    }
    else
    {
        print( "Warning: Vector Data Already Exists In Memory - Using Existing Data\n" ) if ( $self->GetDebugLog() == 0 );
        $self->WriteLog( "Warning: Vector Data Already Exists In Memory - Using Existing Data" );
    }

    print( "Parsing File(s)\n" ) if ( $self->GetDebugLog() == 0 );
    $self->WriteLog( "_WSDParseList - Parsing List Of Files" );

    for my $file ( keys %listOfFiles )
    {
        my $instancesFilePath = $self->GetWorkingDirectory() . "/$file";
        my $sensesFilePath = $self->GetWorkingDirectory() . "/" .$listOfFiles{ $file };

        # Check(s)
        print( "\"$instancesFilePath\" Cannot Be Found\n" ) if !( -e $instancesFilePath ) && $self->GetDebugLog() == 0;
        print( "\"$sensesFilePath\" Cannot Be Found\n" ) if !( -e $sensesFilePath ) && $self->GetDebugLog() == 0;
        $self->WriteLog( "_WSDParseList - Error: \"$instancesFilePath\" Cannot Be Found" ) if !( -e $instancesFilePath );
        $self->WriteLog( "_WSDParseList - Error: \"$sensesFilePath\" Cannot Be Found" ) if !( -e $sensesFilePath );
        $self->WriteLog( "_WSDParseList - Error: \"$instancesFilePath\" Contains No Data" ) if ( -z $instancesFilePath );
        $self->WriteLog( "_WSDParseList - Error: \"$sensesFilePath\" Contains No Data" ) if ( -z $sensesFilePath );
        next if !( -e $instancesFilePath ) || !( -e $sensesFilePath ) || ( -z $instancesFilePath ) || ( -z $sensesFilePath );

        # Parse "Instances" From File
        my $aryRef = $self->WSDParseFile( $instancesFilePath, $stopListRegex );
        $self->SetInstanceAry( $aryRef ) if defined( $aryRef );
        $self->SetInstanceCount( @{ $aryRef } );
        $self->WriteLog( "_WSDParseList - Parsed And Stored ". @{ $aryRef } . " Instances From File." );

        # Parse "Senses" From File
        $aryRef = $self->WSDParseFile( $sensesFilePath, $stopListRegex );
        $self->SetSenseAry( $aryRef ) if defined( $aryRef );
        $self->SetSenseCount( @{ $aryRef } );
        $self->WriteLog( "_WSDParseList - Parsed And Stored " . @{ $aryRef } . " Senses From File." );

        # Analyze Sense Array For SenseID Mis-Match
        $self->_WSDAnalyzeSenseData();

        # Calculate Cosine Similarity For All Data Entries
        my $success = $self->WSDCalculateCosineAvgSimilarity();

        $self->WriteLog( "_WSDParseList - Error Calculating Cosine Average Similarity / Skipping File" ) if ( $success == -1 );
        next if ( $success == -1 );

        # Save Results
        $self->WSDSaveResults( $instancesFilePath ) if ( $success == 0 );
        $self->WriteLog( "_WSDParseList - Results Saved To File \"$instancesFilePath.results\"" ) if ( $success == 0 );

        # Clear Old Data
        $instancesFilePath = "";
        $sensesFilePath = "";
        $self->SetInstanceCount( 0 );
        $self->SetSenseCount( 0 );
        $self->ClearInstanceAry();
        $self->ClearSenseAry();

    }

    $word2vec->ClearVocabularyHash();
    undef( $word2vec );

    return 0;
}

sub WSDParseFile
{
    my ( $self, $filePath, $stopListRegex ) = @_;

    # Check(s)
    return undef if !defined( $filePath );

    # Begin file parsing
    print( "Parsing File: $filePath\n" ) if ( $self->GetDebugLog() == 0 );
    $self->WriteLog( "WSDParseFile - Parsing: $filePath" );

    open( my $fileHandle, "<:encoding(utf8)", $filePath ) or die "Error: Unable To Read File: $filePath";

    my $line = <$fileHandle>;
    return undef if ( index( $line, "<corpus lang=\"" ) == -1 );

    $line = <$fileHandle>;
    return undef if ( index( $line, "lexelt item=\"" ) == -1 );

    my @dataAry = ();

    while( $line = <$fileHandle> )
    {
        chomp( $line );
        #print "$line\n";   # REMOVE ME

        if( index( $line, "<instance id=\"" ) != -1 )
        {
            my $dataEntry = new WSDData();

            $line =~ s/<instance id=\"//g;
            $line =~ s/\">//g;

            $dataEntry->instanceID( $line );
            #print "InstanceID: $line\n";   # REMOVE ME

            # Fetch next line for answer instance and sense id
            $line = <$fileHandle>;
            chomp( $line );

            if( index( $line, "<answer instance=\"") != -1 )
            {
                # Set answer instance id
                $line =~ s/<answer instance=\"//g;
                my $startIndex = 0;
                my $endIndex = index( $line, "\"" );
                $dataEntry->answerInstanceID( substr( $line, $startIndex, $endIndex ) );
                #print "Answer Instance ID: " . substr( $line, $startIndex, $endIndex ) . "\n";  # REMOVE ME

                # Set sense id
                if( index( $line, "senseid=\"" ) != -1 )
                {
                    $startIndex = $endIndex + 1;
                    $endIndex = length( $line );
                    $line = substr( $line, $startIndex, $endIndex );
                    $line =~ s/ +//g;
                    $line =~ s/senseid=\"//g;
                    $line =~ s/\"\/>//g;
                    $dataEntry->senseID( $line );
                    #print "SenseID: $line\n";   # REMOVE ME
                }
            }

            # Fetch next line for context
            $line = <$fileHandle>;
            chomp( $line );

            if( index( $line, "<context>" ) != -1 )
            {
                # Fetch next line for context data
                $line = <$fileHandle>;
                chomp( $line );

                while( index( $line, "</context>") == -1 )
                {
                    # Normalize text
                    $line =~ s/<head>//g;                                           # Remove <head> tag
                    $line =~ s/<\/head>//g;                                         # Remove </head> tag
                    $line = lc( $line );                                            # Convert all characters to lowercase
                    $line =~ s/'s//g;                                               # Remove "'s" characters (Apostrophe 's')
                    $line =~ s/-/ /g;                                               # Replace all hyphen characters to spaces
                    $line =~ tr/a-z/ /cs;                                           # Remove all characters except a to z
                    $line =~ s/$stopListRegex//g if defined( $stopListRegex );      # Remove "stop" words
                    $line =~ s/\s+/ /g;                                             # Remove duplicate white spaces between words
                    $line = "" if( $line eq " " );                                  # Change line to empty string if line only contains space.

                    my $context = $dataEntry->contextStr;
                    $context .= "$line " if length( $line ) >  0;
                    $context .= ""       if length( $line ) == 0;
                    $dataEntry->contextStr( $context );
                    #print "Normalized Context: $line\n";  # REMOVE ME

                    # Fetch next line for more context data
                    $line = <$fileHandle>;
                    chomp( $line );
                }
            }

            # Fetch next line for end of instance data entry
            $line = <$fileHandle>;
            chomp( $line );

            push( @dataAry, $dataEntry ) if index( $line, "</instance>" ) != -1;
        }
    }

    undef( $fileHandle );

    return \@dataAry;
}

sub WSDCalculateCosineAvgSimilarity
{
    my ( $self ) = @_;

    my @instanceAry = $self->GetInstanceAry();
    my @senseAry = $self->GetSenseAry();

    # Check(s)
    $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Error: Instance Array Size Equals Zero - Cannot Continue" ) if ( scalar @instanceAry == 0 );
    $self->Writelog( "WSDCalculateCosineAvgSimilarity - Error: Sense Array Size Equals Zero - Cannot Continue" )    if ( scalar @senseAry == 0 );
    return -1 if ( @instanceAry == 0 || @senseAry == 0 );

    $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Starting Word Sense Disambiguation Computations" );

    my $word2vec = $self->GetWord2VecHandler();

    # Calculate best senseID for each instance via cosine similarity of vector average.
    for my $instance ( @instanceAry )
    {
        my $instanceContext = $instance->contextStr;
        my @instanceWordAry = split( ' ', $instanceContext );

        # Compute vector average for instance->contextStr once and store value in memory to save computational time
        # NOTE: This is not necessary to store the result, since it is only used once.
        #       Might have possibly applications in the future releases.
        #       Comment out if needed be to save memory during run-time.
        my $resultStr1 = "";

        if( !defined( $instance->vectorAvgStr ) )
        {
            $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Calculating Vector Average Of Instance: \"" . $instance->instanceID . "\" Context" ) if defined( $instance->instanceID );

            $resultStr1 = $word2vec->ComputeAverageOfWords( \@instanceWordAry );
            $instance->vectorAvgStr( $resultStr1 ) if defined( $resultStr1 );
        }
        else
        {
            $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Vector Average Of Instance: \"" .$instance->instanceID . "\" Context Previously Computed" ) if defined( $instance->instanceID );
            $resultStr1 = $instance->vectorAvgStr;
        }

        # Clear Instance Word Array
        undef( @instanceWordAry );
        @instanceWordAry = ();

        for my $sense ( @senseAry )
        {
            my $senseContext = $sense->contextStr;
            my @senseWordAry = split( ' ', $senseContext );

            # Compute vector average for sense->contextStr once and store value in memory to save computational time
            my $resultStr2 = "";

            if( !defined( $sense->vectorAvgStr ) )
            {
                $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Calculating Vector Average Of Sense: \"" . $sense->senseID . "\" Context" ) if defined( $sense->senseID );

                $resultStr2 = $word2vec->ComputeAverageOfWords( \@senseWordAry ) if !defined( $sense->vectorAvgStr );
                $sense->vectorAvgStr( $resultStr2 ) if defined( $resultStr2 );
            }
            else
            {
                $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Vector Average Of Sense: \"" . $sense->senseID . "\" Context Previously Computed" ) if defined( $sense->senseID );
                $resultStr2 = $sense->vectorAvgStr;
            }

            # Clear Sense Word Array
            undef( @senseWordAry );
            @senseWordAry = ();

            # Compute Cosine Similarity Of Average Vectors
            $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Calculating Cosine Similarity Between: \"$instanceContext\" and \"$senseContext\"" );
            my $cosSimValue = $word2vec->ComputeCosineSimilarityOfWordVectors( $resultStr1, $resultStr2 );

            # Assign First Sense ID To Calculated Sense ID
            if ( !defined( $instance->cosSimValue ) || ( defined( $instance->cosSimValue ) && defined( $cosSimValue ) && $cosSimValue > $instance->cosSimValue ) )
            {
                $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Calculated Cosine Similarity Between Instance and Sense Context Greater Than Current Value" ) if defined( $cosSimValue );
                $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Assigning \"Instance ID: " . $instance->instanceID .
                                "\" -> \"Calculated Sense ID: " . $sense->senseID . "\" - \"CosSimValue: " . $cosSimValue . "\"" ) if defined( $cosSimValue );

                # Only Assign Calculated Sense ID If Cosine Similarity Is Defined
                $instance->calculatedSenseID( $sense->senseID ) if defined( $cosSimValue );
                $instance->calculatedSenseID( "undef" ) if !defined( $cosSimValue );
                $instance->cosSimValue( $cosSimValue );
            }
            elsif( defined( $instance->cosSimValue ) && ( defined( $cosSimValue ) && $cosSimValue <= $instance->cosSimValue ) )
            {
                $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Calculated Cosine Similarity Between Instance and Sense Context Less Than Or Equal To Current Value" .
                                 " - \"CosSimValue: " . $cosSimValue . "\"" ) if defined( $cosSimValue );
            }

            # Clear Sense Context Average Cosine Similarity Vector
            $resultStr2 = "";
        }

        # Clear Instance Context Average Cosine Similarity Vector
        $resultStr1 = "";
    }

    $self->WriteLog( "WSDCalculateCosineAvgSimilarity - Complete" );

    return 0;
}

sub _WSDCalculateAccuracy
{
    my ( $self ) = @_;

    my @instanceAry = $self->GetInstanceAry();

    # Check(s)
    return -1 if @instanceAry == 0;

    my $numberCorrect = 0;

    for my $instance ( @instanceAry )
    {
        $numberCorrect++ if $instance->calculatedSenseID eq $instance->senseID;
    }

    return $numberCorrect / @instanceAry;
}

sub WSDPrintResults
{
    my ( $self ) = @_;

    my $percentCorrect = CalculateAccuracy();

    $self->WriteLog( "Accuracy: $percentCorrect" );

    my @instanceAry = $self->GetInstanceAry();

    for my $instance ( @instanceAry )
    {
        $self->WriteLog( "InstanceID: " . $instance->instanceID );
        $self->WriteLog( " - Assigned SenseID: " . $instance->senseID );
        $self->WriteLog( " - Calculated SenseID: " . $instance->calculatedSenseID );
        $self->WriteLog( " - CosSim: " . $instance->cosSimValue ) if defined( $instance->cosSimValue );
        $self->WriteLog( " - CosSim: undef " ) if !defined( $instance->cosSimValue );
        $self->WriteLog( "" );
    }
}

sub WSDSaveResults
{
    my ( $self, $instancesFilePath ) = @_;

    open( my $fileHandle, ">:encoding(utf8)", "$instancesFilePath.results.txt" ) or die "Error: Unable to create save file\n";

    my $percentCorrect = $self->_WSDCalculateAccuracy();

    print $fileHandle "Accuracy: $percentCorrect\n";

    my @instanceAry = $self->GetInstanceAry();

    for my $instance ( @instanceAry )
    {
        print $fileHandle "InstanceID: " . $instance->instanceID;
        print $fileHandle " - Assigned SenseID: " . $instance->senseID;
        print $fileHandle " - Calculated SenseID: " . $instance->calculatedSenseID;
        print $fileHandle " - CosSim: " . $instance->cosSimValue if defined( $instance->cosSimValue );
        print $fileHandle " - CosSim: undef" if !defined( $instance->cosSimValue );
        print $fileHandle "\n";
    }

    close( $fileHandle );
}

sub _WSDGenerateAccuracyReport
{
    my ( $self, $workingDir ) = @_;

    # Check(s)
    $self->WriteLog( "_WSDGenerateAccuracyReport - Working Directory Does Not Exist" ) if !( -e $workingDir );
    return -1 if !( -e $workingDir );

    # Read File Name(s) From Specified Directory
    $self->WriteLog( "_WSDGenerateAccuracyReport - Working Directory: $workingDir" );

    my @filesToParse = ();

    opendir( my $dirHandle, $workingDir ) or die "Error: Opening working directory\n";

    for my $file ( readdir( $dirHandle ) )
    {
        push( @filesToParse, $file ) if ( index( $file, ".results" ) != -1 );
    }

    close( $dirHandle );
    undef( $dirHandle );


    # Check(s)
    $self->WriteLog( "_WSDGenerateAccuracyReport - Warning: No Results Files Found") if ( @filesToParse == 0 );
    return if ( @filesToParse == 0 );

    $self->WriteLog( "_WSDGenerateAccuracyReport - Fetching Results From Files" ) if ( @filesToParse != 0 );

    my @resultAry = ();

    # Fetch accuracy results from each file
    for my $resultFile ( @filesToParse )
    {
        open( my $tempHandle, "<:encoding(utf8)", "$workingDir/$resultFile" ) or die "Error opening: $resultFile\n";

        while( my $line = <$tempHandle> )
        {
            chomp( $line );

            if( index( $line, "Accuracy:" ) != -1 )
            {
                my $endIndex = index( $resultFile, ".results" );
                $resultFile = substr( $resultFile, 0, $endIndex );
                push( @resultAry, "$resultFile : $line" );
                last;
            }
        }

        close( $tempHandle );
        undef( $tempHandle );
    }

    $self->WriteLog( "_WSDGenerateAccuracyReport - Done fetching results" ) if ( @filesToParse != 0 );
    $self->WriteLog( "_WSDGenerateAccuracyReport - Saving data to file: \"AccuracyReport.txt\"" ) if ( @filesToParse != 0 );

    # Save all results in file "AccuracyResults.txt"
    open( my $fileHandle, ">:encoding(utf8)", "$workingDir/AccuracyReport.txt" ) or die "Error creating file: \"AccuracyReport.txt\"\n";

    @resultAry = sort( @resultAry );

    for my $result ( @resultAry )
    {
        print $fileHandle $result . "\n";
    }

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "_WSDGenerateAccuracyReport - Data saved" ) if ( @filesToParse != 0 );
}

# Not my own code
sub _WSDStop
{
    my ( $self, $stopListFilePath ) = @_;

    $self->WriteLog( "_WSDStop - Reading Stop List Path: \"$stopListFilePath\"" );

    # Check(s)
    $self->WriteLog( "_WSDStop - Error: Stop List File Path Not Defined" ) if !defined( $stopListFilePath );
    return undef if !defined( $stopListFilePath );

    $self->WriteLog( "_WSDStop - Error: Stop List File Path Does Not Exist" ) if !( -e $stopListFilePath );
    return undef if !( -e $stopListFilePath );

    my $stop_regex = "";
    my $stop_mode = "AND";

    open ( STP, $stopListFilePath ) || die ( "Error: Couldn't Open The Stoplist File: $stopListFilePath\n" );

    while ( <STP> ) {
	chomp;

	if(/\@stop.mode\s*=\s*(\w+)\s*$/) {
	    $stop_mode=$1;
	    if(!($stop_mode=~/^(AND|and|OR|or)$/)) {
		print STDERR "Requested Stop Mode $1 is not supported.\n";
		exit;
	    }
	    next;
	}

	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;

	#handling a blank lines
	if(/^\s*$/) { next; }

	#check if a valid Perl Regex
        if(!(/^\//)) {
	    print STDERR "Stop token regular expression <$_> should start with '/'\n";
	    exit;
        }
        if(!(/\/$/)) {
	    print STDERR "Stop token regular expression <$_> should end with '/'\n";
	    exit;
        }

        #remove the / s from beginning and end
        s/^\///;
        s/\/$//;

	#form a single big regex
        $stop_regex.="(".$_.")|";
    }

    if(length($stop_regex)<=0) {
	print STDERR "No valid Perl Regular Experssion found in Stop file $stopListFilePath";
	exit;
    }

    chop $stop_regex;

    # making AND a default stop mode
    if(!defined $stop_mode) {
	$stop_mode="AND";
    }

    close STP;

    return $stop_regex;
}

sub ConvertStringLineEndingsToTargetOS
{
    my ( $self, $str ) = @_;

    # Check(s)
    $self->WriteLog( "ConvertLineEndingToTargetOS - Error: String Parameter Is Undefined" ) if ( $str eq "" );
    return undef if !defined( $str );

    $self->WriteLog( "ConvertLineEndingToTargetOS - Warning: Cannot Convert Empty String" ) if ( $str eq "" );
    return "" if ( $str eq "" );

    # Convert String Line Ending Suitable To The Target
    my $lineEnding = "";
    my $os = "linux";

    $lineEnding = "\015\012" if ( $os eq "MSWin32" );
    $lineEnding = "\012"     if ( $os eq "linux" );
    $lineEnding = "\015"     if ( $os eq "MacOS" );

    $str =~ s/(\015\012|\012|\015)/($lineEnding)/g;

    # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
    $str =~ s/^\s+|\s(?=\s)|\s+$//g;

    return $str;
}

######################################################################################
#    Accessors
######################################################################################

sub GetWord2VecDir
{
    my ( $self ) = @_;
    $self->{ _word2vecDir } = "" if !defined ( $self->{ _word2vecDir } );
    return $self->{ _word2vecDir };
}

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

sub GetIgnoreCompileErrors
{
    my ( $self ) = @_;
    $self->{ _ignoreCompileErrors } = 0 if !defined ( $self->{ _ignoreCompileErrors } );
    return $self->{ _ignoreCompileErrors };
}

sub GetIgnoreFileChecks
{
    my ( $self ) = @_;
    $self->{ _ignoreFileChecks } = 0 if !defined ( $self->{ _ignoreFileChecks } );
    return $self->{ _ignoreFileChecks };
}

sub GetExitFlag
{
    my ( $self ) = @_;
    $self->{ _exitFlag } = 0 if !defined ( $self->{ _exitFlag } );
    return $self->{ _exitFlag };
}

sub GetFileHandle
{
    my ( $self ) = @_;

    # Setup File Handle If Not Already Defined
    if( !defined( $self->{ _fileHandle } ) && $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:utf8', 'InterfaceLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }

    return $self->{ _fileHandle };
}

sub GetWorkingDirectory
{
    my ( $self ) = @_;
    $self->{ _workingDir } = Cwd::getcwd() if !defined ( $self->{ _workingDir } );
    return $self->{ _workingDir };
}

sub GetLeskHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _lesk } = Word2vec::Lesk->new( $debugLog, $writeLog ) if !defined( $self->{ _lesk } );
    return $self->{ _lesk };
}

sub GetSpearmansHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _spearmans } = Word2vec::Spearmans->new( $debugLog, $writeLog ) if !defined( $self->{ _spearmans } );
    return $self->{ _spearmans };
}

sub GetWord2VecHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _word2vec } = Word2vec::Word2vec->new( $debugLog, $writeLog ) if !defined ( $self->{ _word2vec } );
    return $self->{ _word2vec };
}

sub GetWord2PhraseHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _word2phrase } = Word2vec::Word2phrase->( $debugLog, $writeLog ) if !defined ( $self->{ _word2phrase } );
    return $self->{ _word2phrase };
}

sub GetXMLToW2VHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _xmltow2v } = Word2vec::Xmltow2v->( $debugLog, $writeLog, 1, 1, 1, 1, 2 ) if !defined ( $self->{ _xmltow2v } );
    return $self->{ _xmltow2v };
}

sub GetUtilHandler
{
    my ( $self ) = @_;
    my $debugLog = $self->GetDebugLog();
    my $writeLog = $self->GetWriteLog();
    $self->{ _util } = Word2vec::Util->new( $debugLog, $writeLog ) if !defined ( $self->{ _util } );
    return $self->{ _util };
}

sub GetInstanceAry
{
    my ( $self ) = @_;
    @{ $self->{ _instanceAry } } = () if !defined( $self->{ _instanceAry } );
    return @{ $self->{ _instanceAry } };
}

sub GetSenseAry
{
    my ( $self ) = @_;
    @{ $self->{ _senseAry } } = () if !defined( $self->{ _senseAry } );
    return @{ $self->{ _senseAry } };
}

sub GetInstanceCount
{
    my ( $self ) = @_;
    $self->{ _instanceCount } = 0 if !defined( $self->{ _instanceCount } );
    return $self->{ _instanceCount };
}

sub GetSenseCount
{
    my ( $self ) = @_;
    $self->{ _senseCount } = 0 if !defined( $self->{ _senseCount } );
    return $self->{ _senseCount };
}


######################################################################################
#    Mutators
######################################################################################

sub SetWord2VecDir
{
    my ( $self, $dir ) = @_;

    $self->WriteLog( "SetWord2VecDir - Changing Word2Vec Executable Directory To $dir" ) if defined( $dir );
    $self->WriteLog( "SetWord2VecDir - Adjusting For \"word2vec\" And \"word2phrase\" Objects" ) if defined( $dir );

    # Set word2vec Directory In Respective Objects
    $self->W2VSetWord2VecExeDir( $dir ) if defined( $dir );
    $self->W2PSetWord2PhraseExeDir( $dir ) if defined( $dir );

    return $self->{ _word2vecDir } = $dir if defined( $dir );
}

sub SetDebugLog
{
    my ( $self, $temp ) = @_;
    return $self->{ _debugLog } = $temp if defined( $temp );
}

sub SetWriteLog
{
    my ( $self, $temp ) = @_;
    return $self->{ _writeLog } = $temp if defined( $temp );
}

# Note: Useless Sub-routines - Remove Me
sub SetIgnoreCompileErrors
{
    my ( $self, $temp ) = @_;
    return $self->{ _ignoreCompileErrors } = $temp if defined( $temp );
}

# Note: Useless Sub-routines - Remove Me
sub SetIgnoreFileCheckErrors
{
    my ( $self, $temp ) = @_;
    return $self->{ _ignoreFileChecks } = $temp if defined( $temp );
}

sub SetWorkingDirectory
{
    my ( $self, $temp ) = @_;
    $self->WriteLog( "SetWorkingDirectory - Directory Changed From: \"" . $self->{ _workingDir } . "\ To \"$temp\"" )
                     if defined( $self->{ _workingDir } ) && defined( $temp );
    return $self->{ _workingDir } = $temp if defined( $temp );
}

sub SetInstanceAry
{
    my ( $self, $aryRef ) = @_;
    return @{ $self->{ _instanceAry } } = @{ $aryRef } if defined( $aryRef );
}

sub ClearInstanceAry
{
    my ( $self ) = @_;
    undef( @{ $self->{ _instanceAry } } );
    return @{ $self->{ _instanceAry } } = ();
}

sub SetSenseAry
{
    my ( $self, $aryRef ) = @_;
    return @{ $self->{ _senseAry } } = @{ $aryRef } if defined( $aryRef );
}

sub ClearSenseAry
{
    my ( $self ) = @_;
    undef( @{ $self->{ _senseAry } } );
    return @{ $self->{ _senseAry } } = ();
}

sub SetInstanceCount
{
    my ( $self, $value ) = @_;
    return $self->{ _instanceCount } = $value if defined( $value );
}

sub SetSenseCount
{
    my ( $self, $value ) = @_;
    return $self->{ _senseCount } = $value if defined( $value );
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
    my ( $self )     = shift;
    my $string       = shift;
    my $printNewLine = shift;

    return if !defined ( $string );
    $printNewLine = 1 if !defined ( $printNewLine );


    if( $self->GetDebugLog() )
    {
        if( ref ( $self ) ne "Word2vec::Interface" )
        {
            print( GetDate() . " " . GetTime() . " - Interface: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - Interface::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Interface" )
        {
            print( GetDate() . " " . GetTime() . " - Interface: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - Interface::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}


######################################################################################
#    Lesk Module Functions
######################################################################################

sub GetMatchingFeaturesBetweenStrings
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->GetMatchingFeatures( $string_a, $string_b );
}

sub GetPhraseOverlapBetweenStrings
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->GetPhraseOverlap( $string_a, $string_b );
}

sub CalculateLeskScore
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->CalculateLeskScore( $string_a, $string_b );
}

sub CalculateLeskCosineScore
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->CalculateCosineScore( $string_a, $string_b );
}

sub CalculateLeskFScore
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->CalculateFScore( $string_a, $string_b );
}

sub CalculateAllLeskScores
{
    my ( $self, $string_a, $string_b ) = @_;
    return $self->GetLeskHandler()->CalculateAllScores( $string_a, $string_b );
}


######################################################################################
#    Utility Module Functions
######################################################################################

sub CleanText
{
    my ( $self, $string ) = @_;
    return $self->GetUtilHandler()->CleanText( $string );
}

sub RemoveNewLineEndingsFromString
{
    my ( $self, $string ) = @_;
    return $self->GetUtilHandler()->RemoveNewLineEndingsFromString( $string );
}

sub IsFileOrDirectory
{
    my ( $self, $path ) = @_;
    return $self->GetUtilHandler()->IsFileOrDirectory( $path );
}

sub IsWordOrCUITerm
{
    my ( $self, $term ) = @_;
    return $self->GetUtilHandler()->IsWordOrCUITerm( $term );
}

sub GetFilesInDirectory
{
    my ( $self, $directoryPath, $fileTagStr ) = @_;
    return $self->GetUtilHandler()->GetFilesInDirectory( $directoryPath, $fileTagStr );
}


######################################################################################
#    Spearmans Module Functions
######################################################################################

sub SpCalculateSpearmans
{
    my ( $self, $fileA, $fileB, $includeCountsInResults ) = @_;
    return $self->GetSpearmansHandler()->CalculateSpearmans( $fileA, $fileB, $includeCountsInResults );
}

sub SpIsFileWordOrCUIFile
{
    my ( $self, $filePath ) = @_;
    return $self->GetSpearmansHandler()->IsFileWordOrCUIFile( $filePath );
}

sub SpGetPrecision
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetPrecision();
}

sub SpGetIsFileOfWords
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetIsFileOfWords();
}

sub SpGetPrintN
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetPrintN();
}

sub SpGetACount
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetACount();
}

sub SpGetBCount
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetBCount();
}

sub SpGetNValue
{
    my ( $self ) = @_;
    return $self->GetSpearmansHandler()->GetNValue();
}

sub SpSetPrecision
{
    my ( $self, $value ) = @_;
    return $self->GetSpearmansHandler()->SetPrecision( $value );
}

sub SpSetIsFileOfWords
{
    my ( $self, $value ) = @_;
    return $self->GetSpearmansHandler()->SetIsFileOfWords( $value );
}

sub SpSetPrintN
{
    my ( $self, $value ) = @_;
    return $self->GetSpearmansHandler()->SetPrintN( $value );
}

######################################################################################
#    Word2Vec Module Functions
######################################################################################

sub W2VExecuteTraining
{
    my ( $self, $trainFilePath, $outputFilePath, $vectorSize, $windowSize, $minCount,
         $sample, $negative, $alpha, $hs, $binary, $numOfThreads, $iterations,
         $useCBOW, $classes, $readVocab, $saveVocab, $debug, $overwrite ) = @_;

    return $self->GetWord2VecHandler()->ExecuteTraining( $trainFilePath, $outputFilePath, $vectorSize, $windowSize,
                                                               $minCount, $sample, $negative, $alpha, $hs, $binary,
                                                               $numOfThreads, $iterations, $useCBOW, $classes, $readVocab,
                                                               $saveVocab, $debug, $overwrite );
}

sub W2VExecuteStringTraining
{
    my ( $self, $trainingStr, $outputFilePath, $vectorSize, $windowSize, $minCount,
         $sample, $negative, $alpha, $hs, $binary, $numOfThreads, $iterations,
         $useCBOW, $classes, $readVocab, $saveVocab, $debug, $overwrite ) = @_;

    return $self->GetWord2VecHandler()->ExecuteStringTraining( $trainingStr, $outputFilePath, $vectorSize, $windowSize,
                                                               $minCount, $sample, $negative, $alpha, $hs, $binary,
                                                               $numOfThreads, $iterations, $useCBOW, $classes, $readVocab,
                                                               $saveVocab, $debug, $overwrite );
}

sub W2VComputeCosineSimilarity
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->ComputeCosineSimilarity( $wordA, $wordB );
}

sub W2VComputeAvgOfWordsCosineSimilarity
{
    my ( $self, $avgStrA, $avgStrB ) = @_;
    return $self->GetWord2VecHandler()->ComputeAvgOfWordsCosineSimilarity( $avgStrA, $avgStrB );
}

sub W2VComputeMultiWordCosineSimilarity
{
    my ( $self, $wordA, $wordB, $allWordsMustExist ) = @_;
    return $self->GetWord2VecHandler()->ComputeMultiWordCosineSimilarity( $wordA, $wordB, $allWordsMustExist );
}

sub W2VComputeCosineSimilarityOfWordVectors
{
    my( $self, $wordAData, $wordBData ) = @_;
    return $self->GetWord2VecHandler()->ComputeCosineSimilarityOfWordVectors( $wordAData, $wordBData );
}

sub W2VCosSimWithUserInput
{
    my ( $self ) = @_;
    $self->GetWord2VecHandler()->CosSimWithUserInput();
}

sub W2VMultiWordCosSimWithUserInput
{
    my ( $self ) = @_;
    $self->GetWord2VecHandler()->MultiWordCosSimWithUserInput();
}

sub W2VComputeAverageOfWords
{
    my ( $self, $wordAryRef ) = @_;
    return $self->GetWord2VecHandler()->ComputeAverageOfWords( $wordAryRef );
}

sub W2VAddTwoWords
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->AddTwoWords( $wordA, $wordB );
}

sub W2VSubtractTwoWords
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->SubtractTwoWords( $wordA, $wordB );
}

sub W2VAddTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->AddTwoWordVectors( $wordA, $wordB );
}

sub W2VSubtractTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->SubtractTwoWordVectors( $wordA, $wordB );
}

sub W2VAverageOfTwoWordVectors
{
    my ( $self, $wordA, $wordB ) = @_;
    return $self->GetWord2VecHandler()->AverageOfTwoWordVectors( $wordA, $wordB );
}

sub W2VGetWordVector
{
    my ( $self, $searchWord ) = @_;
    return $self->GetWord2VecHandler()->GetWordVector( $searchWord );
}

sub W2VIsVectorDataInMemory
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->IsVectorDataInMemory();
}

sub W2VIsWordOrCUIVectorData
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->IsWordOrCUIVectorData();
}

sub W2VIsVectorDataSorted
{
    my ( $self, $aryRef ) = @_;
    return $self->GetWord2VecHandler()->IsVectorDataSorted( $aryRef );
}

sub W2VCheckWord2VecDataFileType
{
    my ( $self, $fileDir ) = @_;
    return $self->GetWord2VecHandler()->CheckWord2VecDataFileType( $fileDir );
}

sub W2VReadTrainedVectorDataFromFile
{
    my ( $self, $fileDir, $searchWord ) = @_;
    return $self->GetWord2VecHandler()->ReadTrainedVectorDataFromFile( $fileDir, $searchWord );
}

sub W2VSaveTrainedVectorDataToFile
{
    my ( $self, $filename, $saveFormat ) = @_;
    return $self->GetWord2VecHandler()->SaveTrainedVectorDataToFile( $filename, $saveFormat );
}

sub W2VStringsAreEqual
{
    my ( $self, $strA, $strB ) = @_;
    return $self->GetWord2VecHandler()->StringsAreEqual( $strA, $strB );
}

sub W2VRemoveWordFromWordVectorString
{
    my ( $self, $vectorDataStr ) = @_;
    return $self->GetWord2VecHandler()->RemoveWordFromWordVectorString( $vectorDataStr );
}

sub W2VConvertRawSparseTextToVectorDataAry
{
    my ( $self, $strData ) = @_;
    return $self->GetWord2VecHandler()->ConvertRawSparseTextToVectorDataAry( $strData );
}

sub W2VConvertRawSparseTextToVectorDataHash
{
    my ( $self, $strData ) = @_;
    return $self->GetWord2VecHandler()->ConvertRawSparseTextToVectorDataHash( $strData );
}

sub W2VGetDebugLog
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetDebugLog();
}

sub W2VGetWriteLog
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetWriteLog();
}

sub W2VGetFileHandle
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetFileHandle();
}

sub W2VGetTrainFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetTrainFilePath();
}

sub W2VGetOutputFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetOutputFilePath();
}

sub W2VGetWordVecSize
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetWordVecSize();
}

sub W2VGetWindowSize
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetWindowSize();
}

sub W2VGetSample
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetSample();
}

sub W2VGetHSoftMax
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetHSoftMax();
}

sub W2VGetNegative
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetNegative();
}

sub W2VGetNumOfThreads
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetNumOfThreads();
}

sub W2VGetNumOfIterations
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetNumOfIterations();
}

sub W2VGetMinCount
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetMinCount();
}

sub W2VGetAlpha
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetAlpha();
}

sub W2VGetClasses
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetClasses();
}

sub W2VGetDebugTraining
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetDebugTraining();
}

sub W2VGetBinaryOutput
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetBinaryOutput();
}

sub W2VGetSaveVocabFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetSaveVocabFilePath();
}

sub W2VGetReadVocabFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetReadVocabFilePath();
}

sub W2VGetUseCBOW
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetUseCBOW();
}

sub W2VGetWorkingDir
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetWorkingDir();
}

sub W2VGetWord2VecExeDir
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetWord2VecExeDir();
}

sub W2VGetVocabularyHash
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetVocabularyHash();
}

sub W2VGetOverwriteOldFile
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetOverwriteOldFile();
}

sub W2VGetSparseVectorMode
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetSparseVectorMode();
}

sub W2VGetVectorLength
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetVectorLength();
}

sub W2VGetNumberOfWords
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetNumberOfWords();
}

sub W2VGetMinimizeMemoryUsage
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->GetMinimizeMemoryUsage();
}

sub W2VSetTrainFilePath
{
    my ( $self, $str ) = @_;
    return $self->GetWord2VecHandler()->SetTrainFilePath( $str );
}

sub W2VSetOutputFilePath
{
    my ( $self, $str ) = @_;
    return $self->GetWord2VecHandler()->SetOutputFilePath( $str );
}

sub W2VSetWordVecSize
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetWordVecSize( $value );
}

sub W2VSetWindowSize
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetWindowSize( $value );
}

sub W2VSetSample
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetSample( $value );
}

sub W2VSetHSoftMax
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetHSoftMax( $value );
}

sub W2VSetNegative
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetNegative( $value );
}

sub W2VSetNumOfThreads
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetNumOfThreads( $value );
}

sub W2VSetNumOfIterations
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetNumOfIterations( $value );
}

sub W2VSetMinCount
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetMinCount( $value );
}

sub W2VSetAlpha
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetAlpha( $value );
}

sub W2VSetClasses
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetClasses( $value );
}

sub W2VSetDebugTraining
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetDebugTraining( $value );
}

sub W2VSetBinaryOutput
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetBinaryOutput( $value );
}

sub W2VSetSaveVocabFilePath
{
    my ( $self, $str ) = @_;
    return $self->GetWord2VecHandler()->SetSaveVocabFilePath( $str );
}

sub W2VSetReadVocabFilePath
{
    my ( $self, $str ) = @_;
    return $self->GetWord2VecHandler()->SetReadVocabFilePath( $str );
}

sub W2VSetUseCBOW
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetUseCBOW( $value );
}

sub W2VSetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2VecHandler()->SetWorkingDir( $dir );
}

sub W2VSetWord2VecExeDir
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2VecHandler()->SetWord2VecExeDir( $dir );
}

sub W2VSetVocabularyHash
{
    my ( $self, $ref ) = @_;
    return $self->GetWord2VecHandler()->SetVocabularyHash( $ref );
}

sub W2VClearVocabularyHash
{
    my ( $self ) = @_;
    return $self->GetWord2VecHandler()->ClearVocabularyHash();
}

sub W2VAddWordVectorToVocabHash
{
    my ( $self, $wordVectorStr ) = @_;
    return $self->GetWord2VecHandler()->AddWordVectorToVocabHash( $wordVectorStr );
}

sub W2VSetOverwriteOldFile
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetOverwriteOldFile( $value );
}

sub W2VSetSparseVectorMode
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetSparseVectorMode( $value );
}

sub W2VSetVectorLength
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetVectorLength( $value );
}

sub W2VSetNumberOfWords
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetNumberOfWords( $value );
}

sub W2VSetMinimizeMemoryUsage
{
    my ( $self, $value ) = @_;
    return $self->GetWord2VecHandler()->SetMinimizeMemoryUsage( $value );
}

######################################################################################
#    Word2Phrase Module Functions
######################################################################################

sub W2PExecuteTraining
{
    my( $self, $trainFilePath, $outputFilePath, $minCount, $threshold, $debug, $overwrite ) = @_;
    return $self->GetWord2PhraseHandler()->ExecuteTraining( $trainFilePath, $outputFilePath, $minCount, $threshold, $debug, $overwrite );
}

sub W2PExecuteStringTraining
{
    my( $self, $trainingStr, $outputFilePath, $minCount, $threshold, $debug, $overwrite ) = @_;
    return $self->GetWord2PhraseHandler()->ExecuteStringTraining( $trainingStr, $outputFilePath, $minCount, $threshold, $debug, $overwrite );
}

sub W2PGetDebugLog
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetDebugLog();
}

sub W2PGetWriteLog
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetWriteLog();
}

sub W2PGetFileHandle
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetFileHandle();
}

sub W2PGetTrainFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetTrainFilePath()
}

sub W2PGetOutputFilePath
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetOutputFilePath();
}

sub W2PGetMinCount
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetMinCount();
}

sub W2PGetThreshold
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetThreshold();
}

sub W2PGetW2PDebug
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetW2PDebug();
}

sub W2PGetWorkingDir
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetWorkingDir();
}

sub W2PGetWord2PhraseExeDir
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetWord2PhraseExeDir();
}

sub W2PGetOverwriteOldFile
{
    my ( $self ) = @_;
    return $self->GetWord2PhraseHandler()->GetOverwriteOldFile();
}

sub W2PSetTrainFilePath
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2PhraseHandler()->SetTrainFilePath( $dir );
}

sub W2PSetOutputFilePath
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2PhraseHandler()->SetOutputFilePath( $dir );
}

sub W2PSetMinCount
{
    my ( $self, $value ) = @_;
    return $self->GetWord2PhraseHandler()->SetMinCount( $value );
}

sub W2PSetThreshold
{
    my ( $self, $value ) = @_;
    return $self->GetWord2PhraseHandler()->SetThreshold( $value );
}

sub W2PSetW2PDebug
{
    my ( $self, $value ) = @_;
    return $self->GetWord2PhraseHandler()->SetW2PDebug( $value );
}

sub W2PSetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2PhraseHandler()->SetWorkingDir( $dir );
}

sub W2PSetWord2PhraseExeDir
{
    my ( $self, $dir ) = @_;
    return $self->GetWord2PhraseHandler()->SetWord2PhraseExeDir( $dir );
}

sub W2PSetOverwriteOldFile
{
    my ( $self, $value ) = @_;
    return $self->GetWord2PhraseHandler()->SetOverwriteOldFile( $value );
}


######################################################################################
#    XMLToWW2V Module Functions
######################################################################################

sub XTWConvertMedlineXMLToW2V
{
    my ( $self ) = @_;
    $self->GetXMLToW2VHandler()->ConvertMedlineXMLToW2V();
}

sub XTWCreateCompoundWordBST
{
    my ( $self ) = @_;
    $self->GetXMLToW2VHandler()->CreateCompoundWordBST();
}

sub XTWCompoundifyString
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->CompoundifyString( $str );
}

sub XTWReadCompoundWordDataFromFile
{
    my ( $self, $fileDir, $autoSetMaxCompoundWordLength ) = @_;
    return $self->GetXMLToW2VHandler()->ReadCompoundWordDataFromFile( $fileDir, $autoSetMaxCompoundWordLength );
}

sub XTWSaveCompoundWordListToFile
{
    my ( $self, $savePath ) = @_;
    return $self->GetXMLToW2VHandler()->SaveCompoundWordListToFile( $savePath );
}

sub XTWReadTextFromFile
{
    my ( $self, $fileDir ) = @_;
    return $self->GetXMLToW2VHandler()->ReadTextFromFile( $fileDir );
}

sub XTWSaveTextToFile
{
    my ( $self, $fileName, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SaveTextToFile( $fileName, $str );
}

sub XTWReadXMLDataFromFile
{
    my ( $self, $fileDir ) = @_;
    return $self->GetXMLToW2VHandler()->_ReadXMLDataFromFile( $fileDir );
}

sub XTWSaveTextCorpusToFile
{
    my ( $self, $saveDir, $appendToFile ) = @_;
    return $self->GetXMLToW2VHandler()->_SaveTextCorpusToFile( $saveDir, $appendToFile );
}

sub XTWIsDateInSpecifiedRange
{
    my ( $self, $date, $beginDate, $endDate ) = @_;
    return $self->GetXMLToW2VHandler()->IsDateInSpecifiedRange( $date, $beginDate, $endDate );
}

sub XTWIsFileOrDirectory
{
    my ( $self, $path ) = @_;
    return $self->GetXMLToW2VHandler()->IsFileOrDirectory( $path );
}

sub XTWRemoveSpecialCharactersFromString
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->RemoveSpecialCharactersFromString( $str );
}

sub XTWGetFileType
{
    my ( $self, $filePath ) = @_;
    return $self->GetXMLToW2VHandler()->GetFileType( $filePath );
}

sub XTWDateCheck
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->_DateCheck();
}

sub XTWGetDebugLog
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetDebugLog();
}

sub XTWGetWriteLog
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetWriteLog();
}

sub XTWGetStoreTitle
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetStoreTitle();
}

sub XTWGetStoreAbstract
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetStoreAbstract();
}

sub XTWGetQuickParse
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetQuickParse();
}

sub XTWGetCompoundifyText
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetCompoundifyText();
}

sub XTWGetStoreAsSentencePerLine
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetStoreAsSentencePerLine();
}

sub XTWGetNumOfThreads
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetNumOfThreads();
}

sub XTWGetWorkingDir
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetWorkingDir();
}

sub XTWGetSaveDir
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetSaveDir();
}

sub XTWGetBeginDate
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetBeginDate();
}

sub XTWGetEndDate
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetEndDate();
}

sub XTWGetXMLStringToParse
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetXMLStringToParse();
}

sub XTWGetTextCorpusStr
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetTextCorpusStr();
}

sub XTWGetFileHandle
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetFileHandle();
}

sub XTWGetTwigHandler
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetTwigHandler();
}

sub XTWGetParsedCount
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetParsedCount();
}

sub XTWGetTempStr
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetTempStr();
}

sub XTWGetTempDate
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetTempDate();
}

sub XTWGetOutputFileName
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetOutputFilePath();
}

sub XTWGetCompoundWordAry
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetCompoundWordAry();
}

sub XTWGetCompoundWordBST
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetCompoundWordBST();
}

sub XTWGetMaxCompoundWordLength
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->GetMaxCompoundWordLength();
}

sub XTWSetStoreTitle
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetStoreTitle( $value );
}

sub XTWSetStoreAbstract
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetStoreAbstract( $value );
}

sub XTWSetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->GetXMLToW2VHandler()->SetWorkingDir( $dir );
}

sub XTWSetSavePath
{
    my ( $self, $dir ) = @_;
    return $self->GetXMLToW2VHandler()->SetSavePath( $dir );
}

sub XTWSetQuickParse
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetQuickParse( $value );
}

sub XTWSetCompoundifyText
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetCompoundifyText( $value );
}

sub XTWSetStoreAsSentencePerLine
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetStoreAsSentencePerLine( $value );
}

sub XTWSetBeginDate
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetBeginDate( $str );
}

sub XTWSetEndDate
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetEndDate( $str );
}

sub XTWSetXMLStringToParse
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetXMLStringToParse( $str );
}

sub XTWSetTextCorpusStr
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetTextCorpusStr( $str );
}

sub XTWAppendStrToTextCorpus
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->AppendStrToTextCorpus( $str );
}

sub XTWClearTextCorpusStr
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->ClearTextCorpusStr();
}

sub XTWSetTempStr
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetTempStr( $str );
}

sub XTWAppendToTempStr
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->AppendToTempStr( $str );
}

sub XTWClearTempStr
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->ClearTempStr();
}

sub XTWSetTempDate
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->SetTempDate( $str );
}

sub XTWClearTempDate
{
    my ( $self ) = @_;
    return $self->GetXMLToW2VHandler()->ClearTempDate();
}

sub XTWSetCompoundWordAry
{
    my ( $self, $aryRef ) = @_;
    return $self->GetXMLToW2VHandler()->SetCompoundWordAry( $aryRef );
}

sub XTWClearCompoundWordAry
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->ClearCompoundWordAry();
}

sub XTWSetCompoundWordBST
{
    my ( $self, $bst ) = @_;
    return $self->GetXMLToW2VHandler()->SetCompoundWordBST( $bst );
}

sub XTWClearCompoundWordBST
{
    my ( $self, $str ) = @_;
    return $self->GetXMLToW2VHandler()->ClearCompoundWordBST();
}

sub XTWSetMaxCompoundWordLength
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetMaxCompoundWordLength( $value );
}

sub XTWSetOverwriteExistingFile
{
    my ( $self, $value ) = @_;
    return $self->GetXMLToW2VHandler()->SetOverwriteExistingFile( $value );
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Interface - Interface module for word2vec.pm, word2phrase.pm, interface.pm modules and associated utilities.

=head1 SYNOPSIS

 use Word2vec::Interface;

 my $result = 0;

 # Compile a text corpus, execute word2vec training and compute cosine similarity of two words
 my $w2vinterface = Word2vec::Interface->new();

 my $xmlconv = $w2vinterface->GetXMLToW2VHandler();
 $xmlconv->SetWorkingDir( "Medline/XML/Directory/Here" );
 $xmlconv->SetSavePath( "textcorpus.txt" );
 $xmlconv->SetStoreTitle( 1 );
 $xmlconv->SetStoreAbstract( 1 );
 $xmlconv->SetBeginDate( "01/01/2004" );
 $xmlconv->SetEndDate( "08/13/2016" );
 $xmlconv->SetOverwriteExistingFile( 1 );

 # If Compound Word File Exists, Store It In Memory
 # And Create Compound Word Binary Search Tree Using The Compound Word Data
 $xmlconv->ReadCompoundWordDataFromFile( "compoundword.txt" );
 $xmlconv->CreateCompoundWordBST();

 # Parse XML Files or Directory Of Files
 $result = $xmlconv->ConvertMedlineXMLToW2V( "/xmlDirectory/" );

 # Check(s)
 print( "Error Parsing Medline XML Files\n" ) if ( $result == -1 );
 exit if ( $result == -1 );

 # Setup And Execute word2vec Training
 my $word2vec = $w2vinterface->GetWord2VecHandler();
 $word2vec->SetTrainFilePath( "textcorpus.txt" );
 $word2vec->SetOutputFilePath( "vectors.bin" );
 $word2vec->SetWordVecSize( 200 );
 $word2vec->SetWindowSize( 8 );
 $word2vec->SetSample( 0.0001 );
 $word2vec->SetNegative( 25 );
 $word2vec->SetHSoftMax( 0 );
 $word2vec->SetBinaryOutput( 0 );
 $word2vec->SetNumOfThreads( 20 );
 $word2vec->SetNumOfIterations( 12 );
 $word2vec->SetUseCBOW( 1 );
 $word2vec->SetOverwriteOldFile( 0 );

 # Execute word2vec Training
 $result = $word2vec->ExecuteTraining();

 # Check(s)
 print( "Error Training Word2vec On File: \"textcorpus.txt\"" ) if ( $result == -1 );
 exit if ( $result == -1 );

 # Read word2vec Training Data Into Memory And Store As A Binary Search Tree
 $result = $word2vec->ReadTrainedVectorDataFromFile( "vectors.bin" );

 # Check(s)
 print( "Error Unable To Read Word2vec Trained Vector Data From File\n" ) if ( $result == -1 );
 exit if ( $result == -1 );

 # Compute Cosine Similarity Between "respiratory" and "arrest"
 $result = $word2vec->ComputeCosineSimilarity( "respiratory", "arrest" );
 print( "Cosine Similarity Between \"respiratory\" and \"arrest\": $result\n" ) if defined( $result );
 print( "Error Computing Cosine Similarity\n" ) if !defined( $result );

 # Compute Cosine Similarity Between "respiratory arrest" and "heart attack"
 $result = $word2vec->ComputeMultiWordCosineSimilarity( "respiratory arrest", "heart attack" );
 print( "Cosine Similarity Between \"respiratory arrest\" and \"heart attack\": $result\n" ) if defined( $result );
 print( "Error Computing Cosine Similarity\n" ) if !defined( $result );

 undef( $w2vinterface );

 # or

 use Word2vec::Interface;

 my $result = 0;
 my $w2vinterface = Word2vec::Interface->new();
 $w2vinterface->XTWSetWorkingDir( "Medline/XML/Directory/Here" );
 $w2vinterface->XTWSetSavePath( "textcorpus.txt" );
 $w2vinterface->XTWSetStoreTitle( 1 );
 $w2vinterface->XTWSetStoreAbstract( 1 );
 $w2vinterface->XTWSetBeginDate( "01/01/2004" );
 $w2vinterface->XTWSetEndDate( "08/13/2016" );
 $w2vinterface->XTWSetOverwriteExistingFile( 1 );

 # If Compound Word File Exists, Store It In Memory
 # And Create Compound Word Binary Search Tree Using The Compound Word Data
 $w2vinterface->XTWReadCompoundWordDataFromFile( "compoundword.txt" );
 $w2vinterface->XTWCreateCompoundWordBST();

 # Parse XML Files or Directory Of Files
 $result = $w2vinterface->XTWConvertMedlineXMLToW2V( "/xmlDirectory/" );

 $result = $w2vinterface->W2VExecuteTraining( "textcorpus.txt", "vectors.bin", 200, 8, undef, 0.001, 25,
                                              undef, 0, 0, 20, 15, 1, 0, undef, undef, undef, 1 );

 # Read word2vec Training Data Into Memory And Store As A Binary Search Tree
 $result = $w2vinterface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );

 # Check(s)
 print( "Error Unable To Read Word2vec Trained Vector Data From File\n" ) if ( $result == -1 );
 exit if ( $result == -1 );

 # Compute Cosine Similarity Between "respiratory" and "arrest"
 $result = $w2vinterface->W2VComputeCosineSimilarity( "respiratory", "arrest" );
 print( "Cosine Similarity Between \"respiratory\" and \"arrest\": $result\n" ) if defined( $result );
 print( "Error Computing Cosine Similarity\n" ) if !defined( $result );

 # Compute Cosine Similarity Between "respiratory arrest" and "heart attack"
 $result = $w2vinterface->W2VComputeMultiWordCosineSimilarity( "respiratory arrest", "heart attack" );
 print( "Cosine Similarity Between \"respiratory arrest\" and \"heart attack\": $result\n" ) if defined( $result );
 print( "Error Computing Cosine Similarity\n" ) if !defined( $result );

 undef( $w2vinterface );

=head1 DESCRIPTION

 Word2vec::Interface is an interface module for utilization of word2vec, word2phrase, xmltow2v and their associated functions.
 This program houses a set of functions, modules and utilities for use with UMLS Similarity.

 XmlToW2v Features:
  - Compilation of a text corpus from plain or gun-zipped Medline XML files.
  - Multi-threaded text corpus compilation support.
  - Include text corpus articles via date range.
  - Include text corpus articles via title, abstract or both.
  - Compoundifying on-the-fly while building text corpus given a compound word file.

 Word2vec Features:
  - Word2vec training with user specified settings.
  - Manipulation of Word2vec word vectors. (Addition/Subtraction/Average)
  - Word2vec binary format to plain text file conversion.
  - Word2vec plain text to binary format file conversion.
  - Multi-word cosine similarity computation. (Sudo-compound word cosine similarity).

 Word2phrase Features:
  - Word2phrase training with user specified settings.

 Interface Features:
  - Word Sense Disambiguation via trained word2vec data.

=head2 Interface Main Functions

=head3 new

Description:

 Returns a new "Word2vec::Interface" module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    word2vecDir                 = "../../External/word2vec"
    debugLog                    = 0
    writeLog                    = 0
    ignoreCompileErrors         = 0
    ignoreFileChecks            = 0
    exitFlag                    = 0
    workingDir                  = ""
    word2vec                    = Word2vec::Word2vec->new()
    word2phrase                 = Word2vec::Word2phrase->new()
    xmltow2v                    = Word2vec::Xmltow2v->new()
    util                        = Word2vec::Interface()
    instanceAry                 = ()
    senseAry                    = ()
    instanceCount               = 0
    senseCount                  = 0


Input:

 $word2vecDir                 -> Specifies word2vec package source/executable directory.
 $debugLog                    -> Instructs module to print debug statements to the console. ('1' = True / '0' = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. ('1' = True / '0' = False)
 $ignoreCompileErrors         -> Instructs module to ignore source code compilation errors. ('1' = True / '0' = False)
 $ignoreFileChecks            -> Instructs module to ignore file checks. ('1' = True / '0' = False)
 $exitFlag                    -> In the event of a run-time check error, exitFlag is set to '1' which gracefully terminates the script.
 $workingDir                  -> Specifies the current working directory.
 $word2vec                    -> Word2vec::Word2vec object.
 $word2phrase                 -> Word2vec::Word2phrase object.
 $xmltow2v                    -> Word2vec::Xmltow2v object.
 $interface                   -> Word2vec::Interface object.
 $instanceAry                 -> Word Sense Disambiguation: Array of instances.
 $senseAry                    -> Word Sense Disambiguation: Array of senses.
 $instanceCount               -> Number of Word Sense Disambiguation instances loaded in memory.
 $senseCount                  -> Number of Word Sense Disambiguation senses  loaded in memory.

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested.  Maximum recommended parameters to be specified include:
 "word2vecDir, debugLog, writeLog, ignoreCompileErrors, ignoreFileChecks"

Output:

 Word2vec::Interface object.

Example:

 use Word2vec::Interface;

 # Parameters: Word2Vec Directory = undef, DebugLog = True, WriteLog = False, IgnoreCompileErrors = False, IgnoreFileChecks = False
 my $interface = Word2vec::Interface->new( undef, 1, 0 );

 undef( $interface );

 # Or

 # Parameters: Word2Vec Directory = undef, DebugLog = False, WriteLog = False, IgnoreCompileErrors = False, IgnoreFileChecks = False
 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 undef( $interface );

=head3 DESTROY

Description:

 Removes member variables and file handle from memory.

Input:

 None

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->DESTROY();

 undef( $interface );

=head3 RunFileChecks

Description:

 Runs word2vec file checks. Looks for word2vec executable files, if not found
 it will then look for the source code and compile automatically placing the
 executable files in the same directory. Errors out gracefully when word2vec
 executable files are not present and source files cannot be located.

 Notes : Word2vec Executable File List: word2vec, word2phrase, word-analogy, distance, compute-accuracy.

       : This method is called automatically in interface::new() function. It can be disabled by setting
         _ignoreFileChecks new() parameter to 1.

Input:

 $string -> Word2vec source/executable directory.

Output:

 $value  -> Returns '1' if checks passed and '0' if file checks failed.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new( undef, 1, 0, 1, 1 );
 my $result = $interface->RunFileChecks();

 print( "Passed Word2Vec File Checks!\n" ) if $result == 0;
 print( "Failed Word2Vec File Checks!\n" ) if $result == 1;

 undef( $interface );

=head3 _CheckIfExecutableFileExists

Description:

 Checks specified executable file exists in a given directory.

Input:

 $filePath -> Executable file path
 $fileName -> Executable file name

Output:

 $value    -> Returns '1' if file is found and '0' if otherwise.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->_CheckIfExecutableFileExists( "../../External/word2vec", "word2vec" );

 print( "Executable File Exists!\n" ) if $result == 1;
 print( "Executable File Does Not Exist!\n" ) if $result == 0;

 undef( $interface );

=head3 _CheckIfSourceFileExists

Description:

 Checks specified directory (string) for the filename (string).
 This ensures the specified files are of file type "text/cpp".

Input:

 $filePath -> Executable file path
 $fileName -> Executable file name

Output:

 $value    -> Returns '1' if file is found and of type "text/cpp" and '0' if otherwise.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->_CheckIfSourceFileExists( "../../External/word2vec", "word2vec" );

 print( "Source File Exists!\n" ) if $result == 1;
 print( "Source File Does Not Exist!\n" ) if $result == 0;

 undef( $interface );

=head3 _CompileSourceFile

Description:

 Compiles C++ source filename in a specified directory.

Input:

 $filePath -> Source file path (string)
 $fileName -> Source file name (string)

Output:

 $value    -> Returns '1' if successful and '0' if un-successful.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface;
 my $result = $interface->_CompileSourceFile( "../../External/word2vec", "word2vec" );

 print( "Compiled Source Successfully!\n" ) if $result == 1;
 print( "Source Compilation Attempt Unsuccessful!\n" ) if $result == 0;

 undef( $interface );

=head3 GetFileType

Description:

 Checks file in given file path and if it exists, returns the file type.

Input:

 $filePath -> File path

Output:

 $string -> Returns file type (string).

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $fileType = $interface->GetFileType( "samples/textcorpus.txt" );

 print( "File Type: $fileType\n" );

 undef( $interface );

=head3 GetOSType

Description:

 Returns current operating system (string).

Input:

 None

Output:

 $string -> Operating System Type. (String)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $os = $interface->GetOSType();

 print( "Operating System: $os\n" );

 undef( $interface );

=head3 _ModifyWord2VecSourceForWindows

Description:

 Modifies "word2vec.c" file for compilation under windows operating system.

Input:

 None

Output:

 $value -> '1' = Successful / '0' = Un-successful

Example:

 This is a private function and should not be utilized.

=head3 _RemoveWord2VecSourceModification

Description:

 Removes modification of "word2vec.c". Returns source file to its original state.

Input:

 None

Output:

 $value -> '1' = Successful / '0' = Un-successful.

Example:

 This is a private function and should not be utilized.

=head2 Interface Command-Line Functions

=head3 CLComputeCosineSimilarity

Description:

 Command-line Method: Computes cosine similarity between 'wordA' and 'wordB' using the specified 'filePath' for
 loading trained word2vec word vector data.

Input:

 $filePath -> Word2Vec trained word vectors binary file path. (String)
 $wordA    -> First word for cosine similarity comparison.
 $wordB    -> Second word for cosine similarity comparison.

Output:

 $value    -> Cosine similarity value (float) or undefined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->CLComputeCosineSimilarity( "../../samples/samplevectors.bin", "of", "the" );
 print( "Cosine Similarity Between \"of\" and \"the\": $value\n" ) if defined( $value );
 print( "Error: Cosine Similarity Could Not Be Computed\n" ) if !defined( $value );

 undef( $interface );

=head3 CLComputeMultiWordCosineSimilarity

Description:

 Command-line Method: Computes cosine similarity between 'phraseA' and 'phraseB' using the specified 'filePath'
 for loading trained word2vec word vector data.

 Note: Supports multiple words concatenated by ':' for each string.

Input:

 $filePath -> Word2Vec trained word vectors binary file path. (String)
 $phraseA  -> First phrase for cosine similarity comparison. (String)
 $phraseB  -> Second phrase for cosine similarity comparison. (String)

Output:

 $value    -> Cosine similarity value (float) or undefined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->CLComputeMultiWordCosineSimilarity( "../../samples/samplevectors.bin", "heart:attack", "myocardial:infarction" );
 print( "Cosine Similarity Between \"heart attack\" and \"myocardial infarction\": $value\n" ) if defined( $value );
 print( "Error: Cosine Similarity Could Not Be Computed\n" ) if !defined( $value );

 undef( $instance );

=head3 CLComputeAvgOfWordsCosineSimilarity

Description:

 Command-line Method: Computes cosine similarity average of all words in 'phraseA' and 'phraseB',
 then takes cosine similarity between 'phraseA' and 'phraseB' average values using the
 specified 'filePath' for loading trained word2vec word vector data.

 Note: Supports multiple words concatenated by ':' for each string.

Input:

 $filePath -> Word2Vec trained word vectors binary file path. (String)
 $phraseA  -> First phrase for cosine similarity comparison.
 $phraseB  -> Second phrase for cosine similarity comparison.

Output:

 $value    -> Cosine similarity value (float) or undefined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->CLComputeAvgOfWordsCosineSimilarity( "../../samples/samplevectors.bin", "heart:attack", "myocardial:infarction" );
 print( "Cosine Similarity Between \"heart attack\" and \"myocardial infarction\": $value\n" ) if defined( $value );
 print( "Error: Cosine Similarity Could Not Be Computed\n" ) if !defined( $value );

 undef( $instance );

=head3 CLMultiWordCosSimWithUserInput

Description:

 Command-line Method: Computes cosine similarity depending on user input given a vectorBinaryFile (string).

 Note: Words can be compounded by the ':' character.

Input:

 $filePath -> Word2Vec trained word vectors binary file path. (String)

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->CLMultiWordCosSimWithUserInput( "../../samples/samplevectors.bin" );

 undef( $instance );

=head3 CLAddTwoWordVectors

Description:

 Command-line Method: Loads the specified word2vec trained binary data file, adds word vectors and returns the summed result.

Input:

 $filePath  -> Word2Vec trained word vectors binary file path. (String)
 $wordDataA -> Word2Vec word data (String)
 $wordDataB -> Word2Vec word data (String)

Output:

 $vectorData -> Summed '$wordDataA' and '$wordDataB' vectors

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $wordVtr = $interface->CLAddTwoWordVectors( "../../samples/samplevectors.bin", "of", "the" );

 print( "Word Vector for \"of\" + \"the\": $wordVtr\n" ) if defined( $wordVtr );
 print( "Word Vector Cannot Be Computed\n" ) if !defined( $wordVtr );

 undef( $instance );

=head3 CLSubtractTwoWordVectors

Description:

 Command-line Method: Loads the specified word2vec trained binary data file, subtracts word vectors and returns the difference result.

Input:

 $filePath  -> Word2Vec trained word vectors binary file path. (String)
 $wordDataA -> Word2Vec word data (String)
 $wordDataB -> Word2Vec word data (String)

Output:

 $vectorData -> Difference of '$wordDataA' and '$wordDataB' vectors

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $wordVtr = $interface->CLSubtractTwoWordVectors( "../../samples/samplevectors.bin", "of", "the" );

 print( "Word Vector for \"of\" - \"the\": $wordVtr\n" ) if defined( $wordVtr );
 print( "Word Vector Cannot Be Computed\n" ) if !defined( $wordVtr );

 undef( $instance );

=head3 CLStartWord2VecTraining

Description:

 Command-line Method: Executes word2vec training given the specified options hash.

Input:

 $hashRef -> Hash reference of word2vec options

Output:

 $value   -> Returns '0' = Successful / '-1' = Un-successful.

Example:

 use Word2vec::Interface;

 my %options;
 $options{'-trainfile'} = "../../samples/textcorpus.txt";
 $options{'-outputfile'} = "../../samples/tempvectors.bin";

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLStartWord2VecTraining( \%options );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLStartWord2PhraseTraining

Description:

 Command-line Method: Executes word2phrase training given the specified options hash.

Input:

 $hashRef -> Hash reference of word2vec options.

Output:

 $value   -> Returns '0' = Successful / '-1' = Un-successful.

Example:

 use Word2vec::Interface;

 my %options;
 $options{'-trainfile'} = "../../samples/textcorpus.txt";
 $options{'-outputfile'} = "../../samples/tempvectors.bin";

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLStartWord2PhraseTraining( \%options );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLCleanText

Description:

 Command-line Method: Reads an input text file, normalizes based on the settings below and prints to a new file.
   - All Text Conveted To Lowercase
   - Duplicate White Spaces Removed
   - "'s" (Apostrophe 's') Characters Removed
   - Hyphen "-" Replaced With Whitespace
   - All Characters Outside Of "a-z" and NewLine Characters Are Removed
   - Lastly, Whitespace Before And After Text Is Removed

Input:

 $hashRef -> Hash reference of inputfile/outputfile options.

Output:

 $value   -> Returns '0' = Successful / '-1' = Un-successful.

Example:

 use Word2vec::Interface;

 my %options;
 $options{'-inputfile'} = "../../samples/test.txt";
 $options{'-outputfile'} = "../../samples/clean_text.txt";

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLCleanText( \%options );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLCompileTextCorpus

Description:

 Command-line Method: Compiles a text corpus given the specified options hash.

Input:

 $hashRef -> Hash reference of xmltow2v options.

Output:

 $value   -> Returns '0' = Successful / '-1' = Un-successful.

Example:

 use Word2vec::Interface;

 my %options;
 $options{'-workdir'} = "../../samples";
 $options{'-savedir'} = "../../samples/textcorpus.txt";

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLCompileTextCorpus( \%options );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLConvertWord2VecVectorFileToText

Description:

 Command-line Method: Converts conversion of word2vec binary format to plain text word vector data.

Input:

 $filePath -> Word2Vec binary file path
 $savePath -> Path to save converted file

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLConvertWord2VecVectorFileToText( "../../samples/samplevectors.bin", "../../samples/convertedvectors.bin" );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLConvertWord2VecVectorFileToBinary

Description:

 Command-line Method: Converts conversion of plain text word vector data to word2vec binary format.

Input:

 $filePath -> Word2Vec binary file path
 $savePath -> Path to save converted file

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLConvertWord2VecVectorFileToBinary( "../../samples/samplevectors.bin", "../../samples/convertedvectors.bin" );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLConvertWord2VecVectorFileToSparse

Description:

 Command-line Method: Converts conversion of plain text word vector data to sparse vector data format.

Input:

 $filePath -> Vectors file path
 $savePath -> Path to save converted file

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLConvertWord2VecVectorFileToSparse( "../../samples/samplevectors.bin", "../../samples/convertedvectors.bin" );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLCompoundifyTextInFile

Description:

 Command-line Method: Reads a specified plain text file at 'filePath' and 'compoundWordFile', then compoundifies and saves the file to 'savePath'.

Input:

 $filePath         -> Text file to compoundify
 $savePath         -> Path to save compoundified file
 $compoundWordFile -> Compound word file path

Output:

 $value            -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLCompoundifyTextInFile( "../../samples/textcorpus.txt", "../../samples/compoundcorpus.txt", "../../samples/compoundword.txt" );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLSortVectorFile

Description:

 Reads a specifed vector file in memory, sorts alphanumerically and saves to a file.

Input:

 $hashRef -> Hash reference of parameters. (File path and overwrite parameters)

Output:

 $value   -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my %options;
 %options{ "-filepath" }  = "vectors.bin";
 %options{ "-overwrite" } = 1;

 my $result = $interface->CLSortVectorFile();

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLFindSimilarTerms

Description:

 Fetches an array containing the nearest n terms using cosine similarity as the metric of determining similar terms.

Input:

 $term                  -> Comparison term used to find similar terms.
 $numberOfSimilarTerms  -> Integer value used to limit the number of elements in array returned.

Output:

 $value                 -> 'Array reference' = Successful / 'undef' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );
 $result = $interface->CLFindSimilarTerms( "cookie", 10 ) if $result == 0;

 print "Success\n"                     if  defined( $result );
 print "Error: No Elements Returned\n" if !defined( $result );
 return if !defined( $result );

 for my $element ( @{ $result } )
 {
    print "$element\n";
 }

 undef( $interface );

=head3 CleanWord2VecDirectory

Description:

 Cleans up C object and executable files in word2vec directory.

Input:

 None

Output:

 $value            -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CleanWord2VecDirectory();

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLSimilarityAvg

Description:

 Computes cosine similarity of average values for a list of specified word comparisons given a file.

 Note: Trained vector data must be loaded in memory previously before calling this method.

Input:

 $filePath         -> Text file with list of word comparisons by line.

Output:

 $value            -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );
 $result = $interface->CLSimilarityAvg( "MiniMayoSRS.terms" ) if $result == 0;

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLSimilarityComp

Description:

 Computes cosine similarity values for a list of specified compound word comparisons given a file.

 Note: Trained vector data must be loaded in memory previously before calling this method.

Input:

 $filePath         -> Text file with list of word comparisons by line.

Output:

 $value            -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );
 $result = $interface->CLSimilarityComp( "MiniMayoSRS.terms" ) if $result == 0;

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLSimilaritySum

Description:

 Computes cosine similarity of summed values for a list of specified word comparisons given a file.

 Note: Trained vector data must be loaded in memory previously before calling this method.

Input:

 $filePath         -> Text file with list of word comparisons by line.

Output:

 $value            -> Result '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );
 $result = $interface->CLSimilaritySum( "MiniMayoSRS.terms" ) if $result == 0;

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 CLWordSenseDisambiguation

Description:

 Command-line Method: Assigns a particular sense to each instance using word2vec trained word vector data.
 Stop words are removed if a stoplist is specified before computing cosine similarity average of each instance
 and sense context.

Input:

 $instanceFilePath -> WSD instance file path
 $senseFilePath    -> WSD sense file path
 $stopListfilePath -> Stop list file path

Output:

 $value            -> Returns '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->CLWordSenseDisambiguation( "ACE.instances.sval", "ACE.senses.sval", "vectors.bin", "stoplist" );

 print( "Success!\n" ) if $result == 0;
 print( "Failed!\n" ) if $result == -1;

 undef( $interface );

=head3 _WSDAnalyzeSenseData

Description:

 Analyzes sense sval files for identification number mismatch and adjusts accordingly in memory.

Input:

 None

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 _WSDReadList

Description:

 Reads a WSD list when the '-list' parameter is specified.

Input:

 $listPath    -> WSD list file path

Output:

 \%listOfFile -> List of files hash reference

Example:

 This is a private function and should not be utilized.

=head3 _WSDParseList

Description:

 Parses the specified list of files for Word Sense Disambiguation computation.

Input:

 $listOfFilesHashRef -> Hash reference to a hash of file paths
 $vectorBinaryFile   -> Word2vec trained word vector data file
 $stopListFilePath   -> Stop list file path

Output:

 $value              -> '0' = Successful / '-1' = Un-successful

Example:

 This is a private function and should not be utilized.

=head3 WSDParseFile

Description:

 Parses a specified file in SVL format and stores all context in memory. Utilized for
 Word Sense Disambiguation cosine similarity computation.

Input:

 $filePath       -> WSD instance or sense file path
 $stopListRegex  -> Stop list regex ( Automatically generated with stop list file )

Output:

 $arrayReference -> Array reference of WSD instances or WSD senses in memory.

Example:

 This is a private function and should not be utilized.

=head3 WSDCalculateCosineAvgSimiliarity

Description:

 For each instance stored in memory, this method computes an average cosine similarity for the context
 of each instance and sense with stop words removed via stop list regex. After average cosine similarity
 values are calculated for each instance and sense, the cosine similarity of each instance and sense is
 computed. The highest cosine similarity value of a given instance to a particular sense is assigned and
 stored.

Input:

 None

Output:

 $value -> Returns '0' = Successful / '-1' = Un-successful

Example:

 This is a private function and should not be utilized.

=head3 _WSDCalculateAccuracy

Description:

 Computes accuracy of assigned sense identification for each instance in memory.

Input:

 None

Output:

 $value -> Returns accuracy percentage (float) or '-1' if un-successful.

Example:

 This is a private function and should not be utilized.

=head3 WSDPrintResults

Description:

 For each instance, this method prints standard information to the console window consisting of:

=over 4

=item I<InstanceID>

=item I<Assigned SenseID>

=item I<Calculated SenseID>

=item I<Cosine Similarity Value>

=back

 Note: Only prints to console if '--debuglog' or 'writelog' option is passed.

Input:

 None

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 WSDSaveResults

Description:

 Saves WSD results post sense identification assignment in the 'instanceFilePath' (string) location. Saved data consists of:

=over 4

=item I<InstanceID>

=item I<Assigned SenseID>

=item I<Calculated SenseID>

=item I<Cosine Similarity Value>

=back

Input:

 $instanceFilePath -> WSD instance file path

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 _WSDGenerateAccuracyReport

Description:

 Fetches saved results for all instance files and stores accuracies for each in a text file.

Input:

 $workingDirectory -> Directory of "*.results.txt" files

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 _WSDStop

Description:

 Generates and returns a stop list regex given a 'stopListFilePath' (string). Returns undefined in the event of an error.

Input:

 $stopListFilePath -> WSD Stop list file path

Output:

 $stopListRegex    -> Returns stop list regex of the WSD stop list file.

Example:

 This is a private function and should not be utilized.

=head3 ConvertStringLineEndingsToTargetOS

Description:

 Converts passed string parameter to current OS line ending format.

 ie. DOS/Windows to Unix/Linux or Unix/Linux to DOS/Windows.

 Warning: This is incompatible with the legacy MacOS format, errors may occur as it is not supported.

Input:

 $string -> String to convert

Output:

 $string -> Output data with target OS line endings.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $tempStr = "samples text\r\n;
 $tempStr = $interface->ConvertStringLineEndingsToTargetOS( $tempStr );

 undef( $interface );

=head2 Interface Accessor Functions

=head3 GetWord2VecDir

Description:

 Returns word2vec executable/source directory.

Input:

 None

Output:

 $string -> Word2vec file path

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $filePath = $interface->GetWord2VecDir();

 print( "FilePath: $filePath\n" );

 undef( $interface );

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $debugLog = $interface->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $interface );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $writeLog = $interface->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $interface );

=head3 GetIgnoreCompileErrors

Description:

 Returns the _ignoreCompileErrors member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $ignoreCompileErrors = $interface->GetIgnoreCompileErrors();

 print( "Ignore Compile Errors Enabled\n" ) if $ignoreCompileErrors == 1;
 print( "Ignore Compile Errors Disabled\n" ) if $ignoreCompileErrors == 0;

 undef( $interface );

=head3 GetIgnoreFileChecks

Description:

 Returns the _ignoreFileChecks member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $ignoreFileChecks = $interface->GetIgnoreFileChecks();

 print( "Ignore File Checks Enabled\n" ) if $ignoreFileChecks == 1;
 print( "Ignore File Checks Disabled\n" ) if $ignoreFileChecks == 0;

 undef( $interface );

=head3 GetExitFlag

Description:

 Returns the _exitFlag member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $exitFlag = $interface->GetExitFlag();

 print( "Exit Flag Set\n" ) if $exitFlag == 1;
 print( "Exit Flag Not Set\n" ) if $exitFlag == 0;

 undef( $interface );

=head3 GetFileHandle

Description:

 Returns file handle used by WriteLog() method.

Input:

 None

Output:

 $fileHandle -> Returns file handle blob used by 'WriteLog()' function or undefined.

Example:

 This is a private function and should not be utilized.

=head3 GetWorkingDirectory

Description:

 Returns the _workingDir member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $string -> Returns working directory

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $dir = $interface->GetWorkingDirectory();

 print( "Working Directory: $dir\n" );

 undef( $interface );

=head3 GetLeskHandler

Description:

 Returns the _lesk member variable set during Word2vec::Lesk object initialization of new function.

 Note: This returns a new object if not defined with lesk::_debugLog and lesk::_writeLog parameters mirroring interface::_debugLog and interface::_writeLog.

Input:

 None

Output:

 Word2vec::Lesk -> Returns 'Word2vec::Lesk' object.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $lesk = $interface->GetLeskHandler();

 undef( $lesk );
 undef( $interface );

=head3 GetSpearmansHandler

Description:

 Returns the _spearmans member variable set during Word2vec::Spearmans object initialization of new function.

 Note: This returns a new object if not defined with spearmans::_debugLog and spearmans::_writeLog parameters mirroring interface::_debugLog and interface::_writeLog.

Input:

 None

Output:

 Word2vec::Spearmans -> Returns 'Word2vec::Spearmans' object.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $spearmans = $interface->GetSpearmansHandler();

 undef( $spearmans );
 undef( $interface );

=head3 GetWord2VecHandler

Description:

 Returns the _word2vec member variable set during Word2vec::Word2vec object initialization of new function.

 Note: This returns a new object if not defined with word2vec::_debugLog and word2vec::_writeLog parameters mirroring interface::_debugLog and interface::_writeLog.

Input:

 None

Output:

 Word2vec::Word2vec -> Returns 'Word2vec::Word2vec' object.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $word2vec = $interface->GetWord2VecHandler();

 undef( $word2vec );
 undef( $interface );

=head3 GetWord2PhraseHandler

Description:

 Returns the _word2phrase member variable set during Word2vec::Word2phrase object initialization of new function.

 Note: This returns a new object if not defined with word2phrase::_debugLog and word2phrase::_writeLog parameters mirroring interface::_debugLog and interface::_writeLog.

Input:

 None

Output:

 Word2vec::Word2phrase -> Returns 'Word2vec::Word2phrase' object

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $word2phrase = $interface->GetWord2PhraseHandler();

 undef( $word2phrase );
 undef( $interface );

=head3 GetXMLToW2VHandler

Description:

 Returns the _xmltow2v member variable set during Word2vec::Xmltow2v object initialization of new function.

 Note: This returns a new object if not defined with word2vec::_debugLog and word2vec::_writeLog parameters mirroring interface::_debugLog and interface::_writeLog.

Input:

 None

Output:

 Word2vec::Xmltow2v -> Returns 'Word2vec::Xmltow2v' object

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $xmltow2v = $interface->GetXMLToW2VHandler();

 undef( $xmltow2v );
 undef( $interface );

#=head3 GetInstanceAry

Description:

 Returns the _instanceAry member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $instance -> Returns array reference of WSD instances.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $aryRef = $interface->GetInstanceAry();

 my @instanceAry = @{ $aryRef };
 undef( $interface );

=head3 GetSensesAry

Description:

 Returns the _senseAry member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $senses -> Returns array reference of WSD senses.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $aryRef = $interface->GetSensesAry();

 my @sensesAry = @{ $aryRef };
 undef( $interface );

=head3 GetInstanceCount

Description:

 Returns the _instanceCount member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> Returns number of stored WSD instances.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $count = $interface->GetInstanceCount();

 print( "Stored WSD instances in memory: $count\n" );

 undef( $interface );

=head3 GetSenseCount

Description:

 Returns the _sensesCount member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> Returns number of stored WSD senses.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $count = $interface->GetSensesCount();

 print( "Stored WSD senses in memory: $count\n" );

 undef( $interface );

=head2 Interface Mutator Functions

=head3 SetWord2VecDir

Description:

 Sets word2vec executable/source file directory.

Input:

 $string -> Word2Vec Directory

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetWord2VecDir( "/word2vec" );

 undef( $interface );

=head3 SetDebugLog

Description:

 Instructs module to print debug statements to the console.

Input:

 $value -> '1' = Print Debug Statements / '0' = Do Not Print Statements

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetDebugLog( 1 );

 undef( $interface );

=head3 SetWriteLog

Description:

 Instructs module to print a log file.

Input:

 $value -> '1' = Print Debug Statements / '0' = Do Not Print Statements

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetWriteLog( 1 );

 undef( $interface );

=head3 SetIgnoreCompileErrors

Description:

 Instructs module to ignore compile errors when compiling source files.

Input:

 $value -> '1' = Ignore warnings/errors, '0' = Display and process warnings/errors.

Output:

 None

Example:

 use Word2vec::Interface;

 my $instance = word2vec::instance->new();
 $instance->SetIgnoreCompileErrors( 1 );

 undef( $instance );

=head3 SetIgnoreFileCheckErrors

Description:

 Instructs module to ignore file checking errors.

Input:

 $value -> '1' = Ignore warnings/errors, '0' = Display and process warnings/errors.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetIgnoreFileCheckErrors( 1 );

 undef( $interface );

=head3 SetWorkingDirectory

Description:

 Sets current working directory.

Input:

 $path -> Working directory path (String)

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetWorkingDirectory( "my/new/working/directory" );

 undef( $interface );

=head3 SetInstanceAry

Description:

 Sets member instance array variable to de-referenced passed array reference parameter.

Input:

 $arrayReference -> Array reference for Word Sense Disambiguation - Array of instances (Word2vec::Wsddata objects).

Output:

 None

Example:

 use word2vec::instance;

 # This array would theoretically contain 'Word2vec::Wsddata' objects.
 my @instanceAry = ();

 my $instance = word2vec::instance->new();
 $instance->SetInstanceAry( \@instanceAry );

 undef( $instance );

=head3 ClearInstanceAry

Description:

 Clears member instance array.

Input:

 None

Output:

 None

Example:

 use Word2vec::Interface;

 my $instance = word2vec::instance->new();
 $instance->ClearInstanceAry();

 undef( $instance );

=head3 SetSenseAry

Description:

 Sets member sense array variable to de-referenced passed array reference parameter.

Input:

 $arrayReference -> Array reference for Word Sense Disambiguation - Array of senses (Word2vec::Wsddata objects).

Output:

 None

Example:

 use Word2vec::Interface;

 # This array would theoretically contain 'Word2vec::Wsddata' objects.
 my @senseAry = ();

 my $interface = word2vec::instance->new();
 $interface->SetSenseAry( \@senseAry );

 undef( $instance );

=head3 ClearSenseAry

Description:

 Clears member sense array.

Input:

 None

Output:

 None

Example:

 use word2vec::instance;

 my $instance = word2vec::instance->new();
 $instance->ClearSenseAry();

 undef( $instance );

=head3 SetInstanceCount

Description:

 Sets member instance count variable to passed value (integer).

Input:

 $value -> Integer (Positive)

Output:

 None

Example:

 use word2vec::instance;

 my $instance = word2vec::instance->new();
 $instance->SetInstanceCount( 12 );

 undef( $instance );

=head3 SetSenseCount

Description:

 Sets member sense count variable to passed value (integer).

Input:

 $value -> Integer (Positive)

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = word2vec::instance->new();
 $instance->SetSenseCount( 12 );

 undef( $instance );

=head2 Debug Functions

=head3 GetTime

Description:

 Returns current time string in "Hour:Minute:Second" format.

Input:

 None

Output:

 $string -> XX:XX:XX ("Hour:Minute:Second")

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 my $time = $interface->GetTime();

 print( "Current Time: $time\n" ) if defined( $time );

 undef( $interface );

=head3 GetDate

Description:

 Returns current month, day and year string in "Month/Day/Year" format.

Input:

 None

Output:

 $string -> XX/XX/XXXX ("Month/Day/Year")

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 my $date = $interface->GetDate();

 print( "Current Date: $date\n" ) if defined( $date );

 undef( $interface );

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

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->WriteLog( "Hello World" );

 undef( $interface );

=head2 Lesk Main Functions

=head3 GetPhraseOverlapBetweenStrings

Description:

 Given two strings, this returns a hash of all overlapping (matching) phrases between both strings and their frequency counts. This prioritizes longer phrases as higher priority when matching.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $hash_ref -> Returns a hash table reference with keys being the unique matching phrase between two input string parameters and the value as the frequency count of each unique phrase.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my %phrase_overlaps = %{ $interface->GetPhraseOverlapBetweenStrings( "I like to eat cookies", "Sometimes I like to eat cookies" ) };

 for my $phrase ( sort keys %phrase_overlaps )
 {
    print "$phrase : $phrase_overlaps{ $phrase }\n";
 }

 undef( %phrase_overlaps );
 undef( $interface );

=head3 CalculateLeskScore

Description:

 Given two strings, this returns a lesk score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> Lesk Score (Float)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $lesk_score = $interface->CalculateLeskScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "Lesk Score: $lesk_score\n";

 undef( $interface );

=head3 CalculateLeskCosineScore

Description:

 Given two strings, this returns a cosine score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> Cosine Score (Float)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $cosine_score = $interface->CalculateLeskCosineScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "Cosine Score: $cosine_score\n";

 undef( $interface );

=head3 CalculateLeskFScore

Description:

 Given two strings, this returns a F score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> F Score (Float)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $f_score = $interface->CalculateLeskFScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "F Score: $f_score\n";

 undef( $interface );

=head3 CalculateAllLeskScores

Description:

 Given two strings, this returns a list of scores (F, Cosine, Lesk, Raw Lesk, Precision, Recall), frequency counts (features, phrases, string lengths).

Input:

 $string_a    -> First comparison string
 $string_b    -> Second comparison string

Output:

 $result_hash -> Hash reference containing: Lesk, Raw Lesk, F, Precision, Recall, Cosine, Matching Feature Frequency, Matching Phrase Frequency, String A Length and String B Length.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my %scores = %{ $interface->CalculateAllLeskScores( "I like to eat cookies", "Sometimes I like to eat cookies" ) };

 for my $score_name ( sort keys %scores )
 {
    print "$score_name : $scores{ $score_name }\n";
 }

 undef( $interface );

=head2 Util Main Functions

=head3 CleanText

Description:

 Normalizes text based on the following.
  - Text converted to lowercase
  - More than one white space is replaced with a single white space
  - Apostrophe "s" ('s) characters are removed
  - Hyphen character is replaced with a single white space
  - All special characters removed outside of lowercase 'a-z' and compoundified terms retained, joined by '_' (underscore).
  - Line-feed/carriage return (LF-CR) endings are cleaned and converted to OS specific LF-CR endings

Input:

 $string -> String of text to normalize

Output:

 $string -> Cleaned/Normalized text.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $text = "123485clean-text!!@&^#*@";

 print( "Original Text: \"$text\"\n" );

 $text = $interface->CleanText( $text );

 print( "Cleaned Text: \"$text\"\n" );

 undef( $interface );

=head3 RemoveNewLineEndingsFromString

Description:

 Removes new line endings from string. Supports MSWin32, linux and MacOS line endings.

Input:

 $string -> String with line-feed/carriage return ending to remove.

Output:

 $string -> String without line-feed/carriage return ending.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $text = "this is sample text\n";

 print( "Original Text: \"$text\"\n" );

 $text = $interface->RemoveNewLineEndingsFromString( $text );

 print( "Cleaned Text: \"$text\"\n" );

 undef( $interface );

=head3 IsFileOrDirectory

Description:

 Given a path, returns a string specifying whether this path represents a file or directory.

Input:

 $path   -> String representing path to check

Output:

 $string -> Returns "file", "dir" or "unknown".

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $result = $interface->IsFileOrDirectory( "../samples/stoplist" );

 print( "Path Type Is A File\n" ) if $result eq "file";
 print( "Path Type Is A Directory\n" ) if $result eq "dir";
 print( "Path Type Is Unknown\n" ) if $result eq "unknown";

 undef( $interface );

=head3 IsWordOrCUITerm

Description:

 Determines if string parameter is a 'word' or 'cui'.

Input:

 $string -> String with single term/cui to examine.

Output:

 $string -> Returns "word" or "cui".

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $result = $interface->IsWordOrCUITerm( "c12345678" );

 print( "String Is Word\n" )  if $result eq "word";
 print( "String Is A CUI\n" ) if $result eq "cui";

 undef( $interface );

=head3 GetFilesInDirectory

Description:

 Given a path and file tag string, returns a string of files consisting of the file tag string in the specified path.

Input:

 $path    -> String representing path
 $fileTag -> String consisting of file tag to fetch.

Output:

 $string  -> Returns string of file names consisting of $fileTag.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 # Looks in specified path for files including ".sval" in their file name.
 my $result = $interface->GetFilesInDirectory( "../samples/", ".sval" );

 print( "Found File Name(s): $result\n" ) if defined( $result );

 undef( $interface );

=head2 Spearmans Main Functions

=head3 SpCalculateSpearmans

 Calculates Spearman's Rank Correlation Score between two data-sets.

Input:

 $fileA                  -> Data set to compare
 $fileB                  -> Data set to compare
 $includeCountsInResults -> Specifies whether to return file counts in score. (undef = False / defined = True)

Output:

 $value -> "undef" or Spearman's Rank Correlation Score

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $score     = $interface->SpCalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $interface );

=head3 SpIsFileWordOrCUIFile

Description:

 Determines if a file is composed of CUI or word terms by checking the first line.

Input:

 $string -> File Path

Output:

 $string -> "undef" = Unable to determine, "cui" = CUI Term File, "word" = Word Term File

Example:

 use Word2vec::Interface;

 my $interface       = Word2vec::Interface->new();
 my $isWordOrCuiFile = $interface->SpIsFileWordOrCUIFile( "samples/MiniMayoSRS.terms" );

 print( "MiniMayoSRS.terms File Is A \"$isWordOrCuiFile\" File\n" ) if defined( $isWordOrCuiFile );
 print( "Unable To Determine Type Of File\n" )                      if !defined( $isWordOrCuiFile );

 undef( $interface );

=head3 SpGetPrecision

 Returns the number of decimal places after the decimal point of the Spearman's Rank Correlation Score to represent.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 print "Spearman's Precision: " . $interface->SpGetPrecision() . "\n";

 undef( $interface );

=head3 SpGetIsFileOfWords

 Returns the variable indicating whether the files to be parsed are files consisting of words or CUI terms.

Input:

 None

Output:

 $value -> "undef" = Auto-Detect, 0 = CUI Terms, 1 = Word Terms

Example:

 use Word2vec::Interface;

 my $interface     = Word2vec::Interface->new();
 my $isFileOfWords = $interface->SpGetIsFileOfWords();
 print "Is File Of Words?: $isFileOfWords\n" if defined( $isFileOfWords );
 print "Is File Of Words?: undef\n" if !defined( $isFileOfWords );

 undef( $interface );

=head3 SpGetPrintN

 Returns the variable indicating whether the to print NValue.

Input:

 None

Output:

 $value -> "undef" = Do not print NValue, "defined" = Print NValue

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $printN    = $interface->SpGetPrintN();
 print "Print N\n"        if defined( $printN );
 print "Do Not Print N\n" if !defined( $printN );

 undef( $interface );

=head3 SpGetACount

 Returns the non-negative count for file A.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 print "A Count: " . $interface->SpGetACount() . "\n";

 undef( $interface );

=head3 SpGetBCount

 Returns the non-negative count for file B.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 print "B Count: " . $interface->SpGetBCount() . "\n";

 undef( $interface );

=head3 SpGetNValue

 Returns the N value.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 print "N Value: " . $interface->SpGetNValue() . "\n";

 undef( $interface );

=head3 SpSetPrecision

 Sets number of decimal places after the decimal point of the Spearman's Rank Correlation Score to represent.

Input:

 $value -> Integer

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SpSetPrecision( 8 );
 my $score = $interface->SpCalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $interface );

=head3 SpSetIsFileOfWords

 Specifies the main method to auto-detect if file consists of CUI or Word terms, or manual override with user setting.

Input:

 $value -> "undef" = Auto-Detect, 0 = CUI Terms, 1 = Word Terms

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SpSetIsFileOfWords( undef );
 my $score = $interface->SpCalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $interface );

=head3 SpSetPrintN

 Specifies the main method print _NValue post Spearmans::CalculateSpearmans() function completion.

Input:

 $value -> "undef" = Do Not Print _NValue, "defined" = Print _NValue

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SpSetPrintN( 1 );
 my $score = $interface->SpCalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $interface );

=head2 Word2Vec Main Functions

=head3 W2VExecuteTraining

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetTrainFilePath( "textcorpus.txt" );
 $interface->W2VSetOutputFilePath( "vectors.bin" );
 $interface->W2VSetWordVecSize( 200 );
 $interface->W2VSetWindowSize( 8 );
 $interface->W2VSetSample( 0.0001 );
 $interface->W2VSetNegative( 25 );
 $interface->W2VSetHSoftMax( 0 );
 $interface->W2VSetBinaryOutput( 0 );
 $interface->W2VSetNumOfThreads( 20 );
 $interface->W2VSetNumOfIterations( 15 );
 $interface->W2VSetUseCBOW( 1 );
 $interface->W2VSetOverwriteOldFile( 0 );
 $interface->W2VExecuteTraining();

 undef( $interface );

 # or

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VExecuteTraining( "textcorpus.txt", "vectors.bin", 200, 8, 5, 0.001, 25, 0.05, 0, 0, 20, 15, 1, 0, "", "", 2, 0 );

 undef( $interface );

=head3 W2VExecuteStringTraining

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetOutputFilePath( "vectors.bin" );
 $interface->W2VSetWordVecSize( 200 );
 $interface->W2VSetWindowSize( 8 );
 $interface->W2VSetSample( 0.0001 );
 $interface->W2VSetNegative( 25 );
 $interface->W2VSetHSoftMax( 0 );
 $interface->W2VSetBinaryOutput( 0 );
 $interface->W2VSetNumOfThreads( 20 );
 $interface->W2VSetNumOfIterations( 15 );
 $interface->W2VSetUseCBOW( 1 );
 $interface->W2VSetOverwriteOldFile( 0 );
 $interface->W2VExecuteStringTraining( "string to train here" );

 undef( $interface );

 # or

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VExecuteStringTraining( "string to train here", "vectors.bin", 200, 8, 5, 0.001, 25, 0.05, 0, 0, 20, 15, 1, 0, "", "", 2, 0 );

 undef( $interface );

=head3 W2VComputeCosineSimilarity

Description:

 Computes cosine similarity between two words using trained word2vec vector data. Returns
 float value or undefined if one or more words are not in the dictionary.

 Note: Supports single words only and requires vector data to be in memory with W2VReadTrainedVectorDataFromFile() prior to function execution.

Input:

 $string -> Single string word
 $string -> Single string word

Output:

 $value  -> Float or Undefined

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"of\" and \"the\": " . $interface->W2VComputeCosineSimilarity( "of", "the" ) . "\n";

 undef( $interface );

=head3 W2VComputeAvgOfWordsCosineSimilarity

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"heart attack\" and \"acute myocardial infarction\": " .
       $interface->W2VComputeAvgOfWordsCosineSimilarity( "heart attack", "acute myocardial infarction" ) . "\n";

 undef( $interface );

=head3 W2VComputeMultiWordCosineSimilarity

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 print "Cosine similarity between words: \"heart attack\" and \"acute myocardial infarction\": " .
       $interface->W2VComputeMultiWordCosineSimilarity( "heart attack", "acute myocardial infarction" ) . "\n";

 undef( $interface );

=head3 W2VComputeCosineSimilarityOfWordVectors

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $vectorAData = $interface->W2VGetWordVector( "heart" );
 my $vectorBData = $interface->W2VGetWordVector( "attack" );

 # Remove Words From Data
 $vectorAData = W2VRemoveWordFromWordVectorString( $vectorAData );
 $vectorBData = W2VRemoveWordFromWordVectorString( $vectorBData );

 undef( @tempAry );

 print "Cosine similarity between words: \"heart\" and \"attack\": " .
       $interface->W2VComputeCosineSimilarityOfWordVectors( $vectorAData, $vectorBData ) . "\n";

 undef( $interface );

=head3 W2VCosSimWithUserInput

Description:

 Computes cosine similarity between two words using trained word2vec vector data based on user input.

 Note: No compound word support.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 None

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $interface->W2VCosSimWIthUserInputTest();

 undef( $interface );

=head3 W2VMultiWordCosSimWithUserInput

Description:

 Computes cosine similarity between two words or compound words using trained word2vec vector data based on user input.

 Note: Supports multiple words concatenated by ':'.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 None

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $interface->W2VMultiWordCosSimWithUserInput();

 undef( $interface );


=head3 W2VComputeAverageOfWords

Description:

 Computes cosine similarity average of all found words given an array reference parameter of
 plain text words. Returns average values (string) or undefined.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 $arrayReference -> Array reference of words

Output:

 $string         -> String of word2vec word average values

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my @wordAry = qw( of the and );
 my $data = $interface->W2VComputeAverageOfWords( \@wordAry );
 print( "Computed Average Of Words: $data" ) if defined( $data );

 undef( $interface );

=head3 W2VAddTwoWords

Description:

 Adds two word vectors and returns the result.

 Warning: This method also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to add
 $string -> Word to add

Output:

 $string -> String of word2vec summed word values

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 my $data = $interface->W2VAddTwoWords( "heart", "attack" );
 print( "Computed Sum Of Words: $data" ) if defined( $data );

 undef( $interface );

=head3 W2VSubtractTwoWords

Description:

 Subtracts two word vectors and returns the result.

 Warning: This method also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to subtract
 $string -> Word to subtract

Output:

 $string -> String of word2vec difference between word values

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 my $data = $interface->W2VSubtractTwoWords( "king", "man" );
 print( "Computed Difference Of Words: $data" ) if defined( $data );

 undef( $interface );


=head3 W2VAddTwoWordVectors

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $wordAData = $interface->W2VGetWordVector( "of" );
 my $wordBData = $interface->W2VGetWordVector( "the" );

 # Removing Words From Vector Data
 $wordAData = W2VRemoveWordFromWordVectorString( $wordAData );
 $wordBData = W2VRemoveWordFromWordVectorString( $wordBData );

 my $data = $interface->W2VAddTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Sum Of Words: $data" ) if defined( $data );

 undef( $interface );

=head3 W2VSubtractTwoWordVectors

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

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $wordAData = $interface->W2VGetWordVector( "of" );
 my $wordBData = $interface->W2VGetWordVector( "the" );

 # Removing Words From Vector Data
 $wordAData = W2VRemoveWordFromWordVectorString( $wordAData );
 $wordBData = W2VRemoveWordFromWordVectorString( $wordBData );

 my $data = $interface->W2VSubtractTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Difference Of Words: $data" ) if defined( $data );

 undef( $interface );

=head3 W2VAverageOfTwoWordVectors

Description:

 Computes the average of two vector data strings and returns the result.

 Warning: Text word must be removed from vector data prior to calling this method. This method
 also requires vector data to be in memory prior to method execution.

Input:

 $string -> Word2vec word vector data (with string word removed)
 $string -> Word2vec word vector data (with string word removed)

Output:

 $string -> String of word2vec average between word values

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $wordAData = $interface->W2VGetWordVector( "of" );
 my $wordBData = $interface->W2VGetWordVector( "the" );

 # Removing Words From Vector Data
 $wordAData = W2VRemoveWordFromWordVectorString( $wordAData );
 $wordBData = W2VRemoveWordFromWordVectorString( $wordBData );

 my $data = $interface->W2VAverageOfTwoWordVectors( $wordAData, $wordBData );
 print( "Computed Average Of Words: $data" ) if defined( $data );

 undef( $interface );

=head3 W2VGetWordVector

Description:

 Searches dictionary in memory for the specified string argument and returns the vector data.
 Returns undefined if not found.

 Warning: Requires vector data to be in memory prior to method execution.

Input:

 $string -> Word to locate in word2vec vocabulary/dictionary

Output:

 $string -> Found word2vec word + word vector data or undefined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $wordData = $interface->W2VGetWordVector( "of" );
 print( "Word2vec Word Data: $wordData\n" ) if defined( $wordData );

 undef( $interface );

=head3 W2VIsVectorDataInMemory

Description:

 Checks to see if vector data has been loaded in memory.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VIsVectorDataInMemory();

 print( "No vector data in memory\n" ) if $result == 0;
 print( "Yes vector data in memory\n" ) if $result == 1;

 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 print( "No vector data in memory\n" ) if $result == 0;
 print( "Yes vector data in memory\n" ) if $result == 1;

 undef( $interface );

=head3 W2VIsWordOrCUIVectorData

Description:

 Checks to see if vector data consists of word or CUI terms.

Input:

 None

Output:

 $string -> 'cui', 'word' or undef

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $isWordOrCUIData = $interface->W2VIsWordOrCUIVectorData();

 print( "Vector Data Consists Of \"$isWordOrCUIData\" Terms\n" ) if defined( $isWordOrCUIData );
 print( "Cannot Determine Type Of Terms\n" ) if !defined( $isWordOrCUIData );

 undef( $interface );

=head3 W2VIsVectorDataSorted

Description:

 Checks to see if vector data header is signed as sorted in memory.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 my $result = $interface->IsVectorDataSorted();

 print( "No vector data is not sorted\n" ) if $result == 0;
 print( "Yes vector data is sorted\n" ) if $result == 1;

 undef( $interface );

=head3 W2VCheckWord2VecDataFileType

Description:

 Checks specified file to see if vector data is in binary or plain text format. Returns 'text'
 for plain text and 'binary' for binary data.

Input:

 $string -> File path

Output:

 $string -> File Type ( "text" = Plain text file / "binary" = Binary data file )

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $fileType = $interface->W2VCheckWord2VecDataFileType( "samples/samplevectors.bin" );

 print( "FileType: $fileType\n" ) if defined( $fileType );

 undef( $fileType );

=head3 W2VReadTrainedVectorDataFromFile

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
 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );

 print( "Success Loading Data\n" ) if $result == 0;
 print( "Un-successful, Data Not Loaded\n" ) if $result == -1;

 undef( $interface );

 # or

 # Searching vector data file for a specific word vector
 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin", "medical" );

 print( "Found Vector Data In File\n" ) if $result != -1;
 print( "Vector Data Not Found\n" )     if $result == -1;

 undef( $interface );

=head3 W2VSaveTrainedVectorDataToFile

Description:

 Saves trained vector data at the location in specified format.

 Note: Leaving 'saveFormat' undefined will automatically save as plain text format.

Input:

 $string       -> Save Path
 $saveFormat   -> Integer ( '0' = Save as plain text / '1' = Save data in word2vec binary format / '2' = Sparse vector data Ffrmat )

 Note: Leaving $saveFormat as undefined will save the file in plain text format.

 Warning: If the vector data is stored as a binary search tree, this method will error out gracefully.

Output:

 $value        -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 $interface->W2VSaveTrainedVectorDataToFile( "samples/newvectors.bin" );

 undef( $interface );

=head3 W2VStringsAreEqual

Description:

 Compares two strings to check for equality, ignoring case-sensitivity.

 Note: This method is not case-sensitive. ie. "string" equals "StRiNg"

Input:

 $string -> String to compare
 $string -> String to compare

Output:

 $value  -> '1' = Strings are equal / '0' = Strings are not equal

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->W2VStringsAreEqual( "hello world", "HeLlO wOrLd" );

 print( "Strings are equal!\n" )if $result == 1;
 print( "Strings are not equal!\n" ) if $result == 0;

 undef( $interface );

=head3 W2VRemoveWordFromWordVectorString

Description:

 Given a vector data string as input, it removed the vector word from its data returning only data.

Input:

 $string          -> Vector word & data string.

Output:

 $string          -> Vector data string.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my $vectorData = $interface->W2VRemoveWordFromWordVectorString( $str );

 print( "Success!\n" ) if length( vectorData ) < length( $str );

 undef( $interface );

=head3 W2VConvertRawSparseTextToVectorDataAry

Description:

 Converts sparse vector string to a dense vector format data array.

Input:

 $string          -> Vector data string.

Output:

 $arrayReference  -> Reference to array of vector data.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my @vectorData = @{ $interface->W2VConvertRawSparseTextToVectorDataAry( $str ) };

 print( "Data conversion successful!\n" ) if @vectorData > 0;
 print( "Data conversion un-successful!\n" ) if @vectorData == 0;

 undef( $interface );

=head3 W2VConvertRawSparseTextToVectorDataHash

Description:

 Converts sparse vector string to a dense vector format data hash.

Input:

 $string          -> Vector data string.

Output:

 $hashReference   -> Reference to hash of vector data.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = "cookie 1 0.234 9 0.0002 13 0.234 17 -0.0023 19 1.0000";

 my %vectorData = %{ $interface->W2VConvertRawSparseTextToVectorDataHash( $str ) };

 print( "Data conversion successful!\n" ) if ( keys %vectorData ) > 0;
 print( "Data conversion un-successful!\n" ) if ( keys %vectorData ) == 0;

 undef( $interface );

=head2 Word2Vec Accessor Functions

=head3 W2VGetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Word2vec object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new()
 my $debugLog = $interface->W2VGetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;


 undef( $interface );

=head3 W2VGetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Word2vec object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $writeLog = $interface->W2VGetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $interface );

=head3 W2VGetFileHandle

Description:

 Returns the _fileHandle member variable set during Word2vec::Word2vec object instantiation of new function.

 Warning: This is a private function. File handle is used by WriteLog() method. Do not manipulate this file handle as errors can result.

Input:

 None

Output:

 $fileHandle -> Returns file handle for WriteLog() method or undefined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $fileHandle = $interface->W2VGetFileHandle();

 undef( $interface );

=head3 W2VGetTrainFilePath

Description:

 Returns the _trainFilePath member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns word2vec training text corpus file path.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $filePath = $interface->W2VGetTrainFilePath();
 print( "Training File Path: $filePath\n" );

 undef( $interface );

=head3 W2VGetOutputFilePath

Description:

 Returns the _outputFilePath member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns post word2vec training output file path.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $filePath = $interface->W2VGetOutputFilePath();
 print( "File Path: $filePath\n" );

 undef( $interface );

=head3 W2VGetWordVecSize

Description:

 Returns the _wordVecSize member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) size of word2vec word vectors. Default value = 100

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetWordVecSize();
 print( "Word Vector Size: $value\n" );

 undef( $interface );

=head3 W2VGetWindowSize

Description:

 Returns the _windowSize member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec window size. Default value = 5

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetWindowSize();
 print( "Window Size: $value\n" );

 undef( $interface );

=head3 W2VGetSample

Description:

 Returns the _sample member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec sample size. Default value = 0.001

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetSample();
 print( "Sample: $value\n" );

 undef( $interface );

=head3 W2VGetHSoftMax

Description:

 Returns the _hSoftMax member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec HSoftMax value. Default = 0

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetHSoftMax();
 print( "HSoftMax: $value\n" );

 undef( $interface );

=head3 W2VGetNegative

Description:

 Returns the _negative member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec negative value. Default = 5

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetNegative();
 print( "Negative: $value\n" );

 undef( $interface );

=head3 W2VGetNumOfThreads

Description:

 Returns the _numOfThreads member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec number of threads to use during training. Default = 12

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetNumOfThreads();
 print( "Number of threads: $value\n" );

 undef( $interface );

=head3 W2VGetNumOfIterations

Description:

 Returns the _iterations member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec number of word2vec iterations. Default = 5

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetNumOfIterations();
 print( "Number of iterations: $value\n" );

 undef( $interface );

=head3 W2VGetMinCount

Description:

 Returns the _minCount member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec min-count value. Default = 5

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetMinCount();
 print( "Min Count: $value\n" );

 undef( $interface );

=head3 W2VGetAlpha

Description:

 Returns the _alpha member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec alpha value. Default = 0.05 for CBOW and 0.025 for Skip-Gram.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetAlpha();
 print( "Alpha: $value\n" );

 undef( $interface );

=head3 W2VGetClasses

Description:

 Returns the _classes member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (integer) word2vec classes value. Default = 0

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetClasses();
 print( "Classes: $value\n" );

 undef( $interface );

=head3 W2VGetDebugTraining

Description:

 Returns the _debug member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 0 = No debug output, 1 = Enable debug output, 2 = Even more debug output

Input:

 None

Output:

 $value -> Returns (integer) word2vec debug value. Default = 2

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetDebugTraining();
 print( "Debug: $value\n" );

 undef( $interface );

=head3 W2VGetBinaryOutput

Description:

 Returns the _binaryOutput member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 1 = Save trained vector data in binary format, 2 = Save trained vector data in plain text format.

Input:

 None

Output:

 $value -> Returns (integer) word2vec binary flag. Default = 0

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetBinaryOutput();
 print( "Binary Output: $value\n" );

 undef( $interface );

=head3 W2VGetReadVocabFilePath

Description:

 Returns the _readVocab member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns (string) word2vec read vocabulary file name or empty string if not set.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = $interface->W2VGetReadVocabFilePath();
 print( "Read Vocab File Path: $str\n" );

 undef( $interface );

=head3 W2VGetSaveVocabFilePath

Description:

 Returns the _saveVocab member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $string -> Returns (string) word2vec save vocabulary file name or empty string if not set.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = $interface->W2VGetSaveVocabFilePath();
 print( "Save Vocab File Path: $str\n" );

 undef( $interface );

=head3 W2VGetUseCBOW

Description:

 Returns the _useCBOW member variable set during Word2vec::Word2vec object instantiation of new function.

 Note: 0 = Skip-Gram Model, 1 = Continuous Bag Of Words Model.

Input:

 None

Output:

 $value -> Returns (integer) word2vec Continuous-Bag-Of-Words flag. Default = 1

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetUseCBOW();
 print( "Use CBOW?: $value\n" );

 undef( $interface );

=head3 W2VGetWorkingDir

Description:

 Returns the _workingDir member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (string) working directory path or current directory if not specified.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = $interface->W2VGetWorkingDir();
 print( "Working Directory: $str\n" );

 undef( $interface );

=head3 W2VGetWord2VecExeDir

Description:

 Returns the _word2VecExeDir member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns (string) word2vec executable directory path or empty string if not specified.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = $interface->W2VGetWord2VecExeDir();
 print( "Word2Vec Executable File Directory: $str\n" );

 undef( $interface );

=head3 W2VGetVocabularyHash

Description:

 Returns the _hashRefOfWordVectors member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns hash reference of vocabulary/dictionary words. (Word2vec trained data in memory)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my @vocabulary = $interface->W2VGetVocabularyHash();

 undef( $interface );

=head3 W2VGetOverwriteOldFile

Description:

 Returns the _overwriteOldFile member variable set during Word2vec::Word2vec object instantiation of new function.

Input:

 None

Output:

 $value -> Returns 1 = True or 0 = False.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $value = $interface->W2VGetOverwriteOldFile();
 print( "Overwrite Exiting File?: $value\n" );

 undef( $interface );

=head2 Word2Vec Mutator Functions

=head3 W2VSetTrainFilePath

Description:

 Sets member variable to string parameter. Sets training file path.

Input:

 $string -> Text corpus training file path

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetTrainFilePath( "samples/textcorpus.txt" );

 undef( $interface );

=head3 W2VSetOutputFilePath

Description:

 Sets member variable to string parameter. Sets output file path.

Input:

 $string -> Post word2vec training save file path

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetOutputFilePath( "samples/tempvectors.bin" );

 undef( $interface );

=head3 W2VSetWordVecSize

Description:

 Sets member variable to integer parameter. Sets word2vec word vector size.

Input:

 $value -> Word2vec word vector size

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetWordVecSize( 100 );

 undef( $interface );

=head3 W2VSetWindowSize

Description:

 Sets member variable to integer parameter. Sets word2vec window size.

Input:

 $value -> Word2vec window size

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetWindowSize( 8 );

 undef( $interface );

=head3 W2VSetSample

Description:

 Sets member variable to integer parameter. Sets word2vec sample size.

Input:

 $value -> Word2vec sample size

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetSample( 3 );

 undef( $interface );

=head3 W2VSetHSoftMax

Description:

 Sets member variable to integer parameter. Sets word2vec HSoftMax value.

Input:

 $value -> Word2vec HSoftMax size

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetHSoftMax( 12 );

 undef( $interface );

=head3 W2VSetNegative

Description:

 Sets member variable to integer parameter. Sets word2vec negative value.

Input:

 $value -> Word2vec negative value

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetNegative( 12 );

 undef( $interface );

=head3 W2VSetNumOfThreads

Description:

 Sets member variable to integer parameter. Sets word2vec number of training threads to specified value.

Input:

 $value -> Word2vec number of threads value

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetNumOfThreads( 12 );

 undef( $interface );

=head3 W2VSetNumOfIterations

Description:

 Sets member variable to integer parameter. Sets word2vec iterations value.

Input:

 $value -> Word2vec number of iterations value

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetNumOfIterations( 12 );

 undef( $interface );

=head3 W2VSetMinCount

Description:

 Sets member variable to integer parameter. Sets word2vec min-count value.

Input:

 $value -> Word2vec min-count value

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetMinCount( 7 );

 undef( $interface );

=head3 W2VSetAlpha

Description:

 Sets member variable to float parameter. Sets word2vec alpha value.

Input:

 $value -> Word2vec alpha value. (Float)

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->SetAlpha( 0.0012 );

 undef( $interface );

=head3 W2VSetClasses

Description:

 Sets member variable to integer parameter. Sets word2vec classes value.

Input:

 $value -> Word2vec classes value.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetClasses( 0 );

 undef( $interface );

=head3 W2VSetDebugTraining

Description:

 Sets member variable to integer parameter. Sets word2vec debug parameter value.

Input:

 $value -> Word2vec debug training value.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetDebugTraining( 0 );

 undef( $interface );

=head3 W2VSetBinaryOutput

Description:

 Sets member variable to integer parameter. Sets word2vec binary parameter value.

Input:

 $value -> Word2vec binary output mode value. ( '1' = Binary Output / '0' = Plain Text )

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetBinaryOutput( 1 );

 undef( $interface );

=head3 W2VSetSaveVocabFilePath

Description:

 Sets member variable to string parameter. Sets word2vec save vocabulary file name.

Input:

 $string -> Word2vec save vocabulary file name and path.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetSaveVocabFilePath( "samples/vocab.txt" );

 undef( $interface );

=head3 W2VSetReadVocabFilePath

Description:

 Sets member variable to string parameter. Sets word2vec read vocabulary file name.

Input:

 $string -> Word2vec read vocabulary file name and path.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetReadVocabFilePath( "samples/vocab.txt" );

 undef( $interface );

=head3 W2VSetUseCBOW

Description:

 Sets member variable to integer parameter. Sets word2vec CBOW parameter value.

Input:

 $value -> Word2vec CBOW mode value.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetUseCBOW( 1 );

 undef( $interface );

=head3 W2VSetWorkingDir

Description:

 Sets member variable to string parameter. Sets working directory.

Input:

 $string -> Working directory

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetWorkingDir( "/samples" );

 undef( $interface );

=head3 W2VSetWord2VecExeDir

Description:

 Sets member variable to string parameter. Sets word2vec executable file directory.

Input:

 $string -> Word2vec directory

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetWord2VecExeDir( "/word2vec" );

 undef( $interface );

=head3 W2VSetVocabularyHash

Description:

 Sets vocabulary/dictionary hash reference to hash reference parameter.

 Warning: This will overwrite any existing vocabulary/dictionary data in memory.

Input:

 $hashReference -> Vocabulary/Dictionary hash reference of word2vec word vectors.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VReadTrainedVectorDataFromFile( "samples/samplevectors.bin" );
 my $vocabularyHasReference = $interface->W2VGetVocabularyHash();
 $interface->W2VSetVocabularyHash( $vocabularyHasReference );

 undef( $interface );

=head3 W2VClearVocabularyHash

Description:

 Clears vocabulary/dictionary hash.

Input:

 None

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VClearVocabularyHash();

 undef( $interface );

=head3 W2VAddWordVectorToVocabHash

Description:

 Adds word vector string to vocabulary/dictionary.

Input:

 $string -> Word2vec word vector string

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 # Note: This is representational data of word2vec's word vector format and not actual data.
 $interface->W2VAddWordVectorToVocabHash( "of 0.4346 -0.1235 0.5789 0.2347 -0.0056 -0.0001" );

 undef( $interface );

=head3 W2VSetOverwriteOldFile

Description:

 Sets member variable to integer parameter. Enables overwriting output file if one already exists.

Input:

 $value -> '1' = Overwrite exiting file / '0' = Graceful termination when file with same name exists

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2VSetOverwriteOldFile( 1 );

 undef( $interface );

=head2 Word2Phrase Main Functions

=head3 W2PExecuteTraining

Description:

 Executes word2phrase training based on parameters. Parameter variables have higher precedence than member variables.
 Any parameter specified will override its respective member variable.

 Note: If no parameters are specified, this module executes word2phrase training based on preset member
 variables. Returns string regarding training status.

Input:

 $trainFilePath  -> Training text corpus file path
 $outputFilePath -> Vector binary file path
 $minCount       -> Minimum bi-gram frequency (Positive Integer)
 $threshold      -> Maximum bi-gram frequency (Positive Integer)
 $debug          -> Displays word2phrase debug information during training. (0 = None, 1 = Show Debug Information, 2 = Show Even More Debug Information)
 $overwrite      -> Overwrites old training file when executing training. (0 = False / 1 = True)

Output:

 $value          -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetMinCount( 12 );
 $interface->W2PSetMaxCount( 20 );
 $interface->W2PSetTrainFilePath( "textCorpus.txt" );
 $interface->W2PSetOutputFilePath( "phraseTextCorpus.txt" );
 $interface->W2PExecuteTraining();
 undef( $interface );

 # Or

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PExecuteTraining( "textCorpus.txt", "phraseTextCorpus.txt", 12, 20, 2, 1 );
 undef( $interface );

=head3 W2PExecuteStringTraining

Description:

 Executes word2phrase training based on parameters. Parameter variables have higher precedence than member variables.
 Any parameter specified will override its respective member variable.

 Note: If no parameters are specified, this module executes word2phrase training based on preset member
 variables. Returns string regarding training status.

Input:

 $trainingString -> String to train
 $outputFilePath -> Vector binary file path
 $minCount       -> Minimum bi-gram frequency (Positive Integer)
 $threshold      -> Maximum bi-gram frequency (Positive Integer)
 $debug          -> Displays word2phrase debug information during training. (0 = None, 1 = Show Debug Information, 2 = Show Even More Debug Information)
 $overwrite      -> Overwrites old training file when executing training. (0 = False / 1 = True)

Output:

 $value          -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetMinCount( 12 );
 $interface->W2PSetMaxCount( 20 );
 $interface->W2PSetTrainFilePath( "large string to train here" );
 $interface->W2PSetOutputFilePath( "phraseTextCorpus.txt" );
 $interface->W2PExecuteTraining();
 undef( $interface );

 # Or

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PExecuteTraining( "large string to train here", "phraseTextCorpus.txt", 12, 20, 2, 1 );
 undef( $interface );

=head2 Word2Phrase Accessor Functions

=head3 W2PGetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Interface object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $debugLog = $interface->W2PGetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $interface );

=head3 W2PGetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Interface object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $writeLog = $interface->W2PGetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $interface );

=head3 W2PGetFileHandle

Description:

 Returns file handle used by word2phrase::WriteLog() method.

Input:

 None

Output:

 $fileHandle -> Returns file handle blob used by 'WriteLog()' function or undefined.

Example:

 <This should not be called.>

=head3 W2PGetTrainFilePath

Description:

 Returns (string) training file path.

Input:

 None

Output:

 $string -> word2phrase training file path

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $filePath = $interface->W2PGetTrainFilePath();

 print( "Output File Path: $filePath\n" ) if defined( $filePath );
 undef( $interface );

=head3 W2PGetOutputFilePath

Description:

 Returns (string) output file path.

Input:

 None

Output:

 $string -> word2phrase output file path

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $filePath = $interface->W2PGetOutputFilePath();

 print( "Output File Path: $filePath\n" ) if defined( $filePath );
 undef( $interface );

=head3 W2PGetMinCount

Description:

 Returns (integer) minimum bi-gram range.

Input:

 None

Output:

 $value ->  Minimum bi-gram frequency (Positive Integer)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $mincount = $interface->W2PGetMinCount();

 print( "MinCount: $mincount\n" ) if defined( $mincount );
 undef( $interface );

=head3 W2PGetThreshold

Description:

 Returns (integer) maximum bi-gram range.

Input:

 None

Output:

 $value ->  Maximum bi-gram frequency (Positive Integer)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $mincount = $interface->W2PGetThreshold();

 print( "MinCount: $mincount\n" ) if defined( $mincount );
 undef( $interface );

=head3 W2PGetW2PDebug

Description:

 Returns word2phrase debug parameter value.

Input:

 None

Output:

 $value -> 0 = No debugging, 1 = Show debugging, 2 = Show even more debugging

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $interfacedebug = $interface->W2PGetW2PDebug();

 print( "Word2Phrase Debug Level: $interfacedebug\n" ) if defined( $interfacedebug );

 undef( $interface );

=head3 W2PGetWorkingDir

Description:

 Returns (string) working directory path.

Input:

 None

Output:

 $string -> Current working directory path

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $workingDir = $interface->W2PGetWorkingDir();

 print( "Working Directory: $workingDir\n" ) if defined( $workingDir );

 undef( $interface );

=head3 W2PGetWord2PhraseExeDir

Description:

 Returns (string) word2phrase executable directory path.

Input:

 None

Output:

 $string -> Word2Phrase executable directory path

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $workingDir = $interface->W2PGetWord2PhraseExeDir();

 print( "Word2Phrase Executable Directory: $workingDir\n" ) if defined( $workingDir );

 undef( $interface );

=head3 W2PGetOverwriteOldFile

Description:

 Returns the current value of the overwrite training file variable.

Input:

 None

Output:

 $value -> 1 = True/Overwrite or 0 = False/Append to current file

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $overwrite = $interface->W2PGetOverwriteOldFile();

 if defined( $overwrite )
 {
    print( "Overwrite Old File: " );
    print( "Yes\n" ) if $overwrite == 1;
    print( "No\n" ) if $overwrite == 0;
 }

 undef( $interface );

=head2 Word2Phrase Mutator Functions

=head3 W2PSetTrainFilePath

Description:

 Sets training file path.

Input:

 $string -> Training file path

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetTrainFilePath( "filePath" );

 undef( $interface );

=head3 W2PSetOutputFilePath

Description:

 Sets word2phrase output file path.

Input:

 $string -> word2phrase output file path

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetOutputFilePath( "filePath" );

 undef( $interface );

=head3 W2PSetMinCount

Description:

 Sets minimum range value.

Input:

 $value -> Minimum frequency value (Positive integer)

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetMinCount( 1 );

 undef( $interface );

=head3 W2PSetThreshold

Description:

 Sets maximum range value.

Input:

 $value -> Maximum frequency value (Positive integer)

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetThreshold( 100 );

 undef( $interface );

=head3 W2PSetW2PDebug

Description:

 Sets word2phrase debug parameter.

Input:

 $value -> word2phrase debug parameter (0 = No debug info, 1 = Show debug info, 2 = Show more debug info.)

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetW2PDebug( 2 );

 undef( $interface );

=head3 W2PSetWorkingDir

Description:

 Sets working directory path.

Input:

 $string -> Current working directory path.

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetWorkingDir( "filePath" );

 undef( $interface );

=head3 W2PSetWord2PhraseExeDir

Description:

 Sets word2phrase executable file directory path.

Input:

 $string -> Word2Phrase executable directory path.

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetWord2PhraseExeDir( "filePath" );

 undef( $interface );

=head3 W2PSetOverwriteOldFile

Description:

 Enables overwriting word2phrase output file if one already exists with the same output file name.

Input:

 $value -> Integer: 1 = Overwrite old file, 0 = No not overwrite old file.

Output:

 None

Example:

 use Word2vec::Interface:

 my $interface = Word2vec::Interface->new();
 $interface->W2PSetOverwriteOldFile( 1 );

 undef( $interface );

=head2 XMLToW2V Main Functions

=head3 XTWConvertMedlineXMLToW2V

Description:

 Parses specified parameter Medline XML file or directory of files, creating a text corpus. Returns 0 if successful or -1 during an error.

 Note: Supports plain Medline XML or gun-zipped XML files.

Input:

 $filePath -> XML file path to parse. (This can be a single file or directory of XML/XML.gz files).

Output:

 $value    -> '0' = Successful / '-1' = Un-Successful

Example:

 use Word2vec::Interface;

 $interface = Word2vec::Interface->new();      # Note: Specifying no parameters implies default settings
 $interface->XTWSetSavePath( "testCorpus.txt" );
 $interface->XTWSetStoreTitle( 1 );
 $interface->XTWSetStoreAbstract( 1 );
 $interface->XTWSetBeginDate( "01/01/2004" );
 $interface->XTWSetEndDate( "08/13/2016" );
 $interface->XTWSetOverwriteExistingFile( 1 );
 $interface->XTWConvertMedlineXMLToW2V( "/xmlDirectory/" );
 undef( $interface );

=head3 XTWCreateCompoundWordBST

Description:

 Creates a binary search tree using compound word data in memory and stores root node. This also clears the compound word array afterwards.

 Warning: Compound word file must be loaded into memory using XTWReadCompoundWordDataFromFile() prior to calling this method. This function
          will also delete the compound word array upon completion as it will no longer be necessary.

Input:

 None

Output:

 $value -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $interface->CreateCompoundWordBST();

=head3 XTWCompoundifyString

Description:

 Compoundifies string parameter based on compound word data in memory using the compound word binary search tree.

 Warning: Compound word file must be loaded into memory using XTWReadCompoundWordDataFromFile() prior to calling this method.

Input:

 $string -> String to compoundify

Output:

 $string -> Compounded string or "(null)" if string parameter is not defined.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $interface->CreateCompoundWordBST();
 my $compoundedString = $interface->CompoundifyString( "String to compoundify" );
 print( "Compounded String: $compoundedString\n" );

 undef( $interface );

=head3 XTWReadCompoundWordDataFromFile

Description:

 Reads compound word file and stores in memory. $autoSetMaxCompWordLength parameter is not required to be set. This
 parameter instructs the method to auto set the maximum compound word length dependent on the longest compound word found.

 Note: $autoSetMaxCompWordLength options: defined = True and Undefined = False.

Input:

 $filePath                 -> Compound word file path
 $autoSetMaxCompWordLength -> Maximum length of a given compoundified phrase the module's compoundify algorithm will permit.

 Note: Calling this method with $autoSetMaxCompWordLength defined will automatically set the maxCompoundWordLength variable to the longest compound phrase.

Output:

 $value                    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWReadCompoundWordDataFromFile( "samples/compoundword.txt", 1 );

 undef( $interface );

=head3 XTWSaveCompoundWordListToFile

Description:

 Saves compound word data in memory to a specified file location.

Input:

 $savePath -> Path to save compound word list to file.

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $interface->XTWSaveCompoundWordDataFromFile( "samples/newcompoundword.txt" );
 undef( $interface );

=head3 XTWReadTextFromFile

Description:

 Reads a plain text file with utf8 encoding in memory. Returns string data if successful and "(null)" if unsuccessful.

Input:

 $filePath -> Text file to read into memory

Output:

 $string   -> String data if successful or "(null)" if un-successful.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $textData = $interface->XTWReadTextFromFile( "samples/textcorpus.txt" );
 print( "Text Data: $textData\n" );
 undef( $interface );

=head3 XTWSaveTextToFile

Description:

 Saves a plain text file with utf8 encoding in a specified location.

Input:

 $savePath -> Path to save string data.
 $string   -> String to save

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $result = $interface->XTWSaveTextToFile( "text.txt", "Hello world!" );

 print( "File saved\n" ) if $result == 0;
 print( "File unable to save\n" ) if $result == -1;

 undef( $interface );

=head3 XTWReadXMLDataFromFile

Description:

 Reads an XML file from a specified location. Returns string in memory if successful and "(null)" if unsuccessful.

Input:

 $filePath -> File to read given path

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 Warning: This is a private function and is called by XML::Twig parsing functions. It should not be called outside of xmltow2v module.

=head3 XTWSaveTextCorpusToFile

Description:

 Saves text corpus data to specified file path. This method will append to any existing file if $appendToFile parameter
 is defined or "overwrite" option is disabled. Enabling "overwrite" option will overwrite any existing files.

Input:

 $savePath     -> Path to save the text corpus
 $appendToFile -> Specifies whether the module will overwrite any existing data or append to existing text corpus data.

 Note: Leaving this variable undefined will fetch the "Overwrite" member variable and set the value to this parameter.

Output:

 $value        -> '0' = Successful / '-1' = Un-successful

Example:

 Warning: This is a private function and is called by XML::Twig parsing functions. It should not be called outside of xmltow2v module.

=head3 XTWIsDateInSpecifiedRange

Description:

 Checks to see if $date is within $beginDate and $endDate range. Returns 1 if true and 0 if false.

 Note: Date Format: XX/XX/XXXX (Month/Day/Year)

Input:

 $date      -> Date to check against minimum and maximum data range. (String)
 $beginDate -> Minimum date range (String)
 $endDate   -> Maximum date range (String)

Output:

 $value     -> '1' = True/Date is within specified range Or '0' = False/Date is not within specified range.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 print( "Is \"01/01/2004\" within the date range: \"02/21/1985\" to \"08/13/2016\"?\n" );
 print( "Yes\n" ) if $interface->XTWIsDateInSpecifiedRange( "01/01/2004", "02/21/1985", "08/13/2016" ) == 1;
 print( "No\n" ) if $interface->XTWIsDateInSpecifiedRange( "01/01/2004", "02/21/1985", "08/13/2016" ) == 0;

 undef( $interface );

=head3 XTWIsFileOrDirectory

Description:

 Checks to see if specified path is a file or directory.

Input:

 $path   -> File or directory path. (String)

Output:

 $string -> Returns: "file" = file, "dir" = directory and "unknown" if the path is not a file or directory (undefined).

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $path = "path/to/a/directory";

 print( "Is \"$path\" a file or directory? " . $interface->XTWIsFileOrDirectory( $path ) . "\n" );

 $path = "path/to/a/file.file";

 print( "Is \"$path\" a file or directory? " . $interface->XTWIsFileOrDirectory( $path ) . "\n" );

 undef( $interface );

=head3 XTWRemoveSpecialCharactersFromString

Description:

 Removes special characters from string parameter, removes extra spaces and converts text to lowercase.

 Note: This method is called when parsing and compiling Medline title/abstract data.

Input:

 $string -> String passed to remove special characters from and convert to lowercase.

Output:

 $string -> String with all special characters removed and converted to lowercase.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();

 my $str = "Heart Attack is$ an!@ also KNOWN as an Acute MYOCARDIAL inFARCTion!";

 print( "Original String: $str\n" );

 $str = $interface->XTWRemoveSpecialCharactersFromString( $str );

 print( "Modified String: $str\n" );

 undef( $interface );

=head3 XTWGetFileType

Description:

 Returns file data type (string).

Input:

 $filePath -> File to check located at file path

Output:

 $string   -> File type

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new()
 my $fileType = $interface->XTWGetFileType( "samples/textcorpus.txt" );

 undef( $interface );

=head3 XTWDateCheck

Description:

 Checks specified begin and end date strings for formatting and logic errors.

Input:

 None

Output:

 $value   -> "0" = Passed Checks / "-1" = Failed Checks

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new()
 print "Passed Date Checks\n" if ( $interface->_DateCheck() == 0 );
 print "Failed Date Checks\n" if ( $interface->_DateCheck() == -1 );

 undef( $interface );

=head2 XMLToW2V Accessor Functions

=head3 XTWGetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Interface object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new()
 my $debugLog = $interface->XTWGetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;


 undef( $interface );

=head3 XTWGetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Interface object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $writeLog = $interface->XTWGetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $interface );

=head3 XTWGetStoreTitle

Description:

 Returns the _storeTitle member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $storeTitle = $interface->XTWGetStoreTitle();

 print( "Store Title Option: Enabled\n" ) if $storeTitle == 1;
 print( "Store Title Option: Disabled\n" ) if $storeTitle == 0;

 undef( $interface );

=head3 XTWGetStoreAbstract

Description:

 Returns the _storeAbstract member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $storeAbstract = $interface->XTWGetStoreAbstract();

 print( "Store Abstract Option: Enabled\n" ) if $storeAbsract == 1;
 print( "Store Abstract Option: Disabled\n" ) if $storeAbstract == 0;

 undef( $interface );

=head3 XTWGetQuickParse

Description:

 Returns the _quickParse member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $quickParse = $interface->XTWGetQuickParse();

 print( "Quick Parse Option: Enabled\n" ) if $quickParse == 1;
 print( "Quick Parse Option: Disabled\n" ) if $quickParse == 0;

 undef( $interface );

=head3 XTWGetCompoundifyText

Description:

 Returns the _compoundifyText member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $compoundify = $interface->XTWGetCompoundifyText();

 print( "Compoundify Text Option: Enabled\n" ) if $compoundify == 1;
 print( "Compoundify Text Option: Disabled\n" ) if $compoundify == 0;

 undef( $interface );

=head3 XTWGetStoreAsSentencePerLine

Description:

 Returns the _storeAsSentencePerLine member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $storeAsSentencePerLine = $interface->GetStoreAsSentencePerLine();

 print( "Store As Sentence Per Line: Enabled\n" )  if $storeAsSentencePerLine == 1;
 print( "Store As Sentence Per Line: Disabled\n" ) if $storeAsSentencePerLine == 0;

 undef( $interface );

=head3 XTWGetNumOfThreads

Description:

 Returns the _numOfThreads member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> Number of threads

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $numOfThreads = $interface->XTWGetNumOfThreads();

 print( "Number of threads: $numOfThreads\n" );

 undef( $interface );

=head3 XTWGetWorkingDir

Description:

 Returns the _workingDir member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $string -> Working directory string

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $workingDirectory = $interface->XTWGetWorkingDir();

 print( "Working Directory: $workingDirectory\n" );

 undef( $interface );

=head3 XTWGetSavePath

Description:

 Returns the _saveDir member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $string -> Save directory string

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $savePath = $interface->XTWGetSavePath();

 print( "Save Directory: $savePath\n" );

 undef( $interface );

=head3 XTWGetBeginDate

Description:

 Returns the _beginDate member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $date -> Beginning date range - Format: XX/XX/XXXX (Mon/Day/Year)

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $date = $interface->XTWGetBeginDate();

 print( "Date: $date\n" );

 undef( $interface );

=head3 XTWGetEndDate

Description:

 Returns the _endDate member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $date -> End date range - Format: XX/XX/XXXX (Mon/Day/Year).

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $date = $interface->XTWGetEndDate();

 print( "Date: $date\n" );

 undef( $interface );

=head3 XTWGetXMLStringToParse

Returns the XML data (string) to be parsed.

Description:

 Returns the _xmlStringToParse member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $string -> Medline XML data string

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $xmlStr = $interface->XTWGetXMLStringToParse();

 print( "XML String: $xmlStr\n" );

 undef( $interface );

=head3 XTWGetTextCorpusStr

Description:

 Returns the _textCorpusStr member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $string -> Text corpus string

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $str = $interface->XTWGetTextCorpusStr();

 print( "Text Corpus: $str\n" );

 undef( $interface );

=head3 XTWGetFileHandle

Description:

 Returns the _fileHandle member variable set during Word2vec::Interface object instantiation of new function.

 Warning: This is a private function. File handle is used by 'xmltow2v::WriteLog()' method. Do not manipulate this file handle as errors can result.

Input:

 None

Output:

 $fileHandle -> Returns file handle for WriteLog() method.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $fileHandle = $interface->XTWGetFileHandle();

 undef( $interface );

=head3 XTWGetTwigHandler

Returns XML::Twig handler.

Description:

 Returns the _twigHandler member variable set during Word2vec::Interface object instantiation of new function.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Output:

 $twigHandler -> XML::Twig handler.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $xmlHandler = $interface->XTWGetTwigHandler();

 undef( $interface );

=head3 XTWGetParsedCount

Description:

 Returns the _parsedCount member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $value -> Number of parsed Medline articles.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $numOfParsed = $interface->XTWGetParsedCount();

 print( "Number of parsed Medline articles: $numOfParsed\n" );

 undef( $interface );

=head3 XTWGetTempStr

Description:

 Returns the _tempStr member variable set during Word2vec::Interface object instantiation of new function.

 Warning: This is a private function and should not be called or manipulated. Used by module as a temporary storage
          location for parsed Medline 'Title' and 'Abstract' flag string data.

Input:

 None

Output:

 $string -> Temporary string storage location.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $tempStr = $interface->XTWGetTempStr();

 print( "Temp String: $tempStr\n" );

 undef( $interface );

=head3 XTWGetTempDate

Description:

 Returns the _tempDate member variable set during Word2vec::Interface object instantiation of new function.
 Used by module as a temporary storage location for parsed Medline 'DateCreated' flag string data.

Input:

 None

Output:

 $date -> Date string - Format: XX/XX/XXXX (Mon/Day/Year).

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $date = $interface->XTWGetTempDate();

 print( "Temp Date: $date\n" );

 undef( $interface );

=head3 XTWGetCompoundWordAry

Description:

 Returns the _compoundWordAry member array reference set during Word2vec::Interface object instantiation of new function.

 Warning: Compound word data must be loaded in memory first via XTWReadCompoundWordDataFromFile().

Input:

 None

Output:

 $arrayReference -> Compound word array reference.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $arrayReference = $interface->XTWGetCompoundWordAry();
 my @compoundWord = @{ $arrayReference };

 print( "Compound Word Array: @compoundWord\n" );

 undef( $interface );

=head3 XTWGetCompoundWordBST

Description:

 Returns the _compoundWordBST member variable set during Word2vec::Interface object instantiation of new function.

Input:

 None

Output:

 $bst -> Compound word binary search tree.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $bst = $interface->XTWGetCompoundWordBST();

 undef( $interface );

=head3 XTWGetMaxCompoundWordLength

Description:

 Returns the _maxCompoundWordLength member variable set during Word2vec::Interface object instantiation of new function.

 Note: If not defined, it is automatically set to and returns 20.

Input:

 None

Output:

 $value -> Maximum number of compound words in a given phrase.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $compoundWordLength = $interface->XTWGetMaxCompoundWordLength();

 print( "Maximum Compound Word Length: $compoundWordLength\n" );

 undef( $interface );

=head3 XTWGetOverwriteExistingFile

Description:

 Returns the _overwriteExisitingFile member variable set during Word2vec::Interface object instantiation of new function.
 Enables overwriting of existing text corpus if set to '1' or appends to the existing text corpus if set to '0'.

Input:

 None

Output:

 $value -> '1' = Overwrite existing file / '0' = Append to exiting file.

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 my $overwriteExitingFile = $interface->XTWGetOverwriteExistingFile();

 print( "Overwrite Existing File? YES\n" ) if ( $overwriteExistingFile == 1 );
 print( "Overwrite Existing File? NO\n" ) if ( $overwriteExistingFile == 0 );

 undef( $interface );

=head2 XMLToW2V Mutator Functions

=head3 XTWSetStoreTitle

Description:

 Sets member variable to passed integer parameter. Instructs module to store article title if true or omit if false.

Input:

 $value -> '1' = Store Titles / '0' = Omit Titles

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetStoreTitle( 1 );

 undef( $interface );

=head3 XTWSetStoreAbstract

Description:

 Sets member variable to passed integer parameter. Instructs module to store article abstracts if true or omit if false.

Input:

 $value -> '1' = Store Abstracts / '0' = Omit Abstracts

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetStoreAbstract( 1 );

 undef( $interface );

=head3 XTWSetWorkingDir

Description:

 Sets member variable to passed string parameter. Represents the working directory.

Input:

 $string -> Working directory string

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetWorkingDir( "/samples/" );

 undef( $interface );

=head3 XTWSetSavePath

Description:

 Sets member variable to passed integer parameter. Represents the text corpus save path.

Input:

 $string -> Text corpus save path

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetSavePath( "samples/textcorpus.txt" );

 undef( $interface );

=head3 XTWSetQuickParse

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize quick parse
 routines to speed up text corpus compilation. This method is somewhat less accurate due to its non-exhaustive nature.

Input:

 $value -> '1' = Enable Quick Parse / '0' = Disable Quick Parse

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetQuickParse( 1 );

 undef( $interface );

=head3 XTWSetCompoundifyText

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize 'compoundify' option if true.

 Warning: This requires compound word data to be loaded into memory with XTWReadCompoundWordDataFromFile() method prior
          to executing text corpus compilation.

Input:

 $value -> '1' = Compoundify text / '0' = Do not compoundify text

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetCompoundifyText( 1 );

 undef( $interface );

=head3 XTWSetStoreAsSentencePerLine

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize 'storeAsSentencePerLine' option if true.

Input:

 $value -> '1' = Store as sentence per line / '0' = Do not store as sentence per line

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetStoreAsSentencePerLine( 1 );

 undef( $interface );

=head3 XTWSetNumOfThreads

Description:

 Sets member variable to passed integer parameter. Sets the requested number of threads to parse Medline XML files
 and compile the text corpus.

Input:

 $value -> Integer (Positive value)

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetNumOfThreads( 4 );

 undef( $interface );

=head3 XTWSetBeginDate

Description:

 Sets member variable to passed string parameter. Sets beginning date range for earliest articles to store, by
 'DateCreated' Medline tag, within the text corpus during compilation.

 Note: Expected format - "XX/XX/XXXX" (Mon/Day/Year)

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetBeginDate( "01/01/2004" );

 undef( $interface );

=head3 XTWSetEndDate

Description:

 Sets member variable to passed string parameter. Sets ending date range for latest article to store, by
 'DateCreated' Medline tag, within the text corpus during compilation.

 Note: Expected format - "XX/XX/XXXX" (Mon/Day/Year)

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetEndDate( "08/13/2016" );

 undef( $interface );

=head3 XTWSetXMLStringToParse

Description:

 Sets member variable to passed string parameter. This string normally consists of Medline XML data to be
 parsed for text corpus compilation.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetXMLStringToParse( "Hello World!" );

 undef( $interface );

=head3 XTWSetTextCorpusStr

Description:

 Sets member variable to passed string parameter. Overwrites any stored text corpus data in memory to the string parameter.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetTextCorpusStr( "Hello World!" );

 undef( $interface );

=head3 XTWAppendStrToTextCorpus

Description:

 Sets member variable to passed string parameter. Appends string parameter to text corpus string in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWAppendStrToTextCorpus( "Hello World!" );

 undef( $interface );

=head3 XTWClearTextCorpus

Description:

 Clears text corpus data in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWClearTextCorpus();

 undef( $interface );

=head3 XTWSetTempStr

Description:

 Sets member variable to passed string parameter. Sets temporary member string to passed string parameter.
 (Temporary placeholder for Medline Title and Abstract data).

 Note: This removes special characters and converts all characters to lowercase.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetTempStr( "Hello World!" );

 undef( $interface );

=head3 XTWAppendToTempStr

Description:

 Appends string parameter to temporary member string in memory.

 Note: This removes special characters and converts all characters to lowercase.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWAppendToTempStr( "Hello World!" );

 undef( $interface );

=head3 XTWClearTempStr

 Clears the temporary string storage in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWClearTempStr();

 undef( $interface );

=head3 XTWSetTempDate

Description:

 Sets member variable to passed string parameter. Sets temporary date string to passed string.

 Note: Date Format - "XX/XX/XXXX" (Mon/Day/Year)

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetTempDate( "08/13/2016" );

 undef( $interface );

=head3 XTWClearTempDate

Description:

 Clears the temporary date storage location in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWClearTempDate();

 undef( $interface );

=head3 XTWSetCompoundWordAry

Description:

 Sets member variable to de-referenced passed array reference parameter. Stores compound word array by
 de-referencing array reference parameter.

 Note: Clears previous data if existing.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $arrayReference -> Array reference of compound words

Ouput:

 None

Example:

 use Word2vec::Interface;

 my @compoundWordAry = ( "big dog", "respiratory failure", "seven large masses" );

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetCompoundWordAry( \@compoundWordAry );

 undef( $interface );

=head3 XTWClearCompoundWordAry

Description:

 Clears compound word array in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWClearCompoundWordAry();

 undef( $interface );

=head3 XTWSetCompoundWordBST

Description:

 Sets member variable to passed Word2vec::Bst parameter. Sets compound word binary search tree to passed binary tree parameter.

 Note: Un-defines previous binary tree if existing.

 Warning: This is a private function and should not be called or manipulated.

Input:

 Word2vec::Bst -> Binary Search Tree

Ouput:

 None

Example:

 use Word2vec::Interface;

 my @compoundWordAry = ( "big dog", "respiratory failure", "seven large masses" );
 @compoundWordAry = sort( @compoundWordAry );

 my $arySize = @compoundWordAry;

 my $bst = Word2vec::Bst;
 $bst->CreateTree( \@compoundWordAry, 0, $arySize, undef );

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetCompoundWordBST( $bst );

 undef( $interface );

=head3 XTWClearCompoundWordBST

Description:

 Clears/Un-defines existing compound word binary search tree from memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWClearCompoundWordBST();

 undef( $interface );

=head3 XTWSetMaxCompoundWordLength

Description:

 Sets member variable to passed integer parameter. Sets maximum number of compound words in a phrase for comparison.

 ie. "medical campus of Virginia Commonwealth University" can be interpreted as a compound word of 6 words.
 Setting this variable to 3 will only attempt compoundifying a maximum amount of three words.
 The result would be "medical_campus_of Virginia commonwealth university" even-though an exact representation
 of this compounded string can exist. Setting this variable to 6 will result in compounding all six words if
 they exists in the compound word array/bst.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $value -> Integer

Ouput:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetMaxCompoundWordLength( 8 );

 undef( $interface );

=head3 XTWSetOverwriteExistingFile

Description:

 Sets member variable to passed integer parameter. Sets option to overwrite existing text corpus during compilation
 if 1 or append to existing text corpus if 0.

Input:

 $value -> '1' = Overwrite existing text corpus / '0' = Append to existing text corpus during compilation.

Output:

 None

Example:

 use Word2vec::Interface;

 my $interface = Word2vec::Interface->new();
 $interface->XTWSetOverWriteExistingFile( 1 );

 undef( $xmltow2v );

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
