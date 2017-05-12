package blx::xsdsql::schema_repository::sql::generic::cursor;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use blx::xsdsql::ut::ut qw(nvl ev);


use base qw(blx::xsdsql::ios::debuglogger);

sub _manip_value {
	my ($self,$col,$value,%params)=@_;
	croak "abstract method";
}

sub _new {
	my ($class,%params)=@_;
	affirm { defined $params{BINDING}	} 	"param BINDING not set";
	return bless \%params,$class;
}

sub get_binding_table { 
	my ($self,%params)=@_;
	$self->{BINDING}->get_binding_table;
}

sub fetchrow_arrayref {
	my ($self,%params)=@_;
	my $r=$self->{BINDING}->{STH}->fetchrow_arrayref;
	return unless defined $r;
	my $cols=$self->{BINDING}->{BINDING_DISPLAY};
	affirm { scalar(@$r) == scalar(@$cols) } "number of elements read is not equal to columns number";
	my @r=map { $self->_manip_value($cols->[$_],$r->[$_]) } (0..scalar(@$r) - 1); 
	\@r;
}

sub finish {
	my ($self,%params)=@_;
	my $t=$self->get_binding_table(%params);
	$self->_debug($params{TAG},'finish cursor for table ',$t->get_sql_name) if defined $t;
	$self->{BINDING}->{STH}->finish if defined $self->{BINDING}->{STH};
	$self;
}


1;


__END__



=head1  NAME

blx::xsdsql::schema_repository::sql::generic::cursor -  wrapper to DBI cursor

=cut

=head1 SYNOPSIS

this class is an abstract class base of database depending cursor  class


=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
