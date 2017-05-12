package blx::xsdsql::xsd_parser::node::include;
use base qw(blx::xsdsql::xsd_parser::node);
use strict;
use warnings FATAL => 'all';
use integer;
use Carp;
use Carp::Assert;
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
		$self->_debug(__LINE__,"include: parsing location '$sl' namespace '".nvl($ns)."'");
		my $child_schema=$p->parsefile($sl,%params,CHILD_SCHEMA_ => 1,FORCE_NAMESPACE => $ns);
		$self->_debug(__LINE__,"end parsing location '$sl'");
		$current_schema->add_child_schema($child_schema,$ns,$sl);
	}
	else {
		croak "schemaLocation attr not found into include tag\n";
	}
	return $self;
}

1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::node::include - internal class for parsing schema 

=cut
