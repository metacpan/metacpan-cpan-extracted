package blx::xsdsql::schema_repository::extra_tables;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7
use blx::xsdsql::generator;
use blx::xsdsql::ut::ut qw(ev);

sub factory_instance {
	my %params=@_;
	affirm { defined $params{DB_NAMESPACE} } "param DB_NAMESPACE not set";
	$params{OUTPUT_NAMESPACE}='sql' unless defined $params{OUTPUT_NAMESPACE};
	affirm { !defined $params{SQL_BINDING} }  "params SQL_BINDING is obsolete";
	affirm { !defined $params{BINDING} } "param BINDING is reserved";
	affirm { !defined $params{EXTRA_TABLES} } "param EXTRA_TABLES is reserved";
	affirm { grep( $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE} eq $_,blx::xsdsql::generator::get_namespaces) }
		 $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.": namespace not know"; 
	my $class='blx::xsdsql::schema_repository::'.$params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.'::extra_tables';
	ev('use',$class);
	return $class->_new(%params);
}

1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::extra_tables -  class for generate objet extra_tables

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::extra_tables

=cut

=head1 DESCRIPTION

this package is a class but not be instantiated



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

    factory_instance - instantiate an extra_tables object

    PARAMS
        OUTPUT_NAMESPACE     => output namespace (default sql)
        DB_NAMESPACE         => database namespace
        DEBUG                => if true set the debug mode



=head1 EXPORT

None by default.



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
