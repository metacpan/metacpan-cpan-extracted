package blx::xsdsql::xsd_parser::node::complexType;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::schema_repository::sql::generic::table qw(:overload);
use blx::xsdsql::xsd_parser::type;
use blx::xsdsql::xsd_parser::type::complex;
use blx::xsdsql::xsd_parser::type::simple_content;
use blx::xsdsql::xsd_parser::type::simple;
use base qw(blx::xsdsql::xsd_parser::node);


sub adj_redefine_from_schema {
	my ($self,%params)=@_;
	my $child_schema=delete $self->{REDEFINE_FROM_SCHEMA};
	affirm { defined $child_schema } "redefine_from_schema not set";
	my $types=$child_schema->get_attrs_value(qw(TYPE_NODE_NAMES)); 
	my $name=nvl($self->get_attrs_value(qw(name)));
	my $childs=$self->get_attrs_value(qw(CHILD));
	my $base=$childs->[0]->get_attrs_value(qw(CHILD))->[0]->get_attrs_value(qw(base));
	affirm { defined $name } "$name: not base defined for this simple type";
	my $t=$types->{$base};
	affirm { defined $t } "$base: no such type with this name";
	my $self_restrictions=$childs->[0]->get_attrs_value(qw(CHILD));
	my $old_restrictions=$t->get_attrs_value(qw(CHILD))->[0]->get_attrs_value(qw(CHILD));
	my %self_restrictions=map {  (ref($_),$_); } @$self_restrictions;
	my @new_restrictions=map {  
		my $r=$self_restrictions{ref($_)};
		defined $r ? $r : $_;
	} @$old_restrictions;
	$childs->[0]->set_attrs_value(CHILD => \@new_restrictions,base => $t->get_attrs_value(qw(CHILD))->[0]->get_attrs_value(qw(base)));
}

sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $stackframe=$self->get_attrs_value(qw(STACK));
	my ($schema,$parent)=map { $stackframe->[$_] } (1,-1);
	$self->set_attrs_value(REDEFINE_FROM_SCHEMA => $schema->get_attrs_value(qw(REDEFINE_FROM_SCHEMA)));
	$self->set_attrs_value(MIXED => $self->_resolve_boolean($self->get_attrs_value(qw(mixed))));
	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $table = $self->get_attrs_value(qw(TABLE_CLASS))->new (
			PATH			=> $self->_construct_path($name,PARENT => $parent)
			,XSD_TYPE		=> XSD_TYPE_COMPLEX
			,XSD_SEQ		=> 1
			,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
			,MIXED			=> $self->get_attrs_value(qw(MIXED))
		);
		$schema->set_table_names($table);

		$table->add_columns(
			$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID))
			,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
		);
		$schema->add_types($self);
		$self->set_attrs_value(TABLE => $table);
	}
	else {
		my $parent_table=$parent->get_attrs_value(qw(TABLE));
		$parent_table->set_attrs_value(MIXED => $self->get_attrs_value(qw(MIXED)));
		$self->set_attrs_value(TABLE => $parent_table);
	}
	return $self;
}

sub factory_type {
	my ($self,$t,$types,%params)=@_;
	my ($schema,$debug)=($t->get_attrs_value(qw(STACK))->[1],$self->get_attrs_value(qw(DEBUG)));
	my $table=$t->get_attrs_value(qw(TABLE));
	if ($table->get_attrs_value(qw(XSD_TYPE) eq XSD_TYPE_SIMPLE_CONTENT)) {
		return blx::xsdsql::xsd_parser::type::simple_content->_new(NAME => $t,SCHEMA => $schema,DEBUG => $debug);
	}
	my $out={};
	$self->_resolve_simple_type($t,$types,$out,%params,SCHEMA => $schema);
	if (defined (my $base=$out->{base})) {  #is simpleContent
		my $ty_obj=blx::xsdsql::xsd_parser::type::simple->new(NAME => $out,DEBUG => $debug);
		my $value_col=$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(VALUE_COL))->set_attrs_value(TYPE => $ty_obj);
		$table->add_columns($value_col);
		$table->set_attrs_value(XSD_TYPE => XSD_TYPE_SIMPLE_CONTENT,INTERNAL_REFERENCE => 1);	
		return blx::xsdsql::xsd_parser::type::simple_content->new(NAME => $t,SCHEMA => $schema,DEBUG => $debug);
	}
	return blx::xsdsql::xsd_parser::type::complex->new(NAME => $t,SCHEMA => $schema,DEBUG => $debug);
}


sub trigger_at_end_node {	
	my ($self,%params)=@_;
	if ($self->get_attrs_value(qw(MIXED))) {
		my $table=$self->get_attrs_value(qw(TABLE));
		affirm { defined $table } "TABLE attributed not set";
		my $isparent_choice=$table->get_attrs_value(qw(CHOICE));
		my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
			MINOCCURS				=> 1
			,MAXOCCURS				=> 1
			,CHOICE 				=> $isparent_choice
			,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
			,MIXED					=> 1
			,TYPE					=> blx::xsdsql::xsd_parser::type::simple->new(NAME => 'string')
		);
		if (defined $table->get_xsd_seq) {	   #the table is a sequence or choice
			$column->set_attrs_value(XSD_SEQ => $table->get_xsd_seq); 
			$table->inc_xsd_seq unless $isparent_choice; #the columns of a choice have the same xsd_seq
		}
		$table->add_columns($column);				
	}
	return $self;
}

1;

__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::complexType - internal class for parsing schema

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
