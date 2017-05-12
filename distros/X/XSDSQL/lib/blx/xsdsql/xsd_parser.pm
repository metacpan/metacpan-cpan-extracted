package blx::xsdsql::xsd_parser;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use File::Basename;
use XML::Parser;

use blx::xsdsql::xsd_parser::node;
use blx::xsdsql::ut::ut qw(nvl ev);
use blx::xsdsql::xsd_parser::schema;
use blx::xsdsql::schema_repository::extra_tables;

use base qw(blx::xsdsql::ut::common_interfaces blx::xsdsql::ios::debuglogger Exporter);


use constant {
	USER_SCHEMA_CLASS					=>  'blx::xsdsql::xsd_parser::schema'
};

my @ATTRIBUTE_KEYS:Constant(qw(
			OUTPUT_NAMESPACE 
			DB_NAMESPACE 
			DEBUG
			EXTRA_TABLES
			TABLE_CLASS 
			COLUMN_CLASS
	)
);

my @ATTRIBUTE_KEYS_RESERVED:Constant(qw(
		STACK
		SCHEMA_OBJECT
		DICTIONARIES
		SCHEMA_OBJECT
	)
);

my  %t=( overload => [ qw ( USER_SCHEMA_CLASS )]);

our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=qw( );

our %_ATTRS_R:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is reserved"}) } @ATTRIBUTE_KEYS_RESERVED
);

our %_ATTRS_W:Constant(
	(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } @ATTRIBUTE_KEYS
	,map { my $a=$_;($a,sub {  croak $a.": this attribute is reserved"}) } @ATTRIBUTE_KEYS_RESERVED
	)
);


sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


sub _push {  
	my ($self,$v,%params)=@_;
	push @{$self->{STACK}},$v;
	return $v;
}

sub _pop {
	my ($self,%params)=@_;
	affirm { scalar(@{$self->{STACK}}) > 0 } "empty stack";
	pop @{$self->{STACK}};
	return scalar(@{$self->{STACK}}) == 0 ? undef : $self->{STACK}->[-1];
}

sub _get_stack {
	my ($self,%params)=@_;
	affirm { scalar(@{$self->{STACK}}) > 0 } "empty stack";
	my $s=$self->{STACK}->[-1];
	return $s;
}


sub _to_obj {
	my ($self,$tag,%params)=@_;
	return blx::xsdsql::xsd_parser::node::factory_object($tag,%params);
}

sub _decode {
	my $self=shift;
	return $_[0] if scalar(@_) <= 1;
	return @_;
}

