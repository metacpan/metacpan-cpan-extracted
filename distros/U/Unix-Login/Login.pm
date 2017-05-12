
# $Id: Login.pm,v 1.8 2003/08/29 22:42:59 nwiger Exp $
####################################################################
#
# Copyright (c) 2000-2003 Nathan Wiger <nate@wiger.org>
#
# This is designed to simulate a command-line login on UNIX machines.
# In an array context it returns the std getpwnam array or undef,
# and in a scalar context it returns just the username or undef if
# the login fails.
#
####################################################################

# Basic module setup
package Unix::Login;

use strict;
use vars qw(@ISA @EXPORT $VERSION %CONF);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(login);

# Straight from CPAN
$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Errors
use Carp;

# On interrupt, reset term and exit failure
sub sttyexit () { system 'stty echo'; exit 1 }
$SIG{INT}  = \&sttyexit;
$SIG{TERM} = \&sttyexit;
$SIG{QUIT} = \&sttyexit;

# Configuration - these are all the default values
%CONF = (

    # Max login attempts
    attempts       => 3,
   
    # What todo on failure
    failmesg       => "Login incorrect\n",
    failsleep      => 3,
    failexit       => 1,

    # Misc default strings
    banner         => "Please Login\n",
    bannerfile     => '',
    login          => "login: ",
    password       => "Password: ",

    # Take the username from the process?
    sameuser       => 0,

    # Do we allow them to login with no password??
    passreq        => 1,

    # If can't find homedir
    nohomemesg     => "No home directory! Setting HOME=/\n",

    # Where to take input from
    input          => \*STDIN,
    output         => \*STDOUT,

    # Set ENV variables?
    setenv         => 1,
    clearenv       => 0,
    path           => '/usr/bin:',
    supath         => '/usr/sbin:/usr/bin',
    maildir        => '/var/mail',

    # Use TomC's User::pwent module?
    pwent          => 0,
   
    # Exec the person's shell?
    cdhome         => 0,
    execshell      => 0

);

#------------------------------------------------
# "Constructor" function to handle defaults
#------------------------------------------------

#######
# Usage: $ul = Unix::Login->new(banner => "Welcome to Bob's");
#
# This constructs a new Unix::Login object (optional, silly)
#######

sub new {
    # Easy mostly-std new()
    my $self = shift;
    my $class = ref($self) || $self;

    # override presets with remaining stuff in @_
    my %conf = (%CONF, @_);
    return bless \%conf, $class;
}

#------------------------------------------------
# Private Functions
#------------------------------------------------

#######
# Usage: my($self, @args) = _self_or_default(@_);
#
# Modified object checker from CGI.pm, no object for speed
#######

sub _self_or_default {
    local $^W = 0;
    return @_ if ref $_[0] eq 'Unix::Login';
    unshift @_, \%CONF;     # just need hash anyways
    return @_;
}

#------------------------------------------------
# Public functions - all are exportable
#------------------------------------------------

#######
# Usage: $ul->login or login();
#
# This is designed to simulate a command-line long on UNIX machines.
# In an array context it returns the std getpwnam array or undef,
# and in a scalar contact it returns just the username or undef if
# the login fails.
#
# The args are optional; if no args are given, then the default
# banner is the basename of the script (`basename $0`), the
# default login prompt is "login: ", the default password string
# is "Password: ", and the default fail string is "Login incorrect".
#######

sub login {

    my($self, @attr) = _self_or_default(@_);
    my %conf = (%{$self}, @attr);

    my($logintry, $passwdtry, @pwstruct);

    # Read our input/output
    *INPUT  = $conf{input};
    *OUTPUT = $conf{output};

    # Print out banner once
    print OUTPUT "\n", $conf{banner}, "\n" if $conf{banner};

    # Read our banner file; we print this each iteration
    my $banner = '';
    if ($conf{bannerfile}) {
        if (open(BFILE, "<" . $conf{bannerfile})) {
            $banner = join '', <BFILE>; 
            close BFILE;
        }
    }

    # While loop
    my $success = 0;
    for (my $i=0; $i < $conf{attempts}; $i++) {

        print OUTPUT $banner;          # /etc/issue

        if ($conf{sameuser}) {
            $logintry = getpwuid($<)
                || croak "Unidentifiable user running process";
        } else {
            do {
                print OUTPUT $conf{login};
                $logintry = <INPUT>;
                unless ($logintry) {       # catch ^D
                    sttyexit if $conf{failexit};
                    return;
                }
                $logintry =~ s/\s+//g;     # catch "   "
            } while (! $logintry);
        }

        # Look it up by name - explicitly say "CORE::"
        # since we may be using User::pwent...
        @pwstruct = CORE::getpwnam($logintry);

        # Lose the echo during password entry
        system 'stty -echo';
        print OUTPUT $conf{password};
        chomp($passwdtry = <INPUT>);
        print OUTPUT "\n";
        system 'stty echo';

        # Require a passwd from the passwd file?
        if ($pwstruct[0] && ! $pwstruct[1] && $conf{passreq}) {
            sttyexit if $conf{failexit};
            return;
        }
   
        # Check to make sure we have both a valid username and passwd
        if ($pwstruct[0] && crypt($passwdtry, $pwstruct[1]) eq $pwstruct[1]) {
            $success++;
            last;
        }

        # Fake a UNIX login prompt wait
        sleep $conf{failsleep};
        print OUTPUT $conf{failmesg};
    } 

    unless ($success) {
        sttyexit if $conf{failexit};
        return;
    }
   
    # Do a few basic things
    if ($conf{setenv}) {
        undef %ENV if $conf{clearenv};	# clean slate
        $ENV{LOGNAME} = $pwstruct[0];
        $ENV{PATH}    = ($pwstruct[2] == 0) ? $conf{supath} : $conf{path};
        $ENV{HOME}    = $pwstruct[7];
        $ENV{SHELL}   = $pwstruct[8];
        $ENV{MAIL}    = $conf{maildir} . '/' . $pwstruct[0];
    }

    # Fork a shell if, for some strange reason, we are asked to.
    # We use the little-known indirect object form of exec()
    # to set $0 to -sh so we get a login shell.
    if ($conf{execshell}) {
        if ($> == 0) {
            $< = $> = $pwstruct[2];
            $( = $) = $pwstruct[3];
        } else {
            carp "Warning: Cannot setuid/setgid unless running as root";
        }
        (my $shell = $pwstruct[8]) =~ s!^.*/!!;	# basename
        exec { $pwstruct[8] } "-$shell";
    }

    if ($conf{cdhome}) {
        # Like real login, try to chdir to homedir
        unless (-d $pwstruct[7] && chdir $pwstruct[7]) {
            print OUTPUT $conf{nohomemesg};
            $ENV{HOME} = '/';
        }
    }

    # Return appropriate info
    if (wantarray) {
        return @pwstruct;
    } elsif ($conf{pwent}) {
        require User::pwent;
        return User::pwent::getpwnam($pwstruct[0]);
    } else {
        return $pwstruct[0];
    }
}

1;

#
# Documentation starts down here
#
__END__

=head1 NAME

Unix::Login - Customizable Unix login prompt and validation

=head1 SYNOPSIS

    use Unix::Login;
  
    # This will return the same thing as getpwnam() on
    # success, or will die automatically on failure
    my @pw = login;

=head1 DESCRIPTION

This is a simple yet flexible module that provides a Unix-esque login
prompt w/ password validation. This is useful in custom applications
that need to validate the username/password of the person using the app.

The above example is pretty much all you'll ever need (and all this
module provides). Here are some specifics on the function provided:

=head2 login(option => value, option => value)

This prompts for the username and password and tries to validate
the login. On success, it returns the same thing that getpwuid()
does: the username in a scalar context, or the passwd struct as
an array in a list context. It returns undef on failure. 

