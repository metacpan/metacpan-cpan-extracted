package Tk::DBI::LoginDialog;

=head1 NAME

Tk::DBI::LoginDialog - DBI login dialog class for Perl/Tk.

=head1 SYNOPSIS

  use Tk::DBI::LoginDialog;

  my $top = new MainWindow;

  my $d = $top->LoginDialog(-dsn => 'XE');
 
  $d->username("scott");	# default a username

  my $dbh = $d->login;

  print $d->error . "\n"
	unless defined($dbh);

  # ... or ...

  $d->Show;

  print $d->error . "\n"
	unless defined($d->dbh);

=head1 DESCRIPTION

"Tk::DBI::LoginDialog" is a dialog widget which interacts with the DBI
interface specifically to attempt a connection to a database, and thus
returns a database handle.

This widget allows the user to enter username and password details
into the dialog, and also to select driver, and other driver-specific
details where necessary.

The dialog presents three buttons as follows:

=over 4

=item B<Cancel>: hides the dialog without further processing.

=item B<Exit>: calls the defined exit routine.  See L<CALLBACKS>.

=item B<Login>: attempt to login via DBI with the credentials supplied.

=back

These button labels may be overridden using the B<-buttons> and 
B<-default_button> arguments (refer to the L<Tk::DialogBox> widget for detail).

=cut

use 5.010001;

use strict;
use warnings;

use Carp qw(cluck confess);     # only use stack backtrace within class
use Data::Dumper;
use DBI;
use Log::Log4perl qw/ get_logger :nowarn /;

# based on Tk widget writers advice at:
#    http://docstore.mik.ua/orelly/perl3/tk/ch14_01.htm

use Tk::widgets qw/ DialogBox Label Entry BrowseEntry ROText /;
use base qw/ Tk::DialogBox /;

Construct Tk::Widget 'LoginDialog';


# package constants

use constant A_BUTTONS => qw/ Cancel Exit Login /;
use constant AS_DRIVERS => sort(DBI->available_drivers);
use constant CHAR_MASK => '*';	# masking character
use constant N_RETRY => 3;	# number of loops to attempt login
use constant S_DSN => "DSN";
use constant S_NULL => "";
use constant S_WHATAMI => "Tk::DBI::LoginDialog";


# --- package globals ---
our $VERSION = '1.006';


# --- package locals ---


# --- Tk standard routines ---
sub ClassInit {
	my ($class,$mw)=@_;

	$class->SUPER::ClassInit($mw);
}


sub CreateArgs {
	my($class, $mw, $args) = @_;

	# allow button labels to be overridden in class initialisation
	if (exists $args->{-buttons}) {

		$args->{-default_button} = $args->{-buttons}->[-1]
			unless (exists $args->{-default_button});

	} else {
		my @buttons = A_BUTTONS;
		$args->{-buttons} = [ @buttons ];
		$args->{-default_button} = $buttons[-1];
	}

#	printf "DEBUG args [%s]\n", Dumper($args);

	my @result = $class->SUPER::CreateArgs($mw, $args);

#	printf "DEBUG result [%s]\n", Dumper(\@result);

	return @result;
}


