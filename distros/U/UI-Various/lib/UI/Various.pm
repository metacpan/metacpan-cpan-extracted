package UI::Various;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various - graphical/non-graphical user interface without external programs

=head1 SYNOPSIS

    use UI::Various;

=head1 ABSTRACT

B<Currently this module is just a PROOF OF CONCEPT and not yet fully
functional!> It is only uploaded to see how the tests run and fail on the
various different platforms.

Did you ever need to decide if a graphical or text based user interface is
best for your Perl application?  A GUI may be easier to use, but will not
run on run on a server without a window system (like X11 or Wayland) and
makes testing it more difficult.  The solution to this dilemma is
UI::Various.

UI::Various is a simple variable graphical and non-graphical user interface
(UI).  Unlike L<UI::Dialog> is uses no external programs.  Instead,
depending on the Perl UI packages installed on a machine, it used the best
one available from a list of different UI systems.  If none could be found
at all, it falls back to a very simple query/response interface on the
terminal / console using only core components.  To make an application as
accessible as possible (for the visually impaired or any automated script)
it also allows selection of a specific (installed) UI by the user via the
environment variable C<UI>.

Of course this variability does not come without some simplifications:

At any time there can be only one active window and one (modal) dialog "in
front" of that window.  See L</LIMITS> for more details.  All graphics,
pictures or icons (unless the later are part of the character set used) need
alternative descriptions for the text based interfaces, which can make a big
difference in the usability.

=head1 DESCRIPTION

UI::Various is a user interface (UI) choosing the best available UI from a
list of supported ones to an end-user.  Preferably - but depending on
installed Perl packages and the environment, especially the environment
variables C<DISPLAY> and C<UI> - this would be a graphical user interface
(GUI), but it can fallback to a non-graphical alternative (terminal user
interface aka TUI) and a very simple command-line based one as last resort.

Currently UI::Various supports the following UIs (the sequence here is also
the default selection sequence):

=over

=item C<L<Tk>>

probably the oldest GUI available for Perl, needs a defined C<DISPLAY>
environment variable

=item C<Curses>

the standard terminal UI using the L<Curses::UI> package

=item C<RichTerm>

a builtin query/response console interface still using ANSI colours, simple
graphics and L<Term::Readline> for the input (only Perl core modules)

=item (finally) C<PoorTerm>

a very simple builtin query/response console interface only using the Perl
core module L<Term::Readline>

=back

If the environment variable C<UI> is set, contains one of the values above
and meets all requirements for the corresponding UI, it's taking precedence
over the list in the C<use> statement.

=head1 LIMITS

As it is quite difficult to (as a developer) implement and/or (as a user)
understand a terminal based UI with multiple parallel windows to interact
with, only one window may be active at any time.  For simple modal queries
this window may open a dialog window blocking itself until the dialog
returns.  However, it is possible to have a list of multiple windows and
switch between them: One is active and the others are inactive, waiting to
be activated again.  See examples/TODO

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Carp;			# may only be used in import!

our $VERSION = "0.07";

BEGIN  {  require UI::Various::core;  }

#########################################################################

=head1 METHODS

=cut

#########################################################################
#########################################################################

=head2 B<import> - import and initialisation of UI::Various package

    use UI::Various;
        or
    use UI::Various({<options>});

=head3 example:

    use UI::Various({ use => [qw(Tk RichTerm)],
                      log => 'INFO',
                      language => 'de',
                      stderr => 1,
                      include => [qw(Main Window Button)]});

=head3 parameters:

    use                 prioritised list of UI packages to be checked/used
    language            (initial) language used by the package itself
                        (both for debugging and UI elements)
    log                 (initial) level of logging
    stderr              (initial) handling of STDERR output
    include             list of UI element packages to include as well

=head3 description:

This method initialised the UI::Various package.  It checks for the UI
packages available and selects / initialises the best one available.  In
addition it sets up the handling of error messages and the (initial)
language and debug level of the package.

The prioritised list of UI packages (C<use>) is a list of one or usually
more than one of the possible interface identifiers listed above.  Note that
the last resort UI C<PoorTerm> is always added automatically to the end of
this list.

=head4 C<language>

configures the initial language used by the package itself, both for
debugging and the UI elements.  Currently 2 languages are supported:

=over

=item de

=item en (default)

=back

=head4 C<log>

sets the initial level of logging output:

=over

=item C<FATAL>

Log only fatal errors that cause UI::Various (and thus the application using
it) to abort.

=item C<ERROR>

Also log non-fatal errors like bad parameters replaced by default values.
This is the default value.

=item C<WARN> or C<WARNING>

Also log warnings like features not supported by the currently used UI or
messages missing for the currently used (non-English) language.

=item C<INFO> or C<INFORMATION>

Also log information messages like the UI chosen at startup.

=item C<DEBUG_n>

Also log debugging messages of various debugging levels, mainly used for
development.  Note that debugging messages are always English.

=back

=head4 C<stderr>

configures the handling of output send to STDERR:

=over

=item C<3>

suppress all output to STDERR (usually not a good idea!)

=item C<2>

catch all error messages and print them when the program exits (or you
switch back to C<0>) in order to avoid cluttering the terminal output,
e.g. when running under Curses

=item C<1>

identical to C<2> when using a TUI and identical to C<0> when using a GUI

=item C<0>

print error messages etc. immediately to STDERR (default)

=back

Note that configuration C<1> suppresses the standard error output of
external programs (e.g. using C<system> or back-ticks) instead of capturing
it.  Also note that some fatal errors during initialisation are not caught.

=head4 C<include>

defines a list of UI elements to automatically import as well.  It defaults
to the string C<all>, but may contain a reference to an array containing the
name of specific UI elements like C<L<Main|UI::Various::Main>>, L <
Window|UI::Various::Window>, L < Text|UI::Various::Text>, L <
Button|UI::Various::Button>, etc. instead.  If it is set to the string
C<none>, no other UI element package is imported automatically.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub import($;%)
{
    my $pkg = shift;
    # Use fully qualified names until import of core is complete!
    ref($pkg)  and
	UI::Various::core::fatal('bad_usage_of__1_pkg_is__2',
				 __PACKAGE__, ref($pkg));
    $pkg eq __PACKAGE__  or
	UI::Various::core::fatal('bad_usage_of__1_as__2', __PACKAGE__, $pkg);
    UI::Various::core->import(@_);
}

#########################################################################

=head2 B<language> - get or set currently used language

    $language = language();
    $language = language($new_language);

=head3 example:

    if (language() ne 'en') ...

=head3 parameters:

    $language           optional new language to be used

=head3 description:

This function returns the currently used language.  If the optional
parameter C<$new_language> is set and a supported language, the language is
first changed to that.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub language(;$)
{
    return UI::Various::core::language(@_);
}

#########################################################################

=head2 B<logging> - get or set currently used logging-level

    $log_level = $logging();
    logging($new_level);

=head3 example:

    logging('WARN');

=head3 parameters:

    $new_level          optional new logging-level to be used

=head3 description:

This function returns the currently used logging-level.  If the optional
parameter C<$new_level> is set and a supported keyword (see possible values
for the corresponding parameter C<log> of C<L<use|/import - import and
initialisation of UI::Various package>> above), the logging-level is first
changed to that.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub logging(;$)
{
    return UI::Various::core::logging(@_);
}

#########################################################################

=head2 B<stderr> - get or set currently used handling of output

    $output = $stderr();
    stderr($new_value);

=head3 example:

    stderr(1) if stderr() == 3;

=head3 parameters:

    $new_value          optional new output-handling

=head3 description:

This function returns the currently used variant for the handling of output
to STDERR (see possible values for the corresponding parameter of
C<L<use|/import - import and initialisation of UI::Various package>> above).
If the optional parameter C<$new_value> is set and a supported log, the
handling is first changed to that.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub stderr(;$)
{
    return UI::Various::core::stderr(@_);
}

#########################################################################

=head2 B<using> - get currently used UI

    $interface = $using();

=head3 description:

This function returns the currently used user interface.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub using()
{
    return UI::Various::core::using();
}

1;

__END__
#########################################################################
#########################################################################

=head1 SEE ALSO

L<Tk>, L<Curses::UI>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
