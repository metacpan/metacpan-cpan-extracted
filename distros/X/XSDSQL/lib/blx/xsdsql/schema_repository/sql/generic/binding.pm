package blx::xsdsql::schema_repository::sql::generic::binding;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl ev);
use base(qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::ios::debuglogger Exporter));


my  %t=( overload => [ qw (
	BINDING_TYPE_INSERT	
	BINDING_TYPE_INSERT_GENERIC
	BINDING_TYPE_DELETE
	BINDING_TYPE_DELETE_GENERIC
	BINDING_TYPE_UPDATE
	BINDING_TYPE_QUERY_ROW_GENERIC
) ]);

our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=qw( );

my @ATTRIBUTE_KEYS:Constant(qw(
			DB_CONN 
			SEQUENCE_NAME 
			DEBUG 
			EXECUTE_OBJECTS_PREFIX 
			EXECUTE_OBJECTS_SUFFIX
			OUTPUT_NAMESPACE
			DB_NAMESPACE
		)
);

use constant {
		BINDING_TYPE_INSERT   				=>  'i'
		,BINDING_TYPE_INSERT_GENERIC			=>  'ig'
		,BINDING_TYPE_DELETE   				=>  'd'
		,BINDING_TYPE_DELETE_GENERIC			=>  'dg'
		,BINDING_TYPE_UPDATE  				=>  'u'
		,BINDING_TYPE_QUERY_ROW_GENERIC   	=>  'qrg'
};

our %_ATTRS_R:Constant(());


our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } 
			grep ($_ ne 'SEQUENCE_NAME',@ATTRIBUTE_KEYS)
);

sub _get_attrs_r {  return \%_ATTRS_R; }
sub _get_attrs_w {  return \%_ATTRS_W; }


sub _new {
	my ($class,%params)=@_;
	affirm {  $class ne __PACKAGE__ } "the constructor of ".__PACKAGE__." must be inherited";
	
	for my $k(qw(DB_CONN OUTPUT_NAMESPACE DB_NAMESPACE)) {
		affirm { defined $params{$k} } "param  $k not set"; 
	}
	
	my $self=bless {},$class;
	for my $k(@ATTRIBUTE_KEYS) {
		$self->{$k}=delete $params{$k};
	}
	$self->set_attrs_value(%params);
}

sub get_connection {  $_[0]->get_attrs_value(qw(DB_CONN)) }

sub get_sth { $_[0]->{STH}; }

{
	my @NOT_CLONABLE:Constant( '^DB_CONN$','^PREPARE_','^STH$' );
	sub get_clone {
		my ($self,%params)=@_;
		my %not_cl=();
		for my $k(keys %$self) { #delete the keys not clonable
			if (ref($self->{$k}) eq 'CODE') {
				$not_cl{$k}=delete $self->{$k};
				next;
			}
			next unless defined $self->{$k};
			next unless grep($k=~/$_/,@NOT_CLONABLE);
			$not_cl{$k}=delete $self->{$k};
		}
		local $@;
		my $clone=eval{ Storable::dclone($self); };
		croak $@ if $@;
		for my $k(keys %not_cl) {
			$self->{$k}=delete $not_cl{$k};
		}
		$clone->{DB_CONN}=$self->{DB_CONN} if defined $self->{DB_CONN}; # the connection is shared
		return $clone;
	}
}

sub get_next_sequence {
	my ($self,%params)=@_;
	affirm { defined $self->{SEQUENCE_NAME} } "the attribute SEQUENCE_NAME is not set";
	local $self->{DB_CONN}->{RaiseError}=1;
	$self->_get_next_sequence(%params);
}

sub _get_next_sequence {
	my ($self,%params)=@_;
	croak "abstract method ";
}	

sub _create_prepare {
	my ($self,$sql,%params)=@_;
	my $tag=delete $params{TAG};
	affirm { !(defined $self->{STH}) } "$sql: STH already prepared";
	my $prepattr=delete $params{PREPARE_ATTRS};
	affirm { !defined $prepattr || ref($prepattr) eq 'HASH' } "param PREPARE_ATTRS must be an HASH if is set";
	$self->_debug($tag,'PREPARE',$sql);
	local $self->{DB_CONN}->{RaiseError}=1;
	$self->{STH}=$self->{DB_CONN}->prepare($sql,$prepattr);
	affirm { defined $self->{STH} } "attribute STH not set";
	$self->{SQL}=$sql;
	return $self;
}

sub _manip_value { #manip values from input data
	my ($self,$col,$value,%params)=@_;
	croak "abstract method";
}

sub bind_column {
	my ($self,$col,$value,%params)=@_;
	affirm { defined $col } "1^ param not set";
	affirm { ref($col) =~/::column$/ } "1^ param is not a column class";
	affirm { $self->get_binding_table->get_sql_name eq  $col->get_table_name } " wrong binding - the bind is for table ".$self->get_binding_table->get_sql_name;
	affirm { defined $col->get_column_sequence } $col->get_full_name.": COLUMN_SEQUENCE attr non set";
	affirm { ref($value) eq '' } "2^ param must be a scalar";

	my $name=$col->get_sql_name;	
	my ($pk_seq,$col_seq)=($col->get_pk_seq,nvl($params{COL_SEQ},$col->get_column_sequence));
	if ($params{APPEND}) {
		my $h=$self->{BINDING_VALUES}->[$col_seq];
		my $currval=defined $h ? $h->{VALUE} : '';
		$currval='' unless defined $currval;
		$currval.=$params{SEP} if defined $params{SEP} && length($currval);
		$value=$currval.$value;
	}
	$self->_debug($params{TAG},'BIND',$col->get_full_name,"with value '".nvl($value,'<undef>')."'"); 
	local $self->{DB_CONN}->{RaiseError}=1;          
	$self->{STH}->bind_param($col_seq + 1,$self->_manip_value($col,$value));
	$self->{BINDING_VALUES}->[$col_seq]={ COL => $col,VALUE => $value };
	$self->{EXECUTE_PENDING}=1;
	return $self;
}

sub _get_column_value_init {
	my ($self,$table,$col,%params)=@_;
	my $pk_seq=$col->get_attrs_value(qw(PK_SEQ));
	return unless defined $pk_seq;
	if ($pk_seq == 0) {
		return defined $params{PK_ID_VALUE} ? $params{PK_ID_VALUE} : $self->get_next_sequence(%params);  
	}
	return  0 if $pk_seq == 1;
	return;
}

sub _get_insert_sql {
	my ($self,$table,%params)=@_;
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	return "insert into ".$p.$table->get_sql_name.$s
			." ( ".join(',',map { $_->get_sql_name } $table->get_columns)
			. ") values ( ".join(',',map { '?' } $table->get_columns)
			. ")"
}

sub insert_binding  {
	my ($self,$table,%params)=@_;
	affirm { !$self->is_execute_pending || $params{NO_PENDING_CHECK} } "execute method pending";
	unless (defined $self->{BINDING_TYPE}) {
		affirm { defined $table } "1^ param not set";
		my $sql=$self->_get_insert_sql($table,%params);
		$self->_create_prepare($sql,%params);
		$self->{BINDING_TYPE}=BINDING_TYPE_INSERT;
		$self->{BINDING_TABLE}=$table;
		$self->{BINDING_VALUES}=[];
	}
	else {
		$table=$self->{BINDING_TABLE} unless defined $table;
		affirm { $self->{BINDING_TYPE} eq BINDING_TYPE_INSERT } "binding type is not BINDING_TYPE_INSERT";
		affirm { $self->{BINDING_TABLE}->get_sql_name eq $table->get_sql_name } "incompatible binding table";
	}
	unless ($self->is_execute_pending) {
		for my $col($table->get_columns) {
			next if $params{NO_PK} && $col->is_pk;
			my $value=$self->_get_column_value_init($table,$col,%params);
			$self->bind_column($col,$value,%params);
		}
		$self->{EXECUTE_PENDING}=1;
	}
	return $self;
}

