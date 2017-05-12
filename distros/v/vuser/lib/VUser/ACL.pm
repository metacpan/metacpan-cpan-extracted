package VUser::ACL;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ACL.pm,v 1.9 2006-01-04 21:57:48 perlstalker Exp $

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ALLOW DENY UNKNOWN);
our %EXPORT_TAGS = (consts => [qw(ALLOW DENY UNKNOWN)]);

our $REVISION = (split (' ', '$Revision: 1.9 $'))[1];
our $VERSION = "0.3.0";

our $ALLOW = 1;
our $DENY = 0;
our $UNKNOWN = -1;

my $c_sec = 'ACL'; #conf section

my $acl = undef;

sub revision
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return $REVISION;
}

sub version
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return ${$type."::VERSION"};
}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    if (VUser::ExtLib::check_bool($cfg{$c_sec}{'use internal auth'})) {
	if (not VUser::ExtLib::strip_ws($cfg{$c_sec}{'auth modules'})) {
	    die "Internal auth specified but no auth modules defined.";
	}
	$eh->register_keyword('auth', 'Manage vuser users');

	# auth-add
	$eh->register_action('auth', 'add', 'Add a new user');
	$eh->register_option('auth', 'add', 'user', '=s', 1, 'User name');
	$eh->register_option('auth', 'add', 'password', '=s', 1, 'Password');
	$eh->register_option('auth', 'add', 'ip', '=s', 0, 'Restrict to this IP');
	$eh->register_task('auth', 'add', \&auth_add, 1);

	# auth-show
	$eh->register_action('auth', 'show', 'Show users');
	$eh->register_option('auth', 'show', 'user', '=s', 0, 'User to get');
	$eh->register_option('auth', 'show', 'module', '=s', 0, 'Check in this module only.');
	$eh->register_task('auth', 'show', \&auth_show);

	# auth-del
	$eh->register_action('auth', 'del', 'Delete user');
	$eh->register_option('auth', 'del', 'user', '=s', 1, 'User to get');
	$eh->register_option('auth', 'del', 'module', '=s', 0, 'Check in this module only.');
	$eh->register_task('auth', 'del', \&auth_del);

    }

    $eh->register_keyword('acl', 'Manage vuser ACLs');

    # acl-add
    $eh->register_action('acl', 'add', 'Add new ACL');
    $eh->register_option('acl', 'add', 'module', '=s', 0, 'Module to add to. Add to ALL modules if not specified.');
    $eh->register_option('acl', 'add', 'user', '=s', 1, 'User for ACL');
    $eh->register_option('acl', 'add', 'keyword', '=s', 1, 'Keyword');
    $eh->register_option('acl', 'add', 'action', '=s', 0);
    $eh->register_option('acl', 'add', 'option', '=s', 0);

    $eh->register_option('acl', 'add', 'operation', '=s', 0);
    $eh->register_option('acl', 'add', 'value', '=s', 0);
    $eh->register_option('acl', 'add', 'permissions', '=s', 1, 'ALLOW or DENY');
    $eh->register_task('acl', 'add', \&acl_add, 1);

    $acl = new VUser::ACL (\%cfg);
}

sub unload { return; }

sub new
{
    my $class = shift;
    my $cfg = shift;

    return $acl if defined $acl;

    my $self = { auth => [],
		 acl => []
		 };
    bless $self, $class;

    # load Auth modules
    eval { $self->load_auth_modules($cfg); };
    die $@ if $@;

    # load ACL modules
    eval { $self->load_acl_modules($cfg); };
    die $@ if $@;

    # After we've loaded the requested modules, we'll set the default
    # to allow or deny. (deny is the default)
    my $acl_default = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'acl default'});
    $acl_default = 'DENY' unless $acl_default;

    if (uc($acl_default) eq 'ALLOW') {
	$self->register_acl($cfg, \&ALLOW, -1);
    } else {
	$self->register_acl($cfg, \&DENY, -1);
    }
    $acl = $self;

    return $acl;
}

sub ALLOW { return $ALLOW; };
sub DENY { return $DENY; }
sub UNKNOWN { return $UNKNOWN; }

