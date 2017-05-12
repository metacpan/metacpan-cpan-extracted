package Wx::Mozilla;

use 5.008;
use strict;
use warnings;
use Carp;
use Wx;
use base 'Wx::Window';

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Wx::Mozilla ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Wx::Mozilla', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Wx::Mozilla - Use the embedded Mozilla HTML rendering engine in WxPerl programs.

=head1 SYNOPSIS

  use Wx::Mozilla;

=head1 DESCRIPTION

This is an alpha version of the module. It works on a current stable
debian system, but past that you're somewhat on your own.

The module API is the same as the basic WxMozilla API, which is
generally the same as the basic Mozilla embedding API. In other words,
look elsewhere for documentation for right now.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Wx>

=head1 AUTHOR

Dan Sugalski, E<lt>dan@sidhe.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Sugalski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
