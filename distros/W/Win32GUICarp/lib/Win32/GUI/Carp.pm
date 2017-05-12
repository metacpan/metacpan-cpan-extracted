package Win32::GUI::Carp;

use strict;
require 5.005;

use vars qw/$VERSION/;
$VERSION='1.01';

use Exporter;
use Carp;
use IPC::Open3;

use vars qw/@ISA @EXPORT @EXPORT_FAIL @EXPORT_OK/;
@ISA         = qw(Exporter);
@EXPORT      = qw(confess croak carp); # from Carp (also cluck)
@EXPORT_FAIL = qw(
  fatalsToDialog
  warningsToDialog
  immediateWarnings
);
@EXPORT_OK   = (@EXPORT_FAIL, qw/ cluck windie winwarn syscarp syscroak /);

use vars qw/@WARNINGS/;

use vars qw/
  $ImmediateWarnings
  $FatalsToDialog
  $WarningsToDialog
  $DialogTitle
  $DefaultWarnTitle
  $DefaultDieTitle
  $FatalFilter
  $WarningFilter
/;
$DialogTitle      = '';
$DefaultWarnTitle = 'Warning';
$DefaultDieTitle  = 'Error';
$FatalFilter      = undef;
$WarningFilter    = undef;

use vars qw/$OLDDIE $OLDWARN/;  # play nice with others
$OLDDIE  = $SIG{__DIE__};   $SIG{__DIE__}  = \&death;
$OLDWARN = $SIG{__WARN__};  $SIG{__WARN__} = \&warned;

# handle special directives... well, specially
sub export_fail {
  my $pkg = shift;
  my @unknown;

  for my $failed (@_) {
    if   ($failed eq 'fatalsToDialog')    { $FatalsToDialog    = 1 }
    elsif($failed eq 'warningsToDialog')  { $WarningsToDialog  = 1 }
    elsif($failed eq 'immediateWarnings') { $ImmediateWarnings = 1 }
    else                                  { push @unknown, $failed }
  }

  return @unknown;
}

sub windie {
  local $FatalsToDialog = 1;
  if($#_ or $_[0] =~ /\n/) {
    die @_;
  } else {
    croak @_;
  }
}

sub death {
  eval {
    # save any warnings in @new_warns
    local $SIG{__WARN__} = \&warned;
    $OLDDIE->(@_) if($OLDDIE);  # invoke the old handler
  };

  if($@) { @_ = ($@) }  # check for death in old handler; use as new message

  if($FatalsToDialog and not ($FatalFilter and not $FatalFilter->(@_))) {
    local $DialogTitle = $DialogTitle;
    $DialogTitle = $DefaultDieTitle if($DialogTitle eq '');

    dodialog(@WARNINGS, @_); # show message and any pending warnings
    @WARNINGS = (); # remove warnings so they're not accidentally shown twice
  }

  die(@_);
}

sub winwarn {
  local $WarningsToDialog = 1;
  if($#_ or $_[0] =~ /\n/) {
    warn @_;
  } else {
    carp @_;
  }
}

sub warned {
  my @new_warns;

  eval {
    local $SIG{__WARN__} = sub { push @new_warns, [@_] };
    local $SIG{__DIE__};  # suppress handlers; we propagate any death later
    $OLDWARN->(@_) if($OLDWARN);  # invoke the old handler
  };
  my $oldwarn_death = $@;  # get warnings out of the way first

  if(@new_warns)  { @_ = @new_warns } # look for warnings from handler...
  elsif($OLDWARN) { return }          # if none, and there _is_ a handler,
  else            { @_ = [@_] }       # we have to suppress this warning,
                                      # since that's what would happen if
                                      # we weren't here to notice

  if($WarningsToDialog and not ($WarningFilter and not $WarningFilter->(@_))) {
    local $DialogTitle = $DialogTitle;
    $DialogTitle = $DefaultWarnTitle if($DialogTitle eq '');

    if($ImmediateWarnings) {
      dodialog(@$_) for(@_);
    } else {
      push @WARNINGS, @$_ for(@_);
    }
  }

  warn(@$_) for(@_);
  die($oldwarn_death) if($oldwarn_death); # propagate any death
}

