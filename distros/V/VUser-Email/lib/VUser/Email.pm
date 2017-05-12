package VUser::Email;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Email.pm,v 1.6 2007/01/18 20:30:25 perlstalker Exp $

use VUser::Meta;
use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);

our $VERSION = '0.3.2';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(split_address get_domain_directory get_home_directory);
our %EXPORT_TAGS = (utils => [qw(split_address
				 get_domain_directory
				 get_home_directory)]);

our $c_sec = 'Extension Email';
our %meta = ('account' => VUser::Meta->new('name' => 'account',
					   'type' => 'string',
					   'description' => 'Email account'),
	     'password' => VUser::Meta->new('name' => 'password',
					    'type' => 'string',
					    'description' => 'Account password'),
	     'name' => VUser::Meta->new('name' => 'name',
					'type' => 'string',
					'description' => 'Real name'),
	     'quota' => VUser::Meta->new('name' => 'quota',
					 'type' => 'integer',
					 'description' => 'Mailbox quota in KB'),
	     'domain' => VUser::Meta->new('name' => 'domain',
					  'type' => 'string',
					  'description' => 'Domain name'),
		 'home' => VUser::Meta->new('name' => 'home',
		                            'type' => 'string',
		                            'description' => 'Home directory (overrides config setting)'),
	     'pattern' => VUser::Meta->new('name' => 'pattern',
					   'type' => 'string',
					   'description', 'Limit to pattern')
	     );
			     
my $log;

sub init {
    my $eh = shift;
    my %cfg = @_;

    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser');
    }

    # email
    $eh->register_keyword('email', 'Manage email accounts');

    # email-add
    $eh->register_action('email', 'add', 'Add an email account');
    $eh->register_option('email', 'add', $meta{'account'}, 1);
    $eh->register_option('email', 'add', $meta{'password'}, 1);
    $eh->register_option('email', 'add', $meta{'name'});
    $eh->register_option('email', 'add', $meta{'quota'});
    $eh->register_option('email', 'add', $meta{'home'});

    # email-mod
    $eh->register_action('email', 'mod', 'Modify an email account');
    $eh->register_option('email', 'mod', $meta{'account'}, 1);
    $eh->register_option('email', 'mod', $meta{'account'}->new('name' => 'newaccount'));
    $eh->register_option('email', 'mod', $meta{'password'});
    $eh->register_option('email', 'mod', $meta{'name'});
    $eh->register_option('email', 'mod', $meta{'quota'});
    $eh->register_option('email', 'mod', $meta{'home'});

    # email-del
    $eh->register_action('email', 'del', 'Delete an email account');
    $eh->register_option('email', 'del', $meta{'account'}, 1);

    # email-info
    $eh->register_action('email', 'info', 'Get email account info');
    $eh->register_option('email', 'info', $meta{'account'}, 1);

    # email-list
    $eh->register_action('email', 'list', 'List email accounts');
    $eh->register_option('email', 'list', $meta{'pattern'});

    # domain
    $eh->register_keyword('domain');

    # domain-add
    $eh->register_action('domain', 'add', 'Add a domain');
    $eh->register_option('domain', 'add', $meta{'domain'}, 1);

    # domain-mod
    $eh->register_action('domain', 'mod', 'Modify a domain');
    $eh->register_option('domain', 'mod', $meta{'domain'}, 1);
    $eh->register_option('domain', 'mod', $meta{'domain'}->new(name => 'newdomain'));

    # domain-del
    $eh->register_action('domain', 'del', 'Delete a domain');
    $eh->register_option('domain', 'del', $meta{'domain'}, 1);

    # domain-info
    $eh->register_action('domain', 'info', 'Get domain info');
    $eh->register_option('domain', 'info', $meta{'domain'}, 1);

    # domain-list
    $eh->register_action('domain', 'list', 'List domains');
    $eh->register_option('domain', 'list', $meta{'pattern'});

};

sub meta { return %meta; };
sub c_sec { return $c_sec; }

sub get_home_directory
{
    my $cfg = shift;
    my $user = shift;
    my $domain = shift;

    return eval( $cfg->{$c_sec}{userhomedir} );
}

sub get_domain_directory
{
    my $cfg = shift;
    my $domain = shift;
    return eval( $cfg->{$c_sec}{domaindir} );
}

sub get_quotafile
{
    my $cfg = shift;
    my $user = shift;
    my $domain = shift;

    return get_home_directory( $cfg, $user, $domain )."/Maildir/maildirsize";
}

sub split_address
{
    my $cfg = shift;
    my $account = shift;
    my $username = shift;
    my $domain = shift;

    if ($account =~ /^(\S+)\@(\S+)$/) {
	$$username = $1;
	$$domain = $2;
    } else {
	$$username = $account;
 	$$domain = $cfg->{$c_sec}{defaultdomain};
	$$domain =~ s/^\s*(\S+)\s*/$1/;
    }

    $$username = lc($$username) if check_bool($cfg->{$c_sec}{'lc_user'});
    $$domain = lc($$domain);
    
    $log->log(LOG_DEBUG, "account: $account, user: $$username, domain: $$domain");
}

sub unload { }

1;

__END__

=head1 NAME

Email - vuser email support extention

=head1 DESCRIPTION

VUser::Email is an extention to vuser that allows on to manage email
accounts. VUser::Email is not meant to be used by itself but, instead,
registers the basic keywords, actions and options that other VUser::Email::*
extensions will use. Other options may be added by server specific
extensions.

=head1 SAMPLE CONFIGURATION

 [Extension Email]
 # The location of the files which are copies into a brand new home dir
 skeldir=/usr/local/etc/courier/skel
 
 # Set to 1 to force user names to lower case
 lc_user = 0
 
 # the domain to use if the account doesn't have one
 default domain=example.com
 
 # Given $user and $domain, where will the user's home directory be located?
 # This may be a valid perl expression.
 
 # PerlStalker's scheme:
 #domaindir="/var/mail/virtual/$domain"
 #userhomedir="/var/mail/virtual/$domain/".substr($user, 0, 2)."/$user"
 
 # stew's scheme:
 domaindir="/home/virtual/$domain"
 userhomedir="/home/virtual/$domain/var/mail/$user"

 # Maildir directory name
 maildir=Maildir

 # User and group name of owner of the vittual user's directories
 virtual user=vmail
 virtual group=vmail
 
 # Default quota in bytes
 default quota=20000000

=head1 AUTHORS

Randy Smith <perlstalker@vuser.org>

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

