package blx::xsdsql::xml;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw( nvl ev);
use blx::xsdsql::xml::reader;
use blx::xsdsql::xml::writer;
use blx::xsdsql::schema_repository::extra_tables;
use blx::xsdsql::schema_repository::binding;

sub new {
	my ($class,%params)=@_;
	affirm { defined $params{DB_CONN} } "param DB_CONN not set";
	affirm { defined $params{SCHEMA} } "param SCHEMA not set"; 
	affirm { defined $params{DB_NAMESPACE} } "param DB_NAMESPACE not set";
	affirm { !defined $params{EXTRA_TABLES} } "param EXTRA_TABLES is reserved";
	affirm { !defined $params{BINDING} } "param BINDING is reserved";
	affirm { !defined $params{SQL_BINDING} } "param SQL_BINDING is obsolete";
	$params{OUTPUT_NAMESPACE}='sql' unless defined $params{OUTPUT_NAMESPACE}; 

	$params{EXTRA_TABLES}=blx::xsdsql::schema_repository::extra_tables::factory_instance(
		map { ($_,$params{$_}) } (qw(OUTPUT_NAMESPACE DB_NAMESPACE DEBUG)) 
	);	
	
	$params{BINDING}=blx::xsdsql::schema_repository::binding::factory_instance(
		map { ($_,$params{$_}) } (qw(OUTPUT_NAMESPACE DB_NAMESPACE DEBUG DB_CONN EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX))
	);
	
	my %p=map { ($_,$params{$_}) } qw(BINDING SCHEMA DEBUG PARSER XMLWRITER EXTRA_TABLES);
	my $reader=blx::xsdsql::xml::reader->new(%p);
	my $writer=blx::xsdsql::xml::writer->new(%p);
	return bless { 
					%params
					,READER 	=> $reader
					,WRITER 	=> $writer
				},$class;				
}

sub read {
	my ($self,%params)=@_;
	return $self->{READER}->read(%params);
}


sub write {
	my ($self,%params)=@_;
	return $self->{WRITER}->write(%params);
}

sub finish {
	my ($self,%params)=@_;
	$self->{READER}->finish(%params);
	$self->{WRITER}->finish(%params);
	$self;
}

1;

__END__

=head1  NAME

blx::xsdsql::xml - read/write xml file from/to sql database

=cut

=head1 SYNOPSIS

use blx::xsdsql::xml

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions

new - constructor

    PARAMS:
        XMLWRITER                  => instance of class XML::Writer
                                        if is not set the object is instance automatically
        XMLPARSER                  => instance of class XML::Parser
                                        if is not set the object is instance automatically
        OUTPUT_NAMESPACE        => output namespace (default 'sql')
        DB_NAMESPACE             => database namespace
        DB_CONN                 => DBI connection
        SCHEMA                   => schema object
        EXECUTE_OBJECTS_PREFIX     => prefix for objects in execution
        EXECUTE_OBJECTS_SUFFIX     => suffix for objects in execution
        DEBUG                    => emit debug info


read - read a xml file and put into the database

    PARAMS:
        FD   =>  input file description (default stdin)
    the method return the id inserted into the  root table


write - write a xml file from database

    PARAMS:
        FD                             =>  output file descriptor (default stdout)
        ROOT_ID                        => root_id - the result of the method read
        DELETE_ROWS                 => if true write to FD and delete the rows from the database
        ROOT_TAG_PARAMS               => force a hash or array of key/value for root tag in write xml
        HANDLE_BEFORE_XMLDECL        => pointer sub called before xmlDecl
        HANDLE_AFTER_XMLDECL            => pointer sub called after xmlDecl
        HANDLE_BEFORE_START_NODE    => pointer sub called before a start node is write
        HANDLE_AFTER_START_NODE     => pointer sub called after a start node  is write
        HANDLE_BEFORE_END_NODE      => pointer sub called before a end node is write
        HANDLE_AFTER_END_NODE       => pointer sub called after a end node  is write
        HANDLE_BEFORE_DATA_ELEMENT    => pointer sub called before write dataElement
        HANDLE_AFTER_DATA_ELEMENT    => pointer sub called after write dataElement
        HANDLE_BEFORE_END              => pointer sub called before end of document
        HANDLE_AFTER_END              => pointer sub called after end of document
        NO_WRITE_HEADER                => if true not write the xml header
        NO_WRITE_FOOTER                => if true not write the xml footer

    the method return the self object if root_id exist in the database else return undef



finish -  close the sql statements prepared

    the method return the self object

=cut



=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::parser
for parse a xsd file (schema file)


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
