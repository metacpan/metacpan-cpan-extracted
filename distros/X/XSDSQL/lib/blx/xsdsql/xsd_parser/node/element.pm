package blx::xsdsql::xsd_parser::node::element;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use File::Basename;

use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::xsd_parser::type;
use blx::xsdsql::xsd_parser::type::simple;
use base qw(blx::xsdsql::xsd_parser::node);

sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $parent_table=$self->_get_parent_table;
	my $isparent_choice=$parent_table->get_attrs_value(qw(CHOICE));
	my ($maxoccurs,$minoccurs) = ($self->_resolve_maxOccurs,$self->_resolve_minOccurs(CHOICE => $isparent_choice)); 
	my $is_mixed=$self->_is_into_a_mixed;
	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $path=$self->_construct_path($name,%params,PARENT => undef);
		if (defined (my $xsd_type=$self->get_attrs_value(qw(type)))) {
			my ($schema,$debug)=($self->get_attrs_value(qw(STACK))->[1],$self->get_attrs_value(qw(DEBUG)));
			if ($is_mixed) {
				my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
					MINOCCURS				=> 1
					,MAXOCCURS				=> 1
					,CHOICE 				=> $isparent_choice
					,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
					,MIXED					=> 1
					,TYPE					=> blx::xsdsql::xsd_parser::type::simple->new(NAME => 'string')
				);
				if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or choice
					$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
					$parent_table->inc_xsd_seq unless $isparent_choice; #the columns of a choice have the same xsd_seq
				}
				$parent_table->add_columns($column);				
			}
			my $ty_obj=blx::xsdsql::xsd_parser::type::factory(
					$xsd_type
					,SCHEMA => $schema
					,DEBUG => $debug
			);

			if ($maxoccurs > 1  && ref($ty_obj)=~/::simple$/) {
				$self->_debug(undef,$xsd_type,': simple type with maxOccurs > 1');
				my $column =  $self->get_attrs_value(qw(COLUMN_CLASS))->new(
					PATH					=> $path
					,TYPE					=> $schema->get_attrs_value(qw(ID_SQL_TYPE))
					,MINOCCURS				=> $minoccurs
					,MAXOCCURS				=> $maxoccurs
					,INTERNAL_REFERENCE 		=> 1
					,CHOICE					=> $isparent_choice
					,ELEMENT_FORM 			=> $self->_resolve_form
					,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
				);
				if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or choice
					$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
					$parent_table->inc_xsd_seq unless $isparent_choice; #the columns of a choice have the same xsd_seq
				}
				$parent_table->add_columns($column);
				my $table=$self->get_attrs_value(qw(TABLE_CLASS))->new(
					PATH		    		=> $path
					,INTERNAL_REFERENCE 		=> 1
					,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
					,MIXED					=> $is_mixed
				);
				$schema->set_table_names($table);
				$table->add_columns(
					$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID))
					,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
				);
				my $value_col=$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(VALUE_COL))
									->set_attrs_value(TYPE => $ty_obj,PATH => $path,CHOICE => $isparent_choice);

				if ($is_mixed) {
					my $col = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
							MINOCCURS				=> 1
							,MAXOCCURS				=> 1
							,CHOICE 				=> $isparent_choice
							,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
							,MIXED					=> 1
							,TYPE					=> blx::xsdsql::xsd_parser::type::simple->new(NAME => 'string')
						);
					$table->add_columns($col);
				}
				$table->add_columns($value_col);
				$column->set_attrs_value(TABLE_REFERENCE => $table,PATH_REFERENCE => $table->get_path);
				$parent_table->add_child_tables($table);
				$self->set_attrs_value(TABLE => $table);
			}
			else {
				$self->_debug(undef,$path,': type with maxOccurs <= 1 or type is not simple');
				my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
					PATH					=> $path
					,TYPE					=> $ty_obj
					,MINOCCURS				=> $minoccurs
					,MAXOCCURS				=> $maxoccurs
					,CHOICE 				=> $isparent_choice
					,ELEMENT_FORM 			=> $self->_resolve_form
					,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
				);
				if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or choice
					$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
					$parent_table->inc_xsd_seq unless $isparent_choice; #the columns of a choice have the same xsd_seq
				}
				$parent_table->add_columns($column);
			}
		}
		else {   #anonymous type - converted into a table
			$self->_debug(__LINE__,$path,': anonymous type - converted into table');
			my $schema=$self->get_attrs_value(qw(STACK))->[1];
			my $table = $self->get_attrs_value(qw(TABLE_CLASS))->new(
					PATH				=> $path
					,ANONYMOUS_TYPE		=> 1 
					,DEBUG 				=> $self->get_attrs_value(qw(DEBUG))
			);
			$schema->set_table_names($table);
			my $maxocc=nvl($params{MAXOCCURS},1);
			$table->set_attrs_value(MAXOCCURS => $maxocc) 	if $maxocc > 1;
			$table->set_attrs_value(MAXOCCURS => $maxoccurs) 	if $maxoccurs > 1;
			$table->add_columns($schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID)));
			$parent_table->add_child_tables($table);
			my $form=$self->_resolve_form;
			my $column = $schema->get_attrs_value(qw(COLUMN_CLASS))->new(	 #hoock to the parent the column 
					NAME				=> $name
					,PATH				=> undef
					,TYPE				=> $schema->get_attrs_value(qw(ID_SQL_TYPE))
					,MINOCCURS			=> $minoccurs
					,MAXOCCURS			=> $maxoccurs
					,PATH_REFERENCE		=> $path
					,TABLE_REFERENCE 	=> $table
					,CHOICE				=> $isparent_choice
					,ELEMENT_FORM 		=> $form
					,DEBUG 				=> $self->get_attrs_value(qw(DEBUG))
			);
			
			if (defined $parent_table->get_xsd_seq) {	   #the table is a xs:sequence or a xs:choice 
				$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
				$parent_table->inc_xsd_seq unless $isparent_choice; 
			}	
			$parent_table->add_columns($column);
			my $cols=$parent_table->get_columns;
			my $child_tables=$parent_table->get_child_tables;
			$self->set_attrs_value(
				TABLE 			=> $table
				,TABLE_INDEX 	=> scalar(@$child_tables) - 1
				,PARENT_TABLE 	=> $parent_table
				,COLUMN_INDEX   => scalar(@$cols) - 1
			);
		}
	}
	elsif (defined (my $ref=$self->get_attrs_value(qw(ref)))) {
		$self->_debug(__LINE__,$ref,': element without name and with ref');
		my $schema=$self->get_attrs_value(qw(STACK))->[1];
		my ($ns,$base)=$ref=~/^([^:]+):(.*)$/;
		if (defined $ns) {  			#search the namespace naame 
			$ref=$base;
			my $namespace=$schema->find_namespace_from_abbr($ns);
			affirm { defined $namespace } "$ns: not find URI from this namespace abbr";
			$ns=$namespace;
		}
		my $path=$self->_construct_path($ref,%params,PARENT => undef);
		my $column = $schema->get_attrs_value(qw(COLUMN_CLASS))->new(
			REF					=> 1
			,PATH				=> $path
			,MINOCCURS			=> $minoccurs
			,MAXOCCURS			=> $maxoccurs
			,CHOICE 			=> $isparent_choice
			,ELEMENT_FORM 		=> $self->_resolve_form
			,URI				=> $ns
			,DEBUG 				=> $self->get_attrs_value(qw(DEBUG))
		);
		if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or choice
			$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
			$parent_table->inc_xsd_seq unless  $isparent_choice; #the columns of a choice have the same xsd_seq
		}
		$parent_table->add_columns($column);
		$self->set_attrs_value(TABLE => $parent_table);
	}
	else {
		croak "node without name or ref is not supported\n";
	}

	return $self;
}


sub _get_type {
	my ($self,%params)=@_;
	my $childs=delete $params{CHILD};
	$childs=$self->get_attrs_value(qw(CHILD)) unless defined $childs;
	affirm { defined $childs } "CHILD not set";
	affirm { ref($childs) eq 'ARRAY' } "CHILD not array"; 
	affirm { scalar(@$childs) == 1 } scalar(@$childs).": CHILDS element must be 1";
	my $child=$childs->[0];
	my $out={};
	my ($schema,$debug)=($self->get_attrs_value(qw(STACK))->[1],$self->get_attrs_value(qw(DEBUG)));
	$self->_resolve_simple_type($child,undef,$out,%params,SCHEMA => $schema);
	my $ty_obj=ref($out->{base}) eq '' 
			? blx::xsdsql::xsd_parser::type::simple->new(NAME => $out,SCHEMA => $schema,DEBUG => $debug) 
			: $out->{base};
	return $ty_obj;
}

sub _get_last_node_column { 
	my ($self,$table,%params)=@_;
	my @cols=$table->get_columns;
	my $col=undef;
	while (1) {
		$col=pop @cols;
		last unless defined $col;
		last unless $col->is_sys_attributes or $col->is_attribute or $col->is_pk;
	}	
	return $col;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	my $table=$self->get_attrs_value(qw(TABLE));

	if (defined $table && $table->get_attrs_value(qw(ANONYMOUS_TYPE))) {
		if (defined (my $childs=$self->get_attrs_value(qw(CHILD)))) {
			my $parent_table=$self->get_attrs_value(qw(PARENT_TABLE));
			my $col=$self->_get_last_node_column($parent_table);
			affirm { defined $col } "link column not found for table ".$table->get_sql_name;
			my ($schema,$debug)=($self->get_attrs_value(qw(STACK))->[1],$self->get_attrs_value(qw(DEBUG)));
			my $ty_obj=$self->_get_type(CHILD => $childs);
			if ($col->get_max_occurs <= 1) {
				$col->set_attrs_value(TYPE => $ty_obj,TABLE_REFERENCE => undef,PATH_REFERENCE => undef,PATH => $table->get_path);
				$parent_table->delete_child_tables($self->get_attrs_value(qw(TABLE_INDEX)));
			}
			else {
				my $path=$table->get_path;
				$col->set_attrs_value(INTERNAL_REFERENCE => 1,PATH => $path);
				my $column = $schema->get_attrs_value(qw(COLUMN_CLASS))->new(
					NAME			=> basename($path)
					,PATH			=> $path
					,CHOICE 		=> $table->is_choice
					,TYPE			=> $ty_obj
					,ELEMENT_FORM 	=> $self->_resolve_form
					,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
					,VALUE_COL		=> 1
				);
				$table->set_attrs_value(INTERNAL_REFERENCE => 1);
				$table->add_columns(
					$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
					,$column
				);
			}
		}
	}
	return $self;
}

1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::element - internal class for parsing schema

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
