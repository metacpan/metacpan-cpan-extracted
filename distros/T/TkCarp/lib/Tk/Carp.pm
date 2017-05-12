package Tk::Carp;

use strict;
require 5.005;

use vars qw/$VERSION/;
$VERSION='1.2';

use Exporter;
use Carp;

use vars qw/@ISA @EXPORT @EXPORT_FAIL @EXPORT_OK/;
@ISA         = qw(Exporter);
@EXPORT      = qw(confess croak carp); # from Carp (also cluck)
@EXPORT_FAIL = qw(
  fatalsToDialog
  warningsToDialog
  immediateWarnings
  useTkDialog
  tkDeathsNonFatal
);
@EXPORT_OK   = (@EXPORT_FAIL, qw/ cluck tkdie tkwarn tkwarnnow /);

use vars qw/$MainWindow $Dialog @WARNINGS/;
tie $MainWindow, 'Tk::Carp::_mainWindowTie';

use vars qw/$ImmediateWarnings $FatalsToDialog $WarningsToDialog/;
use vars qw/$DieIcon $DieTitle $WarnIcon $WarnTitle/;
use vars qw/$UseTkDialog/;
$DieIcon    = 'error';  # Valid icons: error, info, question or warning
$DieTitle   = 'Error';
$WarnIcon   = 'warning';
$WarnTitle  = 'Warning';

use vars qw/$OLDDIE $OLDWARN/;  # play nice with others
$OLDDIE  = $SIG{__DIE__};   $SIG{__DIE__}  = \&Tk::Carp::died;
$OLDWARN = $SIG{__WARN__};  $SIG{__WARN__} = \&Tk::Carp::warned;

# handle special directives... well, specially
sub export_fail {
  my $pkg = shift;
  my @unknown;

  for my $failed (@_) {
    if   ($failed eq 'fatalsToDialog')    { $FatalsToDialog    = 1 }
    elsif($failed eq 'warningsToDialog')  { $WarningsToDialog  = 1 }
    elsif($failed eq 'immediateWarnings') { $ImmediateWarnings = 1 }
    elsif($failed eq 'useTkDialog')       { $UseTkDialog       = 1 }
    elsif($failed eq 'tkDeathsNonFatal')  { undef &Tk::Error       }
    else                                  { push @unknown, $failed }
  }

  return @unknown;
}

sub tkdie {
  local $SIG{__DIE__}; # Suppress handling of death temporarily

  if($OLDDIE) {
    eval { $OLDDIE->(@_) };  # invoke the old handler
    if($@) { @_ = ($@) }  # check for death in old handler; use as new message
  }

  my $diehandler = (caller(1))[3] eq 'Tk::Carp::died';

  # Ignore die inside of evals, as it will be
  # caught and propagated up to us if desired.
  die @_ if $^S and $diehandler;

  if($FatalsToDialog or not $diehandler) {
    dodialog($DieIcon, $DieTitle, @WARNINGS, @_); # show any warnings
    @WARNINGS = (); # remove warnings so they're not accidentally shown twice
  }

  die(@_);
}

sub died {
  tkdie(@_);
}

# Copied and modified from Tk.pm
# This lets us ignore die inside of evals, while still
# catching errors in Tk callbacks properly.
sub Tk::Error {
  my ($w, $err, @msgs) = @_;

  if (Tk::Exists($w)) {
    my $grab = $w->grab('current');
    $grab->Unbusy if (defined $grab);
  }
  chomp($err);
  $err = "Tk::Error: $err\n " . join("\n ",@msgs)."\n";

  if($FatalsToDialog) {
    dodialog($DieIcon, $DieTitle, @WARNINGS, $err); # show any warnings
    @WARNINGS = (); # remove warnings so they're not accidentally shown twice
  }

  # Suppress handling of warnings or we would get the error
  # reported twice (once as an error, and once as a warning).
  local $SIG{__WARN__};
  warn($err);
}

sub tkwarn {
  my $oldwarn_death;
  if($OLDWARN) {
    my @new_warns;
    eval {
      local $SIG{__WARN__} = sub { push @new_warns, @_ };
      local $SIG{__DIE__};  # suppress handlers; we propagate any death later
      $OLDWARN->(@_);  # invoke the old handler
    };
    $oldwarn_death = $@;  # get warnings out of the way first

    # Look for warnings from handler.
    # If none, and there _is_ a handler,
    # we have to suppress this warning,
    # since that's what would happen if
    # we weren't here to notice.
    @_ = @new_warns ? @new_warns : goto SUPPRESS_WARNING;
  }

  if($WarningsToDialog or (caller(1))[3] ne 'Tk::Carp::warned') {
    if($ImmediateWarnings) {
      dodialog($WarnIcon, $WarnTitle, @_);
    } else {
      push @WARNINGS, @_;
    }
  }

  {
    local $SIG{__WARN__}; # Suppress handling of warning temporarily
    warn(@_);
  }

  SUPPRESS_WARNING:
  die($oldwarn_death) if($oldwarn_death); # propagate any death in old handler
}

