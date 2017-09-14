#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    06/16/2016                                                             #
#    Revised: 02/06/2017                                                             #
#    UMLS Similarity Word2Phrase Executable Interface Module                         #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Perl "word2phrase" executable interface for UMLS Similarity        #
#    Features:                                                                       #
#    =========                                                                       #
#                 Supports Word2Phrase Training Using Standard Options               #
#                                                                                    #
######################################################################################


package Word2vec::Word2phrase;

use strict;
use warnings;

# Standard Package(s)
use Cwd;


use vars qw($VERSION);

$VERSION = '0.02';


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
        _debugLog           => shift,               # Boolean (Binary): 0 = False, 1 = True
        _writeLog           => shift,               # Boolean (Binary): 0 = False, 1 = True
        _trainFilePath      => shift,               # String
        _outputFilePath     => shift,               # String
        _minCount           => shift,               # Int
        _threshold          => shift,               # Int
        _setW2PDebug        => shift,               # Int
        _workingDir         => shift,               # String
        _word2PhraseExeDir  => shift,               # String
        _overwriteOldFile   => shift,               # Int
    };

    # Set debug log variable to false if not defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _trainFilePath } = "" if !defined ( $self->{ _trainFilePath } );
    $self->{ _outputFilePath } = "" if !defined ( $self->{ _outputFilePath } );
    $self->{ _minCount } = 5 if !defined ( $self->{ _minCount } );
    $self->{ _threshold } = 100 if !defined ( $self->{ _threshold } );
    $self->{ _setW2PDebug } = 2 if !defined ( $self->{ _setW2PDebug } );
    $self->{ _workingDir } = Cwd::getcwd() if !defined ( $self->{ _workingDir } );
    $self->{ _overwriteOldFile } = 0 if !defined ( $self->{ _overwriteOldFile } );


    # Try To Locate Word2Vec Executable Files Path
    for my $dir ( @INC )
    {
        $self->{ _word2PhraseExeDir } = "$dir/External/Word2vec" if ( -e "$dir/External/Word2vec" );                       # Test Directory
        $self->{ _word2PhraseExeDir } = "$dir/../External/Word2vec" if ( -e "$dir/../External/Word2vec" );                 # Dev Directory
        $self->{ _word2PhraseExeDir } = "$dir/../../External/Word2vec" if ( -e "$dir/../../External/Word2vec" );           # Dev Directory
        $self->{ _word2PhraseExeDir } = "$dir/Word2vec/External/Word2vec" if ( -e "$dir/Word2vec/External/Word2vec" );     # Release Directory
    }

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', 'Word2phraseLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );
    $self->WriteLog( "New - Word2Phrase Executable Directory Found" ) if defined( $self->{ _word2PhraseExeDir } );
    $self->WriteLog( "New - Setting Word2Phrase Executable Directory To: \"" . $self->{ _word2PhraseExeDir } . "\"" ) if defined( $self->{ _word2PhraseExeDir } );

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
    my ( $self, $trainFilePath, $outputFilePath, $minCount, $threshold, $debug, $overwrite ) = @_;

    # Pre-Training Check(s)
    my $executableFileDir = $self->GetWord2PhraseExeDir() . "/word2phrase";
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

    # Check For 'word2phrase' Executable and trainFile
    $self->WriteLog( "ExecuteTraining - Error: \"word2phrase\" Executable File Cannot Be Found" ) if !( -e $executableFileDir );
    return -1 if !( -e $executableFileDir );
    $self->WriteLog( "ExecuteTraining - Error: Training File Not Found" ) if !( -e "$trainFilePath" );
    $self->WriteLog( "ExecuteTraining - Error: Training File Size = 0 bytes - No Data In Training File" ) if ( -z "$trainFilePath" );
    return -1 if !( -e "$trainFilePath" ) || ( -z "$trainFilePath" );

    # Checks For Existing Output File And Returns -1 If Overwrite Option Is Not Enabled
    $self->WriteLog( "ExecuteTraining - Warning: \"$outputFilePath\" Already Exists - Canceling Training" ) if ( -e "$outputFilePath" && $overwrite == 0 );
    $self->WriteLog( "ExecuteTraining - Try Enabling \"Overwrite\" Option or Delete \"$outputFilePath\" In Working Directory" ) if ( -e "$outputFilePath" && $overwrite == 0 );
    return -1 if ( -e "$outputFilePath" && $overwrite == 0 );

    # Fetch Other Training Parameters
    $self->WriteLog( "ExecuteTraining - \"MinCount\" Parameter Defined / Overriding Member Variable" ) if defined( $minCount );
    $minCount = $self->GetMinCount() if !defined( $minCount );

    $self->WriteLog( "ExecuteTraining - \"Threshold\" Parameter Defined / Overriding Member Variable" ) if defined( $threshold );
    $threshold = $self->GetThreshold() if !defined( $threshold );

    $self->WriteLog( "ExecuteTraining - \"Debug\" Parameter Defined / Overriding Member Variable" ) if defined( $debug );
    $debug = $self->GetW2PDebug() if !defined( $debug );

    # Setting Up Command String
    my $command = "\"$executableFileDir\" ";
    $command .= ( "-train \"" . $trainFilePath. "\" " );
    $command .= ( "-output \"" . $outputFilePath . "\" " );
    $command .= ( "-min-count " . $minCount . " " );
    $command .= ( "-threshold " . $threshold . " " );
    $command .= ( "-debug " . $debug . " " );

    $self->WriteLog( "Executing Command: $command" );

    # Execute External System Command To Train "word2vec"
    # Execute command without capturing program output
    my $result = system( "$command" );

    print "\n";

    # Post-Training Check(s)
    $self->WriteLog( "ExecuteTraining - Error: Unable To Spawn Executable File - Try Running '--clean' Command And Re-compile Executables" ) if ( $result == 65280 );

    $self->WriteLog( "ExecuteTraining - Error: Word2Phrase Output File Does Not Exist" ) if !( -e "$outputFilePath" );
    $self->WriteLog( "ExecuteTraining - Error: Word2Phrase Output File Size = Zero" ) if ( -z "$outputFilePath" );
    $result = -1 if ( !( -e "$outputFilePath" ) || ( -z "$outputFilePath" ) );

    $self->WriteLog( "ExecuteTraining - Training Successful" ) if $result == 0 && ( -e "$outputFilePath" );
    $self->WriteLog( "ExecuteTraining - Training Unsuccessful" ) if $result != 0;

    return $result;
}

