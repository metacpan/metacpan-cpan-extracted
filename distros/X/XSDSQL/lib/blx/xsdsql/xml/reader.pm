package blx::xsdsql::xml::reader;

use strict;  # use strict is for PBP 
use Filter::Include; 
include blx::xsdsql::include;
#line 7
use XML::Parser;

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::xml::base);

sub _decode {
	my $self=shift;
	return $_[0] if scalar(@_) <= 1;
	@_;
}
sub _debug_stack {
	return $_[0] unless $_[0]->{DEBUG};
	my ($self,$n,%params)=@_;
	my $stack=nvl($params{STACK},$self->{STACK});
	$params{INDEX}= [ (0..scalar(@$stack) - 1) ] unless defined $params{INDEX};
	$params{INDEX}=[ $params{INDEX} ] if ref($params{INDEX}) eq '';
	for my $i(@{$params{INDEX}}) {
		my @line=();
		my $h=$stack->[$i];
		for my $k(sort keys %$h) {
			my $v=$h->{$k};
			my $r=ref($v);
			if ($r =~/::binding$/) {
				push @line,"$k: EXECUTE ".($v->is_execute_pending ? 'PENDING' : 'COMPLETED').' for table '.$v->get_binding_table->get_sql_name;
			}
			elsif ($r eq '')  {
				if (defined $v) {
					push @line,"$k => $v";
				}
				else {
					push @line,"$k => undef";
				}
			}
			else {
					push @line,"$k => $r";
			}
		}
		$self->_debug($n,@line);	
	}
	$self;
}

sub _insert_seq_inc {
	my ($p,%params)=@_; 
	my $colv=($p->get_binding_columns(PK_ONLY => 1))[1];
	$p->insert_binding(undef,TAG => $params{TAG},NO_PK => 1);
	$p->bind_column($colv->{COL},$colv->{VALUE} + 1,TAG => $params{TAG});
	$p;
}

sub _resolve_path {
	my ($self,$path,%params)=@_;
	my $schema=$self->{SCHEMA};
	my $tc=undef;
	my $stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	unless (defined $stack_frame) { # is the root path
		my ($ns)=$path=~/^\/([^:]+):/;
		my @schemas=($schema);
		unless (defined $self->{NSPREFIXES}) {
			affirm { defined $params{NODE_ATTRS} } "param NODE_ATTRS not set";
			my %namespaces=map  {
					my @out=();
					@out=($1,$params{NODE_ATTRS}->{$_}) if /^xmlns:([^:]+)/;
					@out;
			} keys %{$params{NODE_ATTRS}};
			$self->{NSPREFIXES}=\%namespaces;
		}
		if (defined $ns) { # path as namespace prefix
			my $namespace=$self->_find_namespace_from_abbr($ns);
			affirm { defined $namespace } "$ns: no such namespace from this namespace abbr";
			my @child_schemas=$schema->find_schemas_from_namespace($namespace);
			affirm { scalar(@child_schemas) } "$namespace: no such schema from this namespace";			
			@schemas=@child_schemas;
		}
		else {
			my $ns=$params{NODE_ATTRS}->{xmlns}; 
			my @child_schemas=$schema->find_schemas_from_namespace($ns);
			affirm { scalar(@child_schemas) } nvl($ns,'<global_namespace>').": no such schema from this namespace";
			@schemas=@child_schemas;	
		}
		for my $sc(@schemas) {
			$tc=$sc->resolve_path($path);
			if (defined $tc) {
				$self->{_PARAMS}->{CURRENT_SCHEMA}=$sc;
				last;
			}
		}
		affirm { defined $tc } "$path: path not resolved";
	}
	else {
		$tc=$self->{_PARAMS}->{CURRENT_SCHEMA}->resolve_path($path);
		affirm { defined $tc } "$path: path not resolved";
	}
	if ($self->{DEBUG}) {
		my $tag=$params{TAG};
		if (ref($tc) eq 'HASH') {
			$self->_debug($tag,$path,'mapping to column',$tc->{C}->get_full_name);
		}
		elsif (ref($tc) eq 'ARRAY') {
			$self->_debug(
				$tag
				,$path
				,"mapping to tables\n"
				,sub {
					my @out=();
					for my $i(0..scalar(@$tc) - 1) {
						my $t=$tc->[$i];
						push @out,
						  "\t\t\t"
							.$t->{T}->get_sql_name
							.(defined $t->{C} ? '.'.$t->{C}->get_sql_name : '')
							.($i == scalar(@$tc) - 1 ? '' : "\n");
					}
					return @out;
				}->()
				);
		}
		else {
			croak ref($tc).": not a hash or array";
		}
	}
	$tc;
}