my %H=(
		Start => sub { 
			my ($expect,$node,%attrs)=@_;
			my $self=$expect->{LOAD_INSTANCE};
			my @params=(%{$expect->{PARAMS}},ATTRIBUTES => \%attrs);
			push @params,map {  ($_,$self->{$_}) } grep(ref($self->{$_}) eq '',keys %$self);
			my $stack=$self->get_attrs_value(qw(STACK));			
			my $obj=$self->_to_obj($node,@params,STACK => $stack,EXTRA_TABLES => $self->{EXTRA_TABLES});
			$self->_debug(__LINE__,'> (start path)',$obj->get_attrs_value(qw(PATH))," with type ",ref($obj));
			$obj->trigger_at_start_node(%{$expect->{PARAMS}},PARSER => $self);
			if (ref($obj) =~/::schema$/) {
				$stack->[1]=$obj;
			}
			else {
				$self->_push($obj);
			}
			undef;
		}
		,End => sub {
			my ($expect,$node,%attrs)=@_;
			my $self=$expect->{LOAD_INSTANCE};
			my $obj=$self->_get_stack;
			$self->_debug(__LINE__,'< (end path)',$obj->get_attrs_value(qw(PATH))," with type ",ref($obj));
			$obj->trigger_at_end_node;
			if (ref($obj) =~ /::schema$/) {
				$obj->set_attrs_value(
							XMLDECL  => $self->get_attrs_value(qw(STACK))->[0]
				);
				$self->{SCHEMA_OBJECT}=$obj;
			}
			else {
				if (ref($obj)=~/Type$/ && (defined (my $name=$obj->get_attrs_value(qw(name))))) {
					$self->_debug(__LINE__,"type '$name' add to know types"); 
					$self->get_attrs_value(qw(STACK))->[1]->add_types($obj);
				}
				$self->_pop;
			}
			undef;
		}
		,XMLDecl => sub { 
			my ($expect,@decl)=@_;
			my $self=$expect->{LOAD_INSTANCE};
			$self->_push(\@decl);
		}
# 		,Char => sub { x("Char",@_); }
# 		,Proc => sub { x_("Proc",@_); }
# 		,Comment => sub { x("Comment",@_); }
# 		,CdataStart => sub { x_("CdataStart",@_); }
# 		,CdataEnd => sub { x_("CdataEnd",@_); }
# 		,Default => sub { x("Default",@_); }
# 		,Unparsed => sub { x_("Unparsed",@_); }
# 		,Notation => sub { x_("Notation",@_); }
# 		,ExternEnt => sub { x_("ExternEnt",@_); }
# 		,ExternEntFin => sub { x_("ExternEntFin",@_); }
# 		,Entity => sub { x_("Entity",@_); }
# 		,Element => sub { x_("Element",@_); }
# 		,Attlist => sub { x_("Attlist",@_); }
# 		,Doctype => sub { x_("Doctype",@_); }
# 		,DoctypeFin => sub { x_("DoctypeFin",@_); }
);

sub _resolve_postposted_types {
	my ($self,$tables,$types,%params)=@_;
	$self->_debug(__LINE__,'start resolve postposted types');
	for my $t(@$tables) {
		my $child_tables=$t->get_child_tables;
		$self->_resolve_postposted_types($child_tables,$types,%params);
		for my $c($t->get_columns) {
			next if $c->is_pk || $c->is_sys_attributes;
			my $ctype=$c->get_attrs_value(qw(TYPE));
			affirm { defined $ctype } $c->get_full_name.": column without type";
			next if defined $ctype->resolve_type($types);
			my $type_fullname=$ctype->get_attrs_value(qw(FULLNAME));
			$self->_debug(__LINE__,'column  ',$c->get_full_name,' with type ',$type_fullname);
			if (defined (my $new_ctype=$ctype->resolve_external_type($params{SCHEMA}))) {
				$new_ctype->link_to_column($c,%params,TABLE => $t,DEBUG => $self->get_attrs_value(qw(DEBUG)));
			}
			else {
				my $new_ctype=$self->_resolve_recursive_external_type($ctype,$params{ROOT_SCHEMA});
				affirm { defined $new_ctype } "$type_fullname: failed the external resolution";
				$new_ctype->link_to_column($c,%params,TABLE => $t,DEBUG => $self->get_attrs_value(qw(DEBUG)));					
			}
		}
	}
	return $self;
}

sub _recursive_resolution {
	my ($self,$schema,%params)=@_;	
	for my $h($schema->get_childs_schema) {
		$self->_recursive_resolution($h->{SCHEMA},%params);
	}
	$self->_resolve_postposted_ref($schema,%params,NO_ATTRIBUTE_GROUP => 1);
	my $types_name=$schema->get_types_name;
	my $types=[values(%$types_name)];
	$self->_resolve_postposted_ref($schema,%params,NO_ATTRIBUTE_GROUP => 0);
	$self->_resolve_postposted_types($types,$types_name,%params,SCHEMA => $schema);
	$self->_resolve_postposted_types([$schema->get_root_table],$types_name,%params,SCHEMA => $schema);	
	return $self;
}

sub _resolve_postposted_ref {
	my ($self,$schema,%params)=@_;
	my $list=$schema->get_attrs_value(qw(POST_POSTED_REF));
	return $self unless @$list;
	for my $c(@$list) {
		if ($c->get_attrs_value(qw(ATTRIBUTE_GROUP))) {
			next if $params{NO_ATTRIBUTE_GROUP};
			my $table=$schema->get_attrs_value(qw(ATTRIBUTES_GROUP))->{$c->get_name};
			unless (defined $table) {
				my ($uri,$name)=$c->get_attrs_value(qw(URI NAME));
				$uri=$schema->get_attrs_value(qw(URI)) unless defined $uri;
				$table=$self->_resolve_recursive_external_ref($c,$params{ROOT_SCHEMA},$uri,%params);
				affirm { defined $table } "($uri,$name): failed ref resolution";
			}
			my $parent_table=$c->get_attrs_value(qw(TABLE_NAME));
			my @columns=$parent_table->reset_columns;
			my @new_cols=();
			my $fl=0;
			for my $col(@columns) {
				if ($col->get_name eq $c->get_name) {
					push @new_cols,map { 
							my $c=$_->clone;
							$c->{TYPE}=$_->{TYPE};
							affirm { defined $c->get_attrs_value(qw(TYPE)) } 
								$c->get_full_name.': not TYPE attribute set';
							$c;
					} grep { ! $_->get_attrs_value(qw(SYS_ATTRIBUTES)) } $table->get_columns;
					$fl=1;
				}
				else {
					push @new_cols,$col;
				}
			}
			$self->_debug(undef,$c->get_name,': not column added') unless defined $fl;
#			affirm { $fl } "not columns added";
			$parent_table->add_columns(@new_cols);
		}
		else {
			my ($uri,$name)=$c->get_attrs_value(qw(URI NAME));
			$uri=$schema->get_attrs_value(qw(URI)) unless defined $uri;
			my $new_c=$self->_resolve_recursive_external_ref($c,$params{ROOT_SCHEMA},$uri,%params);
			affirm { defined $new_c } "($uri,$name): failed ref resolution";
		}
	}
	return $self;
}


sub _resolve_recursive_external_type {
	my ($self,$ctype,$schema,%params)=@_;	
	if ($schema->get_attrs_value(qw(URI)) eq $ctype->get_attrs_value(qw(URI))) {
		my $types=$schema->get_attrs_value(qw(TYPES));
		my %type_node_names=map  {  ($_->get_attrs_value(qw(name)),$_); } @$types;
		my $name=$ctype->get_attrs_value(qw(NAME));
		if (defined (my $t=$type_node_names{$name})) {
			$self->_debug(__LINE__,'factory type from object type ',ref($t));
			my $new_ctype=$t->factory_type($t,\%type_node_names,%params);
			return $new_ctype if defined $new_ctype;
		}
	}
	for my $h($schema->get_childs_schema) {
		my $new_ctype=$self->_resolve_recursive_external_type($ctype,$h->{SCHEMA},%params);
		return $new_ctype if defined $new_ctype;
	}
	$self->_debug(__LINE__,$ctype->get_attrs_value(qw(FULLNAME)).': failed the external resolution');
	undef;
}