sub syscarp {
  my $cmd = shift;
  local ($@, $!, $/);

  open( OUTPUT, ">&STDOUT" ) or die "Can't dup STDOUT to OUTPUT: $!\n";
  open( OUTERR, ">&STDERR" ) or die "Can't dup STDERR to OUTERR: $!\n";
  my ($pid, $val);
  eval { 
    $pid = open3("<&STDIN", \*OUTPUT, \*OUTERR, $cmd) ;
    $val = waitpid(-1,0); # <--- added this line
  };
  $@ && die "ERROR: $@\n";

  my $results = <OUTPUT>;
  my $errors  = <OUTERR>;
  close OUTPUT;
  close OUTERR;

  warn $errors if($errors);
  return $results;
}

sub syscroak {
  my $cmd = shift;
  local ($@, $!, $/);

  # This code was mostly stolen from particle on PerlMonks
  # See:  http://perlmonks.org/index.pl?node_id=86540
  open( OUTPUT, ">&STDOUT" ) or die "Can't dup STDOUT to OUTPUT: $!\n";
  open( OUTERR, ">&STDERR" ) or die "Can't dup STDERR to OUTERR: $!\n";
  my ($pid, $val);
  eval { 
    $pid = open3("<&STDIN", \*OUTPUT, \*OUTERR, $cmd) ;
    $val = waitpid(-1,0); # <--- added this line
  };
  $@ && die "syscroak error: $@\n";

  my $results = <OUTPUT>;
  my $errors  = <OUTERR>;
  close OUTPUT;
  close OUTERR;

  # Note: There seems to be a bug on *some* versions of Win32
  # where $? is always set to 0 after the waitpid, instead of
  # the correct return value of the called program.  It seems
  # to be OS dependant, and not Perl build dependant (as it
  # occurred on one computer w/ Win98 and not on another with
  # Win2k, though both had the same build of ActiveState Perl).
  croak $errors . "(`$cmd` returned " . ($? >> 8) . ")" if($errors);

  return $results;
}

sub END {
  local $DialogTitle = $DialogTitle;
  $DialogTitle = $DefaultWarnTitle if($DialogTitle eq '');
  dodialog(@WARNINGS) if(@WARNINGS);  # show any pending warnings
}

sub dodialog {
  require Win32::GUI;
  my $msg = join '', @_;
  (Win32::GUI::Window->new(-name=>$DialogTitle))->MessageBox($msg,$DialogTitle)
;
}

1;


=head1 NAME

Win32::GUI::Carp - Redirect warnings and errors to Win32::GUI MessageBoxes

=head1 SYNOPSIS

    use Win32::GUI::Carp qw/cluck/;

    croak "Ribbit!";
    confess "It was me: $!";
    carp "How could you do that?";
    warn "Duck!";
    die "There's no hope...";
    cluck "Don't do it.";

    use Win32::GUI::Carp qw/warningsToDialog/;
    warn "Warnings will be displayed in a pop-up dialog.";

    use Win32::GUI::Carp qw/fatalsToDialog/;
    die "Fatal error messages will be displayed in a pop-up dialog.";

    use Win32::GUI::Carp qw/winwarn windie/;
    winwarn "Warning in dialog.";
    windie  "Death in dialog.";

=head1 DESCRIPTION

When Perl programs are run in a GUI environment, it is often
desirable to have them run with no console attached.
Unfortunately, this causes any warnings or errors to be
lost.  Worse, fatal errors can cause your program to
silently disappear, forcing you to restart the program,
attached to a console, and hope you can reproduce the error.

This module makes it easy to see any errors or warnings your
console-less program might produce by catching any errors
and/or warnings and displaying them in a pop-up dialog box
using Win32::GUI.  It is similar in spirit to CGI::Carp's
C<fatalsToBrowser> and C<warningsToBrowser> special import
directives.

To cause errors or warnings to be displayed in a dialog,
simply specify one or more of the following options on the
C<use> line, as shown in the L<SYNOPSIS|"SYNOPSIS">.

=head1 IMPORT OPTIONS

=head2 C<warningsToDialog>

Show any warnings in a pop-up dialog box.

This option will cause a dialog box to be displayed
containing the text of the warnings.  The type and style of
the dialog box can be configured (see L<"CONFIGURATION">).
Note that warnings are still sent to C<STDERR> as well.

This option can also be activated or deactivated by setting
C<$Win32::GUI::Carp::WarningsToDialog> to true or false,
respectively.

=head2 C<fatalsToDialog>

Show any fatal errors in a pop-up dialog box.

This option will cause a dialog box to be displayed
containing the text of the fatal error.  The type and style
of the dialog box can be configured (see
L<"CONFIGURATION">).  Note that errors are still sent to
C<STDERR> as well.

