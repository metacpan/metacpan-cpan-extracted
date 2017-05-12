package blx::xsdsql::connection::sql::databases::oracle;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::connection::sql::base);

use constant {
		CODE  => 'dbi:Oracle'
};


sub _get_connection_list {
	my ($self,$h,%params)=@_;
	my @args=();
	my $s=CODE.':';
	$s.="host=".$h->{HOST}.';' if defined $h->{HOST};
	$s.="sid=".$h->{DBNAME}.';' if defined $h->{DBNAME};
	$s.="port=".$h->{PORT}.';' if defined $h->{PORT};
	push @args,$s;
	push @args,$h->{USER};
	push @args,$h->{PWD};
	return (undef,@args);
}



1;

__END__


=head1  NAME

blx::xsdsql::connection::sql::databases::DBM -  internal class for oracle

=cut



=head1 SEE ALSO

blx::xsdsql::connection - this is the main class for generate connection

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
