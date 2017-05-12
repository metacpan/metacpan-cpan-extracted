package blx::xsdsql::xsd_parser::type;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::xsd_parser::type::simple;
use blx::xsdsql::xsd_parser::type::other;
use base qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces);

our %_ATTRS_W:Constant(());
our %_ATTRS_R:Constant(());

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


sub _new {
	my ($class,%params)=@_;
	return bless \%params,$class;
}


sub factory {
	my ($type,%params)=@_;
	my $schema=$params{SCHEMA};
	affirm { defined $schema } "param SCHEMA not set";
	my $split=blx::xsdsql::xsd_parser::node::_split_tag_name($type);
	return blx::xsdsql::xsd_parser::type::simple->new(%params,%$split) if $split->{NAMESPACE}  eq $schema->get_std_namespace_attr;
	$split->{URI}=$schema->find_namespace_from_abbr($split->{NAMESPACE});
	affirm { defined $split->{URI} } $split->{NAMESPACE}.": not uri from this namespace abbr";
	return blx::xsdsql::xsd_parser::type::other->new(%params,%$split);
}


1;


__END__

=head1  NAME

blx::xsdsql::xsd_parser::type - internal class for parsing schema

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
