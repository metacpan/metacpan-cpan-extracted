package blx::xsdsql::schema_repository::xml;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use Storable;

use base qw(blx::xsdsql::schema_repository::base);


sub new  { 
	my ($class,%params)=@_;
	return $class->SUPER::_new(%params);
}

sub store_xml {
	my ($self,$xml,%params)=@_;
	affirm { defined $params{CATALOG_NAME} } 'param CATALOG_NAME not set';
	my $id=$xml->read(%params);
	return unless defined $id;
	if (defined (my $na=$params{XML_NAME})) {
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_CATALOG));
		my $n=$self->{_BINDING}->insert_row_from_generic(
					$table
					,[$id,$params{CATALOG_NAME},$na]
					,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});	
		affirm { defined $n && $n == 1 } "the rows insert is not 1";
	}
	else {
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_ID));
		my $n=$self->{_BINDING}->insert_row_from_generic(
					$table
					,[$id,$params{CATALOG_NAME}]
					,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
		);
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});	
		affirm { defined $n && $n == 1 } "the rows insert is not 1";	
	}
	return $id;
}

sub put_xml {
	my ($self,$xml,%params)=@_;
	affirm {defined $params{ID} } 'param ID not set';
	my $r=$xml->write(%params,DELETE_ROWS => $params{DELETE},ROOT_ID => $params{ID});
	return unless defined $r;
	if ($params{DELETE}) {
		for my $k(qw( XML_CATALOG XML_ID)) {
			my $table=$self->{_EXTRA_TABLES}->get_extra_table($k);
			my $n=$self->{_BINDING}->delete_rows_from_generic(
							$table
							,[
								{COL => '$ID',VALUE => $params{ID}}
							],
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
			);
			$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
		}
	}
	return $params{ID};
}

sub get_xml_names {
	my ($self,%params)=@_;
	my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_CATALOG));
	my @where=();
	push @where,{ COL => 'catalog_name',VALUE => $params{CATALOG_NAME} } if defined $params{CATALOG_NAME};
	push @where,{ COL => 'xml_name',VALUE => $params{XML_NAME} } if defined $params{XML_NAME};

	my $prep=$self->{_BINDING}->generic_query_rows(
				$table
				,WHERE => \@where
				,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
			)
	;
	my @rows=();
	while(my $r=$prep->fetchrow_arrayref) {
		push @rows,Storable::dclone($r);
	}
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	return wantarray ? @rows : \@rows;
}

sub get_xml_ids {
	my ($self,%params)=@_;
	my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_ID));
	my @where=();
	push @where,{ COL => 'catalog_name',VALUE => $params{CATALOG_NAME} } if defined $params{CATALOG_NAME};
	push @where,{ COL => '$ID',VALUE => $params{ID} } if defined $params{ID};

	my $prep=$self->{_BINDING}->generic_query_rows(
						$table
						,WHERE => \@where 
						,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
					)
	;
	my @rows=();
	while(my $r=$prep->fetchrow_arrayref) {
		push @rows,Storable::dclone($r);
	}
	$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	return wantarray ? @rows : \@rows;
}

sub get_xml_stored {
	my ($self,%params)=@_;
	my %rows=();
	unless (defined $params{XML_NAME}) {
		my @where=();
		push @where,{ COL => '$ID',VALUE => $params{ID} } if defined $params{ID};
		push @where,{ COL => 'catalog_name',VALUE => $params{CATALOG_NAME} } if defined $params{CATALOG_NAME};
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_ID));
		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,WHERE => \@where
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
						)
		;
		while(my $r=$prep->fetchrow_arrayref) {
			my $clone=Storable::dclone($r);
			$clone->[2]=undef; # set the name to undef
			$rows{$r->[0]}=$clone;
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	{
		my $table=$self->{_EXTRA_TABLES}->get_extra_table(qw(XML_CATALOG));
		my @where=();
		push @where,{ COL => '$ID',VALUE => $params{ID} } if defined $params{ID};
		push @where,{ COL => 'catalog_name',VALUE => $params{CATALOG_NAME} } if defined $params{CATALOG_NAME};
		push @where,{ COL => 'xml_name',VALUE => $params{XML_NAME} } if defined $params{XML_NAME};

		my $prep=$self->{_BINDING}->generic_query_rows(
							$table
							,WHERE => \@where
							,TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__}
						)
		;
		while(my $r=$prep->fetchrow_arrayref) {
			$rows{$r->[0]}=Storable::dclone($r);
		}
		$self->{_BINDING}->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__});
	}
	my @rows=();
	for my $k(sort { $a <=> $b } keys %rows) { #numeric sort
		push @rows,$rows{$k};
	}
	return wantarray ? @rows : \@rows;
}

1; 

__END__


=head1  NAME

blx::xsdsql::schema_repository::xml - internal class for read/write xml file from/to sql database

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::xml

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new


=head1 SEE ALSO

See blx::xsdsql::schema_repository - is a frontend from this class


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



