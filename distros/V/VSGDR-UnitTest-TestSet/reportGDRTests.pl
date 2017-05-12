#!/bin/perl

use Modern::Perl;
use strict;
use warnings;

use autodie qw(:all);
use version ; our $VERSION = qv('1.0.5');

use Carp;

our $opt_infile;
our $opt_warnings;
our $opt_disabled;
our $opt_reverse;
our $opt_totals;


use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;

use Array::Diff ;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use List::MoreUtils qw( uniq none) ;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation ;

use Smart::Comments;

use Data::Dumper;

my $warningsLevel               = 0 ;
$warningsLevel                  = $opt_warnings if ($opt_warnings) ;
my $includeDisabledConditions   = 0 ;
$includeDisabledConditions      = $opt_disabled if ($opt_disabled) ;

if ($opt_reverse)  {$opt_totals = 0 }  ;

croak 'no input file' unless defined($opt_infile) ;

my %ValidParserMakeArgs = ( vb  => "NET::VB"
                          , cs  => "NET::CS"
                          , xls => "XLS"
                          , xml => "XML"
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          

my %Parsers         = () ;

# #########################


    my @testNames                           = () ;
    my $tests_count                         = 0 ;
    my $conditions_count                    = 0 ;
    my $disabled_conditions_count           = 0 ;
    my $scalar_conditions_count             = 0 ;
    my $disabled_scalar_conditions_count    = 0 ;


    for my $testFile ( split /[,\s]/, $opt_infile ) {

        my %resSets          = () ;
        my %resSetBoundaries = () ;

        my %scalarConditionsByTestAndResultSetEtc = () ;
        my %rowCountConditionsByTestAndResultSetEtc = () ;
        my %resSetEmptyEtc = () ;
        my %resSetNotEmptyEtc = () ;

        (my $insfx  = $testFile)  =~ s/^.*\.//g;
        croak 'Invalid input file'   unless defined $insfx ;            
        $insfx  = lc $insfx ;

        die 'Invalid input file $testFile'  unless exists $ValidParserMakeArgs{$insfx} ;

        $Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } )
            if not exists $Parsers{${insfx}} ;
        # if input is in a .net language, add in a .net2 parser to the list
        if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
            $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } )
                if not exists $Parsers{"${insfx}2"} ;
        }

        my $testSet         = undef ;
        eval {
            $testSet         = $Parsers{$insfx}->deserialise($testFile);
            } ;
        if ( not defined $testSet ) {
            if ( exists $Parsers{"${insfx}2"}) {
                eval {
                    $testSet     = $Parsers{"${insfx}2"}->deserialise($testFile);
                    }
            }            
            else {
                croak 'Parsing failed.'; 
            }
        }


        my $ra_tests  = $testSet->tests() ;
        @testNames = map { $_->testName() } @{$ra_tests} ;

        $tests_count += @testNames ;


