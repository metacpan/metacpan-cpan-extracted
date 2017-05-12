package Voting::VoteFairRanking;

use strict;
use warnings;
require Exporter;

=head1 NAME

Voting::VoteFairRanking - Calculates VoteFair Ranking results

=cut


=head1 VERSION

Version 5.01

=cut

our $VERSION = '5.01' ;


=head1 SYNOPSIS

VoteFair Ranking is described at www.VoteFair.org and in the book "Ending The Hidden Unfairness In U.S. Elections" by Richard Fobes.  The components of VoteFair Ranking that are implemented here are briefly described below in the ABOUT section.

The following sample code executes this module.

    use Voting::VoteFairRanking;
    &Voting::VoteFairRanking::votefair_read_calculate_write( );

This usage assumes that you supply via STDIN (standard input) a file that contains the appropriately formatted election/survey/poll data, and that you direct the output via STDOUT (standard output) to a file.  These input and output files can be handled most easily by using Vote-Info-Split-Join (VISJ) files, which are available on GitHub in the CPSolver account.  The VISJ framework uses the Language::Dashrep module.

Alternatively, this module can be accessed from any Perl software by directly using these subroutines:

=over

=item * votefair_put_next_vote_info_number

=item * votefair_do_calculations_all_questions

=item * votefair_get_next_result_info_number

=back

(c) Copyright 1991 through 2011 Richard Fobes at www.VoteFair.org.  You can redistribute and/or modify this VoteFairRanking library module under the Perl Artistic license version 2.0 (a copy of which is included in the LICENSE file).  As required by the license this full copyright notice must be included in all copies of this software.

Conversion of this code into another programming language is also covered by the above license terms.

The mathematical algorithms of VoteFair Ranking are in the public domain.

=cut


=head1 ABOUT

This module calculates VoteFair Ranking results.  The portions of VoteFair Ranking implemented here are:

=over

=item * VoteFair popularity ranking.  This voting method calculates the full popularity ranking of all candidates (or choices in the case of a survey) from most popular and second-most popular down to least popular.  It uses the preference information collected on 1-2-3 ballots (or any equivalent way of expressing "ranked" preferences).  When a single position is being filled, the most popular candidate is declared the winner.  This calculation method is mathematically equivalent to the Condorcet-Kemeny election method.

=item * VoteFair representation ranking.  This voting method is used to elect a second candidate who represents the voters who are not well-represented by the most-popular candidate, or to fill multiple board-of-director positions, or to choose a second simultaneous activity in addition to the most popular activity.  This method reduces the influence of the voters who are already well-represented by the most popular candidate (or choice), and it does so in a way that protects against strategic voting.  If instead the second-most popular candidate as identified by VoteFair popularity ranking were chosen, the same voters who prefer the first winner also can determine the second winner, and this can leave large numbers of other voters unrepresented.  Additional levels of representation ranking can be used to fill additional seats, although VoteFair partial-proportional ranking should be used instead if "proportional representation" of political parties is needed, especially for the purpose of defeating attempts to gerrymander district boundaries.

=item * VoteFair party ranking.  This voting method ranks political parties according to a different kind of "popularity".  The results can be used in high-stakes elections to limit the number of candidates allowed by each party.  In such cases the two or three political parties that are ranked highest can be limited to offering just two candidates from each party, and lower-ranked parties can be allowed to offer one candidate each, and any additional parties can be prohibited from offering any candidate (because those parties are too unpopular and too unrepresentative).  Such limits have not been needed in the past because the fear of vote splitting has limited each political party to offering just one candidate in each contest.

=back

For detailed descriptions of VoteFair Ranking, see www.VoteFair.org or the book "Ending The Hidden Unfairness In U.S. Elections" by Richard Fobes.

In addition to being useful for elections, VoteFair Ranking also is useful for calculating results for surveys and polls, ranking the popularity of songs and movies, and much more.

In mathematical terms, VoteFair Ranking is useful for doing "combinatorial optimization" and may be useful for solving the "linear ordering problem".  See Wikipedia for details about these terms.

=cut


=head1 EXPORT

The following subroutines are exported:

=over

=item * votefair_read_calculate_write

=item * votefair_put_next_vote_info_number

=item * votefair_do_calculations_all_questions

=item * votefair_get_next_result_info_number

=item * votefair_put_input_string

=item * votefair_get_output_string

=item * votefair_always_do_rep_and_party_ranking

=item * votefair_start_new_cases

=back

=cut


our @ISA = qw(Exporter);
our @EXPORT = qw(
    votefair_read_calculate_write
    votefair_put_next_vote_info_number
    votefair_do_calculations_all_questions
    votefair_get_next_result_info_number
    votefair_put_input_string
    votefair_get_output_string
    votefair_always_do_rep_and_party_ranking
    votefair_start_new_cases
);


#-------------------------------------------
#
#      IMPORTANT NOTE TO CODERS!
#
#  This Perl code is intentionally written
#  in a subset of Perl that is close to
#  what can be written in the C language.
#  (Every line that contains a quotation
#  mark must not be necessary for correct
#  calculations, and such lines should
#  only involve unchanging text that is
#  only used for diagnostic or
#  identification purposes.)
#  This approach allows this code to be
#  easily ported to the C language, which
#  is directly recognized by C++, C#, and
#  Objective-C compilers, as well as the
#  widely ported "gcc" compiler.
#  The goal is to eventually create a
#  C version that runs very fast on most
#  operating systems (and most
#  environments).
#
#  If you offer improvements to this code,
#  please follow this convention so that
#  the code continues to be easily
#  convertible into the C language.
#-------------------------------------------


#-----------------------------------------------
#
#     Explanation about VISJ
#
#  Vote-Info-Split-Join (VISJ) is a software
#  framework that handles all text-related
#  information extracted from an EML or XML
#  or JSON data file.  This allows the VoteFair
#  Ranking software to just handle numbers
#  (and a few error messages and optional
#  debugging information).  The VISJ software
#  is open-source software that is available
#  on GitHub in the CPSolver account.


#-----------------------------------------------
#-----------------------------------------------
#
#  History
#
#  Version 1.0 -- In 1991 (approximately) Richard
#  Fobes wrote the subroutine (now named
#  calc_all_sequence_scores) that calculates
#  VoteFair popularity ranking results.
#
#  Version 2.0 -- In 1997 (approximately) Richard
#  Fobes created the web-page-server (CGI)
#  software that calculates VoteFair Ranking
#  results at VoteFair.org.  It uses a modified
#  version of the calc_all_sequence_scores
#  subroutine, and added subroutines including
#  the get_numbers_based_on_one_ballot and
#  add_preferences_to_tally_table and related
#  subroutines.
#
#  Version 3.0 -- In 2005 Richard Fobes wrote
#  the subroutine that calculates VoteFair
#  representation ranking results, which is now
#  named the calc_votefair_representation_rank
#  subroutine.
#
#  Version 4.0 -- In 2011 Richard Fobes wrote
#  the calc_votefair_party_rank subroutine that
#  calculates VoteFair party ranking results,
#  and wrote the remainder of this module to
#  use the VISJ framework.
#
#  Version 4.9 -- In 2011 this module was added
#  to Perl's CPAN archives.
#
#  Version 5.0 -- In 2011 (December) the
#  calc_votefair_choice_specific_pairwise_score_popularity_rank
#  and
#  calc_votefair_insertion_sort_popularity_rank
#  subroutines were added.  These subroutines,
#  when used together, calculate VoteFair
#  popularity ranking results fast -- in
#  "polynomial time".  These two subroutines
#  were developed during the year 2011, as
#  improvements over the also-fast calculation
#  subroutine used at VoteFair.org since about
#  the year 2000.


#-----------------------------------------------
#-----------------------------------------------
#  Declare package variables.

my $global_true ;
my $global_false ;

#  Input and output codes that identify
#  the meaning of the next number in the (coded) list.

my $global_voteinfo_code_for_start_of_all_cases ;
my $global_voteinfo_code_for_end_of_all_cases ;
my $global_voteinfo_code_for_case_number ;
my $global_voteinfo_code_for_question_number ;
my $global_voteinfo_code_for_number_of_choices ;
my $global_voteinfo_code_for_start_of_all_vote_info ;
my $global_voteinfo_code_for_end_of_all_vote_info ;
my $global_voteinfo_code_for_start_of_ballot ;
my $global_voteinfo_code_for_end_of_ballot ;
my $global_voteinfo_code_for_ballot_count ;
my $global_voteinfo_code_for_choice ;
my $global_voteinfo_code_for_tie ;
my $global_voteinfo_code_for_special_request ;
my $global_voteinfo_code_for_start_of_votefair_popularity_ranking_results ;
my $global_voteinfo_code_for_end_of_votefair_popularity_ranking_results ;
my $global_voteinfo_code_for_start_of_votefair_representation_ranking_results ;
my $global_voteinfo_code_for_end_of_votefair_representation_ranking_results ;
my $global_voteinfo_code_for_start_of_votefair_party_ranking_results ;
my $global_voteinfo_code_for_end_of_votefair_party_ranking_results ;
my $global_voteinfo_code_for_early_end_of_ranking ;
my $global_voteinfo_code_for_next_ranking_level ;
my $global_voteinfo_code_for_start_of_tally_table_results ;
my $global_voteinfo_code_for_end_of_tally_table_results ;
my $global_voteinfo_code_for_first_choice ;
my $global_voteinfo_code_for_second_choice ;
my $global_voteinfo_code_for_tally_first_over_second ;
my $global_voteinfo_code_for_tally_second_over_first ;
my $global_voteinfo_code_for_start_of_plurality_results ;
my $global_voteinfo_code_for_end_of_plurality_results ;
my $global_voteinfo_code_for_plurality_count ;
my $global_voteinfo_code_for_skip_case ;
my $global_voteinfo_code_for_skip_question ;
my $global_voteinfo_code_for_request_only_plurality_results ;
my $global_voteinfo_code_for_request_pairwise_counts ;
my $global_voteinfo_code_for_request_no_pairwise_counts ;
my $global_voteinfo_code_for_request_votefair_representation_rank ;
my $global_voteinfo_code_for_request_no_votefair_representation_rank ;
my $global_voteinfo_code_for_request_votefair_party_rank ;
my $global_voteinfo_code_for_request_no_votefair_party_rank ;
my $global_voteinfo_code_for_start_of_votefair_popularity_ranking_sequence_results ;
my $global_voteinfo_code_for_end_of_votefair_popularity_ranking_sequence_results ;
my $global_voteinfo_code_for_start_of_votefair_popularity_ranking_levels_results ;
my $global_voteinfo_code_for_end_of_votefair_popularity_ranking_levels_results ;
my $global_voteinfo_code_for_start_of_votefair_representation_ranking_sequence_results ;
my $global_voteinfo_code_for_end_of_votefair_representation_ranking_sequence_results ;
my $global_voteinfo_code_for_start_of_votefair_representation_ranking_levels_results ;
my $global_voteinfo_code_for_end_of_votefair_representation_ranking_levels_results ;
my $global_voteinfo_code_for_start_of_votefair_party_ranking_sequence_results ;
my $global_voteinfo_code_for_end_of_votefair_party_ranking_sequence_results ;
my $global_voteinfo_code_for_start_of_votefair_party_ranking_levels_results ;
my $global_voteinfo_code_for_end_of_votefair_party_ranking_levels_results ;

#  Input codes that keep track of special calculation
#  requests.

my $global_voteinfo_code_for_true_or_false_request_only_plurality_results ;
my $global_voteinfo_code_for_true_or_false_request_votefair_representation_rank ;
my $global_voteinfo_code_for_true_or_false_request_votefair_party_rank ;

#  Lists related to input.

my @global_vote_info_list ;

#  Lists related to output.

my @global_output_results ;
my @global_string_for_negative_of_code ;

#  Lists related to results.

my @global_plurality_count_for_actual_choice ;
my @global_popularity_ranking_for_actual_choice ;
my @global_full_popularity_ranking_for_actual_choice ;
my @global_representation_ranking_for_actual_choice ;
my @global_full_representation_ranking_for_actual_choice ;
my @global_party_ranking_for_actual_choice ;

#  Input/output-related pointers and variables.

my $global_supplied_vote_info_text ;
my $global_input_pointer_start_next_case ;
my $global_pointer_to_current_ballot ;
my $global_length_of_vote_info_list ;
my $global_max_array_length ;
my $global_pointer_to_output_results ;
my $global_length_of_result_info_list ;
my $global_combined_case_number_and_question_number ;
my $global_combined_case_number_and_question_number_and_choice_number ;

#  Flags indicating which results are to be calculated, and
#  what other choices to make.

my $global_true_or_false_request_votefair_popularity_rank ;
my $global_true_or_false_request_only_plurality_results ;
my $global_true_or_false_always_request_only_plurality_results ;
my $global_true_or_false_request_no_pairwise_counts ;
my $global_true_or_false_always_request_no_pairwise_counts ;
my $global_true_or_false_request_votefair_representation_rank ;
my $global_true_or_false_always_request_votefair_representation_rank ;
my $global_true_or_false_request_votefair_party_rank ;
my $global_true_or_false_always_request_votefair_party_rank ;
my $global_true_or_false_request_dashrep_phrases_in_output ;

#  Miscellaneous variables.

my $global_begin_module_actions_done ;
my $global_intitialization_done ;
my $global_case_number ;
my $global_previous_case_number ;
my $global_maximum_case_number ;
my $global_question_number ;
my $global_maximum_question_number ;
my $global_ballot_info_repeat_count ;
my $global_current_total_vote_count ;
my $global_ballot_influence_amount ;
my $global_choice_number ;
my $global_adjusted_choice_number ;
my $global_adjusted_choice_count ;
my $global_full_choice_count ;
my $global_maximum_choice_number ;
my $global_pair_counter_maximum ;
my $global_true_or_false_tally_table_created ;
my $global_question_count ;
my $global_choice_count_at_top_popularity_ranking_level ;
my $global_choice_count_at_full_top_popularity_ranking_level ;
my $global_choice_count_at_full_second_representation_level ;
my $global_limit_on_popularity_rank_levels ;
my $global_check_all_scores_choice_limit ;
my $global_representation_levels_requested ;
my $global_limit_on_representation_rank_levels ;
my $global_number_of_questions_in_current_case ;
my $global_output_warning_message ;
my $global_case_specific_warning_begin ;
my $global_question_specific_warning_begin ;
my $global_pairwise_matrix_text ;
my $global_first_most_popular_actual_choice ;
my $global_second_most_representative_actual_choice ;
my $global_maximum_twice_highest_possible_score ;
my $global_log_filename ;
my $global_error_message_filename ;
my $global_possible_error_message ;
my $global_output_warning_messages_case_or_question_specific ;
my $global_actual_choice_at_top_of_full_popularity_ranking ;
my $global_actual_choice_at_second_representation_ranking ;
my $global_ranking_type_being_calculated ;
my $global_warning_end ;
my $global_count_of_popularity_rankings ;
my $global_logging_info ;
my $global_voteinfo_code_for_total_ballot_count ;
my $global_actual_choice_at_top_popularity_ranking_level ;
my $global_default_representation_levels_requested ;
my $global_true_or_false_always_request_dashrep_phrases_in_output ;
my $global_code_associations_filename ;
my $global_voteinfo_code_for_preference_level ;
my $global_voteinfo_code_for_ranking_level ;

#  Lists for internal use.

my @global_question_count_for_case ;
my @global_true_or_false_ignore_case ;
my @global_choice_count_for_case_and_question ;
my @global_adjusted_choice_for_actual_choice ;
my @global_actual_choice_for_adjusted_choice ;
my @global_adjusted_first_choice_number_in_pair ;
my @global_adjusted_second_choice_number_in_pair ;
my @global_using_choice ;
my @global_tally_first_over_second_in_pair ;
my @global_tally_second_over_first_in_pair ;
my @global_tally_first_equal_second_in_pair ;
my @global_ballot_preference_for_choice ;
my @global_adjusted_ranking_for_adjusted_choice_bottom_up_version ;
my @global_adjusted_ranking_for_adjusted_choice_top_down_version ;
my @global_pair_counter_offset_for_first_adjusted_choice ;
my @global_log_info_choice_at_position ;
my @global_rank_to_normalize_for_adjusted_choice ;

my %global_code_number_for_letters ;

my $global_scale_for_logged_pairwise_counts ;
my $global_comparison_count ;
my $global_sequence_score ;
my $global_not_same_count ;
my $global_sequence_score_using_choice_score_method ;
my $global_sequence_score_using_insertion_sort_method ;
my $global_sequence_score_using_all_scores_method ;
my $global_top_choice_according_to_choice_specific_scores ;

my @global_choice_score_popularity_rank_for_actual_choice ;
my @global_insertion_sort_popularity_rank_for_actual_choice ;


#-----------------------------------------------
#-----------------------------------------------
#  Indicate whether the first actions of this
#  module have been done.

BEGIN {

    $global_true = 1 ;
    $global_false = 0 ;
    $global_begin_module_actions_done = $global_false ;
    $global_intitialization_done = $global_false ;
    $global_logging_info = $global_false ;

}


#-----------------------------------------------
#-----------------------------------------------

=head1 FUNCTIONS

=cut

#-----------------------------------------------
#-----------------------------------------------





#-----------------------------------------------
#-----------------------------------------------
#  Begin exported subroutines.
#-----------------------------------------------
#-----------------------------------------------





=head2 votefair_read_calculate_write

Reads numbers from the standard input file, does all
the requested calculations, and writes requested
results to the standard output file.  In most
election situations this is the only subroutine
that needs to be used.

=cut

#-----------------------------------------------
#-----------------------------------------------
#     votefair_read_calculate_write
#-----------------------------------------------
#-----------------------------------------------

sub votefair_read_calculate_write
{

    my $input_number_count ;
    my $input_line ;
    my $invalid_characters ;
    my $next_number_text ;
    my $next_number ;
    my $previous_number ;
    my $next_result_code ;


#-----------------------------------------------
#  Reset all the values -- in case this
#  subroutine is used more than once.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        &do_full_initialization( ) ;
    }


#-----------------------------------------------
#  Read each line from the standard
#  input file.

    $global_case_specific_warning_begin = "case-" . "0" . "-warning-message:\n" . "word-case-capitalized " . "0" ;
    $previous_number = 0 ;
    $global_case_number = 0 ;
    $global_true_or_false_ignore_case[ $global_case_number ] = $global_false ;
    $input_number_count = 0 ;
    while( $input_line = <STDIN> )
    {
        chomp( $input_line ) ;
        $input_line =~ s/[\n\t]/ /sg ;


#-----------------------------------------------
#  If any non-numeric text is encountered,
#  ignore it, indicate a warning, and ignore the
#  entire case in which it occurs.

        while ( $input_line =~ /^(.*?)(([^ \-0-9]+)([^ 0-9]*)([^ \-0-9]+))(.*)$/s )
        {
            $invalid_characters = $2 ;
            $input_line = $1 . " " . $6 ;
            $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-non-numeric-characters (" . $invalid_characters . ")" . "\n-----\n\n" ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[Warning: Input line contains non-numeric characters (" . $invalid_characters . "), so this case (" . $global_case_number . ") will be ignored]\n" } ;
            $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
        }


#-----------------------------------------------
#  Get each number from the line, and put each
#  number into the input array.  The negative
#  numbers have the meanings that are declared
#  earlier in this module.  When a new case
#  starts, update the case number.

        while ( $input_line =~ /^[^\-0-9]*(\-?[0-9]+)(.*)$/s )
        {
            $next_number_text = $1 ;
            $input_line = $2 ;
            $next_number = $next_number_text + 0 ;
            $global_possible_error_message = &votefair_put_next_vote_info_number( $next_number ) ;
            if ( $global_possible_error_message ne "" )
            {
                last ;
            }
            $input_number_count ++ ;
            if ( $previous_number == $global_voteinfo_code_for_case_number )
            {
                $global_case_number = $next_number ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[case number " . $global_case_number . "]\n" } ;
                $global_case_specific_warning_begin = "case-" . $global_case_number . "-warning-message:\n" . "word-case-capitalized " . $global_case_number ;
           }
            $previous_number = $next_number ;
        }


#-----------------------------------------------
#  If the current line contains a number that
#  produces an error, exit the main loop.

        if ( $global_possible_error_message ne "" )
        {
            last ;
        }


#-----------------------------------------------
#  Repeat the loop to handle the next input line.

    }


#-----------------------------------------------
#  If less than two numbers were found, indicate
#  this no-data error.

    if ( $input_number_count < 2 )
    {
        $global_possible_error_message = "Error: Input file does not contain any data." ;
        $global_length_of_result_info_list = 0 ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[Error: Input file does not contain any data]\n" } ;
    }


#-----------------------------------------------
#  Do the calculations, after first checking
#  the input numbers for validity.

    if ( $global_possible_error_message eq "" )
    {
        $global_possible_error_message = &votefair_do_calculations_all_questions( ) ;
    }


#-----------------------------------------------
#  If any errors or warnings were encountered,
#  write the messages as Dashrep definitions.

    open ( MSGFILE , ">" . $global_error_message_filename ) ;
    print MSGFILE "dashrep-definitions-begin\n\n" ;
    if ( $global_possible_error_message =~ /[^ ]/ )
    {
        print MSGFILE "*-----  Error message  -----*\n\n\n" . "output-error-message:\n" . $global_possible_error_message . "\n" . "-----\n\n" ;
    } else
    {
        print MSGFILE "*-----  All OK, no error message  -----*\n\n\n" . "output-error-message:\n" . "-----\n\n" ;
    }
    print MSGFILE "output-warning-message:\n" . $global_output_warning_message . "\n" . "-----\n\n" ;

    print MSGFILE $global_output_warning_messages_case_or_question_specific . "\n" . "dashrep-definitions-end\n" ;
    close MSGFILE ;


#-----------------------------------------------
#  If there was an error, exit this subroutine.

    if ( $global_possible_error_message ne "" )
    {
        print $global_possible_error_message . "\n\n\n\n" ;
        print LOGOUT "Error encountered; see main output file (or file " . $global_error_message_filename . " or file " . $global_log_filename . ") for details" . "\n\n" ;
        return 0 ;
    } else
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[all done, no major error encountered]\n\n" } ;
    }


#-----------------------------------------------
#  Write the result code numbers to the standard
#  output file.

    if ( $global_length_of_result_info_list < 2 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[no results calculated]" . "\n\n" } ;
    } else
    {
        $global_pointer_to_output_results = 0 ;
        $next_result_code = &votefair_get_next_result_info_number( ) ;
#        if ( $global_logging_info == $global_true ) { print LOGOUT "[out: " . $next_result_code . "]" } ;
        while ( $next_result_code != $global_voteinfo_code_for_end_of_all_cases )
        {
            if ( $next_result_code == 0 )
            {
                print "0" . "\n" ;
            } elsif ( $next_result_code > 0 )
            {
                print sprintf( "%d" , $next_result_code ) . "\n" ;
            } else
            {
                if ( $global_true_or_false_request_dashrep_phrases_in_output == $global_true )
                {
                    print "voteinfo-inverse-" . sprintf( "%d" , -( $next_result_code ) ) . "-code" . "\n" ;
                } else
                {
                    print sprintf( "%d" , $next_result_code ) . "\n" ;
                }
            }
            $next_result_code = &votefair_get_next_result_info_number( ) ;
#            if ( $global_logging_info == $global_true ) { print LOGOUT "[out: " . $next_result_code . "]" } ;
        }
    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}




=head2 votefair_put_next_vote_info_number

Adds the next input vote-info number to the list
that stores the input data.
The meaning of the negative numbers are explained
in an output file that this module creates.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       votefair_put_next_vote_info_number
#-----------------------------------------------
#-----------------------------------------------

sub votefair_put_next_vote_info_number
{

    my $current_vote_info_number = 0 ;



#-----------------------------------------------
#  If initialization has not yet been done, do it.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        &do_full_initialization( ) ;
    }


#-----------------------------------------------
#  Get the next vote-info number.

    if ( scalar( @_ ) == 1 )
    {
        if ( defined( $_[ 0 ] ) )
        {
            $current_vote_info_number = $_[ 0 ] ;
        } else
        {
            warn "Error: Call to votefair_put_next_vote_info_number subroutine does not supply a parameter." ;
            return "error-no-parameter-supplied" ;
        }
    } else
    {
        warn "Error: Call to votefair_put_next_vote_info_number subroutine does not have exactly one parameter." ;
        return "error-not-exactly-one-parameter" ;
    }


#-----------------------------------------------
#  Ensure the array has not become too long.

    if ( $global_length_of_vote_info_list > $global_max_array_length )
    {
        warn "ERROR: Too many vote-info numbers ( " . $global_length_of_vote_info_list . ") supplied to votefair_put_next_vote_info_number subroutine." ;
        return "Error: Input file containing vote-info numbers is too long (" . $global_length_of_vote_info_list . ")" ;
    }


#-----------------------------------------------
#  Store the supplied vote-info number.

    $global_vote_info_list[ $global_length_of_vote_info_list ] = $current_vote_info_number ;
#    if ( $global_logging_info == $global_true ) { print LOGOUT "[" . $current_vote_info_number . "]" } ;


#-----------------------------------------------
#  Increment the list pointer.

    $global_length_of_vote_info_list ++ ;


#-----------------------------------------------
#  Insert an end-of-info code number at the next
#  position, in case this is the last vote-info
#  number put into the list.

    $global_vote_info_list[ $global_length_of_vote_info_list ] = $global_voteinfo_code_for_end_of_all_cases ;


#-----------------------------------------------
#  End of subroutine.

    return "" ;

}




=head2 votefair_get_next_result_info_number

Gets the next result-info number from the list
that stores the result information.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       votefair_get_next_result_info_number
#-----------------------------------------------
#-----------------------------------------------

sub votefair_get_next_result_info_number
{

    my $current_result_info_number ;


#-----------------------------------------------
#  If initialization has not yet been done,
#  indicate a major error because the user has
#  not yet supplied any input data.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        warn "ERROR: Input data must be supplied (and calculations done) before the votefair_get_next_result_info_number subroutine is called." ;
    }


#-----------------------------------------------
#  If the end of the list has been reached,
#  return the code that indicates the end
#  of the results.

    if ( ( $global_pointer_to_output_results >= $global_length_of_result_info_list ) || ( $global_pointer_to_output_results >= $global_max_array_length ) )
    {
        return $global_voteinfo_code_for_end_of_all_cases ;
    }


#-----------------------------------------------
#  If the pointer is negative, point to the
#  first item.

    if ( $global_pointer_to_output_results < 0 )
    {
        $global_pointer_to_output_results = 0 ;
    }


#-----------------------------------------------
#  If the stored value in the list is not
#  defined, indicate the end of the results.

    if ( not( defined( $global_output_results[ $global_pointer_to_output_results ] ) ) )
    {
        return $global_voteinfo_code_for_end_of_all_cases ;
    }


#-----------------------------------------------
#  Get the next result-info number.

    $current_result_info_number = $global_output_results[ $global_pointer_to_output_results ] ;
#    if ( $global_logging_info == $global_true ) { print LOGOUT "[" . $current_result_info_number . "]" } ;


#-----------------------------------------------
#  If the end-of-all-cases code is encountered,
#  return with that value -- without changing
#  the pointer.

    if ( $current_result_info_number == $global_voteinfo_code_for_end_of_all_cases )
    {
        return $global_voteinfo_code_for_end_of_all_cases ;
    }


#-----------------------------------------------
#  Increment the list pointer.

    $global_pointer_to_output_results ++ ;


#-----------------------------------------------
#  Return the value.

    return $current_result_info_number ;


#-----------------------------------------------
#  End of subroutine.

}




=head2 votefair_put_input_string

Interprets an input text string that contains
vote-info data (for all cases).  Unlike the
votefair_put_next_vote_info_number
subroutine, this string can contain easy-to-type
codes instead of numeric-only codes.
These codes are useful for testing this module,
and for supplying a hypothetical voting scenario
that is typed rather than collected through
ballots.

=cut

#-----------------------------------------------
#-----------------------------------------------
#    votefair_put_input_string
#-----------------------------------------------
#-----------------------------------------------

sub votefair_put_input_string
{
    my $current_vote_info_code ;
    my $current_vote_info_number ;
      my $partial_supplied_vote_info_text ;


#-----------------------------------------------
#  If initialization has not yet been done, do it.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        &do_full_initialization( ) ;
    }


#-----------------------------------------------
#  Get the text string.

    $global_supplied_vote_info_text = "" ;
    if ( scalar( @_ ) == 1 )
    {
        if ( defined( $_[ 0 ] ) )
        {
            $global_supplied_vote_info_text = $_[ 0 ] ;
        }
    }
      if ( $global_logging_info == $global_true ) { print LOGOUT "\n[vote info: " . $global_supplied_vote_info_text . "]\n\n" } ;


#-----------------------------------------------
#  Get each vote-info number or code, and write
#  it to the end of the vote-info input list.

    $partial_supplied_vote_info_text = $global_supplied_vote_info_text ;
    while (  $partial_supplied_vote_info_text =~ /^ *([^ ]+) *(.*)$/s )
    {
        $current_vote_info_code = $1 ;
        $partial_supplied_vote_info_text = $2 ;
        $current_vote_info_code =~ s/ +//g ;


#-----------------------------------------------
#  Ensure the array has not become too long.

        if ( $global_length_of_vote_info_list > $global_max_array_length )
        {
            warn "ERROR: Too many vote-info numbers ( " . $global_length_of_vote_info_list . ") supplied to votefair_put_next_vote_info_number subroutine." ;
            return "Error: Input file containing vote-info numbers is too long (" . $global_length_of_vote_info_list . ")" ;
        }


#-----------------------------------------------
#  Convert the code (which might be text digits)
#  into a vote-info number.

        if ( $current_vote_info_code =~ /^[0-9\-]+$/ )
        {
            $current_vote_info_number = $current_vote_info_code + 0 ;
        } elsif ( defined( $global_code_number_for_letters{ $current_vote_info_code } ) )
        {
            $current_vote_info_number = $global_code_number_for_letters{ $current_vote_info_code } ;
        }


#-----------------------------------------------
#  Store the supplied vote-info number.

        $global_vote_info_list[ $global_length_of_vote_info_list ] = $current_vote_info_number ;


#-----------------------------------------------
#  Increment the list pointer.

        $global_length_of_vote_info_list ++ ;


#-----------------------------------------------
#  Repeat the loop to handle the next vote-info
#  code in the string.

    }


#-----------------------------------------------
#  Insert an end-of-info code number at the next
#  position, in case this is the last vote info
#  put into the list.

    $global_vote_info_list[ $global_length_of_vote_info_list ] = $global_voteinfo_code_for_end_of_all_cases ;
    $global_length_of_vote_info_list ++ ;


#-----------------------------------------------
#  End of subroutine.

    return "" ;


}




=head2 votefair_get_output_string

Creates a text string that contains all the
results in a person-readable code.
It is useful for testing this module, and to
allow a person to directly (although cryptically)
read the results.

=cut

#-----------------------------------------------
#-----------------------------------------------
#    votefair_get_output_string
#-----------------------------------------------
#-----------------------------------------------

sub votefair_get_output_string
{

    my $current_result_info_number ;
    my $letters ;
    my $result_info ;
    my @letters_for_negative_of_code_number ;


#-----------------------------------------------
#  If initialization has not yet been done,
#  indicate a major error because the user has
#  not yet supplied any input data.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        warn "ERROR: Input data must be supplied (and calculations done) before the votefair_get_output_string subroutine is called." ;
    }


#-----------------------------------------------
#  Create the list of valid letter codes that is
#  indexed by the negative code number.

    foreach $letters ( keys( %global_code_number_for_letters ) )
    {
        $letters_for_negative_of_code_number[ - ( $global_code_number_for_letters{ $letters } ) ] = $letters ;
    }


#-----------------------------------------------
#  Point to the beginning of the output list.

    $global_pointer_to_output_results = 0 ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[get output string, length of output list is " . $global_length_of_result_info_list . "]\n" } ;


#-----------------------------------------------
#  Begin a loop that repeats for each result
#  number, stopping at the end of the results.

    while ( ( $global_pointer_to_output_results < $global_length_of_result_info_list ) && ( $global_pointer_to_output_results <= $global_max_array_length ) )
    {


#-----------------------------------------------
#  If the stored value in the list is not
#  defined, indicate the end of the results.

        if ( not( defined( $global_output_results[ $global_pointer_to_output_results ] ) ) )
        {
            $result_info .= "undefined-result-code-number" ;
            last ;
        }


#-----------------------------------------------
#  Get the next result-info number.

        $current_result_info_number = $global_output_results[ $global_pointer_to_output_results ] ;


#-----------------------------------------------
#  If the result number is negative, convert it
#  into the letters that are associated with that
#  code number.
#  If the number is positive, convert it to a
#  text version of that number.
#  Append the resulting text to the end of the
#  results string.

        if ( $current_result_info_number < 0 )
        {
            if ( defined( $letters_for_negative_of_code_number[ - ( $current_result_info_number ) ] ) )
            {
                $result_info .= $letters_for_negative_of_code_number[ - ( $current_result_info_number ) ] . " " ;
            } else
            {
                $result_info .= "undefined-code-number-negative-" . sprintf( "%d" , - ( $current_result_info_number ) ) ;
            }
        } elsif ( $current_result_info_number == 0 )
        {
            $result_info .= "0 " ;
        } else
        {
            $result_info .= sprintf( "%d" , $current_result_info_number ) . " " ;
        }


#-----------------------------------------------
#  When the end-of-all-cases code is encountered,
#  exit the loop.

        if ( $current_result_info_number == $global_voteinfo_code_for_end_of_all_cases )
        {
            last ;
        }


#-----------------------------------------------
#  Increment the list pointer.

        $global_pointer_to_output_results ++ ;


#-----------------------------------------------
#  Repeat the loop that gets each result
#  number.

    }


#-----------------------------------------------
#  Allow only one space between items, and
#  remove leading and trailing spaces (so that
#  these results can be used for testing).

    $result_info =~ s/^ +// ;
    $result_info =~ s/ +$//s ;
    $result_info =~ s/  +/ /gs ;


#-----------------------------------------------
#  Return the results.

    if ( $global_logging_info == $global_true ) { print LOGOUT "\n[vote info: " . $global_supplied_vote_info_text . "]\n\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "\n[results string: " . $result_info . "]\n\n" } ;
    return $result_info ;


#-----------------------------------------------
#  Point to the first item in the results list
#  in case the results are also accessed by
#  using the votefair_get_next_result_info_number
#  subroutine.

    $global_pointer_to_output_results = 0 ;


#-----------------------------------------------
#  End of subroutine.

}




=head2 votefair_do_calculations_all_questions

Does the requested calculations for all the
questions (although other subroutines do the
actual calculations).

=cut

#-----------------------------------------------
#-----------------------------------------------
#         votefair_do_calculations_all_questions
#-----------------------------------------------
#-----------------------------------------------

sub votefair_do_calculations_all_questions
{



#-----------------------------------------------
#  If initialization has not yet been done,
#  indicate a major error because the user has
#  not yet supplied any input data.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        warn "ERROR: Input data must be supplied before the votefair_do_calculations_all_questions subroutine is called." ;
    }


#-----------------------------------------------
#  Clear the output list.

    $global_pointer_to_output_results = 0 ;
    @global_output_results = ( ) ;
    $global_output_results[ $global_pointer_to_output_results ] = $global_voteinfo_code_for_end_of_all_cases ;
    $global_pointer_to_output_results = 0 ;


#-----------------------------------------------
#  Check for errors in the vote-info number list,
#  and get some needed values such as the number
#  of questions in each case, the number of
#  choices in each question, and requests that
#  apply to all the cases.  Also, determine
#  which cases, if any, need to be skipped
#  because they contain invalid vote-info
#  numbers.

    $global_possible_error_message = &check_vote_info_numbers( ) ;
    if ( $global_possible_error_message ne "" )
    {
        return "ERROR: Error in vote-info number list: " . $global_possible_error_message . "\n" ;
    }


#-----------------------------------------------
#  Begin a loop that handles each case.
#
#  Each case may involve voters and questions
#  that are unrelated to any other case.
#  The questions within the same case must
#  be questions that were on the same ballot and
#  voted on by the same people.
#
#  When all the cases have been handled, exit
#  the loop.

    $global_input_pointer_start_next_case = 0 ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, beginning loop that handles each case]" } ;
    while ( ( $global_input_pointer_start_next_case < $global_max_array_length ) && ( $global_vote_info_list[ $global_input_pointer_start_next_case ] != $global_voteinfo_code_for_end_of_all_cases ) )
    {
#        if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, pointer: " . $global_input_pointer_start_next_case . " , value: " . $global_vote_info_list[ $global_input_pointer_start_next_case ] . "]\n" } ;

        if ( $global_vote_info_list[ $global_input_pointer_start_next_case ] != $global_voteinfo_code_for_case_number )
        {
            $global_input_pointer_start_next_case ++ ;
            next ;
        }
        $global_input_pointer_start_next_case ++ ;
        $global_case_number = $global_vote_info_list[ $global_input_pointer_start_next_case ] ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "\n[case " . $global_case_number . "]" } ;
        $global_input_pointer_start_next_case ++ ;


#-----------------------------------------------
#  Indicate the case number in the results list.

        &put_next_result_info_number( $global_voteinfo_code_for_case_number ) ;
        &put_next_result_info_number( $global_case_number ) ;


#-----------------------------------------------
#  If the vote-info numbers for this case were
#  invalid, skip this case.


#        if ( $global_case_number > 40 )
#        {
#            $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
#        }


        if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
        {
            &put_next_result_info_number( $global_voteinfo_code_for_skip_case ) ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, case " . $global_case_number . " skipped because errors were found in the vote-info numbers]\n" } ;
            while ( ( $global_vote_info_list[ $global_input_pointer_start_next_case ] != $global_voteinfo_code_for_case_number ) && ( $global_vote_info_list[ $global_input_pointer_start_next_case ] != $global_voteinfo_code_for_end_of_all_cases ) && ( $global_input_pointer_start_next_case < $global_max_array_length ) )
            {
                $global_input_pointer_start_next_case ++ ;
            }
            next ;
        }

#-----------------------------------------------
#  If there are no questions in this case,
#  indicate it, and then restart the main loop.
#  If this error condition applies, it has
#  already been indicated in the output
#  warning messages.

        if ( $global_question_count_for_case[ $global_case_number ] < 1 )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, warning: case " . $global_case_number . " does not contain any questions]\n" } ;
            next ;
        }


#-----------------------------------------------
#  Begin a loop that handles each question
#  (within a case).
#  Question numbers are sequential (i.e. no
#  question numbers are skipped).

        if ( $global_logging_info == $global_true ) { print LOGOUT "\n[all questions, case " . $global_case_number . ", has " . $global_question_count_for_case[ $global_case_number ] . " questions]\n" } ;
        for ( $global_question_number = 1 ; $global_question_number <= $global_question_count_for_case[ $global_case_number ] ; $global_question_number ++ )
        {


#-----------------------------------------------
#  Indicate the question number in the results list.

            &put_next_result_info_number( $global_voteinfo_code_for_question_number ) ;
            &put_next_result_info_number( $global_question_number ) ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "\n[all questions, case " . $global_case_number . ", question " . $global_question_number . "]\n" } ;


#-----------------------------------------------
#  Get the number of choices for this question.

            $global_full_choice_count = $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, actual choice count = " . $global_full_choice_count . "]" } ;


#-----------------------------------------------
#  Do the calculations for this question.

            &calculate_results_for_one_question( ) ;


#-----------------------------------------------
#  Write the total ballot count (for cross-checking
#  purposes).

            &put_next_result_info_number( $global_voteinfo_code_for_total_ballot_count ) ;
            &put_next_result_info_number( $global_current_total_vote_count ) ;


#-----------------------------------------------
#  Repeat the loop that handles the next question
#  (within a case).

            if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, this question done, repeating loop for next question]\n" } ;
        }


#-----------------------------------------------
#  Repeat the loop that handles the next case.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, all questions done, repeating loop for next case]\n" } ;
    }


#-----------------------------------------------
#  Terminate the results list.

    &put_next_result_info_number( $global_voteinfo_code_for_end_of_all_cases ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, all cases done]\n" } ;


#-----------------------------------------------
#  Save the result-info list pointer as the
#  length of the portion of the result-info
#  list that contains results.
#  Then reset the pointer to the
#  beginning of the list.

    $global_length_of_result_info_list = $global_pointer_to_output_results + 1 ;
    $global_pointer_to_output_results = 0 ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, length of output list is " . $global_length_of_result_info_list . "]\n" } ;


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[all questions, exiting subroutine]\n" } ;
    return "" ;

}




=head2 votefair_start_new_cases

Does initialization again so that another batch of
cases of data can be processed.  Normally this
subroutine is not needed because all the cases
(each with independent questions and preferences)
are done in one batch.

=cut

#-----------------------------------------------
#-----------------------------------------------
#    votefair_start_new_cases
#-----------------------------------------------
#-----------------------------------------------

sub votefair_start_new_cases
{


#-----------------------------------------------
#  Request that initialization be done again.
#  Do not actually do the initialization until
#  it is needed, in case this subroutine is
#  used unnecessarily.

    $global_intitialization_done = $global_false ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[requested doing full initialization]\n" } ;


#-----------------------------------------------
#  End of subroutine.

}





=head2 votefair_always_do_rep_and_party_ranking

Requests that VoteFair representation ranking and
VoteFair party ranking always be done -- except
when only plurality votes are requested (because
in those cases 1-2-3 ballots have not been used).

=cut

#-----------------------------------------------
#-----------------------------------------------
#    votefair_always_do_rep_and_party_ranking
#-----------------------------------------------
#-----------------------------------------------

sub votefair_always_do_rep_and_party_ranking
{


#-----------------------------------------------
#  If initialization has not yet been done, do it.

    if ( ( $global_begin_module_actions_done != $global_true ) || ( $global_intitialization_done != $global_true ) )
    {
        &do_full_initialization( ) ;
    }


#-----------------------------------------------
#  Request that VoteFair representation ranking
#  and VoteFair party ranking always be done.

    $global_true_or_false_always_request_only_plurality_results = $global_false ;
    $global_true_or_false_always_request_votefair_representation_rank = $global_true ;
    $global_true_or_false_always_request_votefair_party_rank = $global_true ;


#-----------------------------------------------
#  Subroutine done.

    return ;

}




#-----------------------------------------------
#-----------------------------------------------
#  Begin non-exported subroutines.
#-----------------------------------------------
#-----------------------------------------------





=head2 calc_votefair_popularity_rank

(Not exported, for internal use only.)

Handles the overhead actions for calculating
VoteFair popularity ranking results, as
described in the book "Ending The Hidden
Unfairness In U.S. Elections", and as
described in Wikipedia as the "Condorcet-Kemeny
method" (which redirects to the "Kemeny-Young
method" article).  See VoteFair.org for details.

These results are used in situations where
a single seat is being filled (and there is
only one such seat), or to determine the full
ranking of choices, or to correctly identify
the least-popular choice (where that choice
is a contestant who is eliminated before the
next round of the contest).

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_votefair_popularity_rank
#-----------------------------------------------
#-----------------------------------------------

sub calc_votefair_popularity_rank
{

    my $actual_choice ;
    my $adjusted_choice ;
    my $ranking_level ;
    my $twice_highest_possible_score ;
    my $ranking_level_from_all_scores_calc ;


#-----------------------------------------------
#  Initialize the result rankings -- to zeros, which
#  indicate that no ranking has been done.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $global_using_choice[ $actual_choice ] == $global_true )
        {
            $global_popularity_ranking_for_actual_choice[ $actual_choice ] = 0 ;
        }
    }
    $global_choice_count_at_top_popularity_ranking_level = 0 ;
    $global_actual_choice_at_top_popularity_ranking_level = 0 ;


#-----------------------------------------------
#  Initialize the insertion-sort rankings to zeros,
#  which indicate that no ranking has been done.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $global_using_choice[ $actual_choice ] == $global_true )
        {
            $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] = 0 ;
        }
    }


#-----------------------------------------------
#  If the total of the vote counts is zero,
#  there is a code bug, so indicate an error.

    if ( $global_current_total_vote_count <= 0 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, zero counts on ballots]\n" } ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, Error: Case " . $global_case_number . " has triggered a program bug caused by a failure to check for zero vote counts]\n" } ;
        $global_possible_error_message .= "Error: Case " . $global_case_number . " has triggered a program bug caused by a failure to check for zero vote counts.  " ;
        return ;
    }


#-----------------------------------------------
#  If there are not at least two choices,
#  indicate an error and return.

    if ( $global_adjusted_choice_count < 2 )
    {
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " does-not-have-at-least-two-choices-so-VoteFair-popularity-ranking-cannot-be-done" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, ERROR: number of (adjusted) choices is less than two]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Do VoteFair choice-specific pairwise-score
#  (CSPS) ranking.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, VoteFair choice-score ranking calculations beginning]\n" } ;
    &calc_votefair_choice_specific_pairwise_score_popularity_rank( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, VoteFair choice-score ranking calculations done]\n" } ;


#-----------------------------------------------
#  Do VoteFair popularity ranking using the
#  insertion-sort method, starting with the
#  ranking that was calculated by the
#  choice-specific pairwise-score (CSPS)
#  method.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, VoteFair insertion-sort popularity ranking calculations beginning]\n" } ;
    &calc_votefair_insertion_sort_popularity_rank( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, VoteFair insertion-sort popularity ranking calculations done]\n" } ;


#-----------------------------------------------
#  Optionally, in the future, do a cross-check
#  that uses the all-scores method to rank the
#  top six choices.  This cross-check would
#  identify theoretically possible situations
#  in which the highest-ranked choice is not
#  the highest-ranked choice in a sequence that
#  has the single (untied) highest sequence
#  score.  Cases that involve multiple sequences
#  with the same highest sequence score are not
#  relevant for matching Condorcet-Kemeny
#  results because that method does not specify
#  how multiple same-highest-score cases should
#  be resolved.


#-----------------------------------------------
#  If there are too many choices, or if there
#  are too many ballots that could combine with
#  the number of choices to produce an overflow
#  in the highest sequence score, skip the
#  calculations (done in the next section)
#  that check all the sequence scores.

    $global_check_all_scores_choice_limit = 6 ;
    $global_maximum_twice_highest_possible_score = 900000 ;
    $twice_highest_possible_score = $global_adjusted_choice_count * $global_adjusted_choice_count * $global_current_total_vote_count ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, adjusted choice count is " . $global_adjusted_choice_count . "]\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, total vote count is " . $global_current_total_vote_count . "]\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, twice highest possible score is " . $twice_highest_possible_score . "]\n" } ;

    if ( ( $global_adjusted_choice_count <= $global_check_all_scores_choice_limit ) && ( $twice_highest_possible_score <= $global_maximum_twice_highest_possible_score ) )
    {


#-----------------------------------------------
#  Do VoteFair popularity ranking calculations
#  by calculating all the sequence scores and
#  finding the sequence with the highest score.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, calling calc_all_sequence_scores subroutine]\n" } ;
        &calc_all_sequence_scores( ) ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, returned from calc_all_sequence_scores subroutine]\n" } ;
    }


#-----------------------------------------------
#  If the full-score calculations were not done,
#  and the insertion-sort calculations were done,
#  use the results from the insertion-sort
#  calculations.

    my $ranking_level_from_insertion_sort_calc ;

    $adjusted_choice = 1 ;
    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
    $ranking_level_from_all_scores_calc = $global_popularity_ranking_for_actual_choice[ $actual_choice ] ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, sample choice " . $actual_choice . " is at popularity level " . $ranking_level_from_all_scores_calc  . "]\n" } ;
    $ranking_level_from_insertion_sort_calc = $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, sample choice " . $actual_choice . " is at insert-sort popularity level " . $ranking_level_from_insertion_sort_calc  . "]\n" } ;
    if ( ( $ranking_level_from_all_scores_calc == 0 ) && ( $ranking_level_from_insertion_sort_calc != 0 ) )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, using insertion-sort ranking results (because all-score method not done]\n" } ;
        {
            $global_sequence_score_using_all_scores_method = 0 ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                $ranking_level = $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] ;
                $global_popularity_ranking_for_actual_choice[ $actual_choice ] = $ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " is at popularity level " . $ranking_level  . "]\n" } ;
            }
        }
    }


#-----------------------------------------------
#  If the full-score calculations were not done,
#  create a warning message that applies to the
#  current question, and request only plurality
#  counts, and skip over the next section.

    $adjusted_choice = 1 ;
    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
    if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 0 )
    {
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " has-too-many-choices-so-plurality-counting-done" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, Warning: Too many choices (" . $global_adjusted_choice_count . ") for this software version (which handles " . $global_check_all_scores_choice_limit . "), so only plurality results calculated]\n" } ;
        $global_true_or_false_request_only_plurality_results = $global_true ;
    } else
    {


#-----------------------------------------------
#  For use by the VoteFair representation
#  ranking and VoteFair party ranking
#  subroutines, count the number of choices
#  that are ranked as most popular.
#  If there is just one top-ranked choice,
#  make it available as a single value.
#  Otherwise set the single value to zero.

        $adjusted_choice = 1 ;
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] > 0 )
        {
            $global_choice_count_at_top_popularity_ranking_level = 0 ;
            $global_actual_choice_at_top_popularity_ranking_level = 0 ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
                {
                    $global_choice_count_at_top_popularity_ranking_level ++ ;
                    if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
                    {
                        $global_actual_choice_at_top_popularity_ranking_level = $actual_choice ;
                    } else
                    {
                        $global_actual_choice_at_top_popularity_ranking_level = 0 ;
                    }
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, choice " . $actual_choice . " is at top ranking level]\n" } ;
                }
            }
            if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, count of most-popular choices is " . $global_choice_count_at_top_popularity_ranking_level . "]\n" } ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, if only one top choice, choice number is " . $global_actual_choice_at_top_popularity_ranking_level . "]\n" } ;
        }


#-----------------------------------------------
#  Finish skipping the above section if the
#  calculations were not done.

    }


#-----------------------------------------------
#  Compare the results with other calculation
#  methods.

    &compare_popularity_results( ) ;


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[popularity rank, done calculating VoteFair popularity ranking results for question " . $global_question_number . " in case " . $global_case_number . "]\n" } ;
    return 1 ;

}




=head2 calc_votefair_representation_rank

(Not exported, for internal use only.)

Calculates VoteFair representation ranking
results, as described in the book "Ending The
Hidden Unfairness In U.S. Elections."
These results are used in situations where
more than one choice is selected, such as
when there is more than one seat being filled,
or when there is more than one activity
(for participation) being offered at the
same time (and attendance at both activities
is not possible).
The first-most representative choice is the most
popular based on VoteFair popularity ranking,
which is calculated before arriving here.
Therefore, this subroutine identifies the
VoteFair-based second-most representative,
third-most representative, etc. choices
in an election.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_votefair_representation_rank
#-----------------------------------------------
#-----------------------------------------------

sub calc_votefair_representation_rank
{

    my $actual_choice ;
    my $adjusted_choice ;
    my $most_preferred_choice ;
    my $previous_most_representative_choice ;
    my $ignored_vote_count ;
    my $non_ignored_vote_count ;
    my $alternative_most_preferred_choice ;
    my $vote_count_for_reduced_influence ;
    my $reduced_influence_amount ;
    my $tie_exists ;
    my $number_of_representation_levels_ranked ;
    my $number_of_choices_rep_ranked ;
    my $single_nonranked_choice ;
    my $initial_choice_count_for_rep_ranking ;
    my $true_or_false_log_details ;


#-----------------------------------------------
#  Hide or show the details in the log file.

    $true_or_false_log_details = $global_false ;
    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[rep ranking, beginning calc_votefair_representation_rank subroutine]\n\n" ;
        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "[rep ranking, details shown (change flag value to hide details)]\n" ;
        } else
        {
            print LOGOUT "[rep ranking, details hidden (change flag value to view details)]\n" ;
        }
    }


#-----------------------------------------------
#  Starting representation calculations.

    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, starting representation calculations]\n" } ;


#-----------------------------------------------
#  Count the number of choices to be ranked.
#  Also initialize the list that keeps track of
#  which choices have been "representation"
#  ranked so far.
#  Assume that not all the choices are
#  involved (which applies to calculations
#  needed by VoteFair party ranking), which
#  means that if a choice is not being used
#  (overall), then it is not involved in this
#  ranking.
#  Also initialize the list that holds the
#  results -- to indicate which choices were
#  not ranked in case of an early exit.

    $initial_choice_count_for_rep_ranking = 0 ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_using_choice[ $actual_choice ] == $global_true )
        {
            $global_representation_ranking_for_actual_choice[ $actual_choice ] = 0 ;
            $initial_choice_count_for_rep_ranking ++ ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, need to rank choice " . $actual_choice . "]\n" } ;
        } else
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, will not be ranking choice " . $actual_choice . "]\n" } ;
        }
    }
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, number of choices to rank is " . $initial_choice_count_for_rep_ranking . " (out of " . $global_full_choice_count . " choices)]\n" } ;


#-----------------------------------------------
#  If there are not at least two choices,
#  indicate an error.

    if ( $initial_choice_count_for_rep_ranking < 2 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ERROR: number of choices for representation ranking is less than two]\n" } ;
        return ;
    }


#-----------------------------------------------
#  If there are only two choices, indicate that
#  the second choice (not the most popular
#  choice) is ranked second.  However, if there
#  is a tie at the top level, indicate those
#  two choices as tied for representation
#  ranking.

    if ( $initial_choice_count_for_rep_ranking == 2 )
    {
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, number of choices for representation ranking is two]\n" } ;
        if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
        {
            $most_preferred_choice = $global_actual_choice_at_top_popularity_ranking_level ;
            $global_representation_ranking_for_actual_choice[ $most_preferred_choice ] = 1 ;
            $global_using_choice[ $most_preferred_choice ] = $global_false ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, first-most-representative choice is " . $most_preferred_choice . "]\n" } ;
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( ( $global_using_choice[ $actual_choice ] == $global_true ) && ( $actual_choice != $most_preferred_choice ) )
                {
                    $global_representation_ranking_for_actual_choice[ $actual_choice ] = 2 ;
                    $global_second_most_representative_actual_choice = $actual_choice ;
                    $global_using_choice[ $actual_choice ] = $global_false ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, second-most-representative choice is " . $actual_choice . "]\n" } ;
                    last ;
                }
            }
        } else
        {
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $global_using_choice[ $actual_choice ] == $global_true )
                {
                    $global_representation_ranking_for_actual_choice[ $actual_choice ] = 1 ;
                    $global_using_choice[ $actual_choice ] = $global_false ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, two-way tie, most representative choice is " . $actual_choice . "]\n" } ;
                }
            }
        }
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, the only two choices have been ranked, done with representation ranking]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Specify how many representation levels
#  should be calculated.
#  It cannot exceed the maximum allowance.
#  This is used as a minimum, and is exceeded if
#  there are ties or if just one choice remains.

    if ( $global_representation_levels_requested > $global_limit_on_representation_rank_levels )
    {
        $global_representation_levels_requested = $global_limit_on_representation_rank_levels ;
    }
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, will calculate " . $global_representation_levels_requested . " representation levels]\n" } ;


#-----------------------------------------------
#  If no representation calculations should
#  be done, indicate that and return.

    if ( $global_representation_levels_requested < 1 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, no representation calculations were requested]\n" } ;
        return ;
    }


#-----------------------------------------------
#-----------------------------------------------
#  Begin the loop that identifies each pair of
#  most-representative choices.
#
#  Assume that the most popular choice has
#  already been determined.
#
#  The first time through this loop, most of the
#  first half of the loop identifies the
#  second-most representative choice, and
#  the second half of the loop identifies the
#  third-most representative choice (which is
#  the most popular choice among the remaining
#  choices, without any representation
#  adjustment.
#  The second time through this loop the
#  fourth-most representative and fifth-most
#  representative choices are identified.
#  Etc.

    $number_of_choices_rep_ranked = 0 ;
    $number_of_representation_levels_ranked = 0 ;
    $global_second_most_representative_actual_choice = 0 ;
    while ( $global_true )
    {


#-----------------------------------------------
#  Count the next representation level.

        $number_of_representation_levels_ranked ++ ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, identifying choices at representation level " . $number_of_representation_levels_ranked . "]\n" } ;


#-----------------------------------------------
#  Using the VoteFair popularity ranking results,
#  if there is just one currently most preferred
#  choice (among the remaining choices), identify
#  it as the first-most (or next-most)
#  representative choice.

        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, there are " . $global_choice_count_at_top_popularity_ranking_level . " choices at the most popular level]\n" } ;
        if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
        {
            $most_preferred_choice = $global_actual_choice_at_top_popularity_ranking_level ;
            $global_representation_ranking_for_actual_choice[ $most_preferred_choice ] = $number_of_representation_levels_ranked ;
            $global_using_choice[ $most_preferred_choice ] = $global_false ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $most_preferred_choice . " is at rep level " . $number_of_representation_levels_ranked . " (at repcase 1)]\n" } ;
            $number_of_choices_rep_ranked ++ ;
            $previous_most_representative_choice = $most_preferred_choice ;


#-----------------------------------------------
#  If there is a tie at this level, rank the tied
#  choices at the current representation ranking
#  level, rank the remaining choices at the next
#  level, indicate that a tie-breaking vote must be
#  introduced before the full representation
#  ranking can be determined, and exit the main loop.

        } elsif ( $global_choice_count_at_top_popularity_ranking_level > 1 )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, at this representation ranking a tie -- among " . $global_choice_count_at_top_popularity_ranking_level . " choices -- has been encountered]\n" } ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
                {
                    $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked ;
                } else
                {
                    $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked + 1 ;
                }
                $global_using_choice[ $actual_choice ] = $global_false ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $actual_choice . " is at rep level " . $global_representation_ranking_for_actual_choice[ $actual_choice ] . " (at repcase 2)]\n" } ;
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because of tie]\n" } ;
            last ;
        } else
        {
            $global_output_warning_messages_case_or_question_specific .= "case-" . $global_case_number . "-question-" . $global_question_number . "-results-type-representation-warning-message:\n" . "ERROR: zero choices popularity ranked, so program bug!" . $global_warning_end ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ERROR: zero choices popularity ranked, so program bug!]\n" } ;
            return ;
        }


#-----------------------------------------------
#  If there is just one remaining choice, rank it
#  as least representative, and exit the loop.

        if ( $number_of_choices_rep_ranked == $initial_choice_count_for_rep_ranking - 1 )
        {
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $global_using_choice[ $actual_choice ] == $global_true )
                {
                    $single_nonranked_choice = $actual_choice ;
                    last ;
                }
            }
            $number_of_representation_levels_ranked ++ ;
            $global_representation_ranking_for_actual_choice[ $single_nonranked_choice ] = $number_of_representation_levels_ranked ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $single_nonranked_choice . " is the only choice remaining]\n" } ;
            $global_using_choice[ $single_nonranked_choice ] = $global_false ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $single_nonranked_choice . " is at rep level " . $number_of_representation_levels_ranked . " (at repcase 3)]\n" } ;
            $number_of_choices_rep_ranked ++ ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because ranked last choice]\n" } ;
            $global_using_choice[ $previous_most_representative_choice ] = $global_false ;
            last ;
        }


#-----------------------------------------------
#  If no more representation calculations are
#  needed, exit the main loop.

        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, number of rep ranked choices is " . $number_of_choices_rep_ranked . "]\n" } ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, current representation level is " . $number_of_representation_levels_ranked . " (for repcase 3)]\n" } ;
        if ( ( $number_of_choices_rep_ranked >= $initial_choice_count_for_rep_ranking ) || ( $number_of_representation_levels_ranked  >= $global_representation_levels_requested ) )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because no more representation ranking needed]\n" } ;
            $global_using_choice[ $previous_most_representative_choice ] = $global_false ;
            last ;
        }


#-----------------------------------------------
#  Indicate the previously most popular choice is
#  no longer considered in the remaining steps.

        $global_using_choice[ $previous_most_representative_choice ] = $global_false ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $previous_most_representative_choice . " is ignored]\n" } ;


#-----------------------------------------------
#-----------------------------------------------
#  Restart at the beginning of all the ballots.

        &reset_ballot_info_and_tally_table( ) ;


#-----------------------------------------------
#  Specify the normal influence of one vote per ballot.

        $global_ballot_influence_amount = 1.0 ;


#-----------------------------------------------
#  Ignore any ballot in which the previous
#  most representative choice
#  (from among the non-ignored choices)
#  is ranked at the first preference level.
#
#  For the remaining ballots, ignore the
#  previous most representative choice
#  and convert the remaining ballot information
#  into numbers in a new tally table.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, now excluding ballots that rank choice " . $previous_most_representative_choice . " as most preferred, and excluding that choice from the available choices]\n" } ;
        $non_ignored_vote_count = 0 ;
        while ( $global_true )
        {
            $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
            if ( $global_ballot_info_repeat_count < 1 )
            {
                last ;
            }
            if ( $global_ballot_preference_for_choice[ $previous_most_representative_choice ] > 1 )
            {
                &add_preferences_to_tally_table( ) ;
                $non_ignored_vote_count += $global_ballot_info_repeat_count ;
            } else
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, excluded]\n" } ;
            }
        }


#-----------------------------------------------
#  Calculate the number of votes ignored and the
#  number of votes not ignored.

        $ignored_vote_count = $global_current_total_vote_count - $non_ignored_vote_count ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, " . $non_ignored_vote_count . " ballots tallied, " . $ignored_vote_count . " ballots ignored]\n" } ;


#-----------------------------------------------
#  If all the ballots were ignored, skip ahead to
#  calculate the popularity of the remaining choices.

        if ( $non_ignored_vote_count == 0 )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, all the ballots have been ignored, so skipping several sections of code and then will calculate the popularity of the remaining choices]\n" } ;
        } else
        {


#-----------------------------------------------
#  Based on the information in the tally table,
#  and with some choices ignored,
#  identify the overall popularity ranking.

            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ranking remaining choices (case 1)]\n" } ;
            &calc_votefair_popularity_rank( ) ;


#-----------------------------------------------
#  Identify the first-most preferred choice.

            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, there are " . $global_choice_count_at_top_popularity_ranking_level . " choices at the most popular level]\n" } ;
            if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
            {
                $alternative_most_preferred_choice = $global_actual_choice_at_top_popularity_ranking_level ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $alternative_most_preferred_choice . " is most preferred]\n" } ;
            } elsif ( $global_choice_count_at_top_popularity_ranking_level > 1 )
            {


#-----------------------------------------------
#  If there is a tie at this level, indicate it
#  and exit the main loop.

                $tie_exists = $global_true ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, two or more choices are tied as most-popular among the voters who did not rank the first-most representative choice at the first preference level]\n" } ;
                $number_of_representation_levels_ranked ++ ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
                    {
                        $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked ;
                    } else
                    {
                        $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked + 1 ;
                    }
                    $global_using_choice[ $actual_choice ] = $global_false ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $actual_choice . " is at rep level " . $global_representation_ranking_for_actual_choice[ $actual_choice ] . " (at repcase 4)]\n" } ;
                }
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because of tie]\n" } ;
                $global_using_choice[ $previous_most_representative_choice ] = $global_false ;
                last ;
            } else
            {
                $global_output_warning_messages_case_or_question_specific .= "case-" . $global_case_number . "-question-" . $global_question_number . "-results-type-representation-warning-message:\n" . "ERROR: zero choices popularity ranked, so program bug!" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ERROR: zero choices popularity ranked, so program bug!]\n" } ;
                return ;
            }


#-----------------------------------------------
#  Ignore the previous most representative choice
#  in the remaining calculations.

            $global_using_choice[ $previous_most_representative_choice ] = $global_false ;


#-----------------------------------------------
#-----------------------------------------------
#  Again restart at the beginning of all the ballots.

            &reset_ballot_info_and_tally_table( ) ;


#-----------------------------------------------
#  Count the number of ballots in which
#  the previous most representative choice is
#  preferred over the alternative-most-preferred choice,
#  which was just identified.

            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, counting ballots that rank choice " . $previous_most_representative_choice . " as preferred more than choice " . $alternative_most_preferred_choice . "]\n" } ;
            $vote_count_for_reduced_influence = 0 ;
            while ( $global_true )
            {
                $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
                if ( $global_ballot_info_repeat_count < 1 )
                {
                    last ;
                }
                if ( $global_ballot_preference_for_choice[ $previous_most_representative_choice ] <= $global_ballot_preference_for_choice[ $alternative_most_preferred_choice ] )
                {
                    $vote_count_for_reduced_influence += $global_ballot_info_repeat_count ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, counted]\n" } ;
                }
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, vote count for reduced influence is " . $vote_count_for_reduced_influence . "]\n" } ;


#-----------------------------------------------
#  Calculate the reduced influence that is appropriate
#  for voters who are already well-represented by the
#  first-most representative choice.

            if ( $vote_count_for_reduced_influence >= 1 )
            {
                $reduced_influence_amount = ( $vote_count_for_reduced_influence - ( $global_current_total_vote_count / 2.0 ) ) / $vote_count_for_reduced_influence ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, influence reduced by: " . $reduced_influence_amount . "]\n" } ;
            } else
            {
                $reduced_influence_amount = 0 ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, no ballots need their influence reduced]\n" } ;
            }
            if ( $reduced_influence_amount < 0 )
            {
                $reduced_influence_amount = 0 ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, the number calculated for the amount of reduced influence is less than zero, so a zero value is used instead]\n" } ;
            }


#-----------------------------------------------
#-----------------------------------------------
#  Again restart at the beginning of all the ballots.

            &reset_ballot_info_and_tally_table( ) ;


#-----------------------------------------------
#  Again convert the ballot information into
#  numbers in a new tally table.  Reduce the
#  influence of any ballot in which the previous
#  most representative choice is preferred over
#  the alternative-most-preferred choice.
#  For other ballots, use the normal amount of
#  influence.  However, scale the decimal
#  values to integer numbers -- so that tied
#  situations are correctly handled.

            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, calculating popularity ranking with reduced influence -- of " . sprintf( "%0.4f" , $reduced_influence_amount ) . " -- for the " . $vote_count_for_reduced_influence . " ballots that prefer choice " . $previous_most_representative_choice . " more than choice " . $alternative_most_preferred_choice . ", and scaling decimal pairwise counts by " . ( $vote_count_for_reduced_influence * 10 ) . "]\n" } ;
            while ( $global_true )
            {
                $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
                if ( $global_ballot_info_repeat_count < 1 )
                {
                    last ;
                }
                if ( $global_ballot_preference_for_choice[ $previous_most_representative_choice ] <= $global_ballot_preference_for_choice[ $alternative_most_preferred_choice ] )
                {
                    $global_ballot_influence_amount = int( $reduced_influence_amount * $vote_count_for_reduced_influence * 10 ) ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, reduced]\n" } ;
                } else
                {
                    $global_ballot_influence_amount = int( 1.0 * $vote_count_for_reduced_influence * 10 );
                }
                &add_preferences_to_tally_table ;
            }


#-----------------------------------------------
#  Based on the information in the tally table,
#  identify the overall popularity ranking.

            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ranking remaining choices (case 2)]\n" } ;
            &calc_votefair_popularity_rank( ) ;


#-----------------------------------------------
#  Count the next representation level.

            $number_of_representation_levels_ranked ++ ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, identifying choices at representation ranking " . $number_of_representation_levels_ranked . "]\n" } ;


#-----------------------------------------------
#  If there is just one currently most preferred
#  choice, identify it as the next-most representative
#  choice based on the reduced influence of the
#  identified ballots.

            if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
            {
                $most_preferred_choice = $global_actual_choice_at_top_popularity_ranking_level ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $most_preferred_choice . " is most preferred]\n" } ;
                $global_representation_ranking_for_actual_choice[ $most_preferred_choice ] = $number_of_representation_levels_ranked ;
                $global_using_choice[ $most_preferred_choice ] = $global_false ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $most_preferred_choice . " is at rep level " . $number_of_representation_levels_ranked . " (at repcase 6)]\n" } ;
                $number_of_choices_rep_ranked ++ ;
                $previous_most_representative_choice = $most_preferred_choice ;


#-----------------------------------------------
#  If there is a tie at this level, list the tied
#  choices, indicate that a tie-breaking vote must be
#  introduced before the next-most representative
#  choices can be identified, and exit the main loop.

            } else
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, at this representation ranking -- after reducing the influence of well-represented voters -- a tie has been encountered.  A tie-breaking vote is needed to go further]\n" } ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
                    {
                        $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked ;
                    } else
                    {
                        $global_representation_ranking_for_actual_choice[ $actual_choice ] = $number_of_representation_levels_ranked + 1 ;
                    }
                    $global_using_choice[ $actual_choice ] = $global_false ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $actual_choice . " is at rep level " . $global_representation_ranking_for_actual_choice[ $actual_choice ] . " (at repcase 7)]\n" } ;
                }
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because of tie]\n" } ;
                last ;
            }


#-----------------------------------------------
#  This is where the code skips ahead to if all
#  the voters indicate the previous-most
#  representative choice as their first choice.

        }


#-----------------------------------------------
#-----------------------------------------------
#  If there is just one remaining choice, rank it
#  as least representative, and exit the loop.

        if ( $initial_choice_count_for_rep_ranking - $number_of_choices_rep_ranked == 1 )
        {
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $global_using_choice[ $actual_choice ] == $global_true )
                {
                    $single_nonranked_choice = $actual_choice ;
                    last ;
                }
            }
            $number_of_representation_levels_ranked ++ ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $single_nonranked_choice . " is the only choice remaining]\n" } ;
            $global_representation_ranking_for_actual_choice[ $single_nonranked_choice ] = $number_of_representation_levels_ranked ;
            $global_using_choice[ $single_nonranked_choice ] = $global_false ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, choice " . $single_nonranked_choice . " is at rep level " . $number_of_representation_levels_ranked . " (at repcase 8)]\n" } ;
            $number_of_choices_rep_ranked ++ ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because ranked last choice]\n" } ;
            last ;
        }


#-----------------------------------------------
#  If no more representation calculations are
#  needed, exit the main loop.

        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, number of rep ranked choices is " . $number_of_choices_rep_ranked . "]\n" } ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, next representation level is " . $number_of_representation_levels_ranked . " (for repcase 8)]\n" } ;
        if ( ( $number_of_choices_rep_ranked >= $initial_choice_count_for_rep_ranking ) || ( $number_of_representation_levels_ranked  >= $global_representation_levels_requested ) )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, exiting loop because no more representation ranking needed]\n" } ;
            last ;
        }


#-----------------------------------------------
#-----------------------------------------------
#  Restart at the beginning of the ballots, and
#  initialize the tally table.

        &reset_ballot_info_and_tally_table( ) ;


#-----------------------------------------------
#  Specify the normal influence of one vote per ballot.

        $global_ballot_influence_amount = 1.0 ;


#-----------------------------------------------
#  Convert the ballot information -- for the
#  remaining choices -- into preferences in a
#  new tally table.

        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[rep ranking, calculating popularity ranking for remaining choices]\n" } ;
        while ( $global_true )
        {
            $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
            if ( $global_ballot_info_repeat_count < 1 )
            {
                last ;
            }
            &add_preferences_to_tally_table ;
        }


