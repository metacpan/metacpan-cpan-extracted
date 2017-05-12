package blx::xsdsql::xsd_parser::node::redefine;
use base qw(blx::xsdsql::xsd_parser::node);
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use blx::xsdsql::ut::ut qw(nvl);

sub trigger_at_start_node {
	my ($self,%params)=@_;
	if (defined (my $sl=$self->get_attrs_value(qw(schemaLocation)))) {
		my $parser=$params{PARSER};
		affirm { defined $parser } "parser param not set";
		my %p=map { ($_,$self->{$_}); } grep($_ eq uc($_) && ref($self->{$_}) eq '' && defined $self->{$_},keys %$self);
		my $current_schema=$self->get_attrs_value(qw(STACK))->[1];
		my $ns=$current_schema->get_attrs_value(qw(DEFAULT_NAMESPACE));
		my $p=blx::xsdsql::xsd_parser->new(map { $_ => $parser->get_attrs_value($_) } qw(OUTPUT_NAMESPACE DB_NAMESPACE DEBUG));
		$self->_debug(__LINE__,"redefine: parsing location '$sl' namespace '".nvl($ns)."'");
		my $child_schema=$p->parsefile($sl,%params,CHILD_SCHEMA_ => 1);
		$self->_debug(__LINE__,"end parsing location '$sl'");
		$child_schema->set_attrs_value;
		$current_schema->add_child_schema($child_schema,$ns,$sl);
		$current_schema->set_attrs_value(REDEFINE_FROM_SCHEMA => $child_schema);
	}
	else {
		croak "schemaLocation attr not found into redefine tag\n";
	}
	return $self;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	my $current_schema=$self->get_attrs_value(qw(STACK))->[1];
	$current_schema->set_attrs_value(REDEFINE_FROM_SCHEMA => undef);
	return $self;
}


1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::include - internal class for parsing schema

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
