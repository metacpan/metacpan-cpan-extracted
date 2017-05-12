package blx::xsdsql::schema_repository::sql::DBM::binding;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::schema_repository::sql::generic::binding);

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
				$value='N'
			}
			else {
				croak  "'$value': unknow value for type boolean"
			}
		}
	}
	return $value;
}

sub _get_sql_drop_table {
	my ($self,%params)=@_;
	return "drop table %t";
}

sub _get_next_sequence {
	my ($self,%params)=@_;
	my $seq=$self->{SEQUENCE_NAME};

	my $sql="select * from $seq";
#	$self->_debug($params{TAG},$sql);
	my $prep=$self->{DB_CONN}->prepare($sql);
	$prep->execute;
	my $r=$prep->fetchrow_arrayref;
	my $n=defined $r ? $r->[0] : 0;
	$prep->finish;

	$sql="delete $seq";
#	$self->_debug($params{TAG},$sql);
	$prep=$self->{DB_CONN}->prepare($sql);
	$prep->execute;
	$prep->finish;
	
	$sql="insert into  $seq values(?,?)";	
#	$self->_debug($params{TAG},$sql);
	$prep=$self->{DB_CONN}->prepare($sql);
	$prep->bind_param(1,++$n);
	$prep->bind_param(2,undef);
	$prep->execute;
	$prep->finish;
	return $n;	
}

sub _information_tables {
	my ($self,%params)=@_;	

#	my ($catalog,$schema,$table,$type)=('','','','TABLE');
#	my $sth = $self->{DB_CONN}->table_info( $catalog, $schema, $table, $type );
#  table_info return undef 
#
	my @t=();
	my $dbh=$self->{DB_CONN};
	my $dir=$dbh->{f_dir};
	$dir="." unless defined $dir;
	if (opendir(my $d,$dir)) {
		while(my $f=readdir($d)) {
			next if -d $f;
			next unless $f=~/\.lck$/;
			$f=~s/\.lck$//;
			push @t,$f;
		}
		closedir($d);
	}
	else {
		croak "$dir: failed to open directory";
	}
	my @t1=sort @t;
	return wantarray ? @t1 : \@t1;
}

sub _get_column_value_init {
	my ($self,$table,$col,%params)=@_;
	return $self->get_next_sequence(%params) if $col->get_attrs_value(qw(PK_AUTOSEQUENCE));
	return $self->SUPER::_get_column_value_init($table,$col,%params);
}


1;


__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::DBM::binding -  a binding class for DBM

=cut

=head1 SYNOPSIS

  use blx::xsdsql::schema_repository::sql::DBM::binding

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

