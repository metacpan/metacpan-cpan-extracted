#!/bin/perl

use strict;
use warnings;
use autodie qw(:all);
# throw exceptions on their use
no indirect ':fatal';
use 5.010;


use Carp;
use Text::Diff ;

#DONE:  1. Add support to merging tests with compatible init/teardown sections
#TODO:  1. Add support to merging tests with compatible init/teardown conditions

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Resx;

our @opt_infile;
our $opt_outfile;
our $opt_version;
our $opt_classname;
our $opt_namespace;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use version ; our $VERSION = qv('1.3.3');
use Data::Dumper;
use File::Basename;
use Smart::Comments;

my %ValidParserMakeArgs = ( vb  => "NET::VB"
                          , cs  => "NET::CS"
                          , xls => "XLS"
                          , xml => "XML"
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          
                          
#my @validSuffixes       = keys %ValidParserMakeArgs ;
my @validSuffixes       = map { '.'.$_ } keys %ValidParserMakeArgs ;


my $version             = $opt_version ;


my @infiles         = @opt_infile ;
my $outFile         = $opt_outfile ;

my($outfname, $outdirectories, $outsfx) = fileparse($outFile, @validSuffixes);
croak 'Invalid output file'   unless defined $outsfx ;    

$outsfx       = substr(lc $outsfx,1) ;
    
my $outpfx          = $outfname;

my $classname       = undef ;
$classname          = $opt_classname    if     defined $opt_classname ;
$classname          = $outpfx           unless defined $classname ;

my $namespace       = undef ; 
$namespace          = $opt_namespace    if     defined $opt_namespace ;
$namespace          = $outpfx           unless defined $namespace ;


croak 'Invalid output file' unless exists $ValidParserMakeArgs{$outsfx} ;
my $outResxFile = "${outpfx}.resx" ;

### check output files can be written to
# yes so it's a race-condition anyway

croak 'Output file cannot be written to'          unless -f $outFile     or ! -e $outFile ;
croak 'Output resource file cannot be written to' unless -f $outResxFile or ! -e $outResxFile ;

my @cleanupScripts = () ;
my @initScripts    = () ;


my %Parsers            = () ;
# if output is needed in ssdt unit test format  add in a .net2 parser to the list
if ($version == 1)  {
    $Parsers{${outsfx}}    = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${outsfx}} } );
}
else {
    $Parsers{"${outsfx}2"} = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${outsfx}} } );
}

my @testSets = () ;
my %test_testScripts  = () ;

### Creating output files

my $o_resx = VSGDR::UnitTest::TestSet::Resx->new() ;
for my $testFile (@infiles) { ### testfile ..                       done

    my($infname, $indirectories, $insfx)    = fileparse($testFile, @validSuffixes);
    croak 'Invalid input file'  unless $insfx;
    
    $insfx          = substr(lc $insfx,1) ;

    croak 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;
    
    $Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } )
        unless exists $Parsers{${insfx}} ;
    # if input is in a .net language, add in a .net2 parser to the list
    if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
        $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } )
            unless exists $Parsers{"${insfx}2"} ;
    }

### Parsing test file

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

    
    push @testSets, $testSet ;
    $testSet = undef ;

#    my $resx_data = ''; { $/ = undef ; open my $AA, "<", "${inpfx}.resx"; $resx_data = <$AA> ;  close $AA ; }  ;
#    my $rh_testScripts  = $o_resx->parse($resx_data) ;

### Parsing script file

    my $inpfx           = $infname ;
    my $rh_testScripts  = $o_resx->deserialise("${inpfx}.resx") ;

    push @cleanupScripts,   $rh_testScripts->{testCleanupAction}    if exists $rh_testScripts->{testCleanupAction} ;
    push @initScripts,      $rh_testScripts->{testInitializeAction} if exists $rh_testScripts->{testInitializeAction} ;

    #warn Dumper $rh_testScripts ;
    #warn Dumper keys %$rh_testScripts ;

    map { $test_testScripts{$_} = $$rh_testScripts{$_} } keys %{$rh_testScripts} ;

}

#warn Dumper keys %test_testScripts ;
#warn Dumper scalar @testSets ;
my @cleanupActions = grep { defined($_->cleanupAction())  } @testSets ;
my @initActions    = grep { defined($_->initializeAction()) } @testSets ;

my %testNames       = () ;
my %conditionNames  = () ;


my %lc_testNames       = () ;
my %lc_conditionNames  = () ;

#exit;