sub tkwarnnow {
  local $ImmediateWarnings = 1;
  tkwarn(@_);
}

sub warned {
  tkwarn(@_);
}

sub END {
  # show any pending warnings
  dodialog($WarnIcon, $WarnTitle, @WARNINGS) if(@WARNINGS);
}

sub dodialog {
  my $icon  = shift;
  my $title = shift;

  require Tk;
  require Tk::Dialog;

  if($UseTkDialog) {

    # create MainWindow if it hasn't been already
    unless($MainWindow) {
      $MainWindow = MainWindow->new(
        -title => 'Tk::Carp',
        -name  => 'winTkCarp',
      );
      $MainWindow->withdraw();
    }

    # create the dialog if it hasn't been already
    unless($Dialog) {
      $Dialog = $MainWindow->Dialog(
        -justify        => 'left',
        -default_button => 'Ok',
        -buttons        => ['Ok'],
      );
    }

    $Dialog->configure(
      -bitmap => $icon,
      -title  => $title,
      -text   => join('', @_),
    );
    $Dialog->Show();

  } else {

    # On Win32 (at least), there is sometimes a problem if
    # the user sets $Tk::Carp::MainWindow to their own MainWindow,
    # and messageBox is called on it before MainLoop is entered.
    # For some reason, it seems to cause all the widgets in the
    # MainWindow to not respond to events.  Of course, this
    # can only happen if they specify immediateWarnings and
    # trigger a warning during initialization, so it shouldn't
    # often be an issue.  Just in case, though, we create a
    # fresh MainWindow every time... Seems wasteful. :-(
    my $mw = MainWindow->new(
      -name  => 'winTkCarp_messageBox',
      -title => 'Tk::Carp',
    );
    $mw->withdraw();
    $mw->messageBox(
      -icon    => $icon,
      -title   => $title,
      -type    => 'OK',
      -message => join('', @_),
    );
    $mw->destroy();

  }
}

package Tk::Carp::_mainWindowTie;

use Tie::Scalar;
BEGIN { @Tk::Carp::_mainWindowTie::ISA = ('Tie::StdScalar') }

sub STORE {
  my $self = shift;
  # If they overwrite $Tk::Carp::MainWindow with their own MainWindow
  # and we've already created our own MainWindow, ours will stay
  # around indefinately and keep the application open.  Bad mojo.
  # So, we destroy it first (and hope they haven't made a copy of it
  # somewhere else for some strange reason).
  if(defined $$self) {
    $$self->destroy();        # $Tk::Carp::Dialog MUST be a child of the
    undef $Tk::Carp::Dialog;  # new MainWindow.  We will recreate it later.
  }
  $$self = shift;
}

1;


=head1 NAME

Tk::Carp - Redirect warnings and errors to Tk Dialogs

=head1 SYNOPSIS

    use Tk::Carp qw/cluck/;

    croak "Ribbit!";
    confess "It was me: $!";
    carp "How could you do that?";
    warn "Duck!";
    die "There's no hope...";
    cluck "Don't do it.";

    use Tk::Carp qw/warningsToDialog/;
    warn "Warnings will be displayed in a pop-up dialog.";

    use Tk::Carp qw/fatalsToDialog/;
    die "Fatal error messages will be displayed in a pop-up dialog.";

    use Tk::Carp qw/tkwarn tkdie/;
    tkwarn "Warning in dialog.";
    tkdie  "Death in dialog.";

=head1 DESCRIPTION

When Perl programs are run in a GUI environment, it is often desirable
to have them run with no console attached.  Unfortunately, this causes
any warnings or errors to be lost.  Worse, fatal errors can cause your
program to silently disappear, forcing you to restart the program,
attached to a console, and hope you can reproduce the error.

This module makes it easy to see any errors or warnings your console-less
program might produce by catching any errors and/or warnings and displaying
them in a pop-up dialog box using Tk.  It is similar in spirit to CGI::Carp's
C<fatalsToBrowser> and C<warningsToBrowser> special import directives.

