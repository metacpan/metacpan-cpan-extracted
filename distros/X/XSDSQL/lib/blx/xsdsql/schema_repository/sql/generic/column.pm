package blx::xsdsql::schema_repository::sql::generic::column;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use blx::xsdsql::ut::ut qw(nvl ev);
use File::Basename;
use Storable;

use base(qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::schema_repository::sql::generic::name_generator));


my @ATTRIBUTE_KEYS:Constant(qw(
		TABLE_NAME
		COLUMN_SEQUENCE  	
		SQL_NAME		
		PATH
		NAME
		XSD_SEQ	
		PATH_REFERENCE
		TABLE_REFERENCE		
		INTERNAL_REFERENCE	
		GROUP_REF		
		MINOCCURS	
		MAXOCCURS
		PK_SEQ
		SQL_TYPE
		TYPE_DUMPER
		CHOICE			
		ATTRIBUTE		
		SYS_ATTRIBUTES	
		ELEMENT_FORM		
		URI				
		MIXED
		VALUE_COL
		CATALOG_NAME
));


our %_ATTRS_R=( 
			NAME   				=> sub { 
											my $self=$_[0]; 	
											my ($n,$p)=map { $self->{$_} }(qw(NAME PATH)); 
											return $self->{ATTRIBUTE} || !defined  $p ? $n : basename($p); 
			} 			
			,MAXOCCURS 			=> sub {	my $m=$_[0]->{MAXOCCURS}; return nvl($m,1); }
			,MINOCCURS 			=> sub {	my $m=$_[0]->{MINOCCURS}; return nvl($m,1); }
			,INTERNAL_REFERENCE => sub { 	return $_[0]->{INTERNAL_REFERENCE} ? 1 : 0; }
			,SQL_TYPE  			=> sub {	return $_[0]->{SQL_TYPE} }  
			,PK					=> sub { 	return defined $_[0]->{PK_SEQ}  ? 1 : 0; }
			,GROUP_REF			=> sub {	return $_[0]->{GROUP_REF} ? 1 : 0; }
			,CHOICE				=> sub {	return $_[0]->{CHOICE} ? 1 : 0; }
			,ATTRIBUTE			=> sub {	return $_[0]->{ATTRIBUTE} ? 1 : 0; }
			,SYS_ATTRIBUTES		=> sub {	return $_[0]->{SYS_ATTRIBUTES} ? 1 : 0; }
			,IDX				=> sub {    croak "the attribute IDX is write only\n"}
			,UK_INDEX_NAMES		=> sub {    
											my $self=$_[0];
											my @a=map {$self->{IDX}->{$_}->{UNIQUE} ? ($_) : () } 
												grep(defined $self->{IDX}->{$_}->{SEQ},keys %{$self->{IDX}});
											my $a:Constant(\@a);
											return $a;
			}
			,IX_INDEX_NAMES		=> sub {    
											my $self=$_[0];
											my @a=map {$self->{IDX}->{$_}->{UNIQUE} ? () : ($_) }
												grep(defined $self->{IDX}->{$_}->{SEQ},keys %{$self->{IDX}});
											my $a:Constant(\@a);
											return $a;
			}
			,INDEX_SEQUENCE		=> sub { croak "the attribute INDEX_SEQUENCE is reserved"}
			,MIXED				=> sub { return $_[0]->{MIXED} ? 1 : 0; }
			,VALUE_COL			=> sub { return $_[0]->{VALUE_COL} ? 1 : 0 }
);

our %_ATTRS_W=(
	SQL_TYPE  => sub {  croak "use the the method set_sql_type for set the attribute SQL_TYPE\n" }
	,TYPE     => sub {
						my ($self,$type)=@_;
						affirm { !defined $type || ref($type)=~/^blx::xsdsql::xsd_parser::type::/ } 
							ref($type).": the 1^ param must not set or a object of class blx::xsdsql::xsd_parser::type::*"; 
						delete $self->{SQL_TYPE};
						delete $self->{TYPE_DUMPER};
						return $type;
	}
	,SQL_NAME	=> sub { croak "use the method set_sql_name for set the attribute SQL_NAME\n" }
	,IDX		=> sub {
						my ($self,$value)=@_;
						my $v=ref($value) eq 'HASH' 
							? [Storable::dclone($value)]
							: ref($value) eq 'ARRAY' 
								? Storable::dclone($value)
								: undef
						;
						affirm { ref($v) eq 'ARRAY' } "the value of the attribute IDX must an HASH { NAME SEQ UNIQUE } or ARRAY of HASH";
						my $out={};
						for my $h(@$v) {
							affirm { ref($h) eq 'HASH' } "the value of the attribute IDX must an HASH { NAME SEQ UNIQUE } or ARRAY of HASH";
							affirm { defined $h->{NAME} } "the key NAME must be set";
							affirm { defined $h->{SEQ} } "the key SEQ must be set";
							affirm { $h->{SEQ}=~/^\d+$/ } " the key SEQ must be an absolute number";
							affirm { !exists $out->{$h->{NAME}}} $h->{NAME}.": duplicate key name";
							$out->{$h->{NAME}}={ SEQ => $h->{SEQ},UNIQUE => ($h->{UNIQUE} ? 1 : 0)};
						}
						my $o:Constant($out);
						return $o;
	}
	,UK_INDEX_NAMES	=> sub { croak "the attribute UK_INDEX_MAMES is read only" }
	,IX_INDEX_NAMES	=> sub { croak "the attribute IX_INDEX_MAMES is read only"}
	,INDEX_SEQUENCE	=> sub { croak "the attribute INDEX_SEQUENCE is reserved"}
	,MIXED			=> sub {
								my ($self,$value)=@_;
								return 0 unless defined $value;
								return 1 if $value=~/^(1|true)$/;
								return 0 if $value=~/^(0|false)$/;
								croak "$value: invalid value for MIXED attribute";
	}
	,PK				=> sub { croak "the attribute PK is read only" }
	,TYPE_DUMPER	=> sub { croak "the attribute TYPE_DUMPER is read only"}
	,ELEMENT_FORM	=> sub {
								my ($self,$value)=@_;
								return unless defined $value;
								return 'Q' if $value eq 'qualified' || $value eq 'Q';
								return 'U' if $value eq 'unqualified' || $value eq 'U';
								croak "$value: invalid value for ELEMENT_FORM attribute";
	}
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _new {
	my ($class,%params)=@_;
	$params{XSD_SEQ}=0 unless defined $params{XSD_SEQ}; 
	my $self=$class->SUPER::_new;
	return $self->set_attrs_value(%params);
}

sub new {
	croak "abstract method\n";
}

sub set_sql_name {
	my ($self,%params)=@_;
	affirm { defined $params{COLUMNNAME_LIST} } "the param COLUMNNAME_LIST is not set";
	delete $params{COLUMNNAME_LIST}->{uc($self->{SQL_NAME})} if defined $self->{SQL_NAME};
	my $name=$self->_gen_name(
				TY 		=> 'c'
				,LIST 	=> $params{COLUMNNAME_LIST}
				,NAME 	=> $self->get_attrs_value(qw(NAME))
				,PATH	=> $self->get_attrs_value(qw(PATH))
	);
	return $self->{SQL_NAME}=$name;
}


sub _translate_path  {
	my ($self,%params)=@_;	
	my $path=defined $params{NAME} ? $params{NAME} : $params{PATH};
	affirm { defined $path } "attribute NAME or PATH not set";
	$path=basename($path);
	$path=~s/^_//;
	$path=~s/^\$//;
	$path=~s/-/_/g;
	$path=~s/:/_/g;
	return $path;
}

sub _reduce_sql_name {
	my ($self,$name,$maxsize,%params)=@_;
	my @s=split('_',$name);
	if (scalar(@s) > 1) {
		for my $s(@s) {
			$s=~s/([A-Z])[a-z0-9]+/$1/g;
			my $t=join('_',@s);
			return $t if  length($t) <= $maxsize;
		}
	}
	return substr(join('_',@s),0,$maxsize);
}

sub _serialize {
	my ($self,$h,%params)=@_;
	affirm { ref($h) eq 'HASH' } '1^ param is not HASH';
	my %h=%$h;
	if (defined (my $excl_keys=$params{EXCLUDE_KEYS})) {
		for my $k(@$excl_keys) {
			delete $h{$k};
		}
	}	
	my $d=Data::Dumper->new([\%h]);
	$d->Indent(0);
	$d->Varname('x');
	$d->Sortkeys(1);
	my $v=$d->Dump;
	$v=~s/^\s*\$x\d+\s+=\s+//;
	$v=~s/;\s*$//;
	$v;
}
sub set_sql_type {
	my ($self,%params)=@_;
	return $self->{SQL_TYPE} if defined $self->{SQL_TYPE};
	affirm { defined $self->{TYPE} } "for set the SQL_TYPE the attribute TYPE must be set";
	affirm { defined $params{EXTRA_TABLES} } " for set SQL_TYPE the param EXTRA_TABLES must be set"; 

	if (ref($self->{TYPE})=~/::type::simple$/) {
		my $ty=$self->{TYPE}->get_sql_type;
		my %limits=map { defined $ty->{$_} ? ($_,$ty->{$_}) : ()} qw(SIZE INT DEC FIXSIZE);
		$self->{SQL_TYPE}=$params{EXTRA_TABLES}->get_translated_type($ty->{SQL_TYPE},LIMITS => \%limits,COLUMN => $self);
		my $type_dumper=Storable::dclone($ty);
		delete $type_dumper->{SQL_TYPE};
		$self->{TYPE_DUMPER}=$type_dumper;		
	}
	else {
		affirm { 0 } "'".ref($self->{TYPE})."': unknow type for conversion";
	}
	affirm { defined $self->{SQL_TYPE} } "SQL_TYPE not set";
	
	return $self->{SQL_TYPE};	
}
	
sub get_sql_type {
	my ($self,%params)=@_;
	return defined $self->{SQL_TYPE} ? $self->{SQL_TYPE} : $self->set_sql_type(%params);
}

sub get_column_sequence {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(COLUMN_SEQUENCE));
}

sub get_name { 	
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(NAME));
}

sub get_sql_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SQL_NAME));
}

sub is_internal_reference {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(INTERNAL_REFERENCE));
}

sub is_group_reference {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(GROUP_REF));	
}

sub is_choice {
	my ($self,%params)=@_;
	return  $self->get_attrs_value(qw(CHOICE));
}

sub is_attribute {
	my ($self,%params)=@_;
	return  $self->get_attrs_value(qw(ATTRIBUTE));
}

sub is_sys_attributes {
	my ($self,%params)=@_;
	return  $self->get_attrs_value(qw(SYS_ATTRIBUTES));
}

sub is_mixed {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MIXED));
}

sub is_value_col {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(VALUE_COL));
}

sub get_min_occurs {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MINOCCURS));
}

sub get_max_occurs {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MAXOCCURS));
}

sub is_pk {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(PK));
}

sub get_pk_seq {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(PK_SEQ));
}

sub get_xsd_seq {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(XSD_SEQ));
}

sub get_path {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(PATH));
}

sub get_path_reference {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(PATH_REFERENCE));
}

sub get_table_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(TABLE_NAME));
}

sub get_full_name {
	my ($self,%params)=@_;
	return $self->get_table_name.'.'.$self->get_sql_name;
}

sub get_table_reference {
	my ($self,%params)=@_;
	$self->get_attrs_value(qw(TABLE_REFERENCE));	
}


sub get_element_form {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(ELEMENT_FORM));
}

sub get_URI {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(URI));
}

sub get_catalog_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(CATALOG_NAME));
}
	
sub get_uk_index_names {
	my ($self,%params)=@_;
	my $a=$self->get_attrs_value(qw(UK_INDEX_NAMES));
	return wantarray ? @$a : $a;
}

sub get_ix_index_names {
	my ($self,%params)=@_;
	my $a=$self->get_attrs_value(qw(IX_INDEX_NAMES));
	return wantarray ? @$a : $a;
}

sub get_index_seq {
	my ($self,$index_name,%params)=@_;
	return unless exists $self->{IDX}->{$index_name}; 
	return $self->{IDX}->{$index_name}->{SEQ};
}

sub get_attrs_key {
	my ($self,%params)=@_;
	return wantarray ? @ATTRIBUTE_KEYS : \@ATTRIBUTE_KEYS;
}

sub get_dictionary_data {
	my ($self,$dictionary_type,%params)=@_;
	affirm { defined $dictionary_type } "1^ param not set";
	if ($dictionary_type eq 'COLUMN_DICTIONARY') {
		my $table_ref=$self->get_table_reference;
		my $path_ref=$self->get_path_reference;
		$path_ref=$path_ref->get_sql_name if ref($path_ref) ne '';
		affirm { defined $params{CATALOG_NAME} && length($params{CATALOG_NAME})} "CATALOG_NAME: param not set";
		affirm { defined $self->{SQL_TYPE} } 
				'attribute SQL_TYPE not set for column '.$self->get_name.' of table '.$self->get_table_name; 
		my %data=(
			table_name 			=> $self->get_table_name
			,column_seq  		=> $self->get_column_sequence
			,column_name		=> $self->get_sql_name
			,path_name			=> $self->get_attrs_value(qw(PATH))
			,name				=> $self->{NAME}
			,xsd_seq			=> $self->get_xsd_seq
			,path_name_ref		=> $path_ref
			,table_name_ref		=> ($table_ref ? $table_ref->get_sql_name : undef)
			,is_internal_ref	=> $self->is_internal_reference
			,is_group_ref		=> $self->is_group_reference
			,min_occurs			=> $self->get_min_occurs
			,max_occurs			=> $self->get_max_occurs
			,pk_seq				=> $self->get_pk_seq
			,sqltype			=> $self->get_attrs_value(qw(SQL_TYPE)) 
			,type_dumper		=> $self->_serialize($self->get_attrs_value(qw(TYPE_DUMPER))) 
			,is_choice			=> $self->is_choice
			,is_attribute		=> $self->is_attribute
			,is_sys_attributes =>  $self->is_sys_attributes
			,element_form		=> $self->get_element_form
			,URI				=> $self->get_URI
			,is_mixed			=> $self->is_mixed 
			,is_value_col		=> $self->is_value_col
			,catalog_name		=> $params{CATALOG_NAME}
		);			
		return wantarray ? %data : \%data;
	}
	affirm { 0 } "$dictionary_type: invalid value for dictionary_type";
	return wantarray ? () : {};
}

