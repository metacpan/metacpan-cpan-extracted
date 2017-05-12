package blx::xsdsql::xml::writer;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use File::Basename;
use XML::Writer;

use blx::xsdsql::ut::ut qw( nvl);
use base(qw(blx::xsdsql::xml::base));

use constant {
		DEFAULT_NAMESPACE => ''
};

sub _get_root_and_row_table {
	my ($self,$schema,$id,%params)=@_;
	my $root_table=$schema->get_root_table;
	my $root_row=$self->_prepared_query($root_table,ID => $id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})->fetchrow_arrayref;
	return ($params{URI},$root_table,$root_row) if defined $root_row;
	for my $h($schema->get_childs_schema) {
		my ($schema,$uri)=map { $h->{$_} } qw(SCHEMA NAMESPACE_PREFIX);
		my @r=$self->_get_root_and_row_table($h->{SCHEMA},$id,%params,URI => $uri);
		return @r if scalar(@r);
	}
	();
}

sub _prepared_query {
	my ($self,$table,%params)=@_;
	affirm { defined $params{TAG} } "TAG param not set";
	affirm { defined $table } "1^ param not set";
	affirm {defined  $params{ID} != defined $params{PK_INIT} } $params{TAG}.": ID or PK_INIT params not set";
	my $sqlname=$table->get_sql_name;
	$self->{PREPARED}->{$sqlname}->{QUERY}=$self->{BINDING}->get_clone
		unless defined $self->{PREPARED}->{$sqlname}->{QUERY};
		
	my $values=$params{PK_INIT};
	$values=[$params{ID}] unless defined $values;	
	affirm { ref($values) eq 'ARRAY' } ref($values).": is not ARRAY";
	my @cols=$table->get_pk_columns;
	affirm { scalar(@cols) > 0 } $table->get_sql_name.': not has pk_columns';
	my @where=map { { COL => $cols[$_],VALUE => $values->[$_]} } (0..scalar(@$values) - 1);
	
	$self->{PREPARED}->{$sqlname}->{QUERY}->generic_query_rows(
						$table
						,WHERE => \@where
						,ORDER	=> \@cols 
						,TAG => $params{TAG}
	);
		
}

sub _prepared_delete {
	my ($self,$table,%params)=@_;
	affirm { defined $params{TAG} } "TAG param not set";
	affirm { defined $table } "1^ param not set";
	affirm { defined  $params{ID} } $params{TAG}.": ID  param not set";
	my $sqlname=$table->get_sql_name;

	$self->{PREPARED}->{$sqlname}->{DELETE}=$self->{BINDING}->get_clone
		unless defined $self->{PREPARED}->{$sqlname}->{DELETE};
		
	my @cols=$table->get_pk_columns;
	$self->{PREPARED}->{$sqlname}->{DELETE}->delete_rows_from_generic(
						$table
						,[ { COL => $cols[0],VALUE => $params{ID} } ]
						,TAG => $params{TAG}
	);	
}

sub _xml_decl {
	my ($self,%params)=@_;
	affirm { defined $params{TAG} } "TAG param not set";
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_XMLDECL HANDLE_AFTER_XMLDECL));
	if (ref($hb) eq 'CODE') {
		$hb->(%$self,%params) || return 0;
	}
	unless ($params{NO_WRITE_HEADER}) {
		$self->_debug($params{TAG},': xmlDecl');
		$self->{XMLWRITER}->xmlDecl($params{ENCODING},$params{STANDALONE}) 
	}
	if (ref($ha) eq 'CODE') {
		$ha->(%$self,%params) || return 0;
	}
	1;
}