To cause errors or warnings to be displayed in a dialog, simply specify one
or more of the following options on the C<use> line, as shown in the
L<SYNOPSIS|"SYNOPSIS">.

=head1 IMPORT OPTIONS

=head2 C<warningsToDialog>

Show any warnings in a pop-up dialog box.

This option will cause a dialog box to be displayed containing the
text of the warnings.  The type and style of the dialog box can be
configured (see L<"CONFIGURATION">).  Note that warnings are still
sent to C<STDERR> as well.

This option can also be activated or deactivated by setting
C<$Tk::Carp::WarningsToDialog> to true or false, respectively.

=head2 C<fatalsToDialog>

Show any fatal errors in a pop-up dialog box.

This option will cause a dialog box to be displayed containing the
text of the fatal error.  The type and style of the dialog box can
be configured (see L<"CONFIGURATION">).  Note that errors are still
sent to C<STDERR> as well.

This option can also be activated or deactivated by setting
C<$Tk::Carp::FatalsToDialog> to true or false, respectively.

=head2 C<immediateWarnings>

This option controls whether all errors and warnings are displayed
in a single dialog box or each get their own.

By default, warnings are buffered and not shown until just before
the program terminates.  At that point, any warnings and errors
are shown together in a single dialog box.  This is to cut down
on the number of dialogs that have to be clicked through, although
it means that you can't tell when a particular warning occurred.

If this option is specified, each warning and error message will get
its own dialog box which will be displayed as soon as the warning
or error occurs.  Note that warnings are always printed to C<STDERR>
as soon as they occur, regardless of the state of this option.

Care should be taken when setting this option as it can cause
a large number of dialog boxes to be created.

This option can also be activated or deactivated by setting
C<$Tk::Carp::ImmediateWarnings> to true or false, respectively.

=head2 C<useTkDialog>

This option controls whether the dialog is displayed using
C<MainWindow-E<gt>messageBox()> or C<$Tk::Carp::ShowTkDialog-E<gt>()>.

By default, the dialog that is displayed when errors or warnings
are raised is done using C<MainWindow-E<gt>messageBox()>.  Under Win32,
this type of dialog seems to be implemented more natively than
C<Tk::Dialog>, and so has better support of focus-taking and icons.
Unfortunately, this type of dialog must be recreated, along with
a parenting C<MainWindow>.

If this option is specified, the dialog box will instead be displayed
using C<$Tk::Carp::ShowTkDialog-E<gt>()> which, by default, displays a
C<Tk::Dialog> object.  Unlike C<messageBox()>, the C<Tk::Dialog>
object is only created the first time it is used.  This is more
efficient when used with the L<immediateWarnings|"immediateWarnings">
option.  You can also manipulate or set the C<Tk::Dialog> object
used directly, gaining better control over the display.  You can
even use a completely different type of object instead
(see L<"$Tk::Carp::Dialog"> and L<"$Tk::Carp::ShowTkDialog">).

This option can also be activated or deactivated by setting
C<$Tk::Carp::UseTkDialog> to true or false, respectively.

=head2 C<tkDeathsNonFatal>

This option causes errors generated in Tk callbacks to be treated as
warnings.

The default Tk::Error handler converts fatal errors in callbacks to
warnings.  Unless this option is specified, this module defines a
custom Tk::Error handler to allow them to be treated as fatal errors
(ie, use the icon and title associated with fatal errors, and displayed
immediately, regardless of the state of C<$Tk::Carp::ImmediateWarnings>).

=head1 FUNCTIONS

=head2 C<tkwarn>

Raises a warning, using a dialog.  This function ignores the state
of C<warningsToDialog>, although all other options are observed.

=head2 C<tkdie>

Raises a fatal error, using a dialog.  This function ignores the state
of C<fatalsToDialog>, although all other options are observed.

=head1 CONFIGURATION

The following variables control the style and type of dialog box used.

=head2 C<$Tk::Carp::DieIcon>

Changes the icon displayed in the dialog box for fatal errors.  Valid values
are any that could be used as the C<-icon> parameter to C<messageBox()>, or
as the C<-bitmap> parameter to the C<Tk::Dialog-E<gt>configure()> method.

The most common values are: C<'error'>, C<'info'>, C<'question'>
and C<'warning'>.  The default value is C<'error'>.

=head2 C<$Tk::Carp::DieTitle>

A string that will be used as the title of the dialog box for fatal errors.

=head2 C<$Tk::Carp::WarnIcon>

