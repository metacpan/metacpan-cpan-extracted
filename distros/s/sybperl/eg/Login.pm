#	@(#)Login.pm	1.1	2/28/96
##########################################
##########################################
##					##
##	Login - a reusable Tk-widget	##
##		login screen		##
##					##
##	Version 1.1			##
##					##
##	Brent B. Powers	(B2Pi)		##
##	Merrill Lynch			##
##	powers@swaps-comm.ml.com	##
##					##
##					##
##########################################
##########################################
#
#From powers@swaps.ml.com  Wed Feb 28 08:14:35 1996
#From: "Brent B. Powers Swaps Programmer x2293" <powers@swaps.ml.com>
#To: mpeppler@itf.ch
#Subject: Login Widget
#X-Filter: mailagent [version 3.0 PL44] for mpeppler@itf.ch
#
#
#Greetings.  I'm not really sure where this goes.  It either goes in
#Sybase or Tk, and I figured since Sybase is more exclusive, I'd hand
#it to you.  I was rather hoping you'd see fit to distribute this with
#the next release of Sybperl.
#
#This is just a graphical login widget for TkPerl and Sybase.
#Documentation is via pod, and there's even a sample program in there
#that needs only to be altered with the appropriate database/server
#combinations.
#
# INSTLLATION:
#
# To use this module, this file should be moved to $PERL5LIB/Sybase/Login.pm

=head1 NAME

=head2 Sybase::Login

=head1 Change History

=over 4

=item

I<1.0> - Initial Implementation

I<1.1> - Componentized for perl5.0021bh, handlers fixed

=back

=cut

=head1 DESCRIPTION

Login is a Widget that presents a dialog box to the user so that
the user may enter his or her login name and password, as well as 
select the appropriate database and server.

=head1 USAGE

One uses Login by creating a new Login widget, adding at least one
Database via the addDatabase method, configuring via the configure
method, and then getting a valid login via the getVerification method.

=over 4

=item

=head2 Sample Program

=over 8

=item

 #!/usr/local/bin/perl -w

 use Tk;
 use Sybase::DBlib;
 use Sybase::Login;
 use strict;

 my($main) = MainWindow->new;
 my($Login) = $main->Login;

 $Login->addDatabase('DB',	'SYBSRV1','SYB11');
 $Login->addDatabase('DBBACK',	'SYBSRV1','SYB11');

 $Login->configure(-User => $ENV{'USER'},
		   -ULabel => 'User Name:',
		   -Title => 'Please Login');

 my($msg) = $main->Message(-text => 'Ready to go')->pack;
 $main->Button(-text => 'kick me!',
	       -command => sub {
		 my($pwd, $usr, $db, $srv, $mDB);
		 if ($Login->getVerification(-Force => 1)) {
		   $pwd = $Login->cget(-Password);
		   $usr = $Login->cget(-User);
		   $db =  $Login->cget(-Database);
		   $srv = $Login->cget(-Server);
		   print "Results good:\n\tUser:\t\t$usr\n";
		   print "\tPassword:\t$pwd\n\tDatabase:\t$db\n";
		   print "\tServer:\t\t$srv\n";
		   print "Verifying Login...\n";
		   $mDB = Sybase::DBlib->dblogin("$usr","$pwd", "$srv");
		   $mDB->dbuse($db);
		   $mDB->dbclose;
		   print "Login worked!!!\n";
		 } else {
		   print "Login cancelled at User request.\n";
		 }
	       })->pack;

 $main->Button(-text => 'exit',
	       -command => sub {$main->destroy;})->pack;

 MainLoop;

 print "And I'm on my way home!\n";

 exit;

=back



=item

=head2 Operation

The user is presented with a dialog box.  The focus is on the username
entry if no user name has been configured; otherwise, it is on the
password entry.  If multiple databases have been configured, the user
may select the appropriate database from the menu button. If multiple
servers have been configured for the selected database, the user may
select the appropriate server from the menu button.

When the user has finished entering information, she may press the OK
button to attempt to login, or the cancel button to abort the process.
If the user presses the OK button, and the login succeeds, control
returns to the caller.  If the login fails, an error dialog box is
displayed, and the user may press retry, or may press cancel, in which
case control returns to the caller exactly as if the user had pressed
cancel at the main login screen.

