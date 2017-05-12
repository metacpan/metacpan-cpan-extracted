package blx::xsdsql::schema_repository::binding;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(ev);
use blx::xsdsql::generator;


sub factory_instance {
	my %params=@_; 
	affirm { defined $params{DB_NAMESPACE} } "param DB_NAMESPACE not set";
	$params{OUTPUT_NAMESPACE}='sql' unless defined $params{OUTPUT_NAMESPACE};
	affirm { grep( $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE} eq $_,blx::xsdsql::generator::get_namespaces) } $params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.": namespace not know"; 
	affirm { defined $params{DB_CONN} } "param DB_CONN not set";
	affirm { !defined $params{SQL_BINDING}} "params SQL_BINDING is obsolete";
	affirm { !defined $params{CURSOR_CLASS}} "param CURSOR_CLASS is reserved";
	my $class='blx::xsdsql::schema_repository::'.$params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.'::binding';
	my $cursor_class='blx::xsdsql::schema_repository::'.$params{OUTPUT_NAMESPACE}.'::'.$params{DB_NAMESPACE}.'::cursor';
	ev('use',$class);
	ev('use',$cursor_class);
	return $class->_new(%params,CURSOR_CLASS => $cursor_class);
}

1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::binding -  class for generate objects binding

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::binding

=cut

=head1 DESCRIPTION

this package is a class but not be instantiated



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

    factory_instance - instantiate an binding object

    PARAMS
        OUTPUT_NAMESPACE         => default sql
        DB_NAMESPACE             => default <none>
        DEBUG                    => if true set the debug mode
        EXECUTE_OBJECTS_PREFIX     => prefix for objects in execution
        EXECUTE_OBJECTS_SUFFIX     => suffix for objects in execution
        BINDING                    => if is set and if possible use it

=cut

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