sub _write_xml_start {
	my ($self,%params)=@_;
	$self->_xml_decl(%params,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	my $row=$params{ROOT_ROW};
	$self->_write_dtd($row->[0],DELETE_ROWS => $params{DELETE_ROWS});
	my $root=$params{TABLE};
	my @cols=$root->get_columns;

	for my $i(1..scalar(@$row) - 1) {
		next unless defined $row->[$i];
		my $col=$cols[$i];
		if (my $table=$col->get_table_reference) {
			if ($table->is_simple_content_type) {
				my $xpath=$col->get_attrs_value('PATH');
				$self->_write_xml(ID => $row->[$i],TABLE	=> $table,LEVEL	=> 1,START_TAG => $xpath,END_TAG => $xpath,ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS},XPATH => $xpath,DELETE_ROWS => $params{DELETE_ROWS});
			}
			else {
				my $xpath=nvl($col->get_attrs_value(qw(PATH)),$table->get_attrs_value(qw(PATH))); 
				$self->_write_xml(ID => $row->[$i],TABLE	=> $table,LEVEL	=> 1,START_TAG => $xpath,END_TAG => $xpath,ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS},XPATH => $xpath,CURRENT_URI => $params{CURRENT_URI},DELETE_ROWS => $params{DELETE_ROWS});
			}
		}
		else {
			$self->_write_xml(ROW_FOR_ID => $row,TABLE	=> $root,LEVEL	=> 1,SIMPLE_ROOT_NODE => 1,ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS},DELETE_ROWS => $params{DELETE_ROWS});
		}
		$self->_end(%params,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		return $self;
	}
	croak "no such column for xml root";
}


