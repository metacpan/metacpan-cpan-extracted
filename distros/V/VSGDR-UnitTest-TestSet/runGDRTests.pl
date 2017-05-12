#!/bin/perl

use Modern::Perl;
use autodie qw(:all);
no indirect ':fatal';

use version ; our $VERSION = qv('1.3.10');

use Try::Tiny ;

#DONE:  1.  Most of it.
#TODO:  1.  Improve reporting - rerunning etc
#DONE:  2.  Honour , but warn about disabled tests and test conditions.  This might exist but looks broken.
#TODO:  3.  Rowcount seems broken.  runGDRTests.pl -c local_loaddecisioning -i up_CollectPaymentStatus.cs
#TODO:  4.  BUM.  There was something else !
#TODO:  5.  Tighten exactness of debugging over sql exec errors.

use Carp;
use Text::Diff;
use File::Basename;

use DBI;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Resx;

use List::MoreUtils qw(any) ;

#use Smart::Comments;

our $opt_connection;
our $opt_pconnection;
our $opt_noReInit;
our $opt_noDebug;
our $opt_noWarn;
our @opt_infile;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use Data::Dumper;
#use Data::Printer;

my $dataBase                = $opt_connection;
my $priv_dataBase           = undef ;
$priv_dataBase              = $opt_pconnection if defined $opt_pconnection ;



my %Parsers = () ;
my %ValidParserMakeArgs = ( vb  => 'NET::VB'
                          , cs  => 'NET::CS'
                          , xls => 'XLS'
                          , xml => 'XML'
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          

#my @validSuffixes       = keys %ValidParserMakeArgs ;
my @validSuffixes       = map { '.'.$_ } keys %ValidParserMakeArgs ;

#warn Dumper @validSuffixes ;
#exit;

my $reInit           = 1 ;
$reInit              = (!$opt_noReInit)  if defined $opt_noReInit ;

my $Warn             = 1 ;
$Warn                = (!$opt_noWarn)    if defined $opt_noWarn ;

my $Debug            = 0 ;
$Debug               = (!$opt_noDebug)   if defined $opt_noDebug ;

### Connect to database
my $dbh ;
my $dbh_quote_conn ;
$dbh                = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, PrintWarn => 1, PrintError => 1, RaiseError => 1});
$dbh_quote_conn     = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, PrintWarn => 1, PrintError => 1, RaiseError => 1});

# Always create a $priv_dbh handle, re-use the normal database dsn if no privileged dsn specified.
my $priv_dbh    = undef ;
$priv_dbh       = get_Priv_dbh() ;

# if noreinit specified
# loop over input files, picking up init and cleardown acction
# if compatible run init and teardown once out side loop
# else fallback to previous implementation

my $commonInitSQL             = undef ;
my $commonCleardownSQL        = undef ;

my $compatibleactions   = 1  ;
my @cleanupScripts      = () ;
my @initScripts         = () ;

my @cleanupActions      = () ;
my @initActions         = () ;

my @testSets            = () ;

if ( ! $reInit && ( scalar @opt_infile > 1 )) {

#    for ( my $i=0; $i <= $#opt_infile; $i++ ) {  ## Process SQL scripts:::                 done
    foreach my $infile (@opt_infile) {  ## Process SQL scripts:::                 done

        my($infname, $directories, $insfx) = fileparse($infile, @validSuffixes);
        croak 'Invalid input file'   unless defined $insfx ;            
        $insfx      = lc $insfx ;
        
        croak 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;
        $Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } )
            unless exists $Parsers{${insfx}} ;
        # if input is in a .net language, add in a .net2 parser to the list
        if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
            $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } )
                unless exists $Parsers{"${insfx}2"} ;
        }

        my $testSet         = undef ;

        eval {
            $testSet         = $Parsers{$insfx}->deserialise($infile);
            } ;
        if ( not defined $testSet ) {
            if ( exists $Parsers{"${insfx}2"}) {
                eval {
                    $testSet     = $Parsers{"${insfx}2"}->deserialise($infile);
                    }
            }            
            else {
                croak 'Parsing failed.'; 
            }
        }
        
        push @testSets, $testSet ;

        my $resxname    = $infname . '.resx' ;
        my $i_resx      = VSGDR::UnitTest::TestSet::Resx->new() ;
        $i_resx->deserialise($resxname) ;

        my $rh_testScripts  = $i_resx->scripts() ;

        push @cleanupScripts,   $rh_testScripts->{testCleanupAction}    if exists $rh_testScripts->{testCleanupAction} ;
        push @initScripts,      $rh_testScripts->{testInitializeAction} if exists $rh_testScripts->{testInitializeAction} ;

        $commonInitSQL                = $rh_testScripts->{$testSet->initializeActionLiteral()} ;
        $commonCleardownSQL           = $rh_testScripts->{$testSet->cleanupActionLiteral()} ;

        $testSet = undef ;

