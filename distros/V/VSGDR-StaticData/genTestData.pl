#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';


use Carp;
use DBI;

our $opt_tablename;
our $opt_connection;
our $opt_sql;
our $opt_noMinimalForm;
our $opt_noIgnoreNulls;

use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use VSGDR::StaticData;

use version ; our $VERSION = qv('0.02');

my $schema          = ($opt_tablename =~ m{ \A \[(.+)\] \. (\[.+\]) \z
                                          | \A \[(.+)\] \. (.+)     \z
                                          | \A (.+)     \. (\[.+\]) \z
                                          | \A (.+)     \. (.+)     \z
                                          }xmis) ? ($1||$3||$5||$7) : "dbo" ;
my $table           = ($opt_tablename =~ m{ \A (\[.+\]) \. \[(.+)\] \z
                                          | \A (\[.+\]) \. (.+)     \z
                                          | \A (.+)     \. \[(.+)\] \z
                                          | \A (.+)     \. (.+)     \z
                                          }xmis) ? ($2||$4||$6||$8) : $opt_tablename ;

my $sql             = $opt_sql ;
my $use_MinimalForm = ! $opt_noMinimalForm ;
my $use_IgnoreNulls = ! $opt_noIgnoreNulls ;

#die 'bad tablename' if $table =~ m{ \. }xms or $schema =~ m{ \. }xms; # it went wrong if we still have an embedded .

my $dbh             = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });


my $staticDataScript = VSGDR::StaticData::generateTestDataScript($dbh,$schema,$table,$sql,$use_MinimalForm,$use_IgnoreNulls) ;
say $staticDataScript; 

exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genTestData.pl - Creates a static data script for a set of data to insert into a table

=head1 VERSION

0.02


=head1 USAGE

genTestData.pl -t <tablename> -s <sql> -c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -t[able][name]   [=] <tablename>

Specify tablename

=for Euclid:
    tablename.type:    string

=item  -s[ql]   [=] <sql>

Specify sql select statement

=for Euclid:
    sql.type:    string

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=back

=head1 OPTIONS

=over

=item  --[no]MinimalForm
 
[Don't] create just the values fragment, rather than the whole insert statement
 
=for Euclid:
    false: --MinimalForm
 
=item  --[no]IgnoreNulls
 
[Don't] extract values where everything is null
 
=for Euclid:
    false: --IgnoreNulls
 


=back



=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.


=head1 COPYRIGHT

Copyright (c) 2018, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

