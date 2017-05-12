package blx::xsdsql::schema_repository::loader;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl ev);
use blx::xsdsql::xsd_parser::schema;
use blx::xsdsql::schema_repository::sql::generic::table;
use blx::xsdsql::schema_repository::sql::generic::column;
use blx::xsdsql::schema_repository::sql::generic::relation_schema;
use blx::xsdsql::schema_repository::sql::generic::relation_table;

use base qw(blx::xsdsql::schema_repository::base);


sub new  { 
	my ($class,%params)=@_;
	return $class->SUPER::_new(%params);
}

sub load_schema_from_catalog {
	my ($self,$catalog_name,%params)=@_;
	my $conn=$self->{DB_CONN};
	my %schemas=(); #hash with key schema_code and value obj of class blx::xsdsql::xsd_parser::schema  
	my $root_schema=undef;
	my %tables=(); #hash with key sql_name and value obj of class blx::xsdsql::<output_namespace>::<db_namespace>::table
	my %root_tables=(); #hash with key schema_code and value obj of class blx::xsdsql::<output_namespace>::<db_namespace>::table
	my %table_types=(); #hash with key schema_code and value array of tables
	
	{ 	### load schema
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(SCHEMA_DICTIONARY));
		my @cols=grep(!$_->get_attrs_value(qw(PK_AUTOSEQUENCE)),$table->get_columns);
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY => \@cols
							,WHERE => [ { COL => 'catalog_name',VALUE => $catalog_name } ]
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		while(my $r=$prep->fetchrow_arrayref) {
			my $schema= blx::xsdsql::xsd_parser::schema::factory_from_dictionary_data($r,EXTRA_TABLES => $self->{_EXTRA_TABLES});
			my $code=$schema->get_attrs_value(qw(SCHEMA_CODE));
			affirm { defined $code } "attribute SCHEMA_CODE not set";
			$schemas{$code}=$schema;
			if ($schema->get_attrs_value(qw(ROOT_SCHEMA))) {
				affirm { !defined $root_schema } "$catalog_name: many root_schema in this catalog";
				$root_schema=$schema;
			}
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		affirm { defined $root_schema } "$catalog_name: no root schema in this catalog"; 
	}
	
	{  # assign childs schema
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(RELATION_SCHEMA_DICTIONARY));
		my @cols=grep(!$_->get_attrs_value(qw(PK_AUTOSEQUENCE)),$table->get_columns);
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY	=> \@cols
							,WHERE => [ { COL => 'catalog_name',VALUE => $catalog_name } ]
							,ORDER	=> [ qw(catalog_name parent_schema_code child_sequence) ] 
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		while(my $r=$prep->fetchrow_arrayref) {
			my $rs= blx::xsdsql::schema_repository::sql::generic::relation_schema::factory_from_dictionary_data($r,EXTRA_TABLES 	=> $self->{_EXTRA_TABLES});
			my $schema_code=$rs->get_attrs_value(qw(PARENT_SCHEMA_CODE));
			affirm { defined $schema_code } "PARENT_SCHEMA_CODE not set";
			my $parent_schema=$schemas{$schema_code};
			affirm { defined $parent_schema } "no such schema with code '$schema_code'";
			$schema_code=$rs->get_attrs_value(qw(CHILD_SCHEMA_CODE));
			affirm { defined $schema_code } "CHILD_SCHEMA_CODE not set";
			my $child_schema=$schemas{$schema_code};
			affirm { defined $child_schema } "no such schema with code '$schema_code'";
			my ($parent_namespace,$child_location)=$rs->get_attrs_value(qw(PARENT_NAMESPACE CHILD_LOCATION));
			$self->{_LOGGER}->log(__LINE__,'add child_schema from location ',$child_location,' and namespace ',$parent_namespace);
			$parent_schema->add_child_schema($child_schema,$parent_namespace,$child_location);
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	{  #load tables
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(TABLE_DICTIONARY));
		my @cols=grep(!$_->get_attrs_value(qw(PK_AUTOSEQUENCE)),$table->get_columns);
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY	=> \@cols
							,WHERE => [ { COL => 'catalog_name',VALUE => $catalog_name } ]
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		while(my $r=$prep->fetchrow_arrayref) {
			my $t= blx::xsdsql::schema_repository::sql::generic::table::factory_from_dictionary_data(
						$r
						,EXTRA_TABLES 	=> $self->{_EXTRA_TABLES}
			);
			$tables{$t->get_sql_name}=$t;
			if ($t->is_root_table) {
				my $schema_code=$t->get_attrs_value(qw(SCHEMA_CODE));
				affirm { defined $schema_code } "attribute SCHEMA_CODE not set";
				$root_tables{$schema_code}=$t;
			}
			if ($t->is_type) {
				my $schema_code=$t->get_attrs_value(qw(SCHEMA_CODE));
				affirm { defined $schema_code } "attribute SCHEMA_CODE not set";
				$table_types{$schema_code}=[] unless defined $table_types{$schema_code};
				push @{$table_types{$schema_code}},$t;
			}	
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	{ # relation tables
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(RELATION_TABLE_DICTIONARY));
		my @cols=grep(!$_->get_attrs_value(qw(PK_AUTOSEQUENCE)),$table->get_columns);
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY => \@cols
							,WHERE => [ { COL => 'catalog_name',VALUE => $catalog_name } ]
							,ORDER	=> [ qw(parent_table_name child_sequence) ] 
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		while(my $r=$prep->fetchrow_arrayref) {
			my $t=blx::xsdsql::schema_repository::sql::generic::relation_table::factory_from_dictionary_data(
						$r
						,EXTRA_TABLES 	=> $self->{_EXTRA_TABLES}
			);	
			my $table_name=$t->get_attrs_value(qw(PARENT_TABLE_NAME));
			my $parent_table=$tables{$table_name};
			affirm { defined $parent_table } "$table_name: no such table object with this sql_name";
			$table_name=$t->get_attrs_value(qw(CHILD_TABLE_NAME));
			my $child_table=$tables{$table_name};
			affirm { defined $child_table } "$table_name: no such table object with this sql_name";
			$self->{_LOGGER}->log({ PACKAGE => __PACKAGE__,LINE => __LINE__},"add table ",$child_table->get_sql_name," with child table to table ",$parent_table->get_sql_name);			
			$parent_table->add_child_tables($child_table);
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	{ # columns 
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(COLUMN_DICTIONARY));
		my @cols=grep(!$_->get_attrs_value(qw(PK_AUTOSEQUENCE)),$table->get_columns);
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY => \@cols
							,WHERE => [ { COL => 'catalog_name',VALUE => $catalog_name } ]
							,ORDER	=> [ qw(table_name column_seq) ] 
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		
		my $symtable=ev('\\%'.ref($cols[0]).'::'); # use the class method factory_from_dictionary_data from the column class
												   # if exists otherwise from the generic column class
												   # $pf contain a pointer to sub
		my $pf=$symtable->{factory_from_dictionary_data} 
			?  \&{ref($cols[0]).'::factory_from_dictionary_data'}
			: \&blx::xsdsql::schema_repository::sql::generic::column::factory_from_dictionary_data
		;
		
		while(my $r=$prep->fetchrow_arrayref) {
			
			my $c=$pf->(
						$r
						,EXTRA_TABLES 	=> $self->{_EXTRA_TABLES}
			);

			if (defined (my $sql_name=$c->get_table_reference)) {
				my $t=$tables{$sql_name};
				affirm { defined $t } "$sql_name: no such table with this name";
				$c->set_attrs_value(TABLE_REFERENCE => $t);
				$self->{_LOGGER}->log( { PACKAGE => __PACKAGE__,LINE => __LINE__},"bind table ",$t->get_sql_name," to column ".$c->get_full_name);
			}
			my $sql_name=$c->get_table_name;
			my $t=$tables{$sql_name};
			affirm { defined $t } "$sql_name: no such table with this name";
			$t->add_columns({
								NO_GENERATE_SEQUENCE 	=> 1
								,NO_SET_TABLE_NAME		=> 1
								,NO_GENERATE_SQL_NAME	=> 1
								,ACCEPT_DUPLICATE_PATH	=> 1
								,IGNORE_ALREADY_EXIST	=> 1
							},$c
			);
			$self->{_LOGGER}->log({ PACKAGE => __PACKAGE__,LINE => __LINE__},"added column ",$c->get_sql_name,' to table ',$t->get_sql_name);						
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	for my $schema_code(keys %schemas) {  # add types e mapping paths
		my $schema=$schemas{$schema_code};
		affirm { defined $schema } "$schema_code: not schema with this schema_code";
		if (defined (my $types=$table_types{$schema_code})) {
				affirm { ref($types) eq 'ARRAY' } ref($types).": must be ARRAY";
				$schema->add_types(@$types);
		}
		my $root_table=$root_tables{$schema_code};
		affirm { defined $root_table } "$schema_code: no root table for this schema_code"; 
		$schema->set_attrs_value(TABLE => $root_table);
		$schema->set_types;
		my $type_table_paths=$schema->get_types_path;
		affirm { ref($type_table_paths) eq 'HASH' } ref($type_table_paths)." not HASH"; 
		$schema->mapping_paths($type_table_paths,DEBUG => $self->{DEBUG});
	}
	
	return $root_schema->set_attrs_value(CATALOG_NAME => $catalog_name);
}


1;



__END__



=head1  NAME

blx::xsdsql::schema_repository::loader -  internal class for load  schema

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::loader

=cut

=head1 SEE ALSO

See blx::xsdsql::schema_repository - is a frontend from this class

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