#-----------------------------------------------
#  Based on the information in the tally table,
#  identify the overall popularity ranking.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, ranking remaining choices (case 3)]\n" } ;
        &calc_votefair_popularity_rank( ) ;


#-----------------------------------------------
#-----------------------------------------------
#  Repeat the loop that identifies each pair of
#  most-representative choices.

    }


#-----------------------------------------------
#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, done doing representation calculations]\n\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[rep ranking, exiting calc_votefair_representation_rank subroutine]\n\n" } ;
    return 1 ;

}




=head2 calc_votefair_party_rank

(Not exported, for internal use only.)

Calculates VoteFair party ranking results, as
described in the book "Ending The Hidden
Unfairness In U.S. Elections."
These results are used to determine the
maximum number of candidates each
political party is allowed to offer
in one election.  The number of allowed
candidates will vary according to the
election type, with less-important elections
not having any limits, and very important
elections, such as for U.S. President, allowing
two candidates each from the first-ranked and
second-ranked parties, one candidate each from
the next three or four parties, and no
candidates from any other parties.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_votefair_party_rank
#-----------------------------------------------
#-----------------------------------------------

sub calc_votefair_party_rank
{

    my $actual_choice ;
    my $adjusted_choice ;
    my $first_party_choice ;
    my $second_party_choice ;
    my $third_party_choice ;
    my $next_party_choice ;
    my $party_ranking_level ;
    my $count_of_parties_ranked ;
    my $non_ignored_vote_count ;
    my $choice_specific_ranking_level ;


#-----------------------------------------------
#  Also do other initialization.

    if ( $global_logging_info == $global_true ) { print LOGOUT "\n[party ranking, beginning VoteFair party ranking calculations]\n" } ;
    $global_ballot_influence_amount = 1.0 ;
    $count_of_parties_ranked = 0 ;
    $first_party_choice = 0 ;
    $second_party_choice = 0 ;
    $third_party_choice = 0 ;
    $party_ranking_level = 1 ;


#-----------------------------------------------
#  If there are no choices, return.

    if ( $global_full_choice_count < 1 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, Warning, no choices to rank for VoteFair party ranking]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Initialize the party ranking results to all
#  be unranked.

    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        $global_party_ranking_for_actual_choice[ $actual_choice ] = 0 ;
    }


#-----------------------------------------------
#  If there is only one choice, indicate that
#  the party is ranked in first place, and
#  then return.

    if ( $global_full_choice_count == 1 )
    {
        $global_party_ranking_for_actual_choice[ 1 ] = 1 ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, only one choice to rank, so done with party ranking]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Identify the first-ranked political party
#  as the most-popular party according to
#  VoteFair popularity ranking.
#  Instead of re-calculating, use the results
#  that were saved before VoteFair representation
#  ranking results were calculated.

    if ( $global_choice_count_at_full_top_popularity_ranking_level == 1 )
    {
        $party_ranking_level = 1 ;
        $first_party_choice = $global_actual_choice_at_top_of_full_popularity_ranking ;
        $global_party_ranking_for_actual_choice[ $first_party_choice ] = $party_ranking_level ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, most preferred, is choice " . $first_party_choice . "]\n" } ;
        $count_of_parties_ranked = 1 ;
        $party_ranking_level ++ ;


#-----------------------------------------------
#  If there is a two-way tie at this first level,
#  use these two choices as the top two political
#  parties (with neither being identified as more
#  popular than the other).  In this case the
#  next party ranking level will be 3.

    } elsif ( $global_choice_count_at_full_top_popularity_ranking_level == 2 )
    {
        $party_ranking_level = 1 ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, there is a two-way tie for first choice, so a tie-breaking ballot must be added]\n" } ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
            {
                if ( $first_party_choice == 0 )
                {
                    $first_party_choice = $actual_choice ;
                    $global_party_ranking_for_actual_choice[ $first_party_choice ] = $party_ranking_level ;
                } elsif ( $second_party_choice == 0 )
                {
                    $second_party_choice = $actual_choice ;
                    $global_party_ranking_for_actual_choice[ $second_party_choice ] = $party_ranking_level ;
                    last ;
                }
            }
        }
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, tie at top between " . $first_party_choice . " and " . $second_party_choice . "]\n" } ;
        $count_of_parties_ranked  = 2 ;
        $party_ranking_level = 3 ;


#-----------------------------------------------
#  If there is any other kind of tie at this
#  first level, indicate that a tie-breaking
#  vote must be introduced before the
#  next-ranked party can be identified, rank
#  the tied choices at level one, rank the
#  remaining choices at level three, and
#  exit this subroutine.

    } else
    {
        $party_ranking_level = 1 ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, there is a tie for first choice, so a tie-breaking ballot must be added]\n" } ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, tied choice: " . $actual_choice . "]\n" } ;
            } elsif ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = 3 ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, at (bottom) level 3 is choice " . $actual_choice . "]\n" } ;
            }
        }
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " first-place-tie-in-VoteFair-party-ranking-so-tie-breaking-vote-needed" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, exit multi_pop_tie, done with party ranking]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Specify that the second-ranked party is the
#  same as the second-ranked choice according to
#  VoteFair representation ranking (which has
#  already been calculated).

    if ( $count_of_parties_ranked == 1 )
    {
        if ( $global_choice_count_at_full_second_representation_level == 1 )
        {
            $party_ranking_level = 2 ;
            $second_party_choice = $global_actual_choice_at_second_representation_ranking ;
            $global_party_ranking_for_actual_choice[ $second_party_choice ] = 2 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, second-most preferred, is choice " . $second_party_choice . "]\n" } ;
            $count_of_parties_ranked ++ ;
            $party_ranking_level ++ ;


#-----------------------------------------------
#  If the VoteFair representation ranking
#  results had a tie in the
#  second-most-representative position,
#  indicate that a tie-breaking vote must be
#  introduced before the next-ranked party
#  can be identified, rank the tied choices at
#  level two, rank the remaining choices at
#  level three, and then exit this subroutine.

        } else
        {
            $party_ranking_level = 2 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, there is a tie for second choice, so a tie-breaking ballot must be added]\n" } ;
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, representation rank for choice " . $actual_choice . " is " . $global_full_representation_ranking_for_actual_choice[ $actual_choice ] . "]\n" } ;
                if ( $global_full_representation_ranking_for_actual_choice[ $actual_choice ] == 2 )
                {
                    $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                    $count_of_parties_ranked ++ ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, tied choice: " . $actual_choice . "]\n" } ;
                } elsif ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
                {
                    $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level + 1 ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, at bottom level " . $party_ranking_level . ", is choice " . $actual_choice . "]\n" } ;
                }
            }
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, exit rep_tie, done with party ranking]\n" } ;
            return ;
        }
    }


#-----------------------------------------------
#  If there are only two choices (total),
#  return.

    if ( $global_full_choice_count == 2 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, only two choices, so done]\n" } ;
        return ;


#-----------------------------------------------
#  If there are only three choices, rank the
#  remaining party at the next ranking level.

    } elsif ( $global_full_choice_count == 3 )
    {
        $party_ranking_level = 3 ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, party at third (and bottom) level is " . $actual_choice . "]\n" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, only three choices, so done with party ranking]\n" } ;
                return ;
            }
        }
    }


#-----------------------------------------------
#  Update which choices have not yet been party
#  ranked.

    &set_all_choices_as_used( ) ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_party_ranking_for_actual_choice[ $actual_choice ] > 0 )
        {
            $global_using_choice[ $actual_choice ] = $global_false ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, ignoring choice " . $actual_choice . "]" } ;
        }
    }


#-----------------------------------------------
#  For the third ranking, re-count the ballots
#  but ignore the ballots in which the first
#  choice -- even if tied (ranked at the same
#  level as another choice) -- is the
#  first-ranked or second-ranked party.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, now excluding ballots that rank choice " . $first_party_choice . " or " . $second_party_choice . " as most preferred, even if there is a tie on the ballot]\n" } ;
    &reset_ballot_info_and_tally_table( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "\n" } ;
    $non_ignored_vote_count = 0 ;
    while ( $global_true )
    {
        $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
        if ( $global_ballot_info_repeat_count < 1 )
        {
            last ;
        } else
        {
            if ( ( $global_ballot_preference_for_choice[ $first_party_choice ] > 1 ) && ( $global_ballot_preference_for_choice[ $second_party_choice ] > 1 ) )
            {
                &add_preferences_to_tally_table( ) ;
                $non_ignored_vote_count += $global_ballot_info_repeat_count ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n" } ;
            } else
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignored]\n" } ;
            }
        }
    }


#-----------------------------------------------
#  If at least one ballot meets this criteria,
#  identify the most popular party according to
#  the just-counted ballots (for the remaining
#  choices), and use that most-popular choice as
#  the third-ranked political party.

    if ( $non_ignored_vote_count >= 1 )
    {
        $global_ranking_type_being_calculated = "party" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, doing VoteFair popularity ranking as part of party ranking, but only with " . $non_ignored_vote_count . " ballots meeting criteria]\n" } ;
        &calc_votefair_popularity_rank( ) ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, ranking choices based on ballots meeting criteria]\n" } ;
        if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
        {
            $third_party_choice = $global_actual_choice_at_top_popularity_ranking_level ;
            $global_party_ranking_for_actual_choice[ $third_party_choice ] = $party_ranking_level ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, third-most preferred, is choice " . $third_party_choice . "]\n" } ;
            $count_of_parties_ranked ++ ;
            $party_ranking_level ++ ;


#-----------------------------------------------
#  If there is a tie -- based on using just the
#  ballots that meet the indicated criteria --
#  then indicate a tie among those parties,
#  then rank the remaining parties at the next
#  level, and then exit the subroutine.

        } else
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, there is a tie for third choice, so a tie-breaking ballot must be added]\n" } ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
                {
                    $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                    $count_of_parties_ranked ++ ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, tied choice: " . $actual_choice . "]\n" } ;
                } elsif ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
                {
                    $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level + 1 ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, at bottom level " . $party_ranking_level . ", is choice " . $actual_choice . "]\n" } ;
                }
            }
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, exit some_ballots_tie, done with party ranking]\n" } ;
            return ;
        }
    } else
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, zero ballots meet criteria]\n" } ;
    }


#-----------------------------------------------
#  If there are no choices remaining, exit the
#  subroutine.

    if ( $global_full_choice_count - $count_of_parties_ranked == 0 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, all choices ranked, so done with party ranking]\n" } ;
        return ;


#-----------------------------------------------
#  If there is only one choice remaining, rank
#  it at the bottom, and exit the subroutine.

    } elsif ( $global_full_choice_count - $count_of_parties_ranked == 1 )
    {
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, final party choice is " . $actual_choice . "]\n" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, no more choices, so done with party ranking]\n" } ;
                return ;
            }
        }
    }


#-----------------------------------------------
#  Update which choices have not yet been party
#  ranked.

    &set_all_choices_as_used( ) ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_party_ranking_for_actual_choice[ $actual_choice ] > 0 )
        {
            $global_using_choice[ $actual_choice ] = $global_false ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, ignoring choice " . $actual_choice . "]\n" } ;
        }
    }


#-----------------------------------------------
#  Specify the fourth (or possibly third)
#  ranking to be the first choice -- among the
#  remaining choices, using all the ballots --
#  according to VoteFair popularity ranking.

    &reset_ballot_info_and_tally_table( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, now considering all ballots]\n" } ;
    while ( $global_true )
    {
        $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
        if ( $global_ballot_info_repeat_count < 1 )
        {
            last ;
        } else
        {
            &add_preferences_to_tally_table( ) ;
        }
    }
    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, using popularity ranking to identify next party choice]\n" } ;
    &calc_votefair_popularity_rank( ) ;
    if ( $global_choice_count_at_top_popularity_ranking_level == 1 )
    {
        $next_party_choice = $global_actual_choice_at_top_popularity_ranking_level ;
        $global_party_ranking_for_actual_choice[ $next_party_choice ] = $party_ranking_level ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, next most preferred, is choice " . $next_party_choice . "]\n" } ;
        $count_of_parties_ranked ++ ;
        $party_ranking_level ++ ;


#-----------------------------------------------
#  If there was a tie, indicate which parties
#  (choices) are tied at this level, and rank
#  the remaining parties at the bottom, then
#  exit the subroutine.

    } else
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, there is a tie for first choice, so a tie-breaking ballot must be added]\n" } ;
        for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
        {
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, tied choice: " . $actual_choice . "]\n" } ;
            } elsif ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level + 1 ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, at bottom level " . $party_ranking_level . ", is choice " . $actual_choice . "]\n" } ;
            }
        }
        if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, exit post_rep_pop_tie, done with party ranking]\n" } ;
        return ;
    }


#-----------------------------------------------
#  If there is only one choice remaining,
#  identify it as the final choice, and then
#  exit the subroutine.

    if ( $global_full_choice_count - $count_of_parties_ranked == 1 )
    {
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
            {
                $global_party_ranking_for_actual_choice[ $actual_choice ] = $party_ranking_level ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, final party choice is " . $actual_choice . "]\n" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, exit post_rep_pop_last, no more choices, so done]\n" } ;
                return ;
            }
        }
    }


#-----------------------------------------------
#  Use VoteFair representation ranking to
#  rank the remaining parties.

    $global_ranking_type_being_calculated = "party-representation" ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, transition from party ranking to representation ranking calculations]\n" } ;
    $global_representation_levels_requested = $global_full_choice_count - $count_of_parties_ranked ;
    &calc_votefair_representation_rank( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, transition back to party ranking from representation ranking calculations]\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, current ranking level is " . $party_ranking_level . "]\n" } ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_party_ranking_for_actual_choice[ $actual_choice ] == 0 )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, choice " . $actual_choice . " is at rep-rank level " . $global_representation_ranking_for_actual_choice[ $actual_choice ] . "]\n" } ;
            $choice_specific_ranking_level = $party_ranking_level - 2 + $global_representation_ranking_for_actual_choice[ $actual_choice ] ;
            $global_party_ranking_for_actual_choice[ $actual_choice ] = $choice_specific_ranking_level ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, at party-ranked level " . $choice_specific_ranking_level . " is choice " . $actual_choice . "]\n" } ;
        }
    }


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[party ranking, done with party ranking]\n" } ;
    return ;

}




=head2 calc_votefair_choice_specific_pairwise_score_popularity_rank

(Not exported, for internal use only.)

Calculates VoteFair choice-specific pairwise-score
(CSPS) popularity ranking results.

This kind of ranking is useful for estimating
the overall ranking when there are many choices
(such as hundreds of choices) and fast results
are desired.   It is also used to estimate the
ranking before doing the VoteFair
insertion-sort popularity ranking calculations.
(If access to a computer is not available, this
CSPS method can be done using pen and paper and
a calculator.)

Example:

(A concise description follows this
example.  The description is easier to
understand after you have read this example.)

Consider an election (or survey) in which
there are five choices: A, B, C, D, E, and the
final ranking order is this alphabetical
order.

In this example the notation A>B
refers to how many voters pairwise prefer
choice A over choice B, and the notation
B>A refers to how many voters pairwise
prefer choice B over choice A.  This
notation always uses the "greater-than" symbol
">", and never uses the "less-than" symbol
"<".

At the beginning of this ranking example,
suppose that the choices are arranged in the
order C, E, A, D, B.  The pairwise counts
for this arrangement are shown in this pairwise
matrix.

      |       |       |       |       |       |
      |   C   |   E   |   A   |   D   |   B   |
      |       |       |       |       |       |
 -----+-------+-------+-------+-------+-------+
      | \     |       |       |       |       |
  C   |   \   |  C>E  |  C>A  |  C>D  |  C>B  |
      |     \ |       |       |       |       |
 -----+-------+-------+-------+-------+-------+
      |       | \     |       |       |       |
  E   |  E>C  |   \   |  E>A  |  E>D  |  E>B  |
      |       |     \ |       |       |       |
 -----+-------+-------+-------+-------+-------+
      |       |       | \     |       |       |
  A   |  A>C  |  A>E  |   \   |  A>D  |  A>B  |
      |       |       |     \ |       |       |
 -----+-------+-------+-------+-------+-------+
      |       |       |       | \     |       |
  D   |  D>C  |  D>E  |  D>A  |   \   |  D>B  |
      |       |       |       |     \ |       |
 -----+-------+-------+-------+-------+-------+
      |       |       |       |       | \     |
  B   |  B>C  |  B>E  |  B>A  |  B>D  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

The diagonal line passes through empty
cells.  These cells are empty because they
would represent a choice's comparison with
itself, such as A>A.

The goal of these calculations is to change
the sequence so that the largest pairwise
counts move into the upper-right triangular
area, leaving the smallest pairwise counts in
the lower-left triangular area.  (This is
similar to the goal of VoteFair popularity
ranking.)

The first step is to calculate
choice-specific scores, with each choice having
a row score and a column
score.  For choice A, its row score
equals the sum of the pairwise counts in the
row labelled A, which equals A>B +
A>C + A>D + A>E.  The column
score for choice A is the sum of the
pairwise counts in the column labeled A,
which equals B>A + C>A + D>A +
E>A.  The row scores and column scores
for choices B, C, D, and E are calculated
similarly.

Next, all the row scores are compared to
determine which choice has the largest row
score.  In this example that score
would be the row score for choice A (because it
is first in alphabetical order).
Therefore choice A is moved into first
place.  The other choices remain in the
same order.  The resulting sequence is A,
C, E, D, B.  Here is the pairwise matrix
for the new sequence.  The pairwise counts
for the ranked choice (A) are surrounded by
asterisks:

      |       |       |       |       |       |
      |   A   |   C   |   E   |   D   |   B   |
      |       |       |       |       |       |
 -----*****************************************
      * \     |       |       |       |       *
  A   *   \   |  A>C  |  A>E  |  A>D  |  A>B  *
      *     \ |       |       |       |       *
 -----*-------*********************************
      *       * \     |       |       |       |
  C   *  C>A  *   \   |  C>E  |  C>D  |  C>B  |
      *       *     \ |       |       |       |
 -----*-------*-------+-------+-------+-------+
      *       *       | \     |       |       |
  E   *  E>A  *  E>C  |   \   |  E>D  |  E>B  |
      *       *       |     \ |       |       |
 -----*-------*-------+-------+-------+-------+
      *       *       |       | \     |       |
  D   *  D>A  *  D>C  |  D>E  |   \   |  D>B  |
      *       *       |       |     \ |       |
 -----*-------*-------+-------+-------+-------+
      *       *       |       |       | \     |
  B   *  B>A  *  B>C  |  B>E  |  B>D  |   \   |
      *       *       |       |       |     \ |
 -----*********-------+-------+-------+-------+

The row scores and column scores for the
remaining (unranked) choices are adjusted to
remove the pairwise counts that involve the
just-ranked choice (A).  The removed
pairwise counts are the ones surrounded by
asterisks.  Specifically, after
subtracting B>A, the row score for choice B
becomes B>C + B>D + B>E, and after
subtracting A>B, the column score for choice
B becomes C>B + D>B + E>B.

From among the remaining row scores the
highest score is found.  At this point
let's assume that both choice B and choice C
have the same highest row score.

In the case of a row-score tie, the
choice with the smallest column score --
from among the choices that have the same
largest row score -- is ranked
next.  This would be choice B.
Therefore, choice B is moved to the sequence
position just after choice A.  The
resulting sequence is A, B, C, E, D.
Below is the pairwise matrix for the new
sequence.  The pairwise counts for the
ranked choices are surrounded by asterisks.

      |       |       |       |       |       |
      |   A   |   B   |   C   |   E   |   D   |
      |       |       |       |       |       |
 -----*****************************************
      * \     |       |       |       |       *
  A   *   \   |  A>B  |  A>C  |  A>E  |  A>D  *
      *     \ |       |       |       |       *
 -----*-------+-------+-------+-------+-------*
      *       | \     |       |       |       *
  B   *  B>A  |   \   |  B>C  |  B>E  |  B>D  *
      *       |     \ |       |       |       *
 -----*-------+--------************************
      *       |       * \     |       |       |
  C   *  C>A  |  C>B  *   \   |  C>E  |  C>D  |
      *       |       *     \ |       |       |
 -----*-------+-------*-------+-------+-------+
      *       |       *       | \     |       |
  E   *  E>A  |  E>B  *  E>C  |   \   |  E>D  |
      *       |       *       |     \ |       |
 -----*-------+-------*-------+-------+-------+
      *       |       *       |       | \     |
  D   *  D>A  |  D>B  *  D>C  |  D>E  |   \   |
      *       |       *       |       |     \ |
 -----*****************-------+-------+-------+

The same ranking process is repeated.
The next choice to be ranked would be choice
C.   It would have the highest row score
-- and the smallest column score if there is a
row-score tie.   So choice C would be
identifed as the next choice in the ranked
sequence.   After that, choice D would
have the highest row score, and would be ranked
next.  Finally the only remaining choice,
choice E, would be ranked at the last (lowest)
position.

Here is the final pairwise matrix.

      |       |       |       |       |       |
      |   A   |   B   |   C   |   D   |   E   |
      |       |       |       |       |       |
 -----*****************************************
      * \     |       |       |       |       *
  A   *   \   |  A>B  |  A>C  |  A>D  |  A>E  *
      *     \ |       |       |       |       *
 -----*-------+-------+-------+-------+-------*
      *       | \     |       |       |       *
  B   *  B>A  |   \   |  B>C  |  B>D  |  B>E  *
      *       |     \ |       |       |       *
 -----*-------+-------+-------+-------+-------*
      *       |       | \     |       |       *
  C   *  C>A  |  C>B  |   \   |  C>D  |  C>E  *
      *       |       |     \ |       |       *
 -----*-------+-------+-------+-------+-------*
      *       |       |       | \     |       *
  D   *  D>A  |  D>B  |  D>C  |   \   |  D>E  *
      *       |       |       |     \ |       *
 -----*-------+-------+-------+-------+-------*
      *       |       |       |       | \     *
  E   *  E>A  |  E>B  |  E>C  |  E>D  |   \   *
      *       |       |       |       |     \ *
 -----*****************************************

The choices are now fully ranked according
to the Choice-Specific Pairwise-Count
method.

If only a single winner is needed, the
first-ranked choice should not necessarily be
selected as the winner.  Instead, the
pairwise counts should be checked for a
possible Condorcet winner, which may be second
or third in the CSPS ranking result.

Concise description of the calculation method:

A row score and a column score
is calculated for each choice.  The
row score is the sum of the pairwise counts in
which the specified choice is preferred over
each of the other choices.  The column
score is the sum of the pairwise counts in
which each other choice is preferred over the
specified choice.

For the choices that have not yet been
ranked, all the row scores are compared to find
the highest row score.  The choice
that has the highest row score is moved to the
most-popular or next-most popular position in
the ranking results.

If more than one choice is
tied with the highest row score, the
choice with the smallest column score is
chosen.  If more than one choice has the
same row score and the same column score, the
choices are regarded as tied.

After each choice has been ranked, the
scores for the remaining (unranked) choices are
adjusted by subtracting from all the
remaining scores the pairwise counts that
involve the just-ranked choice.

The process of ranking each choice and
adjusting the remaining scores is
repeated until only one choice remains,
and it is ranked in the bottom (least-popular)
position.

(This description of the VoteFair choice-specific
pairwise-score method was copied from
www.VoteFair.org with permission.)

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_votefair_choice_specific_pairwise_score_popularity_rank
#-----------------------------------------------
#-----------------------------------------------

sub calc_votefair_choice_specific_pairwise_score_popularity_rank
{

    my $adjusted_choice ;
    my $adjusted_first_choice ;
    my $adjusted_second_choice ;
    my $adjusted_choice_being_displaced ;
    my $adjusted_choice_with_largest_score ;
    my $adjusted_choice_not_yet_sorted ;
    my $actual_choice ;
    my $actual_first_choice ;
    my $actual_second_choice ;
    my $actual_choice_with_largest_score ;
    my $actual_choice_not_yet_sorted ;
    my $actual_choice_being_displaced ;
    my $sequence_position ;
    my $new_position_of_choice_being_moved ;
    my $previous_position_of_choice_being_moved ;
    my $sequence_position_of_choice_not_yet_sorted ;
    my $ranking_level ;
    my $main_loop_count ;
    my $pair_counter ;
    my $tally_first_over_second ;
    my $tally_second_over_first ;
    my $row_score ;
    my $column_score ;
    my $largest_row_score ;
    my $smallest_column_score ;
    my $largest_column_score ;
    my $row_score_reduction ;
    my $column_score_reduction ;
    my $count_of_choices_sorted ;
    my $true_or_false_log_details ;
    my $count_of_tied_scores ;
    my $difference_between_tallies ;
    my $largest_positive_difference ;
    my $list_pointer ;
    my $tie_count_limit ;
    my $first_pointer ;
    my $second_pointer ;

    my @row_score_for_adjusted_choice ;
    my @column_score_for_adjusted_choice ;
    my @position_in_sequence_for_adjusted_choice ;
    my @adjusted_choice_in_rank_sequence_position ;
    my @adjusted_choice_at_tie_count ;


#-----------------------------------------------
#  Hide or show the details in the log file.

    $true_or_false_log_details = $global_true ;
    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[choice-score, beginning calc_votefair_choice_specific_pairwise_score_popularity_rank subroutine]\n\n" ;
        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "[choice-score, details shown (change flag value to hide details)]\n" ;
        } else
        {
            print LOGOUT "[choice-score, details hidden (change flag value to view details)]\n" ;
        }
    }


#-----------------------------------------------
#  Initialize the scale value for the logged
#  pairwise counts.

    $global_scale_for_logged_pairwise_counts = 1.0 ;


#-----------------------------------------------
#  Initialize the results in case of an early
#  exit.

    for ( $adjusted_choice = 1 ; $adjusted_choice < $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] = 0 ;
    }


#-----------------------------------------------
#  If there are not at least two choices,
#  indicate an error.

    if ( $global_adjusted_choice_count < 2 )
    {
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, ERROR: number of (adjusted) choices is less than two]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Initialize the choice sequence.  Just use
#  numerical order.  Also initialize other
#  values.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $sequence_position = $adjusted_choice ;
        $adjusted_choice_in_rank_sequence_position[ $sequence_position ] = $adjusted_choice ;
        $position_in_sequence_for_adjusted_choice[ $adjusted_choice ] = $sequence_position ;
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] = 0 ;
    }
    $adjusted_choice_with_largest_score = 0 ;
    $global_top_choice_according_to_choice_specific_scores = 0 ;
    $global_sequence_score_using_choice_score_method = 0 ;


#-----------------------------------------------
#  Initialize the value that keeps track of how many
#  choices are in the group of highest-ranked
#  choices.

    $count_of_choices_sorted = 0 ;


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.

    if ( $true_or_false_log_details == $global_true )
    {
        for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
        {
            $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $sequence_position ] ;
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
        }
        print LOGOUT "[choice-score, initial ranking:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  Sum the tally counts in each column and each
#  row.
#  (The position of each choice in the
#  array/matrix does not affect these sums.)
#  The "pair counter" is an index that accesses
#  each combination of (adjusted) choice
#  numbers, where the first choice number is
#  less than the second choice number.
#  As a visual representation this means that
#  the pairwise tallies (counts) for the
#  upper-right diagonal and the lower-left
#  diagonal (triangular areas of the pairwise
#  matrix) are stored in the
#  global_tally_first_over_second_in_pair
#  and
#  global_tally_second_over_first_in_pair
#  lists (not necessarily respectively).

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $row_score_for_adjusted_choice[ $adjusted_choice ] = 0 ;
        $column_score_for_adjusted_choice[ $adjusted_choice ] = 0 ;
    }
    for ( $pair_counter = 1 ; $pair_counter <= $global_pair_counter_maximum ; $pair_counter ++ )
    {
        $adjusted_first_choice = $global_adjusted_first_choice_number_in_pair[ $pair_counter ] ;
        $adjusted_second_choice = $global_adjusted_second_choice_number_in_pair[ $pair_counter ] ;
        $row_score_for_adjusted_choice[ $adjusted_first_choice ] += $global_tally_first_over_second_in_pair[ $pair_counter ] ;
        $row_score_for_adjusted_choice[ $adjusted_second_choice ] += $global_tally_second_over_first_in_pair[ $pair_counter ] ;
        $column_score_for_adjusted_choice[ $adjusted_first_choice ] += $global_tally_second_over_first_in_pair[ $pair_counter ] ;
        $column_score_for_adjusted_choice[ $adjusted_second_choice ] += $global_tally_first_over_second_in_pair[ $pair_counter ] ;
        $actual_first_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
        $actual_second_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, for first choice " . $actual_first_choice . " and second choice " . $actual_second_choice . " , tally first over second is " . $global_tally_first_over_second_in_pair[ $pair_counter ] . " , and tally second over first is " . $global_tally_second_over_first_in_pair[ $pair_counter ] . "]\n" } ;
    }


#-----------------------------------------------
#  Display (in the log file) the current column
#  and row scores.  Also save the largest
#  column score.

    $largest_column_score = 0 ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, current column and row scores:]\n" } ;
    for ( $sequence_position = $count_of_choices_sorted + 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
    {
        $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $sequence_position ] ;
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  for choice " . $actual_choice . " row score is " . $row_score_for_adjusted_choice[ $adjusted_choice ] . " and column score is " . $column_score_for_adjusted_choice[ $adjusted_choice ] . "]\n" } ;
        if ( $column_score_for_adjusted_choice[ $adjusted_choice ] > $largest_column_score )
        {
            $largest_column_score = $column_score_for_adjusted_choice[ $adjusted_choice ] ;
        }
    }
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "\n" } ;


#-----------------------------------------------
#  Begin a loop that identifies which choice
#  to move into the first/next-highest or
#  last/lowest sequence position.
#  The loop is exited in the middle (not here).

    $main_loop_count = 0 ;
    while ( $main_loop_count < $global_adjusted_choice_count + 10 )
    {
        $main_loop_count ++ ;


#-----------------------------------------------
#  Prevent an endless loop.

        if ( $main_loop_count > 10000 )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, loop counter has exceeded limit, probably because the choice count (" . $global_full_choice_count . ") is so large, so exiting choice-score rank]" } ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] = 0 ;
            }
            last ;
        }


#-----------------------------------------------
#  If there is only one choice remaining, rank
#  it at the middle, between the two sorted lists.

        if ( $count_of_choices_sorted + 1 == $global_adjusted_choice_count )
        {
            $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $count_of_choices_sorted + 1 ] ;
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] = $count_of_choices_sorted + 1 ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, no choices unsorted, so done sorting]\n" } ;
            last ;
        }


#-----------------------------------------------
#  If all the choices have been sorted, exit
#  the loop.

        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, most-popular sorted list length is " . $count_of_choices_sorted . "]\n" } ;
        if ( $count_of_choices_sorted >= $global_adjusted_choice_count )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, no choices unsorted, so done sorting]\n" } ;
            last ;
        }


#-----------------------------------------------
#  Identify which choice has the largest
#  choice-specific score-based row score.
#  If there is a tie between row scores,
#  choose the choice with the smallest
#  column score.  If there are multiple tied
#  choices, save those choice numbers in a list.

        $largest_row_score = -1 ;
        $smallest_column_score = $largest_column_score ;
        $adjusted_choice_with_largest_score = 0 ;
        $count_of_tied_scores = 0 ;
        for ( $sequence_position = $count_of_choices_sorted + 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
        {
            $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $sequence_position ] ;
            $row_score = $row_score_for_adjusted_choice[ $adjusted_choice ] ;
            $column_score = $column_score_for_adjusted_choice[ $adjusted_choice ] ;
            if ( ( $row_score > $largest_row_score ) || ( ( $row_score == $largest_row_score ) && ( $column_score < $smallest_column_score ) ) )
            {
                $adjusted_choice_with_largest_score = $adjusted_choice ;
                $largest_row_score = $row_score ;
                $smallest_column_score = $column_score ;
                $count_of_tied_scores = 1 ;
                $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_choice_with_largest_score ;
                $actual_choice_with_largest_score = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_with_largest_score ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, starting new tied list, adding to tied list, choice " . $actual_choice_with_largest_score . " (row score is " . $largest_row_score . " and column score is " . $smallest_column_score . ")]\n" } ;
            } elsif ( $row_score == $largest_row_score )
            {
                $adjusted_choice_with_largest_score = $adjusted_choice ;
                $count_of_tied_scores ++ ;
                $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_choice_with_largest_score ;
                $actual_choice_with_largest_score = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_with_largest_score ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, adding to tied list, choice " . $actual_choice_with_largest_score . " (row score is " . $largest_row_score . " and column score is " . $smallest_column_score . ")]\n" } ;
            }
        }


#-----------------------------------------------
#  Specify the limit for the number of tied
#  choices for which it is worth the time to
#  see if the choices with the same highest scores
#  can be sorted.  This number should NOT
#  exceed about 5 at the most.  If it is one,
#  the lowest-numbered choice will be sorted
#  into the next position.

        $tie_count_limit = 1 ;
        if ( $tie_count_limit < 1 )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[ERROR: choice-score, tie_count_limit (" . $count_of_tied_scores . ") is too small]\n" } ;
            die "value of tie_count_limit is too small" ;
        }


#-----------------------------------------------
#  If only one choice has the highest score,
#  save it, and skip over the next sections
#  that deal with ties.
#  If this choice is the highest-ranked choice,
#  make it available for possible tie-breaking
#  use in the insertion-sort calculations.

        if ( $count_of_tied_scores == 1 )
        {
            $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_choice_with_largest_score ;
            $actual_choice_with_largest_score = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_with_largest_score ] ;
            if ( $count_of_choices_sorted == 0 )
            {
                $global_top_choice_according_to_choice_specific_scores = $actual_choice_with_largest_score ;
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, no tie, only choice " . $actual_choice_with_largest_score . "]\n" } ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice_with_largest_score . " has largest row score " . $largest_row_score . " (and a possible tie-breaking column score of " . $smallest_column_score . ")]\n" } ;


#-----------------------------------------------
#  If there are too many tied choices, pick the
#  first one as the next choice to sort.
#  Keep in mind that this algorithm estimates
#  the ranking, and depends on the
#  insertion-sort algorithm to refine the exact
#  ranking.  Also, the method of resolving a
#  tie (below) is not always correct.

        } elsif ( $count_of_tied_scores > $tie_count_limit )
        {
            $count_of_tied_scores = 1 ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, there is a tie among " . $count_of_tied_scores . " choices, which is too many, so only choice " . $adjusted_choice_at_tie_count[ $count_of_tied_scores ] . " is picked]\n" } ;


#-----------------------------------------------
#  If more than one choice has the same highest
#  row score, without a tie-breaking column score,
#  begin to identify which
#  choice has the best (highest) pairwise
#  comparison with each of the other tied
#  choices.

        } else
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, tie involving " . $count_of_tied_scores . " choices]\n" } ;


#-----------------------------------------------
#  For each pair of tied choices, calculate the
#  difference between the relevant pairwise
#  counts (tally numbers), and identify the
#  largest such difference, and choose to sort
#  the choice that is associated with the
#  largest positive difference.

            $largest_positive_difference = 0 ;
            for ( $first_pointer = 1 ; $first_pointer < $count_of_tied_scores ; $first_pointer ++ )
            {
                $adjusted_first_choice = $adjusted_choice_at_tie_count[ $first_pointer ] ;
                $actual_first_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, first choice is " . $actual_first_choice . "]\n" } ;
                for ( $second_pointer = $first_pointer + 1 ; $second_pointer <= $count_of_tied_scores ; $second_pointer ++ )
                {
                    $adjusted_second_choice = $adjusted_choice_at_tie_count[ $second_pointer ] ;
                    $actual_second_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, second choice is " . $actual_second_choice . "]\n" } ;
                    $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_first_choice ] + $adjusted_second_choice ;
                    $tally_first_over_second = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                    $tally_second_over_first = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, first tied choice " . $actual_first_choice . " and second tied choice " . $actual_second_choice . " have tallies " . $tally_first_over_second . " and " . $tally_second_over_first . "]\n" } ;
                    $difference_between_tallies = $tally_first_over_second - $tally_second_over_first ;
                    if ( $difference_between_tallies > 0 )
                    {
                        if ( $difference_between_tallies > $largest_positive_difference )
                        {
                            $largest_positive_difference = $difference_between_tallies ;
                            $count_of_tied_scores = 1 ;
                            $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_first_choice ;
                            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice . " is first choice chosen so far]\n" } ;
                        } elsif ( $difference_between_tallies == $largest_positive_difference )
                        {
                            $count_of_tied_scores ++ ;
                            $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_first_choice ;
                            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice . " is added to list as chosen so far]\n" } ;
                        }
                    } elsif ( $difference_between_tallies < 0 )
                    {
                        if ( ( - $difference_between_tallies ) > $largest_positive_difference )
                        {
                            $largest_positive_difference = - $difference_between_tallies ;
                            $count_of_tied_scores = 1 ;
                            $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_second_choice ;
                            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice . " is first choice chosen so far]\n" } ;
                        } elsif ( ( - $difference_between_tallies ) == $largest_positive_difference )
                        {
                            $count_of_tied_scores ++ ;
                            $largest_positive_difference = - $difference_between_tallies ;
                            $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_second_choice ;
                            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice . " is added to list as chosen so far]\n" } ;
                        }
                    } else
                    {
                        $largest_positive_difference = 0 ;
                        $count_of_tied_scores ++ ;
                        $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_first_choice ;
                        $count_of_tied_scores ++ ;
                        $adjusted_choice_at_tie_count[ $count_of_tied_scores ] = $adjusted_second_choice ;
                        $actual_first_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
                        $actual_second_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, tie at zero, so both choices " . $actual_first_choice . " and " . $actual_second_choice . " are chosen so far]\n" } ;
                    }
                    $main_loop_count ++ ;
                    if ( $main_loop_count > 10000 )
                    {
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, loop counter has exceeded limit while handling tied scores, which means the value of tie_count_limit (which is " . $tie_count_limit . ") is too large ]" } ;
                        last ;
                    }
                }
            }


#-----------------------------------------------
#  Terminate the branches that handle situations
#  in which more than one choice has the same highest
#  row score (and the lowest column score if there
#  is a tie in the row scores).

            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, will repeat loop if another tied choice]\n" } ;
        }


#-----------------------------------------------
#  Specify the ranking level.

        $ranking_level = $count_of_choices_sorted + 1 ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, ranking level is " . $ranking_level . "]\n" } ;


#-----------------------------------------------
#  Begin a loop that repeats only if there are
#  multiple choices that are tied at the same
#  ranking level, in which case the loop
#  repeats for each such choice.  Otherwise this
#  loop is executed only once.

        for ( $list_pointer = 1 ; $list_pointer <= $count_of_tied_scores ; $list_pointer ++ )
        {
            $adjusted_choice_with_largest_score = $adjusted_choice_at_tie_count[ $list_pointer ] ;
            $actual_choice_with_largest_score = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_with_largest_score ] ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, next-ranked choice is " . $actual_choice_with_largest_score . "]\n" } ;


#-----------------------------------------------
#  Rank the specified choice at the current ranking
#  level.

            $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice_with_largest_score ] = $ranking_level ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice_with_largest_score . " ranked at level " . $ranking_level . "]\n" } ;


#-----------------------------------------------
#  Move the specified choice to the bottom of
#  the highest-ranked choices.
#  To make room in the sequence, move
#  whichever choice is already there.
#  If the choice is already in the correct
#  row and column, skip ahead.

            $count_of_choices_sorted ++ ;
            $new_position_of_choice_being_moved = $count_of_choices_sorted ;
            $previous_position_of_choice_being_moved = $position_in_sequence_for_adjusted_choice[ $adjusted_choice_with_largest_score ] ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, moving choice " . $actual_choice_with_largest_score . " from position " . $previous_position_of_choice_being_moved . " to position " . $new_position_of_choice_being_moved . "]\n" } ;
            if ( $new_position_of_choice_being_moved != $previous_position_of_choice_being_moved )
            {
                $adjusted_choice_being_displaced = $adjusted_choice_in_rank_sequence_position[ $new_position_of_choice_being_moved ] ;
                $actual_choice_being_displaced = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_being_displaced ] ;

                $adjusted_choice_in_rank_sequence_position[ $new_position_of_choice_being_moved ] = $adjusted_choice_with_largest_score ;

                $position_in_sequence_for_adjusted_choice[ $adjusted_choice_with_largest_score ] = $new_position_of_choice_being_moved ;

                $adjusted_choice_in_rank_sequence_position[ $previous_position_of_choice_being_moved ] = $adjusted_choice_being_displaced ;

                $position_in_sequence_for_adjusted_choice[ $adjusted_choice_being_displaced ] = $previous_position_of_choice_being_moved ;

            } else
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, no move needed]" . "\n" } ;

            }

            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "\n" } ;


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.

            if ( $true_or_false_log_details == $global_true )
            {
                for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
                {
                    $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $sequence_position ] ;
                    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
                }
                print LOGOUT "[choice-score, intermediate ranking:]\n" ;
                &internal_view_matrix( ) ;
            }
            $global_sequence_score_using_choice_score_method = $global_sequence_score ;


#-----------------------------------------------
#  Skip ahead if the last choice has been sorted.

            if ( $count_of_choices_sorted < $global_adjusted_choice_count )
            {


#-----------------------------------------------
#  Reduce each row score and each column score by
#  the pairwise counts that are associated with
#  the choice that was just sorted.  This
#  updates the row and column scores to apply to
#  only the unsorted choices.
#  In case the number of choices is large (such
#  as hundreds of choices), access the tally
#  counts efficiently (and without creating an
#  extra array that converts from choice-number
#  combinations into pair numbers).

                for ( $sequence_position_of_choice_not_yet_sorted = $count_of_choices_sorted + 1 ; $sequence_position_of_choice_not_yet_sorted <= $global_adjusted_choice_count ; $sequence_position_of_choice_not_yet_sorted ++ )
                {
                    $adjusted_choice_not_yet_sorted = $adjusted_choice_in_rank_sequence_position[ $sequence_position_of_choice_not_yet_sorted ] ;
                    if ( $adjusted_choice_with_largest_score < $adjusted_choice_not_yet_sorted )
                    {
                        $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_choice_with_largest_score ] + $adjusted_choice_not_yet_sorted ;
                        $column_score_reduction = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                        $row_score_reduction = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                    } else
                    {
                        $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_choice_not_yet_sorted ] + $adjusted_choice_with_largest_score ;
                        $row_score_reduction = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                        $column_score_reduction = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                    }
                    $actual_choice_not_yet_sorted = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_not_yet_sorted ] ;
                    $row_score_for_adjusted_choice[ $adjusted_choice_not_yet_sorted ] -= $row_score_reduction ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, for choice " . $actual_choice_not_yet_sorted . " row score reduced by " . $row_score_reduction . "]\n" } ;
                    $column_score_for_adjusted_choice[ $adjusted_choice_not_yet_sorted ] -= $column_score_reduction ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, for choice " . $actual_choice_not_yet_sorted . " column score reduced by " . $column_score_reduction . "]\n" } ;
                }


#-----------------------------------------------
#  Display the updated row and column scores.

                if ( $true_or_false_log_details == $global_true )
                {
                    print LOGOUT "[choice-score, current row and column scores:]\n" ;
                    for ( $sequence_position = $count_of_choices_sorted + 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
                    {
                        $adjusted_choice = $adjusted_choice_in_rank_sequence_position[ $sequence_position ] ;
                        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                        print LOGOUT "[  for choice " . $actual_choice . " row score is " . $row_score_for_adjusted_choice[ $adjusted_choice ] . " and column score is " . $column_score_for_adjusted_choice[ $adjusted_choice ] . "]\n" ;
                    }
                    print LOGOUT "\n" ;
                }


#-----------------------------------------------
#  Finish skipping ahead if the last choice has
#  been sorted.

            }


#-----------------------------------------------
#  Repeat the loop that is repeated only if there
#  is a tie.

        }


#-----------------------------------------------
#  Repeat the loop that identifies which choice to
#  sort next.

    }


#-----------------------------------------------
#  Normalize the results.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] = $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] ;
    }
    &normalize_ranking( ) ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, final normalized ranking levels]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $ranking_level = $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] ;
        $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] = $ranking_level ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, choice " . $actual_choice . " at normalized rank level " . $ranking_level . "]\n" } ;
    }


#-----------------------------------------------
#  Log the calculated ranking levels.

    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice-score, final results:]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " is at ranking level " . $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] . "]\n" } ;
    }


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-score, exiting calc_votefair_choice_specific_pairwise_score_popularity_rank subroutine]\n\n" } ;
    return ;

}



=head2 calc_votefair_insertion_sort_popularity_rank

(Not exported, for internal use only.)

Calculates VoteFair popularity ranking results
using the "insertion-sort" sorting algorithm.

VoteFair popularity ranking is described in
Wikipedia, and is mathematically equivalent
to the Condorcet-Kemeny method.  The
following comments explain the algorithm used
here, which quickly calculates the ranking
results.  This explanation is important
because some academic sources claim that
the computations cannot be done quickly if
there is a large number of choices being
ranked.

Although the goal of VoteFair popularity
ranking is to find the sequence that has the
highest sequence score, the scores themselves
do not need to be calculated.  This
concept is similar to not needing to know the
elevation of every point in a region in order
to know that a specific mountain peak  is the
highest elevation in that region.  By not
calculating all the sequence scores, the
calculation time can be greatly reduced
compared to the method that calculates all the
sequence scores.

The algorithm described here assumes that
the choices already have been pre-sorted using
the Choice-Specific Pairwise-Score (CSPS)
algorithm.  That algorithm is part of this
full calculation algorithm.

The full algorithm repeatedly uses a
variation of the "insertion-sort" sorting
algorithm, so that algorithm is described
first.

Insertion-sort algorithm applied to finding
maximum sequence score:

This explanation clarifies how the
well-known insertion-sort algorithm is applied
to VoteFair popularity ranking in a way that
greatly reduces the number of calculations
needed to find maximum sequence scores.
(This  method is just part of the full
algorithm, which is explained in the next
section.)

Consider an example in which there are five
choices named A, B, C, D, and E, with a final
sort order that matches this alphabetical
order.

Notation: The notation A>B refers to how
many voters pairwise prefer choice A over
choice B, and the notation B>A refers to how
many voters pairwise prefer choice B over
choice A.  This notation always uses the
"greater-than" symbol ">", and never uses
the "less-than" symbol "<".

At an intermediate stage in this sorting
example, suppose that the choices A, C, and E
have been sorted -- into this correct
order -- and choice B is about to be
sorted, and choice D remains unsorted.
The pairwise counts for this arrangement are
shown below.  The asterisks show the
separation between sorted choices and unsorted
choices.

      |       |       |       |       |       |
      |   A   |   C   |   E   |   B   |   D   |
      |       |       |       |       |       |
 -----*************************-------+-------+
      * \     |       |       *       |       |
  A   *   \   |  A>C  |  A>E  *  A>B  |  A>D  |
      *     \ |       |       *       |       |
 -----+-------+-------+-------+-------+-------+
      *       | \     |       *       |       |
  C   *  C>A  |   \   |  C>E  *  C>B  |  C>D  |
      *       |     \ |       *       |       |
 -----+-------+-------+-------+-------+-------+
      *       |       | \     *       |       |
  E   *  E>A  |  E>C  |   \   *  E>B  |  E>D  |
      *       |       |     \ *       |       |
 -----*************************-------+-------+
      |       |       |       | \     |       |
  B   |  B>A  |  B>C  |  B>E  |   \   |  B>D  |
      |       |       |       |     \ |       |
 -----+-------+-------+-------+-------+-------+
      |       |       |       |       | \     |
  D   |  D>A  |  D>C  |  D>E  |  D>B  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

The diagonal line passes through empty cells
-- that would otherwise represent a
choice's comparison with itself, such as
A>A.

The diagonal line also is the border between
the upper-right triangular area and the
lower-left triangular area.  The sequence
score for the current sequence is the sum of
all the pairwise counts in the upper-right
triangular area (currently A>C + A>E +
A>B + A>D + C>E + C>B + C>D +
E>B + E>D + B>D).

The goal of these calculations is to find
the maximum sequence score, which means the
goal is to change the sequence so that the
largest pairwise counts move into the
upper-right triangular area, leaving the
smallest pairwise counts in the lower-left
triangular area.

The first step in sorting choice B is to
consider the possibility of moving it to the
left of choice E, which would form the sequence
A, C, B, E.  Here is the pairwise-count
matrix for this sequence.  The asterisks
now include choice B because this is a possible
sort order.

      |       |       |       |       |       |
      |   A   |   C   |   B   |   E   |   D   |
      |       |       |       |       |       |
 -----*********************************-------+
      * \     |       |       |       *       |
  A   *   \   |  A>C  |  A>B  |  A>E  *  A>D  |
      *     \ |       |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       | \     |       |       *       |
  C   *  C>A  |   \   |  C>B  |  C>E  *  C>D  |
      *       |     \ |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       | \     |       *       |
  B   *  B>A  |  B>C  |   \   |  B>E  *  B>D  |
      *       |       |     \ |  ---  *       |
 -----*-------+-------+-------+-------*-------+
      *       |       |       | \     *       |
  E   *  E>A  |  E>C  |  E>B  |   \   *  E>D  |
      *       |       |  ---  |     \ *       |
 -----*********************************-------+
      |       |       |       |       | \     |
  D   |  D>A  |  D>C  |  D>B  |  D>E  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

The only pairwise counts that crossed the
diagonal line are the (underlined) counts
B>E and E>B, which swapped places.
All the other pairwise counts that move do not
cross the diagonal line; they stay on the same
side of the diagonal line.

As a result, the score for this sequence,
compared to the score for the previous
sequence, increases (or decreases if negative)
by the amount B>E minus E>B.  In
this case (assuming there are no complications
that are explained later) the sequence score
has increased because in the final
(alphabetical) sort order, choice B appears
before choice E.

The next step in sorting choice B is to
consider the possibility of moving it to the
left of choice C, which would form the sequence
A, B, C, E.  Here is the pairwise-count
matrix for this sequence.

      |       |       |       |       |       |
      |   A   |   B   |   C   |   E   |   D   |
      |       |       |       |       |       |
 -----*********************************-------+
      * \     |       |       |       *       |
  A   *   \   |  A>B  |  A>C  |  A>E  *  A>D  |
      *     \ |       |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       | \     |       |       *       |
  B   *  B>A  |   \   |  B>C  |  B>E  *  B>D  |
      *       |     \ |  ---  |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       | \     |       *       |
  C   *  C>A  |  C>B  |   \   |  C>E  *  C>D  |
      *       |  ---  |     \ |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       |       | \     *       |
  E   *  E>A  |  E>B  |  E>C  |   \   *  E>D  |
      *       |       |       |     \ *       |
 -----*********************************-------+
      |       |       |       |       | \     |
  D   |  D>A  |  D>B  |  D>C  |  D>E  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

The only pairwise counts that crossed the
diagonal line are the (underlined) counts
B>C and C>B, which swapped places.
The other pairwise counts that moved remained
on the same side of the diagonal line.

The score for this sequence increases (or
decreases if negative) by the amount B>C
minus C>B.  In this case the sequence
score has increased because (in the final
alphabetical order) choice B appears before
choice C.

The final step in sorting choice B is to
consider the possibility of moving it to the
left of choice A, which would form the sequence
B, A, C, E.  Here is the matrix for this
sequence.

      |       |       |       |       |       |
      |   B   |   A   |   C   |   E   |   D   |
      |       |       |       |       |       |
 -----*********************************-------+
      * \     |       |       |       *       |
  B   *   \   |  B>A  |  B>C  |  B>E  *  B>D  |
      *     \ |  ---  |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       | \     |       |       *       |
  A   *  A>B  |   \   |  A>C  |  A>E  *  A>D  |
      *  ---  |     \ |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       | \     |       *       |
  C   *  C>B  |  C>A  |   \   |  C>E  *  C>D  |
      *       |       |     \ |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       |       | \     *       |
  E   *  E>B  |  E>A  |  E>C  |   \   *  E>D  |
      *       |       |       |     \ *       |
 -----*********************************-------+
      |       |       |       |       | \     |
  D   |  D>B  |  D>A  |  D>C  |  D>E  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

The only pairwise counts that crossed the
diagonal line are the (underlined) counts
B>A and A>B, which swapped places.
The other pairwise counts that moved remained
on the same side of the diagonal line.

The score for this sequence increases (or
decreases if negative) by the amount B>A
minus A>B.  In this case the sequence
score has decreased because (in the final
alphabetical order) choice B appears after, not
before, choice A.

At this point choice B has been tested at
each position within the sorted portion.
The  maximum sequence score (for the sorted
portion) occurred when it was between choices A
and C.  As a result, choice B will be
moved to the position between choices A and
C.

Notice that the full sequence score did not
need to be calculated in order to find this
"local" maximum.  These calculations only
need to keep track of increases and decreases
that occur as the being-sorted choice swaps
places with successive already-sorted
choices.

The pairwise-count matrix with choice B in
the second sort-order position (between A and
C) is shown below.  Now choice D is the
only unsorted choice.

      |       |       |       |       |       |
      |   A   |   B   |   C   |   E   |   D   |
      |       |       |       |       |       |
 -----*********************************-------+
      * \     |       |       |       *       |
  A   *   \   |  A>B  |  A>C  |  A>E  *  A>D  |
      *     \ |       |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       | \     |       |       *       |
  B   *  B>A  |   \   |  B>C  |  B>E  *  B>D  |
      *       |     \ |       |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       | \     |       *       |
  C   *  C>A  |  C>B  |   \   |  C>E  *  C>D  |
      *       |       |     \ |       *       |
 -----*-------+-------+-------+-------*-------+
      *       |       |       | \     *       |
  E   *  E>A  |  E>B  |  E>C  |   \   *  E>D  |
      *       |       |       |     \ *       |
 -----*********************************-------+
      |       |       |       |       | \     |
  D   |  D>A  |  D>B  |  D>C  |  D>E  |   \   |
      |       |       |       |       |     \ |
 -----+-------+-------+-------+-------+-------+

Choice D would be sorted in the same
way.  Of course the maximum sequence score
would occur when choice D is between choices C
and E, so D is moved there.

      |       |       |       |       |       |
      |   A   |   B   |   C   |   D   |   E   |
      |       |       |       |       |       |
 -----*****************************************
      * \     |       |       |       |       *
  A   *   \   |  A>B  |  A>C  |  A>D  |  A>E  *
      *     \ |       |       |       |       *
 -----*-------+-------+-------+-------+-------*
      *       | \     |       |       |       *
  B   *  B>A  |   \   |  B>C  |  B>D  |  B>E  *
      *       |     \ |       |       |       *
 -----*-------+-------+-------+-------+-------*
      *       |       | \     |       |       *
  C   *  C>A  |  C>B  |   \   |  C>D  |  C>E  *
      *       |       |     \ |       |       *
 -----*-------+-------+-------+-------+-------*
      *       |       |       | \     |       *
  D   *  D>A  |  D>B  |  D>C  |   \   |  D>E  *
      *       |       |       |     \ |       *
 -----*-------+-------+-------+-------+-------*
      *       |       |       |       | \     *
  E   *  E>A  |  E>B  |  E>C  |  E>D  |   \   *
      *       |       |       |       |     \ *
 -----*****************************************

Now there are no more choices to sort, so
the resulting sequence is A, B, C, D, E.
In this sequence the full sequence score
-- which equals A>B + A>C + A>D +
A>E + B>C + B>D + B>E + C>D +
C>E + D>E -- is likely to be the
highest possible sequence score.

Additional calculations, as described below,
are needed because in rare cases it is possible
that moving two or more choices at the same
time could produce a higher sequence
score.  This concept is analogous to
climbing a mountain in foggy conditions by
always heading in the locally higher direction
and ending up at the top of a peak and then,
when the fog clears, seeing a higher peak.

Full calculation method for VoteFair popularity ranking:

This is a description of the full algorithm
used to calculate VoteFair popularity ranking
results.

The algorithm begins by calculating the
Choice-Specific Pairwise-Score ranking.
This pre-sort is a required part of the
process.  Without it, some unusual cases
can cause the calculations to fail to find the
sequence with the highest score.  This
pre-sort is analogous to starting a search for
the highest mountain peak within a mountain
range instead of starting the search within a
large valley.

The next step is to apply the insertion-sort
method as described in the section above,
including starting at the left/highest end.

To ensure that all possible moves of each
choice are considered, the insertion-sort
method is done in both directions.
Sorting in both directions means that in some
sorting passes sorting moves choices to the
left, as explained in the above example.
In other sorting passes sorting starts by
considering the right-most choice as the first
sorted choice, and choices move to the right,
into the sorted portion.  This convention
ensures movement for choices that need to move
right, instead of left, in order to cause an
increase in the score.

Complications can arise when there is
"circular ambiguity", so additional steps are
used.  The most common cases of circular
ambiguity involve several choices that are tied
for the same sort-order position.

A key part of dealing with circular
ambiguity is to follow this convention:
whenever a choice can produce the same,
highest, sequence score at more than one
position, the choice is moved to the farthest
of those highest-sequence-score positions.

Another part of dealing with these
complications is to sort the sequence multiple
times.

During the second sorting pass, if there is
no circular ambiguity, the sequence of the
choices in the pairwise matrix remains the
same.  This lack of movement (when there
is no circular ambiguity) occurs because the
sorted and unsorted portions are
adjacent.  Specifically, each choice to be
sorted is already at the top (for left-movement
sorting) or bottom (for right-movement sorting)
of the "unsorted" portion, and it is being
moved to the bottom (for left-movement sorting)
or top (for right-movement sorting) of
the "sorted" portion.  In such cases
the only thing that moves is the boundary
between the sorted choices and unsorted
choices.

However, in cases that involve circular
ambiguity, the positions of some choices will
change during the second and later sorting
passes.  This happens because the
convention (as explained above) is to move each
choice as far as it will go, within the limits
of maximizing the sequence score.

During the sorting passes the highest
sort-order (sequence) position of each choice
is tracked, and the lowest sort-order position
of each choice is tracked.  These highest
and lowest positions are reset (to current
positions) whenever the sequence score
increases to a higher score.  At the end
of the sorting process the highest and lowest
positions reveal which choices are tied at the
same popularity ranking level.

Using the insertion-sort example, if choices
B, C, and D can be in any order and still
produce the same highest sequence score, then
each of these choices would move to the left of
the other two each time it is sorted, and each
of these choices would have the same
highest-ranked position of second place, and
each would have the same lowest-ranked position
of fourth place. Because these three choices
have the same highest and lowest positions,
they are easily identified as tied (at the same
popularity ranking).

More complex cases of circular ambiguity can
occur.  To deal with these cases, and to
ensure the correctness of the "winner" (the
most popular choice), the sorting process is
repeated for the top half (plus one) of the
highest-ranked choices, and this sub-set
sorting is repeated until there are just three
choices.  For example, if there are 12
choices, the sorting process is done for 12
choices, then the top 7 choices, then the top 4
choices, and finally the top 3 choices.
Then the highest-ranked choice (or the choices
that are tied at the top) is kept at the
highest rank while the other choices are sorted
a final time.  (If, instead, the
least-popular choice is the most important one
to identify correctly, the data supplied to
this algorithm can be inverted according to
preference levels, and then the calculated
ranking can be reversed.)

As a clarification, the extra sub-set
sorting is done only if more than one sequence
has the same highest sequence score.  This
point is significant if the distinction between
VoteFair popularity ranking and the
Condorcet-Kemeny method is relevant.
Specifically, the Condorcet-Kemeny method does
not indicate how such "tied" sequence scores
should be resolved, whereas VoteFair popularity
ranking resolves such "tied" sequence scores as
part of its calculation process.

After all the sorting has been done, the
highest and lowest ranking levels are used to
determine the results.  For each choice
its highest and lowest ranking levels
are added together (which equals twice their
average) and then multiplied times a
constant.  The constant equals 10 times
the number of choices minus one.  These
numbers are converted to integers, and then
these "averaged scaled integerized" values are
used as the non-normalized ranking
levels.  Two or more choices are ranked at
the same level if they have the same
"averaged-scaled-integerized" ranking
values.

The final calculation step is to normalize
the "averaged-scaled-integerized" ranking
levels so that the normalized ranking levels
are consecutive, namely 1, 2, 3, etc. (so that
no ranking levels are skipped).

The result is a ranking that identifies
which choice is first-most popular, which
choice is second-most popular, and so on down
to which choice is least popular.  Ties
can occur at any level.

Calculation time:

The full algorithm used to calculate
VoteFair popularity ranking results  has a
calculation time that is less than or equal to
the following polynomial function:

  T = A + ( B * N ) + ( C * ( N * N ) )

where T is the calculation time, N is the
number of choices, and A and B and C are
constants.  (In mathematical notation, N *
N would be written as N squared.)  This
function includes the calculation time required
for the Choice-Specific Pairwise-Score (CSPS)
pre-sort calculations.

This time contrasts with the slow execution
times  of the "NP-hard" approach, in which
every sequence score is calculated in order to
find the sequence with the highest score.
If every sequence score were calculated (from
scratch), the calculation time would be
proportional to:

  N! * N * N

where N is the number of choices, N! is N
factorial (2 * 3 * 4 * ... * N), and N * N
equals N squared.  Note that N factorial
equals the number of possible sequences, and N
squared times one-half approximately equals the
number of pairwise counts that are added to
calculate each sequence score.

This clarification about calculation time is
included because there is an academically
common -- yet mistaken -- belief that
calculating the "Condorcet-Kemeny method" is
"NP-hard" and cannot be calculated in a time
that is proportional to a polynomial function
of N (the number of choices).

(c) Copyright 2011 Richard Fobes at VoteFair.org

(This description copied from VoteFair.org
with permission.)

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_votefair_insertion_sort_popularity_rank
#-----------------------------------------------
#-----------------------------------------------

sub calc_votefair_insertion_sort_popularity_rank
{

    my $adjusted_choice ;
    my $adjusted_choice_to_move ;
    my $new_adjusted_choice ;
    my $new_adjusted_choice_count ;
    my $starting_adjusted_choice_number ;
    my $local_adjusted_choice_count ;
    my $tally_adjusted_choice_for_choice_to_move ;
    my $tally_adjusted_choice_for_choice_at_destination ;
    my $actual_choice ;
    my $actual_choice_to_move ;
    my $actual_choice_at_destination ;
    my $count_of_choices_in_top_half ;
    my $number_of_choices_to_shift ;
    my $sequence_position ;
    my $destination_sequence_position ;
    my $source_sequence_position ;
    my $to_position ;
    my $from_position ;
    my $position_of_choice_to_move ;
    my $position_number ;
    my $actual_destination ;
    my $possible_destination ;
    my $maximum_move_distance_allowed ;
    my $direction_increment ;
    my $distance_to_possible_destination ;
    my $number_of_positions_sorted ;
    my $ranking_level ;
    my $special_ranking_level ;
    my $highest_rank ;
    my $lowest_rank ;
    my $choice_counter ;
    my $pair_counter ;
    my $score_increase ;
    my $tally_choice_to_move_over_choice_at_destination ;
    my $tally_choice_at_destination_over_choice_to_move ;
    my $largest_subset_sum ;
    my $final_stage_reached_at_main_loop_count ;
    my $pass_number ;
    my $sort_pass_counter ;
    my $sort_pass_count_at_last_move ;
    my $sort_pass_counter_maximum ;
    my $recent_sort_pass_count_in_direction_left ;
    my $recent_sort_pass_count_in_direction_right ;
    my $pass_count_at_last_score_increase ;
    my $reached_stable_condition_at_pass_count ;
    my $count_of_sequences_with_same_highest_score ;
    my $main_loop_count ;
    my $main_loop_maximum_count ;
    my $scale_value ;
    my $true_or_false_log_details ;
    my $highest_rank_threshold ;
    my $count_of_highest_ranked_choices ;
    my $count_of_lower_ranked_choices ;
    my $adjusted_choice_overall ;
    my $possible_ranking_level ;
    my $actual_first_choice ;
    my $actual_second_choice ;
    my $tally_adjusted_first_choice ;
    my $tally_adjusted_second_choice ;
    my $tally_first_over_second ;
    my $tally_second_over_first ;

    my @local_actual_choice_for_adjusted_choice ;
    my @actual_choice_at_new_adjusted_choice ;
    my @actual_choice_in_insertion_rank_sequence_position ;
    my @highest_insertion_sort_sequence_position_for_actual_choice ;
    my @lowest_insertion_sort_sequence_position_for_actual_choice ;
    my @pass_number_at_last_rerank_for_adjusted_choice ;
    my @adjusted_choice_count_at_stage ;
    my @highest_ranked_actual_choice_at_count ;
    my @lower_ranked_actual_choice_at_count ;
    my @local_adjusted_choice_for_actual_choice ;


#-----------------------------------------------
#  Hide or show the details in the log file.
#  This choice can slow down the software
#  because it creates a large log file.

    $true_or_false_log_details = $global_false ;
    $true_or_false_log_details = $global_true ;
    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[insertion sort, beginning calc_votefair_insertion_sort_popularity_rank subroutine]\n\n" ;
        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "[insertion sort, details shown (change flag value to hide details)]\n" ;
        } else
        {
            print LOGOUT "[insertion sort, details hidden (change flag value to view details)]\n" ;
        }
    }


#-----------------------------------------------
#  Set the results to zero in case an error is
#  encountered.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] = 0 ;
        $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice ] = 0 ;
    }


#-----------------------------------------------
#  If there are not at least two choices,
#  indicate an error.

    if ( $global_adjusted_choice_count < 2 )
    {
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, ERROR: number of (adjusted) choices is less than two]\n" } ;
        return ;
    }


#-----------------------------------------------
#  If the total vote count is zero, indicate an
#  error.

    if ( $global_current_total_vote_count < 1 )
    {
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, ERROR: number of votes is zero]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Initialize the choice sequence.  Use the
#  sequence calculated by the choice-specific
#  score-based ranking calculations.
#
#  In case there are no results from those calculations,
#  initialize the sequence to be in numeric
#  order (choice 1, choice 2, etc.).
#  However, in complex cases, numeric order
#  may produce the wrong results!

    for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
    {
        $adjusted_choice = $sequence_position ;
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] = $actual_choice ;
    }
    $adjusted_choice = 1 ;
    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
    if ( ( defined( $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] ) ) && ( $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] > 0 ) )
    {
        $sequence_position = 1 ;
        for ( $ranking_level = 1 ; $ranking_level <= $global_adjusted_choice_count ; $ranking_level ++ )
        {
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                if ( $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] == $ranking_level )
                {
                    $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] = $actual_choice ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, put choice " . $actual_choice . " into sequence position " . $sequence_position . "]\n" } ;
                    $sequence_position ++ ;
                    if ( $sequence_position > $global_adjusted_choice_count )
                    {
                        last ;
                    }
                }
            }
        }
    } else
    {
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " triggered-program-bug" . "\n-----\n\n" ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[ERROR: the results of the choice-specific score-based calculations are not available, so the results might not be correct!]\n" } ;
    }


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.

    if ( $true_or_false_log_details == $global_true )
    {
        for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
        {
            $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
            $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
        }
        print LOGOUT "[insertion sort, initial ranking:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  Use a local value for the adjusted choice
#  count.  This allows the count to change.

    $local_adjusted_choice_count = $global_adjusted_choice_count ;


#-----------------------------------------------
#  Create lists that associate adjusted choice
#  numbers with actual choice numbers, in both
#  directions.  These local values are used
#  instead of the global values because these
#  adjusted choice numbers will change.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] = $actual_choice ;
        $local_adjusted_choice_for_actual_choice[ $actual_choice ] = $adjusted_choice ;
    }


#-----------------------------------------------
#  Begin a loop that repeats in order to handle
#  the different stages in the calculations,
#  where the different stages sort either all
#  the choices or a subset of the choices.
#  This loop does not exit here; it exits when
#  the stages are all done.
#  Note that this loop is only repeated if
#  more than one sequence has the same highest
#  sequence score.

    $global_sequence_score_using_insertion_sort_method = 0 ;
    $count_of_sequences_with_same_highest_score = 0 ;
    $final_stage_reached_at_main_loop_count = 0 ;
    $main_loop_maximum_count = 10 ;
    for ( $main_loop_count = 1 ; $main_loop_count <= $main_loop_maximum_count ; $main_loop_count ++ )
    {
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, main-loop number is " . $main_loop_count . "]\n" } ;


#-----------------------------------------------
#  If this is the "starting" stage, sort all the
#  choices (starting with the sort order
#  calculated by the choice-specific score-based
#  method).

        if ( $main_loop_count == 1 )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, first/start stage, so sorting all choices]\n\n" } ;
        }


#-----------------------------------------------
#  If the final stage is complete, exit the loop.

        if ( ( $final_stage_reached_at_main_loop_count > 0 ) && ( $main_loop_count >= $final_stage_reached_at_main_loop_count ) )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, final stage done, so exiting main loop]\n\n" } ;
            last ;
        }


#-----------------------------------------------
#  If at least one pass of sorting has been done
#  and the total number of choices is 2, the
#  sorting is done, so exit the main loop.

        if ( ( $main_loop_count > 1 ) && ( $global_adjusted_choice_count <= 2 ) )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, choice count is just one or two, sorting is done, so exiting main loop]\n" } ;
            last ;
        }


#-----------------------------------------------
#  If this is not the starting stage, and is not
#  the final stage (checked above), and at least
#  one pass of sub-sorting has been done, and
#  the number of sub-sorted choices is now 3 or
#  less, request starting the final stage.

        if ( ( $main_loop_count > 1 ) && ( $local_adjusted_choice_count <= 3 ) && ( $local_adjusted_choice_count < $global_adjusted_choice_count ) )
        {
            $final_stage_reached_at_main_loop_count = $main_loop_count ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, count of choices just sub-sorted (" . $local_adjusted_choice_count . ") is three or less, so starting final stage]\n" } ;
        }


#-----------------------------------------------
#  If this is not the starting stage, and is not the
#  final stage, attempt to reduce the number
#  of choices being sorted.  Identify the choices
#  in the top half, plus the next-ranked choice.
#  If appropriate, these choices will be sub-sorted.

        if ( ( $main_loop_count > 1 ) && ( $local_adjusted_choice_count > 3 ) )
        {
            $new_adjusted_choice_count = int( ( $local_adjusted_choice_count / 2 ) + 1 ) ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, finding " . $new_adjusted_choice_count . " choices at highest rankings]\n" } ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                $actual_choice_at_new_adjusted_choice[ $adjusted_choice ] = 0 ;
            }
            $count_of_choices_in_top_half = 0 ;
            for ( $highest_rank_threshold = 1 ; $highest_rank_threshold <= $local_adjusted_choice_count ; $highest_rank_threshold ++ )
            {
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    $highest_rank = $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] ;
                    if ( $highest_rank == $highest_rank_threshold )
                    {
                        $count_of_choices_in_top_half ++ ;
                        $new_adjusted_choice = $count_of_choices_in_top_half ;
                        $actual_choice_at_new_adjusted_choice[ $new_adjusted_choice ] = $actual_choice ;
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " (at ranking level " . $highest_rank . ") will be sub-sorted as adjusted choice " . $new_adjusted_choice . "]\n" } ;
                    }
                }
                if ( $count_of_choices_in_top_half >= $new_adjusted_choice_count )
                {
                    last ;
                }
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, found " . $count_of_choices_in_top_half . " choices at highest rankings]\n" } ;