sub factory_from_dictionary_data {
	my ($data,%params)=@_;
	affirm { ref($data) eq 'ARRAY' } "the 1^ param must be array";
	affirm { defined $params{EXTRA_TABLES} } " the param EXTRA_TABLES must be set";
	affirm { scalar(@$data) == scalar(@ATTRIBUTE_KEYS) }  "the attributes number is not equal to keys number"; 
	my %data=map {  ($ATTRIBUTE_KEYS[$_],$data->[$_])  } (0..scalar(@$data) - 1);
	my ($sqlname,$sqltype,$type_dumper) = map { delete $data{$_}; } qw(SQL_NAME SQL_TYPE TYPE_DUMPER);
	my $column_class=$params{EXTRA_TABLES}->get_attrs_value(qw(COLUMN_CLASS));
	my $c=$column_class->new(%data);
	$c->{SQL_NAME}=$sqlname;
	$c->{SQL_TYPE}=$sqltype;
	$c->{TYPE_DUMPER}=ev($type_dumper);
	return $c;
}

sub clone {
	my ($self,%params)=@_;
	my $attrs=$self->get_attrs_key;
	if (defined (my $x=$params{EXCLUDE_ATTR_KEYS})) {
		affirm { ref($x) eq 'ARRAY' } ref($x).": value of param EXCLUDE_ATTR_KEYS must be ARRAY";
		my %k=map { ($_,undef) } @$x;
		$attrs=[grep(!exists $k{$_},@$attrs)];
	}
	return $self->_clone_from_attributes($attrs);
}

1;

__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::generic::column -  a generic colum class

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::column

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
        COLUMN_SEQUENCE - a sequence number into the table - the first column has sequence 0
        XSD_SEQ  - a sequence number into xsd
        MIN_OCCURS - default 1
        MAX_OCCURS - default 1
        NAME  - a basename of xml node
        PATH     - a path name of xml xml node
        PATH_REFERENCE - the referenced by column
        TABLE_REFERENCE    - the table referenced by column
        INTERNAL_REFERENCE - true if the column is an array of simple types
        PK_SEQ  - sequence position number into the primary key
        GROUP_REF - true if the column reference a group
        TABLE_NAME - the table name of the column
        CHOICE    - if true the column is part of a choice
        ATTRIBUTE    - if true the column  is an attribute
        SYS_ATTRIBUTES - if true the column contain system attributes
        ELEMENT_FORM - the value of form attribute (Q)ualified|(U)nqualified

set_attrs_value   - set a value of attributes

    the arguments are a pairs NAME => VALUE
    the method return a self object


get_attrs_value  - return a list  of attributes values

    the arguments are a list of attributes name


get_column_sequence - return the sequence into the table - the first column has sequence 0


get_sql_type  - return the sql type of the column


get_sql_name  - return the  sql name of the column


get_min_occurs - return the value of the minoccurs into the xsd schema


get_max_occurs - return the value of the maxoccurs into the xsd schema


is_internal_reference  - return true if the column is an array of simple types


is_group_reference - return true if the column reference a xsd group


is_choice  - return true if the column is a part of a choice


is_attribute - return true if the column is an attribute


is_sys_attributes - return true if then column contain system attributes in the form name="value"[,..]


get_path - return the node path name


get_path_reference - return the path referenced


get_table_reference - return the table referenced


get_table_name - return the table name of the column


is_pk  - return true if the column is part of the primary key


get_pk_seq - return the sequence into the primary key


get_xsd_seq - return a sequence number into a choice


get_element_form - return the value of form attribute (Q)ualified|(U)nqualified


get_URI  - return the external URI referenced


set_sql_name - ser the sql name of the column

    params:
            COLUMNNAME_LIST => hash for store a uniq names

set_sql_type  - set the sql type of the column

    params:
            EXTRA_TABLES = an object of type  blx::xsdsql::schema_repository::sql::generic::extra_tables



=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx::xsdsql::schema_repository::sql::generic::catalog, it's the base class
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
