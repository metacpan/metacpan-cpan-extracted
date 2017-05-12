#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {

use_ok('Voting::VoteFairRanking');


#-------------------------------------------
#-------------------------------------------
#  Declare global variables.

my $global_vote_info;
my $global_test_results_text;
my $global_test_OK_counter;
my $global_test_number_count;
my $global_being_tested;
my $global_expected_result;


#-------------------------------------------
#-------------------------------------------
#  Subroutine that handles the overhead of
#  the vote-data-specific tests (which are
#  done after the initial tests).

sub do_test
{

	my $string_return_value;

	$global_test_number_count ++;
	&Voting::VoteFairRanking::votefair_start_new_cases( );
	$global_test_results_text .= "\n[vote info: " . $global_vote_info . "]\n\n";
	$string_return_value = &Voting::VoteFairRanking::votefair_put_input_string( $global_vote_info );
	$global_test_results_text .= "[results: " . $string_return_value;
	$string_return_value = &Voting::VoteFairRanking::votefair_do_calculations_all_questions( );
	$global_test_results_text .= $string_return_value;
	$string_return_value = &Voting::VoteFairRanking::votefair_get_output_string( );
	$global_test_results_text .= $string_return_value . "]\n\n";
	$global_test_results_text .= "[expected all or portion of results: " . $global_expected_result . "]\n\n";
	if ( index( $string_return_value , $global_expected_result ) >= 0 )
	{
		$global_test_OK_counter ++;
		$global_test_results_text .= $global_being_tested . "OK\n\n";
	} else
	{
		$global_test_results_text .= "\n\n" . $global_being_tested . "ERROR\n\n\n\n";
	}

}

#-------------------------------------------
#  Declare remaining variables.

my $string_return_value ;
my $one_if_ok ;
my $filename ;
my $test_failed_counter;


#-------------------------------------------
#  Initialization.

$global_test_number_count = 0;
$global_test_OK_counter = 0;
$global_test_results_text = "";


#-------------------------------------------
#  Specify the test data for next several 
#  tests.

$global_vote_info = "request-no-rep  request-no-party   case 1  q 1  choices 4   x 1 q 1  1 2 3 4   x 1 q 1  2 4 1 3   x 2 q 1  4 2 1 3";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 1 ch 3 plur 0 ch 4 plur 2 end-plurality tallies ch1 1 ch2 2 1over2 1 2over1 3 ch1 1 ch2 3 1over2 4 2over1 0 ch1 1 ch2 4 1over2 1 2over1 3 ch1 2 ch2 3 1over2 4 2over1 0 ch1 2 ch2 4 1over2 2 2over1 2 ch1 3 ch2 4 1over2 1 2over1 3 end-tallies popularity-levels ch 1 level 2 ch 2 level 1 ch 3 level 3 ch 4 level 1 end-pop-levels popularity-sequence ch 2 tie ch 4 next-level ch 1 next-level ch 3 end-pop-seq votes 4 endallcases";


#-------------------------------------------

$global_being_tested = "put vote info -- ";

$global_test_number_count ++;
$string_return_value = &Voting::VoteFairRanking::votefair_put_input_string( $global_vote_info );
if ( $string_return_value eq "" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $global_test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $global_test_results_text .= $global_being_tested . "OK\n" } else { $global_test_results_text .= $global_being_tested . "ERROR\n\n" };

$global_test_results_text .= "\n";


#-------------------------------------------

$global_being_tested = "do calculations -- ";

$global_test_number_count ++;
$string_return_value = &Voting::VoteFairRanking::votefair_do_calculations_all_questions( );
if ( $string_return_value eq "" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $global_test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $global_test_results_text .= $global_being_tested . "OK\n" } else { $global_test_results_text .= $global_being_tested . "ERROR\n\n" };

$global_test_results_text .= "\n";


#-------------------------------------------

$global_being_tested = "get results -- ";

$global_test_number_count ++;
$string_return_value = &Voting::VoteFairRanking::votefair_get_output_string( );
if ( index( $string_return_value , $global_expected_result ) >= 0 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $global_test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $global_test_results_text .= $global_being_tested . "OK\n" } else { $global_test_results_text .= $global_being_tested . "ERROR\n\n" };


#-------------------------------------------

$global_being_tested = "same data, second pass through code, now using test subroutine -- ";

&do_test( );


#-------------------------------------------
#-------------------------------------------
#  Begin using different test data.

#-------------------------------------------

$global_being_tested = "same preferences but different ballot format -- ";

$global_vote_info = "request-no-rep  request-no-party   case 1  q 1  choices 4   startcase   q 1 x 1 1 2 3 4 b   bal x 1 q 1 2 4 1 3 b   x 2 q 1 4 2 1 3   endcase";

&do_test( );


#-------------------------------------------

$global_being_tested = "same preferences but yet another ballot format -- ";

$global_vote_info = "request-no-rep  request-no-party   case 1  q 1  choices 4   startcase   q 1 x 1  pref 3 ch 3 pref 4 ch 4 pref 1 ch 1 pref 2 ch 2 b   bal x 1 q 1 pref 3 ch 1 pref 4 ch 3 pref 1 ch 2 pref 2 ch 4 b   x 2 q 1 pref 3 1 pref 4 3 pref 1 4 pref 2 2   endcase";

&do_test( );


#-------------------------------------------

$global_being_tested = "two cases, two questions, two ballots, various choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts case 1  q 1  choices 4  q 2  choices 3  x 1  q 1  1 2 3 4  q 2  2 3 1  endcase  case 2  q 1  choices 2  q 2  choices 1  x 1  q 1  2 1  q 2  1  x 1  q 2  1  q 1  1 2";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 0 ch 3 plur 0 ch 4 plur 0 end-plurality popularity-levels ch 1 level 1 ch 2 level 2 ch 3 level 3 ch 4 level 4 end-pop-levels popularity-sequence ch 1 next-level ch 2 next-level ch 3 next-level ch 4 end-pop-seq votes 1 q 2 plurality ch 1 plur 0 ch 2 plur 1 ch 3 plur 0 end-plurality popularity-levels ch 1 level 3 ch 2 level 1 ch 3 level 2 end-pop-levels popularity-sequence ch 2 next-level ch 3 next-level ch 1 end-pop-seq votes 1 case 2 q 1 plurality ch 1 plur 1 ch 2 plur 1 end-plurality popularity-levels ch 1 level 1 ch 2 level 1 end-pop-levels popularity-sequence ch 1 tie ch 2 end-pop-seq rep-levels ch 1 level 1 ch 2 level 1 end-rep-levels rep-seq ch 1 tie ch 2 end-rep-seq votes 2 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "zero ballots (which is invalid) -- ";

$global_vote_info = "case 1 q 1 choices 6";

$global_expected_result = "case-skipped";

&do_test( );


#-------------------------------------------

$global_being_tested = "one choice (which is invalid) -- ";

$global_vote_info = "case 1 q 1 choices 1  x 1 q 1 1  x 1 q 1 1";

$global_expected_result = "case-skipped";

&do_test( );


#-------------------------------------------

$global_being_tested = "two choices, two ballots -- ";

$global_vote_info = "request-rep  request-party  case 1 q 1 choices 2  x 1 q 1 1 2  x 1 q 1 2";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 1 end-plurality tallies ch1 1 ch2 2 1over2 1 2over1 1 end-tallies popularity-levels ch 1 level 1 ch 2 level 1 end-pop-levels popularity-sequence ch 1 tie ch 2 end-pop-seq rep-levels ch 1 level 1 ch 2 level 1 end-rep-levels rep-seq ch 1 tie ch 2 end-rep-seq votes 2 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "three ballots, three choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 3  x 1 q 1 1 2 3  x 1 q 1 2 3 1  x 1 q 1 3 1 2";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 1 ch 3 plur 1 end-plurality popularity-levels ch 1 level 1 ch 2 level 1 ch 3 level 1 end-pop-levels popularity-sequence ch 1 tie ch 2 tie ch 3 end-pop-seq rep-levels ch 1 level 1 ch 2 level 1 ch 3 level 1 end-rep-levels rep-seq ch 1 tie ch 2 tie ch 3 end-rep-seq party-levels ch 1 level 1 ch 2 level 1 ch 3 level 1 end-party-levels party-seq ch 1 tie ch 2 tie ch 3 end-party-seq votes 3 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "request plurality results only, three ballots, three choices -- ";

