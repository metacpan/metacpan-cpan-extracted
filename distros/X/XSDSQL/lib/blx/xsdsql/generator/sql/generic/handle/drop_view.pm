package blx::xsdsql::generator::sql::generic::handle::drop_view;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use base(qw(blx::xsdsql::generator::sql::generic::handle));

sub _get_drop_prefix {
	my ($self,%params)=@_;
	return "drop view";
}

sub get_binding_objects  {
	my ($self,$schema,%params)=@_;
	my $table=$schema->get_root_table;
	return wantarray ? ( $table ) : [ $table ];
}

sub table_header {
	my ($self,$table,%params)=@_;
	my $path=$table->get_attrs_value(qw(PATH));
	my $comm=defined $path ? $table->comment('PATH: '.$path) : '';
	my $name=$table->get_view_sql_name;
	$self->{STREAMER}->put_line($self->_get_drop_prefix,' ',$name,' ',$comm,$table->command_terminator);
	return $self;
}

sub table_footer {
	my ($self,$table,%params)=@_;
	return $self;
}

1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::drop_view  - generic handle for drop view

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::generic::handle::drop_view


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


