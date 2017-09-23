#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';


use Carp;
use DBI;

our $opt_sourcetablename;
our $opt_targettablename;
our $opt_connection;

use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use VSGDR::MergeData;

use version ; our $VERSION = qv('0.01');

my $src_schema           = ($opt_sourcetablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $1 : "dbo" ;
my $src_table            = ($opt_sourcetablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $2 : $opt_sourcetablename;
die 'bad tablename' if $src_table =~ m{ \. }xms or $src_schema =~ m{ \. }xms; # it went wrong if we still have an embedded .

my $targ_schema          = ($opt_targettablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $1 : "dbo" ;
my $targ_table           = ($opt_targettablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $2 : $opt_targettablename;
die 'bad tablename' if $targ_table =~ m{ \. }xms or $targ_schema =~ m{ \. }xms; # it went wrong if we still have an embedded .

my $dbh             = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });


my $staticDataScript = VSGDR::MergeData::generateScript($dbh,$src_schema,$src_table,$targ_schema,$targ_table) ;
say $staticDataScript; 

exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genMergeData.pl - Creates a static data script for a database table

=head1 VERSION

0.01


=head1 USAGE

genMergeData.pl -t <tablename> -c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -s[ourcetable][name]   [=] <sourcetablename>

Specify source tablename

=for Euclid:
    sourcetablename.type:    string

=item  -t[argettable][name]   [=] <targettablename>

Specify tablename

=for Euclid:
    targettablename.type:    string

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=back


=head1 OPTIONS

=over


=back


=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2017, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

