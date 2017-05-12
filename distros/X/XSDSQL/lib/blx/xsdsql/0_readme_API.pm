
use strict; # for PBP

1;

__END__

=head1 NAME

blx::xsdsql - stored xsd schema and xml into database
              the database supported are DBM (with MLDBM), oracle,postgresql and mysql
              see blx::xsdsql::connection for examples of connection to a specific database

=head1 VERSION

0.10.0


=head1 DESCRIPTION


this manual describe the basically use of xsdsql API

for a complete description of the api see
blx::xsdsql::connection
blx::xsdsql::schema_repository
blx::xsdsql::schema_repository::catalog
blx::xsdsql::schema_repository::catalog_xml
blx::xsdsql::xsd_parser


=head1 SYNOPSYS


=head2 create the database connection

use DBI;

my $dbi=DBI->connect(   #get a database connection - see the DBI manual for DBI::connect arguments
    'DBI:Pg:host=127.0.0.1:dbname=mydb','user','pwd'
    ,{ Raise_error => 1,Autocommit => 0,pg_enable_utf8=> 1}
)

another method is:

use blx::xsdsql::connection;

my $conn=blx::xsdsql::connection->new(
            CONNECTION_STRING => 'sql::pg:myuser/mypwd@mydb:127.0.0.1:5432;RaiseError => 1,AutoCommit => 0,pg_enable_utf8 => 1'
 )

my $dbi=DBI->connect($conn->get_connection_list);



=head2 create the repository

use blx::xsdsql::schema_repository;

my $repo=blx::xsdsql::schema_repository->new(    #create the repository object
                                                 #the repository contain the base objects for all catalogs
                                                 #and must be create before create a catalog
    DB_CONN              => $dbi
    ,OUTPUT_NAMESPACE    => 'sql'  # output namespace can be omitted - 'sql' is the default
    ,DB_NAMESPACE        => "pg"   # is a code for postgresql
                                   # see the class method blx::xsdsql::schema_repository::get_namespaces for valid namespaces
 );

$repo->create_repository;          # create the objects on the database

$conn->commit;


=head2 create the catalog

use blx::xsdsql::xsd_parser;

my $parser= blx::xsdsql::xsd_parser->new(
    OUTPUT_NAMESPACE     => $conn->get_output_namespace
   ,DB_NAMESPACE         => $conn->get_db_namespace
 );

my $schema=$parser->parsefile(  #parse a schema file
    'schema001.xsd'
    ,TABLE_PREFIX    => 'T001'
    ,VIEW_PREFIX    => 'V001'
);

my $catalog=$repo->create_catalog('catalog001',$schema); #now the catalog is create

$conn->commit;  # commit the data written into the repository



=head2 store an xml file  into the repository


my $catalog=$repo->get_catalog('catalog001');

my $catalog_xml=$catalog->get_catalog_xml;

open(my $fd,'<','1.xml');

my $id=$catalog_xml->store_xml(  #store xml with name
    ,XML_NAME            =>  'xml001'
    ,FD                  =>  $fd
);

or

my $id=$catalog_xml->store_xml(  #store xml without name
    FD                  =>  $fd
);

$conn->commit;  # commit the data written into the repository

=head2 emit an xml to stdout

my $id=$catalog_xml->put_xml( #emit an xml from name to stdout
    XML_NAME         => 'xml001'
    ,FD              => *STDOUT
 );

or

my $id=$catalog_xml->put_xml( #emit an xml from id to stdout
    ID           => $id
 );

=head2 delete an xml stored into the repository

use File::Spec;

open (my fd,'>',File::Spec->devnull());

my $id=$catalog_xml->put_xml( #emit an xml to null device
    XML_NAME            => 'xml001'
    ,FD                 => $fd
    ,DELETE             => 1
 );


=head2 print catalog names stored into the repository

print join("\n",$repo->get_catalog_names),"\n";


=head2 print id,catalog_name,xml_name stored in the repository for the current catalog

for my $r($catalog->get_xml_stored) {
    print join(",",map { defined $_ ? $_ : '' },@$r),"\n";
 }


=head2 print all xml names stored in the repository

for my $catalog($repo->get_all_catalogs) {
    for my $r($catalog->get_xml_stored) {
        next unless defined $r->[2];
        print $r->[2],"\n";
    }
 }

=head1 SEE ALSO

blx::xsdsql::schema_repository

blx::xsdsql::schema_repository::catalog

blx::xsdsql::schema_repository::catalog_xml

blx::xsdsql::xsd_parser

=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