sub _write_xml {
	my ($self,%params)=@_;
	my $p={ DELETE_ROWS => $params{DELETE_ROWS} };
	my $ostr=$self->{XMLWRITER};
	my $table=$params{TABLE};
	my $r=$params{ROW_FOR_ID};
	unless(defined $r) {
		$r=$self->_prepared_query($table,ID => $params{ID},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})->fetchrow_arrayref;
		affirm { defined $r } nvl($params{ID}).": no such id";
		$self->_prepared_delete($table,ID => $params{ID},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) 
			if $p->{DELETE_ROWS};
	}
	my $columns=$table->get_columns;
	my $flag_start_tag=1;
	if ($params{LEVEL} == 1) {   # the table is the header of the xml
		if (defined (my $start_tag=$params{START_TAG})) {
			$params{NS_PREFIXES}=$self->_get_ns_prefixes(
						ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS}
						,ROW => $r
						,COLUMNS => $columns
			);
			
			my $uri=$params{CURRENT_URI} // $table->get_URI;
			$params{CURRENT_URI}= $params{CURRENT_URI} // $uri;
			
			my $tag=$self->_get_node_fullname($start_tag,$params{NS_PREFIXES},%params,FORM => 'Q');

			my $attrs=$self->_split_attrs(
						ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS}
						,ROW 			=> $r
						,COLUMNS 		=> $columns
						,NS_PREFIXES	=> $params{NS_PREFIXES}
						,TABLE			=> $params{TABLE}
			);
			$flag_start_tag=$self->_start_tag(
					$tag
					,%$p
					,MIXED => $table->is_mixed
					,ATTRIBUTES => $attrs
					,XPATH => $params{XPATH}
					,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
			);
			$params{END_TAG}=$tag;
		} 
		else {
			affirm { $params{SIMPLE_ROOT_NODE} } "param START_TAG or SIMPLE_ROOT_NODE not set";
		}
	}
	elsif (defined (my $tag=$params{START_TAG})) {
		my @attrs=$self->_resolve_attrs(
			$r
			,$columns
			,%params
		);
		$flag_start_tag=$self->_start_tag($tag,%$p,MIXED => $table->is_mixed,ATTRIBUTES => \@attrs,XPATH => $params{XPATH},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		
	}

	if ($flag_start_tag) {
		for my $i(1..scalar(@$r) - 1) {
			my $col=$columns->[$i];
			next if $col->is_attribute;
			my $value=$r->[$i];
			if (defined $col->get_table_reference) {
				next unless defined $value;
				next unless defined  $col->get_xsd_seq;
				my $orig_table=$table;
				$table=$col->get_table_reference;
				if ($table->is_simple_content_type) {
					my $xpath=$col->get_attrs_value('PATH');
					my $tag=$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);
					if ($col->get_max_occurs > 1) {
						my $cur=$self->_prepared_query($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						$self->_prepared_delete($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if $p->{DELETE_ROWS};
						while(my $r=$cur->fetchrow_arrayref) {
							$self->_write_xml(%$p,TABLE	=> $table,LEVEL	=> $params{LEVEL},ROW_FOR_ID	=> $r,NS_PREFIXES => $params{NS_PREFIXES},START_TAG => $tag,END_TAG => $tag,XPATH => $xpath);
						}
						$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})
					}
					else {
						$self->_write_xml(%$p,ID => $value,TABLE	=> $table,LEVEL	=> $params{LEVEL} + 1,NS_PREFIXES => $params{NS_PREFIXES},START_TAG => $tag,END_TAG => $tag,XPATH => $xpath);
					}
				}
				elsif (!$col->is_internal_reference) {
					if (defined $table->get_attrs_value(qw(PATH))) {
						if (!$table->is_type) { 
							my $xpath=$table->get_attrs_value(qw(PATH));
							my $tag=$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);

							$self->_write_xml(%$p,ID => $value,TABLE	=> $table,LEVEL	=> $params{LEVEL} + 1,NS_PREFIXES => $params{NS_PREFIXES},START_TAG => $tag,END_TAG => $tag,XPATH => $xpath);
						}
						else {  #the column reference a complex type
							my $cur=$self->_prepared_query($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
							my $xpath=$col->get_attrs_value(qw(PATH));
							my $tag=$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);
							$self->_prepared_delete($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if $p->{DELETE_ROWS};
							while(my $r=$cur->fetchrow_arrayref()) {
								if ($col->is_group_reference) {
									$self->_write_xml(%$p,TABLE	=> $table,LEVEL	=> $params{LEVEL},ROW_FOR_ID	=> $r,SIMPLE_ROOT_NODE => 1,NS_PREFIXES => $params{NS_PREFIXES});										
								}
								else {
									my $columns=$table->get_columns;
									my @attrs=$self->_resolve_attrs($r,$columns,%params);
									if ($self->_start_tag($tag,%$p,MIXED => $orig_table->is_mixed,ATTRIBUTES => \@attrs,XPATH => $xpath,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) {
										$self->_write_xml(%$p,TABLE	=> $table,LEVEL	=> $params{LEVEL} + 1,ROW_FOR_ID	=> $r,NS_PREFIXES => $params{NS_PREFIXES});	
									}
									$self->_end_tag($tag,%$p,XPATH => $xpath,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
								}
							}
							$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})
						}
					}
					else {	# is a sequence table
						my $cur=$self->_prepared_query($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						$self->_prepared_delete($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if $p->{DELETE_ROWS};
						while(my $r=$cur->fetchrow_arrayref) {
							$self->_write_xml(%$p,TABLE	=> $table,LEVEL	=> $params{LEVEL},ROW_FOR_ID	=> $r,SIMPLE_ROOT_NODE => 1,NS_PREFIXES => $params{NS_PREFIXES});	
						}
						$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})
					}
				}
				else   { #the column reference a simple type
					my $cur=$self->_prepared_query($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					my $xpath=$col->get_attrs_value(qw(PATH));
					my $tag=$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);
					my $idx=$self->{PREPARED}->{$table->get_sql_name}->{QUERY}->get_valuecol_idx;
					affirm { defined $idx } $table->get_sql_name." the table not contain a VALUE_COL column";
					while (my $r=$cur->fetchrow_arrayref) {
						if ($table->is_mixed) {
							$self->_raw_data($r->[$idx - 1],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $r->[$idx - 1];
							$self->_data_element($tag,$r->[$idx],%$p,XPATH => $xpath,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},MIXED => 1);
						}
						else {
							$self->_data_element($tag,$r->[$idx],%$p,XPATH => $xpath,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},MIXED => 0);						
						}
					}
					$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$self->_prepared_delete($table,ID => $value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if $p->{DELETE_ROWS};
				}
			}
			elsif ($col->is_mixed) {
				$self->_raw_data($value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $value;
			}
			else {  #normal data column
				if (defined (my $xpath=$col->get_attrs_value(qw(PATH)))) {
					my $table=$params{TABLE};
					if (defined $value || $col->get_min_occurs > 0) {
						if ($params{LEVEL} == 1 && $params{SIMPLE_ROOT_NODE}) {   # the table is the header of the xml
							my $ns_prefixes=$self->_get_ns_prefixes(
										ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS}
										,ROW => $r
										,COLUMNS => $columns
							);
							my $tag=$self->_get_node_fullname($col,$ns_prefixes,%params,FORM => 'Q');
							$value='' unless defined $value;
							my $attrs=$self->_split_attrs(
										ROOT_TAG_PARAMS => $params{ROOT_TAG_PARAMS}
										,ROW 			=> $r
										,COLUMNS 		=> $columns
										,NS_PREFIXES	=> $ns_prefixes
							);
							$self->_data_element(
								$tag
								,$value
								,%$p
								,MIXED => $table->is_mixed
								,ATTRIBUTES => $attrs
								,XPATH => $xpath
								,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
							);
						}
						else {
							$value='' unless defined $value;
							my $tag=$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);
							$self->_data_element(
								$tag
								,$value
								,%$p
								,MIXED => $table->is_mixed
								,XPATH => $xpath
								,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
							);
						}
					}
				}
				elsif ($params{TABLE}->is_simple_content_type && $col->get_attrs_value('VALUE_COL')) {
					if (defined $value) {
						$value='' unless defined $value;
						$ostr->characters($value);                              
					}
				}
			}
		}  # for columns 
	} #flag_start_tag

	if (defined (my $tag=$params{END_TAG})) {
		$self->_end_tag($tag,%$p,XPATH => $params{XPATH},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	$self;
}
sub _get_ns_prefixes {
	my ($self,%params)=@_;
	my $p=$params{ROOT_TAG_PARAMS};
	$p=[ $self->_resolve_attrs($params{ROW},$params{COLUMNS},ONLY_SYSATTRS => 1) ] unless defined $p;
	my @root_tag_params=@$p;
	affirm { scalar(@root_tag_params) % 2 == 0  } join(",",@root_tag_params).": not an array of pairs key,value";
	my %root_tag_params=@root_tag_params;
	my %namespace_prefix=map { /^xmlns:(\w+)/ ? ($root_tag_params{$_},$1) : (); } keys %root_tag_params; 
	if (defined (my $xmlns=$root_tag_params{xmlns})) {
		$namespace_prefix{&DEFAULT_NAMESPACE}=$xmlns;
	}
	\%namespace_prefix;
}

sub _split_attrs {
	my ($self,%params)=@_;
	my $p=$params{ROOT_TAG_PARAMS};
	return $p if defined $p;
	[$self->_resolve_attrs($params{ROW},$params{COLUMNS},%params)]
}
	
sub _split_sysattrs {
	my $v=shift;
	return () unless defined $v;
	my @a=();
	while(1) {
		my @m=$v=~/^\s*([^=]+)="([^"]+)"(.*)$/;
		last unless scalar(@m);
		push @a,@m[0..1];
		$v=$m[2];
	}
	@a;
}

