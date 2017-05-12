# NAME

X11::WMCtrl - a Perl wrapper for the `wmctrl` program.

# SYNOPSIS

        use X11::WMCtrl;
        use strict;

        my $wmctrl = X11::WMCtrl->new;

        printf("window manager is %s\n", $wmctrl->get_window_manager->{name});

        my @windows = $wmctrl->get_windows;

        my $workspaces = $wmctrl->get_workspaces;

        $wmctrl->switch(1);

        my $app = $windows[0]->{title};

        $wmctrl->maximize($app);
        $wmctrl->unmaximize($app);
        $wmctrl->shade($app);
        $wmctrl->unshade($app);

        $wmctrl->close($app);

# DESCRIPTION

The `wmctrl` program is a command line tool to interact with an EWMH/NetWM compatible X Window Manager.

It provides command line access to almost all the features defined in the EWMH specification. Using it, it's possible to, for example, obtain information about the window manager, get a detailed list of desktops and managed windows, switch and resize desktops, change number of desktops, make windows full-screen, always-above or sticky, and activate, close, move, resize, maximize and minimize them.

The X11::WMCtrl module provides a simple wrapper to this program.

The `wmctrl` program can be downloaded from [http://sweb.cz/tripie/utils/wmctrl/](http://sweb.cz/tripie/utils/wmctrl/).

# CONSTRUCTOR

        my $wmctrl = X11::WMCtrl->new;

This returns a new X11::WMCtrl object. It will fail if an executable `wmctrl` program can't be found.

        my $wm = $wmctrl->get_window_manager;

This returns a hashref of information about the current window manager. The contents of the hash will vary depending on which one is in use - about the only one you can rely on is `name`.

        my @windows = $wmctrl->get_windows;

This method returns an array of hash references with information about the currently managed windows. Each element will contain these keys:

- `id` - the internal ID of the window
- `workspace` - the workspace number of the window. Workspaces are zero indexed. If the workspace value is -1, then the window is 'sticky'.
- `host` - the hostname of the X client drawing the window.
- `title` - the title of the window.

        my $workspaces = $wmctrl->get_workspaces;

This methods returns a hash ref. The keys are the workspaces IDs, and the values are their names.

        $wmctrl->switch($workspace);

Switch to workspace `$workspace`.

        $wmctrl->activate($window);

Activate the window with the title `$window` by switching to its workspace and raising it.

        $wmctrl->close($window);

Tell the window with the title `$window` to close.

        $wmctrl->move_activate($window);

Activate the window with the title `$window` by moving it to the current workspace and raising it.

        $wmctrl->move_to($window, $workspace);

Moves the window with the title `$window` to the workspace `$workspace`.

        $wmctrl->maximize($window);

Maximize `$window`.

        $wmctrl->unmaximize($window);

Unaximize `$window`.

        $wmctrl->minimize($window);

Minimize `$window`.

        $wmctrl->unminimize($window);

Unminimize `$window`.

        $wmctrl->shade($window);

Shade `$window`.

        $wmctrl->unshade($window);

Unshade `$window`.

        $wmctrl->sticky($window);

Make the window `$window` sticky.

        $wmctrl->unstick($window);

Removes the 'sticky' property from `$window`.

        $wmctrl->fullscreen($window);

Make `$window` full-screen.

        $wmctrl->unfullscreen($window);

Restore `$window` from full-screen mode.

        $wmctrl->wmctrl(@args);

This methods allows you to send instructions directly to wmctrl. This is used by X11::WMCtrl internally, but if you want to do something that the module doesn't support, this is the easiest way.

        $wmctrl->modify_state($window, $mod, @params);

This is another low-level function for sending state modifications to windows. The value of `$mod` can be either `add` or `remove`. `@params` may have either one or two elements. They may be any of the following:

        modal, sticky, maximized_vert, maximized_horz,
        shaded, skip_taskbar, skip_pager, hidden,
        fullscreen, above, below

# INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

# BUGS

Currently `stick()`, `unstick()`, `minimize()` and `unminimize()` don't work. This appears to be a problem with `wmctrl` itself since.

# AUTHOR

Gavin Brown ([gavin.brown@uk.com](https://metacpan.org/pod/gavin.brown@uk.com)).

# COPYRIGHT

Copyright (c) 2014 Gavin Brown. This program is free software, you can use it and/or modify it under the same terms as Perl itself.

# SEE ALSO

[wmctrl](https://metacpan.org/pod/wmctrl)