sub _get_delete_sql {
	my ($self,$table,%params)=@_;
	my @cols=(($table->get_pk_columns)[0]);
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	return "delete from "
			.$p
			.$table->get_sql_name
			.$s
			." where "
			.join(' and ',map { $_->get_sql_name.'=?'} @cols);
}

sub delete_rows_for_id  {
	my ($self,$table,$id,%params)=@_;
	affirm { !$self->is_execute_pending || $params{NO_PENDING_CHECK} } "execute method pending";
	unless (defined $self->{BINDING_TYPE}) {
		affirm { defined $table } "1^ param not set"; 
		my $sql=$self->_get_delete_sql($table,%params);
		$self->_create_prepare($sql,%params);
		$self->{BINDING_TYPE}=BINDING_TYPE_DELETE;
		$self->{BINDING_TABLE}=$table;
		$self->{BINDING_VALUES}=[];
	}
	else {
		$table=$self->{BINDING_TABLE} unless defined $table;
		affirm { $self->{BINDING_TYPE} eq BINDING_TYPE_DELETE } "binding type is not BINDING_TYPE_DELETE";
		affirm { $self->{BINDING_TABLE}->get_sql_name eq $table->get_sql_name } "incompatible binding table";
	}
	if (defined $id) {
		my $col=($table->get_pk_columns)[0];
		$self->bind_column($col,$id,COL_SEQ => 0,TAG => $params{TAG});
		$self->{EXECUTE_PENDING}=1;
		my $n=$self->execute(%params);
		$n = 0 if $n eq '0E0';
		return $n;
	}
	else {
		return;
	}	
}
sub _get_delete_generic_sql {
	my ($self,$table,$cols,%params)=@_;
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	return "delete from "
			.$p
			.$table->get_sql_name
			.$s
			." where "
			.join(' and ',map {
								my $col=$_;
								affirm { ref($col) =~/::column$/ } ref($col).": is not a column object";
								$col->get_sql_name.'=?'
						} @$cols
			);
}

sub delete_rows_from_generic  {
	my ($self,$table,$values,%params)=@_;
	affirm { ref($table) =~/::table$/ } "1^ param must be an object of  table class";
	affirm { ref($values) eq 'ARRAY' || !defined $values } "2 param must be an ARRAY or not set";
	affirm { !$self->is_execute_pending || $params{NO_PENDING_CHECK} } "execute method pending";

	if (defined $values) {
		for my $v(@$values) {
			my $col=$v->{COL};
			affirm { defined $col } "no COL key into 2^ param";
			if (ref($col) eq '') {
				my $c=$table->find_column_by_name($col);
				affirm { defined $c } "no such colum with name '$col' into table ".$table->get_sql_name;
				$v->{COL}=$col=$c;
			}
			affirm { ref($col)=~/::column$/ } "the type of the 2^ param  of COL key is not of column class";
		}
	}
	
	unless (defined $self->{BINDING_TYPE}) {
		affirm { defined $table } "1^ param not set";
		affirm { defined $values } "2^ param not set";
		my @cols=map { $_->{COL} } @$values;		
		my $sql=$self->_get_delete_generic_sql($table,\@cols,%params);
		$self->_create_prepare($sql,%params);
		$self->{BINDING_TYPE}=BINDING_TYPE_DELETE_GENERIC;
		$self->{BINDING_TABLE}=$table;
		$self->{BINDING_VALUES}=[];
		$self->{BINDING_SQL}=$sql;
	}
	else {
		$table=$self->{BINDING_TABLE} unless defined $table;
		affirm { $self->{BINDING_TYPE} eq BINDING_TYPE_DELETE_GENERIC } "binding type is not BINDING_TYPE_DELETE_GENERIC";
		affirm { $self->{BINDING_TABLE}->get_sql_name eq $table->get_sql_name } "incompatible binding table";
		if (defined $values) {
			my @cols=map { $_->{COL} } @$values;		
			affirm { $self->{BINDING_SQL} eq $self->_get_delete_generic_sql($table,\@cols,%params) } "incompatible binding delete";
		}
	}
	
	if (defined $values) {
		for my $i(0..scalar(@$values)- 1) {
			my $v=$values->[$i];
			affirm { ref($v) eq 'HASH' } ref($v).": not a HASH ";
			$self->bind_column($v->{COL},$v->{VALUE},%params,COL_SEQ => $i);
		}
		$self->{EXECUTE_PENDING}=1;
		my $n=$self->execute(%params);
		$n = 0 if $n eq '0E0';
		return $n;
	}
	return $self;
}

