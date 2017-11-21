#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    06/16/2016                                                             #
#    Revised: 10/10/2017                                                             #
#    UMLS Similarity - Medline XML-To-Word2Vec Input Format Conversion Module        #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Perl Medline XML-To-Word2Vec Input Format Conversion Module        #
#                 for the "word2vec" package.                                        #
#    Features:                                                                       #
#    =========                                                                       #
#                 Supports Parsing Individual Files or Directories                   #
#                 Plain XML files or .gz XML files (extracts and processes in RAM)   #
#                 Include results by specified Date Ranges: 00/00/0000 Format        #
#                 Include results by title, abstract or both per article             #
#                 Multi-Threading Support - Divides work by number of threads        #
#                 Text Compoundify                                                   #
#                                                                                    #
######################################################################################


package Word2vec::Xmltow2v;

use strict;
use warnings;

# Standard Package(s)
use utf8;
use threads;
use threads::shared;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

# CPAN Package(s)
use Cwd;
use File::Type;
use Text::Unidecode;
use XML::Twig;
use Sys::CpuAffinity;

# Word2Vec Utility Package(s)
use Word2vec::Bst;


use vars qw($VERSION);

$VERSION = '0.021';


# Global Variables
my $debugLock         :shared;
my $writeLock         :shared;
my $queueLock         :shared;
my $appendLock        :shared;
my @xmlJobQueue       :shared;
my $totalJobCount     :shared;
my $finishedJobCount  :shared;
my $preCompWordCount  :shared;
my $postCompWordCount :shared;
my $compoundWordCount :shared;


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
        _debugLog               => shift,                # Boolean (Binary): 0 = False, 1 = True
        _writeLog               => shift,                # Boolean (Binary): 0 = False, 1 = True
        _storeTitle             => shift,                # Boolean (Binary): 0 = False, 1 = True
        _storeAbstract          => shift,                # Boolean (Binary): 0 = False, 1 = True
        _quickParse             => shift,                # Boolean (Binary): 0 = False, 1 = True
        _compoundifyText        => shift,                # Boolean (Binary): 0 = False, 1 = True
        _storeAsSentencePerLine => shift,                # Boolean (Binary): 0 = False, 1 = True
        _numOfThreads           => shift,                # Integer
        _workingDir             => shift,                # String
        _savePath               => shift,                # String
        _beginDate              => shift,                # String Format: Month/Day/Year
        _endDate                => shift,                # String Format: Month/Day/Year
        _xmlStringToParse       => shift,                # String
        _textCorpusStr          => shift,                # String
        _fileHandle             => shift,                # File Handle
        _twigHandler            => shift,                # File Handle
        _parsedCount            => shift,                # Int
        _tempDate               => shift,                # String (Temporary Placeholder)
        _tempStr                => shift,                # String (Temporary Placeholder)
        _compoundWordAry        => shift,                # Array Of Compound Words
        _compoundWordBST        => shift,                # Binary Search Tree Reference
        _maxCompoundWordLength  => shift,                # Integer
        _overwriteExistingFile  => shift,                # Integer
        _compoundWordCount      => shift,                # Integer
    };

    # Set debug log variable to false if not defined
    $self->{ _debugLog }                    = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog }                    = 0 if !defined ( $self->{ _writeLog } );
    $self->{ _storeTitle }                  = 1 if !defined ( $self->{ _storeTitle } );
    $self->{ _storeAbstract }               = 1 if !defined ( $self->{ _storeAbstract } );
    $self->{ _quickParse }                  = 0 if !defined ( $self->{ _quickParse } );
    $self->{ _compoundifyText }             = 0 if !defined ( $self->{ _compoundifyText } );
    $self->{ _storeAsSentencePerLine }      = 0 if !defined ( $self->{ _storeAsSentencePerLine } );
    $self->{ _numOfThreads }                = Sys::CpuAffinity::getNumCpus() if !defined ( $self->{ _numOfThreads } );
    $self->{ _workingDir }                  = Cwd::getcwd() if !defined ( $self->{ _workingDir } );
    $self->{ _savePath }                    = Cwd::getcwd() if !defined ( $self->{ _savePath } );
    $self->{ _beginDate }                   = "00/00/0000" if !defined ( $self->{ _beginDate } );
    $self->{ _endDate }                     = "99/99/9999" if !defined ( $self->{ _endDate } );
    $self->{ _xmlStringToParse }            = "(null)" if !defined ( $self->{ _xmlStringToParse } );
    $self->{ _textCorpusStr }               = "" if !defined ( $self->{ _textCorpusStr } );
    $self->{ _twigHandler }                 = 0 if !defined ( $self->{ _twigHandler } );
    $self->{ _parsedCount }                 = 0 if !defined ( $self->{ _parsedCount } );
    $self->{ _tempDate }                    = "" if !defined ( $self->{ _tempDate } );
    $self->{ _tempStr }                     = "" if !defined ( $self->{ _tempStr } );
    $self->{ _outputFileName }              = "textcorpus.txt" if !defined ( $self->{ _outputFileName } );
    @{ $self->{ _compoundWordAry } }        = () if !defined ( $self->{ _compoundWordAry } );
    @{ $self->{ _compoundWordAry } }        = @{ $self->{ _compoundWordAry } } if defined ( $self->{ _compoundWordAry } );
    $self->{ _compoundWordBST }             = Word2vec::Bst->new() if !defined ( $self->{ _compoundWordBST } );
    $self->{ _maxCompoundWordLength }       = 20 if !defined ( $self->{ _maxCompoundWordLength } );
    $self->{ _overwriteExistingFile }       = 0 if !defined ( $self->{ _overwriteExistingFile } );
    
    # Initialize Thread Safe Counting Variables
    @xmlJobQueue       = ();
    $compoundWordCount = 0;
    $preCompWordCount  = 0;
    $postCompWordCount = 0;

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:utf8', 'Xmltow2vLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log
    }

    # Declare XML parser
    # Quick Parse Method(s): Much Faster With Less Hardware Requirements and Accuracy
    if( $self->{ _quickParse } == 1 )
    {
        $self->{ _twigHandler } = XML::Twig->new(
            twig_handlers =>
            {
                'DateCreated'   => sub { _QuickParseDateCreated( @_, $self ) },
                'Journal'       => sub { _QuickParseJournal( @_, $self ) },
                'Article'       => sub { _QuickParseArticle( @_, $self ) },
                'OtherAbstract' => sub { _QuickParseOtherAbstract( @_, $self ) },
            },
        );
    }
    # Default Parse Method: Much Slower With High RAM Requirements and Better Accuracy
    else
    {
        $self->{ _twigHandler } = XML::Twig->new(
            twig_handlers =>
            {
                'MedlineCitationSet' => sub { _ParseMedlineCitationSet( @_, $self ) },
            },
        );
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );
    $self->WriteLog( "New - QuickParse Enabled" ) if( $self->{ _quickParse } == 1 );

    if( $self->{ _xmlStringToParse } ne "(null)" )
    {
        #$self->_RemoveXMLVersion( \$self->{ _xmlStringToParse } );

        if( $self->_CheckForNullData ( $self->{ _xmlStringToParse } ) )
        {
            $self->WriteLog( "New - Error: XML String is null" );
        }
        else
        {
            $self->{ _twigHandler }->parse( $self->{ _xmlStringToParse } );
        }
    }
    else
    {
        $self->WriteLog( "New - No XML String Argument To Parse" );
    }

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

sub ConvertMedlineXMLToW2V
{
    my ( $self, $dir ) = @_;
    $dir = $self->GetWorkingDir() if !defined ( $dir );

    my $result = $self->_DateCheck();
    
    # Check(s)
    $self->WriteLog( "ConvertMedlineXMLToW2v - Error: Date Check Failed" ) if ( $result == -1 );
    return -1 if ( $result == -1 );
    
    $self->WriteLog( "ConvertMedlineXMLToW2V - Error: StoreTitle and StoreAbstract Variables Set To 0 - No Data Will Be Extracted" )
        if ( $self->GetStoreTitle() == 0 && $self->GetStoreAbstract() == 0 );
    return -1 if ( $self->GetStoreTitle() == 0 && $self->GetStoreAbstract() == 0 );

    # Check To See If Overwrite Existing File Option Is Enabled And Overwrite
    $self->WriteLog( "ConvertMedlineXMLToW2V - Overwrite Existing File Option Enabled" ) if $self->GetOverwriteExistingFile() == 1;
    $self->WriteLog( "ConvertMedlineXMLToW2V - Existing File Found - Removing Existing File" ) if ( $self->GetOverwriteExistingFile() == 1 && -e $self->GetSavePath() );
    unlink( $self->GetSavePath() ) if ( $self->GetOverwriteExistingFile() == 1 && -e $self->GetSavePath() );

    my $isFileOrDir = $self->IsFileOrDirectory( $dir );

    # Process File In Working Directory
    if( $isFileOrDir eq "file" )
    {
        $self->SetXMLStringToParse( $self->_ReadXMLDataFromFile( $dir ) );
        return -1 if ( $self->GetXMLStringToParse() ) eq "(null)";

        $self->WriteLog( "ConvertMedlineXMLToW2V - Parsing XML File: $dir" );
        $self->_ParseXMLString( $self->GetXMLStringToParse() );
        $self->_SaveTextCorpusToFile( $self->GetSavePath() );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Parsing Complete" );
    }
    # Process All Files In Directory
    elsif( $isFileOrDir eq "dir" )
    {
        $self->WriteLog( "ConvertMedlineXMLToW2V - No File Specified/Using Directory Option" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Obtaining File(s) In Directory" );

        # Read File Name(s) From Specified Directory
        opendir( my $dirHandle, "$dir" ) or $result = -1;
        $self->WriteLog( "ConvertMedlineXMLToW2V - Error: Can't open $dir: $!" ) if $result == -1;
        return -1 if $result == -1;

        for my $file ( readdir( $dirHandle ) )
        {
            push( @xmlJobQueue, $file ) if ( ( index( $file, ".xml" ) != -1 ) && ( index( $file, ".xml.gz") == -1 ) );
            push( @xmlJobQueue, $file ) if ( index( $file, ".gz" ) != -1 );
        }

        closedir $dirHandle;
        undef $dirHandle;
        
        # Set Total Job Count
        $totalJobCount = @xmlJobQueue;
        
        $self->WriteLog( "ConvertMedlineXMLToW2V - Parsing $totalJobCount File(s)" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Starting Worker Thread(s) / Compiling Text Corpus" );
        
        # Start Thread(s)
        for( my $i = 0; $i < $self->GetNumOfThreads(); $i++ )
        {
            my $thread = threads->create( "_ThreadedConvert", $self, $dir );
        }

        # Join All Running Threads Prior To Termination
        my @threadAry = threads->list();

        for my $thread ( @threadAry )
        {
            $thread->join() if ( $thread->is_running() || $thread->is_joinable() );
        }

        print( "Parsed $finishedJobCount of $totalJobCount Files\n" ) if ( $self->GetDebugLog() == 0 );
        print( "Number Of Compound Words: $compoundWordCount\n" ) if ( $self->GetDebugLog() == 0 );
        print( "Number Of Words (Before Compounding): $preCompWordCount\n" ) if ( $self->GetDebugLog() == 0 );
        print( "Number Of Words (After Compounding): $postCompWordCount\n" ) if ( $self->GetDebugLog() == 0 );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Parsed $finishedJobCount of $totalJobCount Files" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Number Of Compound Words: $compoundWordCount" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Number Of Words (Before Compounding): $preCompWordCount" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Number Of Words (After Compounding): $postCompWordCount" );
        $self->WriteLog( "ConvertMedlineXMLToW2V - Parsing Complete" );
        
        # Clean Up
        ClearTempStr();
        ClearTextCorpusStr();
        $totalJobCount     = 0;
        $preCompWordCount  = 0;
        $compoundWordCount = 0;
        $postCompWordCount = 0;
    }
    else
    {
        $self->WriteLog( "ConvertMedlineXMLToW2V - Unknown Parameter Type: Not File Or Directory" );
    }

    return 0;
}

sub _ThreadedConvert
{
    my ( $self, $dir ) = @_;

    my $keepWorking = 1;
    my $tid = threads->tid();

    $self->WriteLog( "_ThreadedConvert - Warning: Requested Thread $tid Not Needed/Threads Exceed Work Load - Terminating Thread" ) if ( @xmlJobQueue == 0 );
    return 1 if ( @xmlJobQueue == 0 );

    $self->WriteLog( "_ThreadedConvert - Starting Thread: $tid" );
    $self->WriteLog( "_ThreadedConvert - Thread $tid Parsing File(s) In Job Queue" );

    while( $keepWorking == 1 )
    {
        my $file;

        # Prevent Other Threads From Reading Shared Job Queue (Array) At The Same Time
        {
            lock( $queueLock );

            # Fetch A File Name To Parse
            my $index = 0;

            # Keep Iterating Through Queue While Elements Are Not Defined
            while( $index < @xmlJobQueue )
            {
                $file = $xmlJobQueue[$index];
                delete( $xmlJobQueue[$index] ) if defined( $file );

                # Exit Loop If Element Array Defined
                $index = @xmlJobQueue if defined( $file );

                $index++;
            }
            
            # Increment Parsed File Counter
            $finishedJobCount++ if defined( $file );

            # Exit The Main Loop If The Last Element Was Parsed
            $keepWorking = 0 if ( @xmlJobQueue == 0 );
        }

        if( defined( $file ) )
        {
            print( "Thread $tid: Parsing $file\n" ) if ( !$self->GetDebugLog() );
            $self->WriteLog( "_ThreadedConvert - Thread $tid: Processing File: $file" );
            $self->SetXMLStringToParse( $self->_ReadXMLDataFromFile( "$dir/$file" ) );
            $self->WriteLog( "_ThreadedConvert - Thread $tid: Parsing XML Data" );
            $self->_ParseXMLString( $self->GetXMLStringToParse() );
            $self->WriteLog( "_ThreadedConvert - Thread $tid: Parsed $file" );
            print( "Thread $tid: Parsed $file\n" ) if ( !$self->GetDebugLog() );
            $self->_SaveTextCorpusToFile( $self->GetSavePath(), 1 );
            $self->ClearTextCorpusStr();
        }
    }

    $self->WriteLog( "_ThreadedConvert - Thread $tid Finished - Terminating" );

    return 0;
}

sub _ParseXMLString
{
    my ( $self, $string ) = @_;
    $string = "" if !defined ( $string );

    if( $self->_CheckParseRequirements( $string ) eq -1 )
    {
        return -1;
    }

    # REMOVEME
    #$self->_RemoveXMLVersion( \$string );

    if( $self->_CheckForNullData( $string ) )
    {
        $self->WriteLog( "_ParseXMLString - Cannot Parse (null) string" );
        return -1;
    }
    else
    {
        $self->{ _twigHandler }->parse( $string );
        $self->WriteLog( "_ParseXMLString: Released PubmedArticle from memory" );

        # Print how many entries were parsed
        $self->WriteLog( "_ParseXMLString: Parsed " . $self->GetParsedCount()  . " entries" );
    }

    return 0;
}

sub _CheckParseRequirements
{
    my ( $self, $string ) = @_;
    $string = "" if !defined ( $string );

    if( $string eq "" )
    {
        $self->WriteLog( "_CheckParseRequirements - Error: Nothing To Parse" );
        return -1;
    }
    elsif( $self->GetTwigHandler() == 0 )
    {
        $self->WriteLog( "_CheckParseRequirements - Error: Unable To Parse XML Data/TwigHandler = (null)" );
        return -1;
    }

    return 0;
}

# Checks to see if Medline XML data in memory is a null string
sub _CheckForNullData
{
    my ( $self, $temp ) = @_;
    my $nullStr = "(null)";

    if( my $n = index( $temp, $nullStr ) != -1 )
    {
        # Return True
        return 1 if $n == 0;
    }

    # Return False
    return 0;
}

# Removes the XML Version string prior to parsing the XML string
sub _RemoveXMLVersion
{
    my ( $self, $temp ) = @_;

    # Checking For XML Version
    my $xmlVersion = '<?xml version="1.0"';
    my $docType = '!DOCTYPE';

    my $line = "";
    my $newXMLString = "";

    foreach $line ( split /\n/ , ${$temp} )
    {
        if( index( $line, $xmlVersion ) == -1 && index( $line, $docType ) == -1  )
        {
            $newXMLString .= ( $line . "\n" );
        }
    }

    ${$temp} = $newXMLString;
}

sub _ParseMedlineCitationSet
{
    my ( $twigSelf, $root, $self ) = @_;
    my @pubMedArticles = $root->children();

    my $parsedData = 0;

    foreach my $pubMedArticle ( @pubMedArticles )
    {
        # Parse XML Data
        $parsedData = $self->_ParseMedlineArticle( $pubMedArticle );

        # Compoundify String If Option Is Enabled
        if( $self->GetCompoundifyText() == 1 && ( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 ) )
        {
            my $tempStr = $self->CompoundifyString( lc( $self->GetTempStr() ) );

            # Append Article Data To Text Corpus
            $self->AppendStrToTextCorpus( $tempStr );
        }
        elsif( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 )
        {
            # Append Article Data To Text Corpus
            $self->AppendStrToTextCorpus( $self->GetTempStr() );
        }

        # Clear string placeholders
        $self->ClearTempStr();
        $self->ClearTempDate();

        # Increment Parsed Counter
        $self->{ _parsedCount }++ if ( $parsedData == 1 );

        # Release the stored XML section from memory (not fully tested)
        $pubMedArticle->purge() if defined( $pubMedArticle );

        # Reset Parsed Data Flag
        $parsedData = 0;
    }

    # Release the stored XML section from memory (not fully tested)
    $root->purge();
    $self->WriteLog( "_ParseMedlineCitationSet: Released PubmedArticleSet group from memory" );
}

sub _ParseMedlineArticle
{
    my ( $self, $medlineArticle ) = @_;

    my @articles = $medlineArticle->children();
    my $dateCreated = "";

    for my $article ( @articles )
    {
        if( $article->tag() eq "Article" )
        {
            $self->_ParseArticle( $article );
        }
        elsif( $article->tag() eq "DateCreated" )
        {
            $self->SetTempDate( $self->_ParseDateCreated( $article ) );
        }
        elsif( $article->tag() eq "OtherAbstract" )
        {
            $self->_ParseOtherAbstract( $article );
        }
        else
        {
            $self->WriteLog( "_ParseMedlineArticle - (New Data Found) - Tag: " . $article->tag() . ", Field: " . $article->field() );
        }

        # Release article from memory
        $article->purge();
    }

    return 1;
}

sub _ParseDateCreated
{
    my ( $self, $article ) = @_;

    my $month = "";
    my $day = "";
    my $year = "";

    my @dateAry = $article->children();

    for my $date ( @dateAry )
    {
        $day = $date->field() if ( $date->tag() eq "Day" );
        $month = $date->field if ( $date->tag() eq "Month" );
        $year = $date->field() if ( $date->tag() eq "Year" );
    }

    # Check(s)
    $day = "00" if !defined ( $day );
    $month = "00" if !defined ( $month );
    $year = "0000" if !defined ( $year );

    $self->WriteLog( "_ParseDateCreated - Month: $month, Day: $day, Year: $year " );

    return "$month/$day/$year";
}

sub _ParseArticle
{
    my ( $self, $article ) = @_;

    my @articleChildren = $article->children();

    for my $articleChild ( @articleChildren )
    {
        if( $articleChild->tag() eq "Journal" )
        {
            $self->_ParseJournal( $articleChild );
        }
        elsif( $articleChild->tag() eq "ArticleTitle" )
        {
            my $tempStr = Text::Unidecode::unidecode( $articleChild->field() );
            chomp( $tempStr );
            
            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreTitle() == 1 );

            $self->WriteLog( "_ParseArticle - Tag: " . $articleChild->tag() . ", Field: " . $tempStr );
        }
        elsif( $articleChild->tag() eq "Abstract" )
        {
            my $tempStr = Text::Unidecode::unidecode( $articleChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreAbstract() == 1 );

            $self->WriteLog( "_ParseArticle - Tag: " . $articleChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_ParseArticle - (New Tag Found) - Tag: " . $articleChild->tag() . ", Field: " . $articleChild->field() );
        }
    }
}

sub _ParseJournal
{
    my ( $self, $journalRoot ) = @_;

    my @journalChildren = $journalRoot->children();

    for my $journalChild ( @journalChildren )
    {
        if( $journalChild->tag() eq "Title" )
        {
            my $tempStr = Text::Unidecode::unidecode( $journalChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreTitle() == 1 );

            $self->WriteLog( "_ParseJournal - Tag: " . $journalChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_ParseJournal - (New Tag Found) - Tag: " . $journalChild->tag() . ", Field: " . $journalChild->field() );
        }
    }
}

sub _ParseOtherAbstract
{
    my ( $self, $abstractRoot ) = @_;

    my @otherAbstractChildren = $abstractRoot->children();

    for my $abstractChild ( @otherAbstractChildren )
    {
        if( $abstractChild->tag() eq "AbstractText" )
        {
            my $tempStr = Text::Unidecode::unidecode( $abstractChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreAbstract() == 1 );

            $self->WriteLog( "_ParseOtherAbstract - Tag: " . $abstractChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_ParseOtherAbstract - (New Tag Found) - Tag: " . $abstractChild->tag() . ", Field: " . $abstractChild->field() );
        }
    }
}

sub _QuickParseDateCreated
{
    my ( $twigSelf, $article, $self ) = @_;

    my $month = "";
    my $day = "";
    my $year = "";

    # Clear Old Date
    $self->ClearTempDate();

    my @dateAry = $article->children();

    for my $date ( @dateAry )
    {
        $day = $date->field() if ( $date->tag() eq "Day" );
        $month = $date->field if ( $date->tag() eq "Month" );
        $year = $date->field() if ( $date->tag() eq "Year" );
    }

    # Check(s)
    $day = "00" if !defined ( $day );
    $month = "00" if !defined ( $month );
    $year = "0000" if !defined ( $year );

    $self->WriteLog( "_QuickParseDateCreated - Month: $month, Day: $day, Year: $year " );

    $self->SetTempDate( "$month/$day/$year" );

    # Free Memory
    $article->purge();
}

sub _QuickParseJournal
{
    my ( $twigSelf, $journalRoot, $self ) = @_;

    my @journalChildren = $journalRoot->children();

    for my $journalChild ( @journalChildren )
    {
        if( $journalChild->tag() eq "Title" )
        {
            my $tempStr = Text::Unidecode::unidecode( $journalChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreTitle() == 1 );

            $self->WriteLog( "_QuickParseJournal - Tag: " . $journalChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_QuickParseJournal - (New Tag Found) - Tag: " . $journalChild->tag() . ", Field: " . $journalChild->field() );
        }
    }

    # Compoundify String If Option Is Enabled
    if( $self->GetCompoundifyText() == 1 && ( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 ) )
    {
        my $tempStr = $self->CompoundifyString( lc( $self->GetTempStr() ) );

        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $tempStr );
    }
    elsif( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 )
    {
        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $self->GetTempStr() );
    }

    # Clear string placeholders
    $self->ClearTempStr();

    # Free Memory
    $journalRoot->purge();
}

sub _QuickParseArticle
{
    my ( $twigSelf, $article, $self ) = @_;

    my @articleChildren = $article->children();

    for my $articleChild ( @articleChildren )
    {
        if( $articleChild->tag() eq "ArticleTitle" )
        {
            my $tempStr = Text::Unidecode::unidecode( $articleChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreTitle() == 1 );

            $self->WriteLog( "_QuickParseArticle - Tag: " . $articleChild->tag() . ", Field: " . $tempStr );
        }
        elsif( $articleChild->tag() eq "Abstract" )
        {
            my $tempStr = Text::Unidecode::unidecode( $articleChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreAbstract() == 1 );

            $self->WriteLog( "_QuickParseArticle - Tag: " . $articleChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_QuickParseArticle - (New Tag Found) - Tag: " . $articleChild->tag() . ", Field: " . $articleChild->field() );
        }
    }

    # Compoundify String If Option Is Enabled
    if( $self->GetCompoundifyText() == 1 && ( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 ) )
    {
        my $tempStr = $self->CompoundifyString( lc( $self->GetTempStr() ) );

        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $tempStr );
    }
    elsif( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 )
    {
        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $self->GetTempStr() );
    }

    # Clear string placeholders
    $self->ClearTempStr();

    # Free Memory
    $article->purge();
}

sub _QuickParseOtherAbstract
{
    my ( $twigSelf, $abstractRoot, $self ) = @_;

    my @otherAbstractChildren = $abstractRoot->children();

    for my $abstractChild ( @otherAbstractChildren )
    {
        if( $abstractChild->tag() eq "AbstractText" )
        {
            my $tempStr = Text::Unidecode::unidecode( $abstractChild->field() );
            chomp( $tempStr );

            # Store String
            $self->AppendToTempStr( $tempStr ) if ( $self->GetStoreAbstract() == 1 );

            $self->WriteLog( "_QuickParseOtherAbstract - Tag: " . $abstractChild->tag() . ", Field: " . $tempStr );
        }
        else
        {
            $self->WriteLog( "_QuickParseOtherAbstract - (New Tag Found) - Tag: " . $abstractChild->tag() . ", Field: " . $abstractChild->field() );
        }
    }

    # Compoundify String If Option Is Enabled
    if( $self->GetCompoundifyText() == 1 && ( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 ) )
    {
        my $tempStr = $self->CompoundifyString( lc( $self->GetTempStr() ) );

        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $tempStr );
    }
    elsif( $self->IsDateInSpecifiedRange( $self->GetTempDate(), $self->GetBeginDate(), $self->GetEndDate() ) == 1 )
    {
        # Append Article Data To Text Corpus
        $self->AppendStrToTextCorpus( $self->GetTempStr() );
    }

    # Clear string placeholders
    $self->ClearTempStr();

    # Free Memory
    $abstractRoot->purge();
}

