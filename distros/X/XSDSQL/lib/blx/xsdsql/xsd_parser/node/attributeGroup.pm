package blx::xsdsql::xsd_parser::node::attributeGroup;
use base qw(blx::xsdsql::xsd_parser::node);
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7


sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $schema=$self->get_attrs_value(qw(STACK))->[1];
	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $table= $self->get_attrs_value(qw(TABLE_CLASS))->new (
			ATTRIBUTE_GROUP	=> 1
			,NAME			=> $name
		);
		$self->set_attrs_value(TABLE => $table);
		$schema->set_table_names($table);
	}
	elsif (defined (my $ref=$self->get_attrs_value(qw(ref)))) {
		$self->_debug(__LINE__,$ref,': element without name and with ref');
		my ($ns,$base)=$ref=~/^([^:]+):(.*)$/;
		if (defined $ns) {  			#search the namespace naame 
			$ref=$base;
			my $namespace=$schema->find_namespace_from_abbr($ns);
			affirm { defined $namespace } "$ns: not find URI from this namespace abbr";
			$ns=$namespace;
		}
		my $parent_table=$self->_get_parent_table;
		my $column = $schema->get_attrs_value(qw(COLUMN_CLASS))->new(
			NAME				=> $ref
			,REF				=> 1
			,ELEMENT_FORM 		=> $self->_resolve_form
			,URI				=> $ns
			,DEBUG 				=> $self->get_attrs_value(qw(DEBUG))
			,ATTRIBUTE_GROUP	=> 1
			,TABLE_NAME			=> $parent_table
		);
		$parent_table->add_columns(
			{
                NO_SET_TABLE_NAME    => 1 
			}
			,$column
		);
		$self->set_attrs_value(TABLE => $parent_table);
	}
	else {
		$self->_debug(__LINE__,Dumper($self));
		confess "node without name or ref is not supported\n";
	}	
	$self;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	if (defined (my $table=$self->get_attrs_value(qw(TABLE)))) {
		if ($table->get_attrs_value(qw(ATTRIBUTE_GROUP))) {
			my $stackframe=$self->get_attrs_value(qw(STACK));
			my $schema=$stackframe->[1];
			$schema->add_attributes_group($table);
		}
	}
	$self;
}


1;

__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::attributeGroup - internal class for parsing schema

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
