package X11::XCB;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.24';

use Exporter 'import';

our @EXPORT;
our %EXPORT_TAGS = (all => []); # will be populated by XS
*EXPORT_OK = $EXPORT_TAGS{all};

require XSLoader;
XSLoader::load('X11::XCB', $VERSION);

use XS::Object::Magic;

sub new {
    # XXX $screenp currently unused
    my ($class, $display, $screenp) = @_;

    $display //= '';

    my $self = bless { display => $display }, $class;

    $self->_connect_and_attach_struct;

    return $self;
}

1;
__END__

=head1 NAME

X11::XCB - perl bindings for libxcb

=head1 SYNOPSIS

  use X11::XCB::Connection;
  my $x = X11::XCB::Connection->new;

  my $window = $x->root->create_child(
    class => X11::XCB::WINDOW_CLASS_INPUT_OUTPUT(),
    rect => [0, 0, 200, 200],
    background_color => '#FF00FF',
  );

  $window->map;
  print "Press Enter to continue\n";
  <>;

=head1 DESCRIPTION

These bindings wrap libxcb (a C library to speak with X11, in many cases better
than Xlib in many aspects) and provide a nice object oriented interface to its
methods (using Mouse).

Please note that its aim is B<NOT> to provide yet another toolkit for creating
graphical applications. It is a low-level method of communicating with X11. Use
cases include testcases for all kinds of X11 applications, implementing really
simple applications which do not require an graphical toolkit (such as GTK, QT,
etc.) or command-line utilities which communicate with X11.

B<WARNING>: X11::XCB is in a rather early stage and thus API breaks may happen
in future versions. It is not yet widely used.

=head1 SEE ALSO

=over

=item L<http://xcb.freedesktop.org/>

The website of libxcb.

=item L<https://github.com/zhmylove/X11-XCB>

The git webinterface for the development of X11::XCB.

=item L<http://code.stapelberg.de/git/i3/tree/testcases?h=next>

The i3 window manager includes testcases which use X11::XCB.

=item L<https://github.com/zhmylove/korgwm>

The korgwm is written entirely in Perl and based on X11::XCB.

=back

=head1 AUTHOR

Michael Stapelberg, E<lt>michael+xcb@stapelberg.deE<gt>,
Maik Fischer, E<lt>maikf+xcb@qu.cxE<gt>,
Sergei Zhmylev, E<lt>zhmylove@narod.ruE<gt>

=head1 INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2023 Michael Stapelberg,
Copyright (C) 2011 Maik Fischer,
Copyright (C) 2023-2025 Sergei Zhmylev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
