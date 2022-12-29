# NAME

UI::Various - graphical/non-graphical user interface without external programs

# SYNOPSIS

    use UI::Various;

# ABSTRACT

Did you ever need to decide if a graphical or text based user interface is
best for your Perl application?  A GUI may be easier to use, but will not
run on run on a server without a window system (like X11 or Wayland) and
makes testing it more difficult.  The solution to this dilemma is
UI::Various.

UI::Various is a simple variable graphical and non-graphical user interface
(UI).  Unlike [UI::Dialog](https://metacpan.org/pod/UI%3A%3ADialog) is uses no external programs.  Instead,
depending on the Perl UI packages installed on a machine, it used the best
one available from a list of different UI systems.  If none could be found
at all, it falls back to a very simple query/response interface on the
terminal / console using only core components.  To make an application as
accessible as possible (for the visually impaired or any automated script)
it also allows selection of a specific (installed) UI by the user via the
environment variable `UI`.

Of course this variability does not come without some simplifications:

At any time there can be only one active window and one (modal) dialogue "in
front" of that window.  See ["LIMITS"](#limits) for more details.  All graphics,
pictures or icons (unless the later are part of the character set used) need
alternative descriptions for the text based interfaces, which can make a big
difference in the usability.

Currently the module is still missing some of its planned frills like
alignment, colour, exact positioning, graphics, pictures or icons.  At least
the first two of this list will be added in later versions.  The essential
functionality is ready to be used and will be tested / used by another
project developed before further enhancements on this one.

# DESCRIPTION

UI::Various is a user interface (UI) choosing the best available UI from a
list of supported ones to an end-user.  Preferably - but depending on
installed Perl packages and the environment, especially the environment
variables `DISPLAY` and `UI` - this would be a graphical user interface
(GUI), but it can fallback to a non-graphical alternative (terminal user
interface aka TUI) and a very simple command-line based one as last resort.

Currently UI::Various supports the following UIs (the sequence here is also
the default selection sequence):

- `[Tk](https://metacpan.org/pod/Tk)`

    probably the oldest GUI available for Perl, needs a defined `DISPLAY`
    environment variable

- `Curses`

    the standard terminal UI using the [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI) package

- `RichTerm`

    a builtin query/response console interface still using ANSI colours, simple
    graphics and [Term::Readline](https://metacpan.org/pod/Term%3A%3AReadline) for the input (only Perl core modules)

- (finally) `PoorTerm`

    a very simple builtin query/response console interface where nested
    container elements must be selected to interact with something inside; they
    are also simply displayed in sequence without other arrangement

If the environment variable `UI` is set, contains one of the values above
and meets all requirements for the corresponding UI, it's taking precedence
over the list in the `use` statement.

# LIMITS

As it is quite difficult to (as a developer) implement and/or (as a user)
understand a terminal based UI with multiple parallel windows to interact
with, only one window may be active at any time.  For simple modal queries
this window may open a dialogue window blocking itself until the dialogue
returns.  However, it is possible to have a list of multiple windows and
switch between them: One is active and the others are inactive, waiting to
be activated again.  See `examples/hello-two-windows.pl` and
`examples/hello-variable-content.pl`.

Check buttons may not have variable texts.

Radio buttons can only be arranged vertically.

# KNOWN BUGS

Setting an attribute of any object to `undef` will not work with Perl
versions prior to 5.20 (see [perl5200delta](https://metacpan.org/pod/perl5200delta), bugs #7508 and #109726).  The
only possible (and dirty!) workaround is setting the member of the internal
hash directly.

Boxes can not have visible borders in [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI) as they are currently
"faked" and do not use a proper [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI) element.  This also sometimes
leads to a Curses interface needing slightly more space than the equivalent
RichTerm one.  In addition [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI) has limitations concerning the
alignment of the widgets.

Running `[Main::mainloop](https://metacpan.org/pod/UI%3A%3AVarious%3A%3AMain#mainloop---main-event-loop-of-an-application)` more than once causes [Tk](https://metacpan.org/pod/Tk) to abort with sporadic (about 1
in 9) segmentation violations in Tk's internal code.  In addition there are
sporadic core dumps when running Tk in a virtual X11 framebuffer (Xvfb).
Finally the calculation for automatic wrapping in Tk needs improvement.

Methods, member variables, etc. starting with an underscore (`_`) are
considered to be internal only.  Their usage and interfaces may change
between versions in an incompatible way!

We (try to) use US English for identifiers while using GB English for the
documentation.  This is intended and not a bug!

# METHODS

## **import** - import and initialisation of UI::Various package

    use UI::Various;
        or
    use UI::Various({<options>});

### example:

    use UI::Various({ use => [qw(Tk RichTerm)],
                      log => 'INFO',
                      language => 'de',
                      stderr => 1,
                      include => [qw(Main Window Button)]});

### parameters:

    use                 prioritised list of UI packages to be checked/used
    language            (initial) language used by the package itself
                        (both for debugging and UI elements)
    log                 (initial) level of logging
    stderr              (initial) handling of STDERR output
    include             list of UI element packages to include as well

### description:

This method initialised the UI::Various package.  It checks for the UI
packages available and selects / initialises the best one available.  In
addition it sets up the handling of error messages and the (initial)
language and debug level of the package.

The prioritised list of UI packages (`use`) is a list of one or usually
more than one of the possible interface identifiers listed above.  Note that
the last resort UI `PoorTerm` is always added automatically to the end of
this list.

#### `language`

configures the initial language used by the package itself, both for
messages and the UI elements.  Currently 2 languages are supported:

- de
- en (default)

#### `log`

sets the initial level of logging output:

- `FATAL`

    Log only fatal errors that cause UI::Various (and thus the application using
    it) to abort.

- `ERROR`

    Also log non-fatal errors like bad parameters replaced by default values.
    This is the default value.

- `WARN` or `WARNING`

    Also log warnings like features not supported by the currently used UI or
    messages missing for the currently used (non-English) language.

- `INFO` or `INFORMATION`

    Also log information messages like the UI chosen at startup.

- `DEBUG_n`

    Also log debugging messages of various debugging levels, mainly used for
    development.  Note that debugging messages are always English.

#### `stderr`

configures the handling of output send to STDERR:

- `3`

    suppress all output to STDERR (usually not a good idea!)

- `2`

    catch all error messages and print them when the program exits (or you
    switch back to `0`) in order to avoid cluttering the terminal output,
    e.g. when running under Curses

    Note that under Curses you probably even then still won't see the output, as
    the ncurses library apparently clears the terminal after Perl's END
    handlers.  See `examples/listbox.pl` and `examples/select-file.pl` for a
    possible mitigation.

- `1`

    identical to `2` when using a TUI and identical to `0` when using a GUI

- `0`

    print error messages etc. immediately to STDERR (default)

Note that configuration `1` suppresses the standard error output of
external programs (e.g. using `system` or back-ticks) instead of capturing
it.  Also note that some fatal errors during initialisation are not caught.

#### `include`

defines a list of UI elements to automatically import as well.  It defaults
to the string `all`, but may contain a reference to an array containing the
name of specific UI elements like `[Main](https://metacpan.org/pod/UI%3A%3AVarious%3A%3AMain)`, L <
Window|UI::Various::Window>, L < Text|UI::Various::Text>, L <
Button|UI::Various::Button>, etc. instead.  If it is set to the string
`none`, no other UI element package is imported automatically.

## **language** - get or set currently used language

    $language = language();
    $language = language($new_language);

### example:

    if (language() ne 'en') ...

### parameters:

    $language           optional new language to be used

### description:

This function returns the currently used language.  If the optional
parameter `$new_language` is set and a supported language, the language is
first changed to that.

## **logging** - get or set currently used logging-level

    $log_level = $logging();
    logging($new_level);

### example:

    logging('WARN');

### parameters:

    $new_level          optional new logging-level to be used

### description:

This function returns the currently used logging-level.  If the optional
parameter `$new_level` is set and a supported keyword (see possible values
for the corresponding parameter `log` of `[use](#import-import-and-initialisation-of-ui-various-package)` above), the logging-level is first
changed to that.

## **stderr** - get or set currently used handling of output

    $output = $stderr();
    stderr($new_value);

### example:

    stderr(1) if stderr() == 3;

### parameters:

    $new_value          optional new output-handling

### description:

This function returns the currently used variant for the handling of output
to STDERR (see possible values for the corresponding parameter of
`[use](#import-import-and-initialisation-of-ui-various-package)` above).
If the optional parameter `$new_value` is set and a supported log, the
handling is first changed to that.

## **using** - get currently used UI

    $interface = $using();

### description:

This function returns the currently used user interface.

# SEE ALSO

[Tk](https://metacpan.org/pod/Tk), [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI)

# LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

# AUTHOR

Thomas Dorner &lt;dorner (at) cpan (dot) org>
