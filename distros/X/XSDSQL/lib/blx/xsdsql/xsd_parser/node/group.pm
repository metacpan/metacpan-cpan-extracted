package blx::xsdsql::xsd_parser::node::group;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::schema_repository::sql::generic::table qw(:overload);
use blx::xsdsql::xsd_parser::type;
use blx::xsdsql::xsd_parser::type::group;
use base qw(blx::xsdsql::xsd_parser::node);


sub adj_redefine_from_schema {
	my ($self,%params)=@_;
	my $child_schema=$self->get_attrs_value(qw(REDEFINE_FROM_SCHEMA));
	affirm { defined $child_schema } "redefine_from_schema not set";
	my $name=$self->get_attrs_value(qw(name));
	affirm { defined $name } "not name defined for this group type";
	my $types=$child_schema->get_attrs_value(qw(TYPE_NODE_NAMES)); 
	affirm { defined $types } "not TYPE_NODE_NAMES in child schema";
	my $t=$types->{$name};
	affirm { defined $t } "$name: no such type with this name";
	my $dest_table=$self->get_attrs_value(qw(TABLE));
	affirm { defined $dest_table } "no such TABLE in self";
	my $source_table=$t->get_attrs_value(qw(TABLE));
	affirm { defined $source_table } "no such TABLE in type"; 
	my $fl=0;
	my @new_cols=();
	for my $col($dest_table->reset_columns) {
		if ($col->get_attrs_value(qw(NAME)) eq $name) {
			$fl=1;
			for my $col($source_table->get_columns) {
				next if $col->is_pk;
				next if $col->is_sys_attributes;
				push @new_cols,$col->shallow_clone->set_attrs_value(ELEMENT_FORM => 'Q') # qualified because is external ref                    ;
			}
		}
		else {
			push @new_cols,$col;
		}
	}
	affirm { $fl } "$name: no such column with this name in table ".$dest_table->get_sql_name;
	$dest_table->add_columns(@new_cols);
	$self->set_attrs_value(REDEFINE_FROM_SCHEMA => undef);
	return $self;
}

sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $parent_table=$self->_get_parent_table;
	my $schema=$self->get_attrs_value(qw(STACK))->[1];
	$self->set_attrs_value(REDEFINE_FROM_SCHEMA => $schema->get_attrs_value(qw(REDEFINE_FROM_SCHEMA)));
	if (defined (my $ref=$self->get_attrs_value(qw(ref)))) {
		my $isparent_choice=$parent_table->get_attrs_value(qw(CHOICE));
		my ($maxoccurs,$minoccurs) = ($self->_resolve_maxOccurs,$self->_resolve_minOccurs(CHOICE => $isparent_choice)); 
		my $name=nvl($self->get_attrs_value(qw(name)),$ref);
		my $ty_obj=defined $schema->get_attrs_value(qw(REDEFINE_FROM_SCHEMA)) 
			? undef 
			: blx::xsdsql::xsd_parser::type::factory(
				$ref
				,SCHEMA => $schema
				,DEBUG => $self->get_attrs_value(qw(DEBUG))
			  );
			  
		my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
			PATH			=> $self->_construct_path(undef,%params,PARENT => undef)
			,NAME			=> $name
			,TYPE			=> $ty_obj
			,MINOCCURS		=> $minoccurs
			,MAXOCCURS		=> $maxoccurs
			,GROUP_REF		=> 1
			,CHOICE			=> $isparent_choice
#			,ELEMENT_FORM 	=> $self->_resolve_form
			,ELEMENT_FORM   => 'Q'
			,DEBUG => $self->get_attrs_value(qw(DEBUG))
			
		);
		if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or choice
			$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
			$parent_table->inc_xsd_seq unless $isparent_choice; #the columns of a choice have the same xsd_seq
		}
		$parent_table->add_columns({ ACCEPT_DUPLICATE_PATH => 1},$column);
		$self->set_attrs_value(TABLE => $parent_table);
	}
	elsif (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $table = $self->get_attrs_value(qw(TABLE_CLASS))->new (
			PATH			=> $self->_construct_path($name,PARENT => undef)
			,NAME			=> $name
			,XSD_TYPE		=> XSD_TYPE_GROUP
			,XSD_SEQ		=> 1
			,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
		);
		$schema->set_table_names($table);
		$table->add_columns(
			$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID))
			,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
		);
		$self->set_attrs_value(TABLE => $table);
		$schema->add_types($self);
	}
	else {
		croak "group without name or ref is not supported\n";
	}
	return $self;
}

sub factory_type {
	my ($self,$t,$types,%params)=@_;
	return blx::xsdsql::xsd_parser::type::group->new(NAME => $t,SCHEMA => $t->get_attrs_value(qw(STACK))->[1],DEBUG => $self->get_attrs_value(qw(DEBUG)));
}

1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::group - internal class for parsing schema

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