croak 'Some tests have initialisation and/or cleanup actions, and some do not. The tests cannot be merged.'
    if ( scalar @cleanupActions  and ( scalar @testSets != scalar @cleanupActions ) )
    or ( scalar @initActions     and ( scalar @testSets != scalar @initActions ) ) ;


if (@testSets > 1) {

    if ( scalar(@initScripts) ) {
        my $firstInitSQL = $initScripts[0] ;
        my $fi = $firstInitSQL;
        $fi =~ s{\s+}{\ }xgmsi ;
        shift @initScripts ;

        local $_ = undef ;
        while ( my $sc = shift @initScripts) {
            $sc =~ s{\s+}{\ }xgmsi ;
            croak 'Different initialisation scripts exist, Tests cannot be merged.'
                if diff(\$sc,\$fi) ;
        }
    }

    if (scalar(@cleanupScripts)) {
        my $firstCleanupSQL = $cleanupScripts[0] ;
        my $fc = $firstCleanupSQL;
        $fc =~ s{\s+}{[ ]}xgmsi ;
        shift @cleanupScripts ;

        while ( $_ = shift @cleanupScripts) {
            $_ =~ s{\s+}{[ ]}xgmsi ;
            croak 'Different cleanup scripts exist, Tests cannot be merged.'
                if diff(\$_,\$fc) ;
        }
    }
} ;


### Pulling out test information


foreach my $testSet (@testSets) { ### testset ..               done
    my $ra_tests        = $testSet->tests() ;
    my @t = map { my $s=$_->testName() ; $testNames{$s}++ ; $lc_testNames{lc($s)}++ ; $s ; }
        @$ra_tests ;
    foreach my $test (@$ra_tests) { ### test ..                done
        my $ra_conditions   = $test->conditions() ;
        my @c = map { my $s=$_->conditionName();$conditionNames{$s}++ ; $lc_conditionNames{lc($s)}++ ; $s ; }
            @$ra_conditions ;
    }
} ;


my @dupTestNames      = grep { $lc_testNames{$_} > 1 }      keys %lc_testNames ;
my @dupConditionNames = grep { $lc_conditionNames{$_} > 1 } keys %lc_conditionNames ;


### Checking for clashes

{
local $" =", ";
croak "Duplicate Test names exist:- @dupTestNames, Tests cannot be merged."
    if scalar @dupTestNames ;
croak "Duplicate Condition names exist: @dupConditionNames, Tests cannot be merged."
    if scalar @dupConditionNames ;
}
my $mergedTestSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE        => $namespace
                                                    , CLASSNAME        => $classname
                                                    }
                                                  ) ;
my @testA = () ;
foreach my $testSet (@testSets) {
    my $ra_tests        = $testSet->tests() ;
    push @testA,@$ra_tests ;

} ;

### Building merged test set

$mergedTestSet->initializeConditions([]) ;
$mergedTestSet->cleanupConditions([]) ;
$mergedTestSet->initializeAction($mergedTestSet->initializeActionLiteral()) if scalar @initActions ;
$mergedTestSet->cleanupAction($mergedTestSet->cleanupActionLiteral())       if scalar @cleanupActions ;
$mergedTestSet->tests(\@testA) ;

### Serialising parser

if ($version == 1)  {
    $Parsers{$outsfx}->serialise($opt_outfile,$mergedTestSet);
}
else {
    $Parsers{"${outsfx}2"}->serialise($opt_outfile,$mergedTestSet);
}


### Cloning scripts

my $o_resx_clone   = $o_resx->clone() ;
$o_resx_clone->scripts(\%test_testScripts);
unlink $outResxFile if -f $outResxFile ;

### Serialising scripts

$o_resx_clone->serialise($outResxFile,$o_resx_clone);

exit ;

END {}

__DATA__


=head1 NAME


mergeGDRTests.pl - Merge multiple GDR test files into one combined file.

=head1 VERSION

1.3.3

=head1 USAGE

mergeGDRTests.pl -i <infile> -o <outfile>  -n <namespace> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -i[n][file]  [=]<file>

Specify input file

=for Euclid:
    file.type:    readable
    repeatable

=item  -o[ut][file]  [=]<file>

Specify output file

=for Euclid:
    file.type:    writable




=back


=head1 OPTIONS

=over

=item  -[class]n[ame] [=]<classname>

Specify the name of the required class

=for Euclid:
    classname.type:    string

=item  -v[er][sion] [=]<outputversion>

Output version type

=for Euclid:
    outputversion.type:    /[12]/
    outputversion.default:  2

=item  -n[ame][space] [=]<namespace>

Specify namespace for test class

=for Euclid:
    namespace.type:    string
    



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

