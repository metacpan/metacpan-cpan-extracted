package blx::xsdsql::xsd_parser::type::other;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use blx::xsdsql::ut::ut qw(nvl);

use base qw(blx::xsdsql::xsd_parser::type::base);


sub new {
	my ($class,%params)=@_;
	for my $k(keys %params) { delete $params{$k} if $k=~/^SQL_/; } 
	my $self=bless \%params,$class;
	return $self;
}


sub resolve_type {
	my ($self,$types,%params)=@_;
	if (defined (my $name=$self->get_attrs_value(qw(FULLNAME)))) {
		unless (defined  $self->{URI}) {
			$self->_debug(undef,"$name: type without uri");
			return;
		}
		my $schema=$self->{SCHEMA};
		affirm { defined $schema } "$name: not SCHEMA attr set";
		return unless $self->get_attrs_value(qw(URI)) eq nvl($schema->get_attrs_value(qw(URI)));
		my $t=$types->{$name};
		unless (defined $t) {
			$self->_debug(undef,"$name: name not found into custom types");
			return;
		}
		$self->_debug(undef,'factory type from object type ',ref($t));
		return $t->factory_type($t,$types,%params);
	}
	$self->_debug(undef,"FULLNAME attribute not set");
	undef;
}

sub resolve_external_type {
	my ($self,$schema,%params)=@_;
	my ($ns,$name)=($self->{NAMESPACE},$self->{NAME});
	for my $s($schema->find_schemas_from_namespace_abbr($ns)) {
		my $types=$s->get_attrs_value(qw(TYPES));
		my %type_node_names=map  {  ($_->get_attrs_value(qw(name)),$_); } @$types;
		if (defined (my $t=$type_node_names{$name})) {
			$self->_debug(undef,'factory type from object type ',ref($t));
			return $t->factory_type($t,\%type_node_names,%params);
		}
	}
	$self->_debug(undef,"$ns: not find schema from this namespace abbr"); 
	undef;
}


1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::type::other - internal class for parsing schema

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
