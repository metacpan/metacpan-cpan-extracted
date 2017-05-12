package blx::xsdsql::xsd_parser::type_restriction;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use base qw(blx::xsdsql::xsd_parser::node);

sub _hook_to_parent {
	my ($self,%params)=@_;
	my $parent=$self->get_attrs_value(qw(STACK))->[-2];  # -1 is it' self
	my $ch=$parent->get_attrs_value(qw(CHILD));
	$ch=[] unless defined $ch;
	push @$ch,$self;
	$parent->set_attrs_value(CHILD => $ch);
	return $self;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	return $self->_hook_to_parent(%params);
}

1;


__END__

=head1  NAME

blx::xsdsql::xsd_parser::type_restriction - internal class for parsing schema

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