sub ExecuteStringTraining
{
    my ( $self, $trainingStr, $outputFilePath, $minCount, $threshold, $debug, $overwrite ) = @_;

    # Check(s)
    $self->WriteLog( "ExecuteStringTraining - Error: Training String Is Not Defined" ) if !defined( $trainingStr );
    return -1 if !defined( $trainingStr );

    $self->WriteLog( "ExecuteStringTraining - Error: Training String Is Empty" ) if ( $trainingStr eq "" );
    return -1 if ( $trainingStr eq "" );

    # Save Training String To Temporary File
    my $result = 0;

    $self->WriteLog( "ExecuteStringTraining - Saving Training String To Temporary File At Working Directory: \"" . $self->GetWorkingDir() . "\"" );

    my $tempFilePath = $self->GetWorkingDir() . "/w2ptemp.txt";
    open( my $fileHandle, ">:encoding(utf8)", "$tempFilePath" ) or $result = -1;

    $self->WriteLog( "ExecuteStringTraining - Error Creating File Handle : $!" ) if ( $result == -1 );
    return -1 if ( $result == -1 );

    # Print Training String Data To File
    print( $fileHandle "$trainingStr" ) if defined( $fileHandle );

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "ExecuteStringTraining - Temporary Training String File Saved" );

    $result = $self->ExecuteTraining( "$tempFilePath", $outputFilePath, $minCount, $threshold, $debug, $overwrite );

    $self->WriteLog( "ExecuteStringTraining - Removing Temporary Training String Data File" );
    unlink( $tempFilePath );

    $self->WriteLog( "ExecuteStringTraining - Finished" ) if ( $result == 0 );
    $self->WriteLog( "ExecuteStringTraining - Finished With Errors" ) if ( $result == -1 && $self->GetWriteLog() == 0 );
    $self->WriteLog( "ExecuteStringTraining - Finished With Errors / See Log File For Details" ) if ( $result == -1 && $self->GetWriteLog() == 1 ) ;

    return $result;
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
    $self->{ _trainFilePath } = "" if !defined ( $self->{ _trainFilePath } );
    return $self->{ _trainFilePath };
}

sub GetOutputFilePath
{
    my ( $self ) = @_;
    $self->{ _outputFilePath } = "" if !defined ( $self->{ _outputFilePath } );
    return $self->{ _outputFilePath };
}

sub GetMinCount
{
    my ( $self ) = @_;
    $self->{ _minCount } = 5 if !defined ( $self->{ _minCount } );
    return $self->{ _minCount };
}

sub GetThreshold
{
    my ( $self ) = @_;
    $self->{ _threshold } = 100 if !defined ( $self->{ _threshold } );
    return $self->{ _threshold };
}

sub GetW2PDebug
{
    my ( $self ) = @_;
    $self->{ _setW2PDebug } = 2 if !defined ( $self->{ _setW2PDebug } );
    return $self->{ _setW2PDebug };
}

sub GetWorkingDir
{
    my ( $self ) = @_;
    $self->{ _workingDir } = Cwd::getcwd() if !defined ( $self->{ _workingDir } );
    return $self->{ _workingDir };
}

sub GetWord2PhraseExeDir
{
    my ( $self ) = @_;
    $self->{ _word2PhraseExeDir } = Cwd::getcwd() if !defined ( $self->{ _word2PhraseExeDir } );
    return $self->{ _word2PhraseExeDir };
}

sub GetOverwriteOldFile
{
    my ( $self ) = @_;
    $self->{ _overwriteOldFile } = 0 if !defined ( $self->{ _overwriteOldFile } );
    return $self->{ _overwriteOldFile };
}


######################################################################################
#    Mutators
######################################################################################

sub SetTrainFilePath
{
    my ( $self, $temp ) = @_;
    return $self->{ _trainFilePath } = $temp if defined ( $temp );
}

sub SetOutputFilePath
{
    my ( $self, $temp ) = @_;
    return $self->{ _outputFilePath } = $temp if defined ( $temp );
}

sub SetMinCount
{
    my ( $self, $temp ) = @_;
    return $self->{ _minCount } = $temp if defined ( $temp );
}

sub SetThreshold
{
    my ( $self, $temp ) = @_;
    return $self->{ _threshold } = $temp if defined ( $temp );
}

sub SetW2PDebug
{
    my ( $self, $temp ) = @_;
    return $self->{ _setW2PDebug } = $temp if defined ( $temp );
}

sub SetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->{ _workingDir } = $dir if defined ( $dir );
}

sub SetWord2PhraseExeDir
{
    my ( $self, $dir ) = @_;
    return $self->{ _word2PhraseExeDir } = $dir if defined ( $dir );
}

