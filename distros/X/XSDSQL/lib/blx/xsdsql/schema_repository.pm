package blx::xsdsql::schema_repository;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base qw(blx::xsdsql::ut::common_interfaces);

use blx::xsdsql::xsd_parser qw(USER_SCHEMA_CLASS);
use blx::xsdsql::ut::ut qw(ev);
use blx::xsdsql::schema_repository::extra_tables;
use blx::xsdsql::generator;
use blx::xsdsql::ios::debuglogger;
use blx::xsdsql::schema_repository::binding;
use blx::xsdsql::schema_repository::catalog;

my @ATTRIBUTE_KEYS:Constant(qw(
		DB_CONN
		OUTPUT_NAMESPACE
		DB_NAMESPACE
		BINDING 
		GENERATOR 
		EXTRA_TABLES 
		LOGGER
	)
);
	
our %_ATTRS_R:Constant(
	SQL_BINDING	=> sub { croak "the attribute SQL_BINDING is obsolete\n"; } 
);

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } @ATTRIBUTE_KEYS
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


sub get_namespaces {
	my @l=blx::xsdsql::generator::get_namespaces(@_);
	return wantarray ? @l : \@l;
}

sub check_namespaces {
	my %params=@_;
	affirm { defined $params{OUTPUT_NAMESPACE} } "param OUTPUT_NAMESPACE not set";
	affirm { defined $params{DB_NAMESPACE} } "param DB_NAMESPACE not set";
	return grep( $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE} eq $_,get_namespaces)
		? 1 
		: 0
	;
}

sub new  { 
	my ($class,%params)=@_;
	affirm { defined $params{DB_CONN} } "param DB_CONN not set";
	$params{OUTPUT_NAMESPACE}='sql' unless defined  $params{OUTPUT_NAMESPACE};
	affirm { defined $params{DB_NAMESPACE}} "param DB_NAMESPACE not set";
	affirm { check_namespaces(%params) } $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.": namespace not know"; 
	affirm { ! defined $params{SQL_BINDING} } "param SQL_BINDING is obsolete";
	affirm { ! defined $params{BINDING} } "param BINDING is reserved";
	affirm { ! defined $params{EXTRA_TABLES} } "param EXTRA_TABLES is reserved";
	affirm { ! defined $params{LOGGER} } "param LOGGER is reserved";
	
	$params{_EXTRA_TABLES}=blx::xsdsql::schema_repository::extra_tables::factory_instance(
				map { ($_,$params{$_}) } qw(OUTPUT_NAMESPACE DB_NAMESPACE DEBUG)
	);
	
	$params{_BINDING}=blx::xsdsql::schema_repository::binding::factory_instance(
			map { ($_,$params{$_}) } qw(OUTPUT_NAMESPACE DB_NAMESPACE DB_CONN DEBUG)
	);
	
	$params{_GENERATOR}=blx::xsdsql::generator->new(
			BINDING			=> $params{_BINDING}
			,EXTRA_TABLES	=> $params{_EXTRA_TABLES} 
	);
	
	$params{_LOGGER}=blx::xsdsql::ios::debuglogger->new(DEBUG => $params{DEBUG});
	
	my %instance=map {
		my $class='blx::xsdsql::schema_repository::'.lc($_);
		ev('use',$class);
		($_,$class->new(%params))
	} qw(STOWAGE  LOADER XML);
	$params{_INSTANCE}=\%instance;
	
	for my $k(qw(BINDING GENERATOR EXTRA_TABLES LOGGER)) {  # public attributes
		$params{$k}=$params{'_'.$k};
	}
	
	my $self=bless {},$class;
	for my $k(@ATTRIBUTE_KEYS) { $self->{$k}=delete $params{$k} }
	return $self->set_attrs_value(%params);
}

sub is_repository_installed {
	my ($self,%params)=@_;
	return $self->{_INSTANCE}->{STOWAGE}->is_repository_installed;
}

sub drop_repository {
	my ($self,%params)=@_;
	return unless $self->is_repository_installed; 
	$self->drop_all_catalogs(%params);
	return $self->{_INSTANCE}->{STOWAGE}->drop_repository(%params);
}

sub drop_all_catalogs {
	my ($self,%params)=@_;
	return unless $self->is_repository_installed; 
	for my $cat($self->get_all_catalogs) {
		$cat->drop(%params);
	}
	return $self;
}


sub create_repository {
	my ($self,%params)=@_;
	return if $self->is_repository_installed && !defined $params{FD};	
	return $self->{_INSTANCE}->{STOWAGE}->create_repository(%params);	
}

sub create_catalog {
	my ($self,$catalog_name,$schema,%params)=@_;
	affirm { defined $catalog_name } "1^ param not set";
	affirm { defined $schema } " 2^ param not set";
	affirm { ref($schema) eq USER_SCHEMA_CLASS } ref($schema).": the value of 2^ param  must be of ".USER_SCHEMA_CLASS." class";  
	affirm { $schema->get_attrs_value(qw(OUTPUT_NAMESPACE)) eq $self->{OUTPUT_NAMESPACE} }
		'OUTPUT_NAMESPACE conflict';
	affirm { $schema->get_attrs_value(qw(DB_NAMESPACE)) eq $self->{DB_NAMESPACE} }
		'DB_NAMESPACE conflict';
	return if grep($catalog_name eq $_,$self->get_catalog_names) && !defined $params{FD};
	my $r=$self->{_INSTANCE}->{STOWAGE}->create_catalog($catalog_name,$schema,%params);
	return unless defined $r;
	return blx::xsdsql::schema_repository::catalog->new(
		CATALOG_NAME 	=> $catalog_name
		,_PARENT_OBJECT => $self
		,SCHEMA     	=> $schema
	);
}