This option can also be activated or deactivated by setting
C<$Win32::GUI::Carp::FatalsToDialog> to true or false,
respectively.

=head2 C<immediateWarnings>

This option controls whether all errors and warnings are
displayed in a single dialog box or each get their own.

By default, warnings are buffered and not shown until just
before the program terminates.  At that point, any warnings
and errors are shown together in a single dialog box.  This
is to cut down on the number of dialogs that have to be
clicked through, although it means that you can't tell when
a particular warning occurred.

If this option is specified, each warning and error message
will get its own dialog box which will be displayed as soon
as the warning or error occurs.  Note that warnings are
always printed to C<STDERR> as soon as they occur,
regardless of the state of this option.

Care should be taken when setting this option as it can
cause a large number of dialog boxes to be created.

This option can also be activated or deactivated by setting
C<$Win32::GUI::Carp::ImmediateWarnings> to true or false,
respectively.

=head1 FUNCTIONS

=head2 C<winwarn>

Raises a warning, using a dialog.  This function ignores the
state of C<warningsToDialog>, although all other options are
observed (including ImmediateWarnings).

=head2 C<windie>

Raises a fatal error, using a dialog.  This function ignores
the state of C<fatalsToDialog>, although all other options
are observed.

=head2 C<syscarp>

Executes a system command, just like L<system>, but passes
its its STDERR through any warn filters.  In other words, if
the command displays anything on STDERR, it will show up as
a warning in the calling program, and thus display in a
dialog (respecting warningsToDialog).

Note: The name of this function is subject to change, as I
think it is somewhat misleading.

=head2 C<syscroak>

Does the same thing as L<"syscarp"> but dies if anything is
sent to STDERR.  It includes a message with the return value
of the process.

Note: The name of this function is subject to change, as I
think it is somewhat misleading.

=head1 CONFIGURATION

The following variables control the style and type of dialog
box used.

=head2 C<$Win32::GUI::Carp::DialogTitle>

A string that will be used as the title of the dialog box.
This defaults to "Warning" when displaying warnings, and
"Error" when displaying fatal errors.

=head2 C<$Win32::GUI::Carp::FatalFilter>

Set this to a reference to a subroutine that should be
called whenever a fatal error is about to be shown in a
dialog.  The routine receives the error message in C<@_>,
and if it returns a true value the error will be sent
to the dialog as normal, otherwise the dialog will not
be shown (though the error still propagates as normal).

=head2 C<$Win32::GUI::Carp::WarningFilter>

Set this to a reference to a subroutine that should be
called whenever a warning is about to be shown in a
dialog.  The routine receives the warning message in
C<@_>, and if it returns a true value the warning will
be sent to the dialog as normal, otherwise the dialog
will not be shown (though the warning still propagates
as normal).

=head1 DEPENDANCIES

This module relies on the following other modules to be
installed:

=over 4

=item Win32::GUI

=item Carp

=item IPC::Open3 (for L<"syscarp"> and L<"syscroak">)

=back

=head1 BUGS

=over 4

=item *

This module installs a signal handler for both C<__DIE__>
and C<__WARN__>.  While it does save any previous handlers
and chain them properly, any new handler that is installed
will effectively disable the C<fatalsToDialog> and
C<warningsToDialog> options, respectively.  Note that, as
this module's handlers are installed at compile time, it is
probable that I<any> other handlers will be "new."

Especially if these changes aren't properly localized, this
can cause us to miss many errors.  There is a work-around,
but it's a bit of an ugly hack, and involves tying %SIG,
which seems dangerous.  I may include it as an option in the
future.

=item *

By default, C<carp()>, C<croak()> and C<confess()> are
exported from C<Carp>.  If nothing is specified in the
import list (including the special C<*ToDialog> and
C<immediateWarnings> options), then C<Win32::GUI::Carp> also
exports those functions.  As soon as I<anything> is given in
the import list, however, C<Exporter> stops exporting the
things in C<@EXPORT> (meaning the aforementioned functions
don't get exported).

=item *

There seems to be a bug on I<some> versions of Win32
affecting L<"syscarp"> and, moreso, L<"syscroak"> where $?
is always set to 0, instead of the correct return value of
the called program.

=back

=head1 AUTHOR

Copyright 2002, Cory Johns.

This module is free software; you can redistribute and/or
modify it under the same terms as Perl itself.

Address bug reports and comments to:
Cory Johns E<lt>L<johnsca@cpan.org>E<gt>

=head1 SEE ALSO

Carp, CGI::Carp, Win32::GUI

=cut

