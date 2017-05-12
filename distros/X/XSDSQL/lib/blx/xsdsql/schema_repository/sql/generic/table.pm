package blx::xsdsql::schema_repository::sql::generic::table;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use File::Basename;
use Storable;

use blx::xsdsql::ut::ut qw(nvl ev);
use blx::xsdsql::xsd_parser::type::simple;
use base qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::schema_repository::sql::generic::name_generator Exporter);


my $DEFAULT_ROOT_TABLE_NAME:Constant('ROOT');

my  %t=( overload => [ qw (
	XSD_TYPE_SIMPLE
	XSD_TYPE_COMPLEX
	XSD_TYPE_SIMPLE_CONTENT
	XSD_TYPE_GROUP
) ]);

our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=();

my @ATTRIBUTE_KEYS:Constant(qw(
			SQL_NAME 			
			CATALOG_NAME
			SCHEMA_CODE
			NAME
			PATH					
			URI						
			XSD_SEQ 					
			MINOCCURS					
			MAXOCCURS					
			INTERNAL_REFERENCE		
			VIEW_SQL_NAME					
			XSD_TYPE					
			MIXED
		));

use constant {  
	XSD_TYPE_SIMPLE				=>  'ST'
	,XSD_TYPE_COMPLEX			=>  'CT'
	,XSD_TYPE_SIMPLE_CONTENT		=>  'SCT'
	,XSD_TYPE_GROUP				=>  'GT'
};

our %_ATTRS_R:Constant( 
			MINOCCURS			=> sub { return nvl($_[0]->{MINOCCORS},0); }
			,MAXOCCURS  		=> sub { return nvl($_[0]->{MAXOCCURS},1); }
			,NAME   			=> sub { my $p=$_[0]->{PATH}; return defined $p ? basename($p) : $_[0]->{NAME}; }		
			,TYPES 				=> sub { croak "the attribute TYPES  is obsolete\n";}
			,XSD_SEQ			=> sub { return $_[0]->{XSD_SEQ}; }
			,TABLE_IS_TYPE		=> sub { return defined $_[0]->get_attrs_value(qw(XSD_TYPE)) ? 1 : 0; }
			,SIMPLE_TYPE		=> sub { return nvl($_[0]->get_attrs_value(qw(XSD_TYPE))) eq XSD_TYPE_SIMPLE ? 1 : 0; }
			,CHOICE				=> sub { return $_[0]->{CHOICE} ? 1 : 0; }
			,GROUP_TYPE			=> sub { return nvl($_[0]->get_attrs_value(qw(XSD_TYPE))) eq XSD_TYPE_GROUP ? 1 : 0; } 
			,COMPLEX_TYPE		=> sub { return nvl($_[0]->get_attrs_value(qw(XSD_TYPE))) eq XSD_TYPE_COMPLEX ? 1 : 0;}
			,SIMPLE_CONTENT_TYPE	=> sub { return nvl($_[0]->get_attrs_value(qw(XSD_TYPE))) eq XSD_TYPE_SIMPLE_CONTENT ? 1: 0; }
			,SIMPLE_CONTENT		=> sub { croak " SIMPLE_CONTENT: this attribute name is reserved\n"; }
			,INTERNAL_REFERENCE => sub { return $_[0]->{INTERNAL_REFERENCE} ? 1 : 0; }
			,MIXED				=> sub { return $_[0]->{MIXED} ? 1 : 0; }
			,DEEP_LEVEL			=> sub { 
											if (defined (my $xpath=$_[0]->{PATH})) {
												my @a=grep(length($_),split('/',$xpath));
												return scalar(@a);
											}
											undef;
			}
			,ATTRIBUTE_GROUP_TYPE	=> sub { croak " ATTRIBUTE_GROUP_TYPE; this attribute name is reserved\n"; }
			,COLUMNS				=> sub { return $_[0]->{COLUMNS}; } 
			,CHILD_TABLES			=> sub { return $_[0]->{CHILD_TABLES}; }
			,COLUMN_NAMES			=> sub { 
												my @names=(
																@{$_[0]->get_attrs_value(qw(COLUMN_ATTR_NAMES))}
																,@{$_[0]->get_attrs_value(qw(COLUMN_NOATTR_NAMES))}
												);
												#my $p:Constant(\@names);
												my $p=\@names;
												return $p; 
			}
			,COLUMN_ATTR_NAMES		=> sub { my @names=keys %{$_[0]->{COLUMN_NAMES}->{ATTR}}; return \@names; }
			,COLUMN_NOATTR_NAMES		=> sub { my @names=keys %{$_[0]->{COLUMN_NAMES}->{NO_ATTR}}; \@names; }
			,COLUMN_PATHS			=> sub { my @paths=keys %{$_[0]->{COLUMN_PATHS}}; return \@paths; }
			,COLUMN_SQL_NAMES		=> sub { my @names=keys %{$_[0]->{COLUMN_SQL_NAMES}}; return \@names; }
			,SYSATTRS_COL			=> sub { return $_[0]->{SYSATTRS_COL} }
			,PK_COLUMNS				=> sub { my $self=shift; return [grep($_->is_pk,@{$self->get_attrs_value(qw(COLUMNS))})]; }
			,CATALOG_NAME			=> sub { return $_[0]->{CATALOG_NAME} }
			,SCHEMA_NAME			=> sub { return $_[0]->{SCHEMA_NAME} }
			,UK_INDEX_NAMES			=> sub {
												my $self=shift;
												my %idx=map { 
																my $a=$_->get_uk_index_names; 
																map { ($_,undef) } @$a 
															} @{$self->get_attrs_value(qw(COLUMNS))};
												return 	[keys %idx];
			}
			,IX_INDEX_NAMES			=> sub {
												my $self=shift;
												my %idx=map { 
																my $a=$_->get_ix_index_names; 
																map { ($_,undef) } @$a 
															} @{$self->get_attrs_value(qw(COLUMNS))};
												return 	[keys %idx];
			}
			,ROOT_TABLE				=> sub { 	return nvl($_[0]->get_attrs_value(qw(PATH))) eq '/' ? 1 : 0; }
			,UNPATH					=> sub {  	
												my $self=shift;
												return 0 if $self->get_attrs_value(qw(PATH));
												return 1 if $self->get_max_occurs > 1;
												return 0
			}
			,PARENT_PATH			=> sub {  croak "the attribute PARENT_PATH is obsolete\n" }
			,SEQ_SQL_NAME			=> sub {  croak " the attribute SEQ_SQL_NAME is obsolete\n"} 
);