sub register_acl
{
    my $self = shift;
    my $cfg = shift;
    my $acl_sub = shift;
    my $priority = shift || 10;

    my $pri = $priority;
    if ($priority < 0) {
	$pri = scalar @{$self->{acl}};
    }

    if (not defined $self->{acl}[$pri]) {
	$self->{acl}[$pri] = [];
    }

    push @{ $self->{acl}[$pri] }, $acl_sub;
}

sub register_auth
{
    my $self = shift;
    my $auth_sub = shift;
    my $priority = shift || 10;

    if (not defined $self->{auth}[$priority]) {
	$self->{auth}[$priority] = [];
    }

    push @{$self->{auth}[$priority]}, $auth_sub;
}

sub load_auth_modules
{
    my $self = shift;
    my $cfg = shift;

    # whitespace delimited
    my $mods = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'auth modules'});
    $mods = '' unless $mods;

    foreach my $mod (split / /, $mods) {
	print STDERR "Loading authmod $mod\n" if $main::DEBUG >= 1;
	eval { $self->load_auth_module( "VUser::Auth::$mod", $cfg); };
	warn "Unable to load auth module ($mod): $@\n" if $@;
    }
}

sub load_auth_module
{
    my $self = shift;
    my $mod = shift;
    my $cfg = shift;

    eval ( "require $mod" );
    die $@ if $@;

    no strict 'refs';
    &{ $mod.'::init'}($self, $cfg);
}

sub load_acl_modules
{
    my $self = shift;
    my $cfg = shift;

    # whitespace delimited
    my $mods = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'acl modules'});
    $mods = '' unless $mods;

    foreach my $mod (split / /, $mods) {
	print STDERR "Loading acl mod $mod\n" if $main::DEBUG >= 1;
	eval { $self->load_auth_module( "VUser::ACL::$mod", $cfg); };
	warn "Unable to load ACL module: $@\n";
    }
}

# load_acl_module and load_auth_module are currently identical but that
# may change at some point.
sub load_acl_module { load_auth_module(@_); }

sub auth_user
{
    my $self = shift;
    my $cfg = shift;
    my $user = shift;
    my $pass = shift;
    my $ip = shift;

    my $result = DENY();

    PRI: foreach my $pri (@{ $self->{auth}}) {
	next unless defined $pri;
	foreach my $mod (@{ $pri }) {
	    $result = &$mod($cfg, $user, $pass, $ip);
	    last PRI if ($result eq ALLOW() or $result eq DENY());
	}
    }

    if ($result eq ALLOW()) {
	return 1;
    } else {
	return 0;
    }
}

sub check_acls
{
    my $self = shift;
    my $cfg = shift;
    my $user = shift;
    my $ip = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;
    my $value = shift;

    my $result = DENY();

  PRI: foreach my $pri (@{ $self->{acl}}) {
      next unless defined $pri;
      foreach my $mod (@{ $pri }) {
	  $result = &$mod($cfg, $user, $ip, $keyword, $action, $option, $value);
	  last PRI if ($result eq ALLOW() or $result eq DENY());
      }
  }
    if ($result eq ALLOW()) {
	return 1;
    } else {
	return 0;
    }
}

sub plugin_tasks
{
    my ($cfg, $opts, $action, $eh, $sect, $func) = @_;

    my @mods = ();
    if ($opts->{module}) {
	@mods = ($opts->{module});
    } else {
	my $mods;
	if ($sect eq 'acl') {
	    $mods = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'acl modules'});
	} elsif ($sect eq 'auth') {
	    $mods = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'auth modules'});
	}
	$mods = '' unless $mods;
	@mods = split / /, $mods;
    }

    foreach my $mod (@mods) {
	# is this what I want to call the sub in the modules?
	no strict 'refs';
	&{"VUser::"
	      .($sect eq 'acl'? 'ACL' : 'Auth')
	      ."::".$mod."::".$func}($cfg, $opts, $action, $eh);
    }
}

sub auth_add { plugin_tasks(@_, 'auth', 'auth_add') };
sub auth_del { plugin_tasks(@_, 'auth', 'auth_del') };

sub auth_show
{
    my ($cfg, $opts, $action, $eh) = @_;

#    use Data::Dumper; print Dumper $cfg, $opts, $action, $eh;

    my $mods;

    if ($opts->{module}) {
	$mods = $opts->{module};
    } else {
	$mods = VUser::ExtLib::strip_ws($cfg->{$c_sec}{'auth modules'});
    }

    my @users = ();
    foreach my $mod (split / /, $mods) {
	no strict 'refs';
	push @users, &{ "VUser::Auth::".$mod."::auth_get" }($cfg, $opts, $action, $eh);
    }

    foreach my $user (@users) {
	print join (':', map { defined $_? $_ : '' } ($user->{user},
						      $user->{password},
						      $user->{ip}));
	print "\n";
    }
}

sub acl_add { plugin_tasks(@_, 'acl', 'acl_add'); }

1;

__END__

=head1 NAME

VUser::ACL - vuser access control lists

=head1 DESCRIPTION

=head1 METHODS

=head2 revision

Returns the extension's revision. This is may return an empty string;

=head2 version

Returns the extensions official version. This man not return an empty string.

=head1 DESIGN DISCUSSION

NB: The following discussion was used as a design guide and will probably
match up with the implementation but it may not. When it doubt, consult the
API docs and/or the code. -- PerlStalker

We need to provide two features: authentication and access control.
Storage for each should support backends such as SQLite, MySQL, etc.

=head2 Authentication

Probably the most varied module. I can imagine many installs that will want
to use vuser specific user stores in a local DB and others that will auth
against, e.g. POP3 or IMAP. The auth system must be flexible to support these
plus any others that a local admin may want to add. This is similar to
to the current extension framework and a similar API should probably be used.

If we're going to match the Extension system, then we need a register*()
function or two.

=over 4

=item register_auth (\&sub)

I<\&sub> is a reference to a sub that takes the following params:

=over 8

=item $cfg

A reference to the Config::IniFile hash. This is the same as what's passed
to tasks by ExtHandler.

=item $user

The username of the account trying to connect.

=item $password

The password of the user trying to connect.

=item $ip_address

The IP address of the user trying to connect. I<sub()> may use the IP
address to restrict access but is not required to. B<Note:> Further access
control by IP address is provided by the access control system described
below.

=back

I<sub()> returns one of three possible values:

=over 8

=item ALLOW

The user is authenticated. Processing stops.

=item DENY

The user is denied. Processing stops. Because there may be many more
modules handling authentication, auth modules are encouraged to return
UNKNOWN if the user does not exist, but should return DENY if the user
exists but the passwords don't match.

=item UNKNOWN

I<sub()> was unable to determine if the user should be allowed or not.
Processing continues. If no I<sub()> returns an ALLOW or DENY response,
the user is denied.

=back

=item auth_add

=item auth_get

Plugins must return an array of hash refs with keys: user, password, ip.

=back

=head2 Access Control

Just because a user authenticates doesn't mean that he needs access to
everything that vuser might let him do. This is more vuser specific than
the auth module discussed above. Here about the only thing we need to worry
about is different storage backends. However, since we don't know all the
possible backends that could be used, we'll use a registration system
here, too.

=over 4

=item register_acl (\&sub)

I<\&sub> is a reference to a sub that takes the following params:

=over 8

=item $cfg

A reference to the Config::IniFile hash. This is the same as what's passed
to tasks by ExtHandler.

=item $user

The user that wants to do something.

=item $ip_address

The IP address of the user.

=item $keyword

The keyword

=item $action

The action the user is trying to run. If action is '_meta', then the option
(below) is treated as a meta data name.

=item $option

An option to the keyword/action pair.

=item $value

The value of the option above. Having the value allows us to allow a user
to see/change/delete/whatever certain values but not others. This may be
a pattern or regex.

For example, one might allow an email user to be able to use vuser to change
their password or the password of some number of sub accounts. Specifically,
postmaster@example.com could be allowed to change passwords for
sally@example.com, joe@example or any address in the example.com domain
but sally@example.com could only change her own password.

=back

Any or all of the above parameters may be used to restrict (or grant) access.
I<sub()> must return one of the following values:

=over 8

=item ALLOW

Allow the user to do the action with the actions.

=item DENY

User is not allowed to do the action.

=item UNKNOWN

The ACL module was not able to determine if the user is allowed or not.
If no module returns an ALLOW or DENY, then access is denied or allowed
based on a setting in the config file.

=back

=item acl_add

This is run as a regular task.

A note about the I<user> option: user is the actual user name of the user
or '#name' for a group. The group '#GLOBAL' is reserved. I<#GLOBAL> allows
an admin to set permissions for all users.

=back

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