#    map { $test_testScripts{$_} = $$rh_testScripts{$_} } keys %{$rh_testScripts} ;

    }

    @cleanupActions = grep { defined($_->cleanupAction())  }   @testSets ;
    @initActions    = grep { defined($_->initializeAction()) } @testSets ;

    if ( ( scalar @cleanupActions  and ( scalar @testSets != scalar @cleanupActions ) )
      or ( scalar @initActions     and ( scalar @testSets != scalar @initActions ) )
       ) {
        $compatibleactions = 0 ;
    }
    else {
        if (@testSets > 1) {

            my $firstInitSQL = $initScripts[0] ;
            ( my $fi = $firstInitSQL) =~ s{\s+}{\ }xmsi ;
            shift @initScripts ;

            my $firstCleanupSQL = $cleanupScripts[0] ;
            ( my $fc = $firstCleanupSQL) =~ s{\s+}{\ }xmsi ;
            shift @cleanupScripts ;

            local $_ = undef ;
            while ( $_ = shift @initScripts) {
                s{\s+}{\ }xmsi ;
                 $compatibleactions = 0
                    if diff(\$_,\$fi) ;
            }
            while ( $_ = shift @cleanupScripts) {
                s{\s+}{\ }xmsi ;
                $compatibleactions = 0
                    if diff(\$_,\$fc) ;
            }
        }
    }
}
else {
    $compatibleactions = 0 ;    ## fallback to normal behaviour
}

say {*STDERR} 'Incompatible init/cleanup scripts, falling back to per-test init/cleanup'
    if not $compatibleactions and not $reInit ;

# don't bother with conditions if short-cutting init/teardown. we're implicitly short-cutting things anyway
if ( ! $reInit ) {
    if ( $compatibleactions ) {
        if ( $commonInitSQL ) {
            say {*STDERR} 'Running init';
            my $p_sth = $priv_dbh->prepare($commonInitSQL,{odbc_exec_direct => 1});
            $p_sth->execute();
            $p_sth->finish();
        }
    }
}


#for ( my $i=0; $i <= $#opt_infile; $i++ ) {  ## Process SQL scripts:::                 done
foreach my $infile (@opt_infile) {  ## Process SQL scripts:::                 done

    my($infname, $directories, $insfx) = fileparse($infile, @validSuffixes);
    $insfx          = substr(lc $insfx,1) ;    
    croak 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;

    my $parser          = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } );
    my $testSet         = undef ;
    eval {
        $testSet         = $parser->deserialise($infile);
        } ;
    if ( ! defined $testSet) {
        eval {
            $parser      = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } );
            $testSet     = $parser->deserialise($infile);
            }
    }

#    my $testSet     = $parser->deserialise($infile) ; ## doesn't die on a bad language eg cs for vb - probably a PRD replacement issue

    my $ra_tests    = $testSet->tests() ;


    my $resxname    = $infname . '.resx' ;