our %_ATTRS_W:Constant(
		COLUMNS					=> sub {  croak " use add_columns method to add columns\n"; }
		,SYSATTRS_COL			=> sub {  croak " use add_columns method to add system attributes column\n"; }
 		,CHILD_TABLES			=> sub {  croak " use add_childs_table to add childs table\n" }
		,TABLE_IS_TYPE			=> sub {  croak " attribute TABLE_IS_TYPE is read_only\n"; }
		,SIMPLE_TYPE			=> sub {  croak " use XSD_TYPE => XSD_TYPE_SIMPLE\n"; }
		,GROUP_TYPE				=> sub {  croak " use XSD_TYPE => XSD_TYPE_GROUP\n"; }
		,COMPLEX_TYPE  			=> sub {  croak " use XSD_TYPE => XSD_TYPE_COMPLEX\n"; }
		,SIMPLE_CONTENT_TYPE		=> sub {  croak " use XSD_TYPE => XSD_TYPE_SIMPLE_CONTENT\n"; }
		,SIMPLE_CONTENT			=> sub {  croak " SIMPLE_CONTENT: this attribute name is reserved\n"; }
		,ATTRIBUTE_GROUP_TYPE	=> sub {  croak " ATTRIBUTE_GROUP_TYPE: this attribute name is reserved\n"; }
		,DEEP_LEVEL				=> sub {  croak " attribute DEEP_LEVEL is read_only\n"; }
		,COLUMN_NAMES			=> sub {  croak " attribute COLUMN_NAMES is read only\n"; }
		,COLUMN_ATTR_NAMES		=> sub {  croak " attribute COLUMN_ATTR_NAMES is read only\n"; }
		,COLUMN_NOATTR_NAMES		=> sub {  croak " attribute COLUMN_NOATTR_NAMES is read only\n"; }
		,COLUMN_PATHS			=> sub {  croak " attribute COLUMN_PATHS is read only\n"; }
		,COLUMN_SQL_NAMES		=> sub {  croak " attribute COLUMN_SQL_NAMES is read only\n"; }
		,XSD_SEQ				=> sub {  croak " the attribute XSD_SEQ must be set only in the constructor\n"; }
		,NAME					=> sub {  croak " the attribute NAME must be set only in the constructor\n"}
		,PATH					=> sub {  croak " the attribute PATH must be set only in the constructor\n"}
		,CATALOG_NAME			=> sub {  croak " the attribute CATALOG_NAME must be set only in the constructor\n"}
		,PK_COLUMNS				=> sub {  croak " the attribute PK_COLUMNS is read only\n"}
		,UK_INDEX_NAMES			=> sub {  croak " the attribute UK_INDEX_NAMES is read only\n"}
		,IX_INDEX_NAMES			=> sub {  croak " the attribute IX_INDEX_NAMES is read only\n"}
		,ROOT_TABLE 			=> sub {  croak " the attribute ROOT_TABLE is read only\n"}
		,UNPATH 				=> sub {  croak " the attribute UNPATH is read only\n"}
		,PARENT_PATH			=> sub {  croak " the attribute PARENT_PATH is obsolete\n" }
		,SEQ_SQL_NAME			=> sub {  croak " the attribute SEQ_SQL_NAME is obsolete\n"} 
		,SQL_CONSTRAINT			=> sub {  croak " use the method set_constraint_name for set the attribute SQL_CONSTRAINT\n"}
		,SQL_NAME				=> sub {  croak " use the method set_sql_name for set the attribute SQL_NAME\n"}
		,MIXED					=> sub {
											my ($self,$value)=@_;
											return 0 unless defined $value;
											return 1 if $value=~/^(1|true)$/;
											return 0 if $value=~/^(0|false)$/;
											croak "$value: invalid value for MIXED attribute";
		}
		,TYPES					=> sub { croak "the attribute TYPES is obsolete\n";}
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _translate_path  {
	my ($self,%params)=@_;
	my $path=defined $self->{PATH} ? $self->{PATH} : $self->{NAME};
	affirm { defined $path } " path or name not set";
	$path=nvl($params{ROOT_TABLE_NAME},$DEFAULT_ROOT_TABLE_NAME) if $path eq '/';
	$path=~s/\//_/g;
	$path=~s/^_//;
	$path=~s/-/_/g;
	$path=$params{VIEW_PREFIX}.'_'.$path if $params{VIEW_PREFIX};
	$path=$params{TABLE_PREFIX}.'_'.$path if $params{TABLE_PREFIX};
	return $path;
}

sub _reduce_sql_name {
	my ($self,$name,$maxsize,%params)=@_;
	my @s=split('_',$name);
	for my $i(0..scalar(@s) - 1) {
		next if $i == 0  && (defined $params{TABLE_PREFIX} || defined $params{VIEW_PREFIX}); # not reduce  the prefix
		$s[$i]=~s/([A-Z])[a-z0-9]+/$1/g;
		my $t=join('_',@s);
		return $t if  length($t) <= $maxsize;
	}
	return substr(join('_',@s),0,$maxsize);
}

sub set_sql_name {
	my ($self,%params)=@_;
	affirm { defined $params{TABLENAME_LIST} } "the param TABLENAME_LIST is not set";
	delete $params{TABLENAME_LIST}->{$self->{SQL_NAME}} if defined $self->{SQL_NAME};
	my $name=$self->_gen_name(
				ROOT_TABLE_NAME	=> $params{ROOT_TABLE_NAME}
				,TABLE_PREFIX	=> $params{TABLE_PREFIX}
				,TY 	=> 't'
				,LIST 	=> $params{TABLENAME_LIST}
				,NAME 	=> $self->get_attrs_value(qw(NAME))
				,PATH	=> $self->get_attrs_value(qw(PATH))
	);
	return $self->{SQL_NAME}=$name;
}


sub set_constraint_name {
	my ($self,$type,%params)=@_;
	affirm { defined $type } "1^ param not set";
	affirm { $type eq 'pk' } "the 1^ param must be 'pk' value";
	affirm { defined $params{TABLENAME_LIST} } "param TABLENAME_LIST not set"; 
	my $pk_suffix=$self->_get_constraint_suffix($type,%params);
	my $table_name=$self->get_sql_name;
	my $maxsize=$self->get_name_maxsize;
	my $pt=substr($table_name,0,$maxsize - length($pk_suffix));

	my $name=$self->_gen_name(
				TY 				=> 't'
				,LIST 			=> $params{TABLENAME_LIST}
				,NAME 			=> $pt
				,MAXSIZE 		=> $maxsize - length($pk_suffix)
				,TABLE_PREFIX	=> $params{TABLE_PREFIX}
	);
	return $self->{SQL_CONSTRAINT}->{$type}=$name.$pk_suffix;
}

sub set_view_sql_name {
	my ($self,%params)=@_;

	my $name=$self->_gen_name(
				TY 				=> 't'
				,LIST 			=> $params{TABLENAME_LIST}
				,VIEW_PREFIX 	=> $params{VIEW_PREFIX}
				,NAME 			=> $self->get_attrs_value(qw(NAME))
				,PATH			=> $self->get_attrs_value(qw(PATH))
	);
	return $self->{VIEW_SQL_NAME}=$name;
}


sub inc_xsd_seq {
	my ($self,%params)=@_;
	++$self->{XSD_SEQ};
	return $self;
}

sub _get_constraint_suffix { 
	my ($self,$type,%params)=@_;
	return '_'.$type;
}
 
sub add_child_tables {
	my ($self,@a)=@_;
	push @{$self->{CHILD_TABLES}},map {
		my $t=$_;
		affirm { ref($t) =~ /::table$/ } ref($t).": not a table ";
		$t;
	} @a;
	return $self;
}

sub delete_child_tables {
	my $self=shift;
	for my $index(@_) {
		affirm { defined $index } "index not set";
		affirm { $index=~/^[+-]{0,1}\d+$/ } "$index: index wrong value"; 
		$self->{CHILD_TABLES}->[$index]=undef;
	}
	my @childs=grep(defined $_,@{$self->{CHILD_TABLES}});
	$self->{CHILD_TABLES}=\@childs;
	return $self;
}


sub add_columns {
	my $self=shift;
	my $cols=$self->get_attrs_value(qw(COLUMNS));
	affirm { ref($cols) eq 'ARRAY' } ref($cols).": not an ARRAY";
	my $params={};
	my @newcols_attrs=();
	my @newcols_notattrs=();
	my $sysattrs_col=$self->get_attrs_value(qw(SYSATTRS_COL));
	my $mixed_sequence=0;
	for my $col(@$cols) {
		if ($col->is_attribute || $col->is_sys_attributes) {
			push @newcols_attrs,$col;
		}
		else {
			push  @newcols_notattrs,$col;
			$mixed_sequence++ if $col->get_attrs_value(qw(MIXED));
		}
	}
	for my $index(0..scalar(@_) - 1) {
		my $col=$_[$index];
		my $ref=ref($col);
		if ($ref=~/::column$/) {
			my $already_exist=0;
			if ($col->is_attribute || $col->is_sys_attributes) {
				if (defined (my $name=$col->get_attrs_value(qw(NAME)))) {
					if (defined $self->{COLUMN_NAMES}->{ATTR}->{$name}) {
						if ($params->{IGNORE_ALREADY_EXIST}) {
							$already_exist=1;
						}
						else {
							croak "$name: column (index $index) already exist with this name\n";
						}
					}
				}
				else {
					croak "$index: column without name";
				}
				if ($col->is_sys_attributes) {
					if (defined $sysattrs_col) {
						if ($params->{IGNORE_ALREADY_EXIST}) {
							$already_exist=1;
						}
						else {
							croak $self->get_sql_name.": multiply sysattrs column not allowed\n";
						}
					}
					$sysattrs_col=$col unless $already_exist;
				}
				push @newcols_attrs,$col unless $already_exist;
			}
			else {
				if (defined (my $path=$col->get_path)) {
					if (defined (my $c=$self->{COLUMN_PATHS}->{$path})) {
						if ($params->{IGNORE_ALREADY_EXIST}) {
							$already_exist=1;
						}
						elsif ($params->{ACCEPT_DUPLICATE_PATH})  {
							$self->_debug(undef,"(W) $path: column already exist with this path  (".$self->get_sql_name,','.nvl($c->get_sql_name).")");
						}
						else {
							croak "$path: column already exist with this path  (".$self->get_sql_name,','.nvl($c->get_sql_name).")\n";
						}
					}
				}
				$col->set_attrs_value(NAME => '$mixed_column'.($mixed_sequence++)) if $col->get_attrs_value(qw(MIXED));
				push @newcols_notattrs,$col unless $already_exist;
			}
		}
		elsif ($ref eq 'HASH') { #is not a colum but parameters
			$params=Storable::dclone($col);
		}
		else {
			affirm { 0 } "$ref: unknow object type\n";
		}
	}

	my @newcols_merge=();
	my $col_seq=0;
	my %h=(
				COLUMN_NAMES		=>{ ATTR => {},NO_ATTR => {} }
				,COLUMN_PATHS		=> {}
				,COLUMN_SQL_NAMES	=> {}
				,SYSATTRS_COL		=> $sysattrs_col
	);
	
	my $set_attrs=sub {
		my ($col,$table_name)=@_;
		$col->set_attrs_value(COLUMN_SEQUENCE => $col_seq++) unless $params->{NO_GENERATE_SEQUENCE};
		affirm { defined $col->get_attrs_value(qw(COLUMN_SEQUENCE)) } "attribute COLUMN_SEQUENCE not set";
		$col->set_attrs_value(TABLE_NAME => $table_name) unless $params->{NO_SET_TABLE_NAME};
		affirm { defined  $col->get_attrs_value(qw(TABLE_NAME)) } " attribute TABLE_NAME not set";
		$col->set_sql_name(COLUMNNAME_LIST => $h{COLUMN_SQL_NAMES}) unless $params->{NO_GENERATE_SQL_NAME}; #resolve sql_name
		affirm { defined $col->get_attrs_value(qw(SQL_NAME)) } "attribute SQL_NAME not set";
		if (defined (my $name=$col->get_name)) {
			if ($col->is_attribute || $col->is_sys_attributes) {
				$h{COLUMN_NAMES}->{ATTR}->{$name}=$col;
			}
			else {
				$h{COLUMN_NAMES}->{NO_ATTR}->{$name}=$col;
			}
		}
		if (defined (my $path=$col->get_path)) {
			$h{COLUMN_PATHS}->{$path}=$col;
		}
		return $col;
	};
	
	
	my $table_name=$self->get_sql_name;
	affirm { $params->{NO_SET_TABLE_NAME} || defined $table_name }  "before add a column please set the table attribute SQL_NAME";
	
	my $tag=nvl($params->{TAG},{ LEVEL => 1});
	for my $col(@newcols_notattrs) {	
		$self->_debug($tag,"add column '",nvl($col->get_path,$col->get_name)
			,"' to table '",nvl($self->get_path,$self->get_name),"'");
		push @newcols_merge,$set_attrs->($col,$table_name);
	}

	for my $col(@newcols_attrs) {
		$self->_debug($tag,"add column '",nvl($col->get_path,$col->get_name)
			,"' to table '",nvl($self->get_path,$self->get_name),"'");
		push @newcols_merge,$set_attrs->($col,$table_name);
	}
	
	$self->reset_columns;
	for my $k(keys %h) {
		$self->{$k}=$h{$k};
	}
	
	$self->{COLUMNS}=\@newcols_merge;
	return $self;
}

sub reset_columns {
	my ($self,%params)=@_;
	my $oldcols=$self->{COLUMNS};
	$self->{COLUMNS}=[];
	$self->{COLUMN_NAMES}={ ATTR => {},NO_ATTR => {} };
	$self->{COLUMN_PATHS}={};
	$self->{COLUMN_SQL_NAMES}={};
	delete $self->{SYSATTRS_COL};
	return wantarray ? @$oldcols : $oldcols;
}

		
sub _new {
	my ($class,%params)=@_;
	my $self=$class->SUPER::_new;
	$self->{CHILD_TABLES}=[];
	my $xsd_seq= delete $params{XSD_SEQ};
	$xsd_seq=0 unless defined $xsd_seq;
	affirm { $xsd_seq =~/^\d+$/ } "$xsd_seq: attribute XSD_SEQ must be absolute number";
	$self->{XSD_SEQ}=$xsd_seq;
	$self->reset_columns;
	for my $k(qw(PATH NAME CATALOG_NAME DEBUG)) { $self->{$k}=delete $params{$k} }
	affirm { defined $self->{PATH} || defined $self->{NAME} } "the attribute PATH or NAME must be set into the constructor";
	$self->_debug(nvl(delete $params{TAG},{ LEVEL => 2})," constructor called for table '",
		nvl($self->get_path,$self->get_name),"'");
	return $self->set_attrs_value(%params);
}

sub new {
	croak "abstract method\n";
}

sub get_columns {
	my ($self,%params)=@_;
	my $a=$self->get_attrs_value(qw(COLUMNS));
	return wantarray ? @$a : $a;
}

	
sub get_child_tables {
	my $self=shift;
	my $v=$self->get_attrs_value(qw(CHILD_TABLES));
	return wantarray ? @$v : $v;
}

sub is_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(TABLE_IS_TYPE));
}

