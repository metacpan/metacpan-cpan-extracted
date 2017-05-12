package VUser::Email::Postfix;
use warnings;
use strict;

# Copyright 2005 Michael O'Connor <stew@vireo.org>
# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Postfix.pm,v 1.6 2007/01/18 21:07:42 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:files);

use VUser::Email qw(:utils);

my $log;
my %meta;

my $VERSION = '0.1.0';
my $c_sec = 'Extension Email::Postfix';

our $user_exists;

sub depends { return qw(Email); }

sub init {
    my $eh = shift;
    my %cfg = @_;

    #%meta = %VUser::Email::meta;
    
    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }
    
    $eh->register_task('email', 'add', \&email_add);
    $eh->register_task('email', 'mod', \&email_mod);
    $eh->register_task('email', 'del', \&email_del);

    $eh->register_task('domain', 'add', \&domain_add);
    $eh->register_task('domain', 'mod', \&domain_mod);
    $eh->register_task('domain', 'del', \&domain_del);
}

sub email_add {
    my ($cfg, $opts, $action, $eh) = @_;

    my $account = $opts->{account};
    my $user;
    my $domain;

    VUser::Email::split_address ($cfg, $account, \$user, \$domain);

    die "'account' must be in the form user\@domain" if (!$user or !$domain);

    if (defined $user_exists) {
	die "User $account exists\n" if &$user_exists($cfg, $opts, $account);
    }

    my $userdir = $opts->{home};
    if (not defined $userdir or not $userdir) {
	$userdir = get_home_directory ($cfg, $user, $domain);
    }
    my $user_parentdir = $userdir;
    $user_parentdir =~ s!/[^/]*$!!;

    my $vuid = (getpwnam($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrnam($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    mkdir_p ($user_parentdir,
	     0775, $vuid, $vgid,
	     ) or die "Could not create user directory: $user_parentdir\n";

    my $rc = 0xffff & system ('cp', '-R', $cfg->{$VUser::Email::c_sec}{'skeldir'}, $userdir);
    $rc <<= 8;

    die "Can't copy skel dir ".$cfg->{$VUser::Email::c_sec}{'skeldir'}." to $userdir: $!\n" if $rc != 0;

    $rc = 0xffff & system ('chown', '-R', "$vuid:$vgid", $userdir);
}

sub email_mod {
    my ($cfg, $opts, $action, $eh) = @_;

    my $account = $opts->{account};

    my $old_user;
    my $old_domain;
    VUser::Email::split_address( $cfg, $account, \$old_user, \$old_domain);

    die "account must be in form user\@domain\n" if( !$old_user or !$old_domain );

    my $new_account = $opts->{newaccount};
    if ($new_account and $new_account ne $account) {
	if (defined $user_exists) {
	    die "User $new_account exists\n" if &$user_exists($cfg, $opts, $new_account);
	}

	# User is changing the email address for the account.
	my $new_user;
	my $new_domain;
	VUser::Email::split_address( $cfg, $new_account, \$new_user, \$new_domain);
	die "newaccount must be in form user\@domain" if( !$new_user or !$new_domain );

	my $old_userdir = get_home_directory($cfg, $old_user, $old_domain);
	my $new_userdir = get_home_directory($cfg, $new_user, $new_domain);
	$log->log(LOG_DEBUG, "Old: $old_userdir");
	$log->log(LOG_DEBUG, "New: $new_userdir");
	VUser::ExtLib::mvdir($old_userdir, $new_userdir);
    }
}

sub email_del {
    my ($cfg, $opts, $action, $eh) = @_;

    my $account = $opts->{account};
    my $user;
    my $domain;

    VUser::Email::split_address( $cfg, $account, \$user, \$domain );
    
    die "account must be in form user\@domain" if( !$user or !$domain );

    if (defined $user_exists
	and not &$user_exists($cfg, $opts, $account)) {
	$log->log(LOG_NOTICE, "Deleting unknown user $account");
	die "Deleting unknown user $account";
    }

    my $userdir = get_home_directory( $cfg, $user, $domain );
    rm_r ("$userdir");
}

sub domain_mod {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{domain};
    my $new_domain = $opts->{newdomain};

    my $domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $domain);
    my $new_domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $new_domain);

    my $vuid = (getpwnam($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrnam($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    if ($new_domain and $new_domain ne $domain) {
        # rename dirs
        eval { VUser::ExtLib::mvdir($domain_dir, $new_domain_dir); };
        die "Can't rename $domain_dir to $new_domain_dir: $@\n" if $@;
    }
}

sub domain_del {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{domain};

    my $domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $domain);
    my $vuid = (getpwnam($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrnam($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    rm_r($domain_dir);
}

1;

__END__

=head1 NAME

VUser::Email::Postfix - Postfix module for vuser

=head1 DESCRIPTION

VUser::Email::Postfix provides common tasks for VUser::Email::Postfix::*
modules. These tasks are, generally, file system based such as creating the
user's home and mail dirs. Each ::Postfix::* module provides support
for the authmodule being used.

This extension is not normally used directly. Instead, use one of the
VUser::Email::Postfix::* extensions.

=head1 CONFIGURATION

There in no special configuration for Mail::Postfix.

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>
Michael O'Connor <stew@vireo.org>

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
