package blx::xsdsql::generator::sql::generic::handle::insert_dictionary;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use Scalar::Util qw(looks_like_number);

use base(qw(blx::xsdsql::generator::sql::generic::handle));

sub _get_create_prefix {
	my ($self,%params)=@_;
	return "insert into ";
}


sub _get_columns_string_list {
	my ($self,$columns,%params)=@_;
	return '('.join(',',map { $_->get_sql_name } @$columns).')';
}


sub _get_begin_value_constant {
	my ($self,%params)=@_;
	return " values (";	
}

sub _manip_value { #manip values from input data
	my ($self,$col,$v,%params)=@_;
	$v=$self->{BINDING}->get_attrs_value(qw(DB_CONN))->quote($v)
			unless defined $v && looks_like_number($v);
	return $v;
}

sub _get_value_data {
	my ($self,$columns,$data,%params)=@_;
	
	return join(',',map {
							my $name=$_->get_name;
							affirm { exists $data->{$name} }  "$name: column non defined in data - see  the method get_dictionary_data of the correspondenting class";
							my $v=$self->_manip_value($_,$data->{$name});
							$v;
						}  @$columns
	);
}

sub _get_end_value_constant {
	my ($self,%params)=@_;
	return ")";	
}


sub get_binding_objects  {
	my ($self,$schema,%params)=@_;
	my $root_table=$schema->get_root_table;
	return wantarray ? ( $root_table ) : [ $root_table ];
}

sub _get_dictionary_columns {
	my ($self,$table,%params)=@_;
	return $table->get_columns(%params);
}

sub _get_table_data {
	my ($self,$table,$type,%params)=@_;
	return {} unless defined $table;
	if (ref($table)=~/::table$/) {
		for my $col($table->get_columns) {
			$col->set_sql_type(EXTRA_TABLES => $self->{EXTRA_TABLES});
		}
	}
	my $data=$table->get_dictionary_data($type,%params);
	return $data;
}

sub _get_table_columns_data {
	my ($self,$extra_tables,$table,$type,%params)=@_;
	my $dic=$extra_tables->{$type};
	affirm { defined $dic } "'$type': wrong table type";
	my $data=$self->_get_table_data($table,$type,%params);
	my $columns=$self->_get_dictionary_columns($dic);
	return ($columns,$data);
}

sub _print_insert {
	my ($self,$dic,$dic_columns,$data,%params)=@_;
	my $d=ref($data) eq 'ARRAY' ? $data : [ $data ];
	for my $data(@$d)  { 
		$self->{STREAMER}->put_line(
				$self->_get_create_prefix
				,$dic->get_sql_name
				,$self->_get_columns_string_list($dic_columns)
				,$self->_get_begin_value_constant
				,$self->_get_value_data($dic_columns,$data)
				,$self->_get_end_value_constant
				,$dic->command_terminator
				,"\n"
		);	
	}
	$self->{STREAMER}->put_line if ref($data) eq 'ARRAY';
	return $self;
}

sub _insert_catalog {
	my ($self,$extra_tables,%params)=@_;
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,undef,'CATALOG_DICTIONARY');
	
	for my $k(qw(CATALOG_NAME OUTPUT_NAMESPACE DB_NAMESPACE)) {
		affirm { defined $params{$k} } "$k: param not set";
		$data->{lc($k)}=$params{$k};
	}
	my $dic=$extra_tables->{CATALOG_DICTIONARY};
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}

sub _insert_schema {
	my ($self,$extra_tables,%params)=@_;
	my $schema=$params{SCHEMA};
	affirm { defined $schema } "param SCHEMA not set";
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,$schema,'SCHEMA_DICTIONARY',%params);
	$data->{is_root_schema}=$params{ROOT_SCHEMA} ? 1 : 0;
	$data->{location}=$params{LOCATION} unless $params{ROOT_SCHEMA};
	my $dic=$extra_tables->{SCHEMA_DICTIONARY};
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}

sub _insert_table {
	my ($self,$extra_tables,$table,%params)=@_;
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,$table,'TABLE_DICTIONARY',%params);
	my $dic=$extra_tables->{TABLE_DICTIONARY};
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}

sub _insert_columns {
	my ($self,$extra_tables,$table,%params)=@_;
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,$table,'COLUMN_DICTIONARY',%params);
	my $dic=$extra_tables->{COLUMN_DICTIONARY};
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}

sub _insert_relation_tables {
	my ($self,$extra_tables,$table,%params)=@_;
	my $dic=$extra_tables->{RELATION_TABLE_DICTIONARY};
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,$table,'RELATION_TABLE_DICTIONARY',%params);
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}

sub _insert_relation_schemas {
	my ($self,$extra_tables,%params)=@_;
	my $dic=$extra_tables->{RELATION_SCHEMA_DICTIONARY};
	my ($dic_columns,$data)=$self->_get_table_columns_data($extra_tables,undef,'RELATION_SCHEMA_DICTIONARY',%params);

	my %d=(
					parent_schema_code 	=> $params{PARENT_SCHEMA_CODE}
					,child_sequence		=> $params{SCHEMA_CHILD_SEQ}
					,child_schema_code	=> $params{SCHEMA_CODE}
					,parent_namespace  => $params{NAMESPACE}
					,child_location		=> $params{LOCATION}
					,catalog_name		=> $params{CATALOG_NAME}
	);
	
	for my $k(keys %d) {
		$data->{$k}=$d{$k}
	}
	
	return $self->_print_insert($dic,$dic_columns,$data,%params);
}


sub first_pass {
	my ($self,%params)=@_;
	my $extra_tables=$self->{EXTRA_TABLES}->factory_extra_tables;
	$self->_insert_catalog($extra_tables,%params);
	return $self->_insert_schema($extra_tables,%params,ROOT_SCHEMA => 1);
}

sub table_header {
	my ($self,$table,%params)=@_;
	my $schema=$params{SCHEMA};
	my $extra_tables=$self->{EXTRA_TABLES}->factory_extra_tables;
	$self->_insert_table($extra_tables,$table,%params);
	$self->_insert_columns($extra_tables,$table,%params);
	return $self->_insert_relation_tables($extra_tables,$table,%params);	
}

sub relation_schema {
	my ($self,%params)=@_;
	
	for my $k(qw(PARENT_SCHEMA_CODE SCHEMA_CODE SCHEMA_CHILD_SEQ  CATALOG_NAME SCHEMA LOCATION NAMESPACE)) {
		affirm { defined $params{$k} } "$k: param not set";
	}

	my $extra_tables=$self->{EXTRA_TABLES}->factory_extra_tables;
	$self->_insert_schema($extra_tables,%params,ROOT_SCHEMA => undef);
	return $self->_insert_relation_schemas($extra_tables,%params);
}

sub last_pass {
	my ($self,%params)=@_;
	unless ($params{NO_EMIT_COMMENTS}) {
		my $schema=$params{SCHEMA};
		$self->{STREAMER}->put_line($schema->get_root_table->comment(' end of insert dictionary '));
	}
	return $self;
}

1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::insert_dictionary  - generic handle for insert dictionary

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::generic::handle::insert_dictionary


=head1 DESCRIPTION

this package is a class - instance it with the method new

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::generator::sql::generic::handle

=head1 EXPORT

None by default.


=head1 EXPORT_OK

None

=head1 SEE ALSO


See  blx::xsdsql::generator::sql::generic::handle - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


