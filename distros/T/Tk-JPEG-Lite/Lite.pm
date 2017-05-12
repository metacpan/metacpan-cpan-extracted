package Tk::JPEG::Lite;
require DynaLoader;
use Tk 800.015;
require Tk::Image;
require Tk::Photo;
require DynaLoader;

use vars qw($VERSION $XS_VERSION);
$VERSION = '2.015';

@ISA = qw(DynaLoader);

$XS_VERSION = $Tk::VERSION;
bootstrap Tk::JPEG::Lite;

1;

__END__

=head1 NAME

Tk::JPEG::Lite - lite JPEG loader for Tk::Photo

=head1 SYNOPSIS

  use Tk;
  use Tk::JPEG::Lite; # you must not use Tk::JPEG simultaneously

  my $image = $widget->Photo('-format' => 'jpeg', -file => 'something.jpg');


=head1 DESCRIPTION

This is a version of Tk::JPEG using a shared library.

=head1 AUTHOR

The original Tk::JPEG is by Nick Ing-Simmons E<lt>nick@ni-s.u-net.comE<gt>

Stripped down to the lite version by Slaven Rezic E<lt>slaven@rezic.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2002-2004,2007 Slaven Rezic. All rights reserved. This
package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