#-----------------------------------------------
#  If the just-calculated number of choices to be
#  sub-sorted is less than three, or has not
#  changed (been reduced), request starting the final
#  stage (which will sort all the choices except
#  the highest-ranked choice).

            if ( $count_of_choices_in_top_half < 3 )
            {
                $final_stage_reached_at_main_loop_count = $main_loop_count ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, count of choices to sub-sort (" . $local_adjusted_choice_count . ") is less than three, so starting final stage]\n" } ;
            } elsif ( $count_of_choices_in_top_half == $local_adjusted_choice_count )
            {
                $final_stage_reached_at_main_loop_count = $main_loop_count ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, count of choices to sub-sort (" . $local_adjusted_choice_count . ") did not change (which would cause an endless loop), so starting final stage]\n" } ;


#-----------------------------------------------
#  If the number of choices to be sub-sorted is
#  less than the previous number of choices
#  sorted, but is not less than three, prepare to sort them
#  by shifting the specified number of top-ranked
#  choices into the lowest-numbered sequence
#  positions.

            } else
            {
                $local_adjusted_choice_count = $count_of_choices_in_top_half ;
                $adjusted_choice_count_at_stage[ $main_loop_count ] = $local_adjusted_choice_count ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, now adjusted choice count is " . $local_adjusted_choice_count . "]\n" } ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $actual_choice_at_new_adjusted_choice[ $adjusted_choice ] ;
                    $local_adjusted_choice_for_actual_choice[ $actual_choice ] = $adjusted_choice ;
                    $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] = $actual_choice ;
                    $sequence_position = $adjusted_choice ;
                    $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] = $actual_choice ;
                }
            }
        }


#-----------------------------------------------
#  If this is the final stage, identify the
#  highest-ranked choices -- based on having
#  been at the highest sequence position (during
#  the most recent sorting pass) -- and save
#  them separately.  Also create a list of the
#  other choices.

        if ( $final_stage_reached_at_main_loop_count == $main_loop_count )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, starting final stage]\n" } ;
            $count_of_highest_ranked_choices = 0 ;
            $count_of_lower_ranked_choices = 0 ;
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                if ( $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] == 1 )
                {
                    $count_of_highest_ranked_choices ++ ;
                    $highest_ranked_actual_choice_at_count[ $count_of_highest_ranked_choices ] = $actual_choice ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, choice " . $actual_choice . " is at highest rank]\n" } ;
                } else
                {
                    $count_of_lower_ranked_choices ++ ;
                    $lower_ranked_actual_choice_at_count[ $count_of_lower_ranked_choices ] = $actual_choice ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $global_adjusted_choice_count ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $global_adjusted_choice_count ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, choice " . $actual_choice . " is at lower rank]\n" } ;
                }
            }


#-----------------------------------------------
#  If all the choices are tied at the highest
#  level, indicate this situation and exit the
#  main loop.

            if ( $count_of_highest_ranked_choices == $global_adjusted_choice_count )
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, all the choices are tied at the highest level]\n" } ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = 1 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = 1 ;
                    $sequence_position = $actual_choice ;
                    $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] = $actual_choice ;
                    $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] = $actual_choice ;
                    $local_adjusted_choice_for_actual_choice[ $actual_choice ] = $adjusted_choice ;
                }
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, exiting main loop]\n" } ;
                last ;
            }


#-----------------------------------------------
#  If this is the final stage, put all the choices
#  that are not at the highest rank into a sequence
#  for final sorting.  Use the sequence calculated
#  by VoteFair choice-specific score-based ranking.

            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, preparing to sub-sort the choices that are not highest ranked]\n" } ;
            $local_adjusted_choice_count = $global_adjusted_choice_count - $count_of_highest_ranked_choices ;
            $new_adjusted_choice = 1 ;
            for ( $adjusted_choice_overall = 1 ; $adjusted_choice_overall <= $global_adjusted_choice_count ; $adjusted_choice_overall ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice_overall ] ;
                if ( $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] > 1 )
                {
                    $local_adjusted_choice_for_actual_choice[ $actual_choice ] = $new_adjusted_choice ;
                    $local_actual_choice_for_adjusted_choice[ $new_adjusted_choice ] = $actual_choice ;
                    $new_adjusted_choice ++ ;
                }
            }
            $sequence_position = 1 ;
            for ( $possible_ranking_level = 1 ; $possible_ranking_level <= $global_adjusted_choice_count ; $possible_ranking_level ++ )
            {
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    if ( $possible_ranking_level == $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] )
                    {
                        $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] = $actual_choice ;
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " is at sequence position " . $sequence_position . " and is now adjusted choice " . $adjusted_choice . "]\n" } ;
                        $sequence_position ++ ;
                    }
                }
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, will sort all other choices]\n" } ;
        }


#-----------------------------------------------
#  Initialize the values that keep track of
#  each choice's highest and lowest positions.

        for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
        {
            $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
            $adjusted_choice = $local_adjusted_choice_for_actual_choice[ $actual_choice ] ;
            $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $sequence_position ;
            $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $sequence_position ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, next in sequence is choice " . $actual_choice . "]\n" } ;
        }


#-----------------------------------------------
#  Log the starting sequence.

        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "\n[insertion sort, in sort-pass loop, starting sequence is: " ;
            for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
            {
                $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
                print LOGOUT $actual_choice . " , " ;
            }
            print LOGOUT "]\n" ;
        }


#-----------------------------------------------
#  Initialize values that are used in the
#  upcoming loop that repeatedly sorts the
#  choices.

        $direction_increment = 1 ;
        $starting_adjusted_choice_number = 1 ;
        $sort_pass_count_at_last_move = 0 ;
        $sort_pass_counter_maximum = 10 ;
        $pass_count_at_last_score_increase = 0 ;
        $recent_sort_pass_count_in_direction_left = 0 ;
        $recent_sort_pass_count_in_direction_right = 0 ;
        $reached_stable_condition_at_pass_count = 0 ;


#-----------------------------------------------
#  Begin a loop that repeatedly sorts the
#  choices.  Normally the loop does not reach
#  the maximum loop count used here.

        for ( $sort_pass_counter = 1 ; $sort_pass_counter <= $sort_pass_counter_maximum ; $sort_pass_counter ++ )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, sort pass counter = " . $sort_pass_counter . ", last left sort count is " . $recent_sort_pass_count_in_direction_left . ", last right sort count = " . $recent_sort_pass_count_in_direction_right . "]\n" } ;


#-----------------------------------------------
#  If there is just one choice, indicate its
#  sort order, and exit the sort-pass loop.

            if ( $local_adjusted_choice_count == 1 )
            {
                $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ 1 ] ;
                $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = 1 ;
                $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = 1 ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, only one choice, so no need to sort it]\n" } ;
                last ;
            }


#-----------------------------------------------
#  If there are just two choices, just look at
#  the two relevant pairwise-count numbers,
#  sort the two choices accordingly, and then
#  exit the sort-pass loop.

            if ( $local_adjusted_choice_count == 2 )
            {
                $actual_first_choice = $actual_choice_in_insertion_rank_sequence_position[ 1 ] ;
                $actual_second_choice = $actual_choice_in_insertion_rank_sequence_position[ 2 ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, only two choices, " . $actual_second_choice . " and " . $actual_first_choice . "]\n" } ;
                $tally_adjusted_first_choice = $global_adjusted_choice_for_actual_choice[ $actual_first_choice ] ;
                $tally_adjusted_second_choice = $global_adjusted_choice_for_actual_choice[ $actual_second_choice ] ;
                if ( $tally_adjusted_first_choice < $tally_adjusted_second_choice )
                {
                    $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $tally_adjusted_first_choice ] + $tally_adjusted_second_choice ;
                    $tally_first_over_second = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                    $tally_second_over_first = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                } else
                {
                    $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $tally_adjusted_second_choice ] + $tally_adjusted_first_choice ;
                    $tally_first_over_second = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                    $tally_second_over_first = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                }
                if ( $tally_first_over_second == $tally_second_over_first )
                {
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 1 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 1 ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 1 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 1 ;
                    $actual_choice_in_insertion_rank_sequence_position[ 1 ] = $actual_first_choice ;
                    $actual_choice_in_insertion_rank_sequence_position[ 2 ] = $actual_second_choice ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, choice " . $actual_first_choice . " and choice " . $actual_second_choice . " are tied as highest-ranked]\n" } ;
                } elsif ( $tally_first_over_second > $tally_second_over_first )
                {
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 1 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 1 ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 2 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 2 ;
                    $actual_choice_in_insertion_rank_sequence_position[ 1 ] = $actual_first_choice ;
                    $actual_choice_in_insertion_rank_sequence_position[ 2 ] = $actual_second_choice ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, choice " . $actual_first_choice . " is ranked higher than choice " . $actual_second_choice . "]\n" } ;
                } else
                {
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 2 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_first_choice ] = 2 ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 1 ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_second_choice ] = 1 ;
                    $actual_choice_in_insertion_rank_sequence_position[ 1 ] = $actual_second_choice ;
                    $actual_choice_in_insertion_rank_sequence_position[ 2 ] = $actual_first_choice ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, choice " . $actual_second_choice . " is ranked higher than choice " . $actual_first_choice . "]\n" } ;
                }
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, only two choices, they are now sorted]\n" } ;
                last ;
            }


#-----------------------------------------------
#  Exit the sorting process when there have
#  been at least two sorting passes (one each
#  direction) during which the total score has
#  not increased, and then after two more
#  passes to ensure the choices have all moved
#  as far as possible in each direction.
#  The "extra" sorting passes
#  ensure that cycles ("ties") have had a
#  chance to move the involved ("tied")
#  choices to their highest and lowest
#  position values.
#  Also, when the sorted sequence is stable,
#  set a counter that is used to determine
#  if more than one sequence has the same
#  highest sequence score.

            if ( ( $sort_pass_counter >= $reached_stable_condition_at_pass_count + 2 ) && ( $reached_stable_condition_at_pass_count > 0 ) )
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, two extra sorting passes have been done (after stable condition reached), so exiting sorting process]\n\n" } ;
                last ;
            }
            if ( ( $sort_pass_counter > $pass_count_at_last_score_increase + 1 ) && ( $recent_sort_pass_count_in_direction_left > $pass_count_at_last_score_increase ) && ( $recent_sort_pass_count_in_direction_right > $pass_count_at_last_score_increase ) && ( $recent_sort_pass_count_in_direction_left > 0 ) && ( $recent_sort_pass_count_in_direction_right > 0 ) && ( $reached_stable_condition_at_pass_count <= 0 ) )
            {
                $reached_stable_condition_at_pass_count = $sort_pass_counter ;
                $count_of_sequences_with_same_highest_score = 1 ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, sorting has been done in both directions since the last score increase, so indicating stable condition, so will do two more sorting passes]\n" } ;
            }


#-----------------------------------------------
#  Change the sorting direction for different
#  sorting passes.  When the direction_increment
#  value is positive one, the sorting starts at
#  the highest-ranked (left) end and moves
#  choices left (to the higher-ranked positions).
#  When the direction_increment value is
#  negative one, sorting starts at the
#  lowest-ranked (right) end and moves choices
#  to the right (to the lower-ranked positions).
#  This symmetry ensures that tied choices pass
#  through the same highest and lowest rank
#  positions, and that each choice can move to
#  every possible position.

            if ( $sort_pass_counter == 1 )
            {
                $direction_increment = 1 ;
            } elsif ( $sort_pass_counter == $reached_stable_condition_at_pass_count )
            {
                $direction_increment = $direction_increment * -1 ;
            } elsif ( $sort_pass_counter == $reached_stable_condition_at_pass_count + 1 )
            {
                $direction_increment = $direction_increment * -1 ;
            } elsif ( ( $sort_pass_counter == $sort_pass_count_at_last_move + 1 ) && ( $sort_pass_counter == $pass_count_at_last_score_increase + 2 ) )
            {
                $direction_increment = $direction_increment ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, keeping sort direction the same -- because last move was during pass count " . $sort_pass_count_at_last_move . " and last score increase was during pass count " . $pass_count_at_last_score_increase . "]\n\n" } ;
            } else
            {
                $direction_increment = $direction_increment * -1 ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, changing to opposite sort direction]\n\n" } ;
            }
            if ( $direction_increment == 1 )
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, movement direction is left]\n\n" } ;
            } else
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, movement direction is right]\n\n" } ;
            }


#-----------------------------------------------
#  For each sorting direction, save the sorting
#  pass number for the most recent sorting done
#  in that direction.

            if ( $direction_increment == 1 )
            {
                $recent_sort_pass_count_in_direction_left = $sort_pass_counter ;
            } else
            {
                $recent_sort_pass_count_in_direction_right = $sort_pass_counter ;
            }


#-----------------------------------------------
#  Begin a loop that moves each unsorted choice
#  into the sorted segment.
#  Start by regarding the choice in the
#  highest-ranked (left-most) sequence position
#  as being the first item in the sorted list.
#  The "number_of_positions_sorted" value
#  counts how many of the first (left-most)
#  sequence positions have been sorted, so this
#  number separates the sequence into a sorted
#  list on the left and an unsorted list on
#  the right.

            for ( $number_of_positions_sorted = 1 ; $number_of_positions_sorted < $local_adjusted_choice_count ; $number_of_positions_sorted ++ )
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, number of positions sorted is " .  $number_of_positions_sorted . "]\n" } ;


#-----------------------------------------------
#  Identify which choice will be moved from the
#  unsorted portion of the list into the sorted
#  portion.

                if ( $direction_increment == 1 )
                {
                    $position_of_choice_to_move = $number_of_positions_sorted + 1 ;
                } else
                {
                    $position_of_choice_to_move = $local_adjusted_choice_count - $number_of_positions_sorted ;
                }
                $actual_choice_to_move = $actual_choice_in_insertion_rank_sequence_position[ $position_of_choice_to_move ] ;
                $adjusted_choice_to_move = $local_adjusted_choice_for_actual_choice[ $actual_choice_to_move ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "\n" } ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, check if need to move choice " .  $actual_choice_to_move . "]\n" } ;


#-----------------------------------------------
#  If this choice has already traveled to the
#  farthest position in this direction, skip
#  this choice.

                if ( $direction_increment == 1 )
                {
                    if ( $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] == 1 )
                    {
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, choice " .  $adjusted_choice_to_move . " has already been to the highest ranking]\n" } ;
                        next ;
                    }
                } else
                {
                    if ( $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] == $local_adjusted_choice_count )
                    {
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, choice " .  $adjusted_choice_to_move . " has already been to the lowest ranking]\n" } ;
                        next ;
                    }
                }


#-----------------------------------------------
#  Begin a loop that checks each sorted
#  position as a possible destination for the
#  unsorted choice being moved.

                $maximum_move_distance_allowed = $number_of_positions_sorted ;
                $actual_destination = $position_of_choice_to_move ;
                $score_increase = 0 ;
                $largest_subset_sum = -99999 ;
                for ( $distance_to_possible_destination = 1 ; $distance_to_possible_destination <= $maximum_move_distance_allowed ; $distance_to_possible_destination ++ )
                {
                    if ( $direction_increment == 1 )
                    {
                        $possible_destination = $position_of_choice_to_move - $distance_to_possible_destination ;
                    } else
                    {
                        $possible_destination = $position_of_choice_to_move + $distance_to_possible_destination ;
                    }
                    $actual_choice_at_destination = $actual_choice_in_insertion_rank_sequence_position[ $possible_destination ] ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, possible destination to far side of choice " .  $actual_choice_at_destination . "]" } ;


#-----------------------------------------------
#  Calculate the increase -- or decrease if
#  negative -- in the sequence score that
#  would occur if the unsorted choice was to be
#  moved to the specified destination (within
#  the sorted portion).  The subset sums already
#  include the tally counts that apply to any
#  already-checked positions between the moved
#  choice and the target choice.
#  This approach speeds up the calculation
#  time compared to fully calculating each
#  sequence score from scratch.

                    $tally_adjusted_choice_for_choice_to_move = $global_adjusted_choice_for_actual_choice[ $actual_choice_to_move ] ;
                    $tally_adjusted_choice_for_choice_at_destination = $global_adjusted_choice_for_actual_choice[ $actual_choice_at_destination ] ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[tally choice numbers: " . $actual_choice_to_move . " (" . $tally_adjusted_choice_for_choice_to_move . ") --> " . $actual_choice_at_destination . " (" . $tally_adjusted_choice_for_choice_at_destination . ")]" } ;
                    if ( $tally_adjusted_choice_for_choice_to_move < $tally_adjusted_choice_for_choice_at_destination )
                    {
                        $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $tally_adjusted_choice_for_choice_to_move ] + $tally_adjusted_choice_for_choice_at_destination ;
                        if ( $direction_increment == 1 )
                        {
                            $tally_choice_to_move_over_choice_at_destination = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                            $tally_choice_at_destination_over_choice_to_move = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                        } else
                        {
                            $tally_choice_to_move_over_choice_at_destination = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                            $tally_choice_at_destination_over_choice_to_move = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                        }
                    } else
                    {
                        $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $tally_adjusted_choice_for_choice_at_destination ] + $tally_adjusted_choice_for_choice_to_move ;
                        if ( $direction_increment == 1 )
                        {
                            $tally_choice_to_move_over_choice_at_destination = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                            $tally_choice_at_destination_over_choice_to_move = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                        } else
                        {
                            $tally_choice_to_move_over_choice_at_destination = $global_tally_first_over_second_in_pair[ $pair_counter ] ;
                            $tally_choice_at_destination_over_choice_to_move = $global_tally_second_over_first_in_pair[ $pair_counter ] ;
                        }
                    }
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[tallies: " . $tally_choice_to_move_over_choice_at_destination . "  " . $tally_choice_at_destination_over_choice_to_move . "]" } ;
                    $score_increase += $tally_choice_to_move_over_choice_at_destination - $tally_choice_at_destination_over_choice_to_move ;


#-----------------------------------------------
#  Keep track of which destination position
#  would increase the sequence score by the
#  largest positive amount, and regard that as
#  the expected destination.
#  If the choice being moved is at the same
#  ranking level as another choice -- because
#  it has the same sequence score -- then move
#  the choice to the higher level (left-most
#  position) so that the choices skip over
#  each other, which is the characteristic
#  that is used to keep track of equal
#  rankings.

                    if ( $score_increase > 0 )
                    {
                        $pass_count_at_last_score_increase = $sort_pass_counter ;
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[new highest score reached]" } ;
                    }
                    if ( $score_increase >= 0 )
                    {
                        if ( $score_increase > $largest_subset_sum )
                        {
                            $largest_subset_sum = $score_increase ;
                            $actual_destination = $possible_destination ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[new largest subset sum is " . $largest_subset_sum . "]\n" } ;
                        } elsif ( $score_increase == $largest_subset_sum )
                        {
                            $actual_destination = $possible_destination ;
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[equal tally sums, will move choice to farthest position]\n" } ;
                        } else
                        {
                            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[current subset sum (" . $score_increase . ") is not largest]\n" } ;
                        }
                    } else
                    {
                        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[subset sum (" . $score_increase . ") is negative]\n" } ;
                    }


#-----------------------------------------------
#  Repeat the loop that checks each position in
#  the sorted list as a possible destination for
#  the choice being moved.

                }


#-----------------------------------------------
#  If the choice should remain where it is, skip
#  over the next few sections of code (that
#  would move the choice).
#  After the choices have stabilized into a
#  sorted sequence, this lack of movement will
#  be typical because a "move" from the
#  unsorted segment to the sorted segment does
#  not involve a change in the sequence position,
#  just a change in the boundary between the
#  sorted and sorted segments (which are
#  adjacent).

                if ( $position_of_choice_to_move == $actual_destination )
                {
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, no need to move choice " . $actual_choice_to_move . "]\n" } ;
                } else
                {


#-----------------------------------------------
#  Move the choice to the sequence position that
#  produces the biggest increase in the overall
#  sequence score.
#  For the choices being skipped over (by the
#  choice being moved), update their highest
#  or lowest sequence position value -- if the
#  move involves moving them outside of their
#  previous range.

                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in sort-pass loop, need to move choice " . $actual_choice_to_move . " from position " . $position_of_choice_to_move . " to position " . $actual_destination . "]\n" } ;
                    $count_of_sequences_with_same_highest_score ++ ;
                    $sort_pass_count_at_last_move = $sort_pass_counter ;
                    if ( $direction_increment == 1 )
                    {
                        $number_of_choices_to_shift = $position_of_choice_to_move - $actual_destination ;
                    } else
                    {
                        $number_of_choices_to_shift = $actual_destination - $position_of_choice_to_move ;
                    }
                    for ( $position_number = 1 ; $position_number <= $number_of_choices_to_shift ; $position_number ++ )
                    {
                        if ( $direction_increment == 1 )
                        {
                            $from_position = $position_of_choice_to_move - $position_number ;
                            $to_position = $from_position + 1 ;
                        } else
                        {
                            $from_position = $position_of_choice_to_move + $position_number ;
                            $to_position = $from_position - 1 ;
                        }
                        $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $from_position ] ;
                        $actual_choice_in_insertion_rank_sequence_position[ $to_position ] = $actual_choice ;
                        $adjusted_choice = $local_adjusted_choice_for_actual_choice[ $actual_choice ] ;
                        if ( $to_position > $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] )
                        {
                            $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $to_position ;
                            $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice ] = $sort_pass_counter ;
                        }
                        if ( $to_position < $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] )
                        {
                            $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $to_position ;
                            $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice ] = $sort_pass_counter ;
                        }
                    }
                    $actual_choice_in_insertion_rank_sequence_position[ $actual_destination ] = $actual_choice_to_move ;


#-----------------------------------------------
#  For the choice being moved, update its highest
#  or lowest sequence position value -- if this
#  move involves moving it outside of its
#  previous range.
#  The highest-and-lowest position information
#  is needed to determine which choices are
#  repeatedly skipping over each other, and that
#  indicates which choices are tied, and at what
#  ranking levels.

                    if ( $actual_destination < $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] )
                    {
                        $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] = $actual_destination ;
                        $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice_to_move ] = $sort_pass_counter ;
                    }
                    if ( $actual_destination > $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] )
                    {
                        $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] = $actual_destination ;
                        $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice_to_move ] = $sort_pass_counter ;
                    }


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.

                    if ( $true_or_false_log_details == $global_true )
                    {
                        if ( $local_adjusted_choice_count == $global_adjusted_choice_count )
                        {
                            for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
                            {
                                $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
                                $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
                            }
                            &internal_view_matrix( ) ;
                            if ( $global_sequence_score > $global_sequence_score_using_insertion_sort_method )
                            {
                                $global_sequence_score_using_insertion_sort_method = $global_sequence_score ;
                                print LOGOUT "\n[insertion sort, new sequence score is: " . $global_sequence_score_using_insertion_sort_method . "]\n" ;
                            }
                        } else
                        {
                            print LOGOUT "\n[insertion sort, current sub-sort sequence is: " ;
                            for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
                            {
                                $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
                                print LOGOUT $actual_choice . " , " ;
                            }
                            print LOGOUT "]\n" ;
                        }
                    }


#-----------------------------------------------
#  Finish skipping the code that moves a choice
#  to a new sequence position.

                }


#-----------------------------------------------
#  Repeat the loop that moves each unsorted choice
#  into the sorted segment.

            }


#-----------------------------------------------
#  For debugging, display the highest and lowest
#  rankings -- unless the values are about to be
#  reset.

            if ( $true_or_false_log_details == $global_true )
            {
                if ( $sort_pass_counter != $pass_count_at_last_score_increase )
                {
                    print LOGOUT "\n" ;
                    for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
                    {
                        $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                        $highest_rank = $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] ;
                        $lowest_rank = $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] ;
                        print LOGOUT "[insertion sort, in sort-pass loop, choice " . $actual_choice . " has been at highest " . $highest_rank . " and lowest " . $lowest_rank . "]\n" ;
                    }
                }
            }


#-----------------------------------------------
#  If the total score increased during this
#  sorting pass, reset the highest and lowest
#  sequence-position values according to the
#  current sort order, and reset the flag
#  that might have indicated a stable condition.

            if ( $sort_pass_counter == $pass_count_at_last_score_increase )
            {
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "\n[insertion sort, in sort-pass loop, score increased during this pass, so initializing highest and lowest positions for all choices]\n" } ;
                $reached_stable_condition_at_pass_count = 0 ;
                $count_of_sequences_with_same_highest_score = 0 ;
                for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
                {
                    $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
                    $adjusted_choice = $local_adjusted_choice_for_actual_choice[ $actual_choice ] ;
                    $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $sequence_position ;
                    $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] = $sequence_position ;
                }
            }


#-----------------------------------------------
#  Log the movement of any choices during this
#  sorting pass.

            if ( $true_or_false_log_details == $global_true )
            {
                if ( $sort_pass_count_at_last_move == $sort_pass_counter )
                {
                    print LOGOUT "\n[insertion sort, in sort-pass loop, at least one choice moved during this sorting pass]\n" ;
                } else
                {
                    print LOGOUT "\n[insertion sort, in sort-pass loop, no choices moved during this sorting pass]\n" ;
                }

                for ( $adjusted_choice = 1 ; $adjusted_choice <= $local_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $pass_number = $pass_number_at_last_rerank_for_adjusted_choice[ $adjusted_choice ] ;
                    if ( $pass_number == $sort_pass_counter )
                    {
                        $actual_choice = $local_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                        print LOGOUT "[insertion sort, in sort-pass loop, choice " . $actual_choice . " moved during this pass]\n" ;
                    }
                }
                print LOGOUT "\n" ;
            }


#-----------------------------------------------
#  Repeat the loop that sorts the choices (until
#  they stabilize).

        }


#-----------------------------------------------
#  Log the ending sequence.

        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "\n[insertion sort, in main loop, ending sequence is: " ;
            for ( $sequence_position = 1 ; $sequence_position <= $local_adjusted_choice_count ; $sequence_position ++ )
            {
                $actual_choice = $actual_choice_in_insertion_rank_sequence_position[ $sequence_position ] ;
                print LOGOUT $actual_choice . " , " ;
            }
            print LOGOUT "]\n" ;
        }


#-----------------------------------------------
#  If only one sequence has the highest sequence
#  score, do not do any sub-set sorting (to
#  ensure finding correct most-popular choice).

        if ( ( $main_loop_count == 1 ) && ( $count_of_sequences_with_same_highest_score == 1 ) )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, only one sequence has highest sequence score, so exiting main loop]\n" } ;
            last ;
        }


#-----------------------------------------------
#  If this is the final stage, put the highest-
#  ranked choice (or choices) back into the full
#  sequence, at the highest ranking.
#  Also adjust the values that keep track of
#  each choice's highest and lowest positions.

        if ( $final_stage_reached_at_main_loop_count == $main_loop_count )
        {
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, wrapping up final stage]\n" } ;
            $source_sequence_position = $local_adjusted_choice_count ;
            for ( $destination_sequence_position = $global_adjusted_choice_count ; $destination_sequence_position >= $global_adjusted_choice_count - $local_adjusted_choice_count + 1 ; $destination_sequence_position -- )
            {
                $actual_choice_to_move = $actual_choice_in_insertion_rank_sequence_position[ $source_sequence_position ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[lower choice " . $actual_choice_to_move . " is restored to adjusted choice " . $adjusted_choice_to_move . "]\n" } ;
                $actual_choice_in_insertion_rank_sequence_position[ $destination_sequence_position ] = $actual_choice_to_move ;
                $adjusted_choice_to_move = $global_adjusted_choice_for_actual_choice[ $actual_choice_to_move ] ;
                $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] += $global_adjusted_choice_count - $local_adjusted_choice_count ;
                $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] += $global_adjusted_choice_count - $local_adjusted_choice_count ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[choice " . $actual_choice_to_move . " has highest sequence position " . $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] . " and lowest sequence position " . $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice_to_move ] . "]\n" } ;
                $source_sequence_position -- ;
            }
            for ( $destination_sequence_position = 1 ; $destination_sequence_position <= $count_of_highest_ranked_choices ; $destination_sequence_position ++ )
            {
                $choice_counter = $destination_sequence_position ;
                $actual_choice = $highest_ranked_actual_choice_at_count[ $choice_counter ] ;
                $actual_choice_in_insertion_rank_sequence_position[ $destination_sequence_position ] = $actual_choice ;
                $adjusted_choice = $global_adjusted_choice_for_actual_choice[ $actual_choice ] ;
                if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[highest choice " . $actual_choice . " is restored to adjusted choice " . $adjusted_choice . "]\n" } ;
            }
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, in main loop, done with final stage, exiting main loop]\n" } ;
            last ;
        }


#-----------------------------------------------
#  Repeat the loop to do the next stage of
#  calculations.

    }


#-----------------------------------------------
#  If, at the end of the multiple sorting
#  passes, any of the choices were still moving,
#  this indicates that some choices are tied (at
#  the same ranking level), so determine
#  which choices are tied, and at which levels.
#  If no choices have moved, use the following
#  code anyway because it normalizes the
#  ranking levels.
#  For each choice, multiply the sum of
#  the highest and lowest ranking level by
#  a constant (10 times the number of choices minus one)
#  and convert the result to an integer.
#  Use these "averaged scaled integerized"
#  ranking levels to calculate normalized
#  (and normal) ranking levels, where
#  choices are ranked at the same level if
#  they have the same
#  averaged-scaled-integerized values.

    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, calculating averaged-scaled-integerized levels]\n" } ;
    $scale_value = 10 * ( $global_adjusted_choice_count - 1 ) ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $highest_rank = $highest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] ;
        $lowest_rank = $lowest_insertion_sort_sequence_position_for_actual_choice[ $actual_choice ] ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, done, choice " . $actual_choice . " has been at highest rank level " . $highest_rank . " and lowest rank level " . $lowest_rank . "]\n" } ;
        $special_ranking_level = int( ( $highest_rank + $lowest_rank ) * $scale_value ) ;
        $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] = $special_ranking_level ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, choice " . $actual_choice . " at special rank level " . $special_ranking_level . "]\n" } ;
    }
    &normalize_ranking( ) ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, final normalized ranking levels]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $ranking_level = $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] ;
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] = $ranking_level ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[insertion sort, choice " . $actual_choice . " at normalized rank level " . $ranking_level . "]\n" } ;
    }


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.
#  Use the sequence that was determined when
#  normalization was done.

    if ( $true_or_false_log_details == $global_true )
    {
        print LOGOUT "[insertion sort, final insertion-sort popularity ranking:]\n" ;
        &internal_view_matrix( ) ;
        if ( $global_sequence_score > $global_sequence_score_using_insertion_sort_method )
        {
            $global_sequence_score_using_insertion_sort_method = $global_sequence_score ;
            print LOGOUT "\n[insertion sort, new sequence score is: " . $global_sequence_score_using_insertion_sort_method . "]\n" ;
        }
    }


#-----------------------------------------------
#  Log the calculated ranking levels.

    if ( $true_or_false_log_details == $global_true )
    {
        print LOGOUT "[insertion sort, final results:]\n" ;
        for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
        {
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            print LOGOUT "[  choice " . $actual_choice . " is at ranking level " . $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] . "]\n" ;
        }
    }


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[insertion sort, exiting calc_votefair_insertion_sort_popularity_rank subroutine]\n\n" } ;
    return "" ;

}




=head2 calc_all_sequence_scores

(Not exported, for internal use only.)

Calculates VoteFair popularity ranking
results by calculating every sequence score to
find the highest score, and regarding the
sequence (ranking) with the highest score to be
the overall ranking.  For details, see
www.VoteFair.org or Wikipedia's
"Condorcet-Kemeny method" article (which
currently redirects to the "Kemeny-Young method"
article) or the book titled "Ending The Hidden
Unfairness In U.S. Elections".

If multiple sequences have the same highest score,
calculate the average sequence position for each
choice (but only for the sequences that have the
highest score), and then normalize (remove gaps
from) those rankings.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            calc_all_sequence_scores
#-----------------------------------------------
#-----------------------------------------------

sub calc_all_sequence_scores
{

    my $score ;
    my $highest_score ;
    my $actual_choice ;
    my $adjusted_choice ;
    my $first_choice_number ;
    my $second_choice_number ;
    my $position_in_sequence ;
    my $position_to_shift ;
    my $sequence_count ;
    my $sequence_position ;
    my $removal_position ;
    my $pair_counter ;
    my $counter ;
    my $sequence_info ;
    my $ranking_info ;
    my $ranking_changes_info ;
    my $score_info ;
    my $main_loop_count ;
    my $ranking_level ;
    my $true_or_false_continue_loop ;
    my $true_or_false_log_details ;
    my $true_or_false_log_all_sequences_details ;
    my $top_down_rank ;
    my $bottom_up_rank ;
    my $average ;
    my $count_of_same_highest_score ;

    my @sequence_count_at_position ;
    my @maximum_sequence_count_at_position ;
    my @sequence_position_for_adjusted_choice ;
    my @count_of_sequences_with_highest_ranking_for_adjusted_choice ;
    my @count_of_sequences_with_lowest_ranking_for_adjusted_choice ;
    my @sum_of_rankings_at_highest_score_for_adjusted_choice ;
    my @count_of_rankings_at_highest_score_for_adjusted_choice ;
    my @choice_in_remainder_position ;


#-----------------------------------------------
#  Hide or show the details in the log file.

    $true_or_false_log_details = $global_true ;
    $true_or_false_log_all_sequences_details = $global_false ;
    if ( $global_logging_info == $global_false )
    {
        $true_or_false_log_details = $global_false ;
    }
    if ( $true_or_false_log_details == $global_false )
    {
        $true_or_false_log_all_sequences_details = $global_false ;
    }
    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[all scores, beginning calc_all_sequence_scores subroutine]\n\n" ;
        if ( $true_or_false_log_details == $global_true )
        {
            print LOGOUT "[all scores, some details shown (change flag value to hide details)]\n" ;
            if ( $true_or_false_log_all_sequences_details == $global_false )
            {
                print LOGOUT "[all scores, details for every sequence hidden (change flag value to view details)]\n" ;
            }
        } else
        {
            print LOGOUT "[all scores, details hidden (change flag value to view details)]\n" ;
        }
    }


#-----------------------------------------------
#  In case of an early error, initialize the
#  ranking of each choice -- to zero.

    for ( $adjusted_choice = 1; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_popularity_ranking_for_actual_choice[ $actual_choice ] = 0 ;
    }


#-----------------------------------------------
#  If there are not at least two choices,
#  there is a program bug because that should
#  have already been checked.

    if ( $global_adjusted_choice_count < 2 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[all scores, ERROR: number of (adjusted) choices is less than two]\n" } ;
        warn "program bug, there was an attempt to rank only a single choice" ;
        return ;
    }


#-----------------------------------------------
#  If there are too many choices, indicate an
#  error.

    if ( $global_adjusted_choice_count > $global_check_all_scores_choice_limit )
    {
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " has-too-many-choices-for-this-software-version-so-VoteFair-calculations-cannot-be-done" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[all scores, ERROR: number of (adjusted) choices exceeds limit (" . $global_check_all_scores_choice_limit . ")]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Initialize the ranking information that is
#  tracked for each choice.
#  Initialize the counter that counts how many
#  sequences have the same highest sequence
#  score.  Also initialize the sum that adds the
#  ranking-sequence levels at which a highest
#  sequence score occurs.  If there is only one
#  sequence with the highest score, this sum
#  will equal that sequence position.
#
#  Also, for comparison purposes, initialize
#  two other rank-tracking values.  One such
#  value tracks the highest ranking
#  encountered (in a highest-score sequence),
#  and the other value tracks the lowest
#  ranking encountered (in a highest-score
#  sequence).  Also initialize the counts of
#  how many sequences have these highest or
#  lowest rankings.

    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[all scores, beginning to calculate VoteFair popularity results]\n" } ;
    for ( $adjusted_choice = 1; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $count_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] = 0 ;
        $sum_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] = 0 ;
        $global_adjusted_ranking_for_adjusted_choice_bottom_up_version[ $adjusted_choice ] = $global_adjusted_choice_count + 1 ;
        $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] = 0 ;
        $count_of_sequences_with_highest_ranking_for_adjusted_choice[ $adjusted_choice ] = 0 ;
        $count_of_sequences_with_lowest_ranking_for_adjusted_choice[ $adjusted_choice ] = 0 ;
    }