When control returns to the caller, the return value will be 1 if the 
login was successful, or 0 if not.

=head2 Notes

A caller may define a message or error handler either before or after
calling any of the methods of this object. getCurrentVerification
will restore the handlers extant when invoked.

=back

=head1 Methods

=over 4

=item

=head2 getCurrentVerification

I<$Login->>I<getCurrentVerification;>

I<(No parameters)>

return 1 if the current configuration will result
in a valid login, 0 otherwise.  No GUI is ever displayed.

=head2 getVerification

I<$Login->>I<getVerification(-Force => ?);>

If the current configuration is NOT valid, activate the login
frame. This will return 1 with a valid configuration, or 0 if the user
hit cancel.  If the -Force parameter is passed as 't', 'y', or 1,
the login frame will be activated even if the current configuration
is valid.

=head2 addDatabase

I<$Login->>I<addDatabase(Database, Server List);>

adds a database/server set.  The first parameter is
the name of the database, the second is a list of
Associated Servers.  See the code above for examples.

Note that the first server in the list is the default server for that
database.  Further note that adding a database a second time simply
alters the servers.

=head2 clearDatabase

I<$Login->>I<clearDatabase([Database[, Database,...]);>

Clears the given Database entries, or all databases if 
if none are specified.

=back

=head1 Configuration Items

Any of the following configuration items may be set via the configure
method, or retrieved via the cget method.

=over 4

=item 

=head2 -User

=over 4

Set or get the username.  The default is blank.

=back

=head2 -Password

=over 4

Set or get the password.  The default is blank.

=back

=head2 -Title

=over 4

Set or get the Title of the Login Widget.  The default is 'Database Login'

=back

=head2 -Database

=over 4

Set or get the default Database.  The default is blank.  The call will
silently fail if the database is not configured via the AddDatabase
method.  If the configured server is not a valid server for the given
database, the server will be set to the default server for the
database.

=back

=head2 -Server

=over 4

Set or get the default Server.  The default is blank.  The call will
silently fail if the server is not a valid server for the currently
configured database.

=back

=head2 -OKText

=over 4

Set or get the text for the I<OK> button.  The default is OK.

=back

=head2 -CancelText

=over 4

Set or get the text for the I<Cancel> button.  The default is Cancel.


=back

=head2 -ULabel

=over 4

Set or get the label for the User name entry.  The default is 'User:'.

=back

=head2 -PLabel

=over 4

Set or get the label for the Password entry.  The default is 'Password:'.

=back

=head2 -DLabel

=over 4

Set or get the label for the Database Menu Button.  The default is 'Database:'.

=back

=head2 -SLabel

=over 4

Set or get the label for the Server Menu Button.  The default is 'Server:'.

=back

=head2 -Labelfont

=over 4

Set or get the font used for the labels.  The default is 
'-Adobe-Courier-Bold-R-Normal--*-120-*'.

=back

=head2 -EDlgTitle

=over 4

Set or get the Title for the Error Dialog. The default is
'Database Login Error!'.

=back

=head2 -EDlgText

=over 4

Set or get the text displayed in the Error Dialog.  The default is
'Unable to login to $db at $srv'.  $db will be interpreted as the 
Database name, $srv will be interpreted as the Server name, $usr
will be interpreted as the User name, and $pwd will be interpreted
as the password.

=back

=head2 -EDlgRetry

=over 4

Set or get the text for the Retry button in the Error Dialog. The
default is 'Retry'.

=back

=head2 -EDlgCancel

=over 4

Set or get the text for the Cancel button in the Error Dialog. The
default is 'Cancel'.

=back

=back


=head1 Author

B<Brent B. Powers, Merrill Lynch (B2Pi)>

powers@ml.com

This code may be distributed under the same conditions as perl itself.

=cut
### Gevalt.  That's the end... now the code
package Sybase::Login;

require 5.002;

use Tk;
use Tk::Dialog;
use Sybase::DBlib;
use Carp;
use strict;

@Sybase::Login::ISA = qw (Tk::Toplevel);
Tk::Widget->Construct('Login');

my(@topside) = (-side => 'top');
my(@leftside) = (-side => 'left');
my(@rightside) = (-side => 'right');
my(@xfill) = (-fill => 'x');
my(@expand) = (-expand => 1);
my(@wanchor) = (-anchor => 'w');
my(@eanchor) = (-anchor => 'e');
my(@raised) = (-relief => 'raised');
my(@sunken) = (-relief => 'sunken');
my(@bw2) = (-borderwidth => 2);

sub Populate {

    ## Constructor for Login (password verification) widget.  Inherits
    ## new from base class

    my($self, @args) = @_;

    $self->SUPER::Populate(@args);

    $self->withdraw;

    ## This is a good chance to initialize some values
    $self->{Verified} = 0;
    $self->{DBList} = undef;

    $self->BuildBox;

    $self->ConfigSpecs(-User  =>	['PASSIVE', undef, undef, ''],
		       -Password =>	['PASSIVE', undef, undef, ''],
		       -Title =>	['PASSIVE', undef, undef, 'Database Login'],
		       -Database =>	['METHOD', undef, undef, ''],
		       -Server =>	['METHOD', undef, undef, ''],
		       -OKText =>	['PASSIVE', undef, undef, 'OK'],
		       -CancelText =>	['PASSIVE', undef, undef, 'Cancel'],
		       -ULabel =>	['PASSIVE', undef, undef, 'User:'],
		       -PLabel =>	['PASSIVE', undef, undef, 'Password:'],
		       -DLabel =>	['PASSIVE', undef, undef, 'Database:'],
		       -SLabel =>	['PASSIVE', undef, undef, 'Server:'],
		       -Labelfont =>	['PASSIVE', undef, undef,
				     '-Adobe-Courier-Bold-R-Normal--*-120-*'],
		       -EDlgTitle =>	['PASSIVE', undef, undef,
					 'Database Login Error!'],
		       -EDlgText =>	['PASSIVE', undef, undef,
					 'Unable to login to $db at $srv'],
		       -EDlgRetry =>	['PASSIVE', undef, undef,'Retry'],
		       -EDlgCancel =>	['PASSIVE', undef, undef,'Cancel'],
		      );
}


sub addDatabase {
    my($self,$db,@srvlist) = @_;
    ### $db is the Database being added,
    ### @srvlist is the list of servers

    if (defined($db)) {
	$db =~ s/^\s+|\s+$//g;
    } else {
	$db = '';
    }
    if ($db eq '') {
	carp "Use Login->addDatabase(database, server [, server ...])";
	return;
    }

    ## Kvetch if somebody's trying to add a blank database
    if (!defined(@srvlist)) {
	carp "No servers defined for $db";
	return;
    }


    ### The user may either be modifying a current entry,
    ### implicitly deleting a current entry, or 
    ### creating a new entry
    $self->{DBList}{$db} = \@srvlist;

    my($db1,$srv1);

    ### If the current Database is that just modified, check that the
    ### current server is still valid.  If not, set it to the default.
    if ($self->{Configure}{-Database} eq $db) {
	foreach (@srvlist) {
	    if ($self->{Configure}{'-Server'} eq $_) {
		# Found it, so we're OK
		return;
	    }
	}
	# Didn't find it, so set it to the default
	$self->{Configure}{'-Server'} = @srvlist[0];
    }
}

sub clearDatabase {
#	Parameters:	([Database[, Database, ...]])

    my($self) = shift;
    my($firstdeldb) = @_;
    if (defined($firstdeldb) and ($firstdeldb ne "")) {
	### Parameters given
	foreach (@_) {
	    delete $self->{DBList}{$_};

	    if ($self->{Configure}{'-Database'} eq $_ ) {
		$self->{Configure}{'-Database'} = '';
		$self->{Configure}{'-Server'} = '';
	    }
	}
    } else {
	### No parameters given, delete all databases
	undef $self->{DBList};
	$self->{Configure}{'-Database'} = '';
	$self->{Configure}{'-Server'} = '';
    }
}

sub Server {
    my($self, $server) = @_;

    my($db);

    # Verify that the server is correct before setting

    ## Note that the database must be configured first,
    ## and the given server valid for the configured database
    if (defined($server) &&
	($server ne '') &&
	($self->{Configure}{-Database} ne '')) {

	foreach (@{$self->{DBList}{$self->{Configure}{'-Database'}}}) {
	    if ($server eq $_) {
		## Found it... save it
		$self->{Configure}{'-Server'} = $server;
		last;
	    }
	}
    }
    return $self->{Configure}{'-Server'};
}

sub Database {
#	Parameters:	(Database)
    my ($self, $db) = @_;

    if (defined($db) and ($db ne '')) {
	## Only set a database that is configured
	if (defined($self->{DBList}{$db})) {
	    $self->{Configure}{'-Database'} = $db;

	    ##  Now check that the server is still valid
	    foreach (@{$self->{DBList}{$db}}) {
		if ($self->{Configure}{'-Server'} eq $_) {
		    #  It matches, and we're done
		    return $db;
		}
	    }
	    ## Hmmm, no match, use default
	    $self->{Configure}{'-Server'} = $self->{DBList}{$db}[0];
	}
    }
    return $self->{Configure}{'-Database'};
}

sub BuildBox {

    my($self) = shift;

    ############ Create the User name frame #############
    my($tFrame) = $self->Frame#(@bw2)#,@raised)
	    ->pack(@topside, @xfill);

    $self->{ULabel} = $tFrame->Label
	    ->pack(@leftside, @wanchor);

    $self->{'userEntry'} =
	    $tFrame->Entry(-textvariable => \$self->{Configure}{'-User'},
			   @sunken)
		    ->pack(@rightside, @expand, @xfill, @wanchor);
    
    ############ Create the Password Frame #############
    $tFrame = $self->Frame#(@bw2)#, @raised)
	    ->pack(@topside, @xfill);

    $self->{PLabel} = $tFrame->Label
	    ->pack(@leftside, @wanchor);

    $self->{'passEntry'} =
	    $tFrame->Entry(-textvariable => \$self->{Configure}{'-Password'},
			   -show => '#',
			   @sunken)
	    ->pack(@rightside, @expand, @xfill, @wanchor);

    ############ Create the Database  Frame #############
    $self->{dbFrame} = $self->Frame#(@bw2)#, @raised)
	    ->pack(@topside, @xfill);

    $self->{DLabel} = $self->{dbFrame}->Label
	    ->pack(@leftside, @wanchor);

    ############ Create the Server  Frame #############
    $self->{srvFrame} = $self->Frame#(@bw2)#, @raised)
	    ->pack(@topside, @xfill);

    $self->{SLabel} = $self->{srvFrame}->Label
	    ->pack(@leftside, @wanchor);

    ############ Create the Button Frame #############
    $tFrame = $self->Frame(@bw2)#, @raised)
	    ->pack(@topside);

    $self->{OKButton} = $tFrame->Button(-command => sub {
	$self->TestLogin($self);
    })
	    ->pack(@leftside, @expand);

    $self->{OKButton}->bind('<Return>' => [sub {$self->{OKButton}->invoke}]);

    $self->{CancelButton} = $tFrame->Button(-command => sub {
	$self->Exit(0);
    })
	    ->pack(@leftside, @expand);

    $self->{CancelButton}->bind('<Return>' => sub {
	$self->{CancelButton}->invoke});
    $self->bind('<Escape>' => [sub {$self->{CancelButton}->invoke}]);

    $self->{'passEntry'}->bind('<Return>'=> sub { $self->{OKButton}->focus; });
    $self->{'passEntry'}->bind('<Control-u>' => sub {
	$self->{Configure}{-Password} = '';
    });
    $self->{'userEntry'}->bind('<Control-u>' => sub {
	$self->{Configure}{-User} = '';
    });
    $self->{'userEntry'}->bind('<Return>'=> sub {
	\$self->{passwdEntry}->focus; } );
		       
}

sub getCurrentVerification {
    my $self = shift;

    ### The caller wants to find out if the current user, password
    ### database and server are OK.
#   my ($rslt) = 
	    &TestDatabase($self);

#   return $rslt;
}

sub getVerification {

    my($self, $force, $forceval) = @_;
    if (!defined($self->{'DBList'}) ||
	(keys %{$self->{DBList}}) == 0) {
	carp "No Databases defined";
	return 0;
    }

    if (!defined($force) || !defined($forceval)) {
	$force = 0;
    } else {
	$force =~ s/^\s+|\s+$//g;
	if (lc($force) eq '-force') {
	    $forceval =~ s/^\s+|\s+$//g;
	    $force = lc(substr($forceval,0,1));
	    $force = 1 if (($force eq 'y') ||
			   ($force eq 't') ||
			   ($force == 1));
	} else {
	    $force = 0;
	}
    }

    if ($force || !getCurrentVerification($self)) {
	## OK, do it????
	$self->{Verified} = -1;

	$self->title($self->{Configure}{-Title});
	my($ParentState) = $self->parent->state;

	if ($ParentState ne 'withdrawn') {
	    $self->parent->withdraw;
	}

	## Set up the labels for the entries and menus
	$self->{ULabel}->configure(-text => $self->{Configure}{-ULabel},
				   -font => $self->{Configure}{-Labelfont});
	$self->{PLabel}->configure(-text => $self->{Configure}{-PLabel},
				   -font => $self->{Configure}{-Labelfont});
	$self->{DLabel}->configure(-text => $self->{Configure}{-DLabel},
				   -font => $self->{Configure}{-Labelfont});
	$self->{SLabel}->configure(-text => $self->{Configure}{-SLabel},
				   -font => $self->{Configure}{-Labelfont});
	$self->update;

	## Get the widest label...
	my($maxWidth) = $self->{ULabel}->width;
	my($max) = '-ULabel';
	
	if ($self->{PLabel}->width > $maxWidth) {
	    $maxWidth = $self->{PLabel}->width;
	    $max = '-PLabel';
	}
	
	if ($self->{DLabel}->width > $maxWidth) {
	    $maxWidth = $self->{DLabel}->width;
	    $max = '-DLabel';
	}
	
	if ($self->{SLabel}->width > $maxWidth) {
	    $maxWidth = $self->{SLabel}->width;
	    $max = '-SLabel';
	}
	$max = length($self->{Configure}{$max});

	$self->{ULabel}->configure(-width => $max);
	$self->{PLabel}->configure(-width => $max);
	$self->{DLabel}->configure(-width => $max);
	$self->{SLabel}->configure(-width => $max);
	$self->update;

	## Set up the buttons
	$self->{OKButton}->configure(-text =>
				     $self->{Configure}{-OKText});
	$self->{CancelButton}->configure(-text =>
					 $self->{Configure}{-CancelText});

	&CreateDBMenu($self);
	# Make sure that the Database is set
	if (!defined($self->{Configure}{'-Database'}) ||
	    ($self->{Configure}{'-Database'} eq '')) {
	    $self->{Configure}{'-Database'} = (keys %{$self->{DBList}})[0];
	}

	&CreateSrvMenu($self);
	# Make sure that the server is set
	if (!defined($self->{Configure}{'-Server'}) ||
	    ($self->{Configure}{'-Server'} eq '')) {
	    $self->{Configure}{'-Server'} =
		    $self->{DBList}{$self->{Configure}{'-Database'}}[0];
	}
 
        # Set the focus to the user if it hasn't been set, or
        # to the password frame
        my ($oldFocus) = $self->focusCurrent;
        if ($self->{Configure}{-User} eq "") {
            $self->{'userEntry'}->focus;
        } else {
            $self->{'passEntry'}->focus;
        }
 
	# Take care of the window position
	my($x) = int(($self->screenwidth - $self->reqwidth)/2)
		- $self->parent->vrootx;
	my($y) = int(($self->screenheight - $self->reqheight)/2)
		- $self->parent->vrooty;

	$self->geometry("+$x+$y");

	$self->deiconify;

	## And do a grab
	$self->grab;

	## Wait for verification or cancel
	$self->tkwait('variable'=>\$self->{Verified});

	$self->grab('release');
        $oldFocus->focus if defined($oldFocus);

	$self->withdraw;
	if ($ParentState eq 'normal') {
	    $self->parent->deiconify;
	} elsif ($ParentState eq 'iconic') {
	    $self->parent->iconify;
	}

	return $self->{Verified};

    }
    return 1;
}

sub CreateSrvMenu {
    my($self) = @_;

    if (defined ($self->{serverMB})) {
	$self->{serverMB}->destroy;
	undef $self->{serverMB};
    }

    $self->{serverMB} = $self->{srvFrame}->
	    Menubutton(-textvariable => \$self->{Configure}{'-Server'},
		       @raised);

    my($srv);

    if (@{$self->{DBList}{$self->{Configure}{'-Database'}}} == 1) {
	($srv) = @{$self->{DBList}{$self->{Configure}{'-Database'}}};
	$self->{serverMB}->command(-label => $srv);
	$self->{serverMB}->configure(-state => 'disabled');
    } else {
	my ($x,$srv);

	foreach $srv (@{$self->{DBList}{$self->{Configure}{'-Database'}}}) {
	    $x = "\$self->{serverMB}->command(-label => '$srv',
					     -command => sub {
						 \&Server(\$self,'$srv');
					     });";
	    eval $x;
	    if ($@) {
		carp "Eval (CreateSrvMenu) Error:\n\"$@\"\n";
		carp "$x \n";
	    }
	}
    }

    $self->{serverMB}->pack(@rightside, @eanchor, @expand, @xfill);
}