Changes the icon displayed in the dialog box for warnings.  Valid values
are the same as for C<$Tk::Carp::DieIcon>.

The default value is C<'warning'>.

=head2 C<$Tk::Carp::WarnTitle>

A string that will be used as the title of the dialog box for warnings.

=head2 C<$Tk::Carp::MainWindow>

The C<Tk::MainWindow> object used to create the dialog box.  If not
defined, one will be created as needed.  If your program has a Tk
MainWindow, you should set this variable to it.

B<Note:>  If you create a C<MainWindow> and enter C<MainLoop> I<without>
setting this variable to your C<MainWindow>, and a warning or error is
raised with C<useTkDialog> enabled, you B<MUST> call
C<$Tk::Carp::MainWindow-E<gt>destroy()> when your C<MainWindow> is closed,
or your application I<will not exit>.  It will remain open but without
any visible windows.  Really, it's just better to make sure you set
this variable to your C<MainWindow> if you use C<useTkDialog>.

=head2 C<$Tk::Carp::Dialog>

The C<Tk::Dialog> object used if L<"$Tk::Carp::UseMessageBox"> is not
true.  If not defined, one will be created as needed.

You can use this variable to change the configuration, such as the font
or justification, of the object.  You can also set this variable to a
totally different type of object (such as a C<Tk::DialogBox>, or
C<Tk::Toplevel>), though you must also set the
L<$Tk::Carp::ShowTkDialog|"$Tk::Carp::ShowTkDialog">
variable, lest you get "Bad option" errors (or worse).

=head2 C<$Tk::Carp::ShowTkDialog>

A pointer to a subroutine that is called to display the dialog box if
L<$Tk::Carp::UseMessageBox|"$Tk::Carp::UseMessageBox"> is false.
This subroutine should accept a list of strings to be displayed in the
dialog box.  It should probably also use the
L<$Tk::Carp::DialogIcon|"$Tk::Carp::DialogIcon">,
L<$Tk::Carp::DialogTitle|"$Tk::Carp::DialogTitle">,
and L<$Tk::Carp::MainWindow|"$Tk::Carp::MainWindow"> variables.

When used in conjunction with L<$Tk::Carp::Dialog|"$Tk::Carp::Dialog">,
changing this variable allows you to use a different type of object as
the dialog.  For example, you could use a C<Tk::DialogBox> to be able
to place other widgets in the dialog box, or a C<Tk::Toplevel> to gain
complete control over the appearance of the dialog.

The default subroutine (C<&Tk::Carp::ShowTkDialog()>) creates (if
necessary) a C<Tk::Dialog> object in L<$Tk::Carp::Dialog|"$Tk::Carp::Dialog">
and calls its C<configure()> and C<Show()> methods.

=head1 BUGS

This module installs a signal handler for both C<__DIE__> and C<__WARN__>.
While it does save any previous handlers and chain them properly, any new
handler that is installed will effectively disable the C<fatalsToDialog>
and C<warningsToDialog> options, respectively.  Tk seems to do this
during some of its object initializations.  This can occasionally cause
errors or warnings generated inside Tk widget code to be lost.
(Note: this was probably fixed by the use of a Tk::Error sub, but see
the next bug.)

The introduction of a Tk::Error sub means that if code that uses this
module defines its own Tk::Error sub it will generate a "Subroutine
redefined at..." warning.  Worse, if the sub is defined before this
module is C<use>d, this module's Tk::Error sub will not only generate
a redefinition warning, but will overwrite the user's sub.  If you
want to use a custom Tk::Error sub and still want errors to be sent
to a dialog, you can use the following (somewhat convoluted) code:
    use Tk::Carp;
    BEGIN {
      $OldTkError = \&Tk::Error;
      no warnings 'redefine'; # only works in >= 5.6.0
      *Tk::Error = sub {
        $OldTkError->(@_); # Call Tk::Carp's handler so dialog is shown
        # your code here
      }
    }

By default, C<carp()>, C<croak()> and C<confess()> are exported from
C<Carp>.  If nothing is specified in the import list (including the
special C<*ToDialog>, C<immediateWarnings>, and C<useTkDialog> options),
then C<Tk::Carp> also exports those functions.  As soon as I<anything> is
given in the import list, however, C<Exporter> stops exporting the things
in C<@EXPORT>, meaning the aforementioned functions.

=head1 AUTHORS

Copyright 2001, Cory Johns.  All rights reserved.

This module is free software; you can redistribute and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: johnsca@cpan.org

=head1 SEE ALSO

Carp, CGI::Carp, Tk, Tk::Dialog

