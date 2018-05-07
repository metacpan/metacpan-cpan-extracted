#!/bin/perl

use strict;
use warnings;
use 5.010;

use version ; our $VERSION = qv('1.1.2');

use autodie qw(:all);  
no indirect ':fatal';

use Carp;

use VSGDR::UnitTest::TestSet::Test;
use VSGDR::UnitTest::TestSet::Test::TestCondition;
use VSGDR::UnitTest::TestSet::Representation;

use VSGDR::UnitTest::TestSet::Resx;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use Data::Dumper;
#use Smart::Comments ;
use File::Basename;

my %ValidParserMakeArgs = ( vb  => "NET::VB"
                          , cs  => "NET::CS"
                          , xls => "XLS"
                          , xml => "XML"
                          ) ;
my %ValidParserMakeArgs2 = ( vb  => "NET2::VB"
                           , cs  => "NET2::CS"
                           ) ;                          


### get and validate parameters

our $opt_infile;
our $opt_outfile;
our $opt_version;
our @opt_enable;
our @opt_disable;


croak 'no input file'               unless defined($opt_infile);
croak 'no output file'              unless defined($opt_outfile);

my $version             = $opt_version ;

my $inFile  = $opt_infile ;
my $outFile = $opt_outfile ;

(my $inpfx  = $inFile)  =~ s{^(.*)[.][^.]*$}{$1}smx;
(my $insfx  = $inFile)  =~ s/^.*\.//g;
croak 'Invalid input file'   unless defined $insfx ;
$insfx      = lc $insfx ;

(my $outpfx = $outFile) =~ s{^(.*)[.][^.]*$}{$1}smx;
(my $outsfx = $outFile) =~ s/^.*\.//g;
croak 'Invalid output file'   unless defined $outsfx ;
$outsfx     = lc $outsfx ;

my $outResxFile = "${outpfx}.resx" ;

croak 'Invalid input file'  unless exists $ValidParserMakeArgs{$insfx} ;
croak 'Invalid output file' unless exists $ValidParserMakeArgs{$outsfx} ;

### check output files can be written to 
# yes so it's a race-condition anyway

croak 'Output resource file cannot be written to' unless -f $outResxFile or ! -e $outResxFile ;

### build parsers


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

### build internal representations of input

my $o_resx = VSGDR::UnitTest::TestSet::Resx->new() ;

my $testSet         = undef ;
eval {
    $testSet         = $Parsers{$insfx}->deserialise($inFile);
    } ;
if ( not defined $testSet ) {
    if ( exists $Parsers{"${insfx}2"}) {
        eval {
            $testSet         = $Parsers{$insfx}->deserialise($inFile);
            }
    }            
    else {
        croak 'Parsing failed.'; 
    }
}


my $resx_data       = ''; { $/ = undef ; open (my $aa, "<", "${inpfx}.resx"); $resx_data = <$aa> ; close $aa ;} ; 
my $rh_testScripts  = $o_resx->parse($resx_data) ; 


my $ra_tests        = $testSet->tests() ;

### filter input to output


my $newTestSet = VSGDR::UnitTest::TestSet->new( { NAMESPACE        => $testSet->nameSpace()
                                                 , CLASSNAME        => $testSet->className()
                                                 } 
                                               ) ;
$newTestSet->initializeConditions($testSet->initializeConditions()) ;
$newTestSet->cleanupConditions($testSet->cleanupConditions()) ;
$newTestSet->tests($ra_tests) ;

foreach my $re ( @opt_enable) {
    my $qre = qr{$re} ;
    foreach my $cond ( @{$newTestSet->initializeConditions()} ) {
        if ($cond->Name() =~ m{$qre} ) {
            $cond->conditionEnabled('True')  ;
            say STDERR "Enabled @{[ $cond->conditionName() ]}";
        }
    }
    foreach my $cond ( @{$newTestSet->cleanupConditions()} ) {
        if ($cond->Name() =~ m{$qre} ) {
            $cond->conditionEnabled('True')  ;
            say STDERR "Enabled @{[ $cond->conditionName() ]}";
        }
    }
}
foreach my $re ( @opt_disable) {
    my $qre = qr{$re} ;
    foreach my $cond ( @{$newTestSet->initializeConditions()} ) {
        if ($cond->Name() =~ m{$qre} ) {
            $cond->conditionEnabled('False')  ;
            say STDERR "Disabled @{[ $cond->conditionName() ]}";
        }
    }
    foreach my $cond ( @{$newTestSet->cleanupConditions()} ) {
        if ($cond->Name() =~ m{$qre} ) {
            $cond->conditionEnabled('False')  ;
            say STDERR "Disabled @{[ $cond->conditionName() ]}";
        }
    }
}

foreach my $test (@{$newTestSet->tests()}) {
    foreach my $re ( @opt_enable) {
    my $qre = qr{$re} ;
        foreach my $cond ( @{$test->preTest_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('True')  ;
                say STDERR "Enabled @{[ $cond->conditionName() ]}";
            }
        }
        foreach my $cond ( @{$test->test_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('True')  ;
                say STDERR "Enabled @{[ $cond->conditionName() ]}";
            }
        }
        foreach my $cond ( @{$test->postTest_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('True')  ;
                say STDERR "Enabled @{[ $cond->conditionName() ]}";
            }
        }
    }
    foreach my $re ( @opt_disable) {
    my $qre = qr{$re} ;
        foreach my $cond ( @{$test->preTest_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('False')  ;
                say STDERR "Disabled @{[ $cond->conditionName() ]}";
            }
        }
        foreach my $cond ( @{$test->test_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('False')  ;
                say STDERR "Disabled @{[ $cond->conditionName() ]}";
            }
        }
        foreach my $cond ( @{$test->postTest_conditions()} ) {
            if ($cond->conditionName() =~ m{$qre} ) {
                $cond->conditionEnabled('False')  ;
                say STDERR "Disabled @{[ $cond->conditionName() ]}";
            }
        }
    }
}

unlink $outFile if -f $outFile ;

if ($version == 1)  {
    $Parsers{$outsfx}->serialise($outFile,$newTestSet);
}
else {
    $Parsers{"${outsfx}2"}->serialise($outFile,$newTestSet);
}


my $o_resx_clone   = $o_resx->clone() ;
unlink $outResxFile if -f $outResxFile ;
$o_resx_clone->serialise($outResxFile,$o_resx_clone);

### end

exit ;

END {} 


__END__



=head1 NAME


disableGDRTestCondition.pl - Disable/Enable Test Conditions in a GDR Unit Test file.



=head1 VERSION

1.1.1



=head1 USAGE

disableGDRTestCondition.pl -i <file> -o <file> [options]


=head1 REQUIRED ARGUMENTS


=over


=item  -i[n][file]  [=]<file>

Specify input file

=for Euclid:
    file.type:    readable



=item  -o[ut][file] [=]<file>

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


=item  -e[n][able] [=]<enable_re>

Specify condition name to enable ( as perl RE ) 

=for Euclid:
    enable_re.type:    string
    repeatable


=item  -d[is][able] [=]<disable_re>

Specify condition name to disable ( as perl RE ) 

=for Euclid:
    disable_re.type:    string
    repeatable



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