sub _get_stack_frame {
	my ($self,%params)=@_;
	return unless scalar(@{$self->{STACK}});
	my $s=$self->{STACK}->[-1];
	if ($self->{DEBUG} && !$params{NOT_DEBUG}) {
		my @a=map {
			my $key=$_;
			my $p=$s->{$key};
			my @out=("$key => ");
			if (ref($p) =~/::binding$/) {
				push @out,"'".$p->get_binding_table->get_sql_name."'";
			}
			elsif (ref($p) eq '') {
				push @out,nvl($p,'<undef>');
			}
			elsif (ref($p)=~/::/) {
				push @out,"'".ref($p)."'";
			}
			elsif (grep($key eq $_,qw(INTERNAL_REFERENCE EXTERNAL_REFERENCE UNPATH_PREPARED PREPARED STACK))) {
				push  @out,ref($p);
			}
			else {
				my $v=Dumper($p);
				$v=~s/^\$VAR1\s+=\s+//;
				$v=join(" ",map { 
						my $v=$_;
						$v=~s/^\s+//;
						$v=~s/\s+$//;
						$v;
				} split("\n",$v));
				push @out,("'$v'");
			}
			@out;
		} sort keys %$s;
		$self->_debug($params{TAG},'GET STACK',@a);		
	}
	$s;
}

sub _prepared_insert {
	my ($self,$table,%params)=@_;
	affirm { defined $table } "param 1 not set"; 
	my $sqlname=$table->get_sql_name;
	$self->{PREPARED}->{$sqlname}->{INSERT}=$self->{BINDING}->get_clone
		unless defined $self->{PREPARED}->{$sqlname}->{INSERT};
	$self->{PREPARED}->{$sqlname}->{INSERT}->insert_binding(
						$table
						,TAG 				=> $params{TAG}
						,NO_PENDING_CHECK 	=> $params{NO_PENDING_CHECK}
						,PK_ID_VALUE		=> $params{PK_ID_VALUE}
	);
	$self->{PREPARED}->{$sqlname}->{INSERT};
}

sub _push {  
	my ($self,$v,%params)=@_;
	if ($self->{DEBUG}) {
		$self->_debug($params{TAG},'PUSH STACK'
			,sub {
				my $p=$v->{PREPARED};
				my @a= $p 
					? ("table ",$p->get_binding_table->get_sql_name)
					: ();
				affirm {defined $v->{PATH} } "no PATH in push";
				push @a," - path ".$v->{PATH};
				return @a;
			}->());
	}
	push @{$self->{STACK}},$v;
	$v;
}

sub _pop {
	my ($self,%params)=@_;
	affirm { scalar(@{$self->{STACK}}) > 0 } "empty stack "; 
	if ($self->{DEBUG}) {
		my $v=$self->{STACK}->[-1];
		$self->_debug($params{TAG},'POP STACK'
			,sub {
				my $p=$v->{PREPARED};
				my @a=defined $p 
					? ("table ",$p->get_binding_table->get_sql_name)
					: ();
				push @a," - path ".$v->{PATH};
				return @a;
			}->());

		my @p=$self->_execute($v,%params,CHECK_ONLY => 1);
		my $e=0;
		for my $p(@p) {
			 if ($p->is_execute_pending) {
				$self->_debug($params{TAG},'EXECUTE PENDING - table ',$p->get_binding_table->get_sql_name,' has execute pending');
				++$e;
			 }
		}
		affirm { $e == 0 } "execute pending\nkeys ".join(' ',keys(%$v));
	}
	my $stack=pop @{$self->{STACK}};
	scalar(@{$self->{STACK}}) == 0 ? undef : $self->{STACK}->[-1];
}

sub _is_equal {
	my ($self,$t1,$t2,%params)=@_;
	affirm { defined $t1 }  "param 1 not set";
	affirm { defined $t2 }  "param 2 not set";	
	my $r=$t1 == $t2 #same point r
		|| $t1->get_sql_name eq $t2->get_sql_name ? 1 : 0;
	return $r unless $self->{DEBUG};
	$self->_debug($params{TAG},'not equal ',$t1->get_sql_name,' <==> ',$t2->get_sql_name)
		unless $r;
	$r;
}

sub _execute {
	my ($self,$p,%params)=@_;
	my $r=ref($p);
	my @out=();
	if ($r eq 'HASH') {
		for my $v(values %$p) {
			push @out,$self->_execute($v,%params);
		}
	}
	elsif ($r =~ /::binding$/) {
		if ($params{CHECK_ONLY}) {
			return ($p);
		}
		else {
			if ($params{IGNORE_NOT_PENDING}) {
				$p->execute(%params) if $p->is_execute_pending;
			}
			else {
				$p->execute(%params);
			}
		}
	}
	@out;
}

