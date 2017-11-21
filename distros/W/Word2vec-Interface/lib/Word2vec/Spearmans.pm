#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    05/09/2016                                                             #
#    Revised: 09/09/2017                                                             #
#    UMLS Similarity Word2Phrase Executable Interface Module                         #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                 Spearman's Rank Correlation Module for Word2vec::Interface         #
#    Features:                                                                       #
#    =========                                                                       #
#                 Calculates Spearman's Rank Correlation Scores                      #
#                                                                                    #
######################################################################################


package Word2vec::Spearmans;

use strict;
use warnings;


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
        _precision          => shift,               # Integer
        _isFileOfWords      => shift,               # undef = Auto-Detect, 0 = CUI Terms, 1 = Word Terms
        _printN             => shift,               # undef = Do Not Print N / defined = Print N
        _aCount             => shift,               # Integer
        _bCount             => shift,               # Integer
        _NValue             => shift,               # Integer
    };

    # Set debug log variable to false if not defined
    $self->{ _debugLog }      =  0 if !defined( $self->{ _debugLog } );
    $self->{ _writeLog }      =  0 if !defined( $self->{ _writeLog } );
    $self->{ _precision }     =  4 if !defined( $self->{ _precision } );
    $self->{ _aCount }        = -1 if !defined( $self->{ _aCount } );
    $self->{ _bCount }        = -1 if !defined( $self->{ _bCount } );
    $self->{ _NValue }        = -1 if !defined( $self->{ _NValue } );


    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:encoding(UTF-8)', 'SpearmansLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }

    bless $self, $class;
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

sub CalculateSpearmans
{
    my ( $self, $fileA, $fileB, $includeCountsInResults ) = @_;

    # Check(s)
    print( "Error: This Function Requires Two Arguments\n" ) if $self->GetDebugLog() == 0 && ( !defined( $fileA ) || !defined( $fileB ) );
    $self->WriteLog( "CalculateSpearmans - Error: \"FileA\" Not Defined" ) if !defined( $fileA );
    $self->WriteLog( "CalculateSpearmans - Error: \"FileB\" Not Defined" ) if !defined( $fileB );
    if( !defined( $fileA ) || !defined( $fileB ) )
    {
        $self->_ResetVariables();
        return undef;
    }

    print( "Error: Unable To Locate One Or More Files\n" ) if $self->GetDebugLog() == 0 && ( !( -e $fileA ) || !( -e $fileB ) );
    $self->WriteLog( "CalculateSpearmans - Error: File \"$fileA\" Does Not Exist" ) if !( -e $fileA );
    $self->WriteLog( "CalculateSpearmans - Error: File \"$fileB\" Does Not Exist" ) if !( -e $fileB );
    if( !( -e $fileA ) || !( -e $fileB ) )
    {
        $self->_ResetVariables();
        return undef;
    }

    print( "Error: One Or More Files Are Empty / 0-Byte Files\n" ) if $self->GetDebugLog() == 0 && ( -z $fileA || -z $fileB );
    $self->WriteLog( "CalculateSpearmans - Error: File \"$fileA\" Exists But Has No Data / File Size = 0 bytes" ) if ( -z $fileA );
    $self->WriteLog( "CalculateSpearmans - Error: File \"$fileB\" Exists But Has No Data / File Size = 0 bytes" ) if ( -z $fileB );
    if( -z $fileA || -z $fileB )
    {
        $self->_ResetVariables();
        return undef;
    }

    my $rank       = 0;
    my $aCUICheck  = 0;   my $bCUICheck  = 0;
    my $aMean      = 0 ;  my $bMean      = 0;
    my $aCount     = 0 ;  my $bCount     = 0;
    my %aHash      = ();  my %bHash      = ();
    my %aList      = ();  my %bList      = ();
    my %aRank      = ();  my %bRank      = ();
    my $aNegative  = 0 ;  my $bNegative  = 0;
    my $aTotal     = 0 ;  my $bTotal     = 0;
    my $oldIsFileOfWords = $self->GetIsFileOfWords();
    my $fileAIsCUIFile = undef;
    my $fileBIsCUIFile = undef;

    my $errorOpeningFile = 0;

    # Open $fileA Data
    $self->WriteLog( "CalculateSpearmans - Opening File: \"$fileA\"" );
    open( A, "<:",$fileA ) or $errorOpeningFile = 1;

    # Check
    $self->WriteLog( "CalculateSpearmans - Error Opening \"$fileA\"" ) if ( $errorOpeningFile == 1 );
    if( $errorOpeningFile == 1 )
    {
        $self->_ResetVariables();
        return undef;
    }

    # Read $fileA Data Into Memory Using $_ variable
    while( <A> )
    {
        chomp;  
        $_ = lc;
        
        # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
        $_ =~ s/^\s+|\s(?=\s)|\s+$//g;
    
        my( $score, $term1, $term2 ) = split( /<>/ );

        # Auto-Detect If Terms Are CUIs or Words
        if( $aCUICheck == 0 && !defined( $self->GetIsFileOfWords() ) )
        {
            my $isCUI1 = $self->_IsCUI( $term1 );
            my $isCUI2 = $self->_IsCUI( $term2 );

            $self->WriteLog( "CalculateSpearmans - File: \"$fileA\" Detected As Word File" ) if ( $isCUI1 == 0 && $isCUI2 == 0 );
            $self->WriteLog( "CalculateSpearmans - File: \"$fileA\" Detected As CUI File" ) if ( $isCUI1 == 1 && $isCUI2 == 1 );
            $self->SetIsFileOfWords( 1 ) if( $isCUI1 == 0 && $isCUI2 == 0 );
            $self->SetIsFileOfWords( 0 ) if( $isCUI1 == 1 && $isCUI2 == 1 );

            $fileAIsCUIFile = 0 if ( $isCUI1 == 0 && $isCUI2 == 0 );
            $fileAIsCUIFile = 1 if ( $isCUI1 == 1 && $isCUI2 == 1 );
            $aCUICheck = 1;

            # Check(s)
            $self->WriteLog( "CalculateSpearmans - Error: \"$fileA\" - Term1 Is CUI and Term2 Is Word" ) if ( $isCUI1 == 1 && $isCUI2 == 0 );
            $self->WriteLog( "CalculateSpearmans - Error: \"$fileA\" - Term1 Is Word and Term2 Is CUI" ) if ( $isCUI1 == 0 && $isCUI2 == 1 );
            if ( $isCUI1 != $isCUI2 )
            {
                close( A );
                $self->SetIsFileOfWords( undef );
                $self->_ResetVariables();
                return undef;
            }
        }

        my $cui1 = "";    my $cui2 = "";

        if( defined( $self->GetIsFileOfWords() ) && $self->GetIsFileOfWords() == 1 )
        {
            $cui1 = $term1;
            $cui2 = $term2;
        }
        else
        {
            $term1 =~ /(C[0-9]+)/;
            $cui1 = $1 if defined( $1 );

            $term2 =~ /(C[0-9]+)/;
            $cui2 = $1 if defined( $1 );
        }

        if( $score == -1.0 )
        {
            $aNegative++;
            next;
        }

        $aTotal++;
        push( @{ $aHash{ $score } }, "$cui1 $cui2" );
        $aList{ "$cui1 $cui2" }++;
    }

    # Clean Up
    $self->WriteLog( "CalculateSpearmans - Closing File: \"$fileA\"" );
    $self->SetIsFileOfWords( $oldIsFileOfWords );
    $errorOpeningFile = 0;
    close( A );


    # Open $fileB Data
    $self->WriteLog( "CalculateSpearmans - Opening File: \"$fileB\"" );
    open( B, "<:",$fileB ) or $errorOpeningFile = 1;

    # Check
    $self->WriteLog( "CalculateSpearmans - Error Opening \"$fileB\"" ) if ( $errorOpeningFile == 1 );
    if( $errorOpeningFile == 1 )
    {
        $self->_ResetVariables();
        return undef;
    }

    # Read $fileB Data Into Memory Using $_ variable
    while( <B> )
    {
        chomp;
        $_ = lc;
        
        # Removes Spaces At Both Ends Of String And More Than Once Space In-Between Ends
        $_ =~ s/^\s+|\s(?=\s)|\s+$//g;
        
        my( $score, $term1, $term2 ) = split( /<>/ );

        # Auto-Detect If Terms Are CUIs Or Words
        if( $bCUICheck == 0 && !defined( $self->GetIsFileOfWords() ) )
        {
            my $isCUI1 = $self->_IsCUI( $term1 );
            my $isCUI2 = $self->_IsCUI( $term2 );

            $self->WriteLog( "CalculateSpearmans - File: \"$fileA\" Detected As Word File" ) if ( $isCUI1 == 0 && $isCUI2 == 0 );
            $self->WriteLog( "CalculateSpearmans - File: \"$fileA\" Detected As CUI File" ) if ( $isCUI1 == 1 && $isCUI2 == 1 );
            $self->SetIsFileOfWords( 1 ) if( $isCUI1 == 0 && $isCUI2 == 0 );
            $self->SetIsFileOfWords( 0 ) if( $isCUI1 == 1 && $isCUI2 == 1 );

            $fileAIsCUIFile = 0 if ( $isCUI1 == 0 && $isCUI2 == 0 );
            $fileAIsCUIFile = 1 if ( $isCUI1 == 1 && $isCUI2 == 1 );
            $bCUICheck = 1;

            # Check(s)
            $self->WriteLog( "CalculateSpearmans - Error: \"$fileB\" - Term1 Is CUI and Term2 Is Word" ) if ( $isCUI1 == 1 && $isCUI2 == 0 );
            $self->WriteLog( "CalculateSpearmans - Error: \"$fileB\" - Term1 Is Word and Term2 Is CUI" ) if ( $isCUI1 == 0 && $isCUI2 == 1 );
            if ( $isCUI1 != $isCUI2 )
            {
                close( B );
                $self->SetIsFileOfWords( undef );
                $self->_ResetVariables();
                return undef;
            }
        }

        my $cui1 = "";    my $cui2 = "";

        if( defined( $self->GetIsFileOfWords() ) && $self->GetIsFileOfWords() == 1 )
        {
            $cui1 = $term1;
            $cui2 = $term2;
        }
        else
        {
            $term1 =~ /(C[0-9]+)/;
            $cui1 = $1 if defined( $1 );

            $term2 =~ /(C[0-9]+)/;
            $cui2 = $1 if defined( $1 );
        }

        if( $score == -1.0 )
        {
            $bNegative++;
            next;
        }

        $bTotal++;
        push( @{ $bHash{ $score } }, "$cui1 $cui2" );
        $bList{ "$cui1 $cui2" }++;
    }

    # Clean Up
    $self->WriteLog( "CalculateSpearmans - Closing File: \"$fileB\"" );
    $self->SetIsFileOfWords( $oldIsFileOfWords );
    $errorOpeningFile = 0;
    close( B );

    # Post Read File Check
    $self->WriteLog( "CalculateSpearmans - Error: \"$fileA\" Detected As Word File And \"$fileB\" Detected As CUI File" ) if ( defined( $fileAIsCUIFile ) && defined( $fileBIsCUIFile ) && $fileAIsCUIFile == 0 && $fileBIsCUIFile == 1 );
    $self->WriteLog( "CalculateSpearmans - Error: \"$fileA\" Detected As CUI File And \"$fileB\" Detected As Word File" ) if ( defined( $fileAIsCUIFile ) && defined( $fileBIsCUIFile ) && $fileAIsCUIFile == 1 && $fileBIsCUIFile == 0 );
    if( defined( $fileAIsCUIFile ) && defined( $fileBIsCUIFile ) )
    {
        if( $fileAIsCUIFile == 0 && $fileBIsCUIFile == 1 )
        {
            $self->_ResetVariables();
            return undef;
        }
        elsif( $fileAIsCUIFile == 1 && $fileBIsCUIFile == 0 )
        {
            $self->_ResetVariables();
            return undef;
        }
    }

    $self->WriteLog( "CalculateSpearmans - Calculating Spearman's Rank Correlation" );

    # Calculate Spearman's Rank Correlation Score
    $rank = 1;
    for my $score ( sort( { $b<=>$a } keys %aHash ) )
    {
        my $count         = 0;
        my $computedRank  = 0;
        my $cRank = $rank + 1;

        for my $term ( @{ $aHash{ $score } } )
        {
            if( exists( $bList{ $term } ) )
            {
                $computedRank += $cRank;
                $count++;
                $cRank++;
            }
        }

        next if ( $count == 0 );

        $computedRank = $computedRank / $count;

        for my $term ( @{ $aHash{ $score } } )
        {
            next if( !exists( $bList{ $term } ) );

            $aRank{ $term } = $computedRank;
            $aMean         += $computedRank;
            $aCount++;
            $rank++;
        }
    }

    $self->_SetACount( $aCount );

    # Reset $rank
    $rank = 0;

    for my $score ( sort( { $b<=>$a } keys %bHash ) )
    {
        my $count         = 0;
        my $computedRank  = 0;
        my $cRank = $rank + 1;

        for my $term ( @{ $bHash{ $score } } )
        {
            if( exists( $aList{ $term } ) )
            {
                $computedRank += $cRank;
                $count++;
                $cRank++;
            }
        }

        next if ( $count == 0 );

        $computedRank = $computedRank / $count;

        for my $term ( @{ $bHash{ $score } } )
        {
            next if( !exists( $aList{ $term } ) );

            $bRank{ $term } = $computedRank;
            $bMean         += $computedRank;
            $bCount++;
            $rank++;
        }
    }

    $self->_SetBCount( $bCount );

    $self->WriteLog( "CalculateSpearmans - ACount -> $aCount : BCount -> $bCount" );

    # Check
    $self->WriteLog( "Error: aCount <= 0 / Cannot Continue" ) if ( $aCount <= 0 );
    $self->WriteLog( "Error: bCount <= 0 / Cannot Continue" ) if ( $bCount <= 0 );
    return undef if ( $aCount <= 0 || $bCount <= 0 );

    $aMean = $aMean / $aCount;
    $bMean = $bMean / $bCount;

    my $numerator    = 0;
    my $aDenominator = 0;
    my $bDenominator = 0;

    for my $term ( sort( keys %aRank ) )
    {
        my $ai = $aRank{ $term };
        my $bi = $bRank{ $term };

        $numerator += ( ( $ai - $aMean ) * ( $bi - $bMean ) );

        $aDenominator += ( ( $ai - $aMean ) ** 2 );
        $bDenominator += ( ( $bi - $bMean ) ** 2 );
    }

    my $denominator = sqrt( $aDenominator * $bDenominator );

    if( $denominator <= 0 )
    {
        $self->WriteLog( "CalculateSpearmans - Correlation Cannot Be Calculated" );
        $self->WriteLog( "File Does Not Contain Similar N-Grams" );
        $self->_ResetVariables();
        return undef;
    }

    my $pearsons    = $numerator / $denominator;
    my $floatFormat = join( '', '%', '.', $self->GetPrecision(), 'f' );
    my $score       = sprintf( $floatFormat, $pearsons );

    my $aN = $aTotal - $aNegative;
    my $bN = $bTotal - $bNegative;
    my $N  = $bN;

    $N = $aN if( $aN < $bN );

    $self->_SetNValue( $N );

    $self->WriteLog( "CalculateSpearmans - Spearman's Rank Correlation: $score" );
    $self->WriteLog( "CalculateSpearmans - N: $N" ) if( defined( $self->GetPrintN() ) );

    $score = "$score  $aCount : $bCount" if defined( $includeCountsInResults );

    $self->WriteLog( "CalculateSpearmans - Finished" );
    return $score;
}