#say {*STDERR} "Running tests in $resxname" ;
    my $i_resx      = VSGDR::UnitTest::TestSet::Resx->new() ;
    $i_resx->deserialise($resxname) ;

    my $rh_testScripts  = $i_resx->scripts() ;

    my $TestSQL             = undef ;
    my $PreTestSQL          = undef ;
    my $PostTestSQL         = undef ;

    my $initSQL             = undef ;
    my $cleardownSQL        = undef ;

    $initSQL                = $rh_testScripts->{$testSet->initializeActionLiteral()} ;
    $cleardownSQL           = $rh_testScripts->{$testSet->cleanupActionLiteral()} ;

    $initSQL                = $priv_dbh->quote($initSQL)                if $initSQL ;
    $cleardownSQL           = $priv_dbh->quote($cleardownSQL)           if $cleardownSQL ;
    $initSQL                = 'exec sp_executesql N' . $initSQL         if $initSQL ;
    $cleardownSQL           = 'exec sp_executesql N' . $cleardownSQL    if $cleardownSQL ;


    # don't bother with conditions if short-cutting init/teardown. we're implicitly short-cutting things anyway
    if ( ! $reInit ) {
        if ( ! $compatibleactions ) {
            if ( $initSQL ) {
                say {*STDERR} 'Running init';
                my $p_sth = $priv_dbh->prepare($initSQL,{odbc_exec_direct => 1});
                $p_sth->execute();
                $p_sth->finish();
            }
        }
    }

    for my $test ( @{$ra_tests} ) {
#warn Dumper $test;
        my %test_res ;
        my @test_res = () ;

        try {

            say {*STDERR} "Performing test :- @{[$test->testName()]}" ;


            if ( $initSQL  and $reInit ) {
                say {*STDERR} 'Running setup';
                my $p_sth = $priv_dbh->prepare($initSQL,{odbc_exec_direct => 1});
                $p_sth->execute();

                @test_res = () ;
                do {
                    $p_sth->{PrintError} = 0;
                    $p_sth->{RaiseError} = 0;
                    push @test_res, $p_sth->fetchall_arrayref() ;

                } while ($p_sth->{odbc_more_results}) ;
                $p_sth->finish();
                { my @res         = @test_res ;
                  $test_res{INIT} = [ @res ] ;
                }
            }
            $TestSQL            = q{} ;
            $PreTestSQL         = q{} ;
            $PostTestSQL        = q{} ;

#warn Dumper $test->testAction() ;
#warn Dumper $rh_testScripts->{$test->testAction()};
#exit;

            $TestSQL            = $rh_testScripts->{$test->testAction()}        if $test->testAction()     !~ m{\A \s* (?:null|nothing) \s* \z}ixsm;
            $PreTestSQL         = $rh_testScripts->{$test->preTestAction()}     if $test->preTestAction()  !~ m{\A \s* (?:null|nothing) \s* \z}ixsm;
            $PostTestSQL        = $rh_testScripts->{$test->postTestAction()}    if $test->postTestAction() !~ m{\A \s* (?:null|nothing) \s* \z}ixsm;
#warn Dumper $TestSQL ;
            $TestSQL            = $dbh_quote_conn->quote($TestSQL)              if $TestSQL ;
            $PreTestSQL         = $dbh_quote_conn->quote($PreTestSQL)           if $PreTestSQL ;
            $PostTestSQL        = $dbh_quote_conn->quote($PostTestSQL)          if $PostTestSQL;
#warn Dumper $TestSQL ;
            $TestSQL            = 'exec sp_executesql N' . $TestSQL             if $TestSQL ;
            $PreTestSQL         = 'exec sp_executesql N' . $PreTestSQL          if $PreTestSQL ;
            $PostTestSQL        = 'exec sp_executesql N' . $PostTestSQL         if $PostTestSQL;

#warn Dumper $TestSQL ;

            if ( $PreTestSQL ) {
                say {*STDERR} 'Running PreTest' ;
#warn Dumper $test->preTestAction()  ;
#warn Dumper $rh_testScripts->{$test->preTestAction()}  ;
#warn Dumper $PreTestSQL  ;

                my $p_sth = $priv_dbh->prepare($PreTestSQL,{odbc_exec_direct => 1});
                $p_sth->execute();

                @test_res = () ;
                do {
                    $p_sth->{PrintError} = 0;
                    $p_sth->{RaiseError} = 0;
                    push @test_res, $p_sth->fetchall_arrayref() ;

                } while ($p_sth->{odbc_more_results}) ;
                { my @res         = @test_res ;
                  $test_res{PRETEST} = [ @res ] ;
                }
            }

#warn $TestSQL;
            say {*STDERR} 'Running Test' ;
            my $sth  = $dbh->prepare($TestSQL,{odbc_exec_direct => 1});
            
            try {
                $sth->{PrintError} = 0;
                $sth->{RaiseError} = 1;
                $sth->execute;
            }
            catch {
                if ($Debug ) {
                    say {*STDERR} $TestSQL ;
                }
            }
            finally {
#                say {*STDERR} "ARSE!";
            }
            
#warn Dumper $TestSQL ;
            @test_res = () ;
            do {
                $sth->{PrintError} = 0;
                $sth->{RaiseError} = 0;
                push @test_res, $sth->fetchall_arrayref() ;

            } while ($sth->{odbc_more_results}) ;
#warn Dumper @test_res;            
            $sth->finish();
            { my @res         = @test_res ;
              $test_res{TEST} = [ @res ] ;
            }
            if ( $PostTestSQL ) {
                say {*STDERR} 'Running PostTest' ;
                my $p_sth = $priv_dbh->prepare($PostTestSQL,{odbc_exec_direct => 1});
                $p_sth->execute();

                @test_res = () ;
                do {
                    $p_sth->{PrintError} = 0;
                    $p_sth->{RaiseError} = 0;
                    push @test_res, $p_sth->fetchall_arrayref() ;

                } while ($sth->{odbc_more_results}) ;
                $p_sth->finish();
                { my @res         = @test_res ;
                  $test_res{POSTTEST} = [ @res ] ;
                }
            }


            if ( $cleardownSQL and $reInit ) {
                say {*STDERR} 'Running cleardown';
                my $p_sth = $priv_dbh->prepare($cleardownSQL,{odbc_exec_direct => 1});
                $p_sth->execute();

                @test_res = () ;
                do {
                    $p_sth->{PrintError} = 0;
                    $p_sth->{RaiseError} = 0;
                    push @test_res, $p_sth->fetchall_arrayref() ;

                } while ($sth->{odbc_more_results}) ;
                { my @res         = @test_res ;
                  $test_res{CLEARDOWN} = [ @res ] ;
                }
            }
#warn Dumper @{$test->test_conditions()} ;
        foreach my $tc (@{$test->test_conditions()}) {
#            say STDERR $tc->conditionName . " failed."
#                unless $tc->check( $test_res{TEST} ) ;
#            warn Dumper $tc
#               unless $tc->check( $test_res{TEST} ) ;
#say $tc->conditionEnabled;
            if ( $tc->conditionISEnabled() ) {
                my $res = $tc->check( $test_res{TEST} );
#say $res;                            
            }
            else {
                say {*STDERR} 'Condition ' . $tc->conditionName . ' disabled.'
                    if $Warn ;
            };

        }

        %test_res = () ;

        }
        catch {
            carp $_ ;
            if ($Debug ) {
                say {*STDERR} $rh_testScripts->{$test->testAction()} ;
            }
        }
        finally {
        }
    }

    # don't bother with conditions if short-cutting init/teardown. we're implicitly short-cutting things anmyway
    if ( ! $reInit ) {
        if ( ! $compatibleactions ) {
            if ( $cleardownSQL ) {
                say {*STDERR} 'Running cleardown';
                my $p_sth = $priv_dbh->prepare($cleardownSQL,{odbc_exec_direct => 1});
                $p_sth->execute();
                $p_sth->finish();
            }
        }
    }
}