sub get_catalog {
	my ($self,$catalog_name,%params)=@_;
	affirm { defined $catalog_name } "1^ param not set";
	return unless grep($catalog_name eq $_,$self->get_catalog_names);
	my $schema=$self->{_INSTANCE}->{LOADER}->load_schema_from_catalog($catalog_name,%params);
	return unless defined $schema;
	return blx::xsdsql::schema_repository::catalog->new(
		CATALOG_NAME 	=> $catalog_name
		,_PARENT_OBJECT => $self
		,SCHEMA     	=> $schema
		,NOT_SET_CHILDS	=> 1
	);
}

sub get_all_catalogs {
	my ($self,%params)=@_;
	my @a=();
	for my $catalog_name($self->get_catalog_names) {
		push @a,$self->get_catalog($catalog_name,%params);
	}
	return wantarray ? @a : \@a;
}


sub get_catalog_names {
	my ($self,%params)=@_;
	unless ($self->is_repository_installed(%params)) {
		return wantarray ? () : undef;
	}
	return $self->{_INSTANCE}->{STOWAGE}->get_catalog_names;
}


sub get_dictionary_tables {
	my ($self,%params)=@_;
	my @t=map { $self->{_EXTRA_TABLES}->get_extra_table($_) } $self->{_EXTRA_TABLES}->get_extra_table_types('DICTIONARY_TABLES');
	return wantarray ? @t : \@t;
}


sub get_dtd_tables {
	my ($self,%params)=@_;
	my @t=map { $self->{_EXTRA_TABLES}->get_extra_table($_) } $self->{_EXTRA_TABLES}->get_extra_table_types('DTD_TABLES');
	return wantarray ? @t : \@t;
}

sub get_table_types {
	my ($self,%params)=@_;
	my $types=$self->{_EXTRA_TABLES}->get_extra_table_types;
	return wantarray ? @$types : $types; 
}

sub get_table_from_type {
	my ($self,%params)=@_;
	my @types=$self->get_table_types;
	my $type=$params{TYPE};
	$type=[@types] unless defined $type;
	$type=[$type] if ref($type) eq '';
	affirm { ref($type) eq 'ARRAY' } "param TYPE must be a scalar or an ARRAY";
	my @tables=map {
			my $t=$_;
			affirm {grep($t eq $_, @types) } "param TYPE not correct";
			$self->{_EXTRA_TABLES}->get_extra_table($t)
	} @$type;
	return @tables if wantarray;
	return \@tables unless defined $params{TYPE};
	return \@tables if ref($params{TYPE}) eq 'ARRAY';
	$tables[0];
}


sub is_support_views {
	my ($self,%params)=@_;
	return $self->{_EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->is_support_views;
}

	
1;


__END__


=head1  NAME

blx::xsdsql::schema_repository -  API class for manage repository

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository

=cut


=head1 DESCRIPTION

this package is a class - install with a method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions

get_namespaces - return a list of namespaces know
                 this is a class method


check_namespaces - check if namespaces is know
                   this is a class method
    PARAMS:
            OUTPUT_NAMESPACE  - output namespace  (default sql)
            DB_NAMESPACE      - database type

new - constructor
    PARAMS:
            DB_CONN - connection object - normally a DBI connection object
            DEBUG  - if true set the debug mode
            OUTPUT_NAMESPACE - output namespace - the defaul is 'sql'
            DB_NAMESPACE - database namespace

create_repository - create the repository on database
                    if the repository is already installed and params FD it's not set the method return undef
                    otherwise the self object
    PARAMS:
            FD - file description opened in output mode
                 if it's set the repository is not create but emit on FD the commands for create the repository


create_catalog - create a catalog on database
                 if the repository is not installed or the catalog already exists and the param FD it's not set return undef
                 otherwise the a blx::xsdsql::schema_repository::catalog object
    ARGUMENTS:
            catalog name - a uniq name into the repository
            schema  - schema object, is the output of method blx::xsdsql::xsd_parser::parsefile

    PARAMS:
            FD - file description opened in output mode
                 if it's set the catalog is not create but emit on FD the commands for create the catalog
            SCHEMA_CODE - schema code associated at schema  - if it's not set is automatically set by the system

drop_all_catalogs - drop all catalogs
                    if the repository is not installed the method return undef
                    otherwise the self object

drop_repository - drop the entiry repository
                  if the repository is not installed the method return undef
                  otherwise the self object

is_repository_installed - return true if the repository is installed on database


is_support_views - return true if database support complex views

get_catalog_names - return a list of catalog names stored into the repository
                    if the repository is not installed in list mode return an empty list otherwise undef


get_catalog - return a blx::xsdsql::schema_repository::catalog object
    ARGUMENTS:
            catalog name - a uniq name into the repository



get_dictionary_tables - return a list of table objects relative to dictionary


get_dtd_tables - return a list of table objects relative to dtd


get_table_types - return a list of table types


get_table_from_type - return a table object or list of table object

    PARAMS:

        TYPE - a table type or a list of table type
               if it's not set all table types are assumed



=head1 SEE ALSO

blx::xsdsql::00_readme_API
blx::xsdsql::schema_repository::catalog
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


