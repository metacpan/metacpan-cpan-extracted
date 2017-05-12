package blx::xsdsql::schema_repository::sql::DBM::extra_tables;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::xsd_parser::type::simple;
use base qw(blx::xsdsql::schema_repository::sql::generic::extra_tables);

use constant {
	PK_AUTOSEQUENCE_TYPE		=>  { XSD_TYPE 	=> 'integer',LIMITS		=> { INT => 18} }
	,DUMMY_COL_TYPE			=>  { XSD_TYPE	=> 'string',LIMITS		=> { SIZE => 1} }
};

use constant {
	PREDEF_TYPES	=>  {
		PK_AUTOSEQUENCE_TYPE		=>  PK_AUTOSEQUENCE_TYPE
		,DUMMY_COL_TYPE			=> DUMMY_COL_TYPE
	}
	
};
		
use constant {
	PREDEF_COLUMNS	=>  {
		PK_AUTOSEQUENCE =>  {
					NAME  		=> '$PK'
					,MINOCCURS 	=> 	1
					,MAXOCCURS 	=> 	1
					,PK_SEQ 	=> 	undef
					,TYPE		=>  PK_AUTOSEQUENCE_TYPE
					,PK_AUTOSEQUENCE	=> 1
		}
		,DUMMY_COL		=> {
					NAME  		=> '$DUMMY'
					,MINOCCURS 	=> 	1
					,MAXOCCURS 	=> 	1
					,TYPE		=>  DUMMY_COL_TYPE
					,COMMENT	=>  'dummy column'
		}
	}
};
		
sub factory_pk_col {
	my ($self,%params)=@_;
	my $col=$self->factory_column(qw(PK_AUTOSEQUENCE)); 
	return $col;
}

sub get_predefined_type {
	my ($self,$code,%params)=@_;
	affirm { defined $code } "1^ param not set";
	if ($code eq 'PK_AUTOSEQUENCE_TYPE') {
		my $t=PREDEF_TYPES->{$code};
		affirm { defined $t } "$code: 1^ param value not know";
		return blx::xsdsql::xsd_parser::type::simple->new(%$t,COLUMN => $params{COLUMN});
	}
	return $self->SUPER::get_predefined_type($code,%params);
}

sub get_predefined_column_attrs {
	my ($self,$code,%params)=@_;
	affirm { defined $code } "1^ param not set";
	if (defined (my $t=PREDEF_COLUMNS->{$code})) {
		return $t;
	}
	return $self->SUPER::get_predefined_column_attrs($code,%params);
}

sub _factory_extra_table_columns {
	my ($self,$table_type,%params)=@_;
	my @cols=$self->SUPER::_factory_extra_table_columns($table_type);
	return @cols if grep($table_type eq $_,qw(XML_CATALOG XML_ENCODING XML_ID));
	@cols=(
				$self->factory_pk_col(%params)
				,@cols
	);
	return @cols if $table_type ne 'COLUMN_DICTIONARY';
	push @cols,$self->factory_column(undef,NAME => 'pk_autosequence',TYPE => $self->get_predefined_type(qw(BOOLEAN_TYPE)));
	return @cols;
}

1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::DBM::extra_tables -  class for generate the object  not schema dependent for DBM

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::DBM::extra tables

=cut


=head1 DESCRIPTION

this package is a class - is instantiated automatically by blx::xsdsql::schema_repository::sql::generic::extra_tables


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
