package UI::Dialog;
###############################################################################
#  Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use 5.006;
use strict;
use warnings;
use Carp;

BEGIN {
    use vars qw($VERSION);
    $VERSION = '1.21';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = {@_} || {};
    my $self = {};
    bless($self, $class);

    $self->{'debug'} = $cfg->{'debug'} || 0;

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

    if (not $cfg->{'order'} and ($ENV{'DISPLAY'} && length($ENV{'DISPLAY'}) > 0)) {
		#: Pick a GUI mode 'cause a DISPLAY was detected
		if ($ENV{'TERM'} =~ /^dumb$/i) {
			# we're running free of a terminal
			$cfg->{'order'} = [ 'zenity', 'xdialog', 'gdialog', 'kdialog' ];
		} else {
			# we're running in a terminal
            $cfg->{'order'} = [ 'zenity', 'xdialog', 'gdialog', 'kdialog', 'whiptail', 'cdialog', 'ascii' ];
		}
    }
    # verify and repair the order
    $cfg->{'order'} = ((ref($cfg->{'order'}) eq "ARRAY") ? $cfg->{'order'} :
					   ($cfg->{'order'}) ? [ $cfg->{'order'} ] :
					   [ 'cdialog', 'whiptail', 'ascii' ]);

    $self->_debug("ENV->UI_DIALOGS: ".($ENV{'UI_DIALOGS'}||'NULL'),2);
    $cfg->{'order'} = [ split(/\:/,$ENV{'UI_DIALOGS'}) ] if $ENV{'UI_DIALOGS'};

    $self->_debug("ENV->UI_DIALOG: ".($ENV{'UI_DIALOG'}||'NULL'),2);
    unshift(@{$cfg->{'order'}},$ENV{'UI_DIALOG'}) if $ENV{'UI_DIALOG'};

    $cfg->{'trust-input'} =
      ( exists $cfg->{'trust-input'}
        && $cfg->{'trust-input'}==1
      ) ? 1 : 0;

    my @opts = ();
    foreach my $opt (keys(%$cfg)) { push(@opts,$opt,$cfg->{$opt}); }

    $self->_debug("order: @{$cfg->{'order'}}",2);

    if (ref($cfg->{'order'}) eq "ARRAY") {
		foreach my $try (@{$cfg->{'order'}}) {
			if ($try =~ /^zenity$/i) {
				$self->_debug("trying zenity",2);
				if (eval "require UI::Dialog::Backend::Zenity; 1" && $self->_has_variant('zenity')) {
					require UI::Dialog::Backend::Zenity;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::Zenity (@opts);
					$self->_debug("using zenity",2);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:gdialog|gdialog\.real)$/i) {
				$self->_debug("trying gdialog",2);
				#: In Debian, gdialog is now being diverted to gdialog.real as zenity is the gnome2 replacement
				if (eval "require UI::Dialog::Backend::GDialog; 1" && ($self->_has_variant('gdialog.real') ||
																	   $self->_has_variant('gdialog'))) {
					require UI::Dialog::Backend::GDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::GDialog (@opts);
					$self->_debug("using gdialog ",2);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:xdialog|X)$/i) {
				$self->_debug("trying xdialog",2);
				if (eval "require UI::Dialog::Backend::XDialog; 1" && $self->_has_variant('Xdialog')) {
					require UI::Dialog::Backend::XDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::XDialog (@opts,'XDIALOG_HIGH_DIALOG_COMPAT',1);
					$self->_debug("using xdialog",2);
					last;
				} else { next; }
			} elsif ($try =~ /^kdialog$/i) {
				$self->_debug("trying kdialog",2);
				if (eval "require UI::Dialog::Backend::KDialog; 1" && $self->_has_variant('kdialog')) {
					require UI::Dialog::Backend::KDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::KDialog (@opts);
					$self->_debug("using kdialog",2);
					last;
				} else { next; }
			} elsif ($try =~ /^GNOME$/i) {
				if (eval "require UI::Dialog::GNOME; 1") {
					require UI::Dialog::GNOME;
					$self->{'_ui_dialog'} = new UI::Dialog::GNOME (@opts);
					last;
				} else { next; }
			} elsif ($try =~ /^KDE$/i) {
				if (eval "require UI::Dialog::KDE; 1") {
					require UI::Dialog::KDE;
					$self->{'_ui_dialog'} = new UI::Dialog::KDE (@opts);
					last;
				} else { next; }
			} elsif ($try =~ /^CONSOLE$/i) {
				if (eval "require UI::Dialog::Console; 1") {
					require UI::Dialog::Console;
					$self->{'_ui_dialog'} = new UI::Dialog::Console (@opts);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:dialog|cdialog)$/i) {
				$self->_debug("trying cdialog",2);
				if (eval "require UI::Dialog::Backend::CDialog; 1" && $self->_has_variant('dialog')) {
					require UI::Dialog::Backend::CDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::CDialog (@opts);
					$self->_debug("using cdialog",2);
					last;
				} else { next; }
			} elsif ($try =~ /^whiptail$/i) {
				$self->_debug("trying whiptail",2);
				if (eval "require UI::Dialog::Backend::Whiptail; 1" && $self->_has_variant('whiptail')) {
					require UI::Dialog::Backend::Whiptail;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::Whiptail (@opts);
					$self->_debug("using whiptail",2);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:ascii|native)$/i) {
				$self->_debug("trying ascii",2);
				if (eval "require UI::Dialog::Backend::ASCII; 1") {
					require UI::Dialog::Backend::ASCII;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::ASCII (@opts);
					$self->_debug("using ascii",2);
					last;
				} else { next; }
			} else { next; }
		}
    } else {
		if (eval "require UI::Dialog::Backend::ASCII; 1") {
			require UI::Dialog::Backend::ASCII;
			$self->{'_ui_dialog'} = new UI::Dialog::Backend::ASCII (@opts);
		} else {
			carp("Failed to load any suitable dialog variant backend.");
		}
    }

    ref($self->{'_ui_dialog'}) or croak("unable to load suitable backend.");
    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

#: purely internal usage
sub _debug {
    my $self = $_[0];
    my $mesg = $_[1] || 'null error message given!';
    my $rate = $_[2] || 1;
    return() unless $self->{'debug'} and $self->{'debug'} >= $rate;
    chomp($mesg);
    print STDERR "Debug: ".$mesg."\n";
}

sub _has_variant {
    my $self = $_[0];
    my $variant = $_[1];
    $self->{'PATHS'} = ((ref($self->{'PATHS'}) eq "ARRAY") ? $self->{'PATHS'} :
						($self->{'PATHS'}) ? [ $self->{'PATHS'} ] :
						[ '/bin', '/usr/bin', '/usr/local/bin', '/opt/bin' ]);
    foreach my $PATH (@{$self->{'PATHS'}}) {
		return($PATH . '/' . $variant)
		 unless not -x $PATH . '/' . $variant;
    }
    return(0);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#: dialog variant state methods:
sub state     { return(shift()->{'_ui_dialog'}->state(@_));     }
sub ra        { return(shift()->{'_ui_dialog'}->ra(@_));        }
sub rs        { return(shift()->{'_ui_dialog'}->rs(@_));        }
sub rv        { return(shift()->{'_ui_dialog'}->rv(@_));        }

#: Frills
#:    all backends support nautilus scripts.
sub nautilus  { return(shift()->{'_ui_dialog'}->nautilus(@_));  }
#:    same with osd_cat (aka: xosd).
sub xosd      { return(shift()->{'_ui_dialog'}->xosd(@_));  }
#:    Beep & Clear may have no affect when using GUI backends
sub beep      { return(shift()->{'_ui_dialog'}->beep(@_));      }
sub clear     { return(shift()->{'_ui_dialog'}->clear(@_));     }

#: widget methods:
sub yesno     { return(shift()->{'_ui_dialog'}->yesno(@_));     }
sub msgbox    { return(shift()->{'_ui_dialog'}->msgbox(@_));    }
sub inputbox  { return(shift()->{'_ui_dialog'}->inputbox(@_));  }
sub password  { return(shift()->{'_ui_dialog'}->password(@_));  }
sub textbox   { return(shift()->{'_ui_dialog'}->textbox(@_));   }
sub menu      { return(shift()->{'_ui_dialog'}->menu(@_));      }
sub checklist { return(shift()->{'_ui_dialog'}->checklist(@_)); }
sub radiolist { return(shift()->{'_ui_dialog'}->radiolist(@_)); }
sub fselect   { return(shift()->{'_ui_dialog'}->fselect(@_));   }
sub dselect   { return(shift()->{'_ui_dialog'}->dselect(@_));   }

1;

=head1 NAME

UI::Dialog - wrapper for various dialog applications.

=head1 SYNOPSIS

  use UI::Dialog;
  my $d = new UI::Dialog ( backtitle => 'Demo', title => 'Default',
                           height => 20, width => 65 , listheight => 5,
                           order => [ 'zenity', 'xdialog' ] );

  # Either a Zenity or Xdialog msgbox widget should popup,
  # with a preference for Zenity.
  $d->msgbox( title => 'Welcome!', text => 'Welcome one and all!' );

=head1 ABSTRACT

UI::Dialog is a OOPerl wrapper for the various dialog applications. These
dialog backends are currently supported: Zenity, XDialog, GDialog, KDialog,
CDialog, and Whiptail. There is also an ASCII backend provided as a last
resort interface for the console based dialog variants. UI::Dialog is a
class that provides a strict interface to these various backend modules.
By using UI:Dialog (with it's imposed limitations on the widgets) you can
ensure that your Perl program will function with any available interfaces.

=head1 DESCRIPTION

UI::Dialog supports priority ordering of the backend detection process. So
if you'd prefer that Xdialog should be used first if available, simply
designate the desired order when creating the new object. The default order
for detecting and utilization of the backends are as follows:
  (with DISPLAY env): Zenity, GDialog, XDialog, KDialog
  (without DISPLAY): CDialog, Whiptail, ASCII

UI::Dialog is the result of a complete re-write of the UDPM CPAN module. This
was done to break away from the bad choice of name (UserDialogPerlModule) and
to implement a cleaner, more detached, OOPerl interface.

=head1 EXPORT

=over 2

None

=back

=head1 INHERITS

=over 2

None

=back

=head1 CONSTRUCTOR

=over 2

=back

=head2 new( @options )

=over 4

=item EXAMPLE

=over 6

 my $d = new( title => 'Default Title', backtitle => 'Backtitle',
              width => 65, height => 20, listheight => 5,
              order => [ 'zenity', 'xdialog', 'gdialog' ] );

=back

=item DESCRIPTION

=over 6

This is the Class Constructor method. It accepts a list of key => value pairs
and uses them as the defaults when interacting with the various widgets.

=back

=item RETURNS

=over 6

A blessed object reference of the UI::Dialog class.

=back

=item OPTIONS

The (...)'s after each option indicate the default for the option. An * denotes
support by all the widget methods on a per-use policy defaulting to the values
decided during object creation.

=over 6

=item B<debug = 0,1,2> (0)

=item B<order = [ zenity, xdialog, gdialog, kdialog, cdialog, whiptail, ascii ]> (as indicated)

=item B<PATH = [ /bin, /usr/bin, /usr/local/bin, /opt/bin ]> (as indicated)

=item B<backtitle = "backtitle"> ('') *

=item B<title = "title"> ('') *

=item B<beepbefore = 0,1> (0) *

=item B<beepafter = 0,1> (0) *

=item B<height = \d+> (20) *

=item B<width = \d+> (65) *

=item B<listheight = \d+> (5) *

=back

=back

=head1 STATE METHODS

=over 2

=back

=head2 state( )

=over 4

=item EXAMPLE

=over 6

 if ($d->state() eq "OK") {
     $d->msgbox( text => "that went well" );
 }

=back

=item DESCRIPTION

=over 6

Returns the state of the last dialog widget command. The value can be one of
"OK", "CANCEL", "ESC". The return data is based on the exit codes (return value) of the
last widget displayed.

=back

=item RETURNS

=over 6

a single SCALAR.

=back

=back

=over 2

=back

=head2 ra( )

=over 4

=item EXAMPLE

=over 6

 my @array = $d->ra();

=back

=item DESCRIPTION

=over 6

Returns the last widget's data as an array.

=back

=item RETURNS

=over 6

an ARRAY.

=back

=back

=over 2

=back

=head2 rs( )

=over 4

=item EXAMPLE

=over 6

 my $string = $d->rs();

=back

=item DESCRIPTION

=over 6

Returns the last widget's data as a (possibly multiline) string.

=back

=item RETURNS

=over 6

a SCALAR.

=back

=back

=over 2

=back

=head2 rv( )

=over 4

=item EXAMPLE

=over 6

 my $string = $d->rv();

=back

=item DESCRIPTION

=over 6

Returns the last widget's exit status, aka: return value.

=back

=item RETURNS

=over 6

a SCALAR.

=back

=back

=head1 WIDGET METHODS

=over 2

=back

=head2 yesno( )

=over 4

=item EXAMPLE

=over 6

 if ($d->yesno( text => 'A binary type question?') ) {
     # user pressed yes
 } else {
     # user pressed no or cancel
 }

=back

=item DESCRIPTION

=over 6

Present the end user with a message box that has two buttons, yes and no.

=back

=item RETURNS

=over 6

TRUE (1) for a response of YES or FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 msgbox( )

=over 4

=item EXAMPLE

=over 6

 $d->msgbox( text => 'A simple message' );

=back

=item DESCRIPTION

=over 6

Pesent the end user with a message box that has an OK button.

=back

=item RETURNS

=over 6

TRUE (1) for a response of OK or FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 inputbox( )

=over 4

=item EXAMPLE

=over 6

 my $string = $d->inputbox( text => 'Please enter some text...',
                            entry => 'this is the input field' );

=back

=item DESCRIPTION

=over 6

Present the end user with a text input field and a message.

=back

=item RETURNS

=over 6

a SCALAR if the response is OK and FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 password( )

=over 4

=item EXAMPLE

=over 6

 my $string = $d->password( text => 'Enter some hidden text.' );

=back

=item DESCRIPTION

=over 6

Present the end user with a text input field, that has hidden input, and a message.

Note that the GDialog backend will provide a regular inputbox instead of a password
box because gdialog doesn't support passwords. GDialog is on it's way to the proverbial
software heaven so this isn't a real problem. Use Zenity instead :)

=back

=item RETURNS

=over 6

a SCALAR if the response is OK and FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 textbox( )

=over 4

=item EXAMPLE

=over 6

 $d->textbox( path => '/path/to/a/text/file' );

=back

=item DESCRIPTION

=over 6

Present the end user with a simple scrolling box containing the contents
of the given text file.

=back

=item RETURNS

=over 6

TRUE (1) if the response is OK and FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 menu( )

=over 4

=item EXAMPLE

=over 6

 my $selection1 = $d->menu( text => 'Select one:',
                            list => [ 'tag1', 'item1',
                                      'tag2', 'item2',
                                      'tag3', 'item3' ] );

=back

=item DESCRIPTION

=over 6

Present the user with a selectable list.

=back

=item RETURNS

=over 6

a SCALAR of the chosen tag if the response is OK and FALSE (0) for
anything else.

=back

=back

=over 2

=back

=head2 checklist( )

=over 4

=item EXAMPLE

=over 6

 my @selection1 = $d->checklist( text => 'Select one:',
                                 list => [ 'tag1', [ 'item1', 0 ],
                                           'tag2', [ 'item2', 1 ],
                                           'tag3', [ 'item3', 1 ] ]
                               );

=back

=item DESCRIPTION

=over 6

Present the user with a selectable checklist.

=back

=item RETURNS

=over 6

an ARRAY of the chosen tags if the response is OK and FALSE (0) for
anything else.

=back

=back

=over 2

=back

=head2 radiolist( )

=over 4

=item EXAMPLE

=over 6

 my $selection1 = $d->radiolist( text => 'Select one:',
                                 list => [ 'tag1', [ 'item1', 0 ],
                                           'tag2', [ 'item2', 1 ],
                                           'tag3', [ 'item3', 0 ] ]
                               );

=back

=item DESCRIPTION

=over 6

Present the user with a selectable radiolist.

=back

=item RETURNS

=over 6

a SCALAR of the chosen tag if the response is OK and FALSE (0) for
anything else.

=back

=back

=over 2

=back

=head2 fselect( )

=over 4

=item EXAMPLE

=over 6

 my $text = $d->fselect( path => '/path/to/a/file/or/directory' );

=back

=item DESCRIPTION

=over 6

Present the user with a file selection widget preset with the given path.

=back

=item RETURNS

=over 6

a SCALAR if the response is OK and FALSE (0) for anything else.

=back

=back

=over 2

=back

=head2 dselect( )

=over 4

=item EXAMPLE

=over 6

 my $text = $d->dselect( path => '/path/to/a/file/or/directory' );

=back

=item DESCRIPTION

=over 6

Present the user with a file selection widget preset with the given path.
Unlike fselect() this widget will only return a directory selection.

=back

=item RETURNS

=over 6

a SCALAR if the response is OK and FALSE (0) for anything else.

=back

=back

=head1 SEE ALSO

=over 2

=item PERLDOC

 UI::Dialog::GNOME
 UI::Dialog::KDE
 UI::Dialog::Console
 UI::Dialog::Backend
 UI::Dialog::Backend::ASCII
 UI::Dialog::Backend::CDialog
 UI::Dialog::Backend::GDialog
 UI::Dialog::Backend::KDialog
 UI::Dialog::Backend::Nautilus
 UI::Dialog::Backend::Whiptail
 UI::Dialog::Backend::XDialog
 UI::Dialog::Backend::XOSD
 UI::Dialog::Backend::Zenity

=back

=over 2

=item MAN FILES

 dialog(1), whiptail(1), zenity(1), gdialog(1), Xdialog(1),
 osd_cat(1), kdialog(1) and nautilus(1)

=back

=head1 BUGS

Please email the author with any bug reports. Include the name of the
module in the subject line.

=head1 AUTHOR

Kevin C. Krinke, E<lt>kevin@krinke.caE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=cut
