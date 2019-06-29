#!usr/bin/perl

######################################################################################
#                                                                                    #
#    Author: Clint Cuffy                                                             #
#    Date:    06/16/2019                                                             #
#    Revised: 06/21/2019                                                             #
#    UMLS Similarity Word2Vec Package Utility Module                                 #
#                                                                                    #
######################################################################################
#                                                                                    #
#    Description:                                                                    #
#    ============                                                                    #
#                Module containing Lesk algorithm and associated functions.          #
#                                                                                    #
######################################################################################


package Word2vec::Lesk;

use strict;
use warnings;

# Standard CPAN Module(s)
use Cwd;

# Word2Vec Utility Package(s)
use Word2vec::Util;


use vars qw($VERSION);

$VERSION = '0.01';


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
    };

    # Set Variable Default If Not Defined
    $self->{ _debugLog } = 0 if !defined ( $self->{ _debugLog } );
    $self->{ _writeLog } = 0 if !defined ( $self->{ _writeLog } );

    # Open File Handler if checked variable is true
    if( $self->{ _writeLog } )
    {
        open( $self->{ _fileHandle }, '>:utf8', 'LeskLog.txt' );
        $self->{ _fileHandle }->autoflush( 1 );             # Auto-flushes writes to log file
    }
    else
    {
        $self->{ _fileHandle } = undef;
    }

    bless $self, $class;

    $self->WriteLog( "New - Debug On" );

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

sub GetMatchingFeatures
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "GetMatchingFeatures - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "GetMatchingFeatures - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return () if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "GetMatchingFeatures - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "GetMatchingFeatures - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return () if ( $string_a eq "" ) or ( $string_b eq "" );

    $self->WriteLog( "GetMatchingFeatures - Fetching Overlapped Phrases" );
    my $total_features      = 0;
    my %overlapped_features = ();
    my %overlapped_phrases  = %{ $self->GetPhraseOverlap( $string_a, $string_b ) };

    $self->WriteLog( "GetMatchingFeatures - Found " . scalar %overlapped_phrases . " Overlapping Phrases" );

    for my $phrase ( sort keys %overlapped_phrases )
    {
        my @features = split( /\s+/, $phrase );

        $self->WriteLog( "GetMatchingFeatures - Phrase Contains " . scalar @features . " Features" );

        # Add Matching Feature To Unique Feature Vocabulary Hash And Increment Frequency Count
        #  By Frequency Of Phrase.
        for my $feature ( @features )
        {
            $overlapped_features{ $feature } += ( $overlapped_phrases{ $phrase } );
            $total_features += ( $overlapped_phrases{ $phrase } );
            $self->WriteLog( "GetMatchingFeatures - Adding Feature To List: \"$feature\" -> Count: $overlapped_features{ $feature }" )
        }

        # Clean-Up
        undef( @features );
    }

    # Clean-Up
    undef( %overlapped_phrases );

    $self->WriteLog( "GetMatchingFeatures - Total Number Of Matching Features: $total_features" );
    $self->WriteLog( "GetMatchingFeatures - Complete" );

    return \%overlapped_features;
}