sub Populate {
	my ($self,$args)=@_;
	my %specs;
	my %dsn_types = ('DB2' => 'Database', 'Oracle' => 'Instance');

	$self->SUPER::Populate($args);

	my $attribute = $self->privateData;
	%$attribute = (
	    buttons => undef,
	    dbh => undef,
	    driver => S_NULL,
	    drivers => [ AS_DRIVERS ],
	    dsn => S_NULL,
	    dsn_label => S_NULL,
	    dsn_types => { %dsn_types },
	    password => S_NULL,
	    re_driver => '(' . join('|', sort(keys %dsn_types)) . ')',
	    username => S_NULL,
	    _logger => get_logger(S_WHATAMI),
	);

	$self->_paint;

	$self->Advertise('LoginDialog' => $self);

	$specs{-connect} = [ qw/ METHOD connect Connect /, undef ];
	$specs{-dbh} = [ qw/ METHOD dbh Dbh /, undef ];
	$specs{-disconnect} = [ qw/ METHOD disconnect Disconnect /, undef ];
	$specs{-driver} = [ qw/ METHOD driver Driver /, undef ];
	$specs{-drivers} = [ qw/ METHOD drivers Drivers /, undef ];
	$specs{-dsn} = [ qw/ METHOD dsn dsn /, undef ];
	$specs{-login} = [ qw/ METHOD login Login /, undef ];
	$specs{-password} = [ qw/ METHOD password Password /, undef ];
	$specs{-username} = [ qw/ METHOD username Username /, undef ];

=head1 WIDGET-SPECIFIC OPTIONS

C<LoginDialog> provides the following specific options:

=over 4

=item B<-mask>

The character or string used to hide (mask) the password.

=cut

	$specs{-mask} = [ qw/ PASSIVE mask Mask /, CHAR_MASK ];

=item B<-pressed>

The name of the button pressed during a login sequence.

=cut

	$specs{-pressed} = [ qw/ PASSIVE pressed Pressed /, S_NULL ];

=item B<-retry>

The number of times that attempts will be made to login to the database
before giving up.  A default applies.

=back

=cut
	$specs{-retry} = [ qw/ PASSIVE retry Retry /, N_RETRY ];

=head1 CALLBACKS

C<LoginDialog> provides the following callbacks:

=over 4

=item B<-command>

Per the DialogBox widget, this maps the B<Login> button to the
L<DBI> login routine.

=cut

	$specs{-command} = [ qw/ CALLBACK command Command /, [ \&cb_login, $self ] ];

=item B<-exit>

The sub-routine to call when the B<Exit> button is pressed.
Defaults to B<Tk::exit>.

=cut

	$specs{-exit} = [ qw/ CALLBACK exit Exit /, sub { Tk::exit; } ];

=item B<-showcommand>

This callback refreshes items in the dialog as part of the B<Show> method.

=back

=cut

	$specs{-showcommand} = [ qw/ CALLBACK showcommand Showcommand /, [ \&cb_populate, $self ] ];

	$self->ConfigSpecs(%specs);

	$self->ConfigSpecs('DEFAULT' => [$self]);

	$self->Delegates(
		'DEFAULT' => $self,
	);
}


# --- private methods ---
sub _button {
	my $self = shift;
	my $pressed = shift;
	my $data = $self->privateData;
	my %button;

	if (defined $data->{'buttons'}) {

		%button = %{ $data->{'buttons'} };
	} else {

		# populate button hash with button text, e.g.
		#	{ button -> Cancel, button1 -> Exit, button2 -> Login }

		for ($self->Subwidget) {
			if ($_->class eq 'Button') {

				$button{$_->name} = $_->cget('-text');

       	         		$self->_log->trace(sprintf "subwidget name [%s]", $_->name);
			}
		}

		$data->{'buttons'} = { %button };
	}

	$self->_log->trace(sprintf "button [%s]", Dumper(\%button));

	for (keys %button) {
		return $_
			if ($button{$_} eq $pressed);
	}

	return undef;
}


sub _default_value {
	my $self = shift;
	my $attribute = shift;
	my $value = shift;
	my $data = $self->privateData;

	if (defined $value) {
		$data->{$attribute} = $value;
		return $value;
	}
	return $data->{$attribute};
}


sub _error {
	my $self = shift;
	my $rotext = $self->Subwidget('error');

	if (@_) {
		$rotext->Contents(join(' ', @_));
	}

	my $s_text = $rotext->Contents;

	chomp($s_text);

	return $s_text;
}


sub _log {
	return shift->privateData->{'_logger'};
}


sub _message {
#	echo either the message passed or the DBI error string
#	return the string.
#
	my $self = shift;
	my $msg = shift;

	if (defined $msg) {

		$self->_log->info($msg);

	} elsif (defined $DBI::errstr) {

		$msg = $DBI::errstr;
		$self->_log->logwarn($msg);

	} else {
		$msg = "WARNING unspecified DBI connect error";
		$self->_log->logwarn($msg);
	}

	return $msg;
}


