##==============================================================================
## Tk::Stderr - capture program standard error output
##==============================================================================
## $Id: Stderr.pm,v 1.2 2003/04/01 03:58:42 kevin Exp $
##==============================================================================
require 5.006;

package Tk::Stderr;
use strict;
use warnings;
use vars qw($VERSION @ISA);
($VERSION) = q$Revision: 1.2 $ =~ /Revision:\s+(\S+)/ or $VERSION = "0.0";
use base qw(Tk::Derived Tk::MainWindow);

use Tk::ROText;
use Tk::Frame;

=pod

=head1 NAME

Tk::Stderr - capture standard error output, display in separate window

=head1 SYNOPSIS

	use Tk::Stderr;

	$mw = MainWindow->new->InitStderr;
	print STDERR 'stuff';   ## goes to standard error window
	warn 'eek!';            ## likewise

=head1 DESCRIPTION

This module captures that standard error of a program and redirects it to a read
only text widget, which doesn't appear until necessary. When it does appear, the
user can close it; it'll appear again when there is more output.

=cut

##==============================================================================
## Populate
##==============================================================================
sub Populate {
	my ($mw, $args) = @_;
	my $private = $mw->privateData;
	$private->{ReferenceCount} = 0;
	$private->{Enabled} = 0;

	$mw->SUPER::Populate($args);

	$mw->withdraw;
	$mw->protocol(WM_DELETE_WINDOW => [ $mw => 'withdraw' ]);

	my $f = $mw->Frame(
		Name => 'stderr_frame',
	)->pack(-fill => 'both', -expand => 1);

	my $text = $f->Scrolled(
		'ROText',
		Name => 'stderr_text',
		-scrollbars => 'osoe',
	)->pack(-fill => 'both', -expand => 1);
	
	$mw->Advertise('text' => $text);
	
	$mw->ConfigSpecs(
		'-title' => [ qw/METHOD title Title/, 'Standard Error Output' ],
	);

	$mw->Redirect(1);
	
	return $mw;
}

##==============================================================================
## Redirect
##==============================================================================
sub Redirect {
	my ($mw, $boolean) = @_;
	my $private = $mw->privateData;
	my $old = $private->{Enabled};
	
	if ($old && !$boolean) {
		untie *STDERR;
		$SIG{__WARN__} = 'DEFAULT';
	} elsif (!$old && $boolean) {
		tie *STDERR, 'Tk::Stderr::Handle', $mw;
		$SIG{__WARN__} = sub { print STDERR @_ };
	}
	$private->{Enabled} = $boolean;
	return $old;
}

##==============================================================================
## DecrementReferenceCount
##==============================================================================
sub DecrementReferenceCount {
	my ($mw) = @_;
	my $private = $mw->privateData;

	if (--$private->{ReferenceCount} <= 0) {
		$mw->destroy;
	}
}

##==============================================================================
## IncrementReferenceCount
##==============================================================================
sub IncrementReferenceCount {
	my ($mw) = @_;
	my $private = $mw->privateData;

	++$private->{ReferenceCount};
}

=pod

=head1 METHODS

These are actually added to the MainWindow class.

=over 4

=item I<$mw>->InitStderr;

The first time this method called, it does the following things:

=over 4

=item o

Creates a MainWindow holding a read-only scrollable text widget, and withdraws
this window until it's actually needed.

=item o

Ties STDERR to a special handle that adds the output to this text widget.

=item o

Installs a C<< $SIG{__WARN__} >> handler that redirects the output from B<warn>
to this window as well (by printing it to STDERR).

=back

On the remaining calls, it:

=over 4

=item o

Increments a reference count of "other" MainWindows.

=item o

Installs an OnDestroy handler that decrements this reference count, so that it
can detect when it's the only MainWindow left and destroy itself.

=back

=cut

package MainWindow;
use strict;
use warnings;

my $error_window;

##==============================================================================
## InitStderr
##==============================================================================
sub InitStderr {
	my ($mw, $title) = @_;

	unless (defined $error_window) {
		$error_window = Tk::Stderr->new;
		$error_window->title($title) if defined $title;
	}
	$error_window->IncrementReferenceCount;
	$mw->OnDestroy([ 'DecrementReferenceCount' => $error_window ]);
	return $mw;
}

=pod

=item I<$errwin> = I<$mw>->StderrWindow;

Returns a reference to the main window holding the text. You can use this to
configure the window itself or the widgets it contains. The only advertised
subwidget is 'text', which is the scrolled read-only text widget.

=cut

##==============================================================================
## StderrWindow
##==============================================================================
sub StderrWindow {
	return $error_window;
}

=pod

=item I<$old> = I<$mw>->RedirectStderr(I<$boolean>);

Enables or disables the redirection of standard error to the text window. Set
I<$boolean> to true to enable redirection, false to disable it. Returns the
previous value of the enabled flag.

If B<InitStderr> has never been called, this routine will call it if I<$boolean>
is true.

=cut

##==============================================================================
## RedirectStderr
##==============================================================================
sub RedirectStderr {
	my ($mw, $boolean) = @_;
	
	unless (defined $error_window) {
		$mw->InitStderr if $boolean;
		return;
	}
	return $error_window->Redirect($boolean);
}

=pod

=back

=head1 AUTHOR

Kevin Michael Vail <F<kevin>@F<vaildc>.F<net>>

=cut

##==============================================================================
## Define the handle that actually implements things.
##==============================================================================
BEGIN {
	package Tk::Stderr::Handle;
	use strict;
	use warnings;

	##==========================================================================
	## TIEHANDLE
	##==========================================================================
	sub TIEHANDLE {
		my ($class, $window) = @_;
		bless \$window, $class;
	}

	##==========================================================================
	## PRINT
	##==========================================================================
	sub PRINT {
		my $window = shift;
		my $text = $$window->Subwidget('text');

		$text->insert('end', $_) foreach (@_);
		$text->see('end');
		$$window->deiconify;
		$$window->raise;
		$$window->focus;
	}

	##==========================================================================
	## PRINTF
	##==========================================================================
	sub PRINTF {
		my ($window, $format) = splice @_, 0, 2;

		$window->PRINT(sprintf $format, @_);
	}
}

1;

##==============================================================================
## $Log: Stderr.pm,v $
## Revision 1.2  2003/04/01 03:58:42  kevin
## Add RedirectStderr method to allow redirection to be switched on and off.
##
## Revision 1.1  2003/03/26 21:48:43  kevin
## Fix dependencies in Makefile.PL
##
## Revision 1.0  2003/03/26 19:11:32  kevin
## Initial revision
##==============================================================================