sub _unpath_table {
	my ($self,$stack_frame,$tc,%params)=@_;
	affirm { $tc->{T}->is_unpath } $tc->{T}->get_sql_name."table is not an unpath sequence table";
	my $prepared_tag=$tc->{T}->get_sql_name;
	if ($stack_frame->{UNPATH_PREPARED}->{$prepared_tag}) {
		if 	($stack_frame->{UNPATH_COLSEQ}->{$prepared_tag} >= $tc->{C}->get_column_sequence) {
			$stack_frame->{UNPATH_PREPARED}->{$prepared_tag}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			_insert_seq_inc($stack_frame->{UNPATH_PREPARED}->{$prepared_tag},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}
	}
	else {
		my $sth=$self->_prepared_insert($tc->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		my ($id)=$sth->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		my $trf=$tc->{STACK}->[-1];
		my $p=$trf->{T}->is_unpath
				? $stack_frame->{UNPATH_PREPARED}->{$trf->{T}->get_sql_name}
				: $stack_frame->{PREPARED};

		$p->bind_column($trf->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});				
		$stack_frame->{UNPATH_PREPARED}->{$prepared_tag}=$sth;
	}
	$stack_frame->{UNPATH_COLSEQ}->{$prepared_tag}=$tc->{C}->get_column_sequence;
	$stack_frame->{UNPATH_PREPARED}->{$prepared_tag};
}

sub _bind_mixed_value {
	my ($self,$stack_frame,%params)=@_;
	affirm { defined $stack_frame->{MIXED} } " param MIXED not set into stack frame";
	affirm { defined $params{TAG} } " param TAG not set into stack frame";
	if (defined (my $mixed=$stack_frame->{MIXED})) {
		my $count=$mixed->{COUNT}++;
		if (length($mixed->{VALUE})) {
			my $table=$stack_frame->{PREPARED}->get_binding_table;
			my $col=$table->find_column_by_mixed_count($count);
			affirm { defined $col } "not mixed column having count $count in table ".$table->get_sql_name;
			if ($self->{DEBUG}) {
				my $v=$mixed->{VALUE};
				$v=~s/\n/\\n/g;
				$self->_debug(undef," starting number $count mixed column with value '$v'");
			}
			$stack_frame->{PREPARED}->bind_column($col,$mixed->{VALUE},TAG => $params{TAG});
			$mixed->{VALUE}='';
		}
	}
	$self;
}

sub _xmldecl_node  { 
	my ($expect,@decl)=@_;
	my $self=$expect->{LOAD_INSTANCE};
	$self->{_XMLDECL}=\@decl;
	undef;
}
									
sub _start_node { 
	my ($expect,$node,%node_attrs)=@_;
	my $self=$expect->{LOAD_INSTANCE};		
	my $current_path=$self->_decode('/'.join('/',(@{$expect->{Context}},($node))));
	$self->_debug(undef,'> (start path)',$current_path);
	my $tc=_resolve_path($self,$current_path,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},NODE_ATTRS => \%node_attrs);		
	my $stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	unless (defined $stack_frame) { # prepare the  root table if the stack is empty
		$self->{_XMLDECL}=[] unless defined $self->{_XMLDECL};
		$self->{_XMLDECL}->[1]='UTF-8' unless defined $self->{_XMLDECL}->[1]; 
		$self->{_XMLDECL}->[1]='UTF-8' if  $self->{_XMLDECL}->[1]=~/utf[\-]{0,1}8/i;		
		$self->{BINDING}->set_attrs_value(DATA_LOCALE => $self->{_XMLDECL}->[1]); # for now it's not used
		binmode(STDERR,':encoding(UTF-8)');
		my $root_table=ref($tc) eq 'ARRAY' ? $tc->[0]->{T} : $tc->{T};
		affirm { defined $root_table } "the root table is not set";
		affirm { $root_table->is_root_table } $root_table->get_sql_name.": is not a root table";
		affirm { defined  $self->{_ROOT_ID} } "_ROOT_ID not set";		
		my $insert=$self->_prepared_insert($root_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},PK_ID_VALUE => $self->{_ROOT_ID});
		$self->_push({  PREPARED => $insert,TABLE => $root_table,PATH => $current_path },TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		$stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}		
	if (ref($tc) eq 'ARRAY') {  #is a path for a table
		if (scalar(@$tc) == 2) {
			$self->_bind_mixed_value($stack_frame,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $stack_frame->{MIXED};
			my ($table,$parent_table,$parent_column)=($tc->[-1]->{T},$tc->[0]->{T},$tc->[0]->{C});			
			if ($parent_column->get_max_occurs > 1) {
				my $prepared_tag=$parent_column->get_sql_name;
				if ($stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag}) {
					_insert_seq_inc($stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #increment the value of the seq column
					$self->_bind_node_attrs($stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag},\%node_attrs,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if scalar keys %node_attrs;
				}
				else {
					my $p=$self->_prepared_insert($parent_column->get_table_reference,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$self->_bind_node_attrs($p,\%node_attrs,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if scalar keys %node_attrs;
					my ($id)=$p->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$stack_frame->{PREPARED}->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag}=$p;
				}
				my %v=(PREPARED => $self->_get_prepared_insert($table),PATH => $current_path);
				if ($table->is_mixed) {
					$v{MIXED}={ COUNT => 0,VALUE => ''};
					$self->_debug(undef,' init MIXED into frame stack for table ',$table->get_sql_name);
				}
				$stack_frame=$self->_push(\%v,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
			else {
				$self->_prepared_insert($table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				my $p=$self->_get_prepared_insert($table);
				my ($id)=$p->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				$stack_frame->{PREPARED}->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				$self->_bind_node_attrs($p,\%node_attrs,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if scalar keys %node_attrs;
				my %v=(PREPARED => $p);
				if ($table->is_mixed) {
					$v{MIXED}={ COUNT => 0,VALUE => ''};
					$self->_debug(undef,' init MIXED into frame stack for table ',$table->get_sql_name);
				}
				$v{PATH}=$current_path;
				$stack_frame=$self->_push(\%v,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
		}
		elsif (scalar(@$tc) == 3) {
			my ($gran_parent_table,$gran_parent_column)=($tc->[-3]->{T},$tc->[-3]->{C});
			my ($parent_table,$parent_column)=($tc->[-2]->{T},$tc->[-2]->{C});
			my ($curr_table,$curr_column)=($tc->[-1]->{T},$tc->[-1]->{C});
			my $parent_tag=$parent_table->get_sql_name;
			
			if ($parent_table->is_unpath) {
				if (my $p=$stack_frame->{UNPATH_PREPARED}->{$parent_tag}) {
					if 	($stack_frame->{UNPATH_COLSEQ}->{$parent_tag} >= $parent_column->get_xsd_seq) {
						$p->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						_insert_seq_inc($p,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					}
				}
				else {
					my $sth=$self->_prepared_insert($parent_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					my ($id)=$sth->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});				
					$stack_frame->{PREPARED}->bind_column($gran_parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$stack_frame->{UNPATH_PREPARED}->{$parent_tag}=$sth;
				}
				$stack_frame->{UNPATH_COLSEQ}->{$parent_tag}=$parent_column->get_xsd_seq;
			} 
			else {
				$self->_debug(undef,'(W) ',$curr_table->get_sql_name,': table is not an unpath table');
			}

			if ($self->_is_equal($stack_frame->{PREPARED}->get_binding_table,$curr_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) {
				if ($stack_frame->{COLSEQ} >= $curr_column->get_column_sequence) {
					$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					_insert_seq_inc($stack_frame->{PREPARED},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				}
				else {
					croak "not implemented\n";
				}
			}
			else {
				my $prepared_tag=$parent_column->get_sql_name;
				if ($parent_column->get_max_occurs > 1 && $stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag}) {
					_insert_seq_inc($stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #increment the value of the seq column
					my $curr_tag=$curr_table->get_sql_name;
					$stack_frame=$self->_push({  PREPARED => $self->{PREPARED}->{$curr_tag}->{INSERT},PATH => $current_path},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				}
				else {
					my $sth=$self->_prepared_insert($curr_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					my ($id)=$sth->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					if ($stack_frame->{UNPATH_PREPARED}) {
						$stack_frame->{UNPATH_PREPARED}->{$parent_tag}->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					}
					else {
						$stack_frame->{PREPARED}->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						$stack_frame->{EXTERNAL_REFERENCE}->{$prepared_tag}=$sth if $parent_column->get_max_occurs > 1;
					}
					$stack_frame=$self->_push({  PREPARED => $sth,PATH => $current_path },TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				}
			}
		}
		else {
			croak $current_path.": tc return < 2 or > 3 elements \n";				
		}
	}
	elsif ($tc->{C}->is_internal_reference) { #the column is an occurs of simple types
		$self->_debug(undef,$tc->{C}->get_full_name,' has internal reference');
		my $prepared_tag=$tc->{C}->get_sql_name;
		if (defined (my $prep=$stack_frame->{INTERNAL_REFERENCE}->{$prepared_tag})) {
			_insert_seq_inc($prep->{PREPARED},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #increment the value of the seq column
			$prep->{MIXED}->{COUNT}=0 if defined $prep->{MIXED};			
		}
		else {
			$self->_bind_mixed_value($stack_frame,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $stack_frame->{MIXED};
			my $p=$self->_prepared_insert($tc->{C}->get_table_reference,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			my ($id)=$p->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			$self->_bind_node_attrs($p,\%node_attrs,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if scalar keys %node_attrs;
			unless($self->_is_equal($stack_frame->{PREPARED}->get_binding_table,$tc->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) {
				if ($tc->{T}->is_unpath) {
					my $sth=$self->_unpath_table($stack_frame,$tc);
					$sth->bind_column($tc->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				}
				elsif ($tc->{T}->is_group_type) {
					$stack_frame=$self->_start_group_type($tc);
					$stack_frame->{PREPARED}->bind_column($tc->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				}
				else {
					$self->_debug_stack(__LINE__,INDEX => -1);
					$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					while(1) {
						$stack_frame=$self->_pop(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						last if $self->_is_equal($stack_frame->{PREPARED}->get_binding_table,$tc->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
						$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					}
					$stack_frame->{PREPARED}->bind_column($tc->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #if is set fail on test 004 						
				}
			} 
			else {
				$stack_frame->{PREPARED}->bind_column($tc->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
			my %v=(PREPARED => $p);
			if ($p->get_binding_table->is_mixed) {
				$v{MIXED}={  COUNT => 0,VALUE => ''}; 
				$self->_debug(undef,' init MIXED into frame stack for table ',$p->get_binding_table->get_sql_name);
			}
			$stack_frame->{INTERNAL_REFERENCE}->{$prepared_tag}=\%v;	
		}
		$stack_frame->{VALUE}='';
	}
	elsif (my $table_ref=$tc->{C}->get_table_reference) {
		croak $current_path.": ref to '".$tc->{C}->get_path_reference."' not implemented\n";
	} 
	else {  #normal data column
		$self->_bind_mixed_value($stack_frame,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $stack_frame->{MIXED};
		$self->_debug(undef,' starting column',$tc->{C}->get_full_name);
		$stack_frame->{VALUE}='';

		if ($tc->{T}->is_unpath) {
			$self->_debug(undef,'elab unpath table',$tc->{T}->get_sql_name);		
			my $sth=$self->_unpath_table($stack_frame,$tc);
		}
		elsif ($tc->{T}->is_group_type) {
			$self->_debug(undef,'elab group type table',$tc->{T}->get_sql_name);
			$stack_frame=$self->_start_group_type($tc);
		}
		else {
				#empty
		}
		$self->_bind_node_attrs($stack_frame->{PREPARED},\%node_attrs,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if scalar keys %node_attrs;
	}
	undef;
}  # Start

	
sub _end_node {
	my $self=$_[0]->{LOAD_INSTANCE};		
	my $current_path=$self->_decode('/'.join('/',(@{$_[0]->{Context}},($_[1]))));
	$self->_debug(undef,'< (end path)',$current_path,"\n");
	my $tc=_resolve_path($self,$current_path,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	my $stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	affirm { defined $stack_frame } "stack frame not set";
	if (ref($tc) eq 'ARRAY') { #path ref a table
		my ($parent_table,$parent_column)=($tc->[-2]->{T},$tc->[-2]->{C});
		delete $stack_frame->{INTERNAL_REFERENCE};    #for execute in error
		delete $stack_frame->{EXTERNAL_REFERENCE};    #for execute in error
		$self->_bind_mixed_value($stack_frame,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}) if defined $stack_frame->{MIXED};
		$self->_execute($stack_frame,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},IGNORE_NOT_PENDING => 1);
		if	($stack_frame->{PREPARED}->get_binding_table->is_group_type) {
			while(1) {
				$stack_frame=$self->_pop(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				last if $self->_is_equal($stack_frame->{PREPARED}->get_binding_table,$tc->[0]->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
		}
		else {
			$stack_frame=$self->_pop(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); 
		}
	}
	elsif ($tc->{C}->is_internal_reference) { #the column is an occours of simple types
		my $prepared_tag=$tc->{C}->get_sql_name;
		my $sth=$stack_frame->{INTERNAL_REFERENCE}->{$prepared_tag}->{PREPARED};
		my $value_column_idx=$sth->get_valuecol_idx;
		affirm { defined $value_column_idx } $sth->{BINDING_TABLE}->get_sql_name.": not has a VALUE_COL column";
		my $value_column=(($sth->get_binding_columns)[$value_column_idx])->{COL};
		$sth->bind_column($value_column,$stack_frame->{VALUE},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		if (defined (my $mixed=$stack_frame->{INTERNAL_REFERENCE}->{$prepared_tag}->{MIXED})) {
			$mixed->{VALUE}=delete $stack_frame->{MIXED}->{VALUE};
			$self->_bind_mixed_value($stack_frame->{INTERNAL_REFERENCE}->{$prepared_tag},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}
		$sth->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		delete $stack_frame->{VALUE};
	}
	elsif (my $table_ref=$tc->{C}->get_table_reference) {
		croak $current_path.": ref to ".$tc->{C}->get_path_reference." not implemented";
	} 
	else { #normal data column
		$self->_debug(undef,'ending column',$tc->{C}->get_full_name);
		
		if ($tc->{T}->is_unpath) {
			my $prepared_tag=$tc->{T}->get_sql_name;
			$stack_frame->{UNPATH_PREPARED}->{$prepared_tag}->bind_column($tc->{C},$stack_frame->{VALUE},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}
		else {
			if ($stack_frame->{STACK}) {					
				my $p=$stack_frame->{STACK_INDEX};
				for my $i($p..scalar(@{$stack_frame->{STACK}}) - 1) {
					my $e=$stack_frame->{STACK}->[$i];
					if ($e->{STH}->is_execute_pending) {
						$e->{STH}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					}
					else {
						$self->_debug(undef,$e->{STH}->get_binding_table->get_sql_name,': execute non pending');
					}
				}
			}
			my $value=delete $stack_frame->{VALUE};
			while (!$self->_is_equal($tc->{T},$stack_frame->{PREPARED}->get_binding_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) {  #	
				$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				$stack_frame=$self->_pop(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); 
			}
			$stack_frame->{PREPARED}->bind_column($tc->{C},$value,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}
	}
	if (scalar(@{$self->{STACK}}) == 1) { # is the frame of the root table
		$stack_frame->{PREPARED}->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); 
		$self->{ID}=($stack_frame->{PREPARED}->get_binding_values)[0];			
		$self->_debug(undef,'root row inserted with id ',$self->{ID});
		$self->_pop;
		delete $self->{NSPREFIXES}; #are cached
		delete $self->{_PARAMS}->{CURRENT_SCHEMA}; #are cached
	}
	undef;
}  #End

sub _char_node {
	my $self=$_[0]->{LOAD_INSTANCE};		
	return if scalar(@{$self->{STACK}}) < 1;
	my ($path,$value)=($self->_decode('/'.join('/',@{$_[0]->{Context}})),$self->_decode($_[1]));
	my $stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},NOT_DEBUG => 1);
	if (defined $stack_frame->{VALUE}) {
		$stack_frame->{VALUE}.=$value;
	}
	elsif (defined (my $mixed=$stack_frame->{MIXED})) {
		if ($self->{DEBUG}) {
			my $v=$value;
			$v=~s/\n/\\n/g;
			$self->_debug(undef,"value of mixed node: '$v'");
		}
		$mixed->{VALUE}.=$value;
	}
	undef;
}



sub _doctype_node {
	my ($expect,$name,$sysid,$pubid,$internal,@dummy)=@_;
	$internal=$internal ? 1: 0;
	my $self=$expect->{LOAD_INSTANCE};		
	affirm { defined  $self->{_ROOT_ID} } "_ROOT_ID not set";
	my $extra_tables=$self->{EXTRA_TABLES};
	my $table=$extra_tables->get_extra_table('DOCTYPE_TABLE');	
	my $sth=$self->_prepared_insert($table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},PK_ID_VALUE => $self->{_ROOT_ID});
	my $cols=$table->get_columns;
	my @values=($name,$sysid,$pubid,$internal);
	my $id_colseq=($table->get_pk_columns)[0]->get_column_sequence;
	affirm { defined $id_colseq } "the table ".$table->get_sql_name." not have ID pk column";
	for my $i(0..scalar(@values) - 1) {
		$sth->bind_column($cols->[$id_colseq + 1 + $i],$values[$i]);
	}
	$sth->execute;
	$table=$extra_tables->get_extra_table('DTDSEQ_TABLE');	
	$cols=$table->get_columns;
	$self->{PREPARED_DTD_NODE_DTDSEQ_TABLE}=$self->_prepared_insert($table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},PK_ID_VALUE => $self->{_ROOT_ID});
	undef;
}

sub _dtd_node {
	my ($expect,$type,@values)=@_;
	my $self=$expect->{LOAD_INSTANCE};		
	my $extra_tables=$self->{EXTRA_TABLES};
	my $prepseq=$self->{PREPARED_DTD_NODE_DTDSEQ_TABLE};
	affirm { defined $prepseq } "key PREPARED_DTD_NODE_DTDSEQ_TABLE not set\n";
	my $table=$extra_tables->get_extra_table('DTDSEQ_TABLE');	
	my $cols=$table->get_columns;	
	my $seq_colseq=($table->get_pk_columns)[1]->get_column_sequence;
	affirm { defined $seq_colseq } "the table ".$table->get_sql_name." not have SEQ pk column";
	$prepseq->bind_column($cols->[$seq_colseq + 1],$type);
	$prepseq->execute;
	
	$table=$extra_tables->get_extra_table($type);	
	my ($id,$seq)=$prepseq->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	my $sth=$self->_prepared_insert($table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},PK_ID_VALUE => $id);
	$cols=$table->get_columns;
	$seq_colseq=($table->get_pk_columns)[1]->get_column_sequence;
	affirm { defined $seq_colseq } "the table ".$table->get_sql_name." not have SEQ pk column";
	$sth->bind_column($cols->[$seq_colseq],$seq,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	for my $i(0..scalar(@values) - 1) {
		$sth->bind_column($cols->[$seq_colseq + 1 + $i],$values[$i],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	$sth->execute;
	_insert_seq_inc($prepseq,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #increment the value of the seq column
	undef;
}

sub _doctypefin_node {
	my ($expect,@dummy)=@_;
	my $self=$expect->{LOAD_INSTANCE};		
	affirm { defined  $self->{PREPARED_DTD_NODE_DTDSEQ_TABLE} } "attribute PREPARED_DTD_NODE_DTDSEQ_TABLE not set";
	affirm { defined  $self->{SCHEMA} } "SCHEMA not set";
	delete $self->{PREPARED_DTD_NODE_DTDSEQ_TABLE};
	my $extra_tables=$self->{EXTRA_TABLES};
	my @dtd_tables=map { $extra_tables->get_extra_table($_) }$extra_tables->get_extra_table_types('DTD_TABLES');
	for my $t(@dtd_tables) {
		my $sth=$self->_prepared_insert($t,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},NO_PK => 1,NO_PENDING_CHECK => 1);
		$sth->finish(NO_PENDING_CHECK => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	undef;
}

sub _notation_node {
	my ($expect,$notation,$base,$sysid,$pubid,@dummy)=@_;
	_dtd_node($expect,'NOTATION_TABLE',$notation,$base,$sysid,$pubid);
}

sub _entity_node {
	my ($expect,$name,$val,$sysid,$pubid,$ndata,$isparam,@dummy)=@_;
	$isparam=$isparam ? 1 : undef;
	_dtd_node($expect,'ENTITY_TABLE',$name,$val,$sysid,$pubid,$ndata,$isparam);
};

sub _element_node {
	my ($expect,$name,$model,@dummy)=@_;
	$model=''.$model; #convert into string
	_dtd_node($expect,'ELEMENT_TABLE',$name,$model);
}

sub _attlist_node {
	my ($expect,$elname,$attname,$type,$default,$fixed,@dummy)=@_;
	if (defined $default) { 
		$default=~s/^'//;
		$default=~s/'$//;
	}
	if (defined $fixed) {
		$fixed=~s/^'//;
		$fixed=~s/'$//;
	}
	_dtd_node($expect,'ATTLIST_TABLE',$elname,$attname,$type,$default,$fixed);
}

sub _externent_node {
	my($expect,$base,$sysid,$pubid,@dummy)=@_;
	croak "ExternEnt is not implemented\n"
}

sub _unparser_node {
	croak "set this handler is in conflict with the handle Entity\n"
}

sub _start_group_type {
	my ($self,$tc,%params)=@_;
	affirm { $tc->{T}->is_group_type } $tc->{T}->get_sql_name.": is not a group type table";
	$self->_debug(undef,"start group type for column",$tc->{C}->get_full_name);
	my $stack_frame=$self->_get_stack_frame(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); 
	if ($self->_is_equal($tc->{T},$stack_frame->{PREPARED}->get_binding_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) {  #	
		if (defined $stack_frame->{GROUP_TYPE_COLSEQ}) {
			if ($stack_frame->{GROUP_TYPE_COLSEQ} >= $tc->{C}->get_column_sequence) {
				my $sth=$stack_frame->{PREPARED};
				delete $stack_frame->{EXTERNAL_REFERENCE}; 
				$sth->execute(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				_insert_seq_inc($sth,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); #increment the value of the seq column
			}		
		}
	}
	else {
		affirm { !(scalar(@{$tc->{STACK}}) > 0 && $tc->{STACK}->[0]->{T}->is_group_type) } "bad group stack";
		if ($tc->{STACK} && scalar(@{$tc->{STACK}}) > 1) {
			my ($pt_name)=($stack_frame->{PREPARED}->get_binding_table(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})->get_sql_name);
			my $p=undef;
			for my $i(0..scalar(@{$tc->{STACK}}) - 1) {
				my $st=$tc->{STACK}->[$i];
				if ($st->{T}->get_sql_name eq $pt_name) {
					$p=$i;
					last;
				}
			}
			affirm { defined $p } "$pt_name: not found into stack";
			if ($self->{DEBUG}) {
				for my $i($p..scalar(@{$tc->{STACK}}) - 1) {
					my $st=$tc->{STACK}->[$i];
					$self->_debug(undef,"group_stack index $i for $pt_name",$st->{C}->get_full_name);
				}
			}
			$tc->{STACK}->[$p]->{STH}=$stack_frame->{PREPARED};

			for my $i($p+1..scalar(@{$tc->{STACK}}) - 1) {
				my $st=$tc->{STACK}->[$i];
				$st->{STH}=$self->_prepared_insert($st->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				my ($id)=$st->{STH}->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				my $parent=$tc->{STACK}->[$i - 1];
				$parent->{STH}->bind_column($parent->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});#
			}

			my $sth=$self->_prepared_insert($tc->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			my ($id)=$sth->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			my $parent=$tc->{STACK}->[-1];
			$parent->{STH}->bind_column($parent->{C},$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			$stack_frame=$self->_push({  PREPARED => $sth,VALUE => '',PATH => ' <group type>' },TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			$stack_frame->{STACK}=$tc->{STACK};
			$stack_frame->{STACK_INDEX}=$p + 1;
		}
		else {
			my $trf=$tc->{STACK}->[-1];
			my ($parent_table,$parent_column)=($trf->{T},$trf->{C});
			my $sth=$self->_prepared_insert($tc->{T},TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},NO_PENDING_CHECK => 1);
			my ($id)=$sth->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			if ($self->_is_equal($parent_table,$stack_frame->{PREPARED}->get_binding_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__})) { 
				$stack_frame->{PREPARED}->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				$stack_frame=$self->_push({  PREPARED => $sth,VALUE => '',PATH => '<group  type>' },TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
			}
			else {				
				my $p=$self->_search_into_stack($parent_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
				for my $i($p..scalar(@{$self->{STACK}}) - 1) {
					my $st=$self->{STACK}->[$i]->{PREPARED};
					my ($id)=$st->get_binding_values(PK_ONLY => 1,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					my $st_parent=$self->{STACK}->[$i - 1]->{PREPARED};
					my $parent_column=$self->_resolve_link($st_parent->get_binding_table,$st->get_binding_table,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
					$st_parent->bind_column($parent_column,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});#
				}
			}
		}
	}
	
	$stack_frame->{GROUP_TYPE_COLSEQ}=$tc->{C}->get_column_sequence;	
	$stack_frame;
}

sub _search_into_stack {
	my ($self,$f,%params)=@_;
	my $stack=delete $params{STACK};
	$stack=$self->{STACK} unless defined $stack;
	my $p=undef;
	if (ref($f) =~/::table$/)  {
		for my $i(0..scalar(@$stack) - 1) {
			my $st=$stack->[$i];
			if ($self->_is_equal($st->{PREPARED}->get_binding_table,$f,%params)) { 
				$p=$i;
				last;
			}
		}
	}
	elsif (ref($f) eq 'CODE') {
		for my $i(0..scalar(@$stack) - 1) {
			my $st=$stack->[$i];
			if ($f->($st)) { 
				$p=$i;
				last;
			}
		}
	}
	else {
		croak ref($f).": unknow type\n"; 
	}
	$p;
}

sub _resolve_link {
	my ($self,$t1,$t2,%params)=@_;
	my $tag=delete $params{TAG};
	my $column=$self->{SCHEMA}->resolve_column_link($t1,$t2,%params);
	if ($self->{DEBUG}) {
		$self->_debug($tag,$column->get_full_name,' => '.$t2->get_sql_name);	
	}
	$column;
}

sub _get_prepared_insert {
	my ($self,$tag,%params)=@_;
	$tag=$tag->get_sql_name if ref($tag) =~/::table$/;
	affirm { ref($tag) eq '' } "not a string or table";
	$self->{PREPARED}->{$tag}->{INSERT};
}

sub _bind_node_attrs {
	my ($self,$prep,$attrs,%params)=@_;
	my $table=$prep->get_binding_table;
	my @keys=keys %$attrs;
	my @cols=$self->{SCHEMA}->resolve_attributes($table,$self->{NSPREFIXES},@keys);
	for my $i(0..scalar(@cols) - 1) {
		my $col=$cols[$i];
		if (defined $col) {
			$prep->bind_column($col,$attrs->{$keys[$i]},%params);
		}
		else { # is system attribute
			my $col=$table->get_sysattrs_column;
			my $v=$keys[$i].'="'.$attrs->{$keys[$i]}.'"';
			$prep->bind_column($col,$v,%params,APPEND => 1,SEP => ' ');			
		}
	}
	$self;
}

sub _find_namespace_from_abbr {
	my ($self,$ns,%params)=@_;
	affirm { defined $ns } "1^ param not set";
	my $uri=$self->{NSPREFIXES}->{$ns};
	$self->_debug(undef,"$ns: no such namespace (URI) from this namespace abbr") unless defined $uri;
	$uri;
}

sub new {
	my ($class,%params)=@_;
	affirm { defined $params{BINDING} } 'param BINDING not set';
	affirm { defined $params{SCHEMA} } 'param SCHEMA not set';
	affirm { defined $params{EXTRA_TABLES} } 'param EXTRA_TABLES not set';
	
	$params{PARSER}=XML::Parser->new unless defined $params{PARSER};
	$params{PARSER}->setHandlers(
									Start 			=> \&_start_node
									,End 			=> \&_end_node
									,Char 			=> \&_char_node
									,Doctype 		=> \&_doctype_node
									,Notation 		=> \&_notation_node
									,Entity			=> \&_entity_node
									,Element		=> \&_element_node
									,Attlist		=> \&_attlist_node
									,ExternEnt 		=> \&_externent_node
									,DoctypeFin		=> \&_doctypefin_node
#									,CDataStart		=> \&_cdatastart_node
									,XMLDecl 		=> \&_xmldecl_node 
	);
	$class->SUPER::_new(%params);
}

sub read {
	my ($self,%params)=@_;
	$self->{BINDING}->set_attrs_value(SEQUENCE_NAME => $self->{EXTRA_TABLES}->get_sequence_name)
		unless defined $self->{BINDING}->get_attrs_value(qw(SEQUENCE_NAME)); 
	$self->{STACK}=[];
	$self->{ID}=undef;
	$self->{_ROOT_ID}=$self->{BINDING}->get_next_sequence;
	my $fd=nvl($params{FD},*STDIN); 
	$self->{PARSER}->parse($fd,LOAD_INSTANCE => $self);
	$self->{BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	my $id=delete $self->{ID};
	affirm { defined $id } "returning id not set"; 
	affirm { $id == $self->{_ROOT_ID}} "returning id is not equal at initialization"; 
	delete $self->{_ROOT_ID};
	delete $self->{STACK};
	my $table=$self->{EXTRA_TABLES}->get_extra_table(qw(XML_ENCODING));
	my $n=$self->{BINDING}->insert_row_from_generic(
				$table
				,[$id,$self->{_XMLDECL}->[1]]
				,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
	);
	$self->{BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});	
	affirm { defined $n && $n == 1 } "the rows inserted is not 1";
	$id;
}




1;



__END__

=head1  NAME

blx::xsdsql::xml::reader - internal class - read an xml file and put into a database

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