You can pass it an optional set of parameters. These will specify
options for that login prompt only. The parameters and their default
values are:

    attempts      Max login attempts [3]
    failmesg      Print this on failure ["Login incorrect\n"]
    failsleep     And sleep for this many seconds [3]
    failexit      If can't login after (3) attempts, exit fatally [1]

    banner        Banner printed once up top ["Please Login\n"]
    bannerfile    File to print after banner (i.e. /etc/issue) []
    login         Prompt asking for username ["login: "]
    password      Prompt asking for password ["Password: "]

    sameuser      Take username from process? [0]
    passreq       Require a password for all users? [1]
    nohomemesg    Printed if no homedir ["No home directory! Setting HOME=/\n"]
    stripspaces   Strip spaces from username? [1]

    setenv        If true, setup HOME and other %ENV variables [1]
    clearenv      If true, first undef %ENV before setenv [0]
    path          If setenv, set PATH to this for non-root [/usr/bin:]
    supath        If setenv, set PATH to this for root [/usr/sbin:/usr/bin]
    maildir       If setenv, set MAIL to this dir/username [/var/mail]

    input         Where to read input from filehandle [STDIN]
    output        Where to write output to filehandle [STDOUT]

    pwent         Return a User::pwent struct in scalar context? [0]
    cdhome        Chdir to the person's homedir on success? [0]
    execshell     Execute the person's shell as login session? [0]

So, for example, you can create a fully-customized login screen like so:

    use Unix::Login;

    my @pwent = login(login => "User: ", password => "Pass: ")
       || die "Sorry, try remembering your password next time.\n";

Often, you just want the user to re-enter their password, though. In
this case, specify the C<sameuser> option:

    use Unix::Login;
    my @pwent = login(sameuser => 1);

Since C<login()> will return true or die on exit, you can even just use
it as a standalone line if you're just verifying their identity (and
don't need the pw struct back). You may also want to turn off the banner
for a better display:

    login(sameuser => 1, banner => 0);

If the C<pwent> option is set, then C<User::pwent> is used to provide
an object in a scalar context:

    use Unix::Login;
    my $pwent = login(pwent => 1);

See the man page for User::pwent for more details.

If the C<execshell> option is set, then if login() is successful the
user's shell is forked and the current process is terminated,
just like a real Unix login session.

Thus, with these options, you could create a very Unix-like login:

    use Unix::Login;

    my @pwent = login(bannerfile => '/etc/issue',
                      banner     => `uname -rs`,
                      clearenv   => 1,
                      cdhome     => 1,
                      execshell  => 1);

This will validate our login, clear our environment and reset
it, then exec the shell as a login shell just like a real life
Unix login.

=head2 new(option => value, option => value)

If you really like OO-calling styles, this module also provides an
OO form, although I personally think it's rather silly.

The C<new()> function creates a new Unix::Login object. It accepts the
same parameters as listed above. Then, you call C<login()> as a member
function. So for example:

    use Unix::Login;

    my $ul = Unix::Login->new(setenv => 0, passreq => 0);

    my @pw = $ul->login;

Personally, I always just use C<login()> as a function...

=head1 NOTES

This module automatically grabs control of the signals C<INT>, C<TERM>,
and C<QUIT>, just like C<DBI.pm>, to make sure that a C<^C> causes the
module to fail insted of accidentally succeed.

To use the C<input> and C<output> options, you must first open the
filehandle yourself, and then pass in a glob ref to the filehandle.
For example:

    # ... stuff to listen to SOCKET ...
    login(input => \*SOCKET, output => \*SOCKET);

These options are seldom used, so if this doesn't make any sense to you,
don't sweat it.

=head1 ACKNOWLEDGEMENTS

Thanks to David Redmond to modernizing the C<crypt()> stuff so that
it's RedHat-friendly.

=head1 VERSION

$Id: Login.pm,v 1.8 2003/08/29 22:42:59 nwiger Exp $

=head1 SEE ALSO

User::pwent(3), login(1), perlfunc(1)

=head1 AUTHOR

Copyright (c) 2000-2003 Nathan Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