sub _get_node_fullname {
	my ($self,$col,$ns_prefixes,%params)=@_;
	affirm { defined $col } '1^ param not set';
	affirm { ref($ns_prefixes) eq 'HASH' } '2^ param is not HASH';
	affirm { defined $params{TABLE} } "param TABLE not set";
	my $uri=ref($col) ? nvl($params{TABLE}->get_URI) :  nvl($params{CURRENT_URI});
	my $ns_pref=$self->_get_current_namespace_prefix($ns_prefixes,$uri,%params);
	$ns_pref=$ns_pref // '';
	$ns_pref.=':' if length($ns_pref);
	my $name=ref($col) ? $col->get_name : basename($col);
	if (nvl($params{FORM},'U') eq 'Q') { #force qualified
		return $ns_pref.$name;
	}
	affirm { ref($col) } 'col is not a column class';
	my $form=$col->get_element_form;
	my $schema=undef;
	unless (defined $form && defined $uri) {
		my @schemas=$self->{SCHEMA}->find_schemas_from_namespace($uri);
		affirm { scalar(@schemas) } "$uri: not schema from this namespace";
		if (scalar(@schemas) > 1) {
			my $schema_code=$params{TABLE}->get_schema_code;
			affirm { defined $schema_code } $params{TABLE}->get_name.': schema code not set for this table';
			for my $s(@schemas) {
				if ($s->get_attrs_value(qw(SCHEMA_CODE)) eq $schema_code) {
					$schema=$s;
					last;
				}
			}
			affirm { defined $schema } "$schema_code: no such schema with this schema_code";
		}
		else {
			$schema=$schemas[0];
		}
	}
	if (!defined $form && defined $schema) {
		$form=$schema->get_attrs_value(
			$col->is_attribute ? 'ATTRIBUTE_FORM_DEFAULT' : 'ELEMENT_FORM_DEFAULT'
		);
	}
	$form //= 'U';
	if ($form eq 'Q') {
		if (defined (my $uri=$col->get_attrs_value(qw(URI)))) {
			my $ns=$params{NS_PREFIXES}->{$uri};
			affirm { defined $ns } "no abbreviation namespace for uri $uri";
			return $ns.':'.$name;
		}
		return $ns_pref.$name;
	}
	if (defined (my $uri=$col->get_attrs_value(qw(URI)))) {
		my $ns=$params{NS_PREFIXES}->{$uri};
		affirm { defined $ns } "no abbreviation namespace for uri $uri";
		return $ns.':'.$name if $ns ne $ns_pref; 
	}
	$name;
}

sub _resolve_attrs {
	my ($self,$r,$columns,%params)=@_;
	affirm { ref($r) eq 'ARRAY' } '1^ param is not ARRAY';
	affirm { $params{ONLY_SYSATTRS} || ref($params{NS_PREFIXES}) eq 'HASH' } 'param NS_PREFIXES is not HASH';
	my @attrs=map {
		my @out=();
		my ($row,$col)=($r->[$_],$columns->[$_]);
		if (defined $row) {
			affirm { ($col->is_attribute ? 1 : 0) + ($col->is_sys_attributes ? 1 : 0) < 2 }
				$col->get_full_name.': this column is sys_attribute and attribute';
			if ($col->is_attribute && !$params{ONLY_SYSATTRS}) {
				push @out,$self->_get_node_fullname($col,$params{NS_PREFIXES},%params);
				push @out,$row;
			}
			if ($col->is_sys_attributes && !$params{NOT_SYSATTRS}) {
				push @out,_split_sysattrs($row);
			}
		}
		@out;
	} (0..scalar(@$r) - 1);
	@attrs;
}

sub _get_current_namespace_prefix {
	my ($self,$ns_prefixes,$uri,%params)=@_;
	return '' if length(nvl($uri)) == 0;
	affirm { ref($ns_prefixes) eq 'HASH'  } "1^ param must be HASH";
	my $ns=$ns_prefixes->{$uri};
	$ns='' if !defined $ns && $uri eq nvl($ns_prefixes->{&DEFAULT_NAMESPACE});  
	unless (defined  $ns) {
		$self->_debug($params{TAG},": (W) not namespace prefix from uri '$uri' ");
		$ns='';
	}
	$self->_debug($params{TAG},"translate URI '$uri' into nsprefix '$ns'");
	$ns;
}

sub _data_element {
	my ($self,$tag,$value,%params)=@_;
	affirm { defined  $params{XPATH} } "param XPATH not set";
	affirm { defined  $params{TAG} } "param TAG not set";
	affirm { defined  $params{MIXED}} "param MIXED not defined"; 
	$params{XPATH_ARRAY}=[grep(length($_),split("/",$params{XPATH}))];
	$params{XPATH_LEVEL}=scalar(@{$params{XPATH_ARRAY}});
	my  $ostr=$self->{XMLWRITER};
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_DATA_ELEMENT HANDLE_AFTER_DATA_ELEMENT));
	if (ref($hb) eq 'CODE') {
		$hb->($tag,$value,%$self,%params) || return 0;
	}
	$self->_debug($params{TAG}," (data element) '$tag' with  value '".nvl($value,'<undef>')."'");
	if ($params{MIXED}) {
		my $datamode=$ostr->getDataMode;
		$ostr->setDataMode(0);
		$ostr->dataElement($tag,$value,ref($params{ATTRIBUTES}) eq 'ARRAY' ? @{$params{ATTRIBUTES}} : ());
		$ostr->setDataMode($datamode);
	}
	else {
		$ostr->dataElement($tag,$value,ref($params{ATTRIBUTES}) eq 'ARRAY' ? @{$params{ATTRIBUTES}} : ());
	}
	if (ref($ha) eq 'CODE') {
		$ha->($tag,$value,%$self,%params) || return 0;
	}
	1;
}

sub _start_tag {
	my ($self,$tag,%params)=@_;
	affirm { defined  $params{XPATH} } "param XPATH not set";
	affirm { defined  $params{TAG} } "param TAG not set";
	affirm { defined  $params{MIXED} } "param MIXED not defined";
	$params{XPATH_ARRAY}=[grep(length($_),split("/",$params{XPATH}))];
	$params{XPATH_LEVEL}=scalar(@{$params{XPATH_ARRAY}});
	my $ostr=$self->{XMLWRITER};
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_START_NODE HANDLE_AFTER_START_NODE));
	if (ref($hb) eq 'CODE') {
		$hb->($tag,%$self,%params) || return 0;
	}
	if ($params{XPATH_LEVEL} != 1 ||  !$params{NO_WRITE_HEADER}) { 
		$self->_debug($params{TAG}," (start_node) > '$tag'");
		if ($params{MIXED}) {
			my $datamode=$ostr->getDataMode;
			$ostr->setDataMode(0);
			$ostr->startTag($tag,ref($params{ATTRIBUTES}) eq 'ARRAY' ? @{$params{ATTRIBUTES}} : ());
			$ostr->setDataMode($datamode);
		}
		else {
			$ostr->startTag($tag,ref($params{ATTRIBUTES}) eq 'ARRAY' ? @{$params{ATTRIBUTES}} : ())
		}
	}

	if (ref($ha) eq 'CODE') {
		$ha->($tag,%$self,%params) || return 0;
	}
	1;
}

sub _end_tag {
	my ($self,$tag,%params)=@_;
	affirm { defined  $params{XPATH} } "param XPATH not set";
	affirm { defined  $params{TAG} } "param TAG not set";
	$params{XPATH_ARRAY}=[grep(length($_),split("/",$params{XPATH}))];
	$params{XPATH_LEVEL}=scalar(@{$params{XPATH_ARRAY}});
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_END_NODE HANDLE_AFTER_END_NODE));
	if (ref($hb) eq 'CODE') {
		$hb->($tag,%$self,%params) || return 0;
	}
	if ($params{XPATH_LEVEL} != 1 ||  !$params{NO_WRITE_FOOTER}) { 
		$self->_debug($params{TAG}," (end_node) < '/$tag'"); 
		$self->{XMLWRITER}->endTag($tag);
	}
	if (ref($ha) eq 'CODE') {
		$ha->($tag,%$self,%params) || return 0;
	}
	1;
}

sub _raw_data {
	my ($self,$value,%params)=@_;
	affirm { defined  $params{TAG} } "param TAG not set";
	affirm { defined $value } "1^ param not set";
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_RAW_DATA HANDLE_AFTER_RAW_DATA));
	if (ref($hb) eq 'CODE') {
		$hb->(undef,$value,%$self,%params) || return 0;
	}
	$self->_debug($params{TAG}," (raw data) with  value '$value'");
	$self->{XMLWRITER}->raw($value);
	if (ref($ha) eq 'CODE') {
		$ha->(undef,$value,%$self,%params) || return 0;
	}
	1;
}

{
	my %DTD_HANDLE=(
			NOTATION_TABLE => sub {
				my ($wr,$r)=@_;
				my ($base,$sysid,$pubid)=map { $r->[$_] } 	(2..4);
				$wr->raw("<!NOTATION ");
				$wr->raw($base) if defined $base;
				$wr->raw(' '.nvl($sysid,'SYSTEM'));
				$wr->raw(' "'.$pubid.'"') if defined $pubid;
				$wr->raw(">\n");		
				undef;
			}				
			,ENTITY_TABLE	=> sub {
				my ($wr,$r)=@_;
				my ($name,$val,$sysid,$pubid,$ndata)=map { $r->[$_] } 	(2..6);
				$wr->raw('<!ENTITY ');
				$wr->raw($name) if defined $name;
				$wr->raw(' "'.$val.'"') if defined $val;
				$wr->raw(' '.$pubid) if defined $pubid;
				$wr->raw(' SYSTEM "'.$sysid.'"') if defined $sysid;
				$wr->raw(' NDATA '.$ndata) if defined $ndata;
				$wr->raw(">\n");		
				undef;
			}
			,ATTLIST_TABLE	=> sub {
				my ($wr,$r)=@_;
				my ($elname,$attname,$type,$default,$fixed)=map { $r->[$_] } 	(2..6);
				$wr->raw('<!ATTLIST'); 
				$wr->raw(' '.$elname);
				$wr->raw(' '.$attname);
				$wr->raw(' '.$type);
				$wr->raw(' "'.$default.'"') if defined $default;
				$wr->raw(' "'.$fixed.'"') if defined $fixed;				
				$wr->raw(">\n");		
				return;			
			}
			,ELEMENT_TABLE => sub {
				my ($wr,$r)=@_;
				my ($name,$model)=map { $r->[$_] } (2,3);
				$wr->raw('<!ELEMENT'); 
				$wr->raw(' '.$name);
				$wr->raw(' '.$model);
				$wr->raw(">\n");		
				return;						
			}
	);
	
	sub _write_dtd {
		my ($self,$id,%params)=@_;
		affirm { defined  $id } "1^ param not set";
		my ($wr,$schema)=map { my $k=$_; affirm { defined $self->{$k} } "attribute $k not set"; $self->{$k} } qw(XMLWRITER SCHEMA);
		my @dtd_tables=map { $self->{EXTRA_TABLES}->get_extra_table($_) } qw(DOCTYPE_TABLE DTDSEQ_TABLE);
		my @id_colseq=map { 
			my $seq=($dtd_tables[$_]->get_pk_columns)[0]->get_column_sequence; 
			affirm { defined $seq } "the table ".$dtd_tables[$_]->get_sql_name." not have ID pk column";			
			$seq;
		} (0..scalar(@dtd_tables) - 1);
		my @cur=map {  $self->_prepared_query($_,ID => $id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); } @dtd_tables;
		my $r=$cur[0]->fetchrow_arrayref;	# read from DOCTYPE_TABLE
		if (defined $r) {
			my ($name,$systemid,$pubid)=map { $r->[$_] } ($id_colseq[0] + 1..$id_colseq[0] + 3); # see blx::xsdsql::schema_repository::sql::column::_factory_extra_table_columns for this index
			$wr->raw("<!DOCTYPE ");
			$wr->raw($name) if defined $name;
			$wr->raw(' '.nvl($pubid,'SYSTEM')); 
			$wr->raw(' "'.$systemid.'"') if defined $systemid; 
			my $first=1;
			
			while(my $r=$cur[1]->fetchrow_arrayref) { # read from DTDSEQ
				if ($first) {
					$wr->raw(" [\n");
					$first=0;
				}
				my ($id,$seq,$dtd_type)=map { $r->[$_] } ($id_colseq[1]..$id_colseq[1] + 3); # see blx::xsdsql::schema_repository::sql::column::_factory_extra_table_columns for this index
				my $table=$self->{EXTRA_TABLES}->get_extra_table($dtd_type);
				my $cur=$self->_prepared_query($table,PK_INIT => [ $id,$seq],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				{
					my $r=$cur->fetchrow_arrayref;
					my $row=$r;
					$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					affirm { defined $row } "not row with ID => $id and SEQ => $seq"; 
					my $handle=$DTD_HANDLE{$dtd_type};
					affirm { defined $handle } "$dtd_type: not handle for this dtd table code";
					my $id_colseq=($table->get_pk_columns)[0]->get_column_sequence;
					affirm { defined $id_colseq } "the table ".$table->get_sql_name." not have ID pk column";
					my @row=@$row;
					while($id_colseq--) { shift @row};
					$handle->($wr,\@row);
				}
			}
			$wr->raw("]") unless $first;
			$wr->raw(">\n");		
		}
		while(defined(my $c=shift @cur)) { $c->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); }
		if ($params{DELETE_ROWS}) {	
			my @dtd_tables=map { $self->{EXTRA_TABLES}->get_extra_table($_) } $self->{EXTRA_TABLES}->get_extra_table_types('DTD_TABLES');		
			for my $t(reverse @dtd_tables) {
				$self->_prepared_delete($t,ID => $id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
		}
		$self;
	}
}

sub _end {
	my ($self,%params)=@_;
	affirm { defined  $params{TAG} } "param TAG not set";
	my ($hb,$ha)=map { delete $params{$_}  } (qw(HANDLE_BEFORE_END HANDLE_AFTER_END));
	if (ref($hb) eq 'CODE') {
		$hb->(%$self,%params) || return 0;
	}
	$self->_debug($params{TAG},' end document ');
	$self->{XMLWRITER}->end;
	if (ref($ha) eq 'CODE') {
		$ha->(%$self,%params) || return 0;
	}
	1;
}

sub new {
	my ($class,%params)=@_;
	$params{XMLWRITER}=XML::Writer->new(
		DATA_INDENT => 4
		,DATA_MODE => 1
		,NAMESPACES => 0
		,UNSAFE    => 1
	) unless defined $params{XMLWRITER};
	$class->SUPER::_new(%params);
}

sub write {
	my ($self,%params)=@_;
	my $fd=nvl(delete $params{FD},*STDOUT); 
	my $schema=$self->{SCHEMA};
	affirm { !defined $params{ROOT_TAG_PARAMS} || ref($params{ROOT_TAG_PARAMS}) eq 'ARRAY' } "the param ROOT_TAG_PARAMS must be not set or must be ARRAY";
	affirm { !defined $params{ROOT_TAG_PARAMS} || scalar(@{$params{ROOT_TAG_PARAMS}}) % 2 == 0  } "the value of ROOT_TAG_PARAMS must be an array of pairs key,value";
	my $root_id=delete $params{ROOT_ID};
	return unless defined $root_id;
	return unless $root_id=~/^\d+$/;
	my $table_enc=$self->{EXTRA_TABLES}->get_extra_table(qw(XML_ENCODING));
	my $cur=$self->_prepared_query($table_enc,ID => $root_id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	if (defined (my $r=$cur->fetchrow_arrayref)) {
		my $enc_column=$table_enc->find_column_by_name('encoding');
		affirm { defined $enc_column } "no such column with name 'encoding' in table ".$table_enc->get_sql_name;
		my $encoding=$r->[$enc_column->get_column_sequence];
		affirm { defined $encoding } "no such value for encoding column";
		$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		unless(binmode($fd,':encoding('.$encoding.')')) {
			croak "binmode not support encoding '$encoding'\n";
		}
		$self->{XMLWRITER}->setOutput($fd);
		$params{ENCODING}=$encoding;
		
	}
	else {
		$cur->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		return;
	}
	my ($uri,$root_table,$root_row)=$self->_get_root_and_row_table($schema,$root_id,URI => $schema->get_attrs_value(qw(URI)));
	if (defined $root_row) {
		$self->_write_xml_start(%params,LEVEL => 0,ROOT_ROW => $root_row,TABLE => $root_table,CURRENT_URI => $uri);
		$self->_prepared_delete($root_table,ID => $root_id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})
			if $params{DELETE_ROWS};
	}
	$self->_prepared_delete($table_enc,ID => $root_id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) 
		if $params{DELETE_ROWS};

	defined $root_row ? $self : undef;
}


1;



__END__

=head1  NAME

blx::xsdsql::xml::writer - internal class - read from a database an put into an xml file

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
