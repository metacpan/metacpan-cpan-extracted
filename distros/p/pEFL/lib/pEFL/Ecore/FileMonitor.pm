package pEFL::Ecore::FileMonitor;

use strict;
use warnings;

require Exporter;

use pEFL::PLSide;

our @ISA = qw(Exporter EcoreFileMonitorPtr);

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
XSLoader::load('pEFL::Ecore::FileMonitor');

sub add {
     my ($class,$path,$func,$data) = @_;
     my $id = pEFL::PLSide::register_ecore_file_monitor_cb($path, $func, $data);
     my $widget = _ecore_file_monitor_add($path, $func, $id);
     return $widget;
}
 
*new = \&add;

package EcoreFileMonitorPtr;

our @ISA = qw();

sub del {
	my ($filemonitor) = @_;
	
	# Cleanup C
	my $path = $filemonitor->path_get();
	_ecore_file_monitor_del($filemonitor);
	
	# Cleanup Perl
	foreach my $cb (@pEFL::PLSide::EcoreFileMonitor_Cbs) {
		if ($cb->{path} eq $path) {
			$cb = undef;
		}
	}
}


# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Ecore::FileMonitor

=head1 DESCRIPTION

This module is a perl binding to the Ecore File Monitor functions.

Ecore File Monitor provides infrastructure for the creation of file monitors.

Please note that only one filemonitor per path is possible.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Ecore__File__Group.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
