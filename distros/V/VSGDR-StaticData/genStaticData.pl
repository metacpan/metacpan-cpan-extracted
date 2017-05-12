#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';


use Carp;
use DBI;

our $opt_tablename;
our $opt_connection;

use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use VSGDR::StaticData;

use version ; our $VERSION = qv('0.02');

my $schema          = ($opt_tablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $1 : "dbo" ;
my $table           = ($opt_tablename =~ m{ \A ([^.]+) \. ([^.]+) \z }xms) ? $2 : $opt_tablename;
die 'bad tablename' if $table =~ m{ \. }xms or $schema =~ m{ \. }xms; # it went wrong if we still have an embedded .

my $dbh             = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });


my $staticDataScript = VSGDR::StaticData::generateScript($dbh,$schema,$table) ;
say $staticDataScript; 

exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genStaticData.pl - Creates a static data script for a database table

=head1 VERSION

0.02


=head1 USAGE

genStaticData.pl -t <tablename> -c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -t[able][name]   [=] <tablename>

Specify tablename

=for Euclid:
    tablename.type:    string

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

Copyright (c) 2013, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

