package VUser::Email::Courier;
use warnings;
use strict;

# Copyright 2005 Michael O'Connor <stew@vireo.org>
# Copyright 2006 Randy Smith <perstalker@vuser.org>
# $Id: Courier.pm,v 1.2 2006/12/09 04:10:59 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:files);

my $log;
my %meta;

my $VERSION = '0.1.0';
my $c_sec = 'Extension Email::Courier';

sub depends { return qw(Email); };

sub init {
    my $eh = shift;
    my %cfg = @_;

    %meta = %VUser::Email::meta;
    
    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }

    $eh->register_task('email', 'add', \&email_add);
    $eh->register_task('email', 'mod', \&email_mod);
    $eh->register_task('email', 'del', \&email_del);
    $eh->register_task('email', 'info', \&email_info);
    $eh->register_task('email', 'list', \&email_list);

    $eh->register_task('domain', 'add', \&domain_add);
    $eh->register_task('domain', 'mod', \&domain_mod);
    $eh->register_task('domain', 'del', \&domain_del);
    $eh->register_task('domain', 'info', \&domain_info);
    $eh->register_task('domain', 'list', \&domain_list);
}

sub email_add {
    my ($cfg, $opts, $action, $eh) = @_;

    my $account = $opts->{account};
    my $user;
    my $domain;

    split_address ($cfg, $account, \$user, \$domain);

    die "'account' must be in the form user\@domain" if (!$user or !$domain);

    # die if user_exists() ?

    my $userdir = get_home_directory ($cfg, $user, $domain);
    my $user_parentdir = $userdir;
    $user_parentdir =~ s!/[^/]*$!!;

    my $vuid = (getpwname($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrname($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

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
    split_address( $cfg, $account, \$old_user, \$old_domain);

    die "account must be in form user\@domain" if( !$old_user or $old_domain );

    my $new_account = $opts->{newaccount};
    if ($new_account and $new_account ne $account) {
	# die if user_exists

	# User is changing the email address for the account.
	my $new_user;
	my $new_domain;
	split_address( $cfg, $new_account, \$new_user, \$new_domain);
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

    split_address( $cfg, $account, \$user, \$domain );
    
    die "account must be in form user\@domain" if( !$user or !$domain );

    my $userdir = get_home_directory( $cfg, $user, $domain );
    rm_r ("$userdir");
}

sub email_info {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub email_list {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub domain_add {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{domain};
    die "Domain already exists: $domain\n" if is_domain_hosted($cfg, $domain);

    my $domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $domain);
    my $vuid = (getpwname($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrname($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    mkdir_p ($domain_dir, 0775, $vuid, $vgid)
	or die "Can't create domain directory: $domain_dir\n";

    # Add to hosteddomains
    add_line_to_file($cfg->{$VUser::Email::Courier::c_sec}{etc}."/hosteddomains", $domain);
}

sub domain_mod {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{domain};
    my $new_domain = $opts->{newdomain};

    my $domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $domain);
    my $new_domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $new_domain);

    my $vuid = (getpwname($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrname($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    if ($new_domain and $new_domain ne $domain) {
        # rename dirs
        rename $domain_dir, $new_domain_dir;
        die "Can't rename $domain_dir to $new_domain_dir: $!\n" if $!;
        # replace domain in hosteddomains
        repl_line_in_file($cfg->{$VUser::Email::Courier::c_sec}{etc}."/hosteddomains", $domain, $new_domain);
    }
}

sub domain_del {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{domain};

    my $domain_dir = VUser::Email::Courier::get_domain_directory($cfg, $domain);
    my $vuid = (getpwname($cfg->{$VUser::Email::c_sec}{'virtual user'}))[2];
    my $vgid = (getgrname($cfg->{$VUser::Email::c_sec}{'virtual group'}))[2];

    rm_r($domain_dir);
    # Remove from hosteddomains
    # KNOWN BUG: domains with aliases not removed.
    del_line_from_file($cfg->{$c_sec}{etc}.'/hosteddomains', $domain);
}

sub domain_info {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub domain_list {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub is_domain_hosted
{
    my $cfg = shift;
    my $domain = shift;

    my $hosteddomainsfile = $cfg->{$c_sec}{etc} . "/hosteddomains";
    
    open( HD, "<$hosteddomainsfile" ) || die "couldnt' open $hosteddomainsfile";
    while( <HD> )
    {
	if( /^$domain$/ )
	{
	    close( HD );
	    return 1;
	}
    }
    
    close( HD );
    return 0;
}

sub unload { }

1;

__END__

=head1 NAME

Email::Courier - vuser extension to manage courier-mta accounts/domains

=head1 DESCRIPTION

VUser::Email::Courier provides common tasks for VUser::Email::Courier::*
modules. These tasks are, generally, file system based such as creating the
user's home and mail dirs. Each ::Courier::* module provides support
for the authmodule being used.

This extension is not normally used directly. Instead, use one of the
VUser::Email::Courier::* extensions.

=head1 SAMPLE CONFIGURATION

 [Extension_Email::Courier]
 etc=/usr/local/etc/courier/

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