sub _resolve_recursive_external_ref {
	my ($self,$ref,$schema,$ns,%params)=@_;	
	if (nvl($schema->get_attrs_value(qw(URI))) eq nvl($ns)) {
		if ($ref->get_attrs_value(qw(ATTRIBUTE))) {
			my $name=$ref->get_attrs_value(qw(NAME));
			my $ty=$schema->get_global_attr($name,%params);
			if (defined $ty) {
				$ref->set_attrs_value(
					REF => 0
					,TYPE => $ty
					,ELEMENT_FORM		=> 'Q' #must be qualified because ref to external					
				);
				return $ref;
			}
		}
		elsif ($ref->get_attrs_value(qw(ATTRIBUTE_GROUP))) {
			affirm { 0 } "not implemented";
		}
		else { #is an element ref
			for my $col($schema->get_root_table->get_columns) {
				if ($ref->get_name eq $col->get_name) {
					$ref->set_attrs_value(
							TYPE				=> $col->get_attrs_value(qw(TYPE))
							,REF				=> 0
							,ELEMENT_FORM		=> 'Q' #must be qualified because ref to external
					);
					if (defined (my $path_ref=$col->get_path_reference)) {
						$ref->set_attrs_value(
								PATH_REFERENCE		=> $path_ref
						);
					}
					return $ref;
				}
			}
		}
	}
	for my $h($schema->get_childs_schema) {
		my $new_ref=$self->_resolve_recursive_external_ref($ref,$h->{SCHEMA},$ns,%params);
		return $new_ref if defined $new_ref;
	}
	$self->_debug(__LINE__,$ref.': failed the external resolution');
	undef;
}

sub _recursive_mapping_path {
	my ($self,$schema,%params)=@_;	
	for my $h($schema->get_childs_schema) {
		$self->_recursive_mapping_path($h->{SCHEMA},%params);
	}
	my $type_table_paths=$schema->get_types_path;
	$schema->mapping_paths($type_table_paths,%params);
	return $self;
}

sub _recursive_change_schema_class {
	my ($self,$schema,%params)=@_;	
	for my $h($schema->get_childs_schema) {
		$self->_recursive_change_schema_class($h->{SCHEMA},%params);
	}
	$schema->set_attrs_value(%{$params{DICTIONARIES}});
	bless $schema,USER_SCHEMA_CLASS;
	return $self;
}


sub _parse {
	my ($self,%params)=@_;
	$params{PARSER}->setHandlers(%H);
	$self->{STACK}=[];
	$params{PARSER}->parse($params{FD},LOAD_INSTANCE => $self,PARAMS => \%params);
	delete $self->{STACK};
	return delete $self->{SCHEMA_OBJECT};
}

sub _parsefile {
	my ($self,$file_name,%params)=@_;
	affirm { defined $file_name } "1^ param not set";
	my $p=$self->_fusion_params(%params);
	for my $k(qw(TABLE_CLASS COLUMN_CLASS)) {
		$p->{$k}=$self->{$k};
	}
	for my $k(qw(TABLE_PREFIX VIEW_PREFIX)) {
		$p->{$k}='' unless defined $p->{$k};
	}
	
	$p->{TABLENAME_LIST}={} unless ref($p->{TABLENAME_LIST}) eq 'HASH';
	$p->{CONSTRAINT_LIST}={} unless ref($p->{CONSTRAINT_LIST}) eq 'HASH';

	my $fd=sub {
		if (defined $file_name && $file_name ne '-') { 
			open(my $fd,"<",$file_name) or croak "$file_name: open error $!\n";
			return $fd;
		}
		else {
			return *STDIN;
		}
	}->();
		

	$p->{PARSER}=XML::Parser->new;
	my $schema=$self->_parse(%$p,FD	=> $fd);
	close $fd if defined $file_name && $file_name ne '-';
	delete $p->{PARSER};

	unless ($p->{CHILD_SCHEMA_}) {
		$self->_recursive_resolution($schema,%$p,ROOT_SCHEMA => $schema);
		$self->_recursive_mapping_path($schema,%$p); 
	}
	else {
		$self->_debug(__LINE__,nvl($schema->get_attrs_value(qw(URI))).': the resolution of external names is postposted because is a child schema');
	}
	return $schema;
}

sub _search_schema_file {
	my ($self,$file_name,%params)=@_;
	affirm { defined $file_name } "1^ param not set";
	return $file_name if File::Spec->file_name_is_absolute($file_name);
	my $schema_path=$params{SCHEMA_PATH};
	affirm { defined $schema_path } "param SCHEMA_PATH not set";
	my @dirs=split(':',$schema_path); 
	for my $dir(@dirs)  {
		next unless length($dir);
		my $f=File::Spec->catfile($dir,$file_name);
		return $f if -e $f && ! -d $f;
	}
	undef;
}