$global_vote_info = "request-plurality-only  case 1 q 1 choices 3  x 1 q 1 1 2 3  x 2 q 1 2 3 1  x 3 q 1 3 1 2";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 2 ch 3 plur 3 end-plurality votes 6 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "three cases, with four, five, and six ballots -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 4  x 1 q 1 3 2 4 1  x 1 q 1 4 1 2 3  x 1 q 1 2 3 1 4  x 1 q 1 2 4 3 1 case 2 q 1 choices 5  x 1 q 1 3 tie 2 5 tie 1 4  x 1 q 1 2 tie 4 1 2  x 1 q 1 5  x 1 q 1 3 1 2 4  x 1 q 1 5 2 3 case 3 q 1 choices 6  x 1 q 1 1 2 tie 3 tie 4 tie 5 tie 6  x 1 q 1 2 6 1 4 tie 3  x 1 q 1 6 1 2  x 1 q 1 4 2 3 1  x 1 q 1  2 3 4 5 6 1  x 1 q 1 2 1 5 6 4 3";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 0 ch 2 plur 2 ch 3 plur 1 ch 4 plur 1 end-plurality popularity-levels ch 1 level 3 ch 2 level 1 ch 3 level 2 ch 4 level 2 end-pop-levels popularity-sequence ch 2 next-level ch 3 tie ch 4 next-level ch 1 end-pop-seq rep-levels ch 1 level 4 ch 2 level 1 ch 3 level 3 ch 4 level 2 end-rep-levels rep-seq ch 2 next-level ch 4 next-level ch 3 next-level ch 1 end-rep-seq party-levels ch 1 level 4 ch 2 level 1 ch 3 level 3 ch 4 level 2 end-party-levels party-seq ch 2 next-level ch 4 next-level ch 3 next-level ch 1 end-party-seq votes 4 case 2 q 1 plurality ch 1 plur 0 ch 2 plur 0 ch 3 plur 1 ch 4 plur 0 ch 5 plur 2 end-plurality popularity-levels ch 1 level 4 ch 2 level 1 ch 3 level 2 ch 4 level 5 ch 5 level 3 end-pop-levels popularity-sequence ch 2 next-level ch 3 next-level ch 5 next-level ch 1 next-level ch 4 end-pop-seq rep-levels ch 1 level 5 ch 2 level 1 ch 3 level 3 ch 4 level 4 ch 5 level 2 end-rep-levels rep-seq ch 2 next-level ch 5 next-level ch 3 next-level ch 4 next-level ch 1 end-rep-seq party-levels ch 1 level 3 ch 2 level 1 ch 3 level 3 ch 4 level 3 ch 5 level 2 end-party-levels party-seq ch 2 next-level ch 5 next-level ch 1 tie ch 3 tie ch 4 end-party-seq votes 5 case 3 q 1 plurality ch 1 plur 1 ch 2 plur 3 ch 3 plur 0 ch 4 plur 1 ch 5 plur 0 ch 6 plur 1 end-plurality popularity-levels ch 1 level 2 ch 2 level 1 ch 3 level 4 ch 4 level 3 ch 5 level 5 ch 6 level 2 end-pop-levels popularity-sequence ch 2 next-level ch 1 tie ch 6 next-level ch 4 next-level ch 3 next-level ch 5 end-pop-seq rep-levels ch 1 level 2 ch 2 level 1 ch 3 level 3 ch 4 level 3 ch 5 level 3 ch 6 level 2 end-rep-levels rep-seq ch 2 next-level ch 1 tie ch 6 next-level ch 3 tie ch 4 tie ch 5 end-rep-seq party-levels ch 1 level 2 ch 2 level 1 ch 3 level 3 ch 4 level 3 ch 5 level 3 ch 6 level 2 end-party-levels party-seq ch 2 next-level ch 1 tie ch 6 next-level ch 3 tie ch 4 tie ch 5 end-party-seq votes 6 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "seven choices and ballots -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 7  x 1 q 1 1 2 tie 3  x 1 q 1 3 2 5  x 1 q 1 6 4 2  x 1 q 1 1 3 5  x 1 q 1 5 4 3 2  x 1 q 1 6 4 5 1 2  x 1 q 1 5 1 2 3";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 2 ch 2 plur 0 ch 3 plur 1 ch 4 plur 0 ch 5 plur 2 ch 6 plur 2 ch 7 plur 0 end-plurality popularity-levels ch 1 level 2 ch 2 level 3 ch 3 level 3 ch 4 level 5 ch 5 level 1 ch 6 level 4 ch 7 level 6 end-pop-levels popularity-sequence ch 5 next-level ch 1 next-level ch 2 tie ch 3 next-level ch 6 next-level ch 4 next-level ch 7 end-pop-seq rep-levels ch 1 level 2 ch 2 level 3 ch 3 level 3 ch 4 level 4 ch 5 level 1 ch 6 level 4 ch 7 level 4 end-rep-levels rep-seq ch 5 next-level ch 1 next-level ch 2 tie ch 3 next-level ch 4 tie ch 6 tie ch 7 end-rep-seq party-levels ch 1 level 2 ch 2 level 6 ch 3 level 4 ch 4 level 5 ch 5 level 1 ch 6 level 3 ch 7 level 7 end-party-levels party-seq ch 5 next-level ch 1 next-level ch 6 next-level ch 3 next-level ch 4 next-level ch 2 next-level ch 7 end-party-seq votes 7 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "eight choices and ballots -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 8  x 1 q 1 7 1 3 2 4 5 6  x 1 q 1 3 4 5 2  x 1 q 1 2 6 1 2  x 1 q 1 2 4 1 3  x 1 q 1 2 4 5 3 1  x 1 q 1 6 2 3 4  x 1 q 1 7 1 3 2 4 5  x 1 q 1 8 3 4 2 5 1";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 0 ch 2 plur 3 ch 3 plur 1 ch 4 plur 0 ch 5 plur 0 ch 6 plur 1 ch 7 plur 2 ch 8 plur 1 end-plurality popularity-levels ch 1 level 3 ch 2 level 1 ch 3 level 1 ch 4 level 2 ch 5 level 4 ch 6 level 5 ch 7 level 5 ch 8 level 6 end-pop-levels popularity-sequence ch 2 tie ch 3 next-level ch 4 next-level ch 1 next-level ch 5 next-level ch 6 tie ch 7 next-level ch 8 end-pop-seq rep-levels ch 1 level 2 ch 2 level 1 ch 3 level 1 ch 4 level 2 ch 5 level 2 ch 6 level 2 ch 7 level 2 ch 8 level 2 end-rep-levels rep-seq ch 2 tie ch 3 next-level ch 1 tie ch 4 tie ch 5 tie ch 6 tie ch 7 tie ch 8 end-rep-seq party-levels ch 1 level 3 ch 2 level 1 ch 3 level 1 ch 4 level 4 ch 5 level 5 ch 6 level 6 ch 7 level 6 ch 8 level 7 end-party-levels party-seq ch 2 tie ch 3 next-level ch 1 next-level ch 4 next-level ch 5 next-level ch 6 tie ch 7 next-level ch 8 end-party-seq votes 8 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "nine choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 9  x 1 q 1 9 2 3 4 5 1  x 1 q 1 8 2 3 5 6 4  x 1 q 1 7 2 4 3 5 1  x 1 q 1 6 1 2 4 3  x 1 q 1 5 3 8 2 4  x 1 q 1 4 2 8 4 6  x 1 q 1 4 8 9 2 7 3  x 1 q 1 3 2 9 3 7  x 1 q 1 2 4 9 8 4 5  x 1 q 1 1 3 6 8 9 2 4 5";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 1 ch 2 plur 1 ch 3 plur 1 ch 4 plur 2 ch 5 plur 1 ch 6 plur 1 ch 7 plur 1 ch 8 plur 1 ch 9 plur 1 end-plurality popularity-levels ch 1 level 8 ch 2 level 1 ch 3 level 2 ch 4 level 4 ch 5 level 6 ch 6 level 7 ch 7 level 9 ch 8 level 3 ch 9 level 5 end-pop-levels popularity-sequence ch 2 next-level ch 3 next-level ch 8 next-level ch 4 next-level ch 9 next-level ch 5 next-level ch 6 next-level ch 1 next-level ch 7 end-pop-seq rep-levels ch 1 level 0 ch 2 level 1 ch 3 level 2 ch 4 level 4 ch 5 level 6 ch 6 level 0 ch 7 level 0 ch 8 level 3 ch 9 level 5 end-rep-levels rep-seq ch 2 next-level ch 3 next-level ch 8 next-level ch 4 next-level ch 9 next-level ch 5 end-seq-early end-rep-seq party-levels ch 1 level 4 ch 2 level 1 ch 3 level 2 ch 4 level 3 ch 5 level 4 ch 6 level 4 ch 7 level 4 ch 8 level 3 ch 9 level 4 end-party-levels party-seq ch 2 next-level ch 3 next-level ch 4 tie ch 8 next-level ch 1 tie ch 5 tie ch 6 tie ch 7 tie ch 9 end-party-seq votes 10 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "ten choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 10  x 3 q 1 10 7 6 4 8 2 3  x 3 q 1 3 8 5 9 1 3 2  x 4 q 1 3 2 8 10 4 5";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 0 ch 2 plur 0 ch 3 plur 7 ch 4 plur 0 ch 5 plur 0 ch 6 plur 0 ch 7 plur 0 ch 8 plur 0 ch 9 plur 0 ch 10 plur 3 end-plurality popularity-levels ch 1 level 8 ch 2 level 3 ch 3 level 2 ch 4 level 5 ch 5 level 6 ch 6 level 8 ch 7 level 7 ch 8 level 1 ch 9 level 7 ch 10 level 4 end-pop-levels popularity-sequence ch 8 next-level ch 3 next-level ch 2 next-level ch 10 next-level ch 4 next-level ch 5 next-level ch 7 tie ch 9 next-level ch 1 tie ch 6 end-pop-seq rep-levels ch 1 level 0 ch 2 level 3 ch 3 level 2 ch 4 level 5 ch 5 level 6 ch 6 level 0 ch 7 level 0 ch 8 level 1 ch 9 level 0 ch 10 level 4 end-rep-levels rep-seq ch 8 next-level ch 3 next-level ch 2 next-level ch 10 next-level ch 4 next-level ch 5 end-seq-early end-rep-seq party-levels ch 1 level 8 ch 2 level 4 ch 3 level 2 ch 4 level 6 ch 5 level 3 ch 6 level 8 ch 7 level 7 ch 8 level 1 ch 9 level 7 ch 10 level 5 end-party-levels party-seq ch 8 next-level ch 3 next-level ch 5 next-level ch 2 next-level ch 10 next-level ch 4 next-level ch 7 tie ch 9 next-level ch 1 tie ch 6 end-party-seq votes 10 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "eleven choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 11   x 6 q 1 5 11 2 10 8 9 6  x 5 q 1 2 1 10 tie 11 6 3 5";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 0 ch 2 plur 5 ch 3 plur 0 ch 4 plur 0 ch 5 plur 6 ch 6 plur 0 ch 7 plur 0 ch 8 plur 0 ch 9 plur 0 ch 10 plur 0 ch 11 plur 0 end-plurality popularity-levels ch 1 level 8 ch 2 level 3 ch 3 level 9 ch 4 level 10 ch 5 level 1 ch 6 level 7 ch 7 level 10 ch 8 level 5 ch 9 level 6 ch 10 level 4 ch 11 level 2 end-pop-levels popularity-sequence ch 5 next-level ch 11 next-level ch 2 next-level ch 10 next-level ch 8 next-level ch 9 next-level ch 6 next-level ch 1 next-level ch 3 next-level ch 4 tie ch 7 end-pop-seq rep-levels ch 1 level 0 ch 2 level 2 ch 3 level 0 ch 4 level 0 ch 5 level 1 ch 6 level 0 ch 7 level 0 ch 8 level 5 ch 9 level 6 ch 10 level 4 ch 11 level 3 end-rep-levels rep-seq ch 5 next-level ch 2 next-level ch 11 next-level ch 10 next-level ch 8 next-level ch 9 end-seq-early end-rep-seq party-levels ch 1 level 8 ch 2 level 2 ch 3 level 2 ch 4 level 2 ch 5 level 1 ch 6 level 7 ch 7 level 2 ch 8 level 5 ch 9 level 6 ch 10 level 4 ch 11 level 3 end-party-levels party-seq ch 5 next-level ch 2 tie ch 3 tie ch 4 tie ch 7 next-level ch 11 next-level ch 10 next-level ch 8 next-level ch 9 next-level ch 6 next-level ch 1 end-party-seq votes 11 endallcases";

&do_test( );


#-------------------------------------------

$global_being_tested = "twelve choices -- ";

$global_vote_info = "request-rep  request-party  request-no-pairwise-counts  case 1 q 1 choices 12  x 4 q 1 12 9 3 8 4 2 10 5  x 4 q 1 3 12 2 10 7 3 9 8 4  x 4 q 1 6 10 11 9 7 4 3 12 5 2 8";

$global_expected_result = "case 1 q 1 plurality ch 1 plur 0 ch 2 plur 0 ch 3 plur 4 ch 4 plur 0 ch 5 plur 0 ch 6 plur 4 ch 7 plur 0 ch 8 plur 0 ch 9 plur 0 ch 10 plur 0 ch 11 plur 0 ch 12 plur 4 end-plurality popularity-levels ch 1 level 10 ch 2 level 3 ch 3 level 4 ch 4 level 5 ch 5 level 8 ch 6 level 7 ch 7 level 4 ch 8 level 6 ch 9 level 2 ch 10 level 2 ch 11 level 9 ch 12 level 1 end-pop-levels popularity-sequence ch 12 next-level ch 9 tie ch 10 next-level ch 2 next-level ch 3 tie ch 7 next-level ch 4 next-level ch 8 next-level ch 6 next-level ch 5 next-level ch 11 next-level ch 1 end-pop-seq rep-levels ch 1 level 3 ch 2 level 2 ch 3 level 3 ch 4 level 3 ch 5 level 3 ch 6 level 2 ch 7 level 3 ch 8 level 3 ch 9 level 3 ch 10 level 2 ch 11 level 3 ch 12 level 1 end-rep-levels rep-seq ch 12 next-level ch 2 tie ch 6 tie ch 10 next-level ch 1 tie ch 3 tie ch 4 tie ch 5 tie ch 7 tie ch 8 tie ch 9 tie ch 11 end-rep-seq party-levels ch 1 level 3 ch 2 level 2 ch 3 level 3 ch 4 level 3 ch 5 level 3 ch 6 level 2 ch 7 level 3 ch 8 level 3 ch 9 level 3 ch 10 level 2 ch 11 level 3 ch 12 level 1 end-party-levels party-seq ch 12 next-level ch 2 tie ch 6 tie ch 10 next-level ch 1 tie ch 3 tie ch 4 tie ch 5 tie ch 7 tie ch 8 tie ch 9 tie ch 11 end-party-seq votes 12 endallcases";

&do_test( );


#-------------------------------------------
#  Write results, including the count of
#  successful tests.

$filename = "output_test_results.txt";
open ( OUTFILE , ">" . $filename );

$global_test_results_text .= "\n";
if ( $global_test_OK_counter == $global_test_number_count )
{
    $global_test_results_text .= "All " . $global_test_OK_counter . " sub-tests were successful!\n";
} else
{
    $test_failed_counter = $global_test_number_count - $global_test_OK_counter;
    $global_test_results_text .= "Failed " . $test_failed_counter . " sub-tests!\nSee test output file (" . $filename . ") for details.\n";
}
print OUTFILE $global_test_results_text;
close OUTFILE;


#-------------------------------------------
#  If all test results OK, indicate pass for
#  CPAN module test.

if ( $global_test_OK_counter == $global_test_number_count ) {
    pass("Passed all $global_test_OK_counter sub-tests out of $global_test_number_count");
} else {
    fail("Failed $test_failed_counter sub-tests out of $global_test_number_count, see file $filename for details");
}


#-------------------------------------------
#  All done testing.

}
