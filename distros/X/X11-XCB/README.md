# NAME

X11::XCB - perl bindings for libxcb

# SYNOPSIS

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

# DESCRIPTION

These bindings wrap libxcb (a C library to speak with X11, in many cases better
than Xlib in many aspects) and provide a nice object oriented interface to its
methods (using Mouse).

Please note that its aim is **NOT** to provide yet another toolkit for creating
graphical applications. It is a low-level method of communicating with X11. Use
cases include testcases for all kinds of X11 applications, implementing really
simple applications which do not require an graphical toolkit (such as GTK, QT,
etc.) or command-line utilities which communicate with X11.

**WARNING**: X11::XCB is in a rather early stage and thus API breaks may happen
in future versions. It is not yet widely used.

# SEE ALSO

- [http://xcb.freedesktop.org/](http://xcb.freedesktop.org/)

    The website of libxcb.

- [http://code.stapelberg.de/git/X11-XCB/](http://code.stapelberg.de/git/X11-XCB/)

    The git webinterface for the development of X11::XCB.

- [http://code.stapelberg.de/git/i3/tree/testcases?h=next](http://code.stapelberg.de/git/i3/tree/testcases?h=next)

    The i3 window manager includes testcases which use X11::XCB.

- [https://github.com/zhmylove/korgwm](https://github.com/zhmylove/korgwm)

    The korgwm is written entirely in Perl and based on X11::XCB.

# AUTHOR

Michael Stapelberg, &lt;michael+xcb@stapelberg.de>,
Maik Fischer, &lt;maikf+xcb@qu.cx>,
Sergei Zhmylev, &lt;zhmylove@narod.ru>

# INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

# COPYRIGHT AND LICENSE

Copyright (C) 2009-2023 Michael Stapelberg,
Copyright (C) 2011 Maik Fischer,
Copyright (C) 2023-2025 Sergei Zhmylev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
