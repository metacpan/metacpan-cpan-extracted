package blx::xsdsql::generator::sql::generic::handle::create_extra_tables;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::schema_repository::sql::generic::column;
use base(qw(blx::xsdsql::generator::sql::generic::handle));

sub _get_create_prefix {
	my ($self,%params)=@_;
	return "create table";
}

sub table_header {
	my ($self,$dic,%params)=@_;	
	my $comment=$params{NO_EMIT_COMMENTS} ? '' : $dic->get_comment;
	$self->{STREAMER}->put_line($self->_get_create_prefix,' ',$dic->get_sql_name,"( ",$comment);
	for my $col($dic->get_columns) {
		my $first_column=$col->get_attrs_value(qw(COLUMN_SEQUENCE)) == 0 ? 1 : 0;
		my $comment=$params{NO_EMIT_COMMENTS} ? '' : $col->get_comment;
		$self->{STREAMER}->put_line("\t".($first_column ? '' : ',').$col->get_sql_name."\t".$col->get_sql_type."\t".$comment);
	}
	$self->{STREAMER}->put_line(')',$dic->command_terminator);
	$self->{STREAMER}->put_line;
	$self->_create_indexes($dic,%params);
	return $self;
}



1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::create_extra_tables  - generic handle for create objects not schema dependend

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::generic::handle::create_dictionary


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


