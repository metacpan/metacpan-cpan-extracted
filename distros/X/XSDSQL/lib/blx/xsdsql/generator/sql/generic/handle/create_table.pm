package blx::xsdsql::generator::sql::generic::handle::create_table;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use base(qw(blx::xsdsql::generator::sql::generic::handle));

sub _get_create_prefix {
	my ($self,%params)=@_;
	return "create table";
}

sub get_binding_objects  {
	my ($self,$schema,%params)=@_;
	my $root_table=$schema->get_root_table;
	return wantarray ? ( $root_table ) : [ $root_table ];
}

sub table_header {
	my ($self,$table,%params)=@_;
	my $path=$table->get_attrs_value(qw(PATH));
	my $comm=defined  $path && !$params{NO_EMIT_COMMENTS} ? $table->comment('PATH: '.$path) : '';
	$self->{STREAMER}->put_line($self->_get_create_prefix,' ',$table->get_sql_name,"( $comm");
	return $self;
}

sub table_footer {
	my ($self,$table,%params)=@_;
	$self->{STREAMER}->put_line(')',$table->command_terminator);
	$self->{STREAMER}->put_line;
	return $self;
}

sub column {
	my ($self,$col,%params)=@_;
	my $first_column=$col->get_attrs_value(qw(COLUMN_SEQUENCE)) == 0 ? 1 : 0;
	my ($col_name,$col_type,$path)=($col->get_sql_name(%params),$col->get_sql_type(%params),$col->get_attrs_value(qw(PATH)));
	my $comm=defined $path && !$params{NO_EMIT_COMMENTS} ? 'PATH: '.$path : '';
	my $ref=$col->get_attrs_value(qw(TABLE_REFERENCE));
	$ref=$ref->get_sql_name if ref($ref) =~/::table/;
	$comm.=defined $ref && !$params{NO_EMIT_COMMENTS} ? ' REF: '.$ref : '';
	$comm=~s/^(\s+|\s+)$//;
	my $sqlcomm=length($comm) ?  $col->comment($comm) : '';
	$self->{STREAMER}->put_line("\t".($first_column ? '' : ',').$col_name."\t".$col_type."\t".$sqlcomm);
	return $self;
}

1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::create_table  - generic handle for create table

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::generic::handle::create_table


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