sub _paint {
	my $self = shift;
	my $name;
	my $data = $self->privateData;
	my $t = $self->Subwidget('top');

	# First frame holds the credentialling widgets (the main frame!)

	my $f = $t->Frame(-borderwidth => 3,
		)->pack(-side => 'top', -fill => 'both', -expand => 1);


	# Second frame holds the "hidden" version widget

	my $fv = $t->Frame()->pack(-side => 'top');

	my $str = join(' ', "Version:", S_WHATAMI, $VERSION);

	my $ver = $fv->ROText(-height => 1, -width => length($str),
		-wrap => 'none', -relief => 'flat');

	#$ver->insert('end', $str);
	$ver->Contents($str);

	$self->Advertise('_version', $ver);	# don't document this!


	# create all widgets first then handle geometry later

#	+---------------------+
#	| label | BrowseEntry | driver
#	+---------------------+
#	| label | Entry       | dsn
#	| label | Entry       | username
#	| label | Entry       | password
#	+---------------------+
#	| ROText              | error
#	+---------------------+
#	| label (hidden)      | version
#	+---------------------+

	my $ld = $f->Label(-text => 'Driver', );
	my $li = $f->Label(-textvariable => \$data->{'dsn_label'},);
	my $lu = $f->Label(-text => 'Username', );
	my $lp = $f->Label(-text => 'Password', );

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
Valid subwidget names are listed below.

=over 4

=item Name:  driver, Class: BrowseEntry

Widget reference of B<driver> drop-down widget.

=cut

	$name = 'driver';

	my $ed = $f->BrowseEntry(-state => 'readonly',
			-textvariable => \$data->{$name},
			-choices => $data->{'drivers'});

	$self->Advertise($name, $ed);

=item Name:  dsn, Class: Entry

=item Name:  username, Class: Entry

=item Name:  password, Class: Entry

Widget references for the basic credential entry widgets.

=cut

	my %e;

	for $name (qw/ dsn username password /) {

		my $e = $f->Entry(-textvariable => \$data->{$name});

		$self->Advertise($name, $e);

		my $short = substr($name, 0, 1); # one-letter widget name!

		$e{$short} = $e;
	}

=item Name:  L_driver, Class: Label

=item Name:  L_dsn, Class: Label

=item Name:  L_username, Class: Label

=item Name:  L_password, Class: Label

Widget references of the left-most label widgets.

=cut

	$self->Advertise('L_driver', $ld);
	$self->Advertise('L_dsn', $li);
	$self->Advertise('L_username', $lu);
	$self->Advertise('L_password', $lp);

=item Name:  error, Class: ROText

Widget reference of the status/error message widget.

=back

=cut
	my $err = $f->ROText(-height => 3, -width => 40,
		-wrap => 'word', -relief => 'groove');

	$self->Advertise('error', $err);


	# all widgets are now created, now manage their geometry...

	# 1. calculate label padding to align with entry fields

	my $gd = $ed->Subwidget('arrow')->reqheight - $ld->reqheight;
	my $gi = $e{'d'}->reqheight - $li->reqheight;
	my $gu = $e{'u'}->reqheight - $lu->reqheight;

	# 2. lay-down the labels starting with username (the longest label)

	$lu->form(-top => $li);
	$ld->form(-right => ['&', $lu], -padtop => $gd);
	$li->form(-right => ['&', $lu], -top => $ld, -padtop => $gi);
	$lp->form(-right => ['&', $lu], -top => $lu, -padtop => $gu);

	# 3. lay-down the entry fields

	$ed->form(-left => $ld, -right => '%100');
	$e{'d'}->form(-left => $li, -top => $ed, -right => '%100');
	$e{'u'}->form(-left => $lu, -top => $e{'d'}, -right => '%100');
	$e{'p'}->form(-left => $lp, -top => $e{'u'}, -right => '%100');

	# 4. add the error field at the bottom, allowing it to "stretch"

	$err->form(-top => $e{'p'}, -left => '%0', -right => '%100', -bottom => '%100');
}


# --- callbacks ---
sub cb_login {
	my $self = shift;
	my $button = shift;
	my $data = $self->privateData;

	unless (defined $button) { # Bug #108406 fix for WM event, e.g. close

		$self->_log->logwarn("WARNING no action detected");
		$self->configure('-pressed' => S_NULL);

		return;
	}
	$self->configure('-pressed' => $button);


	my $button_id = $self->_button($button);
	$self->_log->trace("button_id [$button_id] button [$button]");


	if ($button_id eq "button") {		# default 'Cancel' button

	} elsif ($button_id eq "button1") {	# default 'Exit' button

		$self->Callback('-exit');

	} elsif ($button_id eq "button2") {	# 'default Login' button

		my ($dbh,$msg) = $self->connect($data->{'driver'}, $data->{'dsn'}, $data->{'username'}, $data->{'password'});

		$data->{'dbh'} = $dbh
			if (defined $dbh);

		$self->_error($msg);
	} else {
		$self->_log->logconfess("ERROR invalid action [$button]");
	}
}


sub cb_populate {
	my $self = shift;
	my $button = shift;
	my $data = $self->privateData;

	$self->driver;	# default a driver

	my $w; for (qw/ dsn username password /) {

		$w = $self->Subwidget($_);

		last if ($data->{$_} eq S_NULL);
	}

	if (Tk::Exists($w)) {	# fields may have been removed by caller (bad)
		#$self->_log->debug(sprintf "setting focus to [%s]", $w->PathName);
		$w->focus;
	}

	# set the masking for the password field

	my $pw = $self->Subwidget('password');
	$pw->configure(-show => $self->cget('-mask'))
		if (Tk::Exists($pw));	# caller might have removed this widget
}


=head1 METHODS

=over 4

=item B<connect>(Driver, DSN, Username, Password)

The DBI connection routine.  This does not interact with any Tk widgets
so can be called natively, if required.  This routine is also called when
the B<Login> button is pressed.  Returns a database handle and a string
message indicating status of connection attempt.

=cut

sub connect {
	my $self = shift;
	$self->_log->logconfess("SYNTAX: connect(Driver, DSN, Username, Password)") unless (@_ == 4);
	my $driver = shift; 
	my $dsn = shift;
	my $username = shift;
	my $password = shift;

	$self->_log->debug("attempting to login to database");

	my $source = join(':', "DBI", $driver, defined($dsn) ? $dsn : S_NULL);

	$self->_log->debug("source [$source]");

	my $dbh = DBI->connect($source, $username, $password);

	my $msg = (defined $dbh) ? $self->_message("Connected okay.") : $self->_message;

	return ($dbh, $msg);
}

=item B<dbh>

Returns the database handle associated with the current object.

=cut

sub dbh {
	return shift->_default_value('dbh');
}


=item B<disconnect>

Will call the DBI disconnection routine, using the stored handle.
This routine is called when the B<Login> button is pressed. 

=cut

sub disconnect {
	my $self = shift;
	$self->_log->logconfess("SYNTAX: disconnect") unless (@_ == 0);

	my $dbh = $self->dbh;
	my $msg;

	if (defined $dbh) {

		$self->_log->debug("attempting to disconnect from database");

		$dbh->disconnect;

		$msg = $self->_message("Disonnected okay.");

	} else {
		$msg = $self->_message("no database connection exists");
	}

	return $msg;
}

=item B<driver> [EXPR]

Set or return the B<driver> property.  For specific drivers, the label
associated with the B<dsn> may also change to better match the nomenclature
of the specified database management system.

If a driver is specified which is not currently "available", then this 
method will re-set the driver to the first available.

=cut

sub driver {
	my $self = shift;
	my $driver = shift;
	my $data = $self->privateData;

	my %available = map { $_ => 1 } @{ $data->{'drivers'} };
	my $first = $data->{'drivers'}->[0];
	my $default_driver = sub {
		$driver = $first;
		$data->{'dsn_label'} = S_DSN;
	};

	$self->_log->logconfess("ERROR no DBI drivers loaded")
		unless (defined $first);

#	$self->_log->debug(sprintf "DEBUG first [%s] available [%s]", $first, Dumper(\%available));

#	$self->_log->debug(sprintf "DEBUG re_driver [%s] driver [%s]", $self->privateData->{'re_driver'}, $self->privateData->{'driver'});

	if (defined $driver) {

		if (exists($available{$driver})) {

			if (exists($data->{'dsn_types'}->{$driver})) {

				$data->{'dsn_label'} = $data->{'dsn_types'}->{$driver};
			} else {
				$data->{'dsn_label'} = S_DSN;
			}
		} else {

			&$default_driver;
	
			$self->_log->logwarn("WARNING invalid driver specified, choosing first available [$driver]");
		}

	} elsif ($data->{'dsn_label'} eq S_NULL) {	# first time through

		&$default_driver;

	} elsif (!exists( $available{ $data->{'driver'} } )) {

		# existing driver has since been removed, overridden drivers?

		&$default_driver;
	}

	return $self->_default_value('driver', $driver);
}


=item B<drivers> [LIST]

Returns a list of available drivers.
This defaults to those drivers defined as available by DBI.
Note that it is possible to override this list, however this should be
done with caution, as it could cause DBI errors during the login process.
The most likely use of this method is to constrain the list of drivers
to a subset of those available by default.

=cut

sub drivers {
	my $self = shift;
	my @drivers = @_;

	my $data = $self->privateData;
	my $w = $self->Subwidget('driver');
	my $f_reset = 0;

	if (@drivers > 0) {

		$self->driver;		# re-establish a default
		$f_reset = 1;

	} else {
		if (@{ $data->{'drivers'} }) {

			@drivers = @{ $data->{'drivers'} };

		} else {
			# this is no good; someone has emptied the array; fixit

			@drivers = AS_DRIVERS;
			$f_reset = 1;
		}
	}

	my $choices = $w->cget('-choices');

	$w->configure('-choices', \@drivers)
		unless (@$choices == @drivers || $f_reset || @$choices <= 0);

	return $self->_default_value('drivers', \@drivers);
}


=item B<dsn> [EXPR]

Set or return the B<dsn> property.  In some drivers this refers to the
database name or database instance.

=cut

sub dsn {
	return shift->_default_value('dsn', shift);
}


=item B<error>

Return the latest error message from the DBI framework following an
attempt to connect via the specified driver.
If last connection attempt was successful,
this will return the DBI message "Connected okay."

=cut

sub error {
	return shift->_error;
}


=item B<login> [RETRY]

A convenience function to show the login dialog and attempt connection.
The number of attempts is prescribed by the B<RETRY> parameter, which is
optional.
Returns a DBI database handle, subject to the DBI B<connect> method.

=cut

sub login {
	my $self = shift;
	my $retry = (@_) ? shift : $self->cget('-retry');

	# override silly values for retry which might have been 
	# configured by the calling application

	if ($retry <= 0) {
		$retry = N_RETRY;

		$self->configure('-retry' => $retry);

		$self->_log->debug("-retry reset to [$retry]");
	}

	while ($retry-- > 0) {

		my $button = $self->Show;

		last if (defined $self->dbh);

		if (defined $button) {
			my $button_id = $self->_button($button);

			last if ($button_id eq "button"); # 'Cancel' button
		}
	} 

	return $self->dbh;
}


=item B<password> [EXPR]

Set or return the B<password> property.
May not be applicable for all driver types.

=cut

sub password {
	return shift->_default_value('password', shift);
}


=item B<Show>

The Show method behaves as per the DialogBox widget.

=item B<username> [EXPR]

Set or return the B<username> property.
May not be applicable for all driver types.

=cut

sub username {
	return shift->_default_value('username', shift);
}


=item B<version> [0|1]

Toggle the display of this widget's version number (module version).
This can only be done programmatically.  
The default behaviour is to hide the version.
Irrespective of the argument passed, this routine will return the 
version number.

=cut

sub version {
	my $self = shift;
	my $toggle = (@_) ? shift : 0;	# default to off
	
	my $ver = $self->Subwidget('_version');

	if ($toggle) {
		$ver->pack(-side => 'left', -fill => 'both', -expand => 1);
	} else {
		if (defined $ver->manager) {
			#$self->_log->debug(sprintf "manager [%s]", $ver->manager);
			$ver->packForget;
			$ver->parent->update;
		}
	}

	return $VERSION;
}


1;

__END__

=back

=head1 VERSION

Build V1.006

=head1 AUTHOR

Copyright (C) 2014-2016  B<Tom McMeekin> E<lt>tmcmeeki@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<perl>, L<DBI>, L<Log::Log4perl>, L<Tk>, L<Tk::DialogBox>.

=cut

