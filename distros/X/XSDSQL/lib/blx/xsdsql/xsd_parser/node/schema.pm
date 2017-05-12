package blx::xsdsql::xsd_parser::node::schema;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base(qw(blx::xsdsql::xsd_parser::schema blx::xsdsql::xsd_parser::node));

use constant {
	STD_NAMESPACE		=>  'http://www.w3.org/2001/XMLSchema' 
};


our %_ATTRS_R:Constant(
	%blx::xsdsql::xsd_parser::schema::_ATTRS_R
	,ID_SQL_TYPE	=> sub  {
		return $_[0]->get_attrs_value(qw(EXTRA_TABLES))->get_predefined_type(qw(PK_ID_TYPE));
	}
	,(
		map { my $a=$_;($a,sub {  croak $a.": this attribute is not  readable"}) } 
			qw(
				USER_NAMESPACE_ABBR
			)
	)
);

our %_ATTRS_W:Constant(
		%blx::xsdsql::xsd_parser::schema::_ATTRS_W
	,(
		map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } 
			qw(
				ID_SQL_TYPE
				PATH
				STD_NAMESPACE_ABBR
				USER_NAMESPACE_ABBR
				DEFAULT_NAMESPACE
				URI
			)
	)
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _set_std_namespace {
	my ($self,%params)=@_;
	for my $k(keys %$self) {
		if (nvl($self->{$k}) eq STD_NAMESPACE) {
			if ($k=~/^xmlns:(\w+)$/) {
				$self->{STD_NAMESPACE_ABBR}=$1;
				delete $self->{$k};
			}
			else {
				croak "$k: wrong abbr for standard namespace\n";
			}
		}
		elsif ($k=~/^xmlns:(\w+)$/) {
			$self->{USER_NAMESPACE_ABBR}->{$1}=delete $self->{$k};
		}
		elsif ($k eq 'xmlns') {
			$self->{DEFAULT_NAMESPACE}=delete $self->{$k};
		}
		elsif ($k eq 'targetNamespace')  {
			$self->{URI}=delete $self->{$k};
		}
	}
	affirm { defined $self->{STD_NAMESPACE_ABBR} } "not std namespace in schema"; 
	if (defined (my $uri=$params{FORCE_NAMESPACE})) {
		my $orig_uri=nvl($self->get_attrs_value(qw(URI)));
		if (nvl($uri) ne $orig_uri) { 
			affirm { length($orig_uri) == 0 } "$orig_uri: for include the target namespace of the included schema must be on the global namespace or equal to the target namespace  of the parent schema";			
			$self->{URI}=$self->{DEFAULT_NAMESPACE}=$uri;			
		}
	}
	return $self;
}


sub set_table_names {
	my ($self,$table,%params)=@_;
	my %p=%$self;
	$table->set_sql_name(%p); #force the resolve of sql name
	$table->set_constraint_name('pk',%p); #force the resolve of pk constraint
	$table->set_view_sql_name(%p);   #force the resolve of view sql name
	$table->set_attrs_value(URI => $self->get_attrs_value(qw(URI)));  #set the URI attribute
	$table->add_columns(
		$self->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SYS_ATTRIBUTES))
	) unless $params{NOT_ADD_SYS_COLUMNS};

	return $self;
}

sub _set_root_table_before {
	my ($self,%params)=@_;

	my $root=$self->get_attrs_value(qw(TABLE_CLASS))->new (
		PATH			=> '/'
		,CHOICE			=> 1
		,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
	);

	$self->set_attrs_value(TABLENAME_LIST => $params{TABLENAME_LIST},CONSTRAINT_LIST => $params{CONSTRAINT_LIST});
	$self->set_table_names($root,%params);
	$root->add_columns($self->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID)));
	$self->set_attrs_value(TABLE => $root);
	return $self;
}


sub _set_root_table_after {
	my ($self,%params)=@_;
	return $self;
	my $t=$self->get_root_table;
	$t->add_columns(
		$self->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SYS_ATTRIBUTES))
	);
	return $self;
}



sub _adj_redefine_types {
	my ($self,%params)=@_;
	my $types=$self->get_attrs_value(qw(TYPES));
	for my $t(@$types) {
		if (defined (my $child_schema=$t->get_attrs_value(qw(REDEFINE_FROM_SCHEMA)))) {
			$t->adj_redefine_from_schema(%params);
		}
	}
	return $self;
}


sub new {
	my ($class,%params)=@_;
	my $self=$class->blx::xsdsql::xsd_parser::schema::new(%params);
	$self->{PATH}='/';
	delete $params{NO_FLAT_GROUPS}; # set from the base class
	return $self->set_attrs_value(%params);
}

sub _new {
	croak "illegal call\n";
}


sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $encoding=$self->get_attrs_value(qw(STACK))->[0]->[1];	
	$encoding='UTF-8' unless defined $encoding; 
	$encoding='UTF-8' if  $encoding=~/utf[\-]{0,1}8/i;
	$self->{ENCODING}=$encoding;
	$self->set_attrs_value(
		ELEMENT_FORM_DEFAULT => delete $self->{elementFormDefault}
		,ATTRIBUTE_FORM_DEFAULT => delete $self->{attributeFormDefault}
	);
	$self->{SCHEMA_CODE}='ROOT_SCHEMA' unless defined $self->{SCHEMA_CODE};
	$self->_set_std_namespace(%params);
	$self->_set_root_table_before(%params);
	return $self;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	$self->_set_root_table_after(%params);
	$self->_adj_redefine_types;
	$self->set_types;
	return $self;
}

sub get_std_namespace_attr {
	my ($self,%params)=@_;
	return $self->{STD_NAMESPACE_ABBR};
}

sub find_namespace_from_abbr {
	my ($self,$ns,%params)=@_;
	return nvl($self->get_attrs_value(qw(URI))) unless length($ns);
	if (defined (my $uri=$self->{USER_NAMESPACE_ABBR}->{$ns})) {
		return $uri;
	}
	$self->_debug(__LINE__,"$ns: not find uri from this namespace abbr in schema ");
	undef;
}

sub find_schemas_from_namespace_abbr {
	my ($self,$ns,%params)=@_;
	if (defined (my $namespace=$self->find_namespace_from_abbr($ns))) {
		return $self->find_schemas_from_namespace($namespace,%params);
	}
	$self->_debug(__LINE__,"$ns: not find URI from this namespace abbr");
	return wantarray ? () : [];
}

1;

__END__




=head1  NAME

blx::xsdsql::xsd_parser::node::schema - internal class for parsing schema

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