sub CreateCompoundWordBST
{
    my ( $self ) = @_;

    $self->WriteLog( "CreateCompoundWordBST - Creating Binary Search Tree From Compound Word Array" );

    my $bst = $self->GetCompoundWordBST();
    my @compoundWordAry = $self->GetCompoundWordAry();
    my $arySize = @compoundWordAry;

    # Check(s)
    $self->WriteLog( "CreateCompoundWordBST - Error: Cannot Create BST / Compound Word Array Is Empty - Have You Read The Compound Word File To Memory?" ) if $arySize == 0;
    return -1 if $arySize == 0;

    my $rootNode = $bst->CreateBST( \@compoundWordAry, 0, $arySize - 1, undef );
    $bst->SetRootNode( $rootNode );

    # Clean-Up
    $self->ClearCompoundWordAry();

    $self->WriteLog( "CreateCompoundWordBST - Compound Word Binary Search Tree Created" );

    return 0;
}

sub CompoundifyString
{
    my ( $self, $str ) = @_;

    return "(null)" if !defined ( $str );

    $self->WriteLog( "CompoundifyString - Compoundifying String - $str" );

    my $bst = $self->GetCompoundWordBST();

    my @strAry = split( ' ', $str );
    $str = "";

    my $arySize = @strAry;
    my $maxCompoundWordLength = $self->GetMaxCompoundWordLength();

    for( my $i = 0; $i < @strAry; $i++ )
    {
        my $lastIndex = $i + $maxCompoundWordLength;
        $lastIndex = $arySize - 1 if ( $i + $maxCompoundWordLength > $arySize );
        my @tempAry = @strAry[$i..$lastIndex];

        my $node = $self->_CompoundifySearch( \@tempAry, undef, $strAry[$i], 0 );
        undef( @tempAry );

        # Compound Word(s) Found
        if( defined( $node ) )
        {
            # Split Compound Word Data And Set Next Index After Located Compound Word(s)
            my @nodeDataAry = split( ' ', $node->data );
            $i += @nodeDataAry - 1;

            # Add Compound Words To The Return String
            $str .= join( '_', @nodeDataAry ) . " ";
            undef( @nodeDataAry );
            
            # Increment Compound Word Counter
            $compoundWordCount++;
        }
        # No Compound Word(s) Found
        else
        {
            # Add Single Word At Array Index To Return String
            $str .= $strAry[$i] . " ";
        }
        
        # Increment Word Counter
        $postCompWordCount++;

        # Debug Print Statements
        #$self->WriteLog( "Data: " . $node->data . " : Next Index: $i" ) if defined ( $node );
        #$self->WriteLog( "Undefined : Index: $i" ) if !defined ( $node );
    }

    $self->WriteLog( "CompoundifyString - Compounded String - $str" );

    return $str;
}

sub _CompoundifySearch
{
    my ( $self, $strAryRef, $oldNode, $searchStr, $index ) = @_;

    # Checks(s)
    return undef if !defined ( $strAryRef );
    return undef if !defined ( $searchStr );
    return undef if !defined ( $index );

    my @strAry = @{ $strAryRef };
    my $arySize = @strAry;
    my $bst = $self->GetCompoundWordBST();

    
    my $resultNode = $bst->BSTContainsSearch( $bst->GetRootNode(), $searchStr );

    if( defined( $resultNode ) && $index < $arySize )
    {
        $index++;
        
        # Make Sure Returned Node Data Is Equal With Search String Or Return Old Node
        $resultNode = $bst->BSTExactSearch( $bst->GetRootNode(), $searchStr );
        $resultNode = $oldNode if !defined( $resultNode );

        $searchStr .= ( " " . $strAry[$index] ) if ( $index < $arySize );
        return $self->_CompoundifySearch( $strAryRef, $resultNode, $searchStr, $index ) if ( $index < $arySize );
    }

    # Post Check(s)
    $resultNode = undef if defined( $resultNode ) && ( $resultNode->data ne $searchStr );

    if( defined( $oldNode ) )
    {
        my @searchStrAry = split( ' ', $searchStr );
        my @nodeStrAry = split( ' ', $oldNode->data );

        if( @searchStrAry > @nodeStrAry )
        {
            @searchStrAry = splice( @searchStrAry, 0, @nodeStrAry );
            my $strA = join( ' ', @searchStrAry );
            my $strB = join( ' ', @nodeStrAry );
            $oldNode = undef if $strA ne $strB;
        }
        elsif( @searchStrAry == @nodeStrAry )
        {
            $oldNode = undef if $oldNode->data ne $searchStr;
        }
        else
        {
            $oldNode = undef;
        }
    }




    # Bug Fix: If Search Word Found At First Array Index And Second Word Not Found.
    #          Prevent Invalid Data From Being Returned.
    return undef if !defined( $resultNode ) && $index == 1;

    return $oldNode if !defined( $resultNode );

    return $resultNode;
}

sub ReadCompoundWordDataFromFile
{
    my ( $self, $fileDir, $autoSetMaxCompoundWordLength ) = @_;

    $self->WriteLog( "ReadCompoundWordDataFromFile - Error: Directory Not Defined" ) if !defined ( $fileDir );
    return -1 if !defined ( $fileDir );

    $self->WriteLog( "ReadCompoundWordDataFromFile - Error: Directory/File Does Not Exist" ) if !( -e "$fileDir" );
    return -1 if !( -e "$fileDir" );

    $self->WriteLog( "ReadCompoundWordDataFromFile - Reading Compound Word File: \"$fileDir\"" );

    my @dataAry = ();

    # Read XML Data From File To Memory
    open( my $fileHandle, '<:encoding(UTF-8)', "$fileDir" );

    # Prepare Max Compound Word Length
    $self->SetMaxCompoundWordLength( 0 ) if defined ( $autoSetMaxCompoundWordLength );

    while( my $row = <$fileHandle> )
    {
        chomp( $row );
        $row = $self->RemoveSpecialCharactersFromString( $row );
        push( @dataAry, $row );

        # Find Max Compound Word Length
        my @words = split( ' ', $row );
        my $size = @words;
        undef( @words );
        $self->SetMaxCompoundWordLength( $size ) if defined( $autoSetMaxCompoundWordLength ) && ( $self->GetMaxCompoundWordLength() < $size );
    }

    close( $fileHandle );
    
    $self->WriteLog( "ReadCompoundWordDataFromFile - Error: Compound Word Length > 100" ) if ( $self->GetMaxCompoundWordLength() > 100 );
    return -1  if ( $self->GetMaxCompoundWordLength() > 100 );

    $self->WriteLog( "ReadCompoundWordDataFromFile - Auto Set Max Compound Word Length To \"" . $self->GetMaxCompoundWordLength() . "\"") if defined ( $autoSetMaxCompoundWordLength );
    $self->WriteLog( "ReadCompoundWordDataFromFile - Reading Complete" );
    $self->WriteLog( "ReadCompoundWordDataFromFile - Sorting Compound Word List" );

    @dataAry = sort( @dataAry );
    $self->SetCompoundWordAry( \@dataAry );

    $self->WriteLog( "ReadCompoundWordDataFromFile - Stored " . @dataAry . " Compound Words In Memory" ) if ( @dataAry > 0 );
    $self->WriteLog( "ReadCompoundWordDataFromFile - Detected Compound Word Array Data / Auto-Setting Compoundify Text = 1" ) if @dataAry > 0;
    $self->SetCompoundifyText( 1 ) if ( @dataAry > 0 );

    $self->WriteLog( "ReadCompoundwordDataFromFile - No Compound Word Array Data Detected / Auto-Setting Compoundify Text = 0" ) if @dataAry == 0;
    $self->SetCompoundifyText( 0 ) if ( @dataAry == 0 );

    $self->WriteLog( "ReadCompoundWordDataFromFile - Sorting Complete" );

    return 0;
}

sub SaveCompoundWordListToFile
{
    my ( $self, $savePath ) = @_;

    $self->WriteLog( "SaveCompoundWordListToFile - Error: Save Path Not Specified" ) if !defined( $savePath );
    return -1 if !defined( $savePath );

    $self->WriteLog( "SaveCompoundWordListToFile - Saving Compound Word List To \"$savePath\"" );

    # Create File Handle
    open( my $fileHandle, '>:encoding(UTF-8)', "$savePath" );

    # Write Data To File
    for my $compoundWord ( $self->GetCompoundWordAry() )
    {
        print( $fileHandle "$compoundWord\n" );
    }

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "SaveCompoundWordListToFile - Compound Word List Saved To \"$savePath\"" );

    return 0;
}

sub ReadTextFromFile
{
    my ( $self, $fileDir ) = @_;

    $self->WriteLog( "ReadTextFromFile - Error: Directory Not Defined" ) if !defined ( $fileDir );
    return "(null)" if !defined ( $fileDir );

    $self->WriteLog( "ReadTextFromFile - Error: Directory/File Does Not Exist" ) if !( -e "$fileDir" );
    return "(null)" if !( -e "$fileDir" );

    my $str = "";

    # Read XML Data From File To Memory
    open( my $fileHandle, '<:encoding(UTF-8)', "$fileDir" );

    while( my $row = <$fileHandle> )
    {
        chomp $row;
        $str .= " $row";
    }

    close( $fileHandle );

    $self->WriteLog( "ReadTextFromFile - Reading Complete" );

    return $str;
}

sub SaveTextToFile
{
    my ( $self, $savePath, $str ) = @_;

    $self->WriteLog( "SaveTextToFile - Error: No Save Path Specified" ) if !defined( $savePath );
    return -1 if !defined( $savePath );

    $self->WriteLog( "SaveTextToFile - Saving Data To \"$savePath\"" );

    # Create file handle
    my $fileHandle = undef;

    # Over write file if $appendToFile == 0
    open( $fileHandle, '>:encoding(UTF-8)', "$savePath" );

    # Write Data To File
    print( $fileHandle "$str" );

    close( $fileHandle );
    undef( $fileHandle );

    $self->WriteLog( "SaveTextToFile - File Saved To \"$savePath\"" );

    return 0;
}

sub _ReadXMLDataFromFile
{
    my ( $self, $fileDir ) = @_;

    $self->WriteLog( "_ReadXMLDataFromFile - Error: Directory Not Defined" ) if !defined ( $fileDir );
    return "(null)" if !defined ( $fileDir );

    $self->WriteLog( "_ReadXMLDataFromFile - Error: Directory/File Does Not Exist" ) if !( -e "$fileDir" );
    return "(null)" if !( -e "$fileDir" );

    my $data = "";

    # Extract XML File From GZip To Memory
    if ( index( $fileDir, ".gz" ) != -1 )
    {
        IO::Uncompress::Gunzip::gunzip "$fileDir" => \$data or die "gunzip failed\n";
    }
    # Read XML Data From File To Memory
    else
    {
        open( my $fileHandle, '<:encoding(UTF-8)', "$fileDir" );

        while( my $row = <$fileHandle> )
        {
            chomp $row;
            $data .= "$row\n";
        }

        close( $fileHandle );
    }

    $self->WriteLog( "_ReadXMLDataFromFile - Reading Data Complete/Data Stored" );

    return $data;
}

sub _SaveTextCorpusToFile
{
    my ( $self, $savePath, $appendToFile ) = @_;

    # Prevent Other Threads From Writing At The Same Time
    {
        lock( $writeLock );
    
        $self->WriteLog( "_SaveTextCorpusToFile - Error: No Save Path Specified" ) if !defined( $savePath );
        return -1 if !defined( $savePath );
    
        $appendToFile = $self->GetOverwriteExistingFile() if !defined ( $appendToFile );
    
        $self->WriteLog( "_SaveTextCorpusToFile - Saving Text Corpus To \"$savePath\"" );
    
        # Create file handle
        my $fileHandle = undef;
    
        # Over write file if $appendToFile == 0
        open( $fileHandle, '>:encoding(UTF-8)', "$savePath" ) if $appendToFile == 0;
    
        # Append to file if $appendToFile == 1
        open( $fileHandle, '>>:encoding(UTF-8)', "$savePath" ) if $appendToFile == 1;
    
        # Write Data To File
        my $str = $self->GetTextCorpusStr();
        
        # Remove Extra Spaces In Text Corpus String
        $str =~ s/ +/ /g;
        
        print( $fileHandle $str );
    
        close( $fileHandle );
        undef( $fileHandle );
    
        $self->WriteLog( "_SaveTextCorpusToFile - Text Corpus Saved To \"$savePath\"" );
    }

    return 1;
}

sub IsDateInSpecifiedRange
{
    my ( $self, $date, $beginDate, $endDate ) = @_;

    $self->WriteLog( "Error: Date Not Specified To Check Against Date Range" ) if !defined ( $date );
    return 0 if !defined ( $date );

    $self->WriteLog( "Warning - BeginDate Parameter Not Specified - Using Default Value: " . $self->GetBeginDate() ) if !defined ( $beginDate );
    $self->WriteLog( "Warning - EndDate Parameter Not Specified - Using Default Value: " . $self->GetEndDate() ) if !defined ( $endDate );
    $beginDate = $self->GetBeginDate() if !defined ( $beginDate );
    $endDate = $self->GetEndDate() if !defined ( $endDate );

    my @dateAry = split( '/', $date );
    my @beginDateAry = split( '/', $beginDate );
    my @endDateAry = split( '/', $endDate );

    # Check(s)
    if( @dateAry != 3 )
    {
        $self->WriteLog( "Invalid Date Format - Requested Format: Month/Day/Year : Specified Format - $date" );
        return 0;
    }
    elsif( @beginDateAry != 3 )
    {
        $self->WriteLog( "Invalid Date Format - Requested Format: Month/Day/Year : Specified Format - $beginDate" );
        return 0;
    }
    elsif( @endDateAry != 3 )
    {
        $self->WriteLog( "Invalid Date Format - Requested Format: Month/Day/Year : Specified Format - $endDate" );
        return 0;
    }

    # Begin Date Comparison
    my $dateYear = $dateAry[2];
    my $beginYear = $beginDateAry[2];
    my $endYear = $endDateAry[2];

    my $dateMonth = $dateAry[0];
    my $beginMonth = $beginDateAry[0];
    my $endMonth = $endDateAry[0];

    my $dateDay = $dateAry[1];
    my $beginDay = $beginDateAry[1];
    my $endDay = $endDateAry[1];

    # Check(s)
    return 0 if ( $dateYear < 0 || $beginYear < 0 || $endYear < 0 ||
                  $dateMonth < 0 || $beginMonth < 0 || $endMonth < 0 ||
                  $dateDay < 0 || $beginDay < 0 || $endDay < 0 );

    return 0 if ( $dateYear < $beginYear || $dateYear > $endYear );
    return 0 if ( ( $dateYear == $beginYear && $dateMonth < $beginMonth ) || ( $dateYear == $endYear && $dateMonth > $endMonth ) );
    return 0 if ( ( $dateYear == $beginYear && $dateMonth == $beginMonth && $dateDay < $beginDay )
                 || ( $dateYear == $endYear && $dateMonth == $endMonth && $dateDay > $endDay ) );

    return 1;
}

sub IsFileOrDirectory
{
    my ( $self, $path ) = @_;

    # Check(s)
    return "unknown" if !defined( $path );
    return "unknown" if !( -e $path );

    return "file" if ( -f $path );
    return "dir" if ( -d $path );
}

sub RemoveSpecialCharactersFromString
{
    my ( $self, $str ) = @_;
    $str = lc( $str );                                                 # Convert all characters to lowercase
    $str =~ s/ +/ /g;                                                  # Remove duplicate white spaces between words
    $str =~ s/'s//g;                                                   # Remove "'s" characters (Apostrophe 's')
    $str =~ s/-/ /g;                                                   # Replace all hyphen characters to spaces
    $str =~ s/\./\n/g if ( $self->GetStoreAsSentencePerLine() == 1 );  # Convert Period To New Line Character
    $str =~ tr/a-z\015\012/ /cs;                                       # Remove all characters except 'a' to 'z' and new-line characters
    #$str =~ s/[\$#@~!&*()\[\];.,:?^\-'`\\\/]+//g;                     # Does not include numeric characters
    
    # Convert String Line Ending Suitable To The Target 
    my $lineEnding = "";
    my $os = $self->GetOSType();
    
    $lineEnding = "\015\012" if ( $os eq "MSWin32" );
    $lineEnding = "\012"     if ( $os eq "linux" );
    $lineEnding = "\015"     if ( $os eq "MacOS" );
    
    $str =~ s/(\015\012|\012|\015)/$lineEnding/g;
    
    # Removes Spaces At Left Side Of String
    $str =~ s/^\s+//                if ( $self->GetStoreAsSentencePerLine() == 1 );
    
    # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
    $str =~ s/^\s+|\s(?=\s)|\s+$//g if ( $self->GetStoreAsSentencePerLine() == 0 );
    
    return $str;
}

sub GetFileType
{
    my ( $self, $filePath ) = @_;
    
    my $ft = File::Type->new();
    my $fileType = $ft->checktype_filename( $filePath );
    undef( $ft );

    return $fileType;
}

sub _DateCheck
{
    my ( $self ) = @_;
    
    my $beginDate = $self->GetBeginDate();
    my $endDate   = $self->GetEndDate();
    
    # Check(s)
    $self->WriteLog( "_DateCheck - Error: Begin Date Node Defined" ) if !defined( $beginDate );
    return -1 if !defined( $beginDate );
    
    $self->Writelog( "_DateCheck - Error: End Date Not Defined" ) if !defined( $endDate );
    return -1 if !defined( $endDate );
    
    # Parse Begin Date
    my $delimiter = "";
    $delimiter = "-" if index( $beginDate, "-" ) != -1;
    $delimiter = "/" if index( $beginDate, "/" ) != -1;
    
    $self->WriteLog( "_DateCheck - Error: Begin Date Improper Format" ) if ( $delimiter eq "" );
    return -1 if ( $delimiter eq "" );
    
    my @bDateAry = split( $delimiter, $beginDate );
    
    # Check For Default Begin Date And Adjust Accordingly
    if( $bDateAry[0] == 0 && $bDateAry[1] == 0 && $bDateAry[2] == 0000 )
    {
        $bDateAry[0] = 01;
        $bDateAry[1] = 01;
        $bDateAry[2] = 0000;
    }
    
    # Set Date In Proper Format
    $beginDate = join( '/', @bDateAry ) if ( $delimiter eq "-" );
    $self->SetBeginDate( $beginDate ) if ( $delimiter eq "-" );
    
    # Parse End Date
    $delimiter = "";
    $delimiter = "-" if index( $endDate, "-" ) != -1;
    $delimiter = "/" if index( $endDate, "/" ) != -1;
    
    $self->WriteLog( "_DateCheck - Error: End Date Improper Format" ) if ( $delimiter eq "" );
    return -1 if ( $delimiter eq "" );
    
    my @eDateAry = split( $delimiter, $endDate );
    
    # Check For Default End Date And Adjust Accordingly
    if( $eDateAry[0] == 99 && $eDateAry[1] == 99 && $eDateAry[2] == 9999 )
    {
        $eDateAry[0] = 12;
        $eDateAry[1] = 31;
        $eDateAry[2] = 9999;
    }
    
    # Set Date In Proper Format
    $endDate = join( '/', @eDateAry ) if ( $delimiter eq "-" );
    $self->SetEndDate( $endDate ) if ( $delimiter eq "-" );
    
    # Basic Checks
    $self->WriteLog( "_DateCheck - Error: Begin Date Not Specified In \"Month/Day/Year\" or \"Month-Day-Year\" Format" ) if ( @bDateAry != 3 );
    $self->WriteLog( "_DateCheck - Error: End Date Not Specified In \"Month/Day/Year\" or \"Month-Day-Year\" Format" ) if ( @eDateAry != 3 );
    return -1 if ( @bDateAry != 3 ) || ( @eDateAry != 3 );
    
    $self->WriteLog( "_DateCheck - Error: Incorrect Begin Date Month Value - Expected Value: 1-12 / Specified Value: " . $bDateAry[0] ) if ( $bDateAry[0] < 1 || $bDateAry[0] > 12 );
    $self->WriteLog( "_DateCheck - Error: Incorrect End Date Month Value - Expected Value: 1-12 / Specified Value: " . $eDateAry[0] ) if ( $eDateAry[0] < 1 || $eDateAry[0] > 12 );
    return -1 if ( $bDateAry[0] < 1 || $bDateAry[0] > 12 ) || ( $eDateAry[0] < 1 || $eDateAry[0] > 12 );
    
    $self->WriteLog( "_DateCheck - Error: Incorrect Begin Date Day Value - Expected Value: 1-31 / Specified Value: " . $bDateAry[1] ) if ( $bDateAry[1] < 1 || $bDateAry[1] > 31 );
    $self->WriteLog( "_DateCheck - Error: Incorrect End Date Day Value - Expected Value: 1-31 / Specified Value: " . $eDateAry[1] ) if ( $eDateAry[1] < 1 || $eDateAry[1] > 31 );
    return -1 if ( $bDateAry[1] < 1 || $bDateAry[1] > 31 ) || ( $eDateAry[1] < 1 || $eDateAry[1] > 31 );
    
    $self->WriteLog( "_DateCheck - Error: Incorrect Begin Date Year Value - Expected Value: 0-9999 / Specified Value: " . $bDateAry[2] ) if ( $bDateAry[2] < 0 || $bDateAry[2] > 9999 );
    $self->WriteLog( "_DateCheck - Error: Incorrect End Date Year Value - Expected Value: 0-9999 / Specified Value: " . $eDateAry[2] ) if ( $eDateAry[2] < 0 || $eDateAry[2] > 9999 );
    return -1 if ( $bDateAry[2] < 0 || $bDateAry[2] > 9999 ) || ( $eDateAry[2] < 0 || $eDateAry[2] > 9999 );
    
    # Advanced Checks
    $self->WriteLog( "_DateCheck - Error: Begin Date Year > End Date Year" ) if ( $bDateAry[2] > $eDateAry[2] );
    return -1 if ( $bDateAry[2] > $eDateAry[2] );
    
    $self->WriteLog( "_DateCheck - Error: Years Equal, Begin Date Month > End Date Month" ) if ( $bDateAry[2] == $eDateAry[2] && $bDateAry[0] > $eDateAry[0] );
    return -1 if ( $bDateAry[2] == $eDateAry[2] && $bDateAry[0] > $eDateAry[0] );
    
    $self->WriteLog( "_DateCheck - Error: Years And Months Equal, Begin Date Day > End Date Day" ) if ( $bDateAry[2] == $eDateAry[2] && $bDateAry[0] == $eDateAry[0] && $bDateAry[1] > $eDateAry[1] );
    return -1 if ( $bDateAry[2] == $eDateAry[2] && $bDateAry[0] == $eDateAry[0] && $bDateAry[1] > $eDateAry[1] );
    
    # Clean Up
    $beginDate = "";
    $endDate   = "";
    $delimiter = "";
    @bDateAry = ();
    @eDateAry = ();
    
    return 0;
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

sub GetStoreTitle
{
    my ( $self ) = @_;
    $self->{ _storeTitle } = 1 if !defined ( $self->{ _storeTitle } );
    return $self->{ _storeTitle };
}

sub GetStoreAbstract
{
    my ( $self ) = @_;
    $self->{ _storeAbstract } = 1 if !defined ( $self->{ _storeAbstract } );
    return $self->{ _storeAbstract };
}

sub GetQuickParse
{
    my ( $self ) = @_;
    $self->{ _quickParse } = 0 if !defined ( $self->{ _quickParse } );
    return $self->{ _quickParse };
}

sub GetCompoundifyText
{
    my ( $self ) = @_;
    $self->{ _compoundifyText } = 0 if !defined ( $self->{ _compoundifyText } );
    return $self->{ _compoundifyText };
}

sub GetStoreAsSentencePerLine
{
    my ( $self ) = @_;
    $self->{ _storeAsSentencePerLine } = 0 if !defined ( $self->{ _storeAsSentencePerLine } );
    return $self->{ _storeAsSentencePerLine };
}

sub GetNumOfThreads
{
    my ( $self ) = @_;
    $self->{ _numOfThreads } = Sys::CpuAffinity::getNumCpus() if !defined ( $self->{ _numOfThreads } );
    return $self->{ _numOfThreads };
}

sub GetWorkingDir
{
    my ( $self ) = @_;
    $self->{ _workingDir } = Cwd::getcwd() if !defined $self->{ _workingDir };
    return $self->{ _workingDir };
}

sub GetSavePath
{
    my ( $self ) = @_;
    $self->{ _savePath } = "(null)" if !defined $self->{ _savePath };
    return $self->{ _savePath };
}

sub GetBeginDate
{
    my ( $self ) = @_;
    $self->{ _beginDate } = "00/00/0000" if !defined ( $self->{ _beginDate } );
    return $self->{ _beginDate };
}

sub GetEndDate
{
    my ( $self ) = @_;
    $self->{ _endDate } = "99/99/9999" if !defined ( $self->{ _endDate } );
    return $self->{ _endDate };
}

sub GetXMLStringToParse
{
    my ( $self ) = @_;
    $self->{ _xmlStringToParse } = "(null)" if !defined ( $self->{ _xmlStringToParse } );
    return $self->{ _xmlStringToParse };
}

sub GetTextCorpusStr
{
    my ( $self ) = @_;
    $self->{ _textCorpusStr } = "" if !defined ( $self->{_textCorpusStr } );
    return $self->{ _textCorpusStr };
}

sub GetFileHandle
{
    my ( $self ) = @_;
    $self->{ _fileHandle } = undef if !defined ( $self->{ _fileHandle } );
    return $self->{ _fileHandle };
}

sub GetTwigHandler
{
    my ( $self ) = @_;
    $self->{ _twigHandler } = "(null)" if !defined ( $self->{ _twigHandler } );
    return $self->{ _twigHandler };
}

sub GetParsedCount
{
    my ( $self ) = @_;
    $self->{ _parsedCount } = 0 if !defined ( $self->{ _parsedCount } );
    return $self->{ _parsedCount };
}

sub GetTempStr
{
    my ( $self ) = @_;
    $self->{ _tempStr } = "" if !defined ( $self->{ _tempStr } );
    return $self->{ _tempStr };
}

sub GetTempDate
{
    my ( $self ) = @_;
    $self->{ _tempDate } = "" if !defined ( $self->{ _tempDate } );
    return $self->{ _tempDate };
}

sub GetCompoundWordAry
{
    my ( $self ) = @_;
    $self->{ _compoundWordAry } = () if !defined ( $self->{ _compoundWordAry } );
    return @{ $self->{ _compoundWordAry } };
}

sub GetCompoundWordBST
{
    my ( $self ) = @_;
    $self->{ _compoundWordBST } = Word2vec::Bst->new() if !defined ( $self->{ _compoundWordBST } );
    return $self->{ _compoundWordBST };
}

sub GetMaxCompoundWordLength
{
    my ( $self ) = @_;
    $self->{ _maxCompoundWordLength } = 20 if !defined ( $self->{ _maxCompoundWordLength } );
    return $self->{ _maxCompoundWordLength };
}

sub GetOverwriteExistingFile
{
    my ( $self ) = @_;
    $self->{ _overwriteExistingFile } = 0 if !defined ( $self->{ _overwriteExistingFile } );
    return $self->{ _overwriteExistingFile };
}


######################################################################################
#    Mutators
######################################################################################

sub SetStoreTitle
{
    my ( $self, $value ) = @_;
    return $self->{ _storeTitle } = $value;
}

sub SetStoreAbstract
{
    my ( $self, $value ) = @_;
    return $self->{ _storeAbstract } = $value;
}

sub SetWorkingDir
{
    my ( $self, $dir ) = @_;
    return $self->{ _workingDir } = $dir;
}

sub SetSavePath
{
    my ( $self, $dir ) = @_;
    return $self->{ _savePath } = $dir;
}

sub SetQuickParse
{
    my ( $self, $value ) = @_;
    return $self->{ _quickParse } = $value;
}

sub SetCompoundifyText
{
    my ( $self, $value ) = @_;
    return $self->{ _compoundifyText } = $value;
}

sub SetStoreAsSentencePerLine
{
    my ( $self, $value ) = @_;
    return $self->{ _storeAsSentencePerLine } = $value;
}

sub SetNumOfThreads
{
    my ( $self, $value ) = @_;

    # Check
    $self->WriteLog( "SetNumOfThreads - Warning: Number Of Threads Value < 0 / Setting Default Value" ) if ( $value < 0 );
    $value = Sys::CpuAffinity::getNumCpus() if ( $value < 0 );

    return $self->{ _numOfThreads } = $value;
}

sub SetBeginDate
{
    my ( $self, $str ) = @_;
    return $self->{ _beginDate } = $str;
}

sub SetEndDate
{
    my ( $self, $str ) = @_;
    return $self->{ _endDate } = $str;
}

sub SetXMLStringToParse
{
    my ( $self, $str ) = @_;
    return $self->{ _xmlStringToParse } = $str;
}

sub SetTextCorpusStr
{
    my ( $self, $str ) = @_;
    return $self->{ _textCorpusStr } = $str;
}

sub AppendStrToTextCorpus
{
    my ( $self, $str ) = @_;

    return if ( $str eq "" || !defined( $str ) );
    
    # Prevent Other Threads From Appending Data At The Same Time
    {
        lock( $appendLock );
        
        # Removes Spaces At Left Side Of String
        $str =~ s/^\s+//                if ( $self->GetStoreAsSentencePerLine() == 1 );
        
        # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
        $str =~ s/^\s+|\s(?=\s)|\s+$//g if ( $self->GetStoreAsSentencePerLine() == 0 );
        
        # Append string to text corpus
        if( substr( $str, -1 ) eq "\n" )
        {
            $self->{ _textCorpusStr } .= "$str" ;
        }
        else
        {
            $self->{ _textCorpusStr } .= "$str ";
        }
    }
}

sub ClearTextCorpusStr
{
    my ( $self ) = @_;
    return $self->{ _textCorpusStr } = "";
}

sub SetTempStr
{
    my ( $self, $str ) = @_;

    # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
    $str = $self->RemoveSpecialCharactersFromString( $str );
    $str = Text::Unidecode::unidecode( $str );

    return $self->{ _tempStr } = $str;
}

sub AppendToTempStr
{
    my ( $self, $str ) = @_;

    # Convert String To UTF8 Format Encoding (Removes Special Characters / Fixes Wide Character Bug)
    $str = $self->RemoveSpecialCharactersFromString( $str );
    $str = Text::Unidecode::unidecode( $str );
    
    # Removes Spaces At Left Side Of String
    $str =~ s/^\s+//                if ( $self->GetStoreAsSentencePerLine() == 1 );
    
    # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
    $str =~ s/^\s+|\s(?=\s)|\s+$//g if ( $self->GetStoreAsSentencePerLine() == 0 );
    
    # Increment Word Counter
    my @words = split( ' ', $str );
    $preCompWordCount += scalar( @words );
    undef( @words );
    
    # Append String To Temp String
    return $self->{ _tempStr } .= "$str" if ( index( ( scalar reverse $str ), "\n" ) == 0 );
    return $self->{ _tempStr } .= "$str ";
}

sub ClearTempStr
{
    my ( $self ) = @_;
    return $self->{ _tempStr } = "";
}

sub SetTempDate
{
    my ( $self, $str ) = @_;
    return $self->{ _tempDate } = $str;
}

sub ClearTempDate
{
    my ( $self ) = @_;
    return $self->{ _tempDate } = "";
}

sub SetCompoundWordAry
{
    my ( $self, $aryRef ) = @_;
    $self->WriteLog( "Warning: Setting CompoundWordArray when array is already defined - Clearing Previous Array" ) if ( @{ $self->{ _compoundWordAry } } > 0 );
    undef( $self->{ _compoundWordAry } ) if ( @{ $self->{ _compoundWordAry } } > 0 );
    return @{ $self->{ _compoundWordAry } } = @{ $aryRef };
}

sub ClearCompoundWordAry
{
    my ( $self ) = @_;
    undef( $self->{ _compoundWordAry } );
    return @{ $self->{ _compoundWordAry } } = ();
}

sub SetCompoundWordBST
{
    my ( $self, $bst ) = @_;
    $self->WriteLog( "Warning: Setting CompoundWordBST when BST is already defined - Clearing Previous BST" ) if defined ( $self->{ _compoundWordBST } );
    $self->{ _compoundWordBST }->DESTROY() if defined( $self->{ _compoundWordBST } );
    undef( $self->{ _compoundWordBST } ) if defined ( $self->{ _compoundWordBST } );
    return $self->{ _compoundWordBST } = $bst;
}

sub ClearCompoundWordBST
{
    my ( $self ) = @_;
    undef( $self->{ _compoundWordBST } );
    return $self->{ _compoundWordBST };
}

sub SetMaxCompoundWordLength
{
    my ( $self, $value ) = @_;
    return $self->{ _maxCompoundWordLength } = $value;
}

sub SetOverwriteExistingFile
{
    my ( $self, $value ) = @_;
    return $self->{ _overwriteExistingFile } = $value;
}


######################################################################################
#    Debug Functions
######################################################################################

sub GetTime
{
    my ( $self ) = @_;
    my( $sec, $min, $hour ) = localtime();

    $hour = "0$hour" if( $hour < 10 );
    $min = "0$min"   if( $min < 10 );
    $sec = "0$sec"   if( $sec < 10 );

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

    # Prevent Other Threads From Writing At The Same Time
    lock( $debugLock );

    if( $self->GetDebugLog() )
    {
        if( ref ( $self ) ne "Word2vec::Xmltow2v" )
        {
            print( GetDate() . " " . GetTime() . " - xmltow2v: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - xmltow2v::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Xmltow2v" )
        {
            print( GetDate() . " " . GetTime() . " - xmltow2v: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - xmltow2v::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Xmltow2v - Medline XML-To-W2V Module.

=head1 SYNOPSIS

 use Word2vec::Xmltow2v;

 # Parameters: Debug Output = True, Write Log = False, StoreTitle = True, StoreAbstract = True, Quick Parse = True, CompoundifyText = True, Use Multi-Threading (Default = 1 Thread Per CPU Core)
 my $xmlconv = Word2vec::Xmltow2v->new( 1, 0, 1, 1, 1, 1, 2 );      # Note: Specifying no parameters implies default settings.
 $xmlconv->SetWorkingDir( "Medline/XML/Directory/Here" );
 $xmlconv->SetSavePath( "textcorpus.txt" );
 $xmlconv->SetStoreTitle( 1 );
 $xmlconv->SetStoreAbstract( 1 );
 $xmlconv->SetBeginDate( "01/01/2004" );
 $xmlconv->SetEndDate( "08/13/2016" );
 $xmlconv->SetOverwriteExistingFile( 1 );

 # If Compound Word File Exists, Store It In Memory And Create Compound Word Binary Search Tree
 $xmlconv->ReadCompoundWordDataFromFile( "compoundword.txt", 1 );
 $xmlconv->CreateCompoundWordBST();

 # Parse XML Files or Directory Of Files
 $xmlconv->ConvertMedlineXMLToW2V( "/xmlDirectory/" );
 undef( $xmlconv );

=head1 DESCRIPTION

Word2vec::Xmltow2v is a XML-to-text module which converts Medline XML article title
and abstract data, given a date range, into a plain text corpus for use
with Word2vec::Interface. It also "compoundifies" during text corpus compilation
given a compound word file.

=head2 Main Functions

=head3 new

Description:

 Returns a new 'Word2vec::Xmltow2v' module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog                    = 0
    writeLog                    = 0
    storeTitle                  = 1
    storeAbstract               = 1
    quickParse                  = 0
    compoundifyText             = 0
    storeAsSentencePerLine      = 0
    numOfThreads                = Number of CPUs/CPU cores (1 thread per core/CPU)
    workingDir                  = Current Directory
    savePath                    = Current Directory
    beginDate                   = "00/00/0000"
    endDate                     = "99/99/9999"
    xmlStringToParse            = "(null)"
    textCorpusString            = ""
    twigHandler                 = 0
    parsedCount                 = 0
    tempDate                    = ""
    tempStr                     = ""
    outputFileName              = "textcorpus.txt"
    compoundWordAry             = ()
    compoundWordBST             = Word2vec::Bst->new()
    maxCompoundWordLength       = 0
    overwriteExistingFile       = 0

Input:

 $debugLog                    -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. (1 = True / 0 = False)
 $storeTitle                  -> Instructs module to store Medline article titles during text corpus compilation. (1 = True / 0 = False)
 $storeAbstract               -> Instructs module to store Medline article abstracts during text corpus compilation. (1 = True / 0 = False)
 $quickParse                  -> Instructs module to utilize quick XML parsing Functions for known Medline article title and abstract tags. (1 = True / 0 = False)
 $compoundifyText             -> Instructs module to compoundify text on the fly given a compound word file. This is automatically set
                                 when reading the compound word file to memory regardless of user setting. (1 = True / 0 = False)
 $storeAsSentencePerLine      -> Instructs module to store parsed medline data as a length single sentence or separate sentences on new lines based on period character. (1 = True / 0 = False)
 $numOfThreads                -> Specifies the number of worker threads which parse Medline XML files simultaneously to create the text corpus.
                                 This speeds up text corpus generation by the number of physical cores present an a given machine. (Positive integer value)
                                 ie. Using four threads of a Intel i7 core machine speeds up text corpus generation roughly four times faster than being single threaded.
 $workingDir                  -> Specifies the current working directory. (String)
 $savePath                    -> Specifies the save path for text corpus generation. (String)
 $beginDate                   -> Specifies the beginning date range for Medline article text corpus composition. (Format: XX/XX/XXXX)
 $endDate                     -> Specifies the ending date range for Medline article text corpus composition. (Format: XX/XX/XXXX)
 $xmlStringToParse            -> Storage location for the current Medline XML file in memory. (String)
 $textCorpusString            -> Temporary storage location for text corpus generation in memory. (String)
 $twigHandler                 -> XML::Twig object location.
 $parsedCount                 -> Number of parsed Medline articles during text corpus generation.
 $tempDate                    -> Temporary storage location for current Medline article date during text corpus compilation.
 $tempStr                     -> Temporary storage location for current Medline article title/abstract during text corpus compilation.
 $outputFileName              -> Output file path/name.
 $compoundWordAry             -> Storage location for compound words, used to compoundify text. (Array) <- Depreciated
 $compoundWordBST             -> Storage location for compound words, used to compoundify text. (Binary Search Tree) <- Supersedes '$compoundWordAry'
 $maxCompoundWordLength       -> Maximum number of words able to be compoundified in one phrase. ie "six_sea_snakes_were_sailing" = 5 compoundified words.
                                 The compounding algorithm will attempt to compoundify no more than this set value, even-though the compound word list could
                                 possibly contain larger compounded phrases.
 $overwriteExistingFile       -> Instructs the module to either overwrite any existing text corpus files or append to the existing file.

 Note: It is not recommended to specify all new() parameters, as it has not been thoroughly tested. Maximum recommended parameters to be specified include:
       "debugLog, writeLog, storeTitle, storeAbstract, quickParse, compoundifyText, numOfThreads, workingDir, savePath, beginDate, endDate"

Output:

 Word2vec::Xmltow2v object.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();  # Note: Specifying no parameters implies default settings as listed above.

 undef( $xmlconv );

 # Or

 use Word2vec::Xmltow2v;

 # Parameters: Debug Output = True, Write Log = False, StoreTitle = True, StoreAbstract = True, Quick Parse = True, CompoundifyText = True, Use Multi-Threading (2 Threads)
 my $xmlconv = new xmltow2v( 1, 0, 1, 1, 1, 1, 2 );

 undef( $xmlconv );

=head3 DESTROY

Description:

 Removes module objects and variables from memory.

Input:

 None

Output:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();

 $xmlconv->DESTROY();
 undef( $xmlconv );

=head3 ConvertMedlineXMLToW2V

Description:

 Parses specified parameter Medline XML file or directory of files, creating a text corpus. Returns 0 if successful or -1 during an error.

 Note: Supports plain Medline XML or gun-zipped XML files.

Input:

 $filePath -> XML file path to parse. (This can be a single file or directory of XML/XML.gz files).

Output:

 $value    -> '0' = Successful / '-1' = Un-Successful

Example:

 use Word2vec::Xmltow2v;

 $xmlconv = new xmltow2v();      # Note: Specifying no parameters implies default settings
 $xmlconv->SetSavePath( "testCorpus.txt" );
 $xmlconv->SetStoreTitle( 1 );
 $xmlconv->SetStoreAbstract( 1 );
 $xmlconv->SetBeginDate( "01/01/2004" );
 $xmlconv->SetEndDate( "08/13/2016" );
 $xmlconv->SetOverwriteExistingFile( 1 );
 $xmlconv->ConvertMedlineXMLToW2V( "/xmlDirectory/" );
 undef( $xmlconv );


=head3 _ThreadedConvert

Description:

 Multi-Threaded Medline XML to text corpus conversion function.

Input:

 $directory -> File directory or directory of files to parse.

Output:

 $value     -> '0' = Successful / '-1' = Un-successful

Example:

 Warning: This is a private function called by 'ConvertMedlineXMLToW2V()'. It should not be called outside of xmltow2v module.

=head3 _ParseXMLString

Description:

 Parses passed string parameter for Medline XML article title and abstract data and appends found data to the text corpus.

Input:

 $string -> Medline XML string data to parse.

Output:

 None

Example:

 Warning: This is a private function called by "ConvertMedlineXMLToW2V()" and "_ThreadedConvert()". It should not be called outside of xmltow2v module.

=head3 _CheckParseRequirements

Description:

 Checks passed string parameter to see if it contains relevant data and XML::Twig handler is initialized.

Input:

 $string -> String data to check

Output:

 $value  -> '0' = Successful / '-1' = Un-successful

Example:

 Warning: This is a private function called "_ParseXMLString()". It should not be called outside of xmltow2v module.

=head3 _CheckForNullData

Description:

 Checks passed string parameter for "(null)" string.

Input:

 $string -> String data to be checked.

Output:

 $value  -> '1' = True/Null data or '0' = False/Valid data

Example:

 Warning: This is a private function called by "new()" and "_ParseXMLString()". It should not be called outside of xmltow2v module.

=head3 _RemoveXMLVersion

Description:

 Removes the XML Version string prior to parsing the XML string data. (Depreciated)

Input:

 $string -> Medline XML string data

Output:

 None

Example:

 Warning: This is a private function called by "new()" and "_ParseXMLString()". It should not be called outside of xmltow2v module.

=head3 _ParseMedlineCitationSet

Description:

 Parses 'MedlineCitationSet' tag data in Medline XML file.

Input:

 $twigHandler -> XML::Twig handler
 $root        -> Beginning of XML directory to parse. ( Directory in Medline XML string data )

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _ParseMedlineArticle

Description:

 Parses 'MedlineArticle' tag data in Medline XML file.

Input:

 $medlineArticle -> Current Medline article directory in XML data (XML::Twig directory)

Output:

 $value          -> '1' = Finished parsing Medline article.

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _ParseDateCreated

Description:

 Parses 'DateCreated' tag data in Medline XML file.

Input:

 $article -> Current Medline article in XML data (XML::Twig directory)

Output:

 $date    -> 'XX/XX/XXXX' (Month/Day/Year)

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _ParseArticle

Description:

 Parses 'Article' tag data in Medline XML file. Fetches 'ArticleTitle', 'Journal' and 'Abstract' XML tags.

Input:

 $article -> Current Medline article in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _ParseJournal

Description:

 Parses 'Journal' tag data in Medline XML file. Fetches 'Title' XML tag.

Input:

 $journalRoot -> Current Medline journal directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _ParseOtherAbstract

Description:

 Parses 'Abstract' tag data in Medline XML file. Fetches 'AbstractText' XML tag.

Input:

 $abstractRoot -> Current Medline abstract directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _QuickParseDateCreated

Description:

 Parses 'DateCreated' tag data in Medline XML file. Used when 'QuickParse' member variable is enabled. Sets $tempDate member variable to parsed 'DateCreated' tag data.

Input:

 $twigHandler -> 'XML::Twig' handler
 $article     -> Current Medline article directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _QuickParseJournal

Description:

 Parses 'Journal' tag data in Medline XML file. Fetches 'Title' XML tag. Used when 'QuickParse' member variable is enabled.
 Sets $tempStr to parsed data and stores in text corpus.

Input:

 $twigHandler -> 'XML::Twig' handler.
 $journalRoot -> Current Medline journal directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _QuickParseArticle

Description:

 Parses 'Article' tag data in Medline XML file. Fetches 'ArticleTitle' and 'Abstract' XML tags. Used when 'QuickParse' member variable is enabled.
 Sets $tempStr to parsed data and stores in text corpus.

Input:

 $twigHandler -> 'XML::Twig' handler.
 $article     -> Current Medline article directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 _QuickParseOtherAbstract

Description:

 Parses 'Abstract' tag data in Medline XML file. Fetches 'AbstractText' XML tag. Used when 'QuickParse' member variable is enabled.
 Sets $tempStr to parsed data and stores in text corpus.

Input:

 $twigHandler -> 'XML::Twig' handler.
 $anstractRoot -> Current Medline abstract directory in XML data (XML::Twig directory)

Output:

 None

Example:

 Warning: This is a private function and is called by xmltow2v's XML::Twig handler. It should not be called outside of xmltow2v module.

=head3 CreateCompoundWordBST

Description:

 Creates a binary search tree using compound word data in memory and stores root node. This also clears the compound word array afterwards.

 Warning: Compound word file must be loaded into memory using ReadCompoundWordDataFromFile() prior to calling this method. This function
          will also delete the compound word array upon completion as it will no longer be necessary.

Input:

 None

Output:

 $value -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $xmlconv->CreateCompoundWordBST();

=head3 CompoundifyString

Description:

 Compoundifies string parameter based on compound word data in memory using the compound word binary search tree.

 Warning: Compound word file must be loaded into memory using ReadCompoundWordDataFromFile() prior to calling this method.

Input:

 $string -> String to compoundify

Output:

 $string -> Compounded string or "(null)" if string parameter is not defined.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $xmlconv->CreateCompoundWordBST();
 my $compoundedString = $xmlconv->CompoundifyString( "String to compoundify" );
 print( "Compounded String: $compoundedString\n" );

 undef( $xmlconv );

=head3 _CompoundifySearch

Description:

 Recursive method used by CompoundifyString() to fetch compound word data in binary search tree.

 Warning: This function requires specific parameters and should not be called outside of CompoundifyString() method.

Input:

 $stringArrayRef -> Array reference containing string data
 $oldNode        -> Last 'Word2vec::Node' data match was found
 $searchStr      -> Search phrase
 $index          -> Current string array index

Output:

 Word2vec::Node  -> Last node containing positive search phrase match

Example:

 Warning: This is a private function and is called by 'CompoundifyString()'. It should not be called outside of xmltow2v module.

=head3 ReadCompoundWordDataFromFile

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

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ReadCompoundWordDataFromFile( "samples/compoundword.txt", 1 );

 undef( $xmlconv );

=head3 SaveCompoundWordListToFile

Description:

 Saves compound word data in memory to a specified file location.

Input:

 $savePath -> Path to save compound word list to file.

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ReadCompoundWordDataFromFile( "samples/compoundword.txt" );
 $xmlconv->SaveCompoundWordDataFromFile( "samples/newcompoundword.txt" );
 undef( $xmlconv );

=head3 ReadTextFromFile

Description:

 Reads a plain text file with utf8 encoding in memory. Returns string data if successful and "(null)" if unsuccessful.

Input:

 $filePath -> Text file to read into memory

Output:

 $string   -> String data if successful or "(null)" if un-successful.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $textData = $xmlconv->ReadTextFromFile( "samples/textcorpus.txt" );
 print( "Text Data: $textData\n" );
 undef( $xmlconv );

=head3 SaveTextToFile

Description:

 Saves a plain text file with utf8 encoding in a specified location.

Input:

 $savePath -> Path to save string data.
 $string   -> String to save

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $result = $xmlconv->SaveTextToFile( "text.txt", "Hello world!" );

 print( "File saved\n" ) if $result == 0;
 print( "File unable to save\n" ) if $result == -1;

 undef( $xmlconv );

=head3 _ReadXMLDataFromFile

Description:

 Reads an XML file from a specified location. Returns string in memory if successful and "(null)" if unsuccessful.

Input:

 $filePath -> File to read given path

Output:

 $value    -> '0' = Successful / '-1' = Un-successful

Example:

 Warning: This is a private function and is called by XML::Twig parsing functions. It should not be called outside of xmltow2v module.

=head3 _SaveTextCorpusToFile

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

=head3 IsDateInSpecifiedRange

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

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 print( "Is \"01/01/2004\" within the date range: \"02/21/1985\" to \"08/13/2016\"?\n" );
 print( "Yes\n" ) if $xmlconv->IsDateInSpecifiedRange( "01/01/2004", "02/21/1985", "08/13/2016" ) == 1;
 print( "No\n" ) if $xmlconv->IsDateInSpecifiedRange( "01/01/2004", "02/21/1985", "08/13/2016" ) == 0;

 undef( $xmlconv );

=head3 IsFileOrDirectory

Description:

 Checks to see if specified path is a file or directory.

Input:

 $path   -> File or directory path. (String)

Output:

 $string -> Returns: "file" = file, "dir" = directory and "unknown" if the path is not a file or directory (undefined).

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $path = "path/to/a/directory";

 print( "Is \"$path\" a file or directory? " . $xmlconv->IsFileOrDirectory( $path ) . "\n" );

 $path = "path/to/a/file.file";

 print( "Is \"$path\" a file or directory? " . $xmlconv->IsFileOrDirectory( $path ) . "\n" );

 undef( $xmlconv );

=head3 RemoveSpecialCharactersFromString

Description:

 Removes special characters from string parameter, removes extra spaces and converts text to lowercase.

 Note: This method is called when parsing and compiling Medline title/abstract data.

Input:

 $string -> String passed to remove special characters from and convert to lowercase.

Output:

 $string -> String with all special characters removed and converted to lowercase.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();

 my $str = "Heart Attack is$ an!@ also KNOWN as an Acute MYOCARDIAL inFARCTion!";

 print( "Original String: $str\n" );

 $str = $xmlconv->RemoveSpecialCharactersFromString( $str );

 print( "Modified String: $str\n" );

 undef( $xmlconv );

=head3 GetFileType

Description:

 Returns file data type (string).

Input:

 $filePath -> File to check located at file path

Output:

 $string   -> File type

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $fileType = $xmlconv->GetFileType( "samples/textcorpus.txt" );

 undef( $xmlconv );

=head3 _DateCheck

Description:

 Checks specified begin and end date strings for formatting and logic errors.

Input:

 None

Output:

 $value   -> "0" = Passed Checks / "-1" = Failed Checks

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 print "Passed Date Checks\n" if ( $xmlconv->_DateCheck() == 0 );
 print "Failed Date Checks\n" if ( $xmlconv->_DateCheck() == -1 );

 undef( $xmlconv );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Xmltow2v object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $debugLog = $xmlconv->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;


 undef( $xmlconv );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Xmltow2v object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $writeLog = $xmlconv->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $xmlconv );

=head3 GetStoreTitle

Description:

 Returns the _storeTitle member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $storeTitle = $xmlconv->GetStoreTitle();

 print( "Store Title Option: Enabled\n" ) if $storeTitle == 1;
 print( "Store Title Option: Disabled\n" ) if $storeTitle == 0;

 undef( $xmlconv );

=head3 GetStoreAbstract

Description:

 Returns the _storeAbstract member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $storeAbstract = $xmlconv->GetStoreAbstract();

 print( "Store Abstract Option: Enabled\n" ) if $storeAbsract == 1;
 print( "Store Abstract Option: Disabled\n" ) if $storeAbstract == 0;

 undef( $xmlconv );

=head3 GetQuickParse

Description:

 Returns the _quickParse member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $quickParse = $xmlconv->GetQuickParse();

 print( "Quick Parse Option: Enabled\n" ) if $quickParse == 1;
 print( "Quick Parse Option: Disabled\n" ) if $quickParse == 0;

 undef( $xmlconv );

=head3 GetCompoundifyText

Description:

 Returns the _compoundifyText member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $compoundify = $xmlconv->GetCompoundifyText();

 print( "Compoundify Text Option: Enabled\n" )  if $compoundify == 1;
 print( "Compoundify Text Option: Disabled\n" ) if $compoundify == 0;

 undef( $xmlconv );

=head3 GetStoreAsSentencePerLine

Description:

 Returns the _storeAsSentencePerLine member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> '1' = True / '0' = False

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $storeAsSentencePerLine = $xmlconv->GetStoreAsSentencePerLine();

 print( "Store As Sentence Per Line: Enabled\n" )  if $storeAsSentencePerLine == 1;
 print( "Store As Sentence Per Line: Disabled\n" ) if $storeAsSentencePerLine == 0;

 undef( $xmlconv );

=head3 GetNumOfThreads

Description:

 Returns the _numOfThreads member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> Number of threads

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $numOfThreads = $xmlconv->GetNumOfThreads();

 print( "Number of threads: $numOfThreads\n" );

 undef( $xmlconv );

=head3 GetWorkingDir

Description:

 Returns the _workingDir member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $string -> Working directory string

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $workingDirectory = $xmlconv->GetWorkingDir();

 print( "Working Directory: $workingDirectory\n" );

 undef( $xmlconv );

=head3 GetSavePath

Description:

 Returns the _saveDir member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $string -> Save directory string

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $savePath = $xmlconv->GetSavePath();

 print( "Save Directory: $savePath\n" );

 undef( $xmlconv );

=head3 GetBeginDate

Description:

 Returns the _beginDate member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $date -> Beginning date range - Format: XX/XX/XXXX (Mon/Day/Year)

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $date = $xmlconv->GetBeginDate();

 print( "Date: $date\n" );

 undef( $xmlconv );

=head3 GetEndDate

Description:

 Returns the _endDate member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $date -> End date range - Format: XX/XX/XXXX (Mon/Day/Year).

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $date = $xmlconv->GetEndDate();

 print( "Date: $date\n" );

 undef( $xmlconv );

=head3 GetXMLStringToParse

Returns the XML data (string) to be parsed.

Description:

 Returns the _xmlStringToParse member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $string -> Medline XML data string

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $xmlStr = $xmlconv->GetXMLStringToParse();

 print( "XML String: $xmlStr\n" );

 undef( $xmlconv );

=head3 GetTextCorpusStr

Description:

 Returns the _textCorpusStr member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $string -> Text corpus string

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $str = $xmlconv->GetTextCorpusStr();

 print( "Text Corpus: $str\n" );

 undef( $xmlconv );

=head3 GetFileHandle

Description:

 Returns the _fileHandle member variable set during Word2vec::Xmltow2v object instantiation of new function.

 Warning: This is a private function. File handle is used by WriteLog() method. Do not manipulate this file handle as errors can result.

Input:

 None

Output:

 $fileHandle -> Returns file handle for WriteLog() method.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $fileHandle = $xmlconv->GetFileHandle();

 undef( $xmlconv );

=head3 GetTwigHandler

Returns XML::Twig handler.

Description:

 Returns the _twigHandler member variable set during Word2vec::Xmltow2v object instantiation of new function.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Output:

 $twigHandler -> XML::Twig handler.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $xmlHandler = $xmlconv->GetTwigHandler();

 undef( $xmlconv );

=head3 GetParsedCount

Description:

 Returns the _parsedCount member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $value -> Number of parsed Medline articles.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $numOfParsed = $xmlconv->GetParsedCount();

 print( "Number of parsed Medline articles: $numOfParsed\n" );

 undef( $xmlconv );

=head3 GetTempStr

Description:

 Returns the _tempStr member variable set during Word2vec::Xmltow2v object instantiation of new function.

 Warning: This is a private function and should not be called or manipulated. Used by module as a temporary storage
          location for parsed Medline 'Title' and 'Abstract' flag string data.

Input:

 None

Output:

 $string -> Temporary string storage location.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $tempStr = $xmlconv->GetTempStr();

 print( "Temp String: $tempStr\n" );

 undef( $xmlconv );

=head3 GetTempDate

Description:

 Returns the _tempDate member variable set during Word2vec::Xmltow2v object instantiation of new function.
 Used by module as a temporary storage location for parsed Medline 'DateCreated' flag string data.

Input:

 None

Output:

 $date -> Date string - Format: XX/XX/XXXX (Mon/Day/Year).

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $date = $xmlconv->GetTempDate();

 print( "Temp Date: $date\n" );

 undef( $xmlconv );

=head3 GetCompoundWordAry

Description:

 Returns the _compoundWordAry member array reference set during Word2vec::Xmltow2v object instantiation of new function.

 Warning: Compound word data must be loaded in memory first via ReadCompoundWordDataFromFile().

Input:

 None

Output:

 $arrayReference -> Compound word array reference.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $arrayReference = $xmlconv->GetCompoundWordAry();
 my @compoundWord = @{ $arrayReference };

 print( "Compound Word Array: @compoundWord\n" );

 undef( $xmlconv );

=head3 GetCompoundWordBST

Description:

 Returns the _compoundWordBST member variable set during Word2vec::Xmltow2v object instantiation of new function.

Input:

 None

Output:

 $bst -> Compound word binary search tree.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $bst = $xmlconv->GetCompoundWordBST();

 undef( $xmlconv );

=head3 GetMaxCompoundWordLength

Description:

 Returns the _maxCompoundWordLength member variable set during Word2vec::Xmltow2v object instantiation of new function.

 Note: If not defined, it is automatically set to and returns 20.

Input:

 None

Output:

 $value -> Maximum number of compound words in a given phrase.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $compoundWordLength = $xmlconv->GetMaxCompoundWordLength();

 print( "Maximum Compound Word Length: $compoundWordLength\n" );

 undef( $xmlconv );

=head3 GetOverwriteExistingFile

Description:

 Returns the _overwriteExisitingFile member variable set during Word2vec::Xmltow2v object instantiation of new function.
 Enables overwriting of existing text corpus if set to '1' or appends to the existing text corpus if set to '0'.

Input:

 None

Output:

 $value -> '1' = Overwrite existing file / '0' = Append to exiting file.

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $overwriteExitingFile = $xmlconv->GetOverwriteExistingFile();

 print( "Overwrite Existing File? YES\n" ) if ( $overwriteExistingFile == 1 );
 print( "Overwrite Existing File? NO\n" ) if ( $overwriteExistingFile == 0 );

 undef( $xmlconv );

=head2 Mutator Functions

=head3 SetStoreTitle

Description:

 Sets member variable to passed integer parameter. Instructs module to store article title if true or omit if false.

Input:

 $value -> '1' = Store Titles / '0' = Omit Titles

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetStoreTitle( 1 );

 undef( $xmlconv );

=head3 SetStoreAbstract

Description:

 Sets member variable to passed integer parameter. Instructs module to store article abstracts if true or omit if false.

Input:

 $value -> '1' = Store Abstracts / '0' = Omit Abstracts

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetStoreAbstract( 1 );

 undef( $xmlconv );

=head3 SetWorkingDir

Description:

 Sets member variable to passed string parameter. Represents the working directory.

Input:

 $string -> Working directory string

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetWorkingDir( "/samples/" );

 undef( $xmlconv );

=head3 SetSavePath

Description:

 Sets member variable to passed integer parameter. Represents the text corpus save path.

Input:

 $string -> Text corpus save path

Output:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetSavePath( "samples/textcorpus.txt" );

 undef( $xmlconv );

=head3 SetQuickParse

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize quick parse
 routines to speed up text corpus compilation. This method is somewhat less accurate due to its non-exhaustive nature.

Input:

 $value -> '1' = Enable Quick Parse / '0' = Disable Quick Parse

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetQuickParse( 1 );

 undef( $xmlconv );

=head3 SetCompoundifyText

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize 'compoundify' option if true.

 Warning: This requires compound word data to be loaded into memory with ReadCompoundWordDataFromFile() method prior
          to executing text corpus compilation.

Input:

 $value -> '1' = Compoundify text / '0' = Do not compoundify text

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetCompoundifyText( 1 );

 undef( $xmlconv );

=head3 SetStoreAsSentencePerLine

Description:

 Sets member variable to passed integer parameter. Instructs module to utilize 'storeAsSentencePerLine' option if true.

Input:

 $value -> '1' = Store as sentence per line / '0' = Do not store as sentence per line

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetStoreAsSentencePerLine( 1 );

 undef( $xmlconv );

=head3 SetNumOfThreads

Description:

 Sets member variable to passed integer parameter. Sets the requested number of threads to parse Medline XML files
 and compile the text corpus.

Input:

 $value -> Integer (Positive value)

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetNumOfThreads( 4 );

 undef( $xmlconv );

=head3 SetBeginDate

Description:

 Sets member variable to passed string parameter. Sets beginning date range for earliest articles to store, by
 'DateCreated' Medline tag, within the text corpus during compilation.

 Note: Expected format - "XX/XX/XXXX" (Mon/Day/Year)

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetBeginDate( "01/01/2004" );

 undef( $xmlconv );

=head3 SetEndDate

Description:

 Sets member variable to passed string parameter. Sets ending date range for latest article to store, by
 'DateCreated' Medline tag, within the text corpus during compilation.

 Note: Expected format - "XX/XX/XXXX" (Mon/Day/Year)

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetEndDate( "08/13/2016" );

 undef( $xmlconv );

=head3 SetXMLStringToParse

Description:

 Sets member variable to passed string parameter. This string normally consists of Medline XML data to be
 parsed for text corpus compilation.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetXMLStringToParse( "Hello World!" );

 undef( $xmlconv );

=head3 SetTextCorpusStr

Description:

 Sets member variable to passed string parameter. Overwrites any stored text corpus data in memory to the string parameter.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetTextCorpusStr( "Hello World!" );

 undef( $xmlconv );

=head3 AppendStrToTextCorpus

Description:

 Sets member variable to passed string parameter. Appends string parameter to text corpus string in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->AppendStrToTextCorpus( "Hello World!" );

 undef( $xmlconv );

=head3 ClearTextCorpus

Description:

 Clears text corpus data in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ClearTextCorpus();

 undef( $xmlconv );

=head3 SetTempStr

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

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetTempStr( "Hello World!" );

 undef( $xmlconv );

=head3 AppendToTempStr

Description:

 Appends string parameter to temporary member string in memory.

 Note: This removes special characters and converts all characters to lowercase.

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> String

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->AppendToTempStr( "Hello World!" );

 undef( $xmlconv );

=head3 ClearTempStr

 Clears the temporary string storage in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ClearTempStr();

 undef( $xmlconv );

=head3 SetTempDate

Description:

 Sets member variable to passed string parameter. Sets temporary date string to passed string.

 Note: Date Format - "XX/XX/XXXX" (Mon/Day/Year)

 Warning: This is a private function and should not be called or manipulated.

Input:

 $string -> Date string - Format: "XX/XX/XXXX"

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetTempDate( "08/13/2016" );

 undef( $xmlconv );

=head3 ClearTempDate

Description:

 Clears the temporary date storage location in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ClearTempDate();

 undef( $xmlconv );

=head3 SetCompoundWordAry

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

 use Word2vec::Xmltow2v;

 my @compoundWordAry = ( "big dog", "respiratory failure", "seven large masses" );

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetCompoundWordAry( \@compoundWordAry );

 undef( $xmlconv );

=head3 ClearCompoundWordAry

Description:

 Clears compound word array in memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ClearCompoundWordAry();

 undef( $xmlconv );

=head3 SetCompoundWordBST

Description:

 Sets member variable to passed Word2vec::Bst parameter. Sets compound word binary search tree to passed binary tree parameter.

 Note: Un-defines previous binary tree if existing.

 Warning: This is a private function and should not be called or manipulated.

Input:

 Word2vec::Bst -> Binary Search Tree

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my @compoundWordAry = ( "big dog", "respiratory failure", "seven large masses" );
 @compoundWordAry = sort( @compoundWordAry );

 my $arySize = @compoundWordAry;

 my $bst = Word2vec::Bst;
 $bst->CreateTree( \@compoundWordAry, 0, $arySize, undef );

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetCompoundWordBST( $bst );

 undef( $xmlconv );

=head3 ClearCompoundWordBST

Description:

 Clears/Un-defines existing compound word binary search tree from memory.

 Warning: This is a private function and should not be called or manipulated.

Input:

 None

Ouput:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->ClearCompoundWordBST();

 undef( $xmlconv );

=head3 SetMaxCompoundWordLength

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

 use Word2vec::Xmltow2v;

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->SetMaxCompoundWordLength( 8 );

 undef( $xmlconv );

=head3 SetOverwriteExistingFile

Description:

 Sets member variable to passed integer parameter. Sets option to overwrite existing text corpus during compilation
 if 1 or append to existing text corpus if 0.

Input:

 $value -> '1' = Overwrite existing text corpus / '0' = Append to existing text corpus during compilation.

Output:

 None

Example:

 use Word2vec::Xmltow2v;

 my $xmltow2v = Word2vec::Xmltow2v->new();
 $xmltow2v->SetOverWriteExistingFile( 1 );

 undef( $xmltow2v );

=head2 Debug Functions

=head3 GetTime

Description:

 Returns current time string in "Hour:Minute:Second" format.

Input:

 None

Output:

 $string -> XX:XX:XX ("Hour:Minute:Second")

Example:

 use Word2vec::Xmltow2v:

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $time = $xmlconv->GetTime();

 print( "Current Time: $time\n" ) if defined( $time );

 undef( $xmlconv );

=head3 GetDate

Description:

 Returns current month, day and year string in "Month/Day/Year" format.

Input:

 None

Output:

 $string -> XX/XX/XXXX ("Month/Day/Year")

Example:

 use Word2vec::Xmltow2v:

 my $xmlconv = Word2vec::Xmltow2v->new();
 my $date = $xmlconv->GetDate();

 print( "Current Date: $date\n" ) if defined( $date );

 undef( $xmlconv );

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

 use Word2vec::Xmltow2v:

 my $xmlconv = Word2vec::Xmltow2v->new();
 $xmlconv->WriteLog( "Hello World" );

 undef( $xmlconv );

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