sub GetPhraseOverlap
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "GetPhraseOverlap - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "GetPhraseOverlap - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return () if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "GetPhraseOverlap - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "GetPhraseOverlap - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return () if ( $string_a eq "" ) or ( $string_b eq "" );

    $self->WriteLog( "GetPhraseOverlap - String A: \"$string_a\"" );
    $self->WriteLog( "GetPhraseOverlap - String B: \"$string_b\"" );

    my %overlapped_phrases = ();

    # Determine Sentence With Lesser Length
    my $temp_str           = "";

    # Adjust Such That $string_a is sentence of lower length than $string_b.
    #  Skips In The Event Both String Are Equal Or $string_a length < $string_b length
    if( scalar split( /\s+/, $string_a ) > scalar split( /\s+/, $string_b ) )
    {
        $self->WriteLog( "GetPhraseOverlap - String_A Length > String_B Length, Swapping Sentences" );
        $temp_str          = $string_a;
        $string_a          = $string_b;
        $string_b          = $temp_str;
        $temp_str          = "";
        $self->WriteLog( "GetPhraseOverlap - Strings Swapped" );
        $self->WriteLog( "GetPhraseOverlap - New String A: \"$string_a\"" );
        $self->WriteLog( "GetPhraseOverlap - New String B: \"$string_b\"" );
    }

    # Find Overlap Of Phrases
    my @sentence_a_features  = split( /\s+/, $string_a );
    my $matching_phrase      = "";
    my $number_matching      = 0;
    $self->WriteLog( "GetPhraseOverlap - Locating Overlapped Phrases Between Strings" );

    for( 0..$#sentence_a_features )
    {
        my $sentence_feature    = $sentence_a_features[$_];
        my $old_matching_phrase = $matching_phrase;
        $matching_phrase        .= " $sentence_feature";

        $matching_phrase =~ s/\s+/ /g;
        $matching_phrase =~ s/^\s+|\s+$//g;

        if( !( $string_b =~ m/\b$matching_phrase\b/ ) )
        {
            $matching_phrase = $old_matching_phrase;

            if( $matching_phrase ne "" )
            {
                $self->WriteLog( "GetPhraseOverlap -  Possible Matching Phrase Found / Adding To List: \"$matching_phrase\"" );
                $overlapped_phrases{ "$matching_phrase" }++;
                $number_matching++;

                $self->WriteLog( "GetPhraseOverlap -    Phrase Count: $overlapped_phrases{ $matching_phrase }" );
                $matching_phrase = "";
            }

            # Check To See If Current Feature Is Within Sentence B
            $matching_phrase = $sentence_feature if ( $string_b =~ m/\b$sentence_feature\b/ );
        }

        # Check For Matching Phrase Ending At Last Index
        if( ( $_ == $#sentence_a_features ) and $string_b =~ m/\b$matching_phrase\b/ )
        {
            if( $matching_phrase ne "" )
            {
                $self->WriteLog( "GetPhraseOverlap -  Last Index Feature Matched In Current Phrase" );
                $self->WriteLog( "GetPhraseOverlap -  Possible Matching Phrase Found / Adding To List: \"$matching_phrase\"" );
                $overlapped_phrases{ "$matching_phrase" }++;
                $number_matching++;

                $self->WriteLog( "GetPhraseOverlap -    Phrase Count: $overlapped_phrases{ $matching_phrase }" ) if exists( $overlapped_phrases{ $matching_phrase } );
                $matching_phrase = "";
            }
        }
    }

    $self->WriteLog( "GetPhraseOverlap - Number Of Possible Matching Phrases Found: $number_matching" );
    $self->WriteLog( "GetPhraseOverlap - Verifying Possible Matched Phrases By Longest Match First" );

    # Extract Only Longest Phrases Possible
    my %unique_overlapped_phrases = ();
    my @sorted_phrases = sort { length $b <=> length $a } keys %overlapped_phrases;
    $number_matching = 0;

    for my $phrase ( @sorted_phrases  )
    {
        my $match_frequency = $overlapped_phrases{ $phrase };
        my $verified_frequency = 0;

        for( 1..$match_frequency )
        {
            if( $string_b =~ m/$phrase/ )
            {
                $self->WriteLog( "GetPhraseOverlap - Verified Phrase: \"$phrase\"" );

                $string_b =~ s/$phrase/\[#\]/;
                $verified_frequency++;
                $number_matching++;

                $self->WriteLog( "GetPhraseOverlap -   Phrase Count: $verified_frequency" );
            }
        }

        $unique_overlapped_phrases{ $phrase } = $verified_frequency if $verified_frequency > 0;
    }

    undef( %overlapped_phrases );

    $self->WriteLog( "GetPhraseOverlap - Number Of Verified Matching Phrases: $number_matching" );
    $self->WriteLog( "GetPhraseOverlap - Complete" );

    return \%unique_overlapped_phrases;
}

sub CalculateLeskScore
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "CalculateLeskScore - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "CalculateLeskScore - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return -1 if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "CalculateLeskScore - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "CalculateLeskScore - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return -1 if ( $string_a eq "" ) or ( $string_b eq "" );

    # Adjust Such That $string_a is sentence of lower length than $string_b.
    #  Skips In The Event Both String Are Equal Or $string_a length < $string_b length
    my $temp_str = "";

    if( scalar split( /\s+/, $string_a ) > scalar split( /\s+/, $string_b ) )
    {
        $self->WriteLog( "CalculateLeskScore - String_A Length > String_B Length, Swapping Sentences" );
        $temp_str          = $string_a;
        $string_a          = $string_b;
        $string_b          = $temp_str;
        $temp_str          = "";
        $self->WriteLog( "CalculateLeskScore - Strings Swapped" );
        $self->WriteLog( "CalculateLeskScore - New String A: \"$string_a\"" );
        $self->WriteLog( "CalculateLeskScore - New String B: \"$string_b\"" );
    }

    $self->WriteLog( "CalculateLeskScore - String A: \"$string_a\"" );
    $self->WriteLog( "CalculateLeskScore - String B: \"$string_b\"" );

    my $raw_lesk = 0;
    my %matching_phrases = %{ $self->GetPhraseOverlap( $string_a, $string_b ) };

    $self->WriteLog( "CalculateLeskScore - Found " . scalar %matching_phrases . " Matching Phrases" );

    return 0 if scalar %matching_phrases == 0;

    my $string_a_length = scalar split( /\s+/, $string_a );
    my $string_b_length = scalar split( /\s+/, $string_b );

    for my $phrase ( sort keys %matching_phrases )
    {
        my $matching_phrase_frequency = $matching_phrases{ $phrase };
        my $number_of_phrase_features = scalar split( /\s+/, $phrase );
        $raw_lesk += ( $number_of_phrase_features * $number_of_phrase_features * $matching_phrase_frequency );
    }

    $self->WriteLog( "CalculateLeskScore - Raw Lesk: $raw_lesk"               );
    $self->WriteLog( "CalculateLeskScore - String A Length: $string_a_length" );
    $self->WriteLog( "CalculateLeskScore - String B Length: $string_b_length" );
    $self->WriteLog( "CalculateLeskScore - Complete"                          );

    return ( $raw_lesk ) / ( $string_a_length * $string_b_length );
}

sub CalculateCosineScore
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "CalculateCosineScore - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "CalculateCosineScore - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return -1 if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "CalculateCosineScore - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "CalculateCosineScore - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return -1 if ( $string_a eq "" ) or ( $string_b eq "" );

    # Adjust Such That $string_a is sentence of lower length than $string_b.
    #  Skips In The Event Both String Are Equal Or $string_a length < $string_b length
    my $temp_str = "";

    if( scalar split( /\s+/, $string_a ) > scalar split( /\s+/, $string_b ) )
    {
        $self->WriteLog( "CalculateCosineScore - String_A Length > String_B Length, Swapping Sentences" );
        $temp_str          = $string_a;
        $string_a          = $string_b;
        $string_b          = $temp_str;
        $temp_str          = "";
        $self->WriteLog( "CalculateCosineScore - Strings Swapped" );
        $self->WriteLog( "CalculateCosineScore - New String A: \"$string_a\"" );
        $self->WriteLog( "CalculateCosineScore - New String B: \"$string_b\"" );
    }

    $self->WriteLog( "CalculateCosineScore - String A: \"$string_a\"" );
    $self->WriteLog( "CalculateCosineScore - String B: \"$string_b\"" );

    my $feature_count    = 0;
    my %matching_phrases = %{ $self->GetPhraseOverlap( $string_a, $string_b ) };

    $self->WriteLog( "CalculateCosineScore - Found " . scalar %matching_phrases . " Matching Phrases" );

    return 0 if scalar %matching_phrases == 0;

    my $string_a_length = scalar split( /\s+/, $string_a );
    my $string_b_length = scalar split( /\s+/, $string_b );

    for my $phrase ( sort keys %matching_phrases )
    {
        my $matching_phrase_frequency = $matching_phrases{ $phrase };
        my $number_of_phrase_features = scalar split( /\s+/, $phrase );
        $feature_count += ( $number_of_phrase_features * $matching_phrase_frequency );
    }

    $self->WriteLog( "CalculateCosineScore - Matching Feature Count: $feature_count" );
    $self->WriteLog( "CalculateCosineScore - String A Length: $string_a_length"      );
    $self->WriteLog( "CalculateCosineScore - String B Length: $string_b_length"      );
    $self->WriteLog( "CalculateCosineScore - Complete"                               );

    return ( $feature_count ) / sqrt( $string_a_length * $string_b_length );
}

sub CalculateFScore
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "CalculateFScore - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "CalculateFScore - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return -1 if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "CalculateFScore - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "CalculateFScore - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return -1 if ( $string_a eq "" ) or ( $string_b eq "" );

    # Adjust Such That $string_a is sentence of lower length than $string_b.
    #  Skips In The Event Both String Are Equal Or $string_a length < $string_b length
    my $temp_str = "";

    if( scalar split( /\s+/, $string_a ) > scalar split( /\s+/, $string_b ) )
    {
        $self->WriteLog( "CalculateFScore - String_A Length > String_B Length, Swapping Sentences" );
        $temp_str          = $string_a;
        $string_a          = $string_b;
        $string_b          = $temp_str;
        $temp_str          = "";
        $self->WriteLog( "CalculateFScore - Strings Swapped" );
        $self->WriteLog( "CalculateFScore - New String A: \"$string_a\"" );
        $self->WriteLog( "CalculateFScore - New String B: \"$string_b\"" );
    }

    $self->WriteLog( "CalculateFScore - String A: \"$string_a\"" );
    $self->WriteLog( "CalculateFScore - String B: \"$string_b\"" );

    my $feature_count    = 0;
    my %matching_phrases = %{ $self->GetPhraseOverlap( $string_a, $string_b ) };

    $self->WriteLog( "CalculateFScore - Found " . scalar %matching_phrases . " Matching Phrases" );

    return 0 if scalar %matching_phrases == 0;

    my $string_a_length = scalar split( /\s+/, $string_a );
    my $string_b_length = scalar split( /\s+/, $string_b );

    for my $phrase ( sort keys %matching_phrases )
    {
        my $matching_phrase_frequency = $matching_phrases{ $phrase };
        my $number_of_phrase_features = scalar split( /\s+/, $phrase );
        $feature_count += ( $number_of_phrase_features * $matching_phrase_frequency );
    }

    my $precision = $feature_count / $string_b_length;
    my $recall    = $feature_count / $string_a_length;

    $self->WriteLog( "CalculateFScore - Matching Feature Count: $feature_count" );
    $self->WriteLog( "CalculateFScore - Precision: $precision"                  );
    $self->WriteLog( "CalculateFScore - Recall: $recall"                        );
    $self->WriteLog( "CalculateFScore - String A Length: $string_a_length"      );
    $self->WriteLog( "CalculateFScore - String B Length: $string_b_length"      );
    $self->WriteLog( "CalculateFScore - Complete"                               );

    return ( 2 * $precision * $recall ) / ( $precision + $recall );
}

sub CalculateAllScores
{
    my ( $self, $string_a, $string_b ) = @_;

    # Check(s)
    $self->WriteLog( "CalculateAllScores - Error: String_A Term Not Defined" ) if !defined( $string_a );
    $self->WriteLog( "CalculateAllScores - Error: String_B Term Not Defined" ) if !defined( $string_b );
    return () if !defined( $string_a ) || !defined( $string_b );

    $self->WriteLog( "CalculateAllScores - Error: String_A Is Empty String" )  if ( $string_a eq "" );
    $self->WriteLog( "CalculateAllScores - Error: String_B Is Empty String" )  if ( $string_b eq "" );
    return () if ( $string_a eq "" ) or ( $string_b eq "" );

    # Adjust Such That $string_a is sentence of lower length than $string_b.
    #  Skips In The Event Both String Are Equal Or $string_a length < $string_b length
    my $temp_str = "";

    if( scalar split( /\s+/, $string_a ) > scalar split( /\s+/, $string_b ) )
    {
        $self->WriteLog( "CalculateAllScores - String_A Length > String_B Length, Swapping Sentences" );
        $temp_str          = $string_a;
        $string_a          = $string_b;
        $string_b          = $temp_str;
        $temp_str          = "";
        $self->WriteLog( "CalculateAllScores - Strings Swapped" );
        $self->WriteLog( "CalculateAllScores - New String A: \"$string_a\"" );
        $self->WriteLog( "CalculateAllScores - New String B: \"$string_b\"" );
    }

    $self->WriteLog( "CalculateAllScores - String A: \"$string_a\"" );
    $self->WriteLog( "CalculateAllScores - String B: \"$string_b\"" );

    my $raw_lesk         = 0;
    my $feature_count    = 0;
    my $phrase_count     = 0;
    my $string_a_length  = scalar split( /\s+/, $string_a );
    my $string_b_length  = scalar split( /\s+/, $string_b );
    my %matching_phrases = %{ $self->GetPhraseOverlap( $string_a, $string_b ) };

    $self->WriteLog( "CalculateAllScores - Found " . scalar %matching_phrases . " Matching Phrases" );
    
    if( scalar %matching_phrases == 0 )
    {
        my %zero_results = ();
        $zero_results{ "Lesk"                   } = 0;
        $zero_results{ "Raw Lesk"               } = 0;
        $zero_results{ "Precision"              } = 0;
        $zero_results{ "Recall"                 } = 0;
        $zero_results{ "F Score"                } = 0;
        $zero_results{ "Cosine"                 } = 0;
        $zero_results{ "Matching Feature Count" } = 0;
        $zero_results{ "Matching Phrase Count"  } = 0;
        $zero_results{ "String A Length"        } = $string_a_length;
        $zero_results{ "String B Length"        } = $string_b_length;
        return \%zero_results;
    }

    # Calcuate Metrics If Matching Phrases Found
    for my $phrase ( sort keys %matching_phrases )
    {
        my $matching_phrase_frequency = $matching_phrases{ $phrase };
        my $number_of_phrase_features = scalar split( /\s+/, $phrase );
        $phrase_count += $matching_phrase_frequency;
        $feature_count += ( $number_of_phrase_features * $matching_phrase_frequency );
        $raw_lesk += ( $number_of_phrase_features * $number_of_phrase_features * $matching_phrase_frequency );
    }

    my $precision = $feature_count / $string_b_length;
    my $recall    = $feature_count / $string_a_length;
    my $lesk      = $raw_lesk / ( $string_a_length * $string_b_length );
    my $f_score   = ( 2 * $precision * $recall ) / ( $precision + $recall );
    my $cosine    = $feature_count / sqrt ( $string_a_length * $string_b_length );

    $self->WriteLog( "CalculateAllScores - Matching Phrase Count: $phrase_count"   );
    $self->WriteLog( "CalculateAllScores - Matching Feature Count: $feature_count" );
    $self->WriteLog( "CalculateAllScores - Lesk: $lesk"                            );
    $self->WriteLog( "CalculateAllScores - Cosine: $cosine"                        );
    $self->WriteLog( "CalculateAllScores - Raw Lesk Score: $raw_lesk"              );
    $self->WriteLog( "CalculateAllScores - Precision: $precision"                  );
    $self->WriteLog( "CalculateAllScores - Recall: $recall"                        );
    $self->WriteLog( "CalculateAllScores - String A Length: $string_a_length"      );
    $self->WriteLog( "CalculateAllScores - String B Length: $string_b_length"      );

    my %results = ();

    $results{ "Lesk"                   } = $lesk;
    $results{ "Raw Lesk"               } = $raw_lesk;
    $results{ "Precision"              } = $precision;
    $results{ "Recall"                 } = $recall;
    $results{ "F Score"                } = $f_score;
    $results{ "Cosine"                 } = $cosine;
    $results{ "Matching Feature Count" } = $feature_count;
    $results{ "Matching Phrase Count"  } = $phrase_count;
    $results{ "String A Length"        } = $string_a_length;
    $results{ "String B Length"        } = $string_b_length;

    $self->WriteLog( "CalculateAllScores - Complete" );

    return \%results;
}

######################################################################################
#    Accessor Functions
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
        if( ref ( $self ) ne "Word2vec::Lesk" )
        {
            print( GetDate() . " " . GetTime() . " - Lesk: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        $string = "" if !defined ( $string );
        print GetDate() . " " . GetTime() . " - Lesk::$string";
        print "\n" if( $printNewLine != 0 );
    }

    if( $self->GetWriteLog() )
    {
        if( ref ( $self ) ne "Word2vec::Lesk" )
        {
            print( GetDate() . " " . GetTime() . " - Lesk: Cannot Call WriteLog() From Outside Module!\n" );
            return;
        }

        my $fileHandle = $self->GetFileHandle();

        if( defined( $fileHandle ) )
        {
            print( $fileHandle GetDate() . " " . GetTime() . " - Lesk::$string" );
            print( $fileHandle "\n" ) if( $printNewLine != 0 );
        }
    }
}

#################### All Modules Are To Output "1"(True) at EOF ######################
1;


=head1 NAME

Word2vec::Lesk - Word2vec-Interface Utility Module.

=head1 SYNOPSIS

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my $string_a = "This is a test string";
 my $string_b = "This is another test string";

 my $lesk_score   = $lesk->CalculateLeskScore( $string_a, $string_b );
 my $cosine_score = $lesk->CalculateCosineScore( $string_a, $string_b );
 my $f_score      = $lesk->CalcualteFScore( $string_a, $string_b );

 print( "Lesk Score: $lesk_score\n"     );
 print( "Cosine Score: $cosine_score\n" );
 print( "F Score: $f_score\n"           );

 undef( $lesk );

 or

 my $lesk = Word2vec::Lesk->new();

 my $string_a = "This is a test string";
 my $string_b = "This is another test string";

 my %results  = %{ $lesk->CalculateAllScores( $string_a, $string_b ) };

 for my $key ( sort keys %results )
 {
    print "$key: $results{ $key }\n";
 }

 undef( %results );
 undef( $lesk    );

=head1 DESCRIPTION

Word2vec::Lesk is a module of Lesk functions for the Word2vec::Interface package. Lesk, Raw Lesk, Cosine, F, Recall and Precision scores are all calculated and returned to the used based on phrase/feature overlap between two strings.

=head2 Main Functions

=head3 new

Description:

 Returns a new "Word2vec::Lesk" module object.

 Note: Specifying no parameters implies default options.

 Default Parameters:
    debugLog = 0
    writeLog = 0

Input:

 $debugLog -> Instructs module to print debug statements to the console. (1 = True / 0 = False)
 $writeLog -> Instructs module to print debug statements to a log file.  (1 = True / 0 = False)

Output:

 Word2vec::Lesk object.

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 undef( $lesk );

=head3 DESTROY

Description:

 Removes Word2vec::Lesk object from memory.

Input:

 None

Output:

 None

Example:

 See above example for "new" function.

 Note: Destroy function is also automatically called during global destruction when exiting the program.

=head3 GetMatchingFeatures

Description:

 Given two strings, this returns a hash of all overlapping (matching) features between both strings and their frequency counts.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $hash_ref -> Returns a hash table reference with keys being the unique matching feature between two input string parameters and the value as the frequency count of each unique feature.

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my %matching_features = %{ $lesk->GetMatchingFeatures( "I like to eat cookies", "Sometimes I like to eat cookies" ) };

 for my $feature ( sort keys %matching_features )
 {
    print "$feature : $matching_features{ $feature }\n";
 }

 undef( %matching_features );
 undef( $lesk );

