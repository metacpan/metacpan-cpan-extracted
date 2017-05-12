package VUser::Email::Postfix::SQL;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.7 2007/09/21 14:24:25 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ExtLib::SQL;
use VUser::Email qw(:utils);
use VUser::ResultSet;
use VUser::Meta;

our $VERSION = '0.1.1';

our $log;
our %meta;
our $extlib;
our $c_sec = 'Extension Email::Postfix::SQL';

sub c_sec { return $c_sec; }
sub depends { qw(Email::Postfix); }

sub init {
    my $eh = shift;
    my %cfg = @_;

    %meta = %VUser::Email::meta;
    
    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }
    
    $extlib = VUser::ExtLib::SQL->new(\%cfg,
                                      {'dsn' => $cfg{$c_sec}{'dsn'},
                                       'user' => $cfg{$c_sec}{'user'},
                                       'password' => $cfg{$c_sec}{'password'},
                                       'macros' => { 'a' => 'account',
                                                     'p' => 'password',
                                                     'd' => 'domain',
                                                     'n' => 'name',
                                                     'q' => 'quota',
                                                     'h' => 'home',
                                                     'd' => 'domain'
                                       }
                                      }
                                     ); 
    
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

sub user_exists {
    my $cfg = shift;
    my $opts = shift;
    my $account = shift;

    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{account}, \$user, \$domain);
    my $params = { 'u' => $user, 'd', $domain };

    my $sql = strip_ws($cfg->{$c_sec}{userinfo_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get user info: $@");
        die "Unable to get user info: $@";
    }

    my $found;
    my @results;
    if (@results = $sth->fetchrow_array()) {
	$found = 1;
	$log->log(LOG_DEBUG, "User $account exists");
    } else {
	$found = 0;
	$log->log(LOG_DEBUG, "User $account does not exist");
    }

    $sth->finish;
    return $found;
}

sub email_add {
    my ($cfg, $opts, $action, $eh) = @_;

    my $account = $opts->{account};
    if ($cfg->{$VUser::Email::c_sec}{"lc user"}) {
	$account = lc($account);
    }
    
    my ($user, $domain);
    VUser::Email::split_address($cfg, $account, \$user, \$domain);

    if (user_exists($cfg, $opts, $account)) {
	return;
    }

    if (not defined $opts->{home} or not $opts->{home}) {
	$opts->{"home"} = get_home_directory($cfg, $user, $domain);
    }

    if (not defined $opts->{quota}) {
	$opts->{quota} = strip_ws($cfg->{$VUser::Email::c_sec}{'default quota'});
    }
    
    my $sql = strip_ws($cfg->{$c_sec}{'useradd_query'});
    my $sth = $extlib->execute($opts, $sql, {'u' => $user, 'd' => $domain});
    return undef;
}

sub email_mod {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my @sql = ();
    
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{account}, \$user, \$domain);
    
    my $params = { 'u' => $user, 'd' => $domain }; 
    
    if ($opts->{home} and $cfg->{$c_sec}{usermod_home_query}) {
        push @sql, strip_ws($cfg->{$c_sec}{usermod_home_query});
    }
    
    if ($opts->{password} and $cfg->{$c_sec}{usermod_password_query}) {
        push @sql, strip_ws($cfg->{$c_sec}{usermod_password_query})
    }
    
    if ($opts->{name} and $cfg->{$c_sec}{usermod_name_query}) {
        push @sql, strip_ws($cfg->{$c_sec}{usermod_name_query});
    }
    
    if (defined $opts->{quota} and $cfg->{$c_sec}{usermod_quota_query}) {
        push @sql, strip_ws($cfg->{$c_sec}{usermod_quota_query});
    }
       
    if ($opts->{newaccount} and $cfg->{$c_sec}{usermod_account_query}) {
       # change the home dir to match the username unless --home was passed
        if (not $opts->{home} and $cfg->{$c_sec}{usermod_quota_query}) {
	    my ($new_user, $new_domain);
	    VUser::Email::split_address ($cfg, $opts->{newaccount},
					 \$new_user, \$new_domain);
            $opts->{home} = VUser::Email::get_home_directory($cfg,
							     $new_user,
							     $new_domain);
            push @sql, strip_ws($cfg->{$c_sec}{usermod_home_query});
        }

        # Update the user name
        push @sql, strip_ws($cfg->{$c_sec}{usermod_account_query});
    }
    
    #$extlib->begin();
    foreach my $sql (@sql) {
        eval { $extlib->execute($opts, $sql, $params); };
        if ($@) {
            $log->log(LOG_ERROR, "Update error, rolling back changes.");
            $log->log(LOG_DEBUG, "Update error: $@");
            $extlib->rollback();
        }
    }
    #$extlib->commit();
}

sub email_del {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{account}, \$user, \$domain);
    
    my $params = { 'u' => $user, 'd' => $domain };
    
    my $sql = strip_ws($cfg->{$c_sec}{userdel_query});
    eval { $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to delete user: $@");
        die "Unable to delete user: $@";
    }
}