sub _get_insert_generic_sql {
	my ($self,$table,$values,%params)=@_;
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	return "insert into "
			.$p
			.$table->get_sql_name
			.$s
			." values ("
			.join(",",map { '?' } @$values)
			.")";			 
}

sub insert_row_from_generic  {
	my ($self,$table,$values,%params)=@_;
	affirm { ref($table) =~/::table$/ } "1^ param must be an object of  table class";
	affirm { !defined $values || ref($values) eq 'ARRAY' } "2 param must be not set or ARRAY";
	affirm { !$self->is_execute_pending || $params{NO_PENDING_CHECK} } "execute method pending";
	unless (defined $self->{BINDING_TYPE}) {
		affirm { defined $table } "1^ param not set";
		my $sql=$self->_get_insert_generic_sql($table,$values,%params);
		$self->_create_prepare($sql,%params);
		$self->{BINDING_TYPE}=BINDING_TYPE_INSERT_GENERIC;
		$self->{BINDING_TABLE}=$table;
		$self->{BINDING_VALUES}=[];
	}
	else {
		$table=$self->{BINDING_TABLE} unless defined $table;
		affirm { $self->{BINDING_TYPE} eq BINDING_TYPE_INSERT_GENERIC } "binding type is not BINDING_TYPE_DELETE_GENERIC";
		affirm { $self->{BINDING_TABLE}->get_sql_name eq $table->get_sql_name } "incompatible binding table";
	}
	if (defined $values) {
		my @cols=$table->get_columns;
		affirm { scalar(@cols) == scalar(@$values) } "colums number not equal to values number";
		for my $i(0..scalar(@$values)- 1) {
			$self->bind_column($cols[$i],$values->[$i],%params,COL_SEQ => $i);
		}
		$self->{EXECUTE_PENDING}=1;
		my $n=$self->execute(%params);
		$n = 0 if $n eq '0E0';
		return $n;
	}
	return $self; 
}

sub _get_query_row_sql {
	my ($self,$table,%params)=@_;
	my @cols=$table->get_pk_columns;
	my $pk_init=$params{PK_INIT};
	$pk_init=[undef] unless defined $pk_init; #use only ID 
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	my $sql="select * from "
				.$p
				.$table->get_sql_name
				.$s
				.(scalar(@$pk_init) ? " where " : "")
				.join(" and ",map { $cols[$_]->get_sql_name.'=?' } (0..scalar(@$pk_init) - 1))
				.' order by '
				.join(",",map { $_->get_sql_name } @cols)
	;
	return $sql;
}