#-----------------------------------------------
#  Calculate the number of possible sequences to
#  check, and log this number.

    if ( $true_or_false_log_details == $global_true )
    {
        $sequence_count = 1 ;
        for ( $counter = 2 ; $counter <= $global_adjusted_choice_count ; $counter ++ )
        {
            $sequence_count = $sequence_count * $counter ;
        }
        print LOGOUT "[all scores, number of sequences to check is " . $sequence_count . "]" ;
    }


#-----------------------------------------------
#  Initialize a list of numbers that will be
#  used to cycle through all the possible
#  sequences.  Also specify the maximum count
#  value that is allowed for each position in that list.

    for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
    {
        $sequence_count_at_position[ $sequence_position ] = 1 ;
        $maximum_sequence_count_at_position[ $sequence_position ] = $global_adjusted_choice_count - $sequence_position + 1 ;
    }
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "\n" } ;


#-----------------------------------------------
#  Begin a loop that checks each possible
#  sequence, in terms of which choice is first,
#  which is second, etc.

    $main_loop_count = 0 ;
    $true_or_false_continue_loop = $global_true ;
    $highest_score = 0 ;
    $count_of_same_highest_score = 0 ;
    while ( $true_or_false_continue_loop == $global_true )
    {
        $main_loop_count ++ ;
        if ( $main_loop_count > 10000 )
        {
            $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " has-too-many-choices-so-plurality-counting-done" . "\n-----\n\n" ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[all scores, Warning: Too many choices (" . $global_adjusted_choice_count . "), so only plurality results calculated]\n" } ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[all scores, exiting main loop early]" } ;
            return ;
        }


#-----------------------------------------------
#  Initialize some debug text strings.

        $sequence_info = " sequence: " ;
        $ranking_info = "  ranking: " ;
        $ranking_changes_info = "" ;
        @global_log_info_choice_at_position = ( ) ;


#-----------------------------------------------
#  Put all the choice numbers into a
#  number-ordered list named
#  "choice_in_remainder_position".

        for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
        {
            $adjusted_choice = $sequence_position ;
            $choice_in_remainder_position[ $sequence_position ] = $adjusted_choice ;
        }


#-----------------------------------------------
#  Generate the current sequence of choice numbers.
#  Put them in the list named
#  "sequence_position_for_adjusted_choice".
#  Base the sequence on the counters in the
#  counter list named "sequence_count_at_position".
#  While creating this, use the
#  "choice_in_remainder_position" list
#  to keep track of which choice numbers have
#  not yet been used in the sequence.

        for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
        {
            $removal_position = $sequence_count_at_position[ $sequence_position ] ;
            $adjusted_choice = $choice_in_remainder_position[ $removal_position ] ;
            $sequence_info .= $adjusted_choice . " , " ;
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
            $sequence_position_for_adjusted_choice[ $adjusted_choice ] = $sequence_position ;
            for ( $position_to_shift = $removal_position ; $position_to_shift <= $global_adjusted_choice_count - $sequence_position ; $position_to_shift ++ )
            {
                $choice_in_remainder_position[ $position_to_shift ] = $choice_in_remainder_position[ $position_to_shift + 1 ] ;
            }
        }


#-----------------------------------------------
#  Calculate the score for the current sequence.
#  It equals the sum of all the pairwise counts
#  (tally-table numbers) that apply to the
#  sequence.

        $score = 0 ;
        for ( $pair_counter = 1 ; $pair_counter <= $global_pair_counter_maximum ; $pair_counter ++ )
        {
            $first_choice_number = $global_adjusted_first_choice_number_in_pair[ $pair_counter ] ;
            $second_choice_number = $global_adjusted_second_choice_number_in_pair[ $pair_counter ] ;
            if ( $sequence_position_for_adjusted_choice[ $first_choice_number ] < $sequence_position_for_adjusted_choice[ $second_choice_number ] )
            {
                $score += $global_tally_first_over_second_in_pair[ $pair_counter ] ;
            } else
            {
                $score += $global_tally_second_over_first_in_pair[ $pair_counter ] ;
            }
        }
        $score_info = "score = " . $score ;


#-----------------------------------------------
#  If the new score exceeds the previously
#  highest score, save this sequence as (so far)
#  having the highest score.
#  Also use the current sequence position as the
#  ranking position of each choice.

        if ( $score >= $highest_score )
        {
            if ( $score > $highest_score )
            {
                $highest_score = $score ;
                $count_of_same_highest_score = 1 ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $sequence_position = $sequence_position_for_adjusted_choice[ $adjusted_choice ] ;
                    $count_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] = 1 ;
                    $sum_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] = $sequence_position ;
                    $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] = $sequence_position ;
                    $global_adjusted_ranking_for_adjusted_choice_bottom_up_version[ $adjusted_choice ] = $sequence_position ;
                    $count_of_sequences_with_highest_ranking_for_adjusted_choice[ $adjusted_choice ] = 1 ;
                    $count_of_sequences_with_lowest_ranking_for_adjusted_choice[ $adjusted_choice ] = 1 ;
                    $ranking_info .= $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] . " ; " ;
                    $ranking_changes_info .= "      ranking of " . $adjusted_choice . " set to " . $sequence_position . "\n" ;
                }


#-----------------------------------------------
#  If the new score equals the previously highest
#  score, adjust the ranking level of any choices
#  that are in less-preferred (for top-down) or
#  most-preferred (for bottom-up) ranking positions
#  compared to the previous sequence with the
#  same highest score.

            } else
            {
                $count_of_same_highest_score ++ ;
                for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
                {
                    $sequence_position = $sequence_position_for_adjusted_choice[ $adjusted_choice ] ;
                    $ranking_info .= $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] . " , " ;
                    $sum_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] += $sequence_position ;
                    $count_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] ++ ;
                    if ( $sequence_position > $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] )
                    {
                        $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] = $sequence_position ;
                        $ranking_changes_info .= "      top-down ranking of " . $adjusted_choice . " reduced to " . $sequence_position . "\n" ;
                        $count_of_sequences_with_lowest_ranking_for_adjusted_choice[ $adjusted_choice ] ++ ;
                    }
                    if ( $sequence_position < $global_adjusted_ranking_for_adjusted_choice_bottom_up_version[ $adjusted_choice ] )
                    {
                        $global_adjusted_ranking_for_adjusted_choice_bottom_up_version[ $adjusted_choice ] = $sequence_position ;
                        $ranking_changes_info .= "      bottom-up ranking of " . $adjusted_choice . " increased to " . $sequence_position . "\n" ;
                        $count_of_sequences_with_highest_ranking_for_adjusted_choice[ $adjusted_choice ] ++ ;
                    }
                }
            }

#-----------------------------------------------
#  If the current score equals or exceeds the
#  previously highest score, log this information.

            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                $sequence_position = $sequence_position_for_adjusted_choice[ $adjusted_choice ] ;
                $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
            }
            if ( ( $true_or_false_log_details == $global_true ) && ( $global_adjusted_choice_count <= 8 ) )
            {
                print LOGOUT "[all scores, sequence  " ;
                for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
                {
                    $actual_choice = $global_log_info_choice_at_position[ $sequence_position ] ;
                    print LOGOUT $actual_choice . " , " ;
                }
                print LOGOUT "  has high score of " . $highest_score . "]\n" ;
                if ( $main_loop_count == 1 )
                {
                    $global_sequence_score_using_all_scores_method = 0 ;
                }
                print LOGOUT "[all scores, current top or score-matched ranking:]\n" ;
                &internal_view_matrix( ) ;
                $global_sequence_score_using_all_scores_method = $global_sequence_score ;
            }


#-----------------------------------------------
#  Finish skipping over the sections that handle
#  a highest score.

        }


#-----------------------------------------------
#  For debugging, display some key info -- for
#  every sequence checked.

        if ( ( $true_or_false_log_all_sequences_details == $global_true ) && ( $global_adjusted_choice_count <= 8 ) )
        {
            print LOGOUT $sequence_info . "  " . $score_info . "\n" ;
            print LOGOUT $ranking_info . "\n" ;
            print LOGOUT $ranking_changes_info . "\n" ;
        }


#-----------------------------------------------
#  Update the counters that are used to identify
#  the next sequence to be considered.
#  These counters are also used to identify when
#  all the sequences have been checked.

        $position_in_sequence = $global_adjusted_choice_count - 1 ;
        while ( $position_in_sequence > 0 )
        {
            $sequence_count_at_position[ $position_in_sequence ] ++ ;
            if ( $sequence_count_at_position[ $position_in_sequence ] > $maximum_sequence_count_at_position[ $position_in_sequence ] )
            {
                $sequence_count_at_position[ $position_in_sequence ] = 1 ;
                $position_in_sequence -- ;
                if ( $position_in_sequence == 0 )
                {
                    $true_or_false_continue_loop = $global_false ;
                }
            } else
            {
                $position_in_sequence = 0 ;
            }
        }


#-----------------------------------------------
#  Repeat the loop to check the next sequence.

    }


#-----------------------------------------------
#  For each choice, calculate the average
#  ranking for the sequences in which the score
#  was the highest score.  However, scale those
#  averages by the number of adjusted choices
#  minus one so that integer numbers can be
#  used.  Then normalize those values to produce
#  the final ranking.  Also, log the highest and
#  lowest ranking positions -- for the sequences
#  that have the same highest sequence score.

    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[all scores, count of same highest score is " . $count_of_same_highest_score . "]\n" } ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[all scores, top-down and bottom-up and scaled-average values:]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $top_down_rank = $global_adjusted_ranking_for_adjusted_choice_top_down_version[ $adjusted_choice ] ;
        $bottom_up_rank = $global_adjusted_ranking_for_adjusted_choice_bottom_up_version[ $adjusted_choice ] ;
        $average = int( ( ( $global_adjusted_choice_count - 1 ) * $sum_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] ) / $count_of_rankings_at_highest_score_for_adjusted_choice[ $adjusted_choice ] ) ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " , top-down ranking is " . $top_down_rank . " (for " . $count_of_sequences_with_highest_ranking_for_adjusted_choice[ $adjusted_choice ] . " scores) , bottom-up ranking is " . $bottom_up_rank . " (for " . $count_of_sequences_with_lowest_ranking_for_adjusted_choice[ $adjusted_choice ] . " scores) , scaled average " . $average . "]\n" } ;
        $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] = $average ;
    }
    &normalize_ranking( ) ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[all scores, final normalized results:]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $ranking_level = $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] ;
        $global_popularity_ranking_for_actual_choice[ $actual_choice ] = $ranking_level ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[  choice " . $actual_choice . " is at top-down popularity level " . $ranking_level  . "]\n" } ;
    }


#-----------------------------------------------
#  For debugging, display the tally numbers in
#  an array/matrix arrangement.
#  Use the sequence that was determined when
#  normalization was done.

    $true_or_false_log_details = $global_true ;
    if ( $true_or_false_log_details == $global_true )
    {
        print LOGOUT "[all scores, final popularity ranking:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[all scores, exiting calc_all_sequence_scores subroutine]\n\n" } ;
    return 1 ;

}




=head2 compare_popularity_results

(Not exported, for internal use only.)

Compares the results of different methods for
calculating VoteFair popularity ranking.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            compare_popularity_results
#-----------------------------------------------
#-----------------------------------------------

sub compare_popularity_results
{

    my $actual_choice ;
    my $adjusted_choice ;
    my $sequence_position ;
    my $ranking_level ;
    my $ranking_level_official ;
    my $comparison_of_methods_table ;
    my $ranking_level_choice_specific_pairwise_score ;
    my $ranking_level_insertion_sort ;
    my $possible_text_insertion_sort_not_the_same ;
    my $possible_text_choice_specific_pairwise_score_not_the_same ;

    my @actual_choice_at_popularity_list_sequence_position ;


#-----------------------------------------------
#  Sort the official ranking results into a list
#  that is used when listing choice rankings,
#  which means that within the same ranking,
#  a lower choice number appears before a higher
#  choice number.

    $sequence_position = 1 ;
    for ( $ranking_level = 0 ; $ranking_level <= $global_adjusted_choice_count ; $ranking_level ++ )
    {
        for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
        {
            $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
            if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == $ranking_level )
            {
                $actual_choice_at_popularity_list_sequence_position[ $sequence_position ] = $actual_choice ;
                $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
                $sequence_position ++ ;
            }
        }
    }


#-----------------------------------------------
#  Log a display of the tally numbers in
#  an array version.

    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[compare pop results, ordered pairwise counts:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  Convert the tally numbers into percentages,
#  and display those values.

    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[compare pop results, total vote count is " . $global_current_total_vote_count . "]\n" ;
        $global_scale_for_logged_pairwise_counts = 100 / $global_current_total_vote_count ;
        print LOGOUT "[compare pop results, pairwise counts as percent numbers (if only scaled by total votes):]\n" ;
        &internal_view_matrix( ) ;
        $global_scale_for_logged_pairwise_counts = 1.0 ;
    }


#-----------------------------------------------
#  As a check, compare the results of the
#  different ranking calculations.
#  Sort the results by popularity.

    if ( not( defined( $global_comparison_count ) ) )
    {
        $global_comparison_count = 0 ;
    }
    $global_comparison_count ++ ;
    if ( not( defined( $global_not_same_count ) ) )
    {
        $global_not_same_count = 0 ;
    }
    $possible_text_insertion_sort_not_the_same = "InsSrt same" ;
    $possible_text_choice_specific_pairwise_score_not_the_same = "CSPS same" ;
    $comparison_of_methods_table = "[compare pop results, case " . $global_case_number . " , question " . $global_question_number . " , rank type = " . $global_ranking_type_being_calculated . "]\n" ;
    $comparison_of_methods_table .= "[compare pop results, columns: official, insertion, estimated]\n" ;
    for ( $sequence_position = 1 ; $sequence_position <= $global_adjusted_choice_count ; $sequence_position ++ )
    {
        $actual_choice = $actual_choice_at_popularity_list_sequence_position[ $sequence_position ] ;
        $adjusted_choice = $global_adjusted_choice_for_actual_choice[ $actual_choice ] ;
        $ranking_level_official = $global_popularity_ranking_for_actual_choice[ $actual_choice ] ;
        $ranking_level_choice_specific_pairwise_score = $global_choice_score_popularity_rank_for_actual_choice[ $actual_choice ] ;
        $ranking_level_insertion_sort = $global_insertion_sort_popularity_rank_for_actual_choice[ $actual_choice ] ;
        $comparison_of_methods_table .= "[choice " . sprintf( "%2d" , $actual_choice ) . " at levels " . $ranking_level_official . " , " . $ranking_level_insertion_sort . " , " . $ranking_level_choice_specific_pairwise_score . "]" ;
        if ( $ranking_level_official != $ranking_level_insertion_sort )
        {
            $possible_text_insertion_sort_not_the_same = "InsSrt NOT same" ;
            $comparison_of_methods_table .= " ****** " ;
        }
        if ( $ranking_level_official != $ranking_level_choice_specific_pairwise_score )
        {
            $possible_text_choice_specific_pairwise_score_not_the_same = "CSPS NOT same" ;
            $comparison_of_methods_table .= " ------ " ;
        }
        $comparison_of_methods_table .= "\n" ;
    }
    if ( $possible_text_insertion_sort_not_the_same eq "InsSrt NOT same" )
    {
        $global_not_same_count ++ ;
    }
    $comparison_of_methods_table .= "[" . $possible_text_insertion_sort_not_the_same . "][" . $possible_text_choice_specific_pairwise_score_not_the_same . "][case " . $global_case_number . " question " . $global_question_number . "]\n\n" ;
    if ( $global_logging_info == $global_true ) { print LOGOUT $comparison_of_methods_table . "\n" } ;


#-----------------------------------------------
#  Display a count of how many rankings have
#  been done.

    $global_count_of_popularity_rankings ++ ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[count of popularity rankings: " . $global_count_of_popularity_rankings . "]\n" } ;


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[compare pop results, exiting subroutine]\n" } ;
    return 1 ;

}




=head2 do_full_initialization

(Not exported, for internal use only.)

Initializes all the global values and constants.
It is always done at the beginning of executing
this module.  It is also executed if a new
(second or later) set of cases is calculated.

=cut

#-----------------------------------------------
#-----------------------------------------------
#    do_full_initialization
#-----------------------------------------------
#-----------------------------------------------

sub do_full_initialization
{


#-----------------------------------------------
#  Define true and false constants.

    $global_true = 1 ;
    $global_false = 0 ;


#-----------------------------------------------
#  Resetting logging flag.

    $global_logging_info = $global_true ;


#-----------------------------------------------
#  Define constants.

    $global_warning_end = "\n-----\n\n" ;


#-----------------------------------------------
#  Specify defaults.

    $global_default_representation_levels_requested = 6 ;


#-----------------------------------------------
#  Set limits.

    $global_limit_on_popularity_rank_levels = 20 ;
    $global_limit_on_representation_rank_levels = 6 ;
    $global_maximum_case_number = 9999 ;
    $global_maximum_question_number = 99 ;
    $global_maximum_choice_number = 99 ;
    $global_max_array_length = 5000000 ;
    $global_maximum_twice_highest_possible_score = 999999 ;


#-----------------------------------------------
#  Request that the output file embed negative
#  code numbers into text strings so that the
#  Vote-Info-Split-Join (VISJ) framework can
#  easily combine these results with text that
#  is extracted from EML and XML data (without
#  requiring a separate script/program to
#  convert negative numbers into Dashrep
#  phrases).

    $global_true_or_false_request_dashrep_phrases_in_output = $global_true ;


#-----------------------------------------------
#  Initialize the "always" versions of the
#  requests for specified results.

    $global_true_or_false_always_request_only_plurality_results = $global_false ;
    $global_true_or_false_always_request_no_pairwise_counts = $global_false ;
    $global_true_or_false_always_request_votefair_representation_rank = $global_false ;
    $global_true_or_false_always_request_votefair_party_rank = $global_false ;
    $global_true_or_false_always_request_dashrep_phrases_in_output = $global_false ;


#-----------------------------------------------
#  Initialization of zero and empty values.

    $global_length_of_vote_info_list = 0 ;
    $global_input_pointer_start_next_case = 0 ;
    $global_pointer_to_output_results = 0 ;
    $global_case_number = 0 ;
    $global_question_number = 0 ;
    $global_choice_number = 0 ;
    $global_ballot_info_repeat_count = 0 ;
    $global_current_total_vote_count = 0 ;

    $global_output_warning_message = "" ;
    $global_possible_error_message = "" ;
    $global_output_warning_messages_case_or_question_specific = "" ;
    $global_case_specific_warning_begin = "" ;
    $global_question_specific_warning_begin = "" ;


#-----------------------------------------------
#  Clear the logged info flag only if it has not
#  yet been initialized.

    if ( not( defined( $global_logging_info ) ) )
    {
        $global_logging_info = $global_false ;
    }


#-----------------------------------------------
#  Clear all the global values, except the ones
#  that are constants.

    $global_input_pointer_start_next_case = 0 ;
    $global_pointer_to_current_ballot = 0 ;
    $global_length_of_vote_info_list = 0 ;
    $global_pointer_to_output_results = 0 ;
    $global_length_of_result_info_list = 0 ;
    $global_case_number = 0 ;
    $global_previous_case_number = 0 ;
    $global_question_number = 0 ;
    $global_ballot_info_repeat_count = 0 ;
    $global_current_total_vote_count = 0 ;
    $global_ballot_influence_amount = 0 ;
    $global_choice_number = 0 ;
    $global_adjusted_choice_number = 0 ;
    $global_adjusted_choice_count = 0 ;
    $global_full_choice_count = 0 ;
    $global_pair_counter_maximum = 0 ;
    $global_question_count = 0 ;
    $global_choice_count_at_top_popularity_ranking_level = 0 ;
    $global_choice_count_at_full_top_popularity_ranking_level = 0 ;
    $global_choice_count_at_full_second_representation_level = 0 ;
    $global_representation_levels_requested = 0 ;
    $global_number_of_questions_in_current_case = 0 ;
    $global_first_most_popular_actual_choice = 0 ;
    $global_second_most_representative_actual_choice = 0 ;
    $global_actual_choice_at_top_of_full_popularity_ranking = 0 ;
    $global_actual_choice_at_second_representation_ranking = 0 ;
    $global_ranking_type_being_calculated = 0 ;

    $global_combined_case_number_and_question_number = "" ;
    $global_combined_case_number_and_question_number_and_choice_number = "" ;
     $global_pairwise_matrix_text = "" ;
    $global_case_specific_warning_begin = "" ;
    $global_question_specific_warning_begin = "" ;

    $global_true_or_false_tally_table_created = $global_false ;

    @global_vote_info_list = ( ) ;
    @global_output_results = ( ) ;
    @global_plurality_count_for_actual_choice = ( ) ;
    @global_popularity_ranking_for_actual_choice = ( ) ;
    @global_full_popularity_ranking_for_actual_choice = ( ) ;
    @global_representation_ranking_for_actual_choice = ( ) ;
    @global_full_representation_ranking_for_actual_choice = ( ) ;
    @global_party_ranking_for_actual_choice = ( ) ;
    @global_question_count_for_case = ( ) ;
    @global_true_or_false_ignore_case = ( ) ;
    @global_choice_count_for_case_and_question = ( ) ;
    @global_adjusted_choice_for_actual_choice = ( ) ;
    @global_actual_choice_for_adjusted_choice = ( ) ;
    @global_adjusted_first_choice_number_in_pair = ( ) ;
    @global_adjusted_second_choice_number_in_pair = ( ) ;
    @global_using_choice = ( ) ;
    @global_tally_first_over_second_in_pair = ( ) ;
    @global_tally_second_over_first_in_pair = ( ) ;
    @global_tally_first_equal_second_in_pair = ( ) ;
    @global_ballot_preference_for_choice = ( ) ;
    @global_adjusted_ranking_for_adjusted_choice_bottom_up_version = ( ) ;
    @global_adjusted_ranking_for_adjusted_choice_top_down_version = ( ) ;
    @global_pair_counter_offset_for_first_adjusted_choice = ( ) ;
    @global_log_info_choice_at_position = ( ) ;


#-----------------------------------------------
#  If the begin-module actions have not yet
#  been done, begin to do them.

    if ( $global_begin_module_actions_done == $global_false )
    {


#-----------------------------------------------
#  Specify the name of an extra output file
#  that contains a log of actions for the
#  purpose of debugging (or capturing
#  intermediate calculations).

        $global_log_filename = "output_votefair_debug_info.txt" ;


#-----------------------------------------------
#  Open the file for writing log info.

        open ( LOGOUT , ">" . $global_log_filename ) ;


#-----------------------------------------------
#  Specify the name of an extra output file
#  that associates negative code numbers with
#  VISJ hyphenated phrases.

        $global_code_associations_filename = "output_from_vote_calc_sw_visj_codes.txt" ;


#-----------------------------------------------
#  Open the file for writing the code-association
#  information.

        open ( CODEFILE , ">" . $global_code_associations_filename ) ;


#-----------------------------------------------
#  Write definitions of the numeric codes that
#  are used for both input and output.

        &write_numeric_code_definitions( ) ;


#-----------------------------------------------
#  Specify the name of an extra output file
#  that can contain an error message that will
#  be used by the VISJ code.

        $global_error_message_filename = "output_from_vote_calc_sw_visj_possible_error_message.txt" ;


#-----------------------------------------------
#  Finish skipping over the actions that are
#  only done once.

    }


#-----------------------------------------------
#  Indicate the the begin-module actions, and the
#  initializations, have been done.

    $global_begin_module_actions_done = $global_true ;
    $global_intitialization_done = $global_true ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[full initialization done]\n" } ;


#-----------------------------------------------
#  End of initialization.

}




=head2 write_numeric_code_definitions

(Not exported, for internal use only.)

Write to an output file Dashrep definitions that
associate negative code numbers -- that are used
for input data and output results -- with
text-based names for those values.

=cut

#-----------------------------------------------
#-----------------------------------------------
#    write_numeric_code_definitions
#-----------------------------------------------
#-----------------------------------------------

sub write_numeric_code_definitions
{

    my $phrase_name ;
    my $next_code ;
    my $heading_text ;
    my $heading_begin ;
    my $heading_end ;
    my $end_definition ;
    my $text_inverse_part_1 ;
    my $text_inverse_part_2 ;
    my $letters ;


#-----------------------------------------------
#  Write to a separate file the Dashrep-language
#  definitions that associate numeric codes
#  (negative numbers) with Dashrep hyphenated
#  phrases.
#  These codes are used for both the (input)
#  ballot information and the (output) results.
#  Also associate a unique variable name with
#  each code -- for use within this module.

    $heading_begin = "*------------------------------------------------------------\n" ;
    $heading_end = "\n------------------------------------------------------------*\n\n" ;
    $end_definition = "\n-----\n\n\n" ;
    $text_inverse_part_1 = "voteinfo-inverse-" ;
    $text_inverse_part_2 = "-code" . ":\n" . "output-" ;

    print CODEFILE "*-----  Dashrep language -- phrase definitions  -----*\n\n\n" ;
    print CODEFILE "*------------------------------------------------------------\n" ;
    print CODEFILE "See www.Dashrep.org for details about the Dashrep language.\n" ;
    print CODEFILE "------------------------------------------------------------*\n\n\n" ;
    print CODEFILE "*------------------------------------------------------------\n" ;
    print CODEFILE "Vote-Info-Split-Join, code-number associations.\n" ;
    print CODEFILE "------------------------------------------------------------*\n\n\n" ;
    print CODEFILE "*------------------------------------------------------------\n" ;
    print CODEFILE "\n" ;
    print CODEFILE "                     IMPORTANT!                              \n" ;
    print CODEFILE "\n" ;
    print CODEFILE "This file is generated by the vote-counting software,\n" ;
    print CODEFILE "so do not edit this file!  Instead, edit the software that\n" ;
    print CODEFILE "generates this file.\n" ;
    print CODEFILE "------------------------------------------------------------*\n\n\n" ;
    print CODEFILE "dashrep-definitions-begin\n\n" ;
    print CODEFILE "*------------------------------------------------------------\n" ;
    print CODEFILE "Begin Dashrep definitions\n" ;
    print CODEFILE "------------------------------------------------------------*\n\n\n\n\n\n\n" ;

    $next_code = -1 ;
    $heading_text = "Code that identifies the start of all cases" ;
    $global_voteinfo_code_for_start_of_all_cases = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-all-cases" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "startallcases" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of all cases" ;
    $global_voteinfo_code_for_end_of_all_cases = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-all-cases" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "endallcases" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is a case number" ;
    $global_voteinfo_code_for_case_number = $next_code ;
    $phrase_name = "voteinfo-code-for-case-number" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "case" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is a question number" ;
    $global_voteinfo_code_for_question_number = $next_code ;
    $phrase_name = "voteinfo-code-for-question-number" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "q" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that indicates the total number of ballots" ;
    $global_voteinfo_code_for_total_ballot_count = $next_code ;
    $phrase_name = "voteinfo-code-for-total-ballot-count" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "votes" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is the choice count for the current question" ;
    $global_voteinfo_code_for_number_of_choices = $next_code ;
    $phrase_name = "voteinfo-code-for-number-of-choices" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "choices" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of the ballot information for the current case" ;
    $global_voteinfo_code_for_start_of_all_vote_info = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-all-vote-info" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "startcase" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of the ballot information for the current case" ;
    $global_voteinfo_code_for_end_of_all_vote_info = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-all-vote-info" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "endcase" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of information for the next ballot" ;
    $global_voteinfo_code_for_start_of_ballot = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-ballot" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "bal" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of the current ballot" ;
    $global_voteinfo_code_for_end_of_ballot = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-ballot" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "b" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number indicates how many ballots have the same preferences\n(to allow compression for repeated ballot preferences)" ;
    $global_voteinfo_code_for_ballot_count = $next_code ;
    $phrase_name = "voteinfo-code-for-ballot-count" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "x" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is a preference level (that applies to choice numbers that follow)" ;
    $global_voteinfo_code_for_preference_level = $next_code ;
    $phrase_name = "voteinfo-code-for-preference-level" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "pref" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is a choice number" ;
    $global_voteinfo_code_for_choice = $next_code ;
    $phrase_name = "voteinfo-code-for-choice" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "ch" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the previous choice and the next choice are at the same preference level" ;
    $global_voteinfo_code_for_tie = $next_code ;
    $phrase_name = "voteinfo-code-for-tie" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "tie" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair popularity ranking sequence-style results" ;
    $global_voteinfo_code_for_start_of_votefair_popularity_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-popularity-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "popularity-sequence" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair popularity ranking sequence-style results" ;
    $global_voteinfo_code_for_end_of_votefair_popularity_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-popularity-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-pop-seq" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair popularity levels-style ranking results" ;
    $global_voteinfo_code_for_start_of_votefair_popularity_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-popularity-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "popularity-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair popularity levels-style ranking results" ;
    $global_voteinfo_code_for_end_of_votefair_popularity_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-popularity-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-pop-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair representation ranking sequence results" ;
    $global_voteinfo_code_for_start_of_votefair_representation_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-representation-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "rep-seq" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair representation ranking sequence results" ;
    $global_voteinfo_code_for_end_of_votefair_representation_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-representation-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-rep-seq" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair representation ranking levels results" ;
    $global_voteinfo_code_for_start_of_votefair_representation_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-representation-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "rep-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair representation ranking levels results" ;
    $global_voteinfo_code_for_end_of_votefair_representation_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-representation-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-rep-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair party ranking sequence results" ;
    $global_voteinfo_code_for_start_of_votefair_party_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-party-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "party-seq" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair party ranking sequence results" ;
    $global_voteinfo_code_for_end_of_votefair_party_ranking_sequence_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-party-ranking-sequence-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-party-seq" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of VoteFair party ranking levels results" ;
    $global_voteinfo_code_for_start_of_votefair_party_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-votefair-party-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "party-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of VoteFair party ranking levels results" ;
    $global_voteinfo_code_for_end_of_votefair_party_ranking_levels_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-votefair-party-ranking-levels-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-party-levels" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the ranking level (in the output results)" ;
    $global_voteinfo_code_for_ranking_level = $next_code ;
    $phrase_name = "voteinfo-code-for-ranking-level" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "level" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the next lower level of ranking (in the output results)" ;
    $global_voteinfo_code_for_next_ranking_level = $next_code ;
    $phrase_name = "voteinfo-code-for-next-ranking-level" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "next-level" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the sequence results stop here, without all choices being ranked" ;
    $global_voteinfo_code_for_early_end_of_ranking = $next_code ;
    $phrase_name = "voteinfo-code-for-early-end-of-ranking" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-seq-early" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of tally-table counts" ;
    $global_voteinfo_code_for_start_of_tally_table_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-tally-table-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "tallies" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of tally-table counts" ;
    $global_voteinfo_code_for_end_of_tally_table_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-tally-table-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-tallies" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is the first choice number in a pair (in tally-table results)" ;
    $global_voteinfo_code_for_first_choice = $next_code ;
    $phrase_name = "voteinfo-code-for-first-choice" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "ch1" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number is the second choice number in a pair (in tally-table results)" ;
    $global_voteinfo_code_for_second_choice = $next_code ;
    $phrase_name = "voteinfo-code-for-second-choice" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "ch2" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number indicates how many ballots rank the first choice over the second choice" ;
    $global_voteinfo_code_for_tally_first_over_second = $next_code ;
    $phrase_name = "voteinfo-code-for-tally-first-over-second" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "1over2" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies that the next number indicates how many ballots rank the second choice over the first choice" ;
    $global_voteinfo_code_for_tally_second_over_first = $next_code ;
    $phrase_name = "voteinfo-code-for-tally-second-over-first" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "2over1" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the beginning of plurality results" ;
    $global_voteinfo_code_for_start_of_plurality_results = $next_code ;
    $phrase_name = "voteinfo-code-for-start-of-plurality-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-begin" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "plurality" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies the end of plurality results" ;
    $global_voteinfo_code_for_end_of_plurality_results = $next_code ;
    $phrase_name = "voteinfo-code-for-end-of-plurality-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . "ignore-end" . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "end-plurality" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that identifies a plurality count (how many ballots rank the specified choice as their only first choice)" ;
    $global_voteinfo_code_for_plurality_count = $next_code ;
    $phrase_name = "voteinfo-code-for-plurality-count" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "plur" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that indicates this case was skipped (the reason is explained in the warning)" ;
    $global_voteinfo_code_for_skip_case = $next_code ;
    $phrase_name = "voteinfo-code-for-skip-case" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "case-skipped" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that indicates this question was skipped (the reason is explained in the warning)" ;
    $global_voteinfo_code_for_skip_question = $next_code ;
    $phrase_name = "voteinfo-code-for-skip-question" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "question-skipped" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests VoteFair representation ranking results" ;
    $global_voteinfo_code_for_request_votefair_representation_rank = $next_code ;
    $phrase_name = "voteinfo-code-for-request-votefair-representation-rank" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-rep" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests no VoteFair representation ranking results" ;
    $global_voteinfo_code_for_request_no_votefair_representation_rank = $next_code ;
    $phrase_name = "voteinfo-code-for-request-no-votefair-representation-rank" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-no-rep" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests VoteFair party ranking results" ;
    $global_voteinfo_code_for_request_votefair_party_rank = $next_code ;
    $phrase_name = "voteinfo-code-for-request-votefair-party-rank" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-party" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests no VoteFair party ranking results" ;
    $global_voteinfo_code_for_request_no_votefair_party_rank = $next_code ;
    $phrase_name = "voteinfo-code-for-request-no-votefair-party-rank" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-no-party" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests only plurality results" ;
    $global_voteinfo_code_for_request_only_plurality_results = $next_code ;
    $phrase_name = "voteinfo-code-for-request-only-plurality-results" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-plurality-only" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests pairwise counts" ;
    $global_voteinfo_code_for_request_pairwise_counts = $next_code ;
    $phrase_name = "voteinfo-code-for-request-pairwise-counts" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-pairwise-counts" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $next_code -- ;
    $heading_text = "Code that requests no pairwise counts" ;
    $global_voteinfo_code_for_request_no_pairwise_counts = $next_code ;
    $phrase_name = "voteinfo-code-for-request-no-pairwise-counts" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n" . $next_code . $end_definition . $text_inverse_part_1 . sprintf( "%d" , -( $next_code ) ) . $text_inverse_part_2 . $phrase_name . $end_definition ;
    $letters = "request-no-pairwise-counts" ;
    $global_code_number_for_letters{ $letters } = $next_code ;

    $heading_text = "Definition that initializes the error message" ;
    $phrase_name = "output-error-message" ;
    print CODEFILE $heading_begin . $heading_text . $heading_end . $phrase_name . ":\n-----\n\n\n" ;

    print CODEFILE "\n\n\n" . $heading_begin . "End of Dashrep definitions" . $heading_end . "dashrep-definitions-end" . "\n\n" ;

    close ( CODEFILE ) ;


#-----------------------------------------------
#  End of subroutine.

}





=head2 check_vote_info_numbers

(Not exported, for internal use only.)

Checks the validity of the numbers in the vote-info
list, and requests skipping any cases or questions
that contain invalid data.  Also, counts the
number of questions in each case, and counts the
choices in each question.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       check_vote_info_numbers
#-----------------------------------------------
#-----------------------------------------------

sub check_vote_info_numbers
{

    my $status_pair_just_handled ;
    my $current_vote_info_number ;
    my $previous_vote_info_number ;
    my $next_vote_info_number ;
    my $pointer_to_vote_info ;
    my $within_ballots ;
    my $choice_count_for_current_question ;
    my $count_of_choices_marked_for_current_question ;

    my @tally_uses_of_question_number ;
    my @tally_uses_of_choice_number ;
    my @tally_uses_of_question_and_choice_number ;


#-----------------------------------------------
#  Initialization.

    $global_case_specific_warning_begin = "case-" . "0" . "-warning-message:\n" . "word-case-capitalized " . "0" ;
    @tally_uses_of_question_number = ( ) ;
    @tally_uses_of_choice_number = ( ) ;


#-----------------------------------------------
#  In case the debug messages in this subroutine
#  are ignored, write the debug messages
#  collected so far.

    if ( $global_logging_info == $global_true ) { print LOGOUT "\n[about to start checking vote-info numbers]\n\n" } ;


#-----------------------------------------------
#  If the list of numbers is empty, indicate an
#  error.

    if ( $global_length_of_vote_info_list < 2 )
    {
        return "Error: No data was supplied" ;
    }


#-----------------------------------------------
#  Begin a loop that handles each vote-info
#  number in the list.

    $pointer_to_vote_info = 0 ;
    $current_vote_info_number = 0 ;
    $previous_vote_info_number = 0 ;
    $next_vote_info_number = 0 ;
    @tally_uses_of_question_number = ( ) ;
    @tally_uses_of_choice_number = ( ) ;
    @global_true_or_false_ignore_case = ( ) ;
    @global_question_count_for_case = ( ) ;
    @global_choice_count_for_case_and_question = ( ) ;
    $global_case_number = 0 ;
    $global_number_of_questions_in_current_case = 0 ;
    $status_pair_just_handled = $global_false ;
    $global_ballot_info_repeat_count = 0 ;
    $global_current_total_vote_count = 0 ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "\n\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[input info list length = " . $global_length_of_vote_info_list . "]" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[begin checking vote info numbers]\n" } ;
    $global_case_specific_warning_begin = "" ;
    $global_question_specific_warning_begin = "" ;
    for ( $pointer_to_vote_info = 0 ; $pointer_to_vote_info <= $global_length_of_vote_info_list - 1 ; $pointer_to_vote_info ++ )
    {


#-----------------------------------------------
#  If this vote-info number was preceded by a
#  code that already handled this vote-info
#  number, repeat the loop for the next vote-info
#  number.

        if ( $status_pair_just_handled == $global_true )
        {
            $status_pair_just_handled = $global_false ;
            next ;
        }
        $status_pair_just_handled = $global_false ;


#-----------------------------------------------
#  Get the current vote-info number, and adjacent
#  vote-info numbers.

        $current_vote_info_number = $global_vote_info_list[ $pointer_to_vote_info ] ;
#        if ( $global_logging_info == $global_true ) { print LOGOUT "[" . $current_vote_info_number . " is at " . $pointer_to_vote_info . "]" } ;
        if ( $pointer_to_vote_info <= 0 )
        {
            $previous_vote_info_number = 0 ;
        } else
        {
            $previous_vote_info_number = $global_vote_info_list[ $pointer_to_vote_info - 1 ] ;
        }
        if ( $pointer_to_vote_info + 1 > $global_length_of_vote_info_list )
        {
            $next_vote_info_number = 0 ;
        } else
        {
            $next_vote_info_number = $global_vote_info_list[ $pointer_to_vote_info + 1 ] ;
        }


#-----------------------------------------------
#  Ignore a code value of zero.

        if ( $current_vote_info_number == 0 )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring zero value]" } ;
            next ;
        }


#-----------------------------------------------
#  Handle the end of a case.

        if ( ( $current_vote_info_number == $global_voteinfo_code_for_case_number ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_cases ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_vote_info ) )
        {
            if ( $global_case_number > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[case " . $global_case_number . " ending]" } ;
                if ( not( defined( $global_true_or_false_ignore_case[ $global_case_number ] ) ) )
                {
                    $global_true_or_false_ignore_case[ $global_case_number ] = $global_false ;
                }
                if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_false )
                {
                    if ( ( $global_number_of_questions_in_current_case < 1 ) || ( $global_question_count_for_case[ $global_case_number ] < 1 ) )
                    {
                        $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[case-contains-no-questions (case " . $global_case_number . ", new case starting at list position " . $pointer_to_vote_info . ")]" } ;
                        $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " words-contains-no-questions" . $global_warning_end ;
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                    } elsif ( $global_current_total_vote_count < 1 )
                    {
                        $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[case-contains-no-ballots (case " . $global_case_number . ", new case starting at list position " . $pointer_to_vote_info . ")]" } ;
                        $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " words-contains-no-ballots" . $global_warning_end ;
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                    } else
                    {
                        for ( $global_question_number = 1 ; $global_question_number <= $global_question_count_for_case[ $global_case_number ] ; $global_question_number ++ )
                        {
                            if ( $global_logging_info == $global_true ) { print LOGOUT "[question " . $global_question_number . " has " . $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] . " choices]" } ;
                            if ( not( defined( $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] ) ) )
                            {
                                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-count-not-specified (undefined) (question " . $global_question_number . ")]" } ;
                                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " does-not-specify-number-of-choices" . $global_warning_end ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                                last ;
                            } elsif ( $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] == 1 )
                            {
                                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[only-one-choice (question " . $global_question_number . ")]" } ;
                                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " only-one-choice" . $global_warning_end ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                                last ;
                            } elsif ( $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] < 1 )
                            {
                                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[no-choices-found-for-question (case " . $global_case_number . ", question " . $global_question_number . ", end of all vote info at list position " . $pointer_to_vote_info . ")]" } ;
                                $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . ", word-question " . $global_question_number . " has-no-choices" . $global_warning_end ;
                                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                                last ;
                            }
                        }
                    }
                    if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_false )
                    {
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[case " . $global_case_number . " ending without errors]" } ;
                        if ( $global_logging_info == $global_true ) { print LOGOUT "[total ballot count " . $global_current_total_vote_count . "]" } ;
                    }
                }
            } elsif ( $current_vote_info_number != $global_voteinfo_code_for_case_number )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[reached end of case or ballot info, but no case has been started]" } ;
                return "Error: Encountered case-specific vote-info number before first case started (input list position " . $pointer_to_vote_info . ")" ;
            }
            $global_question_number = 0 ;
        }


#-----------------------------------------------
#  Handle the code for a case number.

        if ( $current_vote_info_number == $global_voteinfo_code_for_case_number )
        {
            $global_previous_case_number = $global_case_number ;
            $global_case_number = $next_vote_info_number ;
            $status_pair_just_handled = $global_true ;
            $global_case_specific_warning_begin = "case-" . $global_case_number . "-warning-message:\n" . "word-case-capitalized " . $global_case_number ;
            $global_current_total_vote_count = 0 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "\n[case " . $global_case_number . "]\n\n" } ;
            if ( $global_case_number <= 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[error, first case number is " . $global_case_number . " instead of one]" } ;
                return "Error: First case number is not one" ;
            }
            if ( $global_case_number > $global_maximum_case_number )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[error-case-number-exceeds-limit (limit is " . $global_maximum_case_number . ", list position is " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " exceeds-limit-for-number-of-cases" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            }
            if ( $global_case_number != $global_previous_case_number + 1 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[error-case-number-is-not-sequential (case number " . $global_case_number . " instead of " . ( $global_previous_case_number + 1 ) . ")]" } ;
                return "Error: Case number is not sequential (case number " . $global_case_number . " instead of " . ( $global_previous_case_number + 1 ) . ")" ;
            }
            $global_question_count_for_case[ $global_case_number ] = 0 ;
            $global_question_number = 0 ;
            $global_current_total_vote_count = 0 ;
            if ( defined( $global_true_or_false_ignore_case[ $global_case_number ] ) )
            {
                if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
                {
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . " as previously requested]" } ;
                }
            } else
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_false ;
            }
            $global_number_of_questions_in_current_case = 0 ;
            @tally_uses_of_question_number = ( ) ;
            @tally_uses_of_question_and_choice_number = ( ) ;
            $within_ballots = $global_false ;
            $global_case_specific_warning_begin = "case-" . $global_case_number . "-warning-message:\n" . "word-case-capitalized " . $global_case_number ;
            next ;


#-----------------------------------------------
#  If a case number is not defined, assume a
#  case number of one.

        } elsif ( not( defined( $global_case_number ) ) )
        {
            $global_case_number = 1 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[case number not yet encountered, so case number is assumed to be one]" } ;
        }


#-----------------------------------------------
#  If the ignore-case flag for the current case
#  number has not yet been initialized, then
#  initialize it.

        if ( not( defined( $global_true_or_false_ignore_case[ $global_case_number ] ) ) )
        {
           $global_true_or_false_ignore_case[ $global_case_number ] = $global_false ;
        }


#-----------------------------------------------
#  Handle the code for a question number.

        if ( $current_vote_info_number == $global_voteinfo_code_for_question_number )
        {
            $status_pair_just_handled = $global_true ;
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            $global_question_number = $next_vote_info_number ;
            if ( $global_question_number < 0 )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[question-number-less-than-one (at list position " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-question-number-less-than-one" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            } elsif ( $global_question_number > $global_maximum_question_number )
            {
                    $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[too_many-questions-in-case (limit is " . $global_maximum_question_number . ", case is " . $global_case_number . ")]" } ;
                    $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " has-too-many-questions-limit-is " . $global_maximum_question_number . ")" . $global_warning_end ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            } else
            {
                $global_question_count_for_case[ $global_case_number ] = $global_question_number ;
                $global_number_of_questions_in_current_case = $global_question_number ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[question " . $global_question_number . "]" } ;
                $tally_uses_of_question_number[ $global_question_number ] ++ ;
                $count_of_choices_marked_for_current_question = 0 ;
                $global_question_specific_warning_begin = "case-" . $global_case_number . "-question-" . $global_question_number . "-warning-message:\n" . "word-case-capitalized " . $global_case_number . " word-question " . $global_question_number ;
            }


#-----------------------------------------------
#  Handle the code for a choice count.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_number_of_choices )
        {
            $status_pair_just_handled = $global_true ;
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] = $next_vote_info_number ;
            $choice_count_for_current_question = $next_vote_info_number ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[choice count " . $choice_count_for_current_question . "]" } ;
            if ( $global_question_number == 0 )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[encountered-choice-count-without-question-number (case " . $global_case_number . ", question " . $global_question_number . ", at list position " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-choice-count-without-question-number" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            }
            if ( ( $choice_count_for_current_question < 1 ) || ( $choice_count_for_current_question > $global_maximum_choice_number ) )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[invalid-choice-count (case " . $global_case_number . ", choice count " . $choice_count_for_current_question . ", list position " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-invalid-choice-count (" . $choice_count_for_current_question . ")" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            }


#-----------------------------------------------
#  Handle the code for a ballot count.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_ballot_count )
        {
            $status_pair_just_handled = $global_true ;
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            $global_ballot_info_repeat_count = $next_vote_info_number ;
            if ( $global_ballot_info_repeat_count < 1 )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ballot-count-number-less-than-one (at list position " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " has-ballot-count-number-less-than-one" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            }
            if ( $global_logging_info == $global_true ) { print LOGOUT "[bc " . $global_ballot_info_repeat_count . "]" } ;


#-----------------------------------------------
#  Handle the code for a choice number.

        } elsif ( $current_vote_info_number > 0 )
        {
            $global_choice_number = $current_vote_info_number ;
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            if ( $global_case_number < 1 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[positive-number-encountered-before-first-case-number]" } ;
                return "Error: Positive number encountered before first case number" ;
            }
            if ( $global_question_number < 1 )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-number-not-preceded-by-question-number (at list position " . $pointer_to_vote_info . ")]" } ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-choice-number-without-question-number" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            } elsif ( not( defined( $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] ) ) )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-choice-number-that-appears-before-number-of-choices-specified " . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-number-appears-before-number-of-choices-specified (case " . $global_case_number . ", question " . $global_question_number . ", ballot vote count " . $global_ballot_info_repeat_count . ", choice " . $global_choice_number . ", at list position " . $pointer_to_vote_info . ")]" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            } elsif ( $global_choice_number > $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-choice-number (" . $global_choice_number . ") that-exceeds-number-of-choices (" . $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] . ")" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-number-exceeds-indicated-number-of-choices (case " . $global_case_number . ", question " . $global_question_number . ", ballot vote count " . $global_ballot_info_repeat_count . ", choice " . $global_choice_number . ", specified number " . $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] . ", at list position " . $pointer_to_vote_info . ")]" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            } elsif ( defined( $tally_uses_of_choice_number[ $global_choice_number ] ) )
            {
                if ( $tally_uses_of_choice_number[ $global_choice_number ] > 1 )
                {
                    $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                    $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-choice-number (" . $global_choice_number . ") that-is-used-more-than-once-in-same-ballot" . $global_warning_end ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[choice-number-previously-used-in-this-ballot (case " . $global_case_number . ", question " . $global_question_number . ", ballot vote count " . $global_ballot_info_repeat_count . ", choice " . $global_choice_number . ", at list position " . $pointer_to_vote_info . ")]" } ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
                }
            }
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_false )
            {
                $tally_uses_of_choice_number[ $global_choice_number ] = 1 ;
                $count_of_choices_marked_for_current_question ++ ;
                if ( $global_choice_number > $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] )
                {
                    $global_choice_count_for_case_and_question[ $global_case_number ][ $global_question_number ] = $global_choice_number ;
                }
                $global_current_total_vote_count += $global_ballot_info_repeat_count ;
                $global_ballot_info_repeat_count = 0 ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[" . $global_choice_number . "]" } ;
            }


#-----------------------------------------------
#  Handle the code for a tie.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_tie )
        {
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            if ( ( $count_of_choices_marked_for_current_question < 1 ) || ( $global_question_number < 1 ) )
            {
                $global_true_or_false_ignore_case[ $global_case_number ] = $global_true ;
                $global_output_warning_messages_case_or_question_specific .= $global_case_specific_warning_begin . " contains-invalid-nesting-of-tie-indicator" . $global_warning_end ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[invalid-nesting-of-tied-preference-vote-info-number (case " . $global_case_number . ", question " . $global_question_number . ", ballot vote count " . $global_current_total_vote_count . ", at list position " . $pointer_to_vote_info . ")]" } ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring case " . $global_case_number . "]" } ;
            }
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_false )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[+]" } ;
            }


#-----------------------------------------------
#  Handle the code for the beginning of all the
#  ballots (for this case).

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_start_of_all_vote_info )
        {
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            $global_question_number = 0 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[begin ballots]" } ;


#-----------------------------------------------
#  Handle the code for the end of a ballot.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_end_of_ballot )
        {
            if ( $global_true_or_false_ignore_case[ $global_case_number ] == $global_true )
            {
                next ;
            }
            @tally_uses_of_choice_number = ( ) ;
            $global_question_number = 0 ;
#            if ( $global_logging_info == $global_true ) { print LOGOUT "[end ballot]" } ;


#-----------------------------------------------
#  Handle the code for the end of all vote info
#  (for the current case).

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_vote_info )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[end ballots for case " . $global_case_number . "]" } ;


#-----------------------------------------------
#  Handle the code for the end of all cases.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_cases )
        {
            if ( $global_case_number < 1 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "[reached end of all cases, but no case has been started]" } ;
                return "Error: Reached end of all cases before first case started (list position " . $pointer_to_vote_info . ")" ;
            }
            if ( $global_logging_info == $global_true ) { print LOGOUT "[end of all cases]" } ;


#-----------------------------------------------
#  Handle the code for a request to calculate
#  VoteFair representation ranking results,
#  VoteFair party ranking results, or only do
#  plurality counting.  If this request occurs
#  before the first case number, apply this
#  request to all cases and all questions,
#  although a different request can be specified
#  (later) for a specific question.  If the
#  request does not appear before the first
#  ballot (in the case), indicate (in the log
#  file) an error, but allow this minor error.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_only_plurality_results )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_only_plurality_results = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for only plurality counts]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_pairwise_counts )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_no_pairwise_counts = $global_false ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for pairwise counts]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_no_pairwise_counts )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_no_pairwise_counts = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for no pairwise counts]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_votefair_representation_rank )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_votefair_representation_rank = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for VoteFair representation ranking results]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_no_votefair_representation_rank )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_votefair_representation_rank = $global_false ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for no VoteFair representation ranking results]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_votefair_party_rank )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_votefair_party_rank = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for VoteFair party ranking results]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_no_votefair_party_rank )
        {
            if ( $global_case_number < 1 )
            {
                $global_true_or_false_always_request_votefair_party_rank = $global_false ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found all-cases request for no VoteFair party ranking results]\n" } ;
            } elsif ( $global_current_total_vote_count > 0 )
            {
                if ( $global_logging_info == $global_true ) { print LOGOUT "\n[found special request after first ballot started, this request will be ignored]\n" } ;
            }


#-----------------------------------------------
#  If the code was not recognized, indicate this
#  situation in the log file, but do not indicate
#  an error (because it will be ignored).

        } else
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[unrecognized code: " . $current_vote_info_number . "]" } ;
        }


#-----------------------------------------------
#  Repeat the loop that gets the next vote-info
#  number in the list.

    }


#-----------------------------------------------
#  If the code for the end of all cases was not
#  the last code encountered, extend the list by
#  one more number, and insert the
#  end-of-all-cases code.

    if ( $current_vote_info_number != $global_voteinfo_code_for_end_of_all_cases )
    {
        $global_length_of_vote_info_list ++ ;
        $global_vote_info_list[ $global_length_of_vote_info_list ] = $global_voteinfo_code_for_end_of_all_cases ;
    }


#-----------------------------------------------
#  End of subroutine.

    if ( $global_logging_info == $global_true ) { print LOGOUT "\n\n[done checking vote info numbers]\n\n" } ;
    return "" ;

}




=head2 calculate_results_for_one_question

(Not exported, for internal use only.)

Calculates voting results for one question
(contest) in an election/poll/survey.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       calculate_results_for_one_question
#-----------------------------------------------
#-----------------------------------------------

sub calculate_results_for_one_question
{

    my $actual_choice ;
    my $adjusted_choice ;
    my $ranking_level ;
    my $popularity_level ;
    my $representation_level ;
    my $party_level ;
    my $current_vote_info_number ;
    my $sequence_position ;
    my $context_question_number ;
    my $possible_text_rep_not_the_same ;
    my $possible_text_party_not_the_same ;
    my $comparison_of_methods_table ;
    my $total_vote_count_for_current_question ;


#-----------------------------------------------
#  These values must already be set:
#  (They are not checked for validity because
#  that is done before getting here.)
#      $global_input_pointer_start_next_case
#      $global_case_number
#      $global_question_number
#      $global_full_choice_count


#-----------------------------------------------
#  In case it is needed, initialize a prefix for
#  any warning message that refers to this
#  question.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, beginning to do calculations for question " . $global_question_number . "]\n" } ;
    $global_question_specific_warning_begin = "case-" . $global_case_number . "-question-" . $global_question_number . "-warning-message:\n" . "word-case-capitalized " . $global_case_number . " word-question " . $global_question_number ;


#-----------------------------------------------
#  Initialize the flags that determine whether
#  or not to do VoteFair representation ranking
#  and VoteFair party ranking.  These flags
#  can change (below) if requested for this case.

    $global_true_or_false_request_votefair_popularity_rank = $global_true ;
    $global_true_or_false_request_only_plurality_results = $global_true_or_false_always_request_only_plurality_results ;
    $global_true_or_false_request_no_pairwise_counts = $global_true_or_false_always_request_no_pairwise_counts ;
    $global_true_or_false_request_votefair_representation_rank = $global_true_or_false_always_request_votefair_representation_rank ;
    $global_true_or_false_request_votefair_party_rank = $global_true_or_false_always_request_votefair_party_rank ;


#-----------------------------------------------
#  Clear the result lists in case some
#  calculations are not done.

    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        $global_plurality_count_for_actual_choice[ $actual_choice ] = 0 ;
        $global_popularity_ranking_for_actual_choice[ $actual_choice ] = 0 ;
        $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] = 0 ;
        $global_representation_ranking_for_actual_choice[ $actual_choice ] = 0 ;
        $global_full_representation_ranking_for_actual_choice[ $actual_choice ] = 0 ;
        $global_party_ranking_for_actual_choice[ $actual_choice ] = 0 ;
    }


#-----------------------------------------------
#  Set up pointers and lists and values that
#  will be used for this question.

    if ( $global_logging_info == $global_true ) { print LOGOUT "\n" } ;
    &set_all_choices_as_used( ) ;
    &reset_ballot_info_and_tally_table( ) ;
    $global_ballot_influence_amount = 1.0 ;
    $global_ballot_info_repeat_count = 0 ;
    $global_current_total_vote_count = 0 ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "\n" } ;


#-----------------------------------------------
#  At the beginning of the vote info, look for
#  any requests regarding which calculations
#  should, or should not, be done.  Only check
#  as far as the end of the first ballot.
#  Also update the
#  "global_input_pointer_start_next_case"
#  pointer to skip over the code that indicates
#  how many choices are in each question.

    $context_question_number = 0 ;
    $global_pointer_to_current_ballot = $global_input_pointer_start_next_case ;
    while ( $global_pointer_to_current_ballot < $global_max_array_length )
    {
        $current_vote_info_number = $global_vote_info_list[ $global_pointer_to_current_ballot ] ;
        if ( ( $current_vote_info_number == $global_voteinfo_code_for_end_of_ballot ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_vote_info ) || ( $current_vote_info_number == $global_voteinfo_code_for_case_number ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_cases ) )
        {
            last ;
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_question_number )
        {
            $global_pointer_to_current_ballot ++ ;
            $context_question_number = $global_vote_info_list[ $global_pointer_to_current_ballot ] ;
        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_number_of_choices )
        {
            $global_pointer_to_current_ballot ++ ;
            $global_input_pointer_start_next_case = $global_pointer_to_current_ballot + 1 ;
        } elsif ( $context_question_number == $global_question_number )
        {
            if ( $current_vote_info_number == $global_voteinfo_code_for_request_only_plurality_results )
            {
                $global_true_or_false_request_only_plurality_results = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, request for only plurality results]" } ;
            } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_no_pairwise_counts )
            {
                $global_true_or_false_request_no_pairwise_counts = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, request for no pairwise counts]" } ;
            } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_votefair_representation_rank )
            {
                $global_true_or_false_request_votefair_representation_rank = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, request for representation ranking results]" } ;
            } elsif ( $current_vote_info_number == $global_voteinfo_code_for_request_votefair_party_rank )
            {
                $global_true_or_false_request_votefair_party_rank = $global_true ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, request for party ranking results]" } ;
            }
        }
        $global_pointer_to_current_ballot ++ ;
    }


#-----------------------------------------------
#  Log the status for what is being requested,
#  for this question and for all questions.

    if ( $global_logging_info == $global_true )
    {
        print LOGOUT "[one question, requests: " ;
        if ( $global_true_or_false_request_only_plurality_results == $global_true )
        {
            print LOGOUT "request for only plurality results" ;
        } else
        {
            print LOGOUT "no special request for only plurality results" ;
        }
        if ( $global_true_or_false_request_no_pairwise_counts == $global_true )
        {
            print LOGOUT " ; request for no pairwise counts" ;
        } else
        {
            print LOGOUT " ; pairwise counts will be included" ;
        }
        if ( $global_true_or_false_request_votefair_representation_rank == $global_true )
        {
            print LOGOUT " ; request for VoteFair representation ranking results" ;
        } else
        {
            print LOGOUT " ; request for no VoteFair representation ranking results" ;
        }
        if ( $global_true_or_false_request_votefair_party_rank == $global_true )
        {
            print LOGOUT " ; request for VoteFair party ranking results" ;
        } else
        {
            print LOGOUT " ; request for no VoteFair party ranking results" ;
        }
        print LOGOUT "]\n" ;
    }


#-----------------------------------------------
#  If there are not at least two choices,
#  indicate an error.

    if ( $global_adjusted_choice_count < 2 )
    {
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " does-not-have-at-least-two-choices" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, ERROR: number of (adjusted) choices is less than two]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Do the pairwise counting -- for all the
#  ballots and all the choices, with no special
#  weighting.
#  As part of getting the ballot information,
#  count the plurality results.
#  Also, if any requests for specific results
#  -- such as plurality counts only -- are
#  encountered, set the appropriate flag.

    $global_pointer_to_current_ballot = $global_input_pointer_start_next_case ;
    $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
    while ( $global_ballot_info_repeat_count > 0 )
    {
        &add_preferences_to_tally_table( ) ;
        $global_ballot_info_repeat_count = &get_numbers_based_on_one_ballot( ) ;
    }
    $total_vote_count_for_current_question = $global_current_total_vote_count ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, total vote count is " . $total_vote_count_for_current_question . "]\n" } ;


#-----------------------------------------------
#  If there were no ballots, indicate this in
#  the results, and exit this subroutine.

    if ( $total_vote_count_for_current_question == 0 )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, no ballots for this question, so no calculations done]\n" } ;
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " words-contains-no-ballots" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, this question has no ballots]\n" } ;
        &put_next_result_info_number( $global_voteinfo_code_for_skip_question ) ;
        return ;
    }


#-----------------------------------------------
#  Output the plurality results.

    &output_plurality_counts( ) ;


#-----------------------------------------------
#  If only plurality results are requested,
#  exit this subroutine.

    if ( $global_true_or_false_request_only_plurality_results == $global_true )
    {
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, only plurality results requested, so further calculations not done]\n" } ;
        $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " does-not-request-VoteFair-calculations-only-plurality-counts" . "\n-----\n\n" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, all done for question " . $global_question_number . " in case " . $global_case_number . "]\n" } ;
        return ;
    }


#-----------------------------------------------
#  Log a display of the tally numbers in
#  an array version.

    if ( $global_logging_info == $global_true )
    {
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            $global_log_info_choice_at_position[ $actual_choice ] = $actual_choice ;
        }
        print LOGOUT "[one question, full pairwise counts ranking:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  Unless suppressed, output the pairwise counts
#  -- while the pairwise counts for all the
#  choices are still in the tally table.

    if ( $global_true_or_false_request_no_pairwise_counts == $global_false )
    {
        &output_tally_table_numbers( ) ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, pairwise counts put into output list]\n" } ;
    }


#-----------------------------------------------
#  Do the VoteFair popularity ranking
#  calculations.

    $global_ranking_type_being_calculated = "popularity" ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair popularity ranking calculations beginning]\n" } ;
    $global_pointer_to_current_ballot = $global_input_pointer_start_next_case ;
    &calc_votefair_popularity_rank( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair popularity ranking calculations done]\n" } ;
    if ( $global_possible_error_message ne "" )
    {
        return ;
    }


#-----------------------------------------------
#  If the popularity results were not calculated,
#  the error message has already been written,
#  so just return.

    $adjusted_choice = 1 ;
    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
    if ( $global_popularity_ranking_for_actual_choice[ $actual_choice ] == 0 )
    {
        return ;
    }


#-----------------------------------------------
#  Save the VoteFair popularity ranking results
#  that apply to all the choices (because the
#  rankings will be overwritten if VoteFair
#  representation ranking or VoteFair party
#  ranking calculations are done).
#  Also save the top-ranked choice -- if it is
#  a single winning choice -- for use by
#  the representation and party ranking
#  calculations.

    $global_choice_count_at_full_top_popularity_ranking_level = 0 ;
    $global_actual_choice_at_top_of_full_popularity_ranking = 0 ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] = $global_popularity_ranking_for_actual_choice[ $actual_choice ] ;
        if ( $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] == 1 )
        {
            $global_actual_choice_at_top_of_full_popularity_ranking = $actual_choice ;
            $global_choice_count_at_full_top_popularity_ranking_level ++ ;
        }
    }
    if ( $global_choice_count_at_full_top_popularity_ranking_level != 1 )
    {
        $global_actual_choice_at_top_of_full_popularity_ranking = 0 ;
    }
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, number of most-popular choices is " . $global_choice_count_at_full_top_popularity_ranking_level . "]\n" } ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, if only one top choice, choice number is " . $global_actual_choice_at_top_of_full_popularity_ranking . "]\n" } ;


#-----------------------------------------------
#  Log a display of the tally numbers with the
#  choices in popularity ranking sequence.

    if ( $global_logging_info == $global_true )
    {
        $sequence_position = 1 ;
        for ( $ranking_level = 1 ; $ranking_level <= $global_full_choice_count ; $ranking_level ++ )
        {
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] == $ranking_level )
                {
                    $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
                    $sequence_position ++ ;
                }
            }
        }
        print LOGOUT "[one question, pairwise counts in VoteFair popularity ranking sequence:]\n" ;
        &internal_view_matrix( ) ;
    }


#-----------------------------------------------
#  Determine how many levels of representation
#  ranking should be done.
#
#  If VoteFair party ranking results are
#  requested, request at least two levels of
#  VoteFair representation ranking results.

    $global_representation_levels_requested = $global_default_representation_levels_requested ;
    if ( $global_true_or_false_request_votefair_representation_rank == $global_true )
    {
        $global_representation_levels_requested = $global_limit_on_representation_rank_levels ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, for representation ranking, calculation limit used]\n" } ;
    } else
    {
        $global_representation_levels_requested = 0 ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, no representation ranking requested]\n" } ;
    }
    if ( $global_true_or_false_request_votefair_party_rank == $global_true )
    {
        if ( $global_representation_levels_requested < 2 )
        {
            $global_representation_levels_requested = 2 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, for party ranking, minimum of two representation levels requested]\n" } ;
        }
    }
    if ( $total_vote_count_for_current_question < 2 )
    {
        $global_representation_levels_requested = 0 ;
        $global_output_warning_messages_case_or_question_specific .= "case-" . $global_case_number . "-question-" . $global_question_number . "-results-type-representation-warning-message:\n" . "not-at-least-two-ballots-so-no-representation-calculations-done" . $global_warning_end ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, not at least two ballots, so no representation levels calculated]\n" } ;
    }


#-----------------------------------------------
#  If requested, do VoteFair representation
#  ranking -- using all the choices.

    if ( $global_representation_levels_requested > 1 )
    {
        $global_ranking_type_being_calculated = "representation" ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair representation ranking calculations beginning]\n" } ;
        $global_pointer_to_current_ballot = $global_input_pointer_start_next_case ;
        &set_all_choices_as_used( ) ;
        &calc_votefair_representation_rank( ) ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair representation ranking calculations end]\n" } ;


#-----------------------------------------------
#  If they were calculated, save the VoteFair
#  representation ranking results that apply
#  to all the choices (because these rankings
#  will be overwritten if VoteFair party
#  ranking calculations are done).
#  Also save the second-ranked representation
#  choice -- if it does not involve a tie --
#  for use by the party ranking calculations.

        $global_choice_count_at_full_second_representation_level = 0 ;
        $global_actual_choice_at_second_representation_ranking = 0 ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            $global_full_representation_ranking_for_actual_choice[ $actual_choice ] = $global_representation_ranking_for_actual_choice[ $actual_choice ] ;
            if ( $global_full_representation_ranking_for_actual_choice[ $actual_choice ] == 2 )
            {
                $global_actual_choice_at_second_representation_ranking = $actual_choice ;
                $global_choice_count_at_full_second_representation_level ++ ;
            }
        }
        if ( $global_choice_count_at_full_second_representation_level != 1 )
        {
            $global_actual_choice_at_second_representation_ranking = 0 ;
        }
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, number of second-most-representative choices is " . $global_choice_count_at_full_second_representation_level . "]\n" } ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, if only one top choice, choice number is " . $global_actual_choice_at_second_representation_ranking . "]\n" } ;


#-----------------------------------------------
#  If VoteFair party ranking results
#  have been requested, calculate them.

        if ( $global_true_or_false_request_votefair_party_rank == $global_true )
        {
            if ( $total_vote_count_for_current_question < 3 )
            {
                $global_output_warning_messages_case_or_question_specific .= $global_question_specific_warning_begin . " has-fewer-than-three-ballots-so-VoteFair-party-ranking-cannot-be-done" . "\n-----\n\n" ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, not at least three ballots, so no party ranking done]\n" } ;
            } else
            {
                $global_ranking_type_being_calculated = "party" ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair party ranking calculations beginning]\n" } ;
                &calc_votefair_party_rank( ) ;
                if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, VoteFair party ranking calculations done]\n" } ;
            }
        }
    }


#-----------------------------------------------
#  Output the VoteFair Ranking results, which may
#  include: VoteFair popularity ranking
#  results, VoteFair representation ranking
#  results, and VoteFair popularity ranking results.

    &output_ranking_results( ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, all done for question " . $global_question_number . " in case " . $global_case_number . "]\n" } ;


#-----------------------------------------------
#  In the log file show a comparison of the
#  results for different ranking methods:
#  popularity, representation, and party.

    if ( ( $global_logging_info == $global_true ) && ( ( $global_true_or_false_request_votefair_popularity_rank == $global_true ) || ( $global_true_or_false_request_votefair_representation_rank == $global_true ) ) )
    {
        $possible_text_rep_not_the_same = "rep same" ;
        $possible_text_party_not_the_same = "par same" ;
        $comparison_of_methods_table = "[one question, case " . $global_case_number . " , question " . $global_question_number . " , comparison of popularity, representation, and party ranking]\n" ;
        for ( $sequence_position = 1 ; $sequence_position <= $global_full_choice_count + 1 ; $sequence_position ++ )
        {
            $popularity_level = $sequence_position ;
            if ( $sequence_position == $global_full_choice_count + 1 )
            {
                $popularity_level = 0 ;
            }
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $popularity_level == $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] )
                {
                    $representation_level = $global_full_representation_ranking_for_actual_choice[ $actual_choice ] ;
                    $comparison_of_methods_table .= "[  choice " . $actual_choice . " at popularity level " . $popularity_level . " , representation level " . $representation_level ;
                    if ( $global_true_or_false_request_votefair_party_rank == $global_true )
                    {
                        $party_level = $global_party_ranking_for_actual_choice[ $actual_choice ] ;
                        $comparison_of_methods_table .= " , party level " . $party_level ;
                    } else
                    {
                        $party_level = $representation_level ;
                    }
                    $comparison_of_methods_table .= "]" ;
                    if ( $popularity_level != $representation_level )
                    {
                        $possible_text_rep_not_the_same = "rep not same" ;
                        $comparison_of_methods_table .= " **** " ;
                    }
                    if ( $representation_level != $party_level )
                    {
                        $possible_text_party_not_the_same = "par not same" ;
                        $comparison_of_methods_table .= " **** " ;
                    }
                    $comparison_of_methods_table .= "\n" ;
                }
            }
        }
        $comparison_of_methods_table .= "[" . $possible_text_rep_not_the_same . "][" . $possible_text_party_not_the_same . "]\n\n" ;
        print LOGOUT $comparison_of_methods_table . "\n" ;
    }


#-----------------------------------------------
#  All done.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[one question, exiting subroutine]\n" } ;
    return ;

}




=head2 set_all_choices_as_used

(Not exported, for internal use only.)

Specifies that all the choices (for the current
question) are used (non-ignored).

=cut

#-----------------------------------------------
#-----------------------------------------------
#            set_all_choices_as_used
#-----------------------------------------------
#-----------------------------------------------

