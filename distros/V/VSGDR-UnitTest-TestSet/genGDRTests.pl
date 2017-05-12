#!/bin/perl

use Modern::Perl;
use strict;
use warnings;
use autodie qw(:all);
no indirect ':fatal';



#TODO:  1.  Add some form of support for Pre/Post init/cleardown condition generation.

use Carp;
use DBI;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Resx;

use VSGDR::SQLServer::DataType;

use Readonly ;
use List::MoreUtils qw(any) ;

use File::Basename;
use Smart::Comments;
use Try::Tiny;


use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use Data::Dumper;

use version ; our $VERSION = qv('1.4.1');

our @opt_infile;
our @opt_outfile;
our $opt_noscalarValues;
our $opt_notypes;
our $opt_version;
our $opt_connection;
our @opt_resultSets;
our $opt_pconnection;
our $opt_initfile;
our $opt_prefile;
our $opt_postfile;
our $opt_cleanupfile;
our $opt_namespace;
our $opt_noRunTestsToGenerateResults;

#warn $opt_norunTestsToGenerateResults;
#exit;
my $version             = $opt_version ;


my $opt_scalarValues        = !$opt_noscalarValues;
my $opt_types               = !$opt_notypes;
my $gen_types               = 0;
$gen_types                  = (!$opt_notypes) if defined $opt_notypes ;

my $dataBase                = $opt_connection;
my $priv_dataBase           = undef ;
$priv_dataBase              = $opt_pconnection if defined $opt_pconnection ;


my @resultSets              = () ;
   @resultSets              = @opt_resultSets if @opt_resultSets ;
my $generateAllResultSets   = ! ( scalar @resultSets ) ;
my $generateScalarChecks    = $opt_scalarValues ;
my $generatePassedResults   = $opt_norunTestsToGenerateResults ;

my %Parsers = () ;
my %ValidParserMakeArgs = ( vb  => 'NET::VB'
                          , cs  => 'NET::CS'
                          , xls => 'XLS'
                          , xml => 'XML'
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          
                          
my @validSuffixes       = map { '.'.$_ } keys %ValidParserMakeArgs ;

### Connect to database

my $dbh             = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, RaiseError => 1 });
my $dbh_typeinfo    = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, RaiseError => 1 });

# Always create a $priv_dbh handle, re-use the normal database dsn if no privileged dsn specified.
my $priv_dbh    = undef ;
if ( defined $priv_dataBase ) {
    $priv_dbh       = DBI->connect("dbi:ODBC:${priv_dataBase}", q{}, q{}, { AutoCommit => 1, RaiseError => 1 })
}
else {
    $priv_dbh       = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, RaiseError => 1 })
}


my $initSQL             = undef ;
my $cleardownSQL        = undef ;
my $PreTestSQL          = undef ;
my $PostTestSQL         = undef ;

$initSQL                = getFile($opt_initfile)                    if defined $opt_initfile ;
$cleardownSQL           = getFile($opt_cleanupfile)                 if defined $opt_cleanupfile ;
$PreTestSQL             = getFile($opt_prefile)                     if defined $opt_prefile ;
$PostTestSQL            = getFile($opt_postfile)                    if defined $opt_postfile ;

my $origInitSQL         = $initSQL ;
my $origCleardownSQL    = $cleardownSQL ;
my $origPreTestSQL      = $PreTestSQL ;
my $origPostTestSQL     = $PostTestSQL ;

$initSQL                = $dbh->quote($initSQL)                     if $initSQL ;
$cleardownSQL           = $dbh->quote($cleardownSQL)                if $cleardownSQL ;
$PreTestSQL             = $dbh->quote($PreTestSQL)                  if $PreTestSQL ;
$PostTestSQL            = $dbh->quote($PostTestSQL)                 if $PostTestSQL;

$initSQL                = 'exec sp_executesql N' . $initSQL         if $initSQL ;
$cleardownSQL           = 'exec sp_executesql N' . $cleardownSQL    if $cleardownSQL ;
$PreTestSQL             = 'exec sp_executesql N' . $PreTestSQL      if $PreTestSQL ;
$PostTestSQL            = 'exec sp_executesql N' . $PostTestSQL     if $PostTestSQL;


