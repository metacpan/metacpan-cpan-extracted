package blx::xsdsql::schema_repository::catalog_xml;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::xml;
use base qw(blx::xsdsql::schema_repository::base);

my @ATTRIBUTE_KEYS:Constant(
	CATALOG_NAME
	,OUTPUT_NAMESPACE 
	,DB_NAMESPACE
	,SCHEMA
);

our %_ATTRS_R:Constant(
	OUTPUT_NAMESPACE => sub { $_[0]->{PARENT_OBJECT}->get_attrs_value(qw(OUTPUT_NAMESPACE)) }
	,DB_NAMESPACE	 => sub { $_[0]->{PARENT_OBJECT}->get_attrs_value(qw(DB_NAMESPACE)) }
);

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub { croak "$a: this attribute is not writeble" })} @ATTRIBUTE_KEYS
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


sub new {
	my ($class,%params)=@_;	
	my $p=delete $params{_PARENT_OBJECT};
	$params{_XML}=blx::xsdsql::xml->new(
		%params
		,OUTPUT_NAMESPACE 		=> $p->{_PARENT_OBJECT}->get_attrs_value(qw(OUTPUT_NAMESPACE))
		,DB_NAMESPACE 			=> $p->{_PARENT_OBJECT}->get_attrs_value(qw(DB_NAMESPACE))  
		,DB_CONN     			=> $p->{_PARENT_OBJECT}->get_attrs_value(qw(DB_CONN))
		,SCHEMA   				=> $p->{SCHEMA}
		,DEBUG					=> $p->{_PARENT_OBJECT}->get_attrs_value(qw(DEBUG))
	);
	$params{_PARENT_OBJECT}=$p;
	return bless \%params,$class;
}


sub store_xml {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	$params{CATALOG_NAME}=$self->{_PARENT_OBJECT}->get_attrs_value(qw(CATALOG_NAME));

	my $xml=$self->{_PARENT_OBJECT}->{_PARENT_OBJECT}->{_INSTANCE}->{XML};
	if (defined ($params{XML_NAME})) { #return if xml name already exist
		my @rows=$xml->get_xml_names(%params);
		return if scalar(@rows);
	}
	
	return $xml->store_xml(
		$self->{_XML}
		,%params
		);
}

sub put_xml {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME are reserved';
	affirm { (defined $params{XML_NAME}) != (defined $params{ID}) } 'the param XML_NAME or ID must be set'; 
	my $xml=$self->{_PARENT_OBJECT}->{_PARENT_OBJECT}->{_INSTANCE}->{XML};
	$params{CATALOG_NAME}=$self->{_PARENT_OBJECT}->get_attrs_value(qw(CATALOG_NAME));
	
	my $id=$params{ID};
	if (defined $params{XML_NAME}) {
		my @rows=$xml->get_xml_stored(%params); 
		return unless scalar(@rows); # xml name not exist into catalog_name
		$id=$rows[0]->[0];
	}
	else { # is ok because test if id exists into catalog name 
		my @rows=$xml->get_xml_stored(%params); 
		return unless scalar(@rows); # xml id not exist into catalog name
	}

	return $xml->put_xml(
		$self->{_XML}
		,%params
		,ID => $id
	);
}


1; 

__END__

=pod

=head1  NAME blx::xsdsql::schema_repository::catalog_xml

=cut

=head1 DESCRIPTION

API class for manage xml

=cut


=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions

store_xml - store an xml file into the repository
            if the repository is not installed  the method return undef
            otherwise a uniq id associate to xml
    PARAMS:
            XML_NAME - if this param is set the association from your id is stored into the repository
                       if XML_NAME already exist the method return undef and the file is not stored
            FD - file description opened in input mode relative to an xml file
                 if is not set the standard input is assumed


put_xml - put on file descriptor an xml stored into the database
            if the repository is not installed or the xml name or id not exists return undef
            otherwise a uniq id associated to the xml
    PARAMS:
            NAME or ID - name of an xml file or it's id
            FD - file description opened in output mode relative to an xml file
                 if it's not set standard output is assumed
            NO_WRITE_HEADER    - if it's true not write the xml header
            NO_WRITE_FOOTER    - if it's true not write the xml footer
            ROOT_TAG_PARAMS    - customized the root xml params
                                 if it's set must be a list of pair param_name => value
            DELETE            -  if it's true, after the output on FD, the xml is deleted from repository
            HANDLE_BEFORE_XMLDECL       - pointer sub called before xmlDecl
            HANDLE_AFTER_XMLDECL        - pointer sub called after xmlDecl
            HANDLE_BEFORE_START_NODE    - pointer sub called before a start node is write
            HANDLE_AFTER_START_NODE     - pointer sub called after a start node  is write
            HANDLE_BEFORE_END_NODE      - pointer sub called before a end node is write
            HANDLE_AFTER_END_NODE       - pointer sub called after a end node  is write
            HANDLE_BEFORE_DATA_ELEMENT  - pointer sub called before write dataElement
            HANDLE_AFTER_DATA_ELEMENT   - pointer sub called after write dataElement
            HANDLE_BEFORE_END           - pointer sub called before end of document
            HANDLE_AFTER_END            - pointer sub called after end of document
            HANDLE_BEFORE_RAW_DATA      - pointer sub called before write rawdata
            HANDLE_AFTER_RAW_DATA       - pointer sub called after write rawdata

=head1 SEE ALSO

blx::xsdsql::00_readme_API
blx::xsdsql::schema_repository
blx::xsdsql::schema_repository::catalog
blx::xsdsql::xsd_parser

=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