=head3 GetPhraseOverlap

Description:

 Given two strings, this returns a hash of all overlapping (matching) phrases between both strings and their frequency counts. This prioritizes longer phrases as higher priority when matching.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $hash_ref -> Returns a hash table reference with keys being the unique matching phrase between two input string parameters and the value as the frequency count of each unique phrase.

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my %phrase_overlaps = %{ $lesk->GetPhraseOverlap( "I like to eat cookies", "Sometimes I like to eat cookies" ) };

 for my $phrase ( sort keys %phrase_overlaps )
 {
    print "$phrase : $phrase_overlaps{ $phrase }\n";
 }

 undef( %phrase_overlaps );
 undef( $lesk );

=head3 CalculateLeskScore

Description:

 Given two strings, this returns a lesk score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> Lesk Score (Float)

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my $lesk_score = $lesk->CalculateLeskScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "Lesk Score: $lesk_score\n";

 undef( $lesk );

=head3 CalculateCosineScore

Description:

 Given two strings, this returns a cosine score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> Cosine Score (Float)

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my $cosine_score = $lesk->CalculateCosineScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "Cosine Score: $cosine_score\n";

 undef( $lesk );

=head3 CalculateFScore

Description:

 Given two strings, this returns a F score based on overlapping (matching) features between both strings.