sub CreateDBMenu {
    my ($self) = @_;

    my ($x,$db);
    $self->{databaseMB}->destroy if (defined($self->{databaseMB}));
    undef $self->{databaseMB} if (defined($self->{databaseMB}));

    $self->{databaseMB} = $self->{dbFrame}->
	    Menubutton(-textvariable =>\$self->{Configure}{'-Database'},
		       @raised);

    if ((scalar keys %{$self->{DBList}}) > 1) {
	foreach $db (sort keys(%{$self->{DBList}})) {
	    $x = "\$self->{databaseMB}->command(-label => '$db',
						-command =>
						sub {
						    \&Database(\$self,'$db');
						    &CreateSrvMenu(\$self);
						});";

	    eval $x;
	    carp "Eval (CreateDBMenu) Error:\n\"$@\"\n" if $@;
	    carp "$x \n" if $@;
	}
    } else {
	$db = (keys %{$self->{DBList}})[0];
	$self->{databaseMB}->command(-label => $db);
	$self->{databaseMB}->configure(-state => 'disabled');
    }

    $self->{databaseMB}->pack(@rightside, @eanchor, @expand, @xfill);
}

################################
## Password Screen Subroutines
################################

sub TestDatabase {
    ## Validate the current variables.

    my($self) = shift;

    $self->configure(-cursor => 'watch');
    $self->update;

    my($rslt,$mh, $eh);

    my($usr, $pwd, $srv, $db);
    $usr = $self->{Configure}{-User};
    $pwd = $self->{Configure}{-Password};
    $srv = $self->{Configure}{'-Server'};
    $db = $self->{Configure}{'-Database'};

    $mh = &dbmsghandle(undef);
    $eh = &dberrhandle(undef);
    $rslt = eval {
	&dbmsghandle(sub {return 1});
	&dberrhandle(sub {die;});

	my($MasterDB) = Sybase::DBlib->dblogin("$usr","$pwd", "$srv");
	$MasterDB->dbuse($db);
	$MasterDB->dbclose;
	return 1;
    };

    $rslt = $1 if !defined($rslt);

    if (defined($mh)) {
	&dbmsghandle($mh);
    } else {
	&dbmsghandle(undef);
    }
    if (defined($eh)) {
	&dberrhandle($eh);
    } else {
	&dberrhandle(undef);
    }

    $self->configure(-cursor => 'top_left_arrow');
    $self->update;
    return $rslt;
}

sub TestLogin {

    my($self) = @_;

    ## Validate the current set of login variables.
    ## If there's a failure, inform the user via a dialog
    if ($self->getCurrentVerification) {
	$self->Exit(1);
    } else {
	my($db) = $self->{Configure}{'-Database'};
	my($srv) = $self->{Configure}{'-Server'};
	my($usr) = $self->{Configure}{'-User'};
	my($pwd) = $self->{Configure}{'-Password'};

	eval "\$db = \"$self->{Configure}{-EDlgText}\"";

	if ($self->Dialog(-title => $self->{Configure}{-EDlgTitle},
			  -text => $db,
			  -bitmap => 'error',
			  -default_button => $self->{Configure}{-EDlgRetry},
			  -justify => 'center',
			  -buttons => [$self->{Configure}{-EDlgRetry},
				       $self->{Configure}{-EDlgCancel}])
		->Show eq $self->{Configure}{-EDlgCancel}) {
	    $self->Exit(0);
	}
    }
}


sub Exit {
    my($self, $arg) = @_;
    ## Trigger the change to the value Verified, enabling an exit
    ## from the tkwait.
    $self->{Verified} = $arg;
    return $self->{Verified};
}

### Return 1 to the calling  use statement ###
1;
### End of file Login.pm ###


