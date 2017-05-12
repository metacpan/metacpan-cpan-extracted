package blx::xsdsql::schema_repository::sql::generic::extra_tables;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::schema_repository::sql::generic::table qw(:overload);
use blx::xsdsql::ut::ut qw(ev);
use blx::xsdsql::xsd_parser::type::simple;

use base(qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::ios::debuglogger Exporter));


my  %t=( constants => [ qw (
	TABLE_TYPE_GROUPS
	TABLE_TYPE_GROUP
	EXTRA_TABLES
	DEFAULT_EXTRA_TABLE_NAMES
	SEQUENCE_NAME
	MAXLIMITED_STRING_TYPE	
	PK_ID_TYPE				
	PK_SEQ_TYPE	
	FIXED1_TYPE	  
	STRING5_TYPE			
	PREDEF_TYPES
	PREDEF_COLUMNS
) ]);

our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=qw( );


use constant {
				TABLE_TYPE_GROUPS => [qw(DICTIONARY_TABLES DTD_TABLES)]
				,TABLE_TYPE_GROUP => {
					DICTIONARY_TABLES => [
											qw(
												CATALOG_DICTIONARY
												SCHEMA_DICTIONARY 
												TABLE_DICTIONARY 
												VIEW_DICTIONARY
												COLUMN_DICTIONARY 
												RELATION_TABLE_DICTIONARY
												RELATION_SCHEMA_DICTIONARY
												XML_CATALOG
												XML_ENCODING
												XML_ID
											)
										]
					
					,DTD_TABLES		=>  [
											qw(
												DOCTYPE_TABLE
												DTDSEQ_TABLE
												NOTATION_TABLE
												ENTITY_TABLE
												ATTLIST_TABLE
												ELEMENT_TABLE
											)
										]
				}
};
				
use constant {
				EXTRA_TABLES => sub {
					my @l=();
					for my $g(@{&TABLE_TYPE_GROUPS}) {
						push @l,@{&TABLE_TYPE_GROUP->{$g}};
					}
					return \@l;
				}->()
				,DEFAULT_EXTRA_TABLE_NAMES =>  {
						CATALOG_DICTIONARY				=> 'catalog_dictionary'
						,SCHEMA_DICTIONARY				=> 'schema_dictionary'
						,TABLE_DICTIONARY				=> 'table_dictionary'
						,VIEW_DICTIONARY				=> 'view_dictionary'
						,COLUMN_DICTIONARY				=> 'column_dictionary'
						,RELATION_TABLE_DICTIONARY		=> 'relation_table_dictionary'
						,RELATION_SCHEMA_DICTIONARY	 	=> 'relation_schema_dictionary'
						,XML_CATALOG					=> 'xml_catalog'
						,XML_ID							=> 'xml_id'
						,DOCTYPE_TABLE					=> 'dtd_doctype'
						,DTDSEQ_TABLE					=> 'dtd_seq'
						,NOTATION_TABLE					=> 'dtd_notation'
						,ENTITY_TABLE					=> 'dtd_entity'
						,ATTLIST_TABLE					=> 'dtd_attlist'
						,ELEMENT_TABLE					=> 'dtd_element'
						,XML_ENCODING					=> 'xml_encoding'
				}
				,SEQUENCE_NAME							=> 'seq'
};

use constant {
		MAXLIMITED_STRING_TYPE	=>  { XSD_TYPE	=> 'string' }
		,PK_ID_TYPE				=>  { XSD_TYPE 	=> 'integer',LIMITS		=> { INT => 18} }
		,PK_SEQ_TYPE			=>  { XSD_TYPE 	=> 'integer',LIMITS		=> { INT => 18} }
		,FIXED1_TYPE			=>  { XSD_TYPE	=> 'string',LIMITS		=> { FIXSIZE => 1} }
		,STRING5_TYPE			=>  { XSD_TYPE  => 'string',LIMITS 		=> { SIZE => 5} }
		,BOOLEAN_TYPE			=>  { XSD_TYPE  => 'boolean' }
};

use constant {
	PREDEF_TYPES	=>  {
		MAXLIMITED_STRING_TYPE	=>  MAXLIMITED_STRING_TYPE
		,PK_ID_TYPE				=>  PK_ID_TYPE
		,PK_SEQ_TYPE			=>  PK_SEQ_TYPE
		,FIXED1_TYPE			=>  FIXED1_TYPE
		,STRING5_TYPE			=>  STRING5_TYPE 
		,BOOLEAN_TYPE			=>  BOOLEAN_TYPE
	}
	,PREDEF_COLUMNS	=>  {
		ID =>  {
					NAME  		=> '$ID'
					,MINOCCURS 	=> 	1
					,MAXOCCURS 	=> 	1
					,PK_SEQ 	=> 	0
					,TYPE		=>  PK_ID_TYPE
		}
		,SEQ =>  {
					NAME  		=> '$SEQ'
					,MINOCCURS 	=> 	1
					,MAXOCCURS 	=> 	1
					,PK_SEQ 	=> 	1
					,TYPE		=>  PK_SEQ_TYPE
		}
		,VALUE_COL =>  {
					NAME  		=> '$VALUE'
					,MINOCCURS 	=> 	1
					,MAXOCCURS 	=> 	1
					,TYPE		=>  MAXLIMITED_STRING_TYPE
					,VALUE_COL	=>  1
		}
		,SYS_ATTRIBUTES	=> {
					NAME			=> '$SYSATTRS'
					,MINOCCURS 		=> 	1
					,MAXOCCURS 		=> 	1
					,TYPE			=>  MAXLIMITED_STRING_TYPE
					,SYS_ATTRIBUTES	=> 1
		}
	}
};


my @ATTRIBUTE_KEYS:Constant(
						qw(
							LIMITS_CLASS
							COLUMN_CLASS
							TABLE_CLASS
							CATALOG_CLASS
							LIMITS_INSTANCE
							CATALOG_INSTANCE
							DEBUG
							OUTPUT_NAMESPACE
							DB_NAMESPACE
						)
);


our %_ATTRS_R:Constant(());

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } @ATTRIBUTE_KEYS
);

sub _get_attrs_r {  return \%_ATTRS_R; }
sub _get_attrs_w {  return \%_ATTRS_W; }

sub _new {
	my ($class,%params)=@_;
	affirm {  $class ne __PACKAGE__ } "the constructor of ".__PACKAGE__." must be inherited";
	affirm { defined $params{OUTPUT_NAMESPACE} } "param OUTPUT_NAMESPACE not set";
	affirm { defined $params{DB_NAMESPACE} } "param DB_NAMESPACE not set";
	for my $k(grep(/(_CLASS|_INSTANCE)$/,@ATTRIBUTE_KEYS)) {	
		affirm { !defined $params{$k} } "the param $k is reserved";
	}
	my $self=bless {},$class;
	my $prefix='blx::xsdsql::schema_repository::'.$params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.'::';

	for my $k(grep(/_CLASS$/,@ATTRIBUTE_KEYS)) {
		my ($base)=$k=~/^(\w+)_CLASS$/;
		$self->{$k}=$prefix.lc($base);
		ev('use',$self->{$k});
	}
	for my $k(grep(/_INSTANCE$/,@ATTRIBUTE_KEYS)) {
		my ($base)=$k=~/^(\w+)_INSTANCE$/;
		my $class=$prefix.lc($base);
		ev('use',$class);
		$self->{$k}=$class->new(DEBUG => $params{DEBUG});		
	}
	
	for my $k(grep($_!~/(_INSTANCE|_CLASS)$/,@ATTRIBUTE_KEYS)) {
		$self->{$k}=delete $params{$k};
	}
	$self->set_attrs_value(%params);
}


sub factory_column {
	my ($self,$predef_column,%params)=@_;
	my %args=();
	if (defined $predef_column) {
		my $c=$self->get_predefined_column_attrs($predef_column);
		affirm { defined $c } "$predef_column: unknow predefined column";
		%args=%$c;
	}
	for my $k(keys %params) { $args{$k}=$params{$k}}	
	my $type=delete $args{TYPE};
	my $col=$self->{COLUMN_CLASS}->new(%args,DEBUG => $self->{DEBUG});
	if (defined $type) {
		if (ref($type) eq 'HASH') {
			$col->set_attrs_value(TYPE => blx::xsdsql::xsd_parser::type::simple->new(%$type,COLUMN => $col));
		}
		elsif (ref($type) eq 'blx::xsdsql::xsd_parser::type::simple') {
			$type->set_attrs_value(COLUMN => $col);
			$col->set_attrs_value(TYPE => $type);
		}
		else {
			croak ref($type).": unknow type for TYPE attribute";
		}
		$col->set_sql_type(EXTRA_TABLES => $self);
	}	
	return $col;
}


sub _get_type_catalog_name_size {
	return 500;
}	

sub _get_type_schema_code_size {
	return 500;
}

sub _get_type_xml_name_size {
	return 500;
}

sub _factory_extra_table_columns {
	my ($self,$table_type,%params)=@_;

	my $type_catalog_name={ XSD_TYPE => 'string',LIMITS => { SIZE => $self->_get_type_catalog_name_size }};
	return (
		$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,PK_SEQ => 0) 
		,$self->factory_column(undef,NAME => 'output_namespace',TYPE => MAXLIMITED_STRING_TYPE) 
		,$self->factory_column(undef,NAME => 'db_namespace',TYPE => MAXLIMITED_STRING_TYPE) 
	) if $table_type eq 'CATALOG_DICTIONARY';
	
	my $type_schema_code={ XSD_TYPE => 'string',LIMITS => { SIZE => $self->_get_type_schema_code_size }};
	
	return 
		(
			$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,PK_SEQ => 0) 
			,$self->factory_column(undef,NAME => 'schema_code',TYPE => $type_schema_code,PK_SEQ => 1) 
			,$self->factory_column(undef,NAME => 'location',TYPE => MAXLIMITED_STRING_TYPE) 
			,$self->factory_column(undef,NAME => 'URI',TYPE => MAXLIMITED_STRING_TYPE) 
			,$self->factory_column(undef,NAME => 'element_form_default',TYPE => FIXED1_TYPE,ENUM_RESTRICTIONS => { Q => 'qualified' },COMMENT => 'values: Q is qualified - null is unqualified (the default)')
			,$self->factory_column(undef,NAME => 'attribute_form_default',TYPE => FIXED1_TYPE,ENUM_RESTRICTIONS => { Q => 'qualified' },COMMENT => 'values: Q is qualified - null is unqualified (the default)')
			,$self->factory_column(undef,NAME => 'is_root_schema',TYPE => BOOLEAN_TYPE)
			,$self->factory_column(undef,NAME => 'encoding',TYPE => MAXLIMITED_STRING_TYPE)
		) if $table_type eq 'SCHEMA_DICTIONARY';

	my $type_sql_catalog_name={  XSD_TYPE => 'string',LIMITS => { SIZE => $self->{CATALOG_INSTANCE}->get_name_maxsize}};
					
	return 
		(
			 $self->factory_column(undef,NAME => 'table_name',TYPE => $type_sql_catalog_name,PK_SEQ => 0) 
			,$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,IDX => { NAME => 'idx0_table_dictionary',SEQ => 0})
			,$self->factory_column(undef,NAME => 'schema_code',TYPE => $type_schema_code,IDX => { NAME => 'idx0_table_dictionary',SEQ => 1})
			,$self->factory_column(undef,NAME => 'name',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'internal name') 
			,$self->factory_column(undef,NAME => 'path_name',TYPE	=> MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'URI',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'null is no namespace definition') 
			,$self->factory_column(undef,NAME => 'xsd_seq',TYPE => PK_SEQ_TYPE,COMMENT => 'xsd sequence start')
			,$self->factory_column(undef,NAME => 'min_occurs',TYPE => PK_SEQ_TYPE)
			,$self->factory_column(undef,NAME => 'max_occurs',TYPE => PK_SEQ_TYPE)
			,$self->factory_column(undef,NAME => 'is_internal_ref',TYPE => BOOLEAN_TYPE,COMMENT => 'the table is an occurs of simple type')
			,$self->factory_column(undef,NAME => 'view_name',TYPE => $type_sql_catalog_name,PK_SEQ => 0,COMMENT => 'the view name associated to the table')
			,$self->factory_column(undef,NAME => 'xsd_type',TYPE	=> STRING5_TYPE,ENUM_RESTRICTIONS => { &XSD_TYPE_COMPLEX => 'complex type',&XSD_TYPE_SIMPLE => 'simple_type',&XSD_TYPE_GROUP => 'group_type',&XSD_TYPE_SIMPLE_CONTENT => 'simple content' },COMMENT => 'xsd node type')
			,$self->factory_column(undef,NAME => 'is_mixed',TYPE => BOOLEAN_TYPE,COMMENT => 'the table has mixed attribute set')
		) if $table_type eq 'TABLE_DICTIONARY';

	return 
		(
			$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,PK_SEQ => 0)
			,$self->factory_column(undef,NAME => 'view_name',TYPE => $type_sql_catalog_name,PK_SEQ => 1) 
		) if $table_type eq 'VIEW_DICTIONARY';

	return
		(
			$self->factory_column(undef,NAME => 'table_name',TYPE => $type_sql_catalog_name,PK_SEQ => 0,IDX => { NAME => 'uk0_column_dictionary',SEQ => 0,UNIQUE => 1}) 
			,$self->factory_column(undef,NAME => 'column_seq',TYPE => PK_SEQ_TYPE,COMMENT => 'a column sequence into the table',PK_SEQ => 1)
			,$self->factory_column(undef,NAME => 'column_name',TYPE => $type_sql_catalog_name,IDX => { NAME => 'uk0_column_dictionary',SEQ => 1,UNIQUE => 1}) 
			,$self->factory_column(undef,NAME => 'path_name',TYPE	=> MAXLIMITED_STRING_TYPE) 
			,$self->factory_column(undef,NAME => 'name',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'internal name') 
			,$self->factory_column(undef,NAME => 'xsd_seq',TYPE => PK_SEQ_TYPE,COMMENT => 'xsd sequence into a choice')
			,$self->factory_column(undef,NAME => 'path_name_ref',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'the column reference a table') 
			,$self->factory_column(undef,NAME => 'table_name_ref',TYPE => $type_sql_catalog_name,COMMENT => 'the column reference a table') 
			,$self->factory_column(undef,NAME => 'is_internal_ref',TYPE => BOOLEAN_TYPE,COMMENT => 'the column is an array of simple_type')
			,$self->factory_column(undef,NAME => 'is_group_ref',TYPE => BOOLEAN_TYPE,COMMENT => 'the column reference a group')
			,$self->factory_column(undef,NAME => 'min_occurs',TYPE=> PK_SEQ_TYPE,COMMENT => 'the ref table has this min_occurs or the column has internal reference')
			,$self->factory_column(undef,NAME => 'max_occurs',TYPE => PK_SEQ_TYPE,COMMENT => 'the ref table has this max_occurs or the column has internal reference')
			,$self->factory_column(undef,NAME => 'pk_seq',TYPE => PK_SEQ_TYPE,COMMENT => 'the column is part of the primary key - this is the sequence number')
			,$self->factory_column(undef,NAME => 'sqltype',TYPE => $type_sql_catalog_name)
			,$self->factory_column(undef,NAME => 'type_dumper',TYPE => MAXLIMITED_STRING_TYPE,COMMENT => 'dumper of xsd type')
			,$self->factory_column(undef,NAME => 'is_choice',TYPE => BOOLEAN_TYPE,COMMENT => 'the column is part of a choice')
			,$self->factory_column(undef,NAME => 'is_attribute',TYPE => BOOLEAN_TYPE,COMMENT => 'the column is an attribute')
			,$self->factory_column(undef,NAME => 'is_sys_attributes',TYPE => BOOLEAN_TYPE,COMMENT => 'the column contains  system attributes')
			,$self->factory_column(undef,NAME => 'element_form',TYPE => FIXED1_TYPE,ENUM_RESTRICTIONS => { Q => ' qualified',U => ' unqualified' },COMMENT => 'values: Q(qualified)|(U)nqualified')
			,$self->factory_column(undef,NAME => 'URI',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'if set the colum is a copy from external namespace')
			,$self->factory_column(undef,NAME => 'is_mixed',TYPE => BOOLEAN_TYPE,COMMENT => 'the colum contain a mixed value')
			,$self->factory_column(undef,NAME => 'is_value_col',TYPE => BOOLEAN_TYPE,COMMENT => 'the colum contain the value for a internal reference table')
			,$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,IDX => { NAME => 'idx0_column_dictionary',SEQ => 0})
		) if $table_type eq 'COLUMN_DICTIONARY';
		
	return
		(
			$self->factory_column(undef,NAME => 'parent_table_name',TYPE => $type_sql_catalog_name,PK_SEQ => 0) 
			,$self->factory_column(qw(SEQ),NAME => 'child_sequence',PK_SEQ => 1)
			,$self->factory_column(undef,NAME => 'child_table_name',TYPE => $type_sql_catalog_name) 
			,$self->factory_column(undef, NAME => 'catalog_name',TYPE => $type_catalog_name,IDX => { NAME => 'idx0_reltable_dictionary',SEQ => 0})
		) if $table_type eq 'RELATION_TABLE_DICTIONARY'; 

	return
		(
			$self->factory_column(undef, NAME => 'catalog_name',TYPE => $type_catalog_name,PK_SEQ => 0)
			,$self->factory_column(undef,NAME => 'parent_schema_code',TYPE => $type_schema_code,PK_SEQ => 1) 
			,$self->factory_column(qw(SEQ),NAME => 'child_sequence',PK_SEQ => 2)
			,$self->factory_column(undef,NAME => 'child_schema_code',TYPE => $type_schema_code) 
			,$self->factory_column(undef,NAME => 'parent_namespace',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'child_location',TYPE => MAXLIMITED_STRING_TYPE)
		) if $table_type eq 'RELATION_SCHEMA_DICTIONARY'; 

	return 
		(
			$self->factory_column(qw(ID),COMMENT => 'foreign key to root_table(id)')
			,$self->factory_column(undef,NAME => 'name',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'sysid',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'pubid',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'internal',TYPE => BOOLEAN_TYPE)
		) if $table_type eq 'DOCTYPE_TABLE';
		

	return (
			$self->factory_column(qw(ID),COMMENT => 'foreign key to DOCTYPE_TABLE(ID)')
			,$self->factory_column(qw(SEQ))
			,$self->factory_column(undef,NAME => 'dtd_type',TYPE	=> MAXLIMITED_STRING_TYPE,COMMENT => 'dtd table code') 
	) if $table_type eq 'DTDSEQ_TABLE'; 
	
	
	return 
		(
			$self->factory_column(qw(ID),COMMENT => 'foreign key to DTDSEQ_TABLE(ID)')
			,$self->factory_column(qw(SEQ),COMMENT => 'foreign key to DTDSEQ_TABLE(SEQ)')
			,$self->factory_column(undef,NAME => 'notation',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'base',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'sysid',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'pubid',TYPE => MAXLIMITED_STRING_TYPE)
		) if $table_type eq 'NOTATION_TABLE';
		
	return 
		(
			$self->factory_column(qw(ID),COMMENT => 'foreign key to DTDSEQ_TABLE(ID)')
			,$self->factory_column(qw(SEQ),COMMENT => 'foreign key to DTDSEQ_TABLE(SEQ)')
			,$self->factory_column(undef,NAME => 'name',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'val',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'sysid',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'pubid',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'ndata',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'isparam',TYPE => BOOLEAN_TYPE,COMMENT => 'the column is a parameter entity declaration')
		) if $table_type eq 'ENTITY_TABLE';

	return 
		( 
			$self->factory_column(qw(ID),COMMENT => 'foreign key to DTDSEQ_TABLE(ID)')
			,$self->factory_column(qw(SEQ),COMMENT => 'foreign key to DTDSEQ_TABLE(SEQ)')
			,$self->factory_column(undef,NAME => 'elname',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'attname',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'type',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'default',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'fixed',TYPE => MAXLIMITED_STRING_TYPE)
		) if $table_type eq 'ATTLIST_TABLE';

	return 
		( 
			$self->factory_column(qw(ID),COMMENT => 'foreign key to DTDSEQ_TABLE(ID)')
			,$self->factory_column(qw(SEQ),COMMENT => 'foreign key to DTDSEQ_TABLE(SEQ)')
			,$self->factory_column(undef,NAME => 'name',TYPE => MAXLIMITED_STRING_TYPE)
			,$self->factory_column(undef,NAME => 'model',TYPE => MAXLIMITED_STRING_TYPE)
		) if $table_type eq 'ELEMENT_TABLE';


	my $type_xml_name={ XSD_TYPE => 'string',LIMITS => { SIZE => $self->_get_type_xml_name_size }};

	return (
			$self->factory_column(qw(ID))
			,$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,IDX => { NAME => 'uk0_xml_catalog',SEQ => 0,UNIQUE => 1}) 
			,$self->factory_column(undef,NAME => 'xml_name',TYPE => $type_xml_name,IDX => { NAME => 'uk0_xml_catalog',SEQ => 1,UNIQUE => 1})
	) if $table_type eq 'XML_CATALOG';
	
	return (
			$self->factory_column(qw(ID))
			,$self->factory_column(undef,NAME => 'catalog_name',TYPE => $type_catalog_name,IDX => { NAME => 'idx0_xml_id',SEQ => 0}) 
	) if $table_type eq 'XML_ID';
	
	return (
			$self->factory_column(qw(ID))
			,$self->factory_column(undef,NAME => 'encoding',TYPE => MAXLIMITED_STRING_TYPE)
	) if $table_type eq 'XML_ENCODING';

	affirm { 0 } "$table_type: unknow table type";
	return ();
}

sub get_table_type_groups {
	my ($self,%params)=@_;
	my $t=TABLE_TYPE_GROUPS;
	return wantarray ? @$t : $t;
}

sub get_extra_table_types {
	my ($self,$type,%params)=@_;
	affirm { !defined $type || grep($_ eq $type,get_table_type_groups) }  "1^ param wrong value";
	my $t=defined $type ? TABLE_TYPE_GROUP->{$type} : EXTRA_TABLES;
	return wantarray ? @$t : $t;
}

sub get_extra_table_name {
	my ($self,$table_type,%params)=@_;
	affirm { defined $table_type } "1^ param not set";
	affirm { grep($_ eq $table_type,@{&EXTRA_TABLES}) }  "1^ param wrong value";
	return DEFAULT_EXTRA_TABLE_NAMES->{$table_type};
}

sub _factory_extra_table {
	my ($self,$table_type,$name,%params)=@_;
	my $t=$self->{TABLE_CLASS}->new(
		NAME 		=> $name
		,DEBUG 		=> $self->{DEBUG}
	);
	$t->set_sql_name(%params);  #force the resolve of sql name
	$t->set_constraint_name('pk',%params); #force the resolve of pk constraint
	my @cols=$self->_factory_extra_table_columns($table_type,%params);
	my %cl=();
	for my $col(@cols) { #generate sql names
		$col->set_sql_name(COLUMNNAME_LIST => \%cl);
	}
	$t->add_columns(@cols);
	return $t;
}

sub factory_extra_tables {
	my ($self,%params)=@_;
	if (defined (my $p=$self->{_EXTRA_TABLE_OBJECTS})) {
		return wantarray ? %$p : $p;
	}
	my %list=(
				TABLENAME_LIST		=> {}
				,CONSTRAINT_LIST	=> {}
	);
	my %p=map {
		my $table_type=$_;
		my $k=$table_type.'_NAME';
		my $v=$self->{$k};
		$v=$self->get_extra_table_name($table_type) unless defined $v;
		affirm { defined $v } "$table_type: key not set";
		($table_type,$self->_factory_extra_table($table_type,$v,%params,%list));
	} $self->get_extra_table_types;		
	$self->{_EXTRA_TABLE_OBJECTS}=\%p;
	my $t=$self->{TABLE_CLASS}->new(
		NAME 		=> SEQUENCE_NAME
		,DEBUG 		=> $self->{DEBUG}
	);
	$t->set_sql_name(%params,%list);
	$self->{SEQ_SQL_NAME}=$t->get_sql_name;
	return wantarray ? %p : \%p;
}

sub get_sequence_name {
	my ($self,%params)=@_;
	$self->factory_extra_tables(%params) unless defined $self->{SEQ_SQL_NAME};
	affirm { defined $self->{SEQ_SQL_NAME}} "attribute SEQ_SQL_NAME not set";
	return $self->{SEQ_SQL_NAME};
}

sub get_extra_table {
	my ($self,$type,%params)=@_;
	affirm { defined $type } "1^ param not set";
	my %h= $self->factory_extra_tables(%params);
	my $t=$h{$type};
	affirm { defined $t } "$type: wrong 1^ param value";
	return $t;
}

sub get_translated_type {
	my ($self,$xsd_type,%params)=@_;
	return $self->{LIMITS_INSTANCE}->get_translated_type($xsd_type,%params);
}

sub get_predefined_type {
	my ($self,$code,%params)=@_;
	affirm { defined $code } "1^ param not set";
	my $t=PREDEF_TYPES->{$code};
	affirm { defined $t } "$code: 1^ param value not know";
	return blx::xsdsql::xsd_parser::type::simple->new(%$t,COLUMN => $params{COLUMN});
}

sub get_predefined_column_attrs {
	my ($self,$code,%params)=@_;
	affirm { defined $code } "1^ param not set";
	my $t=PREDEF_COLUMNS->{$code};
	affirm { defined $t } "$code: 1^ param value not know";
	return $t;
}


1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::generic::extra_tables -  class for generate the object  not schema dependent

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::extra tables

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