if ( ! $opt_reverse ) {
say "";
say "Test file: ${testFile}";
}
else {
}

        my $test_No = 0 ;
        for my $test (@$ra_tests) {


            $test_No++ ;

            my $ra_preTestConditions    = $test->preTest_conditions() ;
            my $ra_testConditions       = $test->test_conditions() ;
            my $ra_postTestConditions   = $test->postTest_conditions() ;

            my @scalarTestConditionNames        = map { $_->conditionName() } grep { $_->conditionEnabled() or $includeDisabledConditions } @{$ra_testConditions} ;
            my @scalarPreTestConditionNames     = map { $_->conditionName() } grep { $_->conditionEnabled() or $includeDisabledConditions } @{$ra_preTestConditions} ;
            my @scalarPostTestConditionNames    = map { $_->conditionName() } grep { $_->conditionEnabled() or $includeDisabledConditions } @{$ra_postTestConditions} ;

#warn Dumper @{$ra_testConditions} ;

            map { push @{$resSets{$test->testName()}}, $_->conditionResultSet() }
                @{$ra_testConditions} ;

            map { push @{$resSetBoundaries{$test->testName()}->{$_->conditionResultSet()}->{MAXROW}}, $_->conditionRowNumber() ;
                  push @{$resSetBoundaries{$test->testName()}->{$_->conditionResultSet()}->{MAXCOL}}, $_->conditionColumnNumber() ;
                }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'ScalarValue' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;

            map { # only add this info from rowcount assertion if we have a scalar value test for this resultset
                  if ( exists ($resSetBoundaries{$test->testName()}->{$_->conditionResultSet()}) ) {
                      push @{$resSetBoundaries{$test->testName()}->{$_->conditionResultSet()}->{MAXROW}}, $_->conditionRowCount() ;
                  }
                }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'RowCount' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;

            map { push @{$scalarConditionsByTestAndResultSetEtc{${test}->testName()}->{$_->conditionResultSet()}->{$_->conditionRowNumber()}->{$_->conditionColumnNumber()}}
                       , $_->conditionName() }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'ScalarValue' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;

            map { push @{$rowCountConditionsByTestAndResultSetEtc{${test}->testName()}->{$_->conditionResultSet()}}
                       , $_->conditionName() }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'RowCount' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;

            map { push @{$resSetEmptyEtc{${test}->testName()}->{$_->conditionResultSet()}}
                       , $_->conditionName() }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'EmptyResultSet' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;

            map { push @{$resSetNotEmptyEtc{${test}->testName()}->{$_->conditionResultSet()}}
                       , $_->conditionName() }
                grep { $_->conditionISEnabled() }
                grep { $_->testConditionType() eq 'NotEmptyResultSet' }
                ( @{$ra_testConditions}, @{$ra_preTestConditions}, @{$ra_postTestConditions} ) ;





if ( ! $opt_reverse ) {

{
local $" = "\n\t\t\t\t";
say "\tTest: @{[$test->testName()]}";
say "\t\tPre Conditions: @scalarPreTestConditionNames"  if @scalarPreTestConditionNames ;
say "\t\t    Conditions: @scalarTestConditionNames"     if @scalarTestConditionNames ;
say "\t\tPostConditions: @scalarPostTestConditionNames" if @scalarPostTestConditionNames ;
}
}
else {
say "@{[$test->testName()]}: ${testFile}";
}

            $conditions_count += scalar @{$ra_preTestConditions} ;
            $conditions_count += scalar @{$ra_testConditions} ;
            $conditions_count += scalar @{$ra_postTestConditions} ;

            my @scalarTestConditions     = grep { $_->testConditionType() eq 'ScalarValue' } @{$ra_testConditions} ;
            my @scalarPreTestConditions  = grep { $_->testConditionType() eq 'ScalarValue' } @{$ra_preTestConditions} ;
            my @scalarPostTestConditions = grep { $_->testConditionType() eq 'ScalarValue' } @{$ra_postTestConditions} ;

            $scalar_conditions_count += @scalarTestConditions ;
            $scalar_conditions_count += @scalarPreTestConditions ;
            $scalar_conditions_count += @scalarPostTestConditions ;

            my @disabledTestConditions     = grep { not $_->conditionISEnabled() } @{$ra_testConditions} ;
            my @disabledPreTestConditions  = grep { not $_->conditionISEnabled() } @{$ra_preTestConditions} ;
            my @disabledPostTestConditions = grep { not $_->conditionISEnabled() } @{$ra_postTestConditions} ;

            $disabled_conditions_count += @disabledTestConditions ;
            $disabled_conditions_count += @disabledPreTestConditions ;
            $disabled_conditions_count += @disabledPostTestConditions ;

            my @disabledscalarTestConditions     = grep { not $_->conditionISEnabled() and $_->testConditionType() eq 'ScalarValue' } @{$ra_testConditions} ;
            my @disabledscalarPreTestConditions  = grep { not $_->conditionISEnabled() and $_->testConditionType() eq 'ScalarValue' } @{$ra_preTestConditions} ;
            my @disabledscalarPostTestConditions = grep { not $_->conditionISEnabled() and $_->testConditionType() eq 'ScalarValue' } @{$ra_postTestConditions} ;

            $disabled_scalar_conditions_count += @disabledscalarTestConditions ;
            $disabled_scalar_conditions_count += @disabledscalarPreTestConditions ;
            $disabled_scalar_conditions_count += @disabledscalarPostTestConditions ;

        }

#warn Dumper %scalarConditionsByTestAndResultSetEtc;
#exit;

#warn Dumper %resSetBoundaries ;
    foreach my $test (keys %resSetBoundaries) {
    foreach my $RS   (keys %{$resSetBoundaries{$test}}) {

        my @rowVals   =  uniq(sort(@{$resSetBoundaries{$test}->{$RS}->{MAXROW}})) ;
        my @colVals   =  uniq(sort(@{$resSetBoundaries{$test}->{$RS}->{MAXCOL}})) ;

        my $rowVal= max @rowVals;
        my $colVal= max @colVals;

        $resSetBoundaries{$test}->{$RS}->{MAXROW}        = $rowVal ;
        $resSetBoundaries{$test}->{$RS}->{MAXCOL}        = $colVal ;

    }}