sub parsefile {
	my ($self,$file_name,%params)=@_;
	$file_name='-' if !$params{CHILDS_SCHEMA_} && !defined $file_name; 
	affirm { defined $file_name } "1^ param not set";
	my $schema_path=$params{SCHEMA_PATH};
	unless (defined $schema_path) {
		affirm { !$params{CHILD_SCHEMA_} } " param SCHEMA_PATH not set";		
		$schema_path=$ENV{SCHEMA_PATH};
		$schema_path=dirname($file_name) unless defined $schema_path;
		$params{SCHEMA_PATH}=$schema_path;
	}
	my $f=$params{CHILD_SCHEMA_} ? $self->_search_schema_file($file_name,%params) : $file_name;
	croak "$file_name: not found in SCHEMA_PATH\n" unless defined $f;
	my $schema=$self->_parsefile($f,%params);
	unless ($params{CHILD_SCHEMA_}) {
		my %p=map {  ($_,$schema->get_attrs_value($_));  }  $self->{EXTRA_TABLES}->get_extra_table_types;
		$self->_recursive_change_schema_class($schema,%params,DICTIONARIES => \%p);
		$schema->set_attrs_value(
			OUTPUT_NAMESPACE		=> $self->get_attrs_value(qw(OUTPUT_NAMESPACE))
			,DB_NAMESPACE			=> $self->get_attrs_value(qw(DB_NAMESPACE))
		);
	}
	return $schema;
}


sub new {
	my ($class,%params)=@_;
	$params{OUTPUT_NAMESPACE}='sql' unless defined $params{OUTPUT_NAMESPACE};
	affirm { defined $params{DB_NAMESPACE} } 'param DB_NAMESPACE not set';
	affirm { !defined $params{EXTRA_TABLES} } 'the param EXTRA_TABLES is reserved'; 
	$params{EXTRA_TABLES}=blx::xsdsql::schema_repository::extra_tables::factory_instance(
		map { ($_,$params{$_} ) } (qw(OUTPUT_NAMESPACE DB_NAMESPACE DEBUG))
	);

	for my $cl(qw(catalog table column )) {
		my $k=uc($cl).'_CLASS';
		$params{$k}=$params{EXTRA_TABLES}->get_attrs_value($k);		
	}
	return bless \%params,$class;
}


1;



__END__



=head1  NAME

blx::xsdsql::xsd_parser -  parser for xsd files

=cut

=head1 SYNOPSIS

use blx::xsdsql::xsd_parser

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
        OUTPUT_NAMESPACE    - output_namespace   (default 'sql')
        DB_NAMESPACE        - database namespace
        DEBUG               - set debug mode


parsefile - parse a xsd file - the method return a blx::xsdsql::xsd_parser::schema object

    ARGUMENTS
         schema filename - if is not set standard input is assumed

    PARAMS:
        TABLE_PREFIX                 -  prefix for tables - the default is none
        VIEW_PREFIX                  -  prefix for views  - the default is none
        ROOT_TABLE_NAME              -  the name of the root table - if not set use the default
        DEBUG                        -  set debug mode
        NO_FLAT_GROUPS               -  if true no flat the columns of table groups with maxoccurs <= 1 into the ref table
        FORCE_NAMESPACE              -  force the namespace in uri (valid only if the schema is in the global namespace)
        SCHEMA_PATH                  -  list of directories for search schemas
                                           for default is the environment var SCHEMA_PATH otherwise the directory  of the schema_file

=head1 SEE ALSO

blx::xsdsql::00_readme_API
blx::xsdsql::schema_repository
blx::xsdsql::schema_repository::catalog
blx::xsdsql::schema_repository::catalog_xml


=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
