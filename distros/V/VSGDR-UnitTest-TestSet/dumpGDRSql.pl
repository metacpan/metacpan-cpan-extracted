#!/bin/perl

use strict;
use warnings;
use autodie qw(:all);  
no indirect ':fatal';

use 5.010;
use Carp;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use version ; our $VERSION = qv('1.0.7');

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

our $opt_infile;

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

### Deserialise tests 
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


my $resxname        = $infname . ".resx" ;
my $o_resx          = VSGDR::UnitTest::TestSet::Resx->new() ;

### Deserialise tests scripts
$o_resx->deserialise($resxname) ;
my $rh_testScripts  = $o_resx->scripts() ; 
#warn Dumper $rh_testScripts ;
#exit ;


foreach my $test_action ( sort keys %{$rh_testScripts} ) { ### Dump test action scripts

    my $file = "${test_action}.sql" ;
    my $data ;
    my $fh   = IO::File->new("> ${file}") ;

    if (defined ${fh} ) {
        print {${fh}} $rh_testScripts->{$test_action} ;
        $fh->close;
    }
    else {
        croak "Unable to write to ${file}.";
    }
}

### End

exit ;

END {} 


__END__



=head1 NAME


dumpGDRSql.pl - Dump Out the SQL for the Tests in a GDR Unit Test file.



=head1 VERSION

1.0.7



=head1 USAGE

dumpGDRSql.pl -i <file> 


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
