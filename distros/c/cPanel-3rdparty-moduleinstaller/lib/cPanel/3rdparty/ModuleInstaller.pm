package cPanel::3rdparty::ModuleInstaller;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use cPanel::3rdparty::ModuleInstaller ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.0.6';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

cPanel::3rdparty::ModuleInstaller - Perl extension for cPanel Module Installer

=head1 SYNOPSIS

  use cPanel::3rdparty::ModuleInstaller;
  
=head1 DESCRIPTION

This extension is a helper for installation of modules in WHM with root access.
It allows administrators to install a module in CGI folder of WHM without going
into shell.


=head2 EXPORT

None at this time.



=head1 SEE ALSO

http://www.cpanel.net/
http://www.cpios.com/


=head1 AUTHOR

Farhad Malekpour, E<lt>fm@farhad.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Dayana Networks Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
