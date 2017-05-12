package blx::xsdsql::xsd_parser::schema;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use File::Basename;

use base qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces);
use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::xsd_parser::path_map;


my @ATTRIBUTE_KEYS:Constant( qw(
								CATALOG_NAME 
								SCHEMA_CODE 
								LOCATION 
								URI 
								ELEMENT_FORM_DEFAULT 
								ATTRIBUTE_FORM_DEFAULT 
								ROOT_SCHEMA
								ENCODING
						) 
);


our %_ATTRS_R:Constant(());


our %_ATTRS_W:Constant(
 	CHILDS_SCHEMA_LIST	=> sub { croak "use add_child_schema to add a child schema"; }
	,MAPPING_PATH		=> sub { croak "MAPPING_PATH: this attribute is read_only"; }
	,POST_POSTED_REF	=> sub { croak "the attribute POST_POSTED_REF is reserved" }
	,TYPES				=> sub { croak "use add_types to add types"; }
	,ATTRIBUTES			=> sub { croak "use add_attrs to add attributes"; }
	,NO_FLAT_GROUPS		=> sub { croak "NO_FLAT_GROUPS: this attribute is read_only"}
	,ELEMENT_FORM_DEFAULT	=> sub {
									my ($self,$value)=@_;
									return unless defined $value;
									return 'Q' if $value eq 'qualified' || $value eq 'Q';
									return 'U' if $value eq 'unqualified' || $value eq 'U';
									croak "$value: invalid value for ELEMENT_FORM_DEFAULT";
	}
	,ATTRIBUTE_FORM_DEFAULT	=> sub {
									my ($self,$value)=@_;
									return unless defined $value;
									return 'Q' if $value eq 'qualified' || $value eq 'Q';
									return 'U' if $value eq 'unqualified' || $value eq 'U';
									croak "$value: invalid value for ATTRIBUTE_FORM_DEFAULT";
	}
	
);


sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _adj_element_ref {
	my ($self,$c,%params)=@_;
	for my $col($self->get_root_table->get_columns) {
		if ($c->get_name eq $col->get_name) {
			my $t=$col->get_attrs_value(qw(TYPE));
			$c->set_attrs_value(
					TYPE				=> $t
					,REF				=> 0
					,ELEMENT_FORM		=> 'Q' #force qualified because is a reference
			);
			if (defined (my $path_ref=$col->get_path_reference)) {
				$c->set_attrs_value(
						PATH_REFERENCE		=> $path_ref
				);
			}
			return $c;
		}
	}
	$self->_debug(undef,$c->get_name.": element ref is postposted");
	push @{$self->{POST_POSTED_REF}},$c;
	undef;
}

sub _adj_attr_ref {
	my ($self,$c,%params)=@_;
	my $name=nvl($params{NAME},$c->get_attrs_value(qw(NAME)));
	if (defined (my $ty=$self->get_global_attr($name,%params))) {
		$c->set_attrs_value(
			REF => 0
			,TYPE => $ty
			,ELEMENT_FORM		=> 'Q' #force qualified because is a reference
			);
		return $c;
	}
	$self->_debug(undef,$c->get_name.": attribute ref is postposted");
	push @{$self->{POST_POSTED_REF}},$c;
	undef;
}

sub _adj_ref {
	my ($self,$c,%params)=@_;
	if (!$params{FORCE_ADJ} && (defined (my $uri=$c->get_URI))) {
		my $name=$c->get_attrs_value(qw(NAME));
		$self->_debug(__LINE__,$uri.':'.$name," the resolution of this external ref is post posted\n");
		push @{$self->{POST_POSTED_REF}},$c;
		return;
	}
	return $c->get_attrs_value(qw(ATTRIBUTE)) ? $self->_adj_attr_ref($c,%params) : $self->_adj_element_ref($c,%params); 
}


sub _parse_group_ref {  # flat the columns of groups table  into $table
	my ($self,$table,$type_node_names,%params)=@_;
	if ($params{START_FLAG}) {
		$params{PATH}={};
		my $z=-1;
		$params{MAX_XSD_SEQ}=\$z;
		$params{START_TABLE}=$table;
	}
	my $max_xsd_seq=${$params{MAX_XSD_SEQ}};
	my $pred_xsd_seq=!$params{START_FLAG} && $params{CHOICE} ? $max_xsd_seq : undef; 
	my $fl=0;
	my @newcols=();
	for my $c($table->get_columns) {
		next if ($c->is_pk || $c->is_sys_attributes) && ! $params{START_FLAG};  #bypass the column if is the primary keys or sysattrs col  and not a start table 
		my $p=$c->get_path;
		my $nc=$params{START_FLAG} ? $c : $c->shallow_clone;

		if (defined ( my $xsd_seq=$nc->get_xsd_seq)) {  # change xsd_seq
			if (defined $pred_xsd_seq && $xsd_seq == $pred_xsd_seq) {
				$xsd_seq=$max_xsd_seq;
			}
			else  {
				$pred_xsd_seq=$xsd_seq;
				$xsd_seq=++$max_xsd_seq;
			}
			$nc->set_attrs_value(XSD_SEQ => $xsd_seq);
			unless ($params{START_FLAG}) {
				$nc->set_attrs_value(CHOICE => $params{CHOICE});
				$nc->set_attrs_value(MINOCCURS => 0) if $params{CHOICE}; 
			}
		}

		if  (!$params{START_FLAG}  && defined (my $cpath=$nc->get_path)) {  #change the path of the column
			my $path=$params{START_TABLE}->is_unpath ? $params{START_TABLE}->get_parent_path : $params{START_TABLE}->get_path;
			$path.='/'.basename($cpath) unless $nc->is_group_reference;
			$self->_debug(__LINE__,' change path of column ',$nc->get_full_name," from '$cpath' to '$path'"); 
			$nc->set_attrs_value(PATH	=> $path);
			$p=$path;
		}


		if (defined $p && !$nc->is_group_reference) {  #register new path
			if (defined (my $col=$params{PATH}->{$p})) {
				$self->_debug(__LINE__,$p,': path already register for column ',$nc->get_full_name,' - pred column is ',$col->get_full_name);
				unless ($params{START_FLAGS}) {		 # a column into a group has priority to a column with same path
					$col->set_attrs_value(DELETE => 1);	  # the pred column is marked for deletion
				}
				else {
					$self->_debug(__LINE__,$p,' the column ',$nc->get_full_name, ' is bypassed');
					next;
				}
			}
			$params{PATH}->{$p}=$nc;
		}


		if ($nc->is_group_reference && $nc->get_max_occurs <= 1) { #flat the columns of ref table into $table
			++$fl;
			my $ty=$nc->get_attrs_value(qw(TYPE))->get_attrs_value(qw(NAME));
			my $ref=$type_node_names->{$ty}->get_attrs_value(qw(TABLE));
			affirm { defined $ref } "no such table ref for column ".$c->get_full_name."(type '$ty')"; 
			$self->_debug(__LINE__,$nc->get_full_name,": the columun ref table group '",$ref->get_sql_name,"' with maxoccurs <=1 - flating  the columns of table !!");
			${$params{MAX_XSD_SEQ}}=$max_xsd_seq;
			my @cols=$self->_parse_group_ref($ref,$type_node_names,%params,START_FLAG => 0,CHOICE => $nc->is_choice);
			$max_xsd_seq=${$params{MAX_XSD_SEQ}};
			push @newcols,@cols;
		}
		else {
			push @newcols,$nc
		}
	}	   #for
	${$params{MAX_XSD_SEQ}}=$max_xsd_seq;
	return @newcols unless $params{START_FLAG};
	return unless $fl; # no group ref column
	$table->reset_columns;
	$table->add_columns(grep(!$_->get_attrs_value(qw(DELETE)),@newcols));
	undef;
}


sub _resolve_custom_types {
	my ($self,$tables,$types,%params)=@_;
	$self->_debug(__LINE__,'start resolve custom types');
	for my $t(@$tables) {
		affirm { ref($t) =~/::table$/ } ref($t).": not a table class";
		my $child_tables=$t->get_child_tables;
		$self->_resolve_custom_types($child_tables,$types,%params);
		$self->_parse_group_ref($t,$types,%params,START_FLAG => 1) unless  $self->get_attrs_value(qw(NO_FLAT_GROUPS));
		for my $c($t->get_columns) {
			next if $c->is_pk || $c->is_sys_attributes;
			$self->_adj_ref($c,%params) if $c->get_attrs_value(qw(REF));
			if (defined  (my $ctype=$c->get_attrs_value(qw(TYPE)))) {			
				if (defined (my $new_ctype=$ctype->resolve_type($types))) {
					$self->_debug(__LINE__,'col ',$c->get_full_name,' with type of type ',ref($new_ctype));
					$new_ctype->link_to_column($c,%params,TABLE => $t,SCHEMA => $self,DEBUG => $self->get_attrs_value(qw(DEBUG)));
				}
				else {
					$self->_debug(__LINE__," the resolution of type '",$ctype->get_attrs_value(qw(FULLNAME)),"' for column '",$c->get_full_name,"' is post posted"); 
				}
			}
			else {
				$self->_debug(__LINE__,$c->get_full_name.": column without type");
			}
		}
	}
	return $self;
}


sub _find_schemas_from_namespace {
	my ($self,$namespace,%params)=@_;
	my @schemas=();
	for my $h($self->get_childs_schema) {
		my ($ns,$child_schema)=map { $h->{$_} } qw(NAMESPACE SCHEMA);
		push @schemas,$child_schema if nvl($ns) eq nvl($namespace);
		push @schemas,$child_schema->_find_schemas_from_namespace($namespace,%params,);
	}
	return wantarray ?  @schemas : \@schemas;
}


sub get_root_table {
	my ($self,%params)=@_;
	return $self->get_attrs_value(qw(TABLE));
}


sub get_types_name {
	my ($self,%params)=@_;
	my $types=$self->{TYPE_NAMES};
	return unless defined $types;
	return wantarray ? %$types : $types;
}


sub get_dictionary_data {
	my ($self,$dictionary_type,%params)=@_;
	affirm { defined $dictionary_type }  "1^ param not set";
	affirm { $dictionary_type eq 'SCHEMA_DICTIONARY' } "1^ param must be set to 'SCHEMA_DICTIONARY' value";	
	my %data=map { ($_ eq 'URI' ? $_ : lc($_),$self->get_attrs_value($_)); } @ATTRIBUTE_KEYS;
	for my $k(qw(CATALOG_NAME SCHEMA_CODE)) {
		affirm { defined $params{$k} && length($params{$k})} "$k: param not set";
		my $k1=lc($k);
		affirm { exists $data{$k1}  } "$k: key not found in data"; 
		$data{$k1}=$params{$k};
	}
	$data{location}=$params{LOCATION};
	return wantarray ? %data : \%data;
}

sub factory_from_dictionary_data {
	my ($data,%params)=@_;
	affirm { ref($data) eq 'ARRAY' } "the 1^ param must be array";
	affirm { scalar(@$data) == scalar(@ATTRIBUTE_KEYS) } "the attributes number is not equal to keys number"; 
	my %data=map {  ($ATTRIBUTE_KEYS[$_],$data->[$_])  } (0..scalar(@$data) - 1);
	return __PACKAGE__->new(%params,%data);
}


sub get_childs_schema {
	my ($self,%params)=@_;
	my $a=$self->{CHILDS_SCHEMA_LIST};
	return wantarray ? @$a : $a;
}

sub get_global_attr {
	my ($self,$name,%params)=@_;
	return $self->{ATTRIBUTES}->{$name};
}

sub add_attrs {
	my $self=shift;
	for my $col(@_) {
		my ($name,$type)=map { $col->get_attrs_value($_); }(qw(NAME TYPE));
		next if defined $self->{ATTRIBUTES}->{$name};
		$self->{ATTRIBUTES}->{$name}=$type;
	}
	$self;
}

sub add_attributes_group {
	my $self=shift;
	for my $table(@_) {
		my $name=$table->get_name;
		affirm { $table->get_attrs_value(qw(ATTRIBUTE_GROUP)) }  "$name: this table is not an ATTRIBUTE_GROUP table";
		$self->{ATTRIBUTES_GROUP}->{$name}=$table;
	}
	$self;
}

sub resolve_attributes {
	my ($self,$table,$nsprefixes,@attrnames)=@_;
	$self->{MAPPING_PATH}->resolve_attributes($table,$nsprefixes,@attrnames);
}

sub find_schemas_from_namespace {
	my ($self,$namespace,%params)=@_;
	my @schemas=();
	push @schemas,$self if nvl($self->get_attrs_value(qw(URI))) eq nvl($namespace);
	push @schemas,$self->_find_schemas_from_namespace($namespace,%params);	
	$self->_debug(undef,nvl($namespace,'<global_namespace>').": not find schemas from this namespace") unless scalar(@schemas);
	return wantarray ?  @schemas : \@schemas;
}

sub add_child_schema {
	my ($self,$child_schema,$ns,$location)=@_;
	affirm { defined $child_schema } "1^ param not set";
	affirm { defined $location } "3^ param not set";
	unless (defined $child_schema->get_attrs_value(qw(SCHEMA_CODE))) {
		my $schema_code=$self->get_attrs_value(qw(SCHEMA_CODE));
		affirm { defined $schema_code } "attribute SCHEMA_CODE not set";
		$schema_code .='_'.scalar(@{$self->{CHILDS_SCHEMA_LIST}});
		$child_schema->set_attrs_value(SCHEMA_CODE => $schema_code);
	}
	$child_schema->set_attrs_value(CHILD_SCHEMA => 1);  
	$self->_debug(__LINE__,'add child_schema from location ',$location,' and namespace ',$ns);
	push @{$self->{CHILDS_SCHEMA_LIST}},{  SCHEMA => $child_schema,NAMESPACE => $ns,LOCATION => $location };
	return $self;
}

sub add_types {
	my $self=shift;
	push @{$self->{TYPES}},@_;
	return $self;
}



sub mapping_paths {
	my ($self,$type_paths,%params)=@_;
	affirm { ref($type_paths) eq 'HASH' } "1^ param must be a hash";
	my $root=$self->get_root_table;
	affirm { ref($root)=~/::table$/ } ref($root).": is not a table class";
	$self->{MAPPING_PATH}->mapping_paths($root,$type_paths,%params);
	return $self;
}


sub set_types {
	my ($self,%params)=@_;
	my $types=$self->get_attrs_value(qw(TYPES));
	my @type_tables=map { my $t=$_->get_attrs_value(qw(TABLE)); defined $t ? $t : (); }  @$types;

	my %type_node_names=map  {  
		affirm { defined $_ } "element not set";
		my $name=$_->get_attrs_value(qw(name));
		$name=$_->get_attrs_value(qw(NAME)) unless defined $name;
		affirm { defined $name } "name not set ".ref($_);
		($name,$_); 		
	} @$types;
		
	$self->_resolve_custom_types(\@type_tables,\%type_node_names,%params);
	$self->_resolve_custom_types([$self->get_root_table],\%type_node_names,%params);
	$self->_resolve_custom_types([values(%{$self->{ATTRIBUTES_GROUP}})],\%type_node_names,%params);

	my %type_table_paths=map {  my $path=$_->get_attrs_value(qw(PATH)); defined $path ? ($path,$_) : ();  } @type_tables;
	$self->{TYPE_NAMES}={ map {  my $name=$_->get_attrs_value(qw(NAME)); defined $name ? ($name,$_) : ();  } @type_tables  };     
	$self->{TYPE_PATHS}={ map {  my $path=$_->get_attrs_value(qw(PATH)); defined $path ? ($path,$_) : ();  } @type_tables };
	$self->{TYPE_NODE_NAMES}=\%type_node_names;
	return $self;
}

sub get_types_path {
	my ($self,%params)=@_;
	my $types=$self->{TYPE_PATHS};
	return unless defined $types;
	return wantarray ? %$types : $types;
}	



sub resolve_path {
	my ($self,$path,%params)=@_;
	$self->{MAPPING_PATH}->resolve_path($path,%params);
}


sub resolve_column_link {
	my ($self,$t1,$t2,%params)=@_;
	$self->{MAPPING_PATH}->resolve_column_link($t1,$t2,%params);
}

sub new {
	my ($class,%params)=@_;
	my $self=bless {
		CHILDS_SCHEMA_LIST		=> []
		,MAPPING_PATH			=> blx::xsdsql::xsd_parser::path_map->new(DEBUG => $params{DEBUG})
		,POST_POSTED_REF 		=> []
		,TYPES					=> []
		,ATTRIBUTES				=> {}
		,NO_FLAT_GROUPS			=> delete $params{NO_FLAT_GROUPS}
	},$class;
	$self->set_attrs_value(%params);
}



1;

__END__


=head1  NAME

blx::xsdsql::xsd_parser::schema -  mapping xsd schema

=cut

=head1 SYNOPSIS

use blx::xsdsql::xsd_parser::schema

=cut


=head1 DESCRIPTION

this package is a class - is instanciated from  package blx::xsdsql::xsd_parser




=head1 EXPORT

None by default.


=head1 EXPORT_OK

None


=head1 SEE ALSO

blx::xsdsql::xsd_parser - parse an xsd file

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut





