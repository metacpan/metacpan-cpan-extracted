package blx::xsdsql::generator::sql::DBM::handle::insert_dictionary;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::generator::sql::generic::handle::insert_dictionary);

sub _manip_value { #manip values from input data
	my ($self,$col,$value,%params)=@_;
	if (defined $value) {
		my $t=$col->get_attrs_value(qw(TYPE_DUMPER));
		affirm { defined $t } "attribute TYPE_DUMPER not set for column ".nvl($col->get_full_name);
		if ($t->{BASE} eq 'boolean') {
			if ($value eq '1') {
				$value='Y' ;
			}
			elsif($value eq '0') {
				$value=undef;
			}
			else {
				croak  "'$value': unknow value for type boolean"
			}
		}
	}
	return $self->SUPER::_manip_value($col,$value,%params);
}

{
	my $counter=0;
	sub _get_next_sequence {
		my ($self,%params)=@_;
		return ++$counter if $counter;
		local $@;
		my $n=eval {  
			local $self->{BINDING}->get_attrs_value(qw(DB_CONN))->{PrintError}; 
			$self->{BINDING}->get_next_sequence 
		};
		$@ ? ++$counter : $n;
	}
}

sub _get_table_columns_data {
	my ($self,$extra_tables,$table,$type,%params)=@_;
	my $dic=$extra_tables->{$type};
	affirm { defined $dic } "'$type': wrong table type";
	my $data=$self->_get_table_data($table,$type,%params);
	my $columns=$self->_get_dictionary_columns($dic);
	if ($columns->[0]->get_attrs_value(qw(PK_AUTOSEQUENCE))) {
		affirm { !defined $self->{SQL_BINDING} } "attribute SQL_BINDING is obsolete";
		affirm { defined $self->{BINDING} } "attribute BINDING not set";
		unless ( defined $self->{BINDING}->get_attrs_value(qw(SEQUENCE_NAME))) {
			affirm { defined $self->{EXTRA_TABLES} } "attribute EXTRA_TABLES not set";
			my $extra_tables=$self->{EXTRA_TABLES};
			my $seq_name=$extra_tables->get_sequence_name;
			$self->{BINDING}->set_attrs_value(SEQUENCE_NAME => $seq_name);
			affirm { defined $self->{BINDING}->get_attrs_value(qw(SEQUENCE_NAME)) } "binding object not has attribute SEQUENCE_NAME set"; 
		}
		if (ref($data) eq 'ARRAY') {
			for my $d(@$data) {
				$d->{'$PK'}=$self->_get_next_sequence;
			}
		}
		else {
			$data->{'$PK'}=$self->_get_next_sequence;
		}
	}
	return ($columns,$data);
}

1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::DBM::handle::insert_dictionary  - insert dictionary  for DBM

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::DBM::handle::insert_dictionary


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


See  blx::xsdsql::generator::sql::generic::handle::insert_dictionary  - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