sub IsFileWordOrCUIFile
{
    my ( $self, $filePath ) = @_;

    # Check(s)
    $self->WriteLog( "IsFileWordOrCUIFile - Error: File Path Not Defined" ) if !defined( $filePath );
    return undef if !defined( $filePath );

    $self->WriteLog( "IsFileWordOrCUIFile - Error: File Path Eq Empty String" ) if ( $filePath eq "" );
    return undef if ( $filePath eq "" );

    $self->WriteLog( "IsFileWordOrCUIFile - Error: File Does Not Exist" ) if !( -e $filePath );
    return undef if !( -e $filePath );

    my $errorOpeningFile = 0;
    open( FILE, "<:", "$filePath" ) or $errorOpeningFile = 1;

    # Check
    if ( $errorOpeningFile == 1 )
    {
        $self->WriteLog( "IsFileWordOrCUIFile - Error Opening File: \"$filePath\"" );
        close( FILE );
        return undef;
    }

    # Read First Line Of File
    $_ = <FILE>;
    chomp( $_ );
    my ( $score, $term1, $term2 ) = split( '<>', $_ );

    # Format Check
    # If Checking A Similarity File Without Spearman's Rank Correlation Scores, Adjust For This
    if( defined( $score ) && defined( $term1 ) && !defined( $term2 ) )
    {
        $term2 = $term1;
        $term1 = $score;
        $score = 0.0;
    }

    # Check(s)
    $self->WriteLog( "IsFileWordOrCUIFile - Error: Input File Format" ) if !defined( $score ) || !defined( $term1 ) || !defined( $term2 );
    return undef if !defined( $score ) || !defined( $term1 ) || !defined( $term2 );

    $score =~ s/[0-9].//g;
    $self->WriteLog( "IsFileWordOrCUIFile - Warning: Score Contains Erroneous Data" ) if ( $score ne "" );

    my $isTerm1CUI = $self->_IsCUI( $term1 );
    my $isTerm2CUI = $self->_IsCUI( $term2 );

    $self->WriteLog( "IsFileWordOrCUIFile - File Contains CUI Terms" ) if ( $isTerm1CUI == 1 && $isTerm2CUI == 1 );
    $self->WriteLog( "IsFileWordOrCUIFile - File Contains Word Terms" ) if ( $isTerm1CUI == 0 && $isTerm2CUI == 0 );

    close( FILE );

    return "cui"  if ( $isTerm1CUI == 1 && $isTerm2CUI == 1 );
    return "word" if ( $isTerm1CUI == 0 && $isTerm2CUI == 0 );
    return undef;
}

sub _IsCUI
{
    my ( $self, $term ) = @_;

    # Check
    $self->WriteLog( "_IsCUI - No Term Defined" ) if !defined( $term );

    $term = lc( $term );
    my @terms = split( 'c', $term );

    # Return False If There Are Not Two Elements After Splitting
    return 0 if( @terms != 2 );

    # If $term Is CUI, Then First Element Should Be Empty String
    return 0 if ( $terms[0] ne "" );

    # Remove Numbers From Second Element
    $terms[1] =~ s/[0-9]//g;

    # If $term Is CUI, Then After Removing All Number From Second Element An Empty String Is All That Is Left
    return 0 if ( $terms[1] ne "" );

    return 1;
}

sub _ResetVariables
{
    my ( $self ) = @_;
    $self->_SetACount( -1 );
    $self->_SetBCount( -1 );
    $self->_SetNValue( -1 );
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

sub GetPrecision
{
    my ( $self ) = @_;
    $self->{ _precision } = 4 if !defined ( $self->{ _precision } );
    return $self->{ _precision };
}

sub GetIsFileOfWords
{
    my ( $self ) = @_;
    return $self->{ _isFileOfWords };
}

sub GetPrintN
{
    my ( $self ) = @_;
    return $self->{ _printN };
}

sub GetACount
{
    my ( $self ) = @_;
    return $self->{ _aCount };
}

sub GetBCount
{
    my ( $self ) = @_;
    return $self->{ _bCount };
}

sub GetNValue
{
    my ( $self ) = @_;
    return $self->{ _NValue };
}


######################################################################################
#    Mutators
######################################################################################

sub SetPrecision
{
    my ( $self, $temp ) = @_;
    return $self->{ _precision } = $temp if defined ( $temp );
}

sub SetIsFileOfWords
{
    my ( $self, $temp ) = @_;
    return $self->{ _isFileOfWords } = $temp;
}

sub SetPrintN
{
    my ( $self, $temp ) = @_;
    return $self->{ _printN } = $temp;
}

sub _SetACount
{
    my ( $self, $temp ) = @_;
    return $self->{ _aCount } = $temp;
}

sub _SetBCount
{
    my ( $self, $temp ) = @_;
    return $self->{ _bCount } = $temp;
}

sub _SetNValue
{
    my ( $self, $temp ) = @_;
    return $self->{ _NValue } = $temp;
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
        if( ref ( $self ) ne "Word2vec::Spearmans" )
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
        if( ref ( $self ) ne "Word2vec::Spearmans" )
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

Word2vec::Spearmans - Spearman's Rank Correlation Score Module

=head1 SYNOPSIS

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetPrecision( 8 );
 my $score = $spearmans->CalculateSpearmans( "MiniMayoSRS.comp_results", "MiniMayoSRS.coders", undef );
 print( "Spearman's Rank Correlation Score: $score\n" );
 undef( $spearmans );

 # Or

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetIsFileOfWords( 1 );
 my $score = $spearmans->CalculateSpearmans( "MiniMayoSRS.terms.comp_results", "MiniMayoSRS.terms.coders", undef );
 print( "Spearman's Rank Correlation Score: $score\n" );
 undef( $spearmans );

=head1 DESCRIPTION

Word2vec::Spearmans is a Spearman's Rank Correlation Score Module for the Word2vec::Inteface package.

=head2 Main Functions

=head3 new

Description:

 Returns a new 'Word2vec::Spearmans' module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog                    = 0
    writeLog                    = 0
    precision                   = 4
    isFileOfWords               = undef
    N                           = undef
    aCount                      = -1
    bCount                      = -1
    NValue                      = -1

Input:

 $debugLog                    -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog                    -> Instructs module to print debug statements to a log file. (1 = True / 0 = False)
 $isFileOfWords               -> Specifies the word option, default is Auto-Detect. (undef = Auto-Detect, 0 = CUI Terms, 1 = Word Terms)
 $N                           -> Specifies the N option, default is undef. (defined = Print N / undef = Do Not Print N)
 $aCount                      -> Term count for $aFile post Spearman's Rank Correlation calculation.
 $bCount                      -> Term count for $bFile post Spearman's Rank Correlation calculation.
 $NValue                      -> N Value post Spearmans's Rank Correlation calculation.

 Warning: Only debugLog, writeLog, precision, word and N variables should be specified.

Output:

 Word2vec::Spearmans object.

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();

 undef( $spearmans );

=head3 DESTROY

Description:

 Removes member variables and file handle from memory.

Input:

 None

Output:

 None

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();

 $spearmans->DESTROY();
 undef( $spearmans );

=head3 CalculateSpearmans

Description:

 Calculates Spearman's Rank Correlation Score between two data-sets (files) using _precision, _isWordOfFile and _printN Variables.

 Note: _precision, _isFileOfWords and _printN variables must be set prior to calling this function or default values will be used.

Input:

 $fileA                  -> File To Process
 $fileB                  -> File To Process
 $includeCountsInResults -> Specifies whether to return file counts in score. (undef = False / defined = True)

Output:

 $value -> Spearman's Rank Correlation Score or "undef"

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetPrecision( 8 );
 my $score = $spearmans->CalculateSpearmans( "MiniMayoSRS.comp_results", "MiniMayoSRS.coders", undef );
 print( "Spearman's Rank Correlation Score: $score\n" ) if defined( $score );
 print( "Spearman's Rank Correlation Score: undef\n" ) if !defined( $score );
 undef( $spearmans );

 # Or

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetIsFileOfWords( 1 );
 my $score = $spearmans->CalculateSpearmans( "MiniMayoSRS.terms.comp_results", "MiniMayoSRS.terms.coders", 1 );
 print( "Spearman's Rank Correlation Score: $score\n" ) if defined( $score );
 print( "Spearman's Rank Correlation Score: undef\n" ) if !defined( $score );
 undef( $spearmans );

=head3 IsFileWordOrCUIFile

Description:

 Determines if a file is composed of CUI or word terms by checking the first line.

Input:

 $string -> File Path

Output:

 $string -> "undef" = Unable to determine, "cui" = CUI Term File, "word" = Word Term File

Example:

 use Word2vec::Spearmans;

 my $spearmans       = Word2vec::Spearmans->new();
 my $isWordOrCuiFile = $spearmans->IsFileWordOrCUIFile( "samples/MiniMayoSRS.terms" );

 print( "MiniMayoSRS.terms File Is A \"$isWordOrCuiFile\" File\n" ) if defined( $isWordOrCuiFile );
 print( "Unable To Determine Type Of File\n" )                      if !defined( $isWordOrCuiFile

 undef( $spearmans );

=head3 _IsCUI

Description:

 Checks to see whether passed string argument is a word or CUI term.

 Note: This is an internal function and should not be called.

Input:

 $value -> String

Output:

 $value -> 0 = Word Term, 1 = CUI Term

Example:

 This is a private function and should not be utilized.

=head3 _ResetVariables

Description:

 Resets _aCount, _bCount and _NValue variables.

 Note: This is an internal function and should not be called.

Input:

 None

Output:

 None

Example:

 This is a private function and should not be utilized.

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Spearmans object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 my $debugLog = $spearmans->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $spearmans );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Spearmans object initialization of new function.

Input:

 None

Output:

 $value -> 0 = False, 1 = True

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 my $writeLog = $spearmans->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $spearmans );

=head3 GetFileHandle

Description:

 Returns file handle used by WriteLog() method.

Input:

 None

Output:

 $fileHandle -> Returns file handle blob used by 'WriteLog()' function or undefined.

Example:

 <This should not be called.>

=head3 GetPrecision

Description:

 Returns floating point precision value.

Input:

 None

Output:

 $value -> Spearmans Float Precision Value

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 my $value     = $spearmans->GetPrecision();

 print( "Float Precision Value: $value\n" ) if defined( $value );
 undef( $spearmans );

=head3 GetIsFileOfWords

Description:

 Returns the variable indicating whether the files to be parsed are files consisting of words or CUI terms.

Input:

 None

Output:

 $value -> "undef = Auto-Detect, 0 = CUI Terms, 1 = Word Terms"

Example:

 use Word2vec::Spearmans;

 my $spearmans     = Word2vec::Spearmans->new();
 my $isFileOfWords = $spearmans->GetIsFileOfWords();

 print( "IsFileOfWords Is Undefined\n" ) if !defined( $isFileOfWords );
 print( "IsFileOfWords Value: $isFileOfWords\n" )   if defined( $isFileOfWords );
 undef( $spearmans );

=head3 GetPrintN

Description:

 Returns the variable indicating whether to print NValue.

Input:

 None

Output:

 $value -> "undef" = Do not print NValue, "defined" = Print NValue

Example:

 use Word2vec::Spearmans;

 my $spearmans     = Word2vec::Spearmans->new();
 my $printN        = $spearmans->GetPrintN();
 print "Print N\n"        if defined( $printN );
 print "Do Not Print N\n" if !defined( $printN );

 undef( $spearmans );

=head3 GetACount

 Returns the non-negative count for file A.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 print "A Count: " . $spearmans->GetACount() . "\n";

 undef( $spearmans );

=head3 GetBCount

 Returns the non-negative count for file B.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 print "B Count: " . $spearmans->GetBCount() . "\n";

 undef( $spearmans );

=head3 SpGetNValue

 Returns the N value.

Input:

 None

Output:

 $value -> Integer

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 print "N Value: " . $spearmans->GetNValue() . "\n";

 undef( $spearmans );

=head2 Mutator Functions

=head3 SetPrecision

Description:

 Sets number of decimal places after the decimal point of the Spearman's Rank Correlation Score to represent.

Input:

 $value -> Integer

Output:

 None

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetPrecision( 8 );
 my $score = $spearmans->CalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $spearmans );

=head3 SetIsFileOfWords

 Specifies the main method to auto-detect if file consists of CUI or Word terms, or manual override with user setting.

Input:

 $value -> "undef" = Auto-Detect, 0 = CUI Terms, 1 = Word Terms

Output:

 None

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetIsFileOfWords( undef );
 my $score = $spearmans->CalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $spearmans );

=head3 SetPrintN

 Specifies the main method print _NValue post Spearmans::CalculateSpearmans() function completion.

Input:

 $value -> "undef" = Do Not Print _NValue, "defined" = Print _NValue

Output:

 None

Example:

 use Word2vec::Spearmans;

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->SetPrintN( 1 );
 my $score = $spearmans->CalculateSpearmans( "samples/MiniMayoSRS.term.comp_results", "Similarity/MiniMayoSRS.terms.coders", undef );
 print "Spearman's Rank Correlation Score: $score\n" if defined( $score );
 print "Spearman's Rank Correlation Score: undef\n" if !defined( $score );

 undef( $spearmans );

=head3 _SetACount

Description:

 Sets _aCount variable.

 Note: This is an internal function and should not be called.

Input:

 $value -> Integer

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 _SetBCount

Description:

 Sets _bCount variable.

 Note: This is an internal function and should not be called.

Input:

 $value -> Integer

Output:

 None

Example:

 This is a private function and should not be utilized.

=head3 _SetNValue

Description:

 Sets _NValue variable.

 Note: This is an internal function and should not be called.

Input:

 $value -> Integer

Output:

 None

Example:

 This is a private function and should not be utilized.

=head2 Debug Functions

=head3 GetTime

Description:

 Returns current time string in "Hour:Minute:Second" format.

Input:

 None

Output:

 $string -> XX:XX:XX ("Hour:Minute:Second")

Example:

 use Word2vec::Spearmans:

 my $spearmans = Word2vec::Spearmans->new();
 my $time = $spearmans->GetTime();

 print( "Current Time: $time\n" ) if defined( $time );

 undef( $spearmans );

=head3 GetDate

Description:

 Returns current month, day and year string in "Month/Day/Year" format.

Input:

 None

Output:

 $string -> XX/XX/XXXX ("Month/Day/Year")

Example:

 use Word2vec::Spearmans:

 my $spearmans = Word2vec::Spearmans->new();
 my $date = $spearmans->GetDate();

 print( "Current Date: $date\n" ) if defined( $date );

 undef( $spearmans );

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

 use Word2vec::Spearmans:

 my $spearmans = Word2vec::Spearmans->new();
 $spearmans->WriteLog( "Hello World" );

 undef( $spearmans );

=head1 Author

 Bridget T McInnes, Virginia Commonwealth University
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
