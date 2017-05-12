package blx::xsdsql::xsd_parser::node::sequence;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::xsd_parser::type;
use base qw(blx::xsdsql::xsd_parser::node);

use constant {
	DEFAULT_OCCURS_TABLE_PREFIX	=> 'm_'
};

sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $parent_table=$self->_get_parent_table;
	my $path=$parent_table->get_path;
	my ($maxoccurs,$minoccurs)=(
		$self->_resolve_maxOccurs
		,$self->_resolve_minOccurs(CHOICE => $parent_table->get_attrs_value(qw(CHOICE)))
	);
	if ($maxoccurs > 1) {
		my $schema=$self->get_attrs_value(qw(STACK))->[1];
		my $table = $self->get_attrs_value(qw(TABLE_CLASS))->new(
			NAME			=> DEFAULT_OCCURS_TABLE_PREFIX.$parent_table->get_attrs_value(qw(NAME))
			,MAXOCCURS		=> $maxoccurs
			,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
		);
		
		$schema->set_table_names($table);

		$table->add_columns(
			$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID))
			,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
		);
		$parent_table->add_child_tables($table);
		my $isparent_choice=$parent_table->get_attrs_value(qw(CHOICE));

		my $column =  $self->get_attrs_value(qw(COLUMN_CLASS))->new (	 #hook the column to the parent table 
			NAME				=> $table->get_attrs_value(qw(NAME))
			,TYPE				=> $schema->get_attrs_value(qw(ID_SQL_TYPE))
			,MINOCCURS			=> 0
			,MAXOCCURS			=> 1
			,PATH_REFERENCE		=> $table->get_path
			,TABLE_REFERENCE	=> $table
			,CHOICE				=> $isparent_choice
			,ELEMENT_FORM 		=> $self->_resolve_form
			,DEBUG 				=> $self->get_attrs_value(qw(DEBUG))
		);
		if (defined $parent_table->get_xsd_seq) {	   #the table is a sequence or a choice 
			$column->set_attrs_value(XSD_SEQ => $parent_table->get_xsd_seq); 
			$parent_table->inc_xsd_seq unless $isparent_choice;
		}
		$parent_table->add_columns($column);
		$self->set_attrs_value(TABLE => $table);
	}
	else {
		$parent_table->set_attrs_value(XSD_SEQ => 0) unless defined $parent_table->get_xsd_seq; 
	}
}

1;

__END__

=head1  NAME

blx::xsdsql::xsd_parser::node::sequence - internal class for parsing schema

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