sub _get_generic_query_row_sql {
	my ($self,$table,%params)=@_;
	$params{DISPLAY}=$table->get_columns unless defined $params{DISPLAY};
	my @cols_display=();
	for my $k(qw(DISPLAY WHERE ORDER)) {
		$params{$k}=[] unless defined $params{$k};
		affirm { ref($params{$k}) eq 'ARRAY' } "param '$k' must be array";
		my @a=@{$params{$k}};
		affirm { ref($table) =~ /::table$/ } "1^ param is not of table class";
		affirm { defined $table->get_sql_name } "1^ param of type table not have an sql name";
		for my $i(0..scalar(@a) - 1) {
			my $e=$a[$i];
			my $col=$k eq 'WHERE' 
					? do {
							affirm { ref($e) eq 'HASH' } "element '$i' of '$k' param must be HASH";
							$e->{COL}
					}
					: $e;
			my $r=ref($col);
			if ($r =~/::column$/) {
				push @cols_display,$col if $k eq 'DISPLAY';
			}
			elsif($r eq '') {
				my $name=$col;
				affirm  { defined $name } "element '$i' (column) of '$k' param must be defined";
				$col=$table->find_column_by_name($name);
				affirm { defined $col } "no such column with name '$name' in table ".$table->get_sql_name." - element '$i' of '$k' param";
				push @cols_display,$col if $k eq 'DISPLAY';
			}
			else {
				affirm  { 0 } "$r - invalid type for the element '$i' of '$k' param";
			}
			if ($k eq 'WHERE') {
				$a[$i]->{COL}=$col
			}
			else {
				$a[$i]=$col
			}
		}
		$params{$k}=\@a;
	}
	
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	my $sql="select "
		.join(",",map { $_->get_sql_name } @{$params{DISPLAY}})
		." from $p".$table->get_sql_name.$s
		. ( scalar(@{$params{WHERE}}) 
				? ' where '.join(' and ',map { $_->{COL}->get_sql_name.'=?' } @{$params{WHERE}})
				: ''
		)
		.( scalar(@{$params{ORDER}})
				? ' order by '.join(',',map { $_->get_sql_name } @{$params{ORDER}})
				: ''
		);
	return ($sql,\@cols_display);
}
		

sub generic_query_rows {
	my ($self,$table,%params)=@_;
	affirm { !$self->is_execute_pending || $params{NO_PENDING_CHECK} } "execute method pending";
	unless (defined $self->{BINDING_TYPE}) {
		affirm { defined $table } "1^ param not set";
		my ($sql,$cols_display)=$self->_get_generic_query_row_sql($table,%params);
		$self->_create_prepare($sql,%params);
		$self->{BINDING_TYPE}=BINDING_TYPE_QUERY_ROW_GENERIC;
		$self->{BINDING_TABLE}=$table;
		$self->{BINDING_VALUES}=[];
		$self->{BINDING_DISPLAY}=$cols_display;
		$self->{BINDING_SQL}=$sql;
		
	}
	else {
		affirm { $self->{BINDING_TYPE} eq BINDING_TYPE_QUERY_ROW_GENERIC } "binding type is not BINDING_TYPE_QUERY_ROW_GENERIC";
		$table=$self->{BINDING_TABLE} unless defined $table;
		affirm { $self->{BINDING_TABLE}->get_sql_name eq $table->get_sql_name } "incompatible binding table";
		unless ($ENV{NDEBUG}) {
			my ($sql,$cols_display)=$self->_get_generic_query_row_sql($table,%params);
			affirm { $self->{BINDING_SQL} eq $sql } "incompatible binding query";
		}
	}
	
	my $where_filter=nvl($params{WHERE},[]);
	for my $i(0..scalar(@$where_filter) - 1) {
		my $f=$where_filter->[$i];
		if (ref($f->{COL}) !~/::column$/) {
			my $col=$table->find_column_by_name($f->{COL});
			affirm { defined $col } "no such column with name '".$f->{COL}."' in table '".$table->get_sql_name."'";
			$f->{COL}=$col;
		}
		$self->bind_column($f->{COL},$f->{VALUE},COL_SEQ => $i,TAG => $params{TAG});
	}	
	$self->execute(NO_PENDING_CHECK => 1,TAG => $params{TAG});
	return $self->{CURSOR_CLASS}->_new(
			BINDING => $self
			,DEBUG 	=> $self->{DEBUG}
	);
}

sub get_valuecol_idx {
	my ($self,%params)=@_;
	my $t=$self->{BINDING_TABLE};
	affirm { defined $t } "attribute BINDING_TABLE not set";
	affirm { $t->is_internal_reference } nvl($t->get_sql_name,$t->get_attrs_value(qw(NAME))).": is not an internal reference table";
	for my $c($t->get_columns) {
		return $c->get_column_sequence if $c->get_attrs_value(qw(VALUE_COL));
	}
	undef;
}

sub get_binding_columns {
	my ($self,%params)=@_;
	if (!defined $self->{BINDING_VALUES}) {
		return wantarray ? () : [];
	}
	my @binding=grep (!$params{PK_ONLY} || $_->{COL}->is_pk,@{$self->{BINDING_VALUES}});
	return wantarray ? @binding : \@binding;
}

sub get_binding_values {
	my ($self,%params)=@_;
	my @values= map { $_->{VALUE} } $self->get_binding_columns(%params);
	return wantarray ? @values : \@values;
}

sub get_binding_table {
	my ($self,%params)=@_;
	my $t=$self->{BINDING_TABLE};
	if ($self->{DEBUG} && defined $params{TAG}) {
		my $name=$t ? $t->get_sql_name : '<undef>';
		$self->_debug($params{TAG},' get binding table:',$name);
	}
	$t;
}

sub execute {
	my ($self,%params)=@_;
	my $tag=delete $params{TAG};
	if ($self->{DEBUG}) {
		unless ($self->is_execute_pending || $params{NO_PENDING_CHECK}) {
			my $t=$self->get_binding_table;
			my $table_name=$t ? $t->get_sql_name : '<not binding table>';
			$self->_debug($tag,"$table_name: not prepared for execute");
		}
	}
	affirm { $self->is_execute_pending || $params{NO_PENDING_CHECK} } "not prepared for execute";

	local $self->{DB_CONN}->{RaiseError}=1;	
	my $r=$self->get_sth->execute;
	if ($self->{DEBUG} || !$r) {
		if ($self->{DEBUG}) {
			my @data=(
				$tag
				,'EXECUTED'
				,$self->{SQL},' with data ('
				,join(',',map { 
								my $x=nvl($_,'<null>'); 
								$x=~s/'/''/g; #'
								$x="'".$x."'" unless $x=~/^\d+$/;
								$x;
						} $self->get_binding_values
				)
				,')'
			);
			$self->_debug(@data);
		}
		affirm { $r } "execute failed";
	}
	delete $self->{EXECUTE_PENDING};
	$r;
}


sub is_execute_pending { return $_[0]->{EXECUTE_PENDING} ? 1 : 0; }

sub get_query_prepared { return $_[0]->{SQL}; }

sub _get_sql_drop_table {
	my ($self,%params)=@_;
	croak "abstract method ";
}

sub drop_table {
	my ($self,$table,%params)=@_;
	affirm { defined $table } "1^ param not set";
	my $tag=delete $params{TAG};
	my $sql=$self->_get_sql_drop_table(%params);
	my $name=ref($table)=~/::table$/ ? $table->get_sql_name : $table;
	affirm { ref($name) eq '' } "1^ param is not a scalar or a table object";
	$sql=~s/\%t/$name/g;
	$self->_debug($tag,'DROP TABLE',$sql);
	local $self->{DB_CONN}->{RaiseError}=1;
	my $n=$self->{DB_CONN}->do($sql);
	$n=0 if $n eq '0E0';
	return $n;
}
sub _get_sql_drop_view {
	my ($self,%params)=@_;
	croak "abstract method ";
}

sub drop_view {
	my ($self,$table,%params)=@_;
	affirm { defined $table } "1^ param not set";
	my $tag=delete $params{TAG};
	my $sql=$self->_get_sql_drop_view(%params);
	my $name=ref($table)=~/::table$/ ? $table->get_view_sql_name : $table;
	affirm { ref($name) eq '' } "1^ param is not a scalar or a table object";
	$sql=~s/\%v/$name/g;
	$self->_debug($tag,'DROP VIEW',$sql);
	local $self->{DB_CONN}->{RaiseError}=1;
	my $n=$self->{DB_CONN}->do($sql);
	$n=0 if $n eq '0E0';
	return $n;
}