sub set_all_choices_as_used
{
    my $actual_choice ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        $global_using_choice[ $actual_choice ] = $global_true ;
    }
    if ( $global_logging_info == $global_true ) { print LOGOUT "[setting all choices as used]\n" } ;
    return 1 ;
}




=head2 reset_ballot_info_and_tally_table

(Not exported, for internal use only.)

Restarts the counting of ballot information at
the first ballot (in the current case).
Also sets up the adjusted (alias) choice numbers
and pair counters to exclude the choices being ignored.
Also creates and initializes the tally table.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            reset_ballot_info_and_tally_table
#-----------------------------------------------
#-----------------------------------------------

sub reset_ballot_info_and_tally_table
{

    my $actual_choice ;
    my $pair_counter ;
    my $adjusted_first_choice ;
    my $adjusted_second_choice ;
    my $adjusted_choice ;


#-----------------------------------------------
#  Reset the ballot vote count.

    $global_ballot_info_repeat_count = 0 ;
    $global_current_total_vote_count = 0 ;


#-----------------------------------------------
#  Reset the value that normally counts each
#  ballot as having one vote.
#  At some steps in VoteFair representation
#  ranking it is set to a value less than one
#  for some ballots (based on how the voter
#  ranked choices that have already been
#  identified as winning choices).

    $global_ballot_influence_amount = 1.0 ;


#-----------------------------------------------
#  Log which choices are not being used.

    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_using_choice[ $actual_choice ] == $global_false )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[ignoring choice " . $actual_choice . "]" } ;
        }
    }


#-----------------------------------------------
#  Set up the adjusted choice numbers, and the
#  adjusted choice count.

    $global_adjusted_choice_count = 0 ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        if ( $global_using_choice[ $actual_choice ] == $global_true )
        {
            $global_adjusted_choice_count ++ ;
            $global_adjusted_choice_for_actual_choice[ $actual_choice ] = $global_adjusted_choice_count ;
            $global_actual_choice_for_adjusted_choice[ $global_adjusted_choice_count ] = $actual_choice ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[adjusted choice " . $global_adjusted_choice_count . " corresponds to actual choice " . $actual_choice . "]" } ;
        }
    }
    if ( $global_logging_info == $global_true ) { print LOGOUT "[adjusted choice count is " . $global_adjusted_choice_count . "]\n" } ;


#-----------------------------------------------
#  Create the pairwise choice counters.
#  Also create an offset indexing that allows
#  the appropriate pair-counter number to be
#  easily calculated when the two choice
#  numbers are known.

    $pair_counter = 0 ;
    $global_pair_counter_maximum = 0 ;
    for ( $adjusted_first_choice = 1 ; $adjusted_first_choice < $global_adjusted_choice_count ; $adjusted_first_choice ++ )
    {
        $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_first_choice ] = $pair_counter - $adjusted_first_choice ;
        for ( $adjusted_second_choice = $adjusted_first_choice + 1 ; $adjusted_second_choice <= $global_adjusted_choice_count ; $adjusted_second_choice ++ )
        {
            $pair_counter ++ ;
            $global_pair_counter_maximum ++ ;
            $global_adjusted_first_choice_number_in_pair[ $pair_counter ] = $adjusted_first_choice ;
            $global_adjusted_second_choice_number_in_pair[ $pair_counter ] = $adjusted_second_choice ;
        }
    }


#-----------------------------------------------
#  Create, and clear, the tally table.

    for ( $pair_counter = 1 ; $pair_counter <= $global_pair_counter_maximum ; $pair_counter ++ )
    {
        $global_tally_first_over_second_in_pair[ $pair_counter ] = 0 ;
        $global_tally_second_over_first_in_pair[ $pair_counter ] = 0 ;
        $global_tally_first_equal_second_in_pair[ $pair_counter ] = 0 ;
    }
    $global_true_or_false_tally_table_created = $global_true ;


#-----------------------------------------------
#  Initialize the plurality counts.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        $global_plurality_count_for_actual_choice[ $actual_choice ] = 0 ;
    }


#-----------------------------------------------
#  Reset the pointer to the beginning of the
#  ballots for the current case.

    $global_pointer_to_current_ballot = $global_input_pointer_start_next_case ;


#  All done.

    return 1 ;

}




=head2 get_numbers_based_on_one_ballot

(Not exported, for internal use only.)

Gets the preference information from the next
ballot.  This information may include an optional
multiple-ballot count that indicates how many
ballots have the same specified preferences.

=cut

#-----------------------------------------------
#-----------------------------------------------
#          get_numbers_based_on_one_ballot
#-----------------------------------------------
#-----------------------------------------------

sub get_numbers_based_on_one_ballot
{

    my $current_vote_info_number ;
    my $next_vote_info_number ;
    my $current_question_number ;
    my $preference_level ;
    my $choice_number ;
    my $choice_at_top_preference_level ;
    my $choice_count_at_top_preference_level ;
    my $count_of_encountered_ballot_counts ;
    my $text_ballot_info ;


#-----------------------------------------------
#  Initialization.

    $current_question_number = 0 ;
    $choice_number = 0 ;
    $count_of_encountered_ballot_counts = 0 ;
    $choice_count_at_top_preference_level = 0 ;
    $choice_at_top_preference_level = 0 ;
    $preference_level = 1 ;


#-----------------------------------------------
#  In case any of the choice numbers are not
#  encountered, initialize all the preference
#  levels to the last level.

    for ( $choice_number = 1 ; $choice_number <= $global_full_choice_count ; $choice_number ++ )
    {
        $global_ballot_preference_for_choice[ $choice_number ] = $global_full_choice_count ;
    }


#-----------------------------------------------
#  If the pointer is already at the end of the
#  ballots, return with a value of zero.

        $current_vote_info_number = $global_vote_info_list[ $global_pointer_to_current_ballot ] ;
        if ( ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_vote_info ) || ( $current_vote_info_number == $global_voteinfo_code_for_case_number ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_cases ) )
        {
            $global_ballot_info_repeat_count = 0 ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[end of ballots]\n" } ;
            return 0 ;
        }


#-----------------------------------------------
#  Initially assume that the ballot count is
#  one.

    $global_ballot_info_repeat_count = 1 ;
    $text_ballot_info = "q " . $global_question_number . " " ;


#-----------------------------------------------
#  Repeat a loop that handles each vote-info
#  number within one ballot.

    while ( $global_pointer_to_current_ballot < $global_max_array_length )
    {


#-----------------------------------------------
#  Get the current vote-info number and, just in
#  case it's needed, the one after it.

        $current_vote_info_number = $global_vote_info_list[ $global_pointer_to_current_ballot ] ;
        if ( $global_pointer_to_current_ballot < $global_max_array_length - 1 )
        {
            $next_vote_info_number = $global_vote_info_list[ $global_pointer_to_current_ballot + 1 ] ;
        } else
        {
            $next_vote_info_number = 0 ;
        }


#-----------------------------------------------
#  If the end of all the vote info, or the next
#  case number, or the end of all the cases,
#  has been reached, exit the loop.

        if ( ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_vote_info ) || ( $current_vote_info_number == $global_voteinfo_code_for_case_number ) || ( $current_vote_info_number == $global_voteinfo_code_for_end_of_all_cases ) )
        {
            last ;


#-----------------------------------------------
#  When the end of the ballot is reached, point
#  to the beginning of the next ballot and exit
#  the loop.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_end_of_ballot )
        {
            $global_pointer_to_current_ballot ++ ;
            last ;


#-----------------------------------------------
#  If a ballot count (see next section) has been
#  encountered for a second time, the beginning
#  of the next ballot has been reached, so leave
#  the pointer pointing to the beginning of this
#  next ballot and exit the loop.

        } elsif ( ( $current_vote_info_number == $global_voteinfo_code_for_ballot_count ) && ( $count_of_encountered_ballot_counts > 0 ) )
        {
            last ;


#-----------------------------------------------
#  Get the count for the number of identical
#  ballots (that have the same ranking sequence).
#  This vote count will be returned, or a value
#  of zero will be returned when there are no
#  more ballots encountered.  Also count a
#  second ballot count in case an end-of-ballot
#  code is not used at the end of each ballot.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_ballot_count )
        {
            $global_ballot_info_repeat_count = $next_vote_info_number ;
            $global_pointer_to_current_ballot ++ ;
            $count_of_encountered_ballot_counts ++ ;


#-----------------------------------------------
#  Get the question number for the current
#  vote-info preference information.

        } elsif ( $current_vote_info_number == $global_voteinfo_code_for_question_number )
        {
            $current_question_number = $next_vote_info_number ;
            $global_pointer_to_current_ballot ++ ;


#-----------------------------------------------
#  If the current preference levels do not apply
#  to the question being handled, skip ahead
#  over the handling of other codes.

        } elsif ( $current_question_number == $global_question_number )
        {


#-----------------------------------------------
#  If a preference level is explicitly supplied,
#  adjust the preference level.

            if ( $current_vote_info_number == $global_voteinfo_code_for_preference_level )
            {
                $preference_level = $next_vote_info_number ;
                $global_pointer_to_current_ballot ++ ;


#-----------------------------------------------
#  Adjust the preference level at tied levels.

            } elsif ( $current_vote_info_number == $global_voteinfo_code_for_tie )
            {
                $preference_level -- ;
                if ( $preference_level == 1 )
                {
                    $choice_count_at_top_preference_level ++ ;
                    $choice_at_top_preference_level = 0 ;
                }
                $text_ballot_info .= " tie" ;


#-----------------------------------------------
#  For a choice number, determine its preference
#  level.
#  If this choice is at the top preference level,
#  save it -- for possible use in plurality
#  counting.

            } elsif ( $current_vote_info_number > 0 )
            {
                $choice_number = $current_vote_info_number ;
                $global_ballot_preference_for_choice[ $choice_number ] = $preference_level ;
                $text_ballot_info .= " " . $choice_number ;
                if ( $preference_level == 1 )
                {
                    $choice_count_at_top_preference_level ++ ;
                    $choice_at_top_preference_level = $choice_number ;
                }
                $preference_level ++ ;
            }


#-----------------------------------------------
#  Finish skipping over the handling of codes
#  that do not apply to the question being
#  handled.

        }


#-----------------------------------------------
#  Repeat the loop to handle the next
#  vote-info number.

        $global_pointer_to_current_ballot ++ ;
    }


#-----------------------------------------------
#  If there was only one choice at the top
#  preference level, increment the plurality
#  count for that choice.

    if ( ( $choice_count_at_top_preference_level == 1 ) && ( $choice_at_top_preference_level > 0 ) )
    {
        $global_plurality_count_for_actual_choice[ $choice_at_top_preference_level ] += $global_ballot_info_repeat_count ;
    }


#-----------------------------------------------
#  Accumulate the total ballot vote count.

    $global_current_total_vote_count += $global_ballot_info_repeat_count ;


#-----------------------------------------------
#  Return with the number of ballot counts
#  handled.  If zero, there are no
#  more ballots in this question.

    if ( $global_logging_info == $global_true ) { print LOGOUT "[x " . $global_ballot_info_repeat_count . " " . $text_ballot_info . "]" } ;
    return $global_ballot_info_repeat_count ;


#-----------------------------------------------
#  End of subroutine.

}




=head2 add_preferences_to_tally_table

(Not exported, for internal use only.)

Adds to the tally table the just-acquired
preference numbers (from the current ballot).

=cut

#-----------------------------------------------
#-----------------------------------------------
#        add_preferences_to_tally_table
#-----------------------------------------------
#-----------------------------------------------

sub add_preferences_to_tally_table
{

    my $pair_counter ;
    my $adjusted_first_choice ;
    my $adjusted_second_choice ;
    my $actual_first_choice ;
    my $actual_second_choice ;
    my $tally_amount ;


#-----------------------------------------------
#  Update the tally table with the current ballot information.
#  Normally the influence amount is one, but it can be
#  a fractional vote in some VoteFair representation
#  calculations.

    $tally_amount = $global_ballot_info_repeat_count * $global_ballot_influence_amount ;
    for ( $pair_counter = 1 ; $pair_counter <= $global_pair_counter_maximum ; $pair_counter ++ )
    {
        $adjusted_first_choice = $global_adjusted_first_choice_number_in_pair[ $pair_counter ] ;
        $adjusted_second_choice = $global_adjusted_second_choice_number_in_pair[ $pair_counter ] ;
        $actual_first_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
        $actual_second_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;
        if ( $global_ballot_preference_for_choice[ $actual_first_choice ] < $global_ballot_preference_for_choice[ $actual_second_choice ] )
        {
            $global_tally_first_over_second_in_pair[ $pair_counter ] += $tally_amount ;
        } elsif ( $global_ballot_preference_for_choice[ $actual_first_choice ] > $global_ballot_preference_for_choice[ $actual_second_choice ] )
        {
            $global_tally_second_over_first_in_pair[ $pair_counter ] += $tally_amount ;
        } else
        {
            $global_tally_first_equal_second_in_pair[ $pair_counter ] += $tally_amount ;
        }
    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}





=head2 internal_view_matrix

(Not exported, for internal use only.)

For debugging purposes, writes to the debug log
a matrix with the pairwise counts.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            internal_view_matrix
#-----------------------------------------------
#-----------------------------------------------

sub internal_view_matrix
{

    my $matrix_row_number ;
    my $matrix_column_number ;
    my $sequence_string ;
    my $pair_counter ;
    my $adjusted_first_choice ;
    my $adjusted_second_choice ;
    my $actual_first_choice ;
    my $actual_second_choice ;
    my $text_count ;
    my $tally ;
    my $opposition_score ;
    my $text_count_decimal ;
    my $percentage ;


#-----------------------------------------------
#  The sequence must be indicated in the list named
#  global_log_info_choice_at_position.
#  The number of choices is determined by the value
#  of global_adjusted_choice_count.


#-----------------------------------------------
#  Display the tally numbers in a matrix.

    if ( $global_logging_info == $global_true )
    {
        $sequence_string = "" ;
        $global_pairwise_matrix_text = "" ;
        $global_sequence_score = 0 ;
        $opposition_score = 0 ;
        if ( ( not( defined( $global_scale_for_logged_pairwise_counts ) ) ) || ( $global_scale_for_logged_pairwise_counts < 0.000001 ) )
        {
            $global_scale_for_logged_pairwise_counts = 1.0 ;
        }
        for ( $matrix_row_number = 1 ; $matrix_row_number <= $global_adjusted_choice_count ; $matrix_row_number ++ )
        {
            $actual_first_choice = $global_log_info_choice_at_position[ $matrix_row_number ] ;
            $adjusted_first_choice = $global_adjusted_choice_for_actual_choice[ $actual_first_choice ] ;
            $sequence_string .= $actual_first_choice . " , " ;
            $global_pairwise_matrix_text .= "[" ;
            for ( $matrix_column_number = 1 ; $matrix_column_number <= $global_adjusted_choice_count ; $matrix_column_number ++ )
            {
                $actual_second_choice = $global_log_info_choice_at_position[ $matrix_column_number ] ;
                $adjusted_second_choice = $global_adjusted_choice_for_actual_choice[ $actual_second_choice ] ;
                $tally = 0 ;
                if ( $actual_first_choice == $actual_second_choice )
                {
                    $text_count = " ---" ;
                    $text_count_decimal = "  ----- " ;
                } elsif ( $actual_first_choice < $actual_second_choice )
                {
                    $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_first_choice ] + $adjusted_second_choice ;
                    $tally = $global_tally_first_over_second_in_pair[ $pair_counter ] * $global_scale_for_logged_pairwise_counts ;
                    $text_count = sprintf( "%4d" , $tally ) ;
                    $text_count_decimal = sprintf( "%6.2f" , $tally ) ;
                } else
                {
                    $pair_counter = $global_pair_counter_offset_for_first_adjusted_choice[ $adjusted_second_choice ] + $adjusted_first_choice ;
                    $tally = $global_tally_second_over_first_in_pair[ $pair_counter ] * $global_scale_for_logged_pairwise_counts ;
                    $text_count = sprintf( "%4d" , $tally ) ;
                    $text_count_decimal = sprintf( "%6.2f" , $tally ) ;
                }
                $global_pairwise_matrix_text .= "  " . $text_count . "  " ;
                if ( $matrix_column_number > $matrix_row_number )
                {
                    $global_sequence_score += $tally ;
                } else
                {
                    $opposition_score += $tally ;
                }
            }
            $global_pairwise_matrix_text .= "]\n" ;
        }
        if ( $global_sequence_score + $opposition_score > 0 )
        {
            $percentage = ( $global_sequence_score / ( $global_sequence_score + $opposition_score ) ) * 100 ;
        } else
        {
            $percentage = 0 ;
        }
        $sequence_string =~ s/, *$// ;
        $global_pairwise_matrix_text .= "\n" . "[above counts apply to sequence: " . $sequence_string . "] [seq score = " . sprintf( "%6d" , $global_sequence_score ) . "]\n" ;
        $global_pairwise_matrix_text .= "[percent support: " . sprintf( "%4d" , $percentage ) . "]\n" ;
        print LOGOUT "\n" . $global_pairwise_matrix_text . "\n" ;
    }


#-----------------------------------------------
#  Reset the scale value in case it is not
#  reset elsewhere.

    $global_scale_for_logged_pairwise_counts = 1.0 ;


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}




=head2 normalize_ranking

(Not exported, for internal use only.)

Normalizes ranking levels so that ranking levels
are sequential integer numbers (with no numbers
skipped).

=cut

#-----------------------------------------------
#-----------------------------------------------
#            normalize_ranking
#-----------------------------------------------
#-----------------------------------------------

sub normalize_ranking
{

    my $adjusted_choice ;
    my $actual_choice ;
    my $ranking_level ;
    my $previous_ranking_level ;
    my $new_ranking_level ;
    my $sequence_position ;
    my $true_or_false_log_details ;

    my @new_rank_for_adjusted_choice ;
    my %adjusted_choice_at_ranking_level ;


#-----------------------------------------------
#  Hide (or show) details.

    $true_or_false_log_details = $global_false ;


#-----------------------------------------------
#  For each adjusted choice, get its ranking
#  level, and index those ranking levels.
#  If there is only one choice at a ranking
#  level, store the adjusted choice number at
#  that level.

    %adjusted_choice_at_ranking_level = ( ) ;
    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[normalization, un-normalized values:]\n" } ;
    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $ranking_level = $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] ;
        $adjusted_choice_at_ranking_level{ $ranking_level } ++ ;
        if ( defined( $adjusted_choice_at_ranking_level{ $ranking_level } ) )
        {
            $adjusted_choice_at_ranking_level{ $ranking_level } = 0 ;
        } else
        {
            $adjusted_choice_at_ranking_level{ $ranking_level } = $adjusted_choice ;
        }
        $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
        if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[    choice " . $actual_choice . " at level " . $ranking_level . "]\n" } ;
    }


#-----------------------------------------------
#  Normalize the ranking levels so that no
#  ranking levels are skipped.
#  While doing this, put into the
#  global_log_info_choice_at_position
#  list the actual choice numbers in the
#  calculated sequence -- so that the
#  internal_view_matrix subroutine can use this
#  sequence to display the normalized results.

    $new_ranking_level = 1 ;
    $sequence_position = 1 ;
#  Possibly modify code in next line to allow easier future conversion to C language.
    foreach $previous_ranking_level ( sort {$a <=> $b} keys( %adjusted_choice_at_ranking_level ) )
    {
        if ( $adjusted_choice_at_ranking_level{ $previous_ranking_level } != 0 )
        {
            $adjusted_choice = $adjusted_choice_at_ranking_level{ $previous_ranking_level } ;
            $new_rank_for_adjusted_choice[ $adjusted_choice ] = $new_ranking_level ;
            if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[normalization, changed rank of choice " . $adjusted_choice . " to level " . $new_ranking_level . "]\n" } ;
        } else
        {
            for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
            {
                if ( $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] == $previous_ranking_level )
                {
                    $new_rank_for_adjusted_choice[ $adjusted_choice ] = $new_ranking_level ;
                    $actual_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_choice ] ;
                    $global_log_info_choice_at_position[ $sequence_position ] = $actual_choice ;
                    $sequence_position ++ ;
                    if ( $true_or_false_log_details == $global_true ) { print LOGOUT "[normalization, changed rank of choice " . $actual_choice . " to level " . $new_ranking_level . "]\n" } ;
                }
            }
        }
        $new_ranking_level ++ ;
    }


#-----------------------------------------------
#  Copy the results back to the globally
#  accessible array.

    for ( $adjusted_choice = 1 ; $adjusted_choice <= $global_adjusted_choice_count ; $adjusted_choice ++ )
    {
        $global_rank_to_normalize_for_adjusted_choice[ $adjusted_choice ] = $new_rank_for_adjusted_choice[ $adjusted_choice ] ;
    }


#-----------------------------------------------
#  End of subroutine.

    return ;

}




=head2 put_next_result_info_number

(Not exported, for internal use only.)

Puts the next result-info number into the array
that stores the result information.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       put_next_result_info_number
#-----------------------------------------------
#-----------------------------------------------

sub put_next_result_info_number
{

    my $current_result_info_number ;


#-----------------------------------------------
#  Get the supplied value.

    if ( scalar( @_ ) == 1 )
    {
        $current_result_info_number = $_[ 0 ] ;
    } else
    {
        warn "Error: No value supplied to the put_next_result_info_number subroutine" ;
        return ;
    }


#-----------------------------------------------
#  If the list has become too long,
#  insert the code that indicates the end
#  of the results, and then indicate an error.

    if ( $global_pointer_to_output_results >= $global_max_array_length )
    {
        $global_output_results[ $global_pointer_to_output_results ] = $global_voteinfo_code_for_end_of_all_cases ;
        $global_possible_error_message = "Error: Not enough room for results from all cases (size limit is " . $global_max_array_length . ")" ;
        return ;
    }


#-----------------------------------------------
#  Put the next result-info number into the list.

    $global_output_results[ $global_pointer_to_output_results ] = $current_result_info_number ;


#-----------------------------------------------
#  Increment the list pointer, and increment the
#  length of the list.

    $global_pointer_to_output_results ++ ;
    $global_length_of_result_info_list = $global_pointer_to_output_results ;


#-----------------------------------------------
#  End of subroutine.

    return ;

}




=head2 output_plurality_counts

(Not exported, for internal use only.)

Puts into the output results the plurality counts.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            output_plurality_counts
#-----------------------------------------------
#-----------------------------------------------

sub output_plurality_counts
{

    my $actual_choice ;


#-----------------------------------------------
#  Put the plurality counts into the output
#  results list.

    &put_next_result_info_number( $global_voteinfo_code_for_start_of_plurality_results ) ;
    if ( $global_logging_info == $global_true ) { print LOGOUT "[output, plurality counts:]\n" } ;
    for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
    {
        &put_next_result_info_number( $global_voteinfo_code_for_choice ) ;
        &put_next_result_info_number( $actual_choice ) ;
        &put_next_result_info_number( $global_voteinfo_code_for_plurality_count ) ;
        &put_next_result_info_number( $global_plurality_count_for_actual_choice[ $actual_choice ] ) ;
        if ( $global_plurality_count_for_actual_choice[ $actual_choice ] > 0 )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[output, plurality count for choice " . $actual_choice . " is " . $global_plurality_count_for_actual_choice[ $actual_choice ] . "]\n" } ;
        } else
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[output, plurality count for choice " . $actual_choice . " is " . "0" . "]\n" } ;
        }
    }
    &put_next_result_info_number( $global_voteinfo_code_for_end_of_plurality_results ) ;


#-----------------------------------------------
#  End of subroutine.

    return ;

}




=head2 output_tally_table_numbers

(Not exported, for internal use only.)

Puts the pairwise counts from the tally table
into the output list.

=cut

#-----------------------------------------------
#-----------------------------------------------
#        output_tally_table_numbers
#-----------------------------------------------
#-----------------------------------------------

sub output_tally_table_numbers
{

    my $adjusted_first_choice ;
    my $adjusted_second_choice ;
    my $actual_first_choice ;
    my $actual_second_choice ;
    my $pair_counter ;


#-----------------------------------------------
#  This subroutine must be used while the pairwise
#  counts for all the choices are still in the
#  tally table.


#-----------------------------------------------
#  Output the pairwise counts from the tally table.

    &put_next_result_info_number( $global_voteinfo_code_for_start_of_tally_table_results ) ;
    for ( $pair_counter = 1 ; $pair_counter <= $global_pair_counter_maximum ; $pair_counter ++ )
    {
        $adjusted_first_choice = $global_adjusted_first_choice_number_in_pair[ $pair_counter ] ;
        $adjusted_second_choice = $global_adjusted_second_choice_number_in_pair[ $pair_counter ] ;

        $actual_first_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_first_choice ] ;
        $actual_second_choice = $global_actual_choice_for_adjusted_choice[ $adjusted_second_choice ] ;

        if ( ( $adjusted_first_choice != $actual_first_choice ) || ( $adjusted_second_choice != $actual_second_choice ) )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[error: in output_tally_table_numbers subroutine, actual and adjusted choice numbers do not match]" } ;
            warn "Error: Subroutine output_tally_table_numbers used inappropriately" ;
            return ;
        }

        &put_next_result_info_number( $global_voteinfo_code_for_first_choice ) ;
        &put_next_result_info_number( $actual_first_choice ) ;

        &put_next_result_info_number( $global_voteinfo_code_for_second_choice ) ;
        &put_next_result_info_number( $actual_second_choice ) ;

        &put_next_result_info_number( $global_voteinfo_code_for_tally_first_over_second ) ;
        &put_next_result_info_number( $global_tally_first_over_second_in_pair[ $pair_counter ] ) ;

        &put_next_result_info_number( $global_voteinfo_code_for_tally_second_over_first ) ;
        &put_next_result_info_number( $global_tally_second_over_first_in_pair[ $pair_counter ] ) ;

    }
    &put_next_result_info_number( $global_voteinfo_code_for_end_of_tally_table_results ) ;


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}




=head2 output_ranking_results

(Not exported, for internal use only.)

Outputs the results of the requested VoteFair
Ranking results.  These results are supplied in
two forms: in their sequence order, and in order
of their choice number.

=cut

#-----------------------------------------------
#-----------------------------------------------
#            output_ranking_results
#-----------------------------------------------
#-----------------------------------------------

sub output_ranking_results
{

    my $actual_choice ;
    my $ranking_level ;
    my $ranking_type_name ;
    my $ranking_type_number ;
    my $ranking_type_number_for_popularity ;
    my $ranking_type_number_for_representation ;
    my $ranking_type_number_for_party ;
    my $start_code ;
    my $end_code ;
    my $count_of_ranked_choices ;
    my $sum_of_rankings ;
    my $count_of_choices_found_at_this_ranking_level ;

    my @ranking_type_number_for_popularity ;
    my @ranking_type_number_for_representation ;
    my @ranking_type_number_for_party ;
    my @ranking_type_name_for_number ;
    my @sequence_start_code_for_ranking_type ;
    my @sequence_end_code_for_ranking_type ;
    my @levels_start_code_for_ranking_type ;
    my @levels_end_code_for_ranking_type ;
    my @ranking_level_result_for_actual_choice ;


#-----------------------------------------------
#  Set up lists that allow the different kinds
#  of ranking to have their associated code
#  numbers in indexed lists.

    $ranking_type_number_for_popularity = 1 ;
    $ranking_type_name_for_number[ $ranking_type_number_for_popularity ] = "popularity" ;
    $sequence_start_code_for_ranking_type[ $ranking_type_number_for_popularity ] = $global_voteinfo_code_for_start_of_votefair_popularity_ranking_sequence_results ;
    $sequence_end_code_for_ranking_type[ $ranking_type_number_for_popularity ] = $global_voteinfo_code_for_end_of_votefair_popularity_ranking_sequence_results ;
    $levels_start_code_for_ranking_type[ $ranking_type_number_for_popularity ] = $global_voteinfo_code_for_start_of_votefair_popularity_ranking_levels_results ;
    $levels_end_code_for_ranking_type[ $ranking_type_number_for_popularity ] = $global_voteinfo_code_for_end_of_votefair_popularity_ranking_levels_results ;

    $ranking_type_number_for_representation = 2 ;
    $ranking_type_name_for_number[ $ranking_type_number_for_representation ] = "representation" ;
    $sequence_start_code_for_ranking_type[ $ranking_type_number_for_representation ] = $global_voteinfo_code_for_start_of_votefair_representation_ranking_sequence_results ;
    $sequence_end_code_for_ranking_type[ $ranking_type_number_for_representation ] = $global_voteinfo_code_for_end_of_votefair_representation_ranking_sequence_results ;
    $levels_start_code_for_ranking_type[ $ranking_type_number_for_representation ] = $global_voteinfo_code_for_start_of_votefair_representation_ranking_levels_results ;
    $levels_end_code_for_ranking_type[ $ranking_type_number_for_representation ] = $global_voteinfo_code_for_end_of_votefair_representation_ranking_levels_results ;

    $ranking_type_number_for_party = 3 ;
    $ranking_type_name_for_number[ $ranking_type_number_for_party ] = "party" ;
    $sequence_start_code_for_ranking_type[ $ranking_type_number_for_party ] = $global_voteinfo_code_for_start_of_votefair_party_ranking_sequence_results ;
    $sequence_end_code_for_ranking_type[ $ranking_type_number_for_party ] = $global_voteinfo_code_for_end_of_votefair_party_ranking_sequence_results ;
    $levels_start_code_for_ranking_type[ $ranking_type_number_for_party ] = $global_voteinfo_code_for_start_of_votefair_party_ranking_levels_results ;
    $levels_end_code_for_ranking_type[ $ranking_type_number_for_party ] = $global_voteinfo_code_for_end_of_votefair_party_ranking_levels_results ;


#-----------------------------------------------
#  Begin a loop that handles each of the three
#  different ranking types.

    for ( $ranking_type_number = 1 ; $ranking_type_number <= 3 ; $ranking_type_number ++ )
    {
        $ranking_type_name = $ranking_type_name_for_number[ $ranking_type_number ] ;


#-----------------------------------------------
#  Copy the ranking levels for the kind of
#  ranking being sent to the code-number
#  output list.

        $sum_of_rankings = 0 ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            if ( $ranking_type_number == $ranking_type_number_for_popularity )
            {
                $ranking_level_result_for_actual_choice[ $actual_choice ] = $global_full_popularity_ranking_for_actual_choice[ $actual_choice ] ;
            } elsif ( $ranking_type_number == $ranking_type_number_for_representation )
            {
                $ranking_level_result_for_actual_choice[ $actual_choice ] = $global_full_representation_ranking_for_actual_choice[ $actual_choice ] ;
            } elsif ( $ranking_type_number == $ranking_type_number_for_party )
            {
                $ranking_level_result_for_actual_choice[ $actual_choice ] = $global_party_ranking_for_actual_choice[ $actual_choice ] ;
            }
            $sum_of_rankings += $ranking_level_result_for_actual_choice[ $actual_choice ] ;
        }


#-----------------------------------------------
#  If there are only zero ranking values,
#  create an error message, and skip the
#  outputting of these all-zero values.

        if ( $sum_of_rankings < 1 )
        {
            if ( $global_logging_info == $global_true ) { print LOGOUT "[output, all-zero results for " . $ranking_type_name . " ranking, so none written]\n" } ;
            next ;
        }


#-----------------------------------------------
#  Output specified ranking results as coded
#  numbers in which each choice is associated
#  with a ranking level.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[output, ranking results for " . $ranking_type_name . " ranking:]\n" } ;
        $start_code = $levels_start_code_for_ranking_type[ $ranking_type_number ] ;
        &put_next_result_info_number( $start_code ) ;
        for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
        {
            $ranking_level = $ranking_level_result_for_actual_choice[ $actual_choice ] ;
            &put_next_result_info_number( $global_voteinfo_code_for_choice ) ;
            &put_next_result_info_number( $actual_choice ) ;
            &put_next_result_info_number( $global_voteinfo_code_for_ranking_level ) ;
            &put_next_result_info_number( $ranking_level ) ;
            if ( $global_logging_info == $global_true ) { print LOGOUT "[output, choice " . $actual_choice . " is at ranking level " . $ranking_level  . "]\n" } ;
        }
        $end_code = $levels_end_code_for_ranking_type[ $ranking_type_number ] ;
        &put_next_result_info_number( $end_code ) ;


#-----------------------------------------------
#  Output the ranking as a sequence of
#  choice numbers, with ties and transitions (to
#  the next ranking level) indicated.

        if ( $global_logging_info == $global_true ) { print LOGOUT "[output, sequence results for " . $ranking_type_name . " ranking:]\n" } ;
        $start_code = $sequence_start_code_for_ranking_type[ $ranking_type_number ] ;
        &put_next_result_info_number( $start_code ) ;
        $count_of_ranked_choices = 0 ;
        for ( $ranking_level = 1 ; $ranking_level <= $global_full_choice_count ; $ranking_level ++ )
        {
            $count_of_choices_found_at_this_ranking_level = 0 ;
            for ( $actual_choice = 1 ; $actual_choice <= $global_full_choice_count ; $actual_choice ++ )
            {
                if ( $ranking_level_result_for_actual_choice[ $actual_choice ] == $ranking_level )
                {
                    if ( $count_of_choices_found_at_this_ranking_level > 0 )
                    {
                        &put_next_result_info_number( $global_voteinfo_code_for_tie ) ;
                    } elsif ( $count_of_ranked_choices > 0 )
                    {
                        &put_next_result_info_number( $global_voteinfo_code_for_next_ranking_level ) ;
                    }
                    &put_next_result_info_number( $global_voteinfo_code_for_choice ) ;
                    &put_next_result_info_number( $actual_choice ) ;
                    if ( $global_logging_info == $global_true ) { print LOGOUT "[output, choice " . $actual_choice . " is next in sequence at ranking level " . $ranking_level  . "]\n" } ;
                    $count_of_choices_found_at_this_ranking_level ++ ;
                    $count_of_ranked_choices ++ ;
                }
            }
        }
        if ( $count_of_ranked_choices < $global_full_choice_count )
        {
            &put_next_result_info_number( $global_voteinfo_code_for_early_end_of_ranking ) ;
        }
        $end_code = $sequence_end_code_for_ranking_type[ $ranking_type_number ] ;
        &put_next_result_info_number( $end_code ) ;
        if ( $global_logging_info == $global_true ) { print LOGOUT "[output, end of " . $ranking_type_name . " ranking sequence]\n" } ;


#-----------------------------------------------
#  Repeat the loop that handles each type of
#  ranking.

    }


#-----------------------------------------------
#  End of subroutine.

    return ;

}




=head1 AUTHOR

Richard Fobes, C<< <fobes at CPAN.org> >>


=head1 BUGS

Please report any bugs or feature requests on GitHub, at the CPSolver account, in the VoteFairRanking project area.  Thank you!


=head1 SUPPORT

You can find documentation for this module on GitHub, in the CPSolver account, in the VoteFairRanking project area.

You can find details about VoteFair Ranking at: www.VoteFair.org


=head1 ACKNOWLEDGEMENTS

Richard Fobes designed VoteFair Ranking and developed the original version of this code over a period of many years.  Richard Fobes is the author of the books titled "The Creative Problem Solver's Toolbox" and "Ending The Hidden Unfairness In U.S. Elections."


=head1 COPYRIGHT & LICENSE

(c) Copyright 1991 through 2011 Richard Fobes at www.VoteFair.org.  You can redistribute and/or modify this VoteFairRanking library module under the Perl Artistic license version 2.0 (a copy of which is included in the LICENSE file).  As required by the license this full copyright notice must be included in all copies of this software.

Conversion of this code into another programming language is also covered by the above license terms.

The mathematical algorithms of VoteFair Ranking are in the public domain.

=cut

1; # End of VoteFairRanking