# don't bother with conditions if short-cutting init/teardown. we're implicitly short-cutting things anmyway
if ( ! $reInit ) {
    if ( $compatibleactions ) {
        if ( $commonCleardownSQL ) {
            say {*STDERR} 'Running cleardown';
            my $p_sth = $priv_dbh->prepare($commonCleardownSQL,{odbc_exec_direct => 1});
            $p_sth->execute();
            $p_sth->finish();
        }
    }
}

exit ;

# #######################################################################################


END {
    $dbh->disconnect()              if $dbh ;
    $dbh_quote_conn->disconnect()   if $dbh_quote_conn ;
    $priv_dbh->disconnect()         if $priv_dbh ;
}

# #######################################################################################


sub get_Priv_dbh {
    local $_ = undef ;
    my $_dbh ;

    if ( defined $priv_dataBase ) {
        $_dbh       = DBI->connect("dbi:ODBC:${priv_dataBase}", q{}, q{}, { AutoCommit => 1, PrintWarn => 1, PrintError => 1, RaiseError => 1})
    }
    else {
        $_dbh       = DBI->connect("dbi:ODBC:${dataBase}", q{}, q{}, { AutoCommit => 1, PrintWarn => 1, PrintError => 1, RaiseError => 1})
    }
    return $_dbh ;
}

__DATA__


=head1 NAME


runGDRTests.pl - Runs GDR test files.
Runs multiple input files, mixes vb and cs sources, can run setup and teardown once per run, once per test file
or for each test.

=head1 VERSION

1.3.10

=head1 USAGE

runGDRTests.pl -i <infile> -c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -c[onnection]  [=]<dsn>

Specify ODBC connection for Test script


=item  -i[n][file]    [=]<file>

Specify input file

=for Euclid:
    file.type:    readable
    repeatable


=back



=head1 OPTIONS

=over

=item  -pc[onnection] [=]<dsn>

Specify privileged ODBC connection for Setup/Teardown scripts


=item  --[no]ReInit

[Don't] run initialisation and cleanup code for each test.  Perform once only for each run. (Or per
test file if not compatible across files.)

=for Euclid:
    false: --noReInit


=item  --[no]Warn

[Don't] warn of disabled test conditions.

=for Euclid:
    false: --noWarn



=item  --[no]Debug

[Don't] print failing test SQL

=for Euclid:
    false: --noDebug



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