sub _information_tables {
	affirm { 0 } "abstract method";
}

sub information_tables {
	my ($self,%params)=@_;
	local $self->{DB_CONN}->{RaiseError}=1;
	$self->_information_tables(%params);
}

sub query_from_view {
	my ($self,$view_name,%params)=@_;
	affirm { defined $view_name } "1^ param not set";
	my ($p,$s)=map{ nvl($self->{$_}) } (qw(EXECUTE_OBJECTS_PREFIX EXECUTE_OBJECTS_SUFFIX));
	my $q="select * from ".$p.$view_name.$s;
	local $self->{DB_CONN}->{RaiseError}=1;
	if (defined (my $prep=$self->{DB_CONN}->prepare($q))) {
		unless($prep->execute) {
			$prep->finish;
			return wantarray ? () : undef;
		}
		my @rows=();
		while(my $r=$prep->fetchrow_arrayref) {
			push @rows,Storable::dclone($r);
		}
		$prep->finish;
		return wantarray ? @rows : \@rows;
	}
	return wantarray ? () : undef;
}

sub finish {
	my ($self,%params)=@_;
	if (defined  $self->{STH}) {
		if ($self->{DEBUG}) {
			my $t=$self->get_binding_table(%params);
			$self->_debug($params{TAG},'finish for table ',$t->get_sql_name) if defined $t;
		}
		local $self->{DB_CONN}->{RaiseError}=1;
		(delete $self->{STH})->finish;
	}
	for my $i(qw(BINDING_TYPE BINDING_VALUES BINDING_TABLE SQL EXECUTE_PENDING)) {
		delete $self->{$i};
	}
	return $self;
}

sub DESTROY { 
	$_[0]->finish(NO_PENDING_CHECK => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})
}


1;


__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::generic::binding -  binding generator for blx::xsdsql::schema_repository::sql

=cut

=head1 SYNOPSIS

use  blx::xsdsql::schema_repository::sql::generic::binding

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new




=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions


get_connection - return the value of DB_CONN param


get_sth  - return the handle of the prepared statement


get_clone - return the clone of the object


get_next_sequence - return a unique number

    this method call _get_next_sequence abstract method because the algorithm  depend from database
    the attribute SEQUENCE_NAME must be set before call this method


bind_column - bind a value with a column

    the first argument is a column object generate from blx::xsdsql::parser::parse
    the second argument is a scalar


insert_binding - prepare a binding for a table

    the first argument is a table object generate from blx::xsdsql::parser::parse

    PARAMS:
        NO_PENDING_CHECK - not check for a pending execute
        NO_PK             - not init the columns of the primary key
        PK_ID_VALUE         - init the first column of the primary key with this value
                            if this param is not set the method get_next_sequence is used
delete_rows_for_id - delete a row  of a table

    the first argument is a table object generate from blx::xsdsql::parser::parse
    the second argument is  a id value
    the method return  the number of rows deleted if id value exist else return undef


get_binding_table - return the binding table object

get_binding_columns - return the columns with a value binding

    in scalar mode the method return a pointer of an array
    in array mode  the method return an array


get_binding_values -  return the values binding

    in scalar mode the method return a pointer of an array
    in array mode  the method return an array


execute - execute the current statement prepared

    the method return the self object

    PARAMS:
        NO_PENDING_CHECK - not check for a pending execute


is_execute_pending - return true if exits a prepared statement with binds but not executed


get_query_prepared - return the current query prepared


query_from_view  - return a result of a query

    ARGUMENT:

        view_name  - view name


finish - close the prepared statements

    this method return the self object


=head1 EXPORT


None by default.


=head1 EXPORT_OK

    BINDING_TYPE_INSERT
    BINDING_TYPE_DELETE
    BINDING_TYPE_UPDATE
    BINDING_TYPE_QUERY_ROW

    :all


=head1 SEE ALSO

    DBI  - Database independent interface for Perl

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

