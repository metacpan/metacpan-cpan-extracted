package pEFL::Ecore;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use pEFL::Ecore::Idler;
use pEFL::Ecore::Mainloop;
use pEFL::Ecore::Poller;
use pEFL::Ecore::Time;
use pEFL::Ecore::Timer;
use pEFL::Ecore::Event;
use pEFL::Ecore::EventFilter;
use pEFL::Ecore::EventHandler;
use pEFL::Ecore::Event::Key;
use pEFL::Ecore::Event::MouseButton;
use pEFL::Ecore::Event::MouseMove;
use pEFL::Ecore::Event::MouseWheel;
use pEFL::Ecore::Event::SignalExit;
use pEFL::Ecore::Event::SignalRealtime;
use pEFL::Ecore::Event::SignalUser;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	ECORE_VERSION_MAJOR
	ECORE_VERSION_MINOR
	ECORE_CALLBACK_CANCEL
	ECORE_CALLBACK_RENEW
	ECORE_CALLBACK_PASS_ON
	ECORE_CALLBACK_DONE
	ECORE_POLLER_CORE
	ECORE_EVENT_NONE
	ECORE_EVENT_SIGNAL_USER
	ECORE_EVENT_SIGNAL_HUP
	ECORE_EVENT_SIGNAL_EXIT
	ECORE_EVENT_SIGNAL_POWER
	ECORE_EVENT_SIGNAL_REALTIME
	ECORE_EVENT_MEMORY_STATE
	ECORE_EVENT_POWER_STATE
	ECORE_EVENT_LOCALE_CHANGED
	ECORE_EVENT_HOSTNAME_CHANGED
	ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED
	ECORE_EVENT_COUNT
	ECORE_EVENT_KEY_DOWN
	ECORE_EVENT_KEY_UP
	ECORE_EVENT_MOUSE_BUTTON_DOWN
	ECORE_EVENT_MOUSE_BUTTON_UP
	ECORE_EVENT_MOUSE_MOVE
	ECORE_EVENT_MOUSE_WHEEL
	ECORE_EVENT_MOUSE_IN
	ECORE_EVENT_MOUSE_OUT
	ECORE_EVENT_MODIFIER_SHIFT
	ECORE_EVENT_MODIFIER_CTRL
	ECORE_EVENT_MODIFIER_ALT
	ECORE_EVENT_MODIFIER_WIN
	ECORE_EVENT_MODIFIER_SCROLL
	ECORE_EVENT_MODIFIER_NUM
	ECORE_EVENT_MODIFIER_CAPS
	ECORE_EVENT_LOCK_SCROLL
	ECORE_EVENT_LOCK_NUM
	ECORE_EVENT_LOCK_CAPS
	ECORE_EVENT_LOCK_SHIFT
	ECORE_EVENT_MODIFIER_ALTGR
	ECORE_NONE
	ECORE_SHIFT
	ECORE_CTRL
	ECORE_ALT
	ECORE_WIN
	ECORE_SCROLL
	ECORE_CAPS
	ECORE_MODE
	ECORE_LAST
	ECORE_EVAS_OBJECT_ASSOCIATE_BASE
	ECORE_EVAS_OBJECT_ASSOCIATE_STACK
	ECORE_EVAS_OBJECT_ASSOCIATE_LAYER
	ECORE_EVAS_OBJECT_ASSOCIATE_DEL
	ECORE_EVAS_ENGINE_SOFTWARE_BUFFER
  	ECORE_EVAS_ENGINE_SOFTWARE_XLIB
  	ECORE_EVAS_ENGINE_XRENDER_X11
   	ECORE_EVAS_ENGINE_OPENGL_X11
   	ECORE_EVAS_ENGINE_SOFTWARE_XCB
   	ECORE_EVAS_ENGINE_XRENDER_XCB
   	ECORE_EVAS_ENGINE_SOFTWARE_GDI
   	ECORE_EVAS_ENGINE_SOFTWARE_DDRAW
   	ECORE_EVAS_ENGINE_DIRECT3D
   	ECORE_EVAS_ENGINE_OPENGL_GLEW
   	ECORE_EVAS_ENGINE_OPENGL_COCOA
   	ECORE_EVAS_ENGINE_SOFTWARE_SDL
   	ECORE_EVAS_ENGINE_DIRECTFB
   	ECORE_EVAS_ENGINE_SOFTWARE_FB
   	ECORE_EVAS_ENGINE_SOFTWARE_8_X11
   	ECORE_EVAS_ENGINE_SOFTWARE_16_X11
   	ECORE_EVAS_ENGINE_SOFTWARE_16_DDRAW
   	ECORE_EVAS_ENGINE_SOFTWARE_16_WINCE
   	ECORE_EVAS_ENGINE_OPENGL_SDL
   	ECORE_EVAS_ENGINE_EWS
   	ECORE_EVAS_ENGINE_PSL1GHT
   	ECORE_EVAS_ENGINE_WAYLAND_SHM
   	ECORE_EVAS_ENGINE_WAYLAND_EGL
   	ECORE_EVAS_ENGINE_DRM
   	ECORE_EVAS_ENGINE_OPENGL_DRM
	ECORE_EVAS_AVOID_DAMAGE_NONE
	ECORE_EVAS_AVOID_DAMAGE_EXPOSE
	ECORE_EVAS_AVOID_DAMAGE_BUILT_IN
);


require XSLoader;
XSLoader::load('pEFL::Ecore');

# Preloaded methods go here.

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Callback::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ($error) { croak $error; }
	{
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX		*$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
		*$AUTOLOAD = sub { $val };
#XXX	}
	}
	goto &$AUTOLOAD;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Ecore

=head1 DESCRIPTION

pEFL::Ecore contains the "ECORE_*" Constants.

Additional it contains the following general function:

=over 4

=item * pEFL::Ecore::init();

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<https://www.enlightenment.org/develop/legacy/api/c/start#ecore_main.html>

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut