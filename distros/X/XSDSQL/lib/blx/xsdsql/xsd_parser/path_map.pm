package blx::xsdsql::xsd_parser::path_map;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);

      
use base(qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::ios::debuglogger));

use constant {
	STD_NAMESPACE		=>  'http://www.w3.org/2001/XMLSchema-instance' 
};


our %_ATTRS_R:Constant(());
our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) }
		qw(
			LINK_TABLES
			ATTRS
			TC
		)
);

sub _get_attrs_r {  return \%_ATTRS_R; }
sub _get_attrs_w {  return \%_ATTRS_W; }


sub _register_attribute {
	my ($self,%params)=@_;
	my $tag=$params{TAG};
	$self->_debug($tag,'register column attribute ',$params{C}->get_name,' with (',$params{C}->get_full_name,')');
	$params{ATTRIBUTES}->{$params{T}->get_sql_name}->{$params{C}->get_name}=$params{C};
	return $self;
}

sub _link_tables {  # link column $t1.$c1 => $t2.id 
	my ($self,$t1,$c1,$t2,%params)=@_;
	$self->{LINK_TABLES}->{$t1->get_sql_name}->{$t2->get_sql_name}=$c1;
	return $self;
}

sub _register_path {
	my ($self,%params)=@_;
	my $tag=$params{TAG};
	my $path=defined $params{C}  
		? $params{C}->get_attrs_value(qw(PATH))
		: $params{T}->get_attrs_value(qw(PATH));
		
	if ($params{ORIG_PATH_NAME}) {
		$path=$self->_resolve_relative_path($params{ORIG_PATH_NAME},$params{T},$path,%params);
	}
	else {
		affirm { !$params{T}->is_type } "$tag: ORIG_PATH_NAME not set for type table";
	}
	affirm { defined $path && length($path) }  "path not set";

	my $ret=sub {
		if (defined $params{C}) { #map path into a column
			my $h={ T => $params{T},C => $params{C}};
			my @stack=@{$params{STACK}};
			$h->{STACK}=\@stack if $params{T}->is_unpath || $params{T}->is_group_type; 
			$self->_debug($tag,'register column path ',$path,' with (',$params{C}->get_full_name,')');
			return $h;
		}
		else { #map path into a tables stack 
			$params{STACK}=[] unless defined $params{STACK};
			push @{$params{STACK}},{ T => $params{T} };
			$self->_debug($tag,'register table path ',$path,' with ('.
				join(',',map { $_->{T}->get_sql_name.(defined $_->{C} ? '.'.$_->{C}->get_sql_name : '') } @{$params{STACK}})
				.')');
			return $params{STACK};
		}
		affirm { 0 } "dead code";
		undef;
	}->();

	if (my $tc=$params{PATH}->{$path}) {  #path is already register
		if ($self->{DEBUG}) {  #check the consistence $tc and $ret
			$self->_debug($tag,"$path: path already register");
			if (ref($tc) eq 'ARRAY' && ref($ret) ne 'ARRAY') {
				$self->_debug(__LINE__,$tc->[-1]->{T}->get_sql_name,$ret->{C}->get_full_name);
				confess "check consistence 1 failed\n";
			}
			confess "check consistence 2 failed " if ref($tc) eq 'HASH' && ref($ret) ne 'HASH';
			if (ref($tc) eq 'ARRAY' && $tc->[-1]->{T}->get_sql_name ne $ret->[-1]->{T}->get_sql_name) {
				$self->_debug(__LINE__,$tc->[-1]->{T}->get_sql_name);
				$self->_debug(__LINE__,$tc->[-1]->{T}->get_path);
				$self->_debug(__LINE__,$ret->[-1]->{T}->get_sql_name);
				$self->_debug(__LINE__,$ret->[-1]->{T}->get_path);
			}

			confess "check consistence 3 failed " if ref($tc) eq 'ARRAY' && $tc->[-1]->{T}->get_sql_name ne $ret->[-1]->{T}->get_sql_name;

			if (ref($tc) eq 'HASH' && $tc->{C}->get_full_name ne $ret->{C}->get_full_name) {
				$self->_debug(__LINE__,$tc->{C}->get_full_name,$ret->{C}->get_full_name);
				$self->_debug(__LINE__,$ret->{T}->get_sql_name,$ret->{T}->is_group_type);
				$self->_debug(__LINE__,$tc->{T}->get_sql_name,$tc->{T}->is_group_type);
				$self->_debug(__LINE__," consistence 4 failed");
			}

			confess "check consistence 4 failed " if ref($tc) eq 'HASH' && $tc->{C}->get_full_name ne $ret->{C}->get_full_name;
		}
	}
	else {
		my $p=$params{PATH};
		$p->{$path}=$ret;
		if (my $ns=$params{XML_NAMESPACES}) {
			for my $n(@$ns) {
				next if $n eq 'xs';
				my $newpath=join('/',map {  length($_) ? $n.':'.$_ : $_;    } split('/',$path));
				$p->{$newpath}=$ret;
			}
		}
	}

	return $path;	
}


sub _resolve_path_ref {
	my ($self,$table,$col,$path_ref,%params)=@_;
	$self->_debug($params{TAG},'col',"'".$col->get_full_name."'","ref path  '$path_ref'");
	my $tab_ref=$params{TYPE_PATHS}->{$path_ref};
	return $tab_ref if defined $tab_ref;
	for my $child($table->get_child_tables) {
		return $child if nvl($child->get_attrs_value('PATH'),'') eq $path_ref;
	}
	for my $t($params{ROOT_TABLE}->get_child_tables) {
		return $t if nvl($t->get_path,'') eq $path_ref;
	}
	undef;
}

sub _resolve_table_path {
	my ($self,$t,%params)=@_;
	my $x=-1; 
	while(!$t->get_attrs_value(qw(PATH))) {
		$t=$params{STACK}->[$x--]->{T};
	}
	return $t;
}

sub _resolve_relative_path {
	my ($self,$startpath,$table,$relative_path,%params)=@_;
	affirm { defined $startpath } "1 param not set";
	affirm { defined $table } "2 param not set";
	affirm { defined $relative_path } "3 param not set";	
	my $path=$startpath.substr($relative_path,length($self->_resolve_table_path($table,%params)->get_attrs_value(qw(PATH))));
	return $path;
}

sub _mapping_path {
	my ($self,$table,%params)=@_;
	my $tag=$params{TAG};
	if ($table->get_path && !$table->is_group_type) {
		$self->_register_path(%params,T => $table,C => undef,TAG => __LINE__);
		$params{STACK}=[];
	}

	for my $col($table->get_columns) {
		next if $col->is_pk || $col->is_sys_attributes;
		if ($col->is_attribute) {
			$self->_register_attribute(%params,T => $table,C => $col,TAG => __LINE__);
			next;
		}
		my ($path_ref,$table_ref)=$col->get_attrs_value(qw(PATH_REFERENCE TABLE_REFERENCE));
		if (defined $path_ref || defined $table_ref) {
			if (defined $table_ref) {  #the column ref a table
				if ($col->is_internal_reference) {
					$self->_register_path(%params,T => $table,C => $col,TAG => __LINE__);
					if ($table_ref->is_simple_content_type)  {
						for my $col($table_ref->get_columns) {
							next unless $col->is_attribute;
							$self->_register_attribute(%params,T => $table_ref,C => $col,TAG => __LINE__);
						}
					}
				}
				else {
					$self->_link_tables($table,$col,$table_ref);
					my $orig_path_name=$params{ORIG_PATH_NAME};
					if (my $path=$col->get_path) {

						$orig_path_name=$self->_resolve_relative_path(
							nvl($params{ORIG_PATH_NAME},$self->_resolve_table_path($table,%params)->get_path)
							,$table
							,$path
							,%params
							,TAG => __LINE__
						);
							
					}
					my @stack=({ T =>  $table,C => $col });
					@stack=(@{$params{STACK}},@stack) if ! $table->get_path || $table->is_group_type;				
					$self->_mapping_path($table_ref,%params,STACK => \@stack,ORIG_PATH_NAME => $orig_path_name);
				}
			}
			else {	# the column ref a path of an unknow table				
				affirm { !$col->is_internal_reference }  nvl($tag).": the column has internal reference and table_ref is not a table: '".$col->get_full_name."'";
				my $t=$self->_resolve_path_ref($table,$col,$path_ref,%params,TAG => __LINE__);
				affirm { defined $t } "$path_ref: path not resolved from '".$col->get_full_name."'";
				$self->_link_tables($table,$col,$t);
				$col->set_attrs_value(TABLE_REFERENCE => $t);
				my $orig_path_name=$params{ORIG_PATH_NAME};
				if (my $path=$col->get_path) {
					$orig_path_name=$self->_resolve_relative_path(
						nvl($params{ORIG_PATH_NAME},$table->get_attrs_value(qw(PATH)))
						,$table
						,$path
						,%params
						,TAG => __LINE__
					); 
				}
				my @stack=({ T =>  $table,C => $col });
				@stack=(@{$params{STACK}},@stack) if ! $table->get_path || $table->is_group_type;				
				$self->_mapping_path($t,%params,STACK => \@stack,ORIG_PATH_NAME => $orig_path_name);
			}
		}
		else {
			$self->_register_path(%params,T => $table,C => $col,TAG => __LINE__) if defined $col->get_path;
		}
	}
	undef;
}

sub mapping_paths {
	my ($self,$root_table,$type_paths,%params)=@_;
	affirm { ref($root_table) =~/::table$/ } ": 1^ param must be a table";
	affirm { ref($type_paths) eq 'HASH' } ": 2^ param must be hash";
	my %path_translate=();
	my %attr_translate=();
	$self->_mapping_path(
		$root_table
		,PATH => \%path_translate
		,TYPE_PATHS => $type_paths
		,STACK => []
		,ATTRIBUTES => \%attr_translate
		,ROOT_TABLE => $root_table
	);
	$self->{TC}=\%path_translate;
	$self->{ATTRS}=\%attr_translate;
	$self;
}



sub _manip_path {
	my ($self,$path,%params)=@_;
	return $path unless $path=~/:/;  # no  namespace specificied 
	my @p=map {
		my $out=$_;
		$out=$2 if /^([^:]+):(.*)$/;
		$out;
	}	grep(length($_),split('/',$path));
	return  '/'.join('/',@p);
}

sub resolve_path { #return an array if resolve into tables otherwise an hash
	my ($self,$path,%params)=@_;
	affirm { defined $path } "1^ arg not set";
	my $p=$self->_manip_path($path,%params);
	affirm { defined $p} "_manip_path return undef";
	my $a=$self->{TC}->{$p};
	$self->_debug($params{TAG},"$p: path not resolved - orig path is '$path'") unless defined $a;
	$a;
}


sub resolve_attributes {
	my ($self,$table,$nsprefixes,@attrnames)=@_;
	affirm { defined $table } "1^ param not set";
	affirm { ref($nsprefixes) eq 'HASH' } "2^ param is not HASH"; 
	my $table_name=$table->get_sql_name;
	$self->_debug(undef,'attributes: ',keys %{$self->{ATTRS}->{$table_name}});
	my @cols=map {
		my $fullname=$_;
		my $out=undef;
		if ($fullname!~/^xmlns:/ && $fullname ne 'xmlns') {
			my ($ns,$name)=$fullname=~/^([^:]+):([^:]+)$/;
			if (defined $ns) {
				affirm { defined $nsprefixes->{$ns} } "$ns: prefix not know";
				if ($nsprefixes->{$ns} ne STD_NAMESPACE) {
					$out=$self->{ATTRS}->{$table_name}->{$name};
					affirm {defined $out } "$name: not found column for this attribute in table '$table_name'"; 
				}
			}
			else {
				$out=$self->{ATTRS}->{$table_name}->{$fullname};
				affirm {defined $out } "$fullname: not found column for this attribute in table '$table_name'"; 
			}
		}
		$out;
	} @attrnames;
	return @cols if wantarray;
	return scalar(@cols) <= 1 ? $cols[0] : \@cols;
}

sub resolve_column_link {
	my ($self,$t1,$t2,%params)=@_;
	my ($n1,$n2)=($t1->get_sql_name,$t2->get_sql_name);
	my $col=$self->{LINK_TABLES}->{$n1}->{$n2};
	affirm { defined $col }  "$n1 => $n2: link not resolved"; 
	$col;
}

sub new {
	my ($classname,%params)=@_;
	my $self=bless {},$classname;
	$self->set_attrs_value(%params);
	$self;
}


1;

__END__

=head1  NAME

blx::xsdsql::xsd_parser::path_map  - internal class for parsing schema

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
