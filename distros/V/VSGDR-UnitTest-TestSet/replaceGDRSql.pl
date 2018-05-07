#!/bin/perl

use strict;
use warnings;
use autodie qw(:all);  
no indirect ':fatal';

use 5.010;
use Carp;

our $opt_infile;
our $opt_action;
our $opt_test;
our $opt_sinfile;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use version ; our $VERSION = qv('1.0.1');

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;

use VSGDR::UnitTest::TestSet::Resx;

use Data::Dumper;

use IO::File ;
#use Smart::Comments;
use File::Basename;

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


croak 'no input file'  unless defined($opt_infile) ;
my $infile;
$infile = $opt_infile;

my($infname, $directories, $insfx)      = fileparse($infile , @validSuffixes);
croak 'Invalid input file'   unless defined $insfx ;
$insfx        = lc $insfx ;
$insfx        = substr $insfx,1;
#warn Dumper $insfx;

### Validate parameters
die 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;

### Build parsers

my %Parsers            = () ;
$Parsers{${insfx}}     = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs{${insfx}} } );
# if input is in a .net language, add in a .net2 parser to the list
if ( firstidx { $_ eq ${insfx} } ['cs','vb']  != -1 ) {
    $Parsers{"${insfx}2"}  = VSGDR::UnitTest::TestSet::Representation->make( { TYPE => $ValidParserMakeArgs2{${insfx}} } );
}


my $resxname        = $infname . ".resx" ;
my $o_resx          = VSGDR::UnitTest::TestSet::Resx->new() ;

### Deserialise tests scripts
$o_resx->deserialise($resxname) ;
my $rh_testScripts  = $o_resx->scripts() ; 
#warn Dumper $rh_testScripts ;
#exit ;

my %test_Actions = 
(       test    => VSGDR::UnitTest::TestSet::Test->testActionLiteral()
,       pre     => VSGDR::UnitTest::TestSet::Test->preTestActionLiteral()
,       post    => VSGDR::UnitTest::TestSet::Test->postTestActionLiteral()
,       init    => VSGDR::UnitTest::TestSet->initializeActionLiteral()
,       cleanup => VSGDR::UnitTest::TestSet->cleanupActionLiteral()
) ;

#say Dumper %test_Suffixes;
#exit;

my $action = $test_Actions{${opt_action}} ;
croak "Invalid action ${opt_action}" unless $action;

if ( exists $rh_testScripts->{"${opt_test}_${action}"} ) {
    $rh_testScripts->{"${opt_test}_${action}"} = getFile($opt_sinfile);
    #$o_resx->scripts(rh_testScripts) ;
    $o_resx->serialise($infname.'.resx',$o_resx) ;
    
}
else {
    croak "Invalid test/action $opt_test/$opt_action" ;
}

### End

exit ;

END {} 


sub getFile {
    local $_        = undef ;
    my $infile      = shift or croak 'no input filename' ;
    my $SQL         = q{} ;
    open my $infh, '<', $infile ;
    { local $/=undef ; $SQL = <$infh> ; close $infh ; } ;
    return scalar $SQL ;
}


__END__



=head1 NAME


replaceGDRSql.pl - Replace the embedded SQL for a Test in a GDR Unit Test file.



=head1 VERSION

1.0.1



=head1 USAGE

replaceGDRSql.pl -i <file> -t <TestName> -a <TestAction> -si <SQLfile>


=head1 REQUIRED ARGUMENTS


=over


=item  -i[n][file]  [=]<file>

Specify the unit test file

=for Euclid:
    file.type:    readable


=item  -si[n][file]  [=]<sqlfile>

Specify the file containing the new sql.

=for Euclid:
    sqlfile.type:    readable


=item  -t[est]  [=]<testname>

Specify the name of the test the SQL of which is to be replaced.

=for Euclid:
    testname.type:   string


=item  -a[ction]  [=] <action>

Specify the action element to be replaced.  One of :- /pre|post|test|init|cleanup/

=for Euclid:
    action.type:    /pre|post|test|init|cleanup/
    action.default  = 'test'

=back

=head1 AUTHOR

Ded MedVed. 



=head1 BUGS

Hopefully none. 



=head1 COPYRIGHT

Copyright (c) 2013, Ded MedVed. All Rights Reserved. 
This module is free software. It may be used, redistributed 
and/or modified under the terms of the Perl Artistic License 
(see http://www.perl.com/perl/misc/Artistic.html) 
