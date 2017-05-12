package blx::xsdsql::xsd_parser::node::attribute;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::xsd_parser::type;
use base qw(blx::xsdsql::xsd_parser::node);

sub trigger_at_start_node {
	my ($self,%params)=@_;
	my $schema=$self->get_attrs_value(qw(STACK))->[1];

	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
			NAME			=> $name
			,ATTRIBUTE		=> 1
			,DEBUG 			=> $self->get_attrs_value(qw(DEBUG))
			,ELEMENT_FORM 	=> $self->get_attrs_value(qw(form))
		);

		if (defined (my $type=$self->get_attrs_value(qw(type)))) {
			my $ty_obj=blx::xsdsql::xsd_parser::type::factory(
				$type
				,SCHEMA => $schema
				,DEBUG => $self->get_attrs_value(qw(DEBUG))
			);
			$column->set_attrs_value(TYPE => $ty_obj);
		}
	
		my $parent_table=$self->_get_parent_table;
		if ($parent_table->is_root_table) {
			 $schema->add_attrs($column);
		}
		elsif ($parent_table->get_attrs_value(qw(ATTRIBUTE_GROUP))) {
			$parent_table->add_columns($column);			
		}
		else {
			$parent_table->add_columns($column);
		}
		$self->set_attrs_value(TABLE => $parent_table);
	}
	elsif (defined (my $ref=$self->get_attrs_value(qw(ref)))) {
		my ($ns,$base)=$ref=~/^([^:]+):(.*)$/;
		if (defined $ns) {  			#search the namespace naame 
			$ref=$base;
			my $namespace=$schema->find_namespace_from_abbr($ns);
			affirm { defined $namespace } "$ns: not find URI from this namespace abbr";
			$ns=$namespace eq nvl($schema->get_attrs_value(qw(URI))) ? undef : $namespace;
		}
		
		my $column = $self->get_attrs_value(qw(COLUMN_CLASS))->new(
			NAME		=> $ref
			,ATTRIBUTE	=> 1
			,REF		=> 1
			,URI		=> $ns
			,DEBUG 		=> $self->get_attrs_value(qw(DEBUG))
		);
		my $parent_table=$self->_get_parent_table;
		if ($parent_table->is_root_table) {
			$schema->add_attrs($column);
		}
		elsif ($parent_table->get_attrs_value(qw(ATTRIBUTE_GROUP))) {
				$parent_table->add_columns($column);			
		}
		else {
				$parent_table->add_columns($column);
		}
		$self->set_attrs_value(TABLE => $parent_table);
	} else {
		confess "internal error - attribute without name or ref is not implemented\n";
	}
	return $self;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	unless (defined $self->get_attrs_value(qw(type))) {
		if (defined (my $childs=$self->get_attrs_value(qw(CHILD)))) {
			my $child=$childs->[0];
#			$self->_debug(__LINE__,$child);
			my $out={};
			my $table=$self->get_attrs_value(qw(TABLE));
			my ($schema,$col,$debug)=($self->get_attrs_value(qw(STACK))->[1],($table->get_columns)[-1],$self->get_attrs_value(qw(DEBUG)));
			$self->_resolve_simple_type($child,undef,$out,%params,SCHEMA => $schema,DEBUG => $debug);
			my $ty_obj=ref($out->{base}) eq '' 
					? blx::xsdsql::xsd_parser::type::simple->_new(NAME => $out,SCHEMA => $schema,DEBUG => $debug) 
					: $out->{base};
			$col->set_attrs_value(TYPE => $ty_obj);
		}
		elsif (defined (my $ref=$self->get_attrs_value(qw(ref)))) {
			#empty 
		}
		else {
			croak "attribute without  type and childs\n";
		}
	}
	return $self;
}



1;

__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::attribute - internal class for parsing schema

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