sub email_info {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{account}, \$user, \$domain);
    my $params = { 'u' => $user, 'd', $domain };
    
    my $sql = strip_ws($cfg->{$c_sec}{userinfo_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get user info: $@");
        die "Unable to get user info: $@";
    }
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'account'});
    $rs->add_meta($meta{'password'});
    $rs->add_meta($meta{'name'});
    $rs->add_meta($meta{'home'});
    $rs->add_meta($meta{'quota'});
    
    my @results;
    while (@results = $sth->fetchrow_array) {
        $rs->add_data( [@results[0 .. 4]] );
    }
    $sth->finish;
    return $rs;
}

sub email_list {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{account}, \$user, \$domain);
    my $params = { 'u' => $user, 'd', $domain };
    
    my $sql = strip_ws($cfg->{$c_sec}{userlist_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get user info: $@");
        die "Unable to get user info: $@";
    }
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'account'});
    $rs->add_meta($meta{'password'});
    $rs->add_meta($meta{'name'});
    $rs->add_meta($meta{'home'});
    $rs->add_meta($meta{'quota'});
    
    my @results;
    while (@results = $sth->fetchrow_array) {
        $rs->add_data( [@results[0 .. 4]] );
    }
    $sth->finish;
    return $rs;
}

sub domain_add {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $params = { 'd', $opts->{domain} };
    
    my $sql = strip_ws($cfg->{$c_sec}{domainadd_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to add domain: $@");
        die "Unable to add domain info: $@";
    }
}

sub domain_mod {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $params = { 'd' => $opts->{domain} }; 
    
    my @sql = ();
    if ($opts->{newdomain} and $cfg->{$c_sec}{domainmod_domain_query}) {
        push @sql, strip_ws($cfg->{$c_sec}{domainmod_domain_query});
    }
    
    $extlib->begin();
    foreach my $sql (@sql) {
        eval { $extlib->execute($opts, $sql, $params); };
        if ($@) {
            $log->log(LOG_ERROR, "Update error, rolling back changes.");
            $log->log(LOG_DEBUG, "Update error: $@");
            $extlib->rollback();
        }
    }
    $extlib->commit();
}

sub domain_del {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $params = { 'd', $opts->{domain} };
    
    my $sql = strip_ws($cfg->{$c_sec}{domainadel_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to delete domain: $@");
        die "Unable to delete domain info: $@";
    }
}

sub domain_list {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $params = { 'd', $opts->{domain} };
    
    my $sql = strip_ws($cfg->{$c_sec}{domainlist_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get the domain list: $@");
        die "Unable to get the domain list: $@";
    }
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'domain'});
    
    my @result;
    while (@result = $sth->fetchrow_array) {
        $rs->add_data([$result[0]]);
    }
    
    return $rs;
}

sub domain_info {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $params = { 'd', $opts->{domain} };
    
    my $sql = strip_ws($cfg->{$c_sec}{domaininfo_query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get domain info: $@");
        die "Unable to get domain info: $@";
    }
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'domain'});
    
    my @result;
    while (@result = $sth->fetchrow_array) {
        $rs->add_data([$result[0]]);
    }
    
    return $rs;
}

1;

__END__

=head1 NAME

VUser::Email::Postfix::SQL - vuser extension for managing postfix users and domain in SQL

=head1 DESCRIPTION

=head1 SAMPLE CONFIGURATION

 [Extension Email::Postfix::SQL]
 dsn = dbi:mysql:database=email
 user = email
 password = secret

 # The various *_query settings here need to be defined to tell vuser how to
 # add, delete, etc accounts in the database. Any option passed on the commandline
 # can be inserted into the query with %-option_name.
 # Several macros are defined by VUser::Email::Postfix::SQL to make things easier.
 #  %a = account name (user@domain)
 #  %p = password
 #  %n = name
 #  %q = quota
 #  %h = home
 #  %d = domain (option, i.e. --domain)
 # These options are calculated from other options, hence the '$' in the macro
 #  %$u = user part of the account (user)
 #  %$d = domain part of the account (domain)
 
 # Add a user
 useradd_query = insert into Emails set username=%a, password=%p
 
 # Delete a user
 userdel_query = delete from Email where username=%a
 
 # Modify the user
 # The usermod_*_query's are used to change various portions of the users'
 # account information.
 usermod_account_query  = update Email set username=%-newaccount where username = %a
 usermod_password_query = update Email set password=%p where username = %a
 usermod_name_query     = update Email set name=%n where username = %a
 usermod_quota_query    = update Email set quota = %q where username = %a
 usermod_home_query     = update Email set home = %h where username = %a
 
 # Get user information. This query must return the following values in order
 #  account, password, name, home directory, quota
 userinfo_query = select ... from Email where username = %a
 userlist_query = select ... from Email
 
 # The domain*_query allow %d and %$d to be the same.
 # Add a domain 
 domainadd_query = insert into Domains set domain = %d, transport = 'virtual:' 
 
 # Delete a domain
 domaindel_query = delete from Domain where domain = %d
 
 # Modify a domain
 domainmod_domain_query = update Domain set domain = %-newdomain where domain = %d
 
 # Get domain info. The query must return the following fields in order
 #  domain
 domaininfo_query = select domain from Domain where domain = %d
 
 # Get domain list. The query must return the following fields in order
 #  domain
 domainlist_query = select domain from Domain

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of VUser-Email-Postfix-SQL.
 
 VUser-Email-Postfix-SQL is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Email-Postfix-SQL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Email-Postfix-SQL; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