sub is_complex_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(COMPLEX_TYPE));
}

sub is_simple_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SIMPLE_TYPE));
}

sub is_simple_content_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SIMPLE_CONTENT_TYPE));
}


sub is_group_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(GROUP_TYPE));
}

sub is_choice {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(CHOICE));	
}	

sub is_mixed {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MIXED));	
}

sub get_path {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(PATH));
}

sub get_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(NAME));
}
sub get_min_occurs { 
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MINOCCURS));
}

sub get_max_occurs { 
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(MAXOCCURS));
}

sub get_xsd_seq {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(XSD_SEQ));
}

sub get_xsd_type {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(XSD_TYPE));
}

sub get_sql_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SQL_NAME));
}


sub get_view_sql_name {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(VIEW_SQL_NAME));
}


sub get_constraint_name {
	my ($self,$type,%params)=@_;
	return $self->{SQL_CONSTRAINT}->{$type};
}


sub get_deep_level {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(DEEP_LEVEL));
}

sub is_internal_reference {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(INTERNAL_REFERENCE));
}

sub get_pk_columns {
	my ($self,%params)=@_;
	my $cols=$self->get_attrs_value(qw(PK_COLUMNS));	
	return wantarray ? @$cols : $cols;
} 

sub get_catalog_name	{
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(CATALOG_NAME));
}