Input:

 $string_a -> First comparison string
 $string_b -> Second comparison string

Output:

 $score    -> F Score (Float)

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my $f_score = $lesk->CalculateFScore( "I like to eat cookies", "Sometimes I like to eat cookies" );

 print "F Score: $f_score\n";

 undef( $lesk );

=head3 CalculateAllScores

Description:

 Given two strings, this returns a list of scores (F, Cosine, Lesk, Raw Lesk, Precision, Recall), frequency counts (features, phrases, string lengths).

Input:

 $string_a    -> First comparison string
 $string_b    -> Second comparison string

Output:

 $result_hash -> Hash reference containing: Lesk, Raw Lesk, F, Precision, Recall, Cosine, Matching Feature Frequency, Matching Phrase Frequency, String A Length and String B Length.

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();

 my %scores = %{ $lesk->CalculateAllScores( "I like to eat cookies", "Sometimes I like to eat cookies" ) };

 for my $score_name ( sort keys %scores )
 {
    print "$score_name : $scores{ $score_name }\n";
 }

 undef( $lesk );

=head2 Accessor Functions

=head3 GetDebugLog

Description:

 Returns the _debugLog member variable set during Word2vec::Lesk object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new()
 my $debugLog = $lesk->GetDebugLog();

 print( "Debug Logging Enabled\n" ) if $debugLog == 1;
 print( "Debug Logging Disabled\n" ) if $debugLog == 0;

 undef( $lesk );

=head3 GetWriteLog

Description:

 Returns the _writeLog member variable set during Word2vec::Lesk object initialization of new function.

Input:

 None

Output:

 $value -> '0' = False, '1' = True

Example:

 use Word2vec::Lesk;

 my $lesk = Word2vec::Lesk->new();
 my $writeLog = $lesk->GetWriteLog();

 print( "Write Logging Enabled\n" ) if $writeLog == 1;
 print( "Write Logging Disabled\n" ) if $writeLog == 0;

 undef( $lesk );

=head2 Debug Functions

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

 use Word2vec::Lesk:

 my $lesk = Word2vec::Lesk->new();
 $lesk->WriteLog( "Hello World" );

 undef( $lesk );

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