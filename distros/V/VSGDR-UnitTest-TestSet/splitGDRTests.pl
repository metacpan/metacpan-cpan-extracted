#!/bin/perl

use strict;
use warnings;
use Modern::Perl;

use autodie qw(:all);  
no indirect ':fatal';

use 5.010;
use version ; our $VERSION = qv('1.0.6');

use Carp;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;
use VSGDR::UnitTest::TestSet::Resx;


our $opt_version;
our $opt_infile;
our $opt_outfile;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;

use Data::Dumper;
use File::Basename;

my %ValidParserMakeArgs = ( vb  => "NET::VB"
                          , cs  => "NET::CS"
                          , xls => "XLS"
                          , xml => "XML"
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          
                          
my @validSuffixes       = map { '.'.$_ } keys %ValidParserMakeArgs ;


my $version             = $opt_version ;


my($infname, $indirectories, $insfx) = fileparse($opt_infile, @validSuffixes);
croak 'Invalid input file'   unless defined $insfx ;            
$insfx        = lc $insfx ;
$insfx        = substr(lc $insfx,1) ;
my($outfname, $outdirectories, $outsfx) = fileparse($opt_outfile, @validSuffixes);
croak 'Invalid output file'   unless defined $outsfx ;            
$outsfx       = lc $outsfx ;
$outsfx       = substr(lc $outsfx,1) ;
    
my %Parsers            = () ;
$Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } );
# if input is in a .net language, add in a .net2 parser to the list
if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
    $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } );
}
# if output is needed in ssdt unit test format  add in a .net2 parser to the list
if ($version == 1)  {
    $Parsers{${outsfx}}    = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${outsfx}} } );
}
else {
    $Parsers{"${outsfx}2"} = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${outsfx}} } );
}

my $testSet         = undef ;
eval {
    $testSet         = $Parsers{$insfx}->deserialise($opt_infile);
    } ;
if ( not defined $testSet ) {
    if ( exists $Parsers{"${insfx}2"}) {
        eval {
            $testSet     = $Parsers{"${insfx}2"}->deserialise($opt_infile);
            }
    }            
    else {
        croak 'Parsing failed.'; 
    }
}


my $resxname        = $infname . ".resx" ;
my $o_resx          = VSGDR::UnitTest::TestSet::Resx->new() ;
$o_resx->deserialise($resxname) ;

my $rh_testScripts  = $o_resx->scripts() ; 
my $o_resx_clone    = $o_resx->clone() ;

my $testSet_clone   = $testSet->clone(); 
$testSet_clone->tests([]);
foreach my $test ( @{ $testSet->tests() } ) {

    my $rx_dyn = ${test}->testName() ;
    my @script_keys = grep { $_ =~ /^ testInitializeAction|testCleanupAction|${rx_dyn}/x ; } keys %{$rh_testScripts} ;

    my %test_testScripts = () ;
    map { $test_testScripts{$_} = $$rh_testScripts{$_} } @script_keys ;

    $o_resx_clone->scripts(\%test_testScripts) ;
    $testSet_clone->className($testSet->className() . '_' . $test->testName() ) ;
    $testSet_clone->tests([$test]) ;
    
    if ($version == 1)  {
        $Parsers{$outsfx}->serialise($outfname."_".$test->testName().".".$outsfx, $testSet_clone);
    }
    else {
        $Parsers{"${outsfx}2"}->serialise($outfname."_".$test->testName().".".$outsfx, $testSet_clone);
    }

    $o_resx_clone->serialise( ${outfname}."_".$test->testName().".resx", ${o_resx_clone} ); 

}
    

exit ;

END {} 

__DATA__


=head1 NAME


splitGDRTests.pl - Splits GDR test files.
Splits out each test in a GDR .vb or .cs test file into a separate .cs or .vb file, each with a corresponding .resx file.  The files are named after the corresponding tests.
The output file name is a dummy parameter, used to determine the source code type of the output file, and the prefix applied to each file name.

eg splitGDRTests.pl -i myTest.cs -o split.vb

creates a .vb file for each test in myTest.cs, each file name beginning with 'split_'.



=head1 VERSION

1.0.5

=head1 USAGE

splitGDRTests.pl -i <infile> -o <outfile> 


=head1 REQUIRED ARGUMENTS

=over

=item  -i[n][file]    [=]<file>

Specify input file

=for Euclid:
    file.type:    readable
    repeatable


=item  -o[ut][file]    [=]<file>

Specify output file


=for Euclid:
    file.type:    writable

=back



=head1 OPTIONS

=over

=item  -v[er][sion] [=]<outputversion>

Output version type

=for Euclid:
    outputversion.type:    /[12]/
    outputversion.default:  2

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