sub get_schema_code {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SCHEMA_CODE));
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

sub is_root_table {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(ROOT_TABLE));
}

sub get_index_columns {
	my ($self,$index_name,%params)=@_;
	my @cols=();
	for my $col($self->get_columns) {
		if (defined (my $seq=$col->get_index_seq($index_name))) {
			$cols[$seq]=$col;
		}
	}
	return wantarray ? @cols : \@cols;
}

sub is_unpath {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(UNPATH));
}

sub get_URI { 
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(URI));
} 

sub get_sysattrs_column { 
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(SYSATTRS_COL));
}


sub get_dictionary_data {
	my ($self,$dictionary_type,%params)=@_;
	affirm { defined $dictionary_type } "1^ param not set"; 

	if ($dictionary_type eq 'TABLE_DICTIONARY') {
		my %data=(
			table_name 					=> $self->get_sql_name
			,catalog_name				=> undef
			,schema_code				=> undef
			,name						=> $self->get_name
			,path_name					=> $self->get_path
			,URI						=> $self->get_URI
			,xsd_seq 					=> $self->get_xsd_seq
			,min_occurs					=> $self->get_min_occurs
			,max_occurs					=> $self->get_max_occurs
			,is_internal_ref			=> $self->is_internal_reference
			,view_name					=> $self->get_view_sql_name
			,xsd_type					=> $self->get_xsd_type 
			,is_mixed					=> $self->is_mixed
		);

		for my $k(qw(CATALOG_NAME SCHEMA_CODE)) {
			affirm { defined $params{$k} && length($params{$k})} "$k: param not set";
			my $k1=lc($k);
			affirm { exists $data{$k1}  } "$k1: key not found in data"; 
			$data{$k1}=$params{$k};
		}
		return wantarray ? %data : \%data; # if scalar %data;
	}
	
	if ($dictionary_type eq 'RELATION_TABLE_DICTIONARY') {
		my $count=0;
		my $name=$self->get_sql_name;
		affirm { defined $params{CATALOG_NAME} && length($params{CATALOG_NAME})} "CATALOG_NAME: param not set";
		my @data=map {
			{
				parent_table_name	=> $name
				,child_sequence		=> ${count}++
				,child_table_name	=> $_->get_sql_name
				,catalog_name		=> $params{CATALOG_NAME}
			}
		} $self->get_child_tables;
		return wantarray ? @data : \@data;
	}
	
	if ($dictionary_type eq 'COLUMN_DICTIONARY') {
		my $table_name=$self->get_sql_name;
		affirm { defined $params{CATALOG_NAME} && length($params{CATALOG_NAME})} "CATALOG_NAME: param not set";
		my @data=map { 
			my $data=$_->get_dictionary_data('COLUMN_DICTIONARY',%params); 
			$data->{table_name}=$table_name;
			$data 
		} $self->get_columns;
		return wantarray ? @data : \@data;	 
	}

	affirm { 0 } "$dictionary_type: 1^ param invalid value"; 
	return wantarray ? () : [];
}

