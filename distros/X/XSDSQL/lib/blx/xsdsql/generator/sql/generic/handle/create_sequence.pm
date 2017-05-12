package blx::xsdsql::generator::sql::generic::handle::create_sequence;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use base qw(blx::xsdsql::generator::sql::generic::handle);

sub _sql_create_sequence {
	return 'create sequence %n';
}

sub table_header {
	my ($self,$table,%params)=@_;
	affirm { ref($table) =~/::extra_tables$/ } ref($table).": 1^ param must be extra_tables class";
	my $name=$table->get_sequence_name(%params);
	my $sql=$self->_sql_create_sequence($table,%params);
	$sql=~s/\%n/$name/g;
	$self->{STREAMER}->put_line($sql,$table->get_attrs_value(qw(CATALOG_INSTANCE))->command_terminator);
	affirm { defined $self->{BINDING} } "attribute BINDING not set";
	$self->{BINDING}->set_attrs_value(SEQUENCE_NAME => $name);
	undef;
}

1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::create_sequence - generic handle for create sequence

=head1 SYNOPSIS

use blx::xsdsql::generator::sql::generic::handle::create_sequence


=head1 DESCRIPTION

this package is a class - instance it with the method new

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::generator::sql::generic::handle


=head1 EXPORT

None by default.


=head1 EXPORT_OK

None

=head1 SEE ALSO


See  blx::xsdsql::generator::sql::generic::handle - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut


