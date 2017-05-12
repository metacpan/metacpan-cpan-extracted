package blx::xsdsql::schema_repository::catalog;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7


use blx::xsdsql::schema_repository::catalog_xml;
use base qw(blx::xsdsql::schema_repository::base);


my @ATTRIBUTE_KEYS:Constant(qw(
		CATALOG_NAME
		SCHEMA
	)
);

our %_ATTRS_R:Constant(());

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub { croak "$a: this attribute is not writeble" })} @ATTRIBUTE_KEYS
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _set_schema_code_t { 
	my ($self,$table,%params)=@_;
	for my $t($table->get_child_tables) {
		$t->set_attrs_value(SCHEMA_CODE => $params{SCHEMA_CODE})
			unless defined $t->get_attrs_value(qw(SCHEMA_CODE));
		$self->_set_schema_code_t($t,%params);
	}
	$table->set_attrs_value(SCHEMA_CODE => $params{SCHEMA_CODE})
			unless defined $table->get_attrs_value(qw(SCHEMA_CODE));
	$self;
}

sub _set_schema_code {
	my ($self,$schema,%params)=@_;
	my $root_table=$schema->get_root_table;
	my $h=$schema->get_types_name;
	my $schema_code=$schema->get_attrs_value(qw(SCHEMA_CODE));

	for my $t(values %$h) {
		$self->_set_schema_code_t($t,SCHEMA_CODE => $schema_code);
	}
	$self->_set_schema_code_t($root_table,SCHEMA_CODE => $schema_code);
	for my $child($schema->get_childs_schema) {
		$self->_set_schema_code($child->{SCHEMA},%params);
	}
	$self;
}

sub new {
	my ($class,%params)=@_;
	affirm { defined $params{CATALOG_NAME} } "param CATALOG_NAME not set";
	affirm { defined $params{SCHEMA} } "param SCHEMA not set";
	my $self=bless \%params,$class;
	$self->_set_schema_code($params{SCHEMA}) unless $params{NOT_SET_CHILDS};
	$self;
}


sub drop {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	return unless defined $self->{CATALOG_NAME};
	affirm { grep($self->{CATALOG_NAME} eq $_,$self->{_PARENT_OBJECT}->get_catalog_names )} 
		$self->{CATALOG_NAME}.': catalog not exist into repository';
	$self->{_PARENT_OBJECT}->{_INSTANCE}->{STOWAGE}->drop_catalog_views($self->{CATALOG_NAME},%params);
	my $r=$self->{_PARENT_OBJECT}->{_INSTANCE}->{STOWAGE}->drop_catalog($self->{CATALOG_NAME},%params);
	return unless defined $r;
	delete $self->{CATALOG_NAME};
	return $self;
}

sub drop_views {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	return unless defined $self->{CATALOG_NAME};
	affirm { grep($self->{CATALOG_NAME} eq $_,$self->{_PARENT_OBJECT}->get_catalog_names )} 
		$self->{CATALOG_NAME}.': catalog not exist into repository';
	return $self->{_PARENT_OBJECT}->{_INSTANCE}->{STOWAGE}->drop_catalog_views($self->{CATALOG_NAME},%params);
}

sub create_views {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	affirm { !defined $params{SCHEMA} } 'the param SCHEMA is reserved';
	return unless defined $self->{CATALOG_NAME};
	return unless $self->{_PARENT_OBJECT}->is_support_views; 
	affirm { grep($self->{CATALOG_NAME} eq $_,$self->{_PARENT_OBJECT}->get_catalog_names )} 
		$self->{CATALOG_NAME}.': catalog not exist into repository';
	return $self->{_PARENT_OBJECT}->{_INSTANCE}->{STOWAGE}->create_catalog_views($self->{CATALOG_NAME},$self->{SCHEMA},%params);
}

sub get_xml_stored {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	my @rows=$self->{_PARENT_OBJECT}->{_INSTANCE}->{XML}->get_xml_stored(%params,CATALOG_NAME => $self->{CATALOG_NAME});
	return wantarray ? @rows : \@rows;
}

sub get_catalog_xml {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	return unless defined $self->{CATALOG_NAME};
	return blx::xsdsql::schema_repository::catalog_xml->new(
		%params
		,_PARENT_OBJECT => $self
	);
}

sub get_object_names {
	my ($self,%params)=@_;
	affirm { !defined $params{CATALOG_NAME} } 'the param CATALOG_NAME is reserved';
	affirm { !defined $params{TYPE} || grep($_ eq $params{TYPE},qw(table view)) } "the param TYPE must be unset or with value table|view";
	unless ($self->{_PARENT_OBJECT}->is_repository_installed) {
		return wantarray ? () : undef;
	}
	return $self->{_PARENT_OBJECT}->{_INSTANCE}->{STOWAGE}->get_catalog_object_names(CATALOG_NAME => $self->{CATALOG_NAME},%params);
} 



1;

__END__

=head1  NAME blx::xsdsql::schema_repository::catalog


=cut

=head1 DESCRIPTION

API class for manage catalog

=cut

=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions


create_views - create the views on database objects
                if the repository is not installed, the catalog not exists or the database not support views return undef
                otherwise the self object
    PARAMS:
        FD - file description opened in output mode
             if it's set the views are not created but emit on FD the commands for created it
        TABLES_FILTER - if it's set create the views only for the list of table_name/xml_path specify


drop_views - drop the views associated to a catalog
             if the repository is not installed or the catalog not exists the method return undef
             otherwise the self object


drop  - drop it self from database
        if the repository is not installed or the catalog not exists the method return undef
        otherwise the self object


get_catalog_xml - return an object of type blx::xsdsql::schema_repository::catalog_xml for read or store xml
     PARAMS:
        EXECUTE_OBJECTS_PREFIX     - prefix for objects in execution (default none)
        EXECUTE_OBJECTS_SUFFIX     - suffix for objects in execution (default none)
        XMLWRITER                  - instance of class XML::Writer
                                     if is not set is instance automatically
        XMLPARSER                  - instance of class XML::Parser
                                     if is not set is instance automatically

get_xml_stored - return a list of xml stored into the repository for the current catalog
                if the repository is not installed in list mode return an empty list otherwise undef
                the component of the list is a list with id,catalog_name,xml_name
        PARAMS:
            ID         -  filter by xml id
            XML_NAME   -  filter by xml name

get_object_names - return a list of objects stored into the repository
                   if the repository  is not installed in list mode return an empty list otherwise undef
    PARAMS:
           OBJECT_TYPE        => table|view  if is not set return a list of tables and views


=head1 SEE ALSO

blx::xsdsql::00_readme_API
blx::xsdsql::schema_repository
blx::xsdsql::schema_repository::catalog_xml
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