sub find_column_by_name {
	my ($self,$name,%params)=@_;
	affirm { defined $name } "1^ param not set";
	for my $col($self->get_columns) {
		my $n=$col->get_attrs_value(qw(NAME));
		next unless defined $n;
		return $col if $n eq $name;
	}
	undef;
}

sub find_column_by_mixed_count {
	my ($self,$count,%params)=@_;
	affirm { defined $count } "1^ param not set";
	affirm { $count=~/^\d+/ } "1^ param must be an absolute number";
	my $n=0;
	for my $col($self->get_columns) {
		if ($col->is_mixed) {
			return $col if $n++==$count;
		}
	}
	undef;
}


sub factory_from_dictionary_data {
	my ($data,%params)=@_;
	affirm { ref($data) eq 'ARRAY' } "the 1^ param must be array";
	affirm { defined $params{EXTRA_TABLES} } " the param EXTRA_TABLES must be set";
	affirm { scalar(@$data) == scalar(@ATTRIBUTE_KEYS) }  'the attributes number is not equal to keys number '
		.'data => '.scalar(@$data).' attributes => '.scalar(@ATTRIBUTE_KEYS);
	my %data=map {  ($ATTRIBUTE_KEYS[$_],$data->[$_])  } (0..scalar(@$data) - 1);
	my ($sqlname,$view_name) = map { delete $data{$_}; } qw(SQL_NAME VIEW_SQL_NAME);
	my $table_class=$params{EXTRA_TABLES}->get_attrs_value(qw(TABLE_CLASS));
	my $t=$table_class->new(%data);
	$t->{SQL_NAME}=$sqlname;
	$t->{VIEW_SQL_NAME}=$view_name;
	$t;
}

sub clone {
	my ($self,%params)=@_;
	my $t=$self->_clone_from_attributes(\@ATTRIBUTE_KEYS);
	$t->{CHILD_TABLES}=[];
	unless ($params{SET_SQLNAME}) {
		for my $k(qw(SQL_NAME VIEW_SQL_NAME SQL_CONSTRAINT)) {
			delete $t->{$k};
		}
	}
	$t->reset_columns;
	unless ($params{NO_COLUMNS}) {
		$t->add_columns({
							IGNORE_ALREADY_EXIST		=> 1
							,ACCEPT_DUPLICATE_PATH    	=> 1 
							,NO_GENERATE_SEQUENCE    	=> 1 
							,NO_SET_TABLE_NAME		 	=> 1
							,NO_GENERATE_SQL_NAME		=> 1
						}
						,map { $_->clone } $self->get_columns
		);
	}
	$t;
}

1;

__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::generic::table -  a generic table class

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::table

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions


new - constructor -

        the construct is private, use the new constructor of a child class


_new  - contructor

    PARAMS:
        CATALOG_NAME	         - catalog of table
        SCHEMA_CODE          - schema code of table
        XSD_SEQ              - a XSD_SEQ start number
        XSD_TYPE             - xsd type - see XSD_TYPE_* constants
        CHOICE               - the table is associated to a choice
        MINOCCURS            - the table as a minoccurs
        MAXOCCURS            - the table as a maxoccurs
        PATH                 - a node path name
        TYPE                 - an internal node type
        NAME                 - a node name
        DEEP_LEVEL           - a deep level - the root has level 0
        INTERNAL_REFERENCE   - if true the table is an occurs of simple types
        MIXED                - is true if  the xsd:mixed attribute is true
        URI                  - a node URI
        VIEW_SQL_NAME        - the corresponding view name
        DEBUG                - set the debug mode
        TAG                  - set the caller for debug

get_columns - return an array of columns object


get_child_tables  - return an array of child tables


get_sql_name  - return the sql name


get_constraint_name  - return a constraint name

    the first argument must be the constant 'pk' (primary key)


get_pk_columns - return the primary key columns


is_type    - return true if the table is associated to a xsd type


is_simple_type - return true if the table is associated to a xsd simple type


is_complex_type - return true if the table is associated to a xsd complex type


is_simple_content_type - return true if the table is associated to a xsd simple content type


is_group_type    - return true if the table is associated to a xsd group type


is_choice - return true if the table is associated to a xsd choice


is_internal_reference - return  true if the the table is an occurs of simple types


is_unpath - return true if the table is not associated to a path


get_xsd_seq - return the  start xsd sequence


get_xsd_type - return the xsd type og the object - see the constants XSD_TYPE_*


get_min_occurs - return the min occurs of the table


get_max_occurs - return the max occurs of the table


get_path    - return the xml path associated with table


get_name    - return the table name 


get_dictionary_data - return an hash of dictionary column name => value for the insert into dictionary

    the first argument must be:
        TABLE_DICTIONARY - return data for table dictionary
        RELATION_DICTIONARY - return data for relation dictionary
        COLUMN_DICTIONARY - return data for column dictionary


get_deep_level - return the deep level - the root has level 0


get_parent_path - return the parent path if is_unpath is true


inc_xsd_seq - increment by 1 the value of attribute XSD_SEQ


add_columns

    the arguments are a flag or columns
        value for flag is
                IGNORE_ALREADY_EXIST         - not add a column if the name is already exist in table otherwise is an error
                ACCEPT_DUPLICATE_PATH        - add the column if the path is already registered in table otherwise is an error
                NO_GENERATE_SEQUENCE        - not set the column sequence in columns
                NO_SET_TABLE_NAME             - not set the table name in columns
                NO_GENERATE_SQL_NAME        - not geneate colum sql name


reset_columns - reset the columns of the  table


add_child_tables

   the arguments are tables


delete_child_tables - delete child tables

    the arguments are the positions index of the child tables


find_column_by_name -  find a column

    the 1^ param is the name (not the sql name) of the column

    if the column exist return a column object otherwise undef


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx::xsdsql::schema_repository::sql::generic::catalog, it's the base class

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::xsd_parser
for parse a xsd file (schema file)


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
