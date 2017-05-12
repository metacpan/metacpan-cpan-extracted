package blx::xsdsql::schema_repository::stowage;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ios::ostream;
use blx::xsdsql::ios::debuglogger;
use blx::xsdsql::ut::ut qw(nvl);

use base qw(blx::xsdsql::schema_repository::base);

sub _sql_handle {
	my ($ostr,$sql,%params)=@_;
	$sql=~s/^\s+//m;
	my $sep=$ostr->{LINE_SEPARATOR};
	$sql=~s/$sep\s*$//m;
	if (length($sql)) {
		$ostr->{LOG}->log({ PACKAGE => __PACKAGE__,LINE => __LINE__ },$sql);
		if ($ostr->{IGNORE_ERRORS}) {
			local $@;
			eval { $ostr->{DB_CONN}->do($sql) };
			print STDERR $@ if $@;
		}
		else {
			$ostr->{DB_CONN}->do($sql);
		}
	} 
	return 1;
}

sub _sql_handle_create_view {
	my ($ostr,$sql,%params)=@_;
	$sql=~s/^\s+//m;
	my $sep=$ostr->{LINE_SEPARATOR};
	$sql=~s/$sep\s*$//m;
	my $insert=0;
	if (length($sql)) {
		$ostr->{LOG}->log({ PACKAGE => __PACKAGE__,LINE => __LINE__ },$sql);
		if ($ostr->{IGNORE_ERRORS}) {
			local $@;
			eval { $ostr->{DB_CONN}->do($sql) };
			print STDERR $@ if $@;
			$insert=1 unless $@;
		}
		else {
			$ostr->{DB_CONN}->do($sql);
			$insert=1;
		}
		if ($insert) {
			my ($view_name)=$sql=~/\s*create\s+or\s+replace\s+view\s+(\S+)/mi;
			($view_name)=$sql=~/\s*create\s+view\s+(\S+)/mi unless defined $view_name;
			croak "$sql: not view name in this sql expression\n" unless defined $view_name;
			my $table=$ostr->{EXTRA_TABLES}->get_extra_table(qw(VIEW_DICTIONARY));
			$ostr->{BINDING}->delete_rows_from_generic(
						$table,
						[
							{COL => 'catalog_name',VALUE => $ostr->{CATALOG_NAME}}
							,{COL=> 'view_name',VALUE => $view_name}
						],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
			);
			$ostr->{BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});						
			my $n=$ostr->{BINDING}->insert_row_from_generic(
						$table
						,[$ostr->{CATALOG_NAME},$view_name]
						,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
			);
			$ostr->{BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});	
			affirm { defined $n && $n == 1 } "the rows insert is not 1";
			print STDERR "create view '$view_name'\n";
		}
	} 
	return 1;
}

sub new  { 
	my ($class,%params)=@_;
	return $class->SUPER::_new(%params);
}

sub is_repository_installed {
	my ($self,%params)=@_;
	my $name=lc($self->{_EXTRA_TABLES}->get_extra_table('CATALOG_DICTIONARY')->get_sql_name);
	my @tables=$self->{_BINDING}->information_tables;
	return grep(lc($_) eq $name,@tables) ? 1 : 0;	
}


sub create_repository {
	my ($self,%params)=@_;
	my $ostr= defined $params{FD} 
				? $params{FD}
				: blx::xsdsql::ios::ostream->new(
					OUTPUT_STREAM 		=> \&_sql_handle
					,LINE_SEPARATOR 	=> $self->{_EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->command_terminator
					,DB_CONN 			=> $self->{DB_CONN}
					,LOG     			=> $self->{_LOGGER}
				);
	for my $cmd(qw(create_sequence create_dictionary )) {
		$self->{_GENERATOR}->generate(COMMAND => $cmd,FD => $ostr,,NO_EMIT_COMMENTS	=> defined $params{FD}  ? 0 : 1);
	}
	$ostr->flush;
	$self;
}

sub drop_repository {
	my ($self,%params)=@_;
	my $ostr= defined $params{FD} 
				? $params{FD}
				: blx::xsdsql::ios::ostream->new(
					OUTPUT_STREAM 		=> \&_sql_handle
					,LINE_SEPARATOR 	=> $self->{_EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->command_terminator
					,DB_CONN 			=> $self->{DB_CONN}
					,LOG     			=> $self->{_LOGGER}
					,IGNORE_ERRORS		=> 1
				);
	for my $cmd(qw(drop_dictionary drop_sequence)) {
		$self->{_GENERATOR}->generate(COMMAND => $cmd,FD => $ostr,,NO_EMIT_COMMENTS	=> defined $params{FD}  ? 0 : 1);
	}
	$ostr->flush;
	return $self;
}

sub create_catalog {
	my ($self,$catalog_name,$schema,%params)=@_;
	my $ostr= defined $params{FD} 
				? $params{FD}
				: blx::xsdsql::ios::ostream->new(
					OUTPUT_STREAM 		=> \&_sql_handle
					,LINE_SEPARATOR 	=> $self->{_EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->command_terminator
					,DB_CONN 			=> $self->{DB_CONN}
					,LOG     			=> $self->{_LOGGER}
				);
	
	return if !defined $params{FD} && grep($catalog_name eq $_,$self->get_catalog_names);
	my $schema_code=$params{SCHEMA_CODE};
	$schema_code='ROOT_SCHEMA' unless defined $schema_code;
	for my $cmd(qw(create_table addpk insert_dictionary)) {
		$self->{_GENERATOR}->generate(
				COMMAND 			=> $cmd
				,CATALOG_NAME		=> $catalog_name 
				,SCHEMA				=> $schema
				,SCHEMA_CODE 		=> $schema_code
				,FD 				=> $ostr
				,NO_EMIT_COMMENTS	=> defined $params{FD}  ? 0 : 1
		);
	}
	$ostr->flush;
	$schema->set_attrs_value(SCHEMA_CODE => $schema_code,CATALOG_NAME => $catalog_name);
	$self;
}



sub drop_catalog {
	my ($self,$cat,%params)=@_;
	my $conn=$self->{DB_CONN};	
	my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(TABLE_DICTIONARY));
	my $prep=$self->{_BINDING}->generic_query_rows(
						$table
						,DISPLAY 	=> [ qw(table_name path_name) ]
						,WHERE 		=> [ 
											{ COL => 'catalog_name',VALUE => $cat } 
										]
						,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
	);	
	my @root_tables=();
	my @not_root_tables=();
	while(my $r=$prep->fetchrow_arrayref) {
		if (nvl($r->[1]) eq '/') {
			push @root_tables,$r->[0];
		}
		else {
			push @not_root_tables,$r->[0];
		}
	}
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	
	my @root_ids=();
	for my $t(@root_tables) {
		my $prep=$conn->prepare("select id from $t");
		$prep->execute;
		while(my $r=$prep->fetchrow_arrayref) {
			push @root_ids,$r->[0];
		}
		$prep->finish;
	}
		
	my @dtd_tables=map { $self->{_EXTRA_TABLES}->get_extra_table($_) } $self->{_EXTRA_TABLES}->get_extra_table_types('DTD_TABLES');
	for my $t(@dtd_tables) {
		for my $id(@root_ids) {
			$self->{_BINDING}->delete_rows_for_id($t,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}	
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	my $xml_encoding=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_ENCODING));
	for my $id(@root_ids) {
		$self->{_BINDING}->delete_rows_for_id($xml_encoding,$id,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}	
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	
	my @dic_tables=map { $self->{_EXTRA_TABLES}->get_extra_table($_) } 
			grep($_ ne 'XML_ENCODING',$self->{_EXTRA_TABLES}->get_extra_table_types(qw(DICTIONARY_TABLES)));
			
	for my $t(@dic_tables) {
		$self->{_BINDING}->delete_rows_from_generic($t,[{COL => 'catalog_name',VALUE => $cat}],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	for my $t(@root_tables,@not_root_tables) {
		$self->{_BINDING}->drop_table($t,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	
	return $self;
	
}

sub create_catalog_views {
	my ($self,$catalog_name,$schema,%params)=@_;
	my $ostr= defined $params{FD} 
				? $params{FD}
				: blx::xsdsql::ios::ostream->new(
					OUTPUT_STREAM 		=> \&_sql_handle_create_view
					,LINE_SEPARATOR 	=> $self->{_EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->command_terminator
					,DB_CONN 			=> $self->{DB_CONN}
					,LOG     			=> $self->{_LOGGER}
					,CATALOG_NAME		=> $catalog_name
					,BINDING			=> $self->{_BINDING}
					,EXTRA_TABLES		=> $self->{_EXTRA_TABLES}
				);
	
	return if !defined $params{FD} && !grep($catalog_name eq $_,$self->get_catalog_names);
	for my $cmd(qw(create_view)) {
		$self->{_GENERATOR}->generate(
				COMMAND 			=> $cmd
				,CATALOG_NAME		=> $catalog_name 
				,SCHEMA				=> $schema
				,SCHEMA_CODE 		=> $schema->get_attrs_value(qw(SCHEMA_CODE))
				,FD 				=> $ostr
				,NO_EMIT_COMMENTS	=> defined $params{FD}  ? 0 : 1
				,map { 
					($_,$params{$_})
				} qw(TABLES_FILTER MAX_VIEW_COLUMNS MAX_VIEW_JOINS VIEWS_FROM_LEVEL)				
		);
	}
	
	$ostr->flush;
	$self;
}

sub drop_catalog_views {
	my ($self,$catalog_name,%params)=@_;
	my $conn=$self->{DB_CONN};	
	my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(VIEW_DICTIONARY));
	my $prep=$self->{_BINDING}->generic_query_rows(
						$table
						,DISPLAY 	=> [ qw(view_name) ]
						,WHERE 		=> [ 
											{ COL => 'catalog_name',VALUE => $catalog_name } 
										]
						,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
	);	
	my @views=(); 
	while(my $r=$prep->fetchrow_arrayref) { push @views,$r->[0]; }
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	
	$self->{_BINDING}->delete_rows_from_generic($table,[{COL => 'catalog_name',VALUE => $catalog_name}],TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	for my $v(@views) { 
		$self->{_BINDING}->drop_view($v,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}); 
	}
	return $self;
}


sub get_catalog_names {
	my ($self,%params)=@_;
	my $catalog_table=$self->{_EXTRA_TABLES}->get_extra_table('CATALOG_DICTIONARY');

	my $prep=$self->{_BINDING}->generic_query_rows(
						$catalog_table
						,DISPLAY 	=> [ qw(catalog_name) ]
						,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
	);	
	my @rows=();
	while(my $r=$prep->fetchrow_arrayref) {
		push @rows,$r->[0];
	}
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	return wantarray ? @rows : \@rows;
}


sub get_catalog_object_names {
	my ($self,%params)=@_;
	my @rows=();
	if (!defined $params{TYPE} || $params{TYPE} eq 'table') {
		my $table=$self->{_EXTRA_TABLES}->get_extra_table('TABLE_DICTIONARY');
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY 	=> [qw(catalog_name table_name) ]
							,WHERE		=> defined $params{CATALOG_NAME} 
												? [ { COL => 'catalog_name',VALUE => $params{CATALOG_NAME} }]
												: undef
							,ORDER		=> [qw(catalog_name table_name) ]
							,TAG 		=> { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		$prep->execute;
		while(my $r=$prep->fetchrow_arrayref) {
			push @rows,[ 'T',$r->[0],$r->[1]];
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	if (!defined $params{TYPE} || $params{TYPE} eq 'view') {
		my $table=$self->{_EXTRA_TABLES}->get_extra_table('VIEW_DICTIONARY');
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,DISPLAY 	=> [qw(catalog_name view_name) ]
							,WHERE		=> defined $params{CATALOG_NAME} 
												? [ { COL => 'catalog_name',VALUE => $params{CATALOG_NAME} }]
												: undef
							,ORDER		=> [qw(catalog_name view_name) ]
							,TAG 		=> { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		while(my $r=$prep->fetchrow_arrayref) {
			push @rows,[ 'V',$r->[0],$r->[1]];
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	return wantarray ? @rows : \@rows;
} 

1;



__END__



=head1  NAME

blx::xsdsql::schema_repository::stowage -  internal class for store a catalog

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::stowage

=cut

=head1 SEE ALSO

See blx::xsdsql::schema_repository - is a frontend from this class

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