for ( my $i=0; $i <= $#opt_infile; $i++ ) {  ## Process SQL scripts:::                 done

    my $infile    = $opt_infile[$i];
    my($infname, $indirectories, $insfx)    = fileparse($infile, @validSuffixes);
    croak 'Invalid input file'   unless defined $insfx ;    
    $insfx        = lc $insfx ;

    my $outfile   = $opt_outfile[$i];
    my($outfname, $outdirectories, $outsfx) = fileparse($outfile, @validSuffixes);
    croak 'Invalid output file'   unless defined $outsfx ;        
    $outsfx       = substr(lc $outsfx,1) ;

#warn Dumper $insfx;
#warn Dumper $outsfx;

    croak 'Invalid output file' unless exists $ValidParserMakeArgs{$outsfx} ;

    # if output is needed in ssdt unit test format  add in a .net2 parser to the list
    if ($version == 1)  {
        $Parsers{${outsfx}}    = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${outsfx}} } );
    }
    else {
        $Parsers{"${outsfx}2"} = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${outsfx}} } );
    }

    my $testSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE        => "${opt_namespace}"
                                                  , CLASSNAME        => "${outfname}_cls"
                                                  }
                                                ) ;


    $testSet->initializeAction($testSet->initializeActionLiteral())
        if $initSQL  ;
    $testSet->cleanupAction($testSet->cleanupActionLiteral())
        if $cleardownSQL  ;

    my $PreTestActionName   = 'null' ;
    my $PostTestActionName  = 'null' ;
    my $TestActionName      = "${outfname}_TestAction" ;

    $PreTestActionName      = "${outfname}_PreTestAction"   if $PreTestSQL ;
    $PostTestActionName     = "${outfname}_PostTestAction"  if $PostTestSQL ;

    my $test = VSGDR::UnitTest::TestSet::Test->new( { TESTNAME             => "${outfname}"
                                                     , TESTACTIONDATANAME   => "${outfname}Data"
                                                     , PRETESTACTION        => ${PreTestActionName}
                                                     , TESTACTION           => ${TestActionName}
                                                     , POSTTESTACTION       => ${PostTestActionName}
                                                     }
                                                   ) ;

### Open script files

    my $TestSQL     = getFile($infile)  ;
    my $origTestSQL = $TestSQL ;

    $TestSQL = $dbh->quote($TestSQL) ;
    $TestSQL = 'exec sp_executesql N' . $TestSQL ;

	
	my @testConditions = () ;
	my $conditionNamePrefix             = "${outfname}_Res_" ;
	
	Readonly::Scalar  my $testConditionTypeRC => 'RowCount' ;
	Readonly::Scalar  my $testConditionTypeSV => 'ScalarValue' ;
	
	if ( $generatePassedResults ) {

		my $testConditionRC = VSGDR::UnitTest::TestSet::Test::TestCondition->make(
					{ TESTCONDITIONTYPE         => $testConditionTypeRC
					, CONDITIONTESTACTIONNAME   => ${TestActionName}
					, CONDITIONNAME             => ${conditionNamePrefix} . "1_RowCount"
					, CONDITIONENABLED          => 'True'
					, CONDITIONROWCOUNT         => 1
					, CONDITIONRESULTSET        => 1
					} ) ;
		push @testConditions, $testConditionRC ;
	
		my $testConditionSV = VSGDR::UnitTest::TestSet::Test::TestCondition->make(
					{ TESTCONDITIONTYPE         => $testConditionTypeSV
					, CONDITIONTESTACTIONNAME   => ${TestActionName}
					, CONDITIONNAME             => ${conditionNamePrefix} . '1_Col_1'
					, CONDITIONENABLED          => 'True'
					, CONDITIONEXPECTEDVALUE    => '"Passed"'
					, CONDITIONNULLEXPECTED     => 'False'
					, CONDITIONRESULTSET        => 1
					, CONDITIONROWNUMBER        => 1
					, CONDITIONCOLUMNNUMBER     => 1
					} ) ;
	
		push @testConditions, $testConditionSV ;

	}
	else { 
		if ( $initSQL ) {
### 	Run initialisation script
			my $p_sth = $priv_dbh->prepare($initSQL,{odbc_exec_direct => 1});
			$p_sth->execute();
		}
		if ( $PreTestSQL ) {
### 	Run pre-test script
			my $p_sth = $priv_dbh->prepare($PreTestSQL,{odbc_exec_direct => 1});
			$p_sth->execute();
		}
	
### 	Run test script once
	
		my @run1_res ;
		my @res_col ;
		my @res_type ;
		my $sth = $dbh->prepare($TestSQL,{odbc_exec_direct => 1});
	
		try {
			$sth->execute;
		} catch {
			#warn "caught error: $_\n";
			warn "File :- $infile\n";
			#warn "TRYING :- \n$TestSQL";
		};
	
	
		do {
			push @res_type, $sth->{TYPE} ;
			push @res_col,  $sth->{NAME} ;
	
			if ( $gen_types ) {
				{
				my @names   = map { scalar $dbh_typeinfo->type_info($_)->{TYPE_NAME} }   @{ $sth->{TYPE} } ;
				my @colSize = map { scalar $dbh_typeinfo->type_info($_)->{COLUMN_SIZE} } @{ $sth->{TYPE} } ;
	
				my @types = List::MoreUtils::pairwise { $a =~ m{char}ism ? "$a($b)" : "$a" }  @names, @colSize ;
				my @spec  = List::MoreUtils::pairwise { "$a\t\t\t$b" }  @{$sth->{NAME}}, @types ;
	
				do { local $"= "\n,\t" ;
					say {*STDERR} "ResultSet(\n\t@{spec}\n)";
				}
				}
			}
	
			push @run1_res, $sth->fetchall_arrayref() ;
	
		} while ($sth->{odbc_more_results}) ;
	
	
		foreach my $row (@res_col) {
			for ( my $i = 0; $i < scalar (@$row) ; $i++ ) {
				my $y=$i+1;
				$$row[$i]  = "Col_${y}" if $$row[$i] eq q{} ;
			}
		}
	
### 	Run test script twice
	
		my @run2_res ;
		$sth = $dbh->prepare($TestSQL,{odbc_exec_direct => 1});
		$sth->execute;
		do {
			push @run2_res, $sth->fetchall_arrayref() ;
	
		} while ($sth->{odbc_more_results}) ;
	
		my $G_ln = 0 ;
	
### 	Build conditions
	
		for ( my $ra_arr = 0; $ra_arr < scalar (@res_col) ; $ra_arr++ ) {
	
			unless ( $generateAllResultSets ) {
				next unless any { $_ == ($ra_arr+1) } @resultSets ;
			}
		#warn Dumper @resultSets ;
		#warn "!!!!\n";
		#warn Dumper $ra_arr ;
	
			my $testConditionRC = VSGDR::UnitTest::TestSet::Test::TestCondition->make(
						{ TESTCONDITIONTYPE         => $testConditionTypeRC
						, CONDITIONTESTACTIONNAME   => ${TestActionName}
						, CONDITIONNAME             => ${conditionNamePrefix} . ($ra_arr+1) . "_RowCount"
						, CONDITIONENABLED          => 'True'
						, CONDITIONROWCOUNT         => scalar(@{$run1_res[$ra_arr]})
						, CONDITIONRESULTSET        => $ra_arr+1
						} ) ;
			push @testConditions, $testConditionRC ;
	
			my $single_row_output = ( scalar(@{$run1_res[$ra_arr]}) == 1
															? 1
															: 0 );
	
	
			if ( $generateScalarChecks) {
				for ( my $ra_row = 0; $ra_row < scalar ( @{$run1_res[$ra_arr]} ) ; $ra_row++ ) {
	
					for ( my $ra_col = 0; $ra_col < scalar ( @{$res_col[$ra_arr]} ) ; $ra_col++ ) {
	
						my $run1_dataValue = VSGDR::SQLServer::DataType->make( $res_type[$ra_arr][$ra_col]
																				, $run1_res[$ra_arr][$ra_row][$ra_col]
																				) ;
	
						my $run2_dataValue = VSGDR::SQLServer::DataType->make( $res_type[$ra_arr][$ra_col]
																				, $run2_res[$ra_arr][$ra_row][$ra_col]
																				) ;
	
						# check the values are stable from run to run before generating test condition.
						if ( ( ( ! defined $run1_dataValue->value() ) and (! defined $run2_dataValue->value() ) ) or
							( (   defined $run1_dataValue->value()   and    defined $run2_dataValue->value() )
										and  $run1_dataValue eq $run2_dataValue
							)
						) {
							my $testConditionSV = VSGDR::UnitTest::TestSet::Test::TestCondition->make(
										{ TESTCONDITIONTYPE         => $testConditionTypeSV
										, CONDITIONTESTACTIONNAME   => ${TestActionName}
										, CONDITIONNAME             => ( $single_row_output == 0
																			? ${conditionNamePrefix} . ($ra_arr+1) . '_Row_' . ($ra_row+1) . '_' . $res_col[$ra_arr][$ra_col]
																			: ${conditionNamePrefix} . ($ra_arr+1) . '_' . $res_col[$ra_arr][$ra_col]
																	)
										, CONDITIONENABLED          => 'True'
										, CONDITIONEXPECTEDVALUE    => ( defined $run1_dataValue->getValue()
																			? q{"} .    # " kill highlighting
																			$run1_dataValue->quoteValue($run1_dataValue->getValue()) 
																			. q{"}      # " kill highlighting
																			: 'null'
																	)
										, CONDITIONNULLEXPECTED     => defined $run1_res[$ra_arr][$ra_row][$ra_col] ? 'False' : 'True'
										, CONDITIONRESULTSET        => $ra_arr+1
										, CONDITIONROWNUMBER        => $ra_row+1
										, CONDITIONCOLUMNNUMBER     => $ra_col+1
										} ) ;
	
							push @testConditions, $testConditionSV ;
						}
						else {
							say {*STDERR} "Skipping mutating values for resultset\[${ra_arr}\], row\[${ra_row}\], column\[${ra_col}\] .." ;
						}
					}
				}
			}
		}
	
	
		if ( $PostTestSQL ) {
### 	Run post-test script
			my $p_sth = $priv_dbh->prepare($PostTestSQL,{odbc_exec_direct => 1});
			$p_sth->execute();
		}
	
		if ( $cleardownSQL ) {
### 	Run cleardown script
			my $p_sth = $priv_dbh->prepare($cleardownSQL,{odbc_exec_direct => 1});
			$p_sth->execute();
		}
	}

### Build GDR files

    $test->testAction(${TestActionName}) ;
    $test->test_conditions(\@testConditions) ;
    $testSet->tests([$test]) ;

    my $o_resx = VSGDR::UnitTest::TestSet::Resx->new() ;
    my %code = ( ${TestActionName} => $origTestSQL ) ;

    $code{$PreTestActionName}                   = $origPreTestSQL
        if $origPreTestSQL ;
    $code{$PostTestActionName}                  = $origPostTestSQL
        if $origPostTestSQL ;
    $code{$testSet->initializeActionLiteral()}  = $origInitSQL
        if $origInitSQL ;
    $code{$testSet->cleanupActionLiteral()}     = $origCleardownSQL
        if $origCleardownSQL ;


    $o_resx->scripts(\%code) ;
    $o_resx->serialise($outfname.'.resx',$o_resx) ;

    if ($version == 1)  {
        $Parsers{$outsfx}->serialise($opt_outfile[$i],$testSet);
    }
    else {
        $Parsers{"${outsfx}2"}->serialise($opt_outfile[$i],$testSet);
    }



}


exit ;

# #######################################################################################

sub getFile {
    local $_        = undef ;
    my $infile      = shift or croak 'no input filename' ;
    my $SQL         = q{} ;
    open my $infh, '<', $infile ;
    { local $/=undef ; $SQL = <$infh> ; close $infh ; } ;
    return scalar $SQL ;
}


END {
    $dbh->disconnect()          if $dbh ;
    $dbh_typeinfo->disconnect() if $dbh_typeinfo ;
    $priv_dbh->disconnect()     if $priv_dbh ;
}

__DATA__


=head1 NAME


genGDRTests.pl - Creates GDR test files from test sql scripts.
This version creates no test conditions for anything other than the main test file.
All files, other than the main test files are fixed, are the same for each generated test.
Test is run tw2ce to generate tests only for stable values. (Dates are still a problem.)

=head1 VERSION

1.4.1

=head1 USAGE

genGDRTests.pl -i <infile> -o <outfile> -c <odbc connection> -r <resultSets>  -n <namespace> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -i[n][file]   [=] <file>

Specify input file

=for Euclid:
    file.type:    readable
    repeatable


=item  -o[ut][file]  [=] <file>

Specify output file

=for Euclid:
    file.type:    writable
    repeatable

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=back


=head1 OPTIONS

=over


=item  -v[er][sion] [=]<outputversion>

Output version type

=for Euclid:
    outputversion.type:    /[12]/
    outputversion.default:  2

=item  -pc[onnection] [=] <dsn>

Specify privileged ODBC connection for Setup/Teardown scripts


=item  -pre[file]     [=] <prefile>

Pre-test file

=for Euclid:
    prefile.type:    readable

=item  -post[file]    [=] <postfile>

Post-test file

=for Euclid:
    postfile.type:    readable


=item  -init[file]    [=] <initfile>

Common initialisation code file

=for Euclid:
    initfile.type:    readable

=item  -cleanup[file] [=] <cleanupfile>

Common cleanup code file

=for Euclid:
    cleanupfile.type:    readable


=item  -r[esultSets]  [=] <resultSets>

Resultsets (numeric list) for which to generate test conditions

=for Euclid:
    resultSets.type:    int
    repeatable

=item  -n[ame][space] [=]<namespace>

Specify namespace for test class

=for Euclid:
    namespace.type:    string



=item  --[no]runTestsToGenerateResults

[Don't] generate 'Passed' scalar value result ie don't run the tests

=for Euclid:
    false: --norunTestsToGenerateResults




=item  --[no]scalarValues

[Don't] generate scalar value test conditions

=for Euclid:
    false: --noscalarValues


=item  --[no]types

[Don't] generate SQL types declaration

=for Euclid:
    false: --notypes


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