sub SetOverwriteOldFile
{
    my ( $self, $dir ) = @_;
    return $self->{ _overwriteOldFile } = $dir if defined ( $dir );
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
        if( ref ( $self ) ne "Word2vec::Word2phrase" )
        {
            print( GetDate() . " " . GetTime() . " - word2phrase: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - word2phrase::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Word2phrase" )
        {
            print( GetDate() . " " . GetTime() . " - word2phrase: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - word2phrase::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Word2phrase - word2vec's word2phrase wrapper module.

=head1 SYNOPSIS

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetMinCount( 12 );
 $w2p->SetMaxCount( 20 );
 $w2p->SetTrainFilePath( "textCorpus.txt" );
 $w2p->SetOutputFilePath( "phraseTextCorpus.txt" );
 $w2p->ExecuteTraining();
 undef( $w2p );

 # or

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->ExecuteTraining( $trainFilePath, $outputFilePath, $minCount, $threshold, $debug, $overwrite );
 undef( $w2p );

=head1 DESCRIPTION

Word2vec::Word2phrase is a word2vec package tool that "compoundifies" bi-grams in a text corpus based on a minimum and maximum frequency.

=head2 Main Functions

=head3 new

Description:

 Returns a new 'Word2vec::Word2phrase' module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog                    = 0
    writeLog                    = 0
    trainFilePath               = ""
    outputFilePath              = ""
    minCount                    = 5
    threshold                   = 100
    setW2PDebug                 = 2
    workingDir                  = Current Directory
    word2PhraseExeDir           = Word2Phrase Executable Directory
    overwriteOldFile            = 0

Input:

 $debugLog                    -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. (1 = True / 0 = False)
 $trainFilePath               -> Specifies the training text corpus for word2phrase training. (String)
 $outputFilePath              -> Specifies the output path for post word2phrase training. (String)
 $minCount                    -> Specifies the minimum range value for bi-gram 'compoundification'. (Positive Integer)
 $threshold                   -> Specifies the maximum range value for bi-gram 'compoundification'. (Positive Integer)
 $setW2PDebug                 -> Specifies the word2phrase debug information parameter value to show during training. (Integer)
 $workingDir                  -> Specifies the current working directory. (String)
 $word2PhraseExeDir           -> Specifies word2phrase executable directory. (String)
 $overwriteOldFile            -> Instructs the module to either overwrite any existing data with the same output file name and path. ( '1' or '0' )

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested.

Output:

 Word2vec::Word2phrase object.

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();

 undef( $w2p );

=head3 DESTROY

Description:

 Removes member variables and file handle from memory.

Input:

 None

Output:

 None

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();

 $w2p->DESTROY();
 undef( $w2p );

=head3 ExecuteTraining

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

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetMinCount( 12 );
 $w2p->SetMaxCount( 20 );
 $w2p->SetTrainFilePath( "textCorpus.txt" );
 $w2p->SetOutputFilePath( "phraseTextCorpus.txt" );
 $w2p->ExecuteTraining();
 undef( $w2p );

 # Or

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->ExecuteTraining( "textCorpus.txt", "phraseTextCorpus.txt", 12, 20, 2, 1 );
 undef( $w2p );

=head3 ExecuteStringTraining

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

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetMinCount( 12 );
 $w2p->SetMaxCount( 20 );
 $w2p->SetTrainFilePath( "large string to train here" );
 $w2p->SetOutputFilePath( "phraseTextCorpus.txt" );
 $w2p->ExecuteTraining();
 undef( $w2p );

 # Or

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->ExecuteTraining( "large string to train here", "phraseTextCorpus.txt", 12, 20, 2, 1 );
 undef( $w2p );

=head3 GetOSType

Description:

 Returns the operating system type string.

Input:

 None

Output:

 $string -> Operating system string.

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $operatingSystem = $w2p->GetOSType();
 print( "Operating System: $operatingSystem\n" ) if defined( $operatingSystem );
 undef( $w2p );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $debugLog = $w2p->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $w2p );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Word2phrase object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $writeLog = $w2p->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $w2p );

=head3 GetFileHandle

Description:

 Returns file handle used by WriteLog() method.

Input:

 None

Output:

 $fileHandle -> Returns file handle blob used by 'WriteLog()' function or undefined.

Example:

 <This should not be called.>

=head3 GetTrainFilePath

Description:

 Returns (string) training file path.

Input:

 None

Output:

 $string -> word2phrase training file path

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $filePath = $w2p->GetTrainFilePath();

 print( "Output File Path: $filePath\n" ) if defined( $filePath );
 undef( $w2p );

=head3 GetOutputFilePath

Description:

 Returns (string) output file path.

Input:

 None

Output:

 $string -> word2phrase output file path

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $filePath = $w2p->GetOutputFilePath();

 print( "Output File Path: $filePath\n" ) if defined( $filePath );
 undef( $w2p );

=head3 GetMinCount

Description:

 Returns (integer) minimum bi-gram range.

Input:

 None

Output:

 $value ->  Minimum bi-gram frequency (Positive Integer)

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $mincount = $w2p->GetMinCount();

 print( "MinCount: $mincount\n" ) if defined( $mincount );
 undef( $w2p );

=head3 GetThreshold

Description:

 Returns (integer) maximum bi-gram range.

Input:

 None

Output:

 $value ->  Maximum bi-gram frequency (Positive Integer)

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $mincount = $w2p->GetThreshold();

 print( "MinCount: $mincount\n" ) if defined( $mincount );
 undef( $w2p );

=head3 GetW2PDebug

Description:

 Returns word2phrase debug parameter value.

Input:

 None

Output:

 $value -> 0 = No debugging, 1 = Show debugging, 2 = Show even more debugging

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $w2pdebug = $w2p->GetW2PDebug();

 print( "Word2Phrase Debug Level: $w2pdebug\n" ) if defined( $w2pdebug );

 undef( $w2p );

=head3 GetWorkingDir

Description:

 Returns (string) working directory path.

Input:

 None

Output:

 $string -> Current working directory path

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $workingDir = $w2p->GetWorkingDir();

 print( "Working Directory: $workingDir\n" ) if defined( $workingDir );

 undef( $w2p );

=head3 GetWord2PhraseExeDir

Description:

 Returns (string) word2phrase executable directory path.

Input:

 None

Output:

 $string -> Word2Phrase executable directory path

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $workingDir = $w2p->GetWord2PhraseExeDir();

 print( "Word2Phrase Executable Directory: $workingDir\n" ) if defined( $workingDir );

 undef( $w2p );

=head3 GetOverwriteOldFile

Description:

 Returns the current value of the overwrite training file variable.

Input:

 None

Output:

 $value -> 1 = True/Overwrite or 0 = False/Append to current file

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 my $overwrite = $w2p->GetOverwriteOldFile();

 if defined( $overwrite )
 {
    print( "Overwrite Old File: " );
    print( "Yes\n" ) if $overwrite == 1;
    print( "No\n" ) if $overwrite == 0;
 }

 undef( $w2p );

=head2 Mutator Functions

=head3 SetTrainFilePath

Description:

 Sets training file path.

Input:

 $string -> Training file path

Output:

 None

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetTrainFilePath( "filePath" );

 undef( $w2p );

=head3 SetOutputFilePath

Description:

 Sets word2phrase output file path.

Input:

 $string -> word2phrase output file path

Output:

 None

Example:

 use Word2vec::Word2phrase;

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetOutputFilePath( "filePath" );

 undef( $w2p );

=head3 SetMinCount

Description:

 Sets minimum range value.

Input:

 $value -> Minimum frequency value (Positive integer)

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetMinCount( 1 );

 undef( $w2p );

=head3 SetThreshold

Description:

 Sets maximum range value.

Input:

 $value -> Maximum frequency value (Positive integer)

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetThreshold( 100 );

 undef( $w2p );

=head3 SetW2PDebug

Description:

 Sets word2phrase debug parameter.

Input:

 $value -> word2phrase debug parameter (0 = No debug info, 1 = Show debug info, 2 = Show more debug info.)

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetW2PDebug( 2 );

 undef( $w2p );

=head3 SetWorkingDir

Description:

 Sets working directory path.

Input:

 $string -> Current working directory path.

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetWorkingDir( "filePath" );

 undef( $w2p );

=head3 SetWord2PhraseExeDir

Description:

 Sets word2phrase executable file directory path.

Input:

 $string -> Word2Phrase executable directory path.

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetWord2PhraseExeDir( "filePath" );

 undef( $w2p );

=head3 SetOverwriteOldFile

Description:

 Enables overwriting word2phrase output file if one already exists with the same output file name.

Input:

 $value -> Integer: 1 = Overwrite old file, 0 = No not overwrite old file.

Output:

 None

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->SetOverwriteOldFile( 1 );

 undef( $w2p );

=head2 Debug Functions

=head3 GetTime

Description:

 Returns current time string in "Hour:Minute:Second" format.

Input:

 None

Output:

 $string -> XX:XX:XX ("Hour:Minute:Second")

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 my $time = $w2p->GetTime();

 print( "Current Time: $time\n" ) if defined( $time );

 undef( $w2p );

=head3 GetDate

Description:

 Returns current month, day and year string in "Month/Day/Year" format.

Input:

 None

Output:

 $string -> XX/XX/XXXX ("Month/Day/Year")

Example:

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 my $date = $w2p->GetDate();

 print( "Current Date: $date\n" ) if defined( $date );

 undef( $w2p );

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

 use Word2vec::Word2phrase:

 my $w2p = Word2vec::Word2phrase->new();
 $w2p->WriteLog( "Hello World" );

 undef( $w2p );

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
