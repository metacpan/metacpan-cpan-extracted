package blx::xsdsql::xsd_parser::node::simpleType;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base(qw(blx::xsdsql::xsd_parser::type_restriction));
use blx::xsdsql::ut::ut qw(nvl);

sub trigger_at_start_node {
	my ($self,%params)=@_;
	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
		my $schema=$self->get_attrs_value(qw(STACK))->[1];
		$self->set_attrs_value(REDEFINE_FROM_SCHEMA => $schema->get_attrs_value(qw(REDEFINE_FROM_SCHEMA)));
		$schema->add_types($self);
	}
	return $self;
}


sub factory_type {
	my ($self,$t,$types,%params)=@_;
	my $out={};
	my $schema=$t->get_attrs_value(qw(STACK))->[1];
	$self->_resolve_simple_type($t,$types,$out,%params,SCHEMA => $schema);
	return blx::xsdsql::xsd_parser::type::simple->new(NAME => $out,DEBUG => $self->get_attrs_value(qw(DEBUG)));
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	if (defined (my $name=$self->get_attrs_value(qw(name)))) {
			#### none
	}
	else {
		return $self->_hook_to_parent(%params);
	}
}

sub adj_redefine_from_schema {
	my ($self,%params)=@_;
	my $child_schema=delete $self->{REDEFINE_FROM_SCHEMA};
	affirm { defined $child_schema } "child schema not set";
	my $types=$child_schema->get_attrs_value(qw(TYPE_NODE_NAMES)); 
	my $name=nvl($self->get_attrs_value(qw(name)));
	my $childs=$self->get_attrs_value(qw(CHILD));
	my $base=$childs->[0]->get_attrs_value(qw(base));
	affirm { defined $base } "$name: not base defined for this simple type";
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
	return $self;
}

1;


__END__

=head1  NAME

blx::xsdsql::xsd_parser::node::simpleType - internal class for parsing schema

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
