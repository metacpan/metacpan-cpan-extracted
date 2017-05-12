package blx::xsdsql::generator::sql::generic::handle::create_view;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use base(qw(blx::xsdsql::generator::sql::generic::handle));

sub _get_create_prefix {
	my ($self,%params)=@_;
	return "create or replace view";
}

sub get_binding_objects  {
	my ($self,$schema,%params)=@_;
	my $table=$schema->get_root_table;
	return wantarray ? ( $table ) : [ $table ];
}

sub _alias_table {
	my ($self,%params)=@_;
	return " as ";
}

sub table_header {
	my ($self,$table,%params)=@_;
	return $self->_table_header($table,%params,STREAMER => $self->{STREAMER});
}

sub _table_header {
	my ($self,$table,%params)=@_;
	my $path=$table->get_attrs_value(qw(PATH));
	my $comm=defined  $path && !$params{NO_EMIT_COMMENTS} ? $table->comment('ROOTPATH: '.$path) : '';
	$params{STREAMER}->put_line($self->_get_create_prefix,' ',$table->get_view_sql_name," as select  $comm");
	my @cols=$self->_get_columns($table,%params);
	my $colseq=0;
	for my $col(@cols) {
		next unless $col->get_attrs_value(qw(VIEWABLE));
		next if $col->is_attribute;
		next if $col->is_sys_attributes;
		my $t=$col->get_attrs_value(qw(TABLE));
		my $sqlcomm=sub {
			return '' if $params{NO_EMIT_COMMENTS};
			my $path=$col->get_attrs_value(qw(PATH));
			my $comm=defined $path ? 'PATH: '.$path : '';
			my $ref=$col->get_attrs_value(qw(PATH_REFERENCE));
			$comm.=defined $ref ? ' REF: '.$ref : '';
			$comm=~s/^(\s+|\s+)$//;
			return length($comm) ?  $col->comment($comm) : '';
		}->();
		my $table_alias=sprintf("A_%0".length(scalar(@cols))."d",$t->get_attrs_value(qw(ALIAS_COUNT)));
		my $column_alias=$col->get_attrs_value(qw(ALIAS_NAME));
		$params{STREAMER}->put_line("\t".($colseq == 0 ? '' : ',').$table_alias,'.',$col->get_sql_name,' as ',$column_alias,' ',$sqlcomm);
		++$colseq;
	}
	$params{STREAMER}->put_line(' from ');
	for my $col(@cols) {
		my $t=$col->get_attrs_value(qw(TABLE));
		my $alias=sprintf("A_%0".length(scalar(@cols))."d",$col->get_attrs_value(qw(TABLE))->get_attrs_value(qw(ALIAS_COUNT)));

		if ($t->get_sql_name eq $table->get_sql_name) { #the start table
			$params{STREAMER}->put_line("\t",$t->get_sql_name,$self->_alias_table,$alias) if $col->is_pk && $col->get_pk_seq == 0;
		}
		my $table_ref=$col->get_attrs_value(qw(JOIN_TABLE));
		next unless defined $table_ref;
		my $alias_ref=sprintf("A_%0".length(scalar(@cols))."d",$table_ref->get_attrs_value(qw(ALIAS_COUNT)));
		$params{STREAMER}->put_chars("\t","left join ",$table_ref->get_sql_name,$self->_alias_table,$alias_ref,' on ');
		my @pk=$table_ref->get_pk_columns;
		$params{STREAMER}->put_chars("\t",$alias,'.',$col->get_sql_name,'=',$alias_ref,'.',$pk[0]->get_sql_name);
		$params{STREAMER}->put_chars("\t\tand ",$alias_ref,'.',$pk[1]->get_sql_name,'=0') if scalar(@pk) > 1;
		$params{STREAMER}->put_line;
	}
	$params{STREAMER}->put_line($table->command_terminator);
	return $self;
}

sub table_footer {
	my ($self,$table,%params)=@_;
	return $self;
}


1;


__END__

=head1 NAME

blx::xsdsql::generator::sql::generic::handle::create_view  - generic handle for create view

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::generic::handle::create_view


=head1 DESCRIPTION

this package is a class - instance it with the method new

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::generator::sql::generic::handle

get_view_columns - return an array of the view columns


get_join_columns - return an array of the join columns


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


