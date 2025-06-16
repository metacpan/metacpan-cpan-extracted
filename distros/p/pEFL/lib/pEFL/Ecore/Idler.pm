package pEFL::Ecore::Idler;

use strict;
use warnings;

require Exporter;

use pEFL::PLSide;

our @ISA = qw(Exporter EcoreIdlerPtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL::Elm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('pEFL::Ecore::Idler');

sub add {
     my ($class,$func,$data) = @_;
     my $id = pEFL::PLSide::register_ecore_task_cb($func, $data);
     my $widget = _ecore_idler_add($func, $id);
     return $widget;
}

*new = \&add;

sub enterer_add {
    my ($class,$func,$data) = @_;
     my $id = pEFL::PLSide::register_ecore_task_cb($func, $data);
     my $widget = _ecore_idle_enterer_add($func, $id);
     return $widget;
}

sub enterer_before_add {
    my ($class,$func,$data) = @_;
     my $id = pEFL::PLSide::register_ecore_task_cb($func, $data);
     my $widget = _ecore_idle_enterer_before_add($func, $id);
     return $widget;
}

sub exiter_add {
    my ($class,$func,$data) = @_;
     my $id = pEFL::PLSide::register_ecore_task_cb($func, $data);
     my $widget = _ecore_idle_exiter_add($func, $id);
     return $widget;
}
 

package EcoreIdlerPtr;

our @ISA = qw();


package EcoreIdleEntererPtr;

our @ISA = qw();

package EcoreIdleExiterPtr;

our @ISA = qw();


# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Ecore::Idler

=head1 DESCRIPTION

This module is a perl binding to the Ecore Idle functions.

The idler functionality in Ecore allows for callbacks to be called when
the program isn't handling.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Ecore__Idle__Group.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
