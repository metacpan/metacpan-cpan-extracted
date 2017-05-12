package blx::xsdsql::xml::base;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base(qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces));

sub _new {
	my ($class,%params)=@_;
	affirm { defined $params{BINDING} } 'param BINDING not set';
	$params{BINDING}=$params{BINDING}->get_clone; 
	bless \%params,$class;
}

sub finish {
	my ($self,%params)=@_;
	if (defined $self->{PREPARED}) {
		for my $table_name(keys %{$self->{PREPARED}}) {
			for my $op(keys %{$self->{PREPARED}->{$table_name}}) {
				if ($self->{PREPARED}->{$table_name}->{$op}) {
#					$self->_debug($params{TAG},"finish for table '$table_name' operation '$op'");
					(delete $self->{PREPARED}->{$table_name}->{$op})->finish(%params);
				}
			}
		}
	}
	$self;
}


sub DESTROY {
	$_[0]->finish(TAG => { PACKAGE => __PACKAGE__,LINE => __LINE__},NO_PENDING_CHECK => 1);
}

1;

__END__

=head1  NAME

blx::xsdsql::xml::base - internal class - base for read/write xml file from/to sql database

=cut

=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
