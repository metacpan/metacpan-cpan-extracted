package blx::xsdsql::schema_repository::sql::oracle::binding;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::schema_repository::sql::generic::binding);


sub _get_next_sequence {
	my ($self,%params)=@_;
	$self->{PREPARE_SEQUENCE}=$self->{DB_CONN}->prepare("select ".$self->{SEQUENCE_NAME}.".nextval from dual")
		unless defined $self->{PREPARE_SEQUENCE};
	$self->{PREPARE_SEQUENCE}->execute;
	my $r=$self->{PREPARE_SEQUENCE}->fetchrow_arrayref;
	return $r->[0];
}	

sub _get_sql_drop_table {
	my ($self,%params)=@_;
	return 'drop table %t cascade constraints purge';
}

sub _get_sql_drop_view {
	my ($self,%params)=@_;
	return 'drop view %v cascade constraints';
}


sub _information_tables {
	my ($self,%params)=@_;
	my $prep=undef;
	my $pref=$self->{EXECUTE_OBJECTS_PREFIX};
	my $suf=$self->{EXECUTE_OBJECTS_SUFFIX};
	$suf='' unless defined $suf;
	if (defined $pref  && $pref=~/\.$/) { 
		my ($cat,$schema)=$pref=~/^([^\.]+)\.([^\.]+)/;
		($schema)=$pref=~/^([^\.]+)/ unless defined $schema;
		affirm { defined $schema && !defined $cat } "$pref: the param 'EXECUTE_OBJECTS_PREFIX' is not correct"
					.' - must be <schema_name>.';
		$prep=$self->{DB_CONN}->prepare("
			select table_name 
			from all_all_tables$suf
			where owner=?
			order by owner,table_name
			)
		");
		$prep->bind_param(1,$schema);
	}
	else {
		$prep=$self->{DB_CONN}->prepare(
			q(
			select table_name from user_tables
			order by table_name
			)
		);
	}
	$prep->execute;
	my @t=();
	while(my $r=$prep->fetchrow_arrayref) {
		push @t,$r->[0];
	}
	$prep->finish;
	return wantarray ? @t : \@t;
}


sub _manip_value {
	my ($self,$col,$value,%params)=@_;
	if (defined $value) {
		my $t=$col->get_attrs_value(qw(TYPE_DUMPER));
		affirm { defined $t } "attribute TYPE_DUMPER not set for column ".nvl($col->get_full_name);
		if ($t->{BASE} eq 'boolean') {
			if ($value eq 'true' || $value eq '1') {
				$value='Y' ;
			}
			elsif($value eq 'false' || $value eq '0') {
				$value='N';
			}
			else {
				croak  "'$value': unknow value for type boolean"
			}
		}
	}
	return $value;
}


sub finish {
	my ($self,%params)=@_;
	local $self->{DB_CONN}->{RaiseError}=1;
	(delete $self->{PREPARE_SEQUENCE})->finish if defined $self->{PREPARE_SEQUENCE};
	return $self->SUPER::finish(%params);
}


1;




__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::oracle::binding -  a binding class for oracle

=cut

=head1 SYNOPSIS

  use blx::xsdsql::schema_repository::sql::oracle::binding

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of  blx::xsdsql::schema_repository::sql::generic::binding


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx::xsdsql::schema_repository::sql::generic::binding   - this class inerith for it

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::parser  for parse a xsd file (schema file)

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut




