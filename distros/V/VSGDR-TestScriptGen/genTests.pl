#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';


use Carp;
use DBI;


use Getopt::Euclid qw( :vars<opt_> );
our $opt_noTestRun ;
our $opt_outdir;
our $opt_connection ;

use Data::Dumper;
use VSGDR::TestScriptGen;

use IO::Dir ;
use File::Basename;


use version ; our $VERSION = qv('0.04');

croak 'no output directory'             unless defined($opt_outdir) ;
do  { 
    my $iodir = IO::Dir->new($opt_outdir);
    croak "Invalid directory:- $opt_outdir" unless defined $iodir;
    };
my $dbh                                 = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });
my $dbh_typeinfo                        = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });

my $RunChecks         = 1 ;
$RunChecks            = (!$opt_noTestRun)    if defined $opt_noTestRun ;


my $void = VSGDR::TestScriptGen::generateScripts($dbh,$dbh_typeinfo,$opt_outdir,$opt_infile,$RunChecks) ;


exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genTests.pl - Creates unit test scripts for a database

=head1 VERSION

0.04


=head1 USAGE

genTests.pl --c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=item  -o[ut][dir]  [=]<dir>

Specify output directory

=for Euclid:
    dir.type:    writable






=back


=head1 OPTIONS

=over

=item  --[no]TestRun
 
[Don't] run a test run during generation (in order to determine result shape).
 
=for Euclid:
    false: --noTestRun
 

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

Copyright (c) 2014, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

