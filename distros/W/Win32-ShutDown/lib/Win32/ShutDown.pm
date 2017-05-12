package Win32::ShutDown;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::ShutDown ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
 ShutDown
 Restart
 LogOff
 SetItAsLastShutDownProcess
 ForceReStart
 ForceLogOff
 ForceShutDown

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Win32::ShutDown', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::ShutDown - a perl extension to let you shutdown and/or restart and/or logoff a Windows PC

=head1 SYNOPSIS

  use Win32::ShutDown;
  Win32::ShutDown::ForceShutDown(); # Turns off the PC, no matter what :-)

=head1 DESCRIPTION

See the documentation in the .xs module for:-

ShutDown()
Restart()
LogOff()
SetItAsLastShutDownProcess()
ForceReStart()
ForceLogOff()
ForceShutDown()

=head2 EXPORT

None by default.

=head1 AUTHOR

=head1 AUTHOR

C. N. Drake, E<lt>christopher@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by C. N. Drake.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