if ( $warningsLevel >= 1 ) {
    foreach my $test (keys %scalarConditionsByTestAndResultSetEtc) {
    foreach my $RS   (sort keys %{$scalarConditionsByTestAndResultSetEtc{$test}}) {
    foreach my $row  (sort keys %{$scalarConditionsByTestAndResultSetEtc{$test}{$RS}}) {
    foreach my $col  (sort keys %{$scalarConditionsByTestAndResultSetEtc{$test}{$RS}{$row}}) {
        if (scalar(@{$scalarConditionsByTestAndResultSetEtc{$test}{$RS}{$row}{$col}}) > 1 ) {
            local $" = ", ";
            warn "Test:${test} ResultSet:${RS} Row:${row} Col:${col} has multiple conditions specified:-\n";
            warn "\t@{$scalarConditionsByTestAndResultSetEtc{$test}{$RS}{$row}{$col}}\n";
        }
    }}}}


    foreach my $test (keys %rowCountConditionsByTestAndResultSetEtc) {
    foreach my $RS   (sort keys %{$rowCountConditionsByTestAndResultSetEtc{$test}}) {
        if (scalar(@{$rowCountConditionsByTestAndResultSetEtc{$test}{$RS}}) > 1 ) {
            local $" = ", ";
            warn "Test:${test} ResultSet:${RS} has multiple RowCount conditions specified:-\n";
            warn "\t@{$rowCountConditionsByTestAndResultSetEtc{$test}{$RS}}\n";
        }
        # check we haven't overlapped with a less stringent test on rowset size
        if (exists $resSetEmptyEtc{$test}->{$RS} or
            exists $resSetNotEmptyEtc{$test}->{$RS}
            ) {
            warn "Test:${test} ResultSet:${RS} has a redundant empty or non-empty ResultSet test:-\n";
            warn "\t$resSetEmptyEtc{$test}->{$RS}\n"
                if exists $resSetEmptyEtc{$test}->{$RS};
            warn "\t$resSetNotEmptyEtc{$test}->{$RS}\n"
                if exists $resSetNotEmptyEtc{$test}->{$RS};
        }
    }}

    foreach my $test (keys %resSetEmptyEtc) {
    foreach my $RS   (sort keys %{$resSetEmptyEtc{$test}}) {
        if (scalar(@{$resSetEmptyEtc{$test}{$RS}}) > 1 ) {
            local $" = ", ";
            warn "Test:${test} ResultSet:${RS} has multiple EmptyResultSet conditions specified:-\n";
            warn "\t@{$resSetEmptyEtc{$test}{$RS}}\n";
        }
    }}

    foreach my $test (keys %resSetNotEmptyEtc) {
    foreach my $RS   (sort keys %{$resSetNotEmptyEtc{$test}}) {
        if (scalar(@{$resSetNotEmptyEtc{$test}{$RS}}) > 1 ) {
            local $" = ", ";
            warn "Test:${test} ResultSet:${RS} has multiple NonEmptyResultSetconditions specified:-\n";
            warn "\t@{$resSetNotEmptyEtc{$test}{$RS}}\n";
        }
    }}
}


if ( $warningsLevel >= 1 ) {

    foreach my $test (keys %resSets) {

        my @vals   =  uniq( sort { $a <=> $b }  (@{$resSets{$test}}) ) ; # sort strings numerically, not alphabetically
#warn Dumper @vals;
        my $MinKey= min @vals;
        my $MaxKey= max @vals;

        my @range = 1 .. $MaxKey ;

        map  { $_ = "$_" } @range ;                                      # stringify sorted range numbers for comparison
#warn Dumper @range;
        my $diff = Array::Diff->diff( \@vals, \@range );
#warn Dumper $diff ;
        if ( ( $diff->count != 0)  or ( $MinKey > 1)  ) {
            local $" = ", ";
            my $added = $diff->added ;
            warn "Test:${test} does not have tests to cover all ResultSets, gaps exist for these ResultSets:-\n";
            warn "\t@{$added}\n";

        } ;
    }
}

my %missingScalarAssertions = () ;

    foreach my $test (keys %scalarConditionsByTestAndResultSetEtc) {
    foreach my $RS   (keys %{$scalarConditionsByTestAndResultSetEtc{$test}}) {
    foreach my $row  ( 1 .. $resSetBoundaries{$test}->{$RS}->{MAXROW} ) {
    foreach my $col  ( 1 .. $resSetBoundaries{$test}->{$RS}->{MAXCOL} ) {
        if ( (   not exists ( $scalarConditionsByTestAndResultSetEtc{$test}->{$RS}->{$row}->{$col} ) )
              or   ( exists ( $scalarConditionsByTestAndResultSetEtc{$test}->{$RS}->{$row}->{$col} )
                  and scalar(@{$scalarConditionsByTestAndResultSetEtc{$test}->{$RS}->{$row}->{$col}}) < 1
             )
           ) {
             $missingScalarAssertions{$test}->{$RS}->{ORIG}->[$row][$col] = 1 ;
        }
        else {
             $missingScalarAssertions{$test}->{$RS}->{ORIG}->[$row][$col] = 0 ;
        }
    }}

        my @origTable     = @{$missingScalarAssertions{$test}->{$RS}->{ORIG}} ;
        my @pivottedTable = () ;

        for ( my $r = 1; $r <= $#origTable ; $r++ ) {
            for ( my $c = 1; $c <= $#{$origTable[$r]} ; $c++ ) {
                $pivottedTable[$c][$r] = $origTable[$r][$c] ;
            }
        }
        $missingScalarAssertions{$test}->{$RS}->{PIVOTTED} = \@pivottedTable ;
    }}

if ( $warningsLevel >= 2 ) {

    foreach my $test (keys %missingScalarAssertions) {
    foreach my $RS   ( sort keys %{$missingScalarAssertions{$test}}) {

        my @Rows = @{$missingScalarAssertions{$test}->{$RS}->{ORIG}} ;
        my @Cols = @{$missingScalarAssertions{$test}->{$RS}->{PIVOTTED}} ;

        my @allBlankRows = () ;
        my @allBlankCols = () ;


        for (my $i = 1; $i <= $#Rows; $i++) {
            push @allBlankRows, $i
                if  none { $_ == 0 } grep {defined $_} @{$Rows[$i]} ;
        }
        for (my $i = 1; $i <= $#Cols; $i++) {
            push @allBlankCols, $i
                if  none { $_ == 0 } grep {defined $_} @{$Cols[$i]} ;
        }

        if ( $resSetBoundaries{$test}->{$RS}->{MAXROW} > 1 and $resSetBoundaries{$test}->{$RS}->{MAXCOL} > 1  ) {
            local $" = "," ;
            warn "Test:${test} ResultSet:${RS} has rows/columns with no scalar conditions:-\n"
                if scalar @allBlankRows or scalar @allBlankCols ;
            warn "\tRows :- @allBlankRows\n" if scalar @allBlankRows ;
            warn "\tCols :- @allBlankCols\n" if scalar @allBlankCols ;
        }
        for ( my $row = 1; $row <= $resSetBoundaries{$test}->{$RS}->{MAXROW}; $row++ ) {
            local $" = "," ;
            # skip if there is more than one column and all the values in the row are missing
            # as they've been reported above
            next if $resSetBoundaries{$test}->{$RS}->{MAXCOL} > 1 and grep { $row }  @allBlankRows ;
            my @blankCols = () ;
            for ( my $col = 1; $col <= $resSetBoundaries{$test}->{$RS}->{MAXCOL}; $col++ ) {
                # skip if there is more than one row and all the values in the column are missing
                # as they've been reported above
                next if $resSetBoundaries{$test}->{$RS}->{MAXROW} > 1 and grep { $col }  @allBlankCols ;
                push @blankCols, $col
                    if   exists $missingScalarAssertions{$test}->{$RS}->{ORIG}
                    and         $missingScalarAssertions{$test}->{$RS}->{ORIG}[$row][$col] == 1 ;

            }
            if ( scalar @blankCols ) {
                warn "Test:${test} ResultSet:${RS} row:$row has no scalar conditions in columns :-\n";
                warn "\t@blankCols\n";
            }
        }

    }}
}

    }

if ( $opt_totals ) {
    say "";
    say "Total tests                                    = ${tests_count}";
    say "Total test conditions                          = ${conditions_count}";
    say "Total disabled test conditions                 = ${disabled_conditions_count}";
    say "Total scalar value test conditions             = ${scalar_conditions_count}";
    say "Total disabled scalar value test conditions    = ${disabled_scalar_conditions_count}";
}

exit ;

END {}


__END__



=head1 NAME


reportGDRTests.pl - Reports on Test and Test Conditions within a GDR Unit Test file.



=head1 VERSION

1.0.5



=head1 USAGE

reportGDRTests.pl -i <file> [options]



=head1 OPTIONS


=over

=item  -t[otals]

Produce Totals Summary block.


=item  -d[isabled]

Include disabled Test Conditions in the report output.


=item  -r[everse]

Reverse output.  Show Test name followed by containing file.


=item  -w[arnings] [=]<level>

Write warnings to STDERR.  Warning level is 1 or 2.

=for Euclid:
    level.type:    +i

=back



=head1 REQUIRED ARGUMENTS


=over


=item  -i[n][file]  [=]<file>

Specify input file

=for Euclid:
    file.type:    readable



=back



=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2012, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)
