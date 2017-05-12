#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
#
# Description: The kernel of ePortal.
#
# ------------------------------------------------------------------------


=head1 NAME

ePortal::Server - The core module of ePortal project.

=head1 SYNOPSIS

ePortal is a set of perl packages and HTML::Mason components to easy
implement intranet WEB site for a company. ePortal is writen with a help of
Apache, mod_perl, HTML::Mason. The current version of ePortal uses MySQL as
database backend.

The ePortal project is open source software.

=head1 DOCUMENTATION

Look at L<http://eportal.sourceforge.net/eng_index.html> for complete 
documentation (Russian and English) and screen shots.

=head1 METHODS

=cut

package ePortal::Server;
	require 5.6.1;
    our $VERSION = '4.5';

    use ePortal::Global;
    use ePortal::Utils;

    # Localization and cyrillization.
    use POSIX qw(locale_h);
    use locale;

    # System modules
    use strict;
    use DBI;
    use Storable qw/freeze thaw/;
    use Mail::Sendmail ();
    use File::Basename ();
    use Data::Dumper;           # Sometimes I use it (print config)
    use Digest::MD5;
    use List::Util qw//;
    use URI;
    use Text::Wrap qw //;

    # Exception handling and parameters validating modules
    use Error qw/:try/;
    use ePortal::Exception;
    use Params::Validate qw/:types/;

    # ePortal's packages
    use ePortal::Auth::LDAP;
    use ePortal::Attachment;
    use ePortal::Catalog;
    use ePortal::CtlgCategory;
    use ePortal::CtlgItem;
    use ePortal::CronJob;
    use ePortal::epGroup;
    use ePortal::epUser;
    use ePortal::Exception;
    use ePortal::PageView;
    use ePortal::PopupEvent;

    # ThePersistent packages
    use ePortal::ThePersistent::Dual;
    use ePortal::ThePersistent::Session;
    use ePortal::ThePersistent::ExtendedACL;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::Utils;
    use ePortal::ThePersistent::Tools qw/table_exists/; # table exists


    # Some usefull read only internal variables
    use ePortal::MethodMaker( read_only => [qw/ user config_file/]);

    # Main configuration parameters
    my @MAIN_CONFIG_PARAMETERS = (qw/ 
            dbi_source dbi_host dbi_database 
            dbi_username dbi_password 
            admin_mode /);
    eval 'use ePortal::MethodMaker( read_only => [@MAIN_CONFIG_PARAMETERS] );';

    my @GENERAL_CONFIG_PARAMETERS = (qw/
            admin debug log_filename log_charset disk_charset
            vhost comp_root applications storage_version
            days_keep_sessions language refresh_interval date_field_style
            smtp_server www_server mail_domain
            ldap_server ldap_base ldap_binddn ldap_bindpw ldap_charset
            ldap_uid_attr ldap_fullname_attr ldap_title_attr
            ldap_ou_attr ldap_group_attr ldap_groupdesc_attr
            /);
    eval 'use ePortal::MethodMaker( read_only => [@GENERAL_CONFIG_PARAMETERS] );';

    
    our $RUNNING_UNDER_APACHE = $ENV{MOD_PERL};    # True if the module loaded under Apache HTTP server
    our $MAX_GROUP_NAME_LENGTH = 60;               # maximum length of LDAP DN for group name
    our $STORAGE_VERSION = 450;                    # Increment this on change comp_root/admin/ePortal_database.htm
                                                   # ePortal version 4.4 has db store version 16
                                                   # from v4.5 db store numbers as 450
    # --------------------------------------------------------------------
    # ePortal package for global variables
    {
      package ePortal;
      our $VERSION = '4.5';
      our $DEBUG = 0;                              # See Params::Validate
      $DEBUG = 1 if $ENV{PERL_NO_VALIDATION} or $ENV{EPORTAL_DEBUG};
    }

############################################################################
# Function: new
# Description: ePortal object Constructor
# Parameters:
#   vhost name, config hash
# or
#   vhost name, config filename
# Returns:
#   ePortal blessed object
#
############################################################################
sub new {   #12/26/00 3:34
############################################################################
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p = Params::Validate::validate( @_, {
        dbi_host      => {type => SCALAR|UNDEF, optional => 1},
        dbi_username  => {type => SCALAR|UNDEF, optional => 1},
        dbi_password  => {type => SCALAR|UNDEF, optional => 1},
        dbi_database  => {type => SCALAR|UNDEF, optional => 1},
        m             => {type => OBJECT, isa => 'HTML::Mason::Request', optional => 1},
        
        # too early. database connection is available after ePortal->Initialize
        #username      => {type => SCALAR|UNDEF, optional => 1},
      });

    my $self = {
        dbi_source    => undef,         # available only under Apache for backward compatibility
        dbi_host      => $p{dbi_host},
        dbi_database  => $p{dbi_database},
        dbi_username  => $p{dbi_username},
        dbi_password  => $p{dbi_password},
        username      => 'internal',    # default user name. Admin privilegies
        admin_mode    => 0,
        };
    bless $self, $class;

    # This is global variable imported from ePortal::Global;
    $ePortal = $self;

    # Discover main parameters needed for database connection
    if ( $p{m} ) {
      $self->{dbi_source}   ||= $p{m}->apache_req->dir_config('ePortal_dbi_source');
      $self->{dbi_host}     ||= $p{m}->apache_req->dir_config('ePortal_dbi_host');
      $self->{dbi_database} ||= $p{m}->apache_req->dir_config('ePortal_dbi_database');
      $self->{dbi_username} ||= $p{m}->apache_req->dir_config('ePortal_dbi_username');
      $self->{dbi_password} ||= $p{m}->apache_req->dir_config('ePortal_dbi_password');
      $self->{admin_mode}   ||= $p{m}->apache_req->dir_config('ePortal_admin_mode');
    }  
    $self->{dbi_source}   ||= $ENV{EPORTAL_DBI_SOURCE};
    $self->{dbi_host}     ||= $ENV{EPORTAL_DBI_HOST};
    $self->{dbi_database} ||= $ENV{EPORTAL_DBI_DATABASE};
    $self->{dbi_username} ||= $ENV{EPORTAL_DBI_USERNAME};
    $self->{dbi_password} ||= $ENV{EPORTAL_DBI_PASSWORD};
    $self->{admin_mode}   ||= $ENV{EPORTAL_ADMIN_MODE};

    return $self;
}##new

############################################################################
# Function: initialize
# Description: new() is a general class initializer
#   initialize() does all initialization with accordance with configs
# Parameters:
#   skip_applications=1  do not create application objects
# Returns:
#
############################################################################
sub initialize  {   #03/21/03 3:51
############################################################################
    my ($self, %p) = @_;

    $self->dbh;
    throw ePortal::Exception::DatabaseNotConfigured
        if ! table_exists($self->dbh, 'UserConfig');

    $self->config_load;
    throw ePortal::Exception::DatabaseNotConfigured
        if $self->storage_version != $STORAGE_VERSION;

    # Precreate some objects
    $self->{user} = new ePortal::epUser;
}##initialize

############################################################################
sub config_load {   #03/17/03 3:38
############################################################################
    my $self = shift;

    # Try load config hash
    my $c = $self->Config('config');
    if ( ref($c) eq 'HASH' ) {
        foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
            $self->{$par} = $c->{$par};
        }

    } else {    # Old style 'row per parameter' config
        foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
            $self->{$par} = $self->Config($par);
        }
    }

    # Initialize some of the parameters to empty values
    $self->{admin} = [] if ref($self->{admin}) ne 'ARRAY';
    $self->{applications} = {} if ref($self->{applications}) ne 'HASH';
}##config_load


############################################################################
sub config_save {   #03/17/03 3:38
############################################################################
    my $self = shift;

    my $c = {};

    # Load configuration parameters
    foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
        $c->{$par} = $self->{$par};
    }
    $self->Config('config', $c);
}##config_save


=head2 Application()

 $app = $ePortal->Application('appname');

Returns ePortal::Application object or undef if no such object exists.

Returns $ePortal itself for application called 'ePortal'.

throws Exception::ApplicationNotInstalled if the application is
not installed.

=cut


############################################################################
sub Application {   #04/26/02 12:47
############################################################################
    my $self = shift;
    my $app_name = shift;
    my %p = @_;

    return $self if $app_name eq 'ePortal';
    return $self->{_application_object}{$app_name} if exists $self->{_application_object}{$app_name};

    eval "use ePortal::App::$app_name;";
    if ( $@ ) {
        logline ('emerg', "Cannot load Application module [$app_name]: $@");
        throw ePortal::Exception::ApplicationNotInstalled(-app => $app_name); 
    } 

    my $app = "ePortal::App::$app_name"->new();
    logline('info', "Created Application object $app_name");

    $self->{_application_object}{$app_name} = $app;

    return $app;
}##Application






=head2 ApplicationsInstalled()

Returns array of installed application names based on modules found in
ePortal::App directory

=cut

############################################################################
sub ApplicationsInstalled   {   #03/17/03 11:14
############################################################################
    my $self = shift;

    my $ePortal_pm = $INC{'ePortal/Server.pm'};
    throw ePortal::Exception::Fatal(-text => "Looking for 'ePortal/Server.pm' in \%INC hash but not found!")
        if ! $ePortal_pm;
    my ($name, $path) = File::Basename::fileparse($ePortal_pm, '\.pm');

    my @ApplicationsInstalled;
    throw ePortal::Exception::Fatal(-text => "Cannot open dir $path for reading")
        if ! opendir(DIR, "$path/App");
    while(my $file = readdir(DIR)) {
        next if $file =~ /dummy\.pm/oi;
        if ($file =~ /^(.+)\.pm$/oi) {
            push @ApplicationsInstalled, $1;
        }
    }
    closedir DIR;

    logline('debug', "Found installed applications: ". join(',', @ApplicationsInstalled));
    return @ApplicationsInstalled;
}##ApplicationsInstalled


############################################################################
sub ApplicationName {   #05/15/02 9:02
############################################################################
    'ePortal';
}##ApplicationName


############################################################################
sub username    {   #06/19/2003 4:46
############################################################################
    my $self = shift;

    if (@_ and !$self->admin_mode) {
        my $newusername = shift;
        $self->{user}->clear;

        if ($newusername) {
          throw ePortal::Exception::BadUser(-reason => 'bad_user')
            if ! $self->{user}->restore($newusername);

          throw ePortal::Exception::BadUser(-reason => 'bad_user')
              if ($self->{user}->Username ne $newusername) and 
                 ($self->{user}->DN ne $newusername);

          $self->{username} = $self->{user}->Username;

        } else {
          $self->{username} = undef;
        }
    }

    return $self->{username};
}##username




=head2 CheckUserAccount($username,$password)

Complete checks for a user account. If it is external user then local copy
is created. If local copy is expired, then it is refreshed.

This function is used during login phase.

Parameters:

=over 4

=item * username

User name to check. It is from login dialog box

=item * password

A password from login dialog box to verify

=back

Returns: C<(username,reason)> in array context and C<username> in scalar
context.

In case of bad login the C<username> is undefined and C<reason> is
the code of denial.

In case of successful login C<username> returned

=cut

############################################################################
sub CheckUserAccount    {   #06/21/01 2:00
############################################################################
  my $self = shift;
  my %p = Params::Validate::validate( @_, {
      username => { type => UNDEF | SCALAR},
      password => { type => UNDEF | SCALAR},
      });

  my $U = new ePortal::epUser;

  throw ePortal::Exception::BadUser(-reason => 'bad_user')
    if $p{username} eq '';

  my $user_exists = 0;
  if ($U->restore($p{username})) {
    $user_exists = 1 
      if $U->Username eq $p{username} or 
         $U->DN eq $p{username};
  }  

  # Check local user
  if ($user_exists and $U->ext_user == 0) {
    throw ePortal::Exception::BadUser(-reason => 'disabled')
      if ! $U->Enabled;
    
    throw ePortal::Exception::BadUser(-reason => 'bad_password')
      if ($p{password} eq '') or 
         ($U->Password ne $p{password});

  # Check LDAP external module
  } elsif ($self->ldap_server) {
    try {
      my $auth_ldap = new ePortal::Auth::LDAP( $p{username} );

      throw ePortal::Exception::BadUser(-reason => 'bad_user')
        if ! $auth_ldap->check_account;

      throw ePortal::Exception::BadUser(-reason => 'bad_password')
        if ! $auth_ldap->check_password( $p{password} );

      # Refresh user info from LDAP
      $U->last_checked('now');
      $U->UserName(   $p{username} );
      $U->DN(         $auth_ldap->dn);
      $U->FullName(   $auth_ldap->full_name );
      $U->Title(      $auth_ldap->title );
      $U->Department( $auth_ldap->department );
      $U->ext_user( 1 );
      $U->Enabled( 1 );

      my $res = $user_exists ? $U->update : $U->insert;
      throw ePortal::Exception::BadUser(-reason => 'system_error')
        if ! $res;

      # Refresh group membership
      my $G = new ePortal::epGroup;
      foreach my $g ($auth_ldap->membership) {
        if ($G->restore($g)) {
          $U->add_groups($g);
        }    
      }    

    } catch ePortal::Exception::Fatal with {
      my $E = shift;
      logline('error', "LDAP error: $E");
      throw ePortal::Exception::BadUser(-reason => 'system_error')
    };  
  
  # Nothing more to check
  } else {
    throw ePortal::Exception::BadUser(-reason => 'bad_user');
  }
      

  $self->dbh->do("UPDATE epUser SET last_login=now() WHERE id=?", undef, $U->id);
  logline('notice', "CheckUserAccount: User $p{username} checked successfully");
}##CheckUserAccount




=head2 cleanup_request()

Cleans all internal variables and caches after request is completed.

=cut

############################################################################
sub cleanup_request {   #12/26/00 3:18
############################################################################
  my $self = shift;

  # Clear ThePersistent cache
  ePortal::ThePersistent::Cached::ClearCache();

  # disconnect from database
  if ( ref($self->{dbh_cache}) ) {
    $self->{dbh_cache}->disconnect;
  }
  delete $self->{dbh_cache};
  delete $self->{user};

  # destroy Application object cache
  delete $self->{_application_object};
}##cleanup_request

############################################################################
# Function: ShortUserName
# Parameters: None
# Returns: Фамилия И.О. или Гость
#
############################################################################
sub ShortUserName   {   #12/27/00 9:49
############################################################################
    my $self = shift;

    my $name = $self->user->FullName;
    if ($name) {
        $name =~ s/^(\S+)\s+(\S)\S*\s+(\S)\S*/$1 $2. $3./;
        return $name;
    } elsif ($self->username) {
        return $self->username;
    } else {
        return "Гость";
    }
}##ShortUserName

=head2 isAdmin()

Check current for for admin privilegies.

If the server run under command line then the user always is admin.

Returns [1|0]

=cut

############################################################################
sub isAdmin {   #10/27/00 1:42
############################################################################
    my $self = shift;

    return $self->{_isadmin}
        if defined $self->{_isadmin};   # cache results.

    return 1 if $self->admin_mode;      # Admin mode on

    my $u = $self->username;            # anonymous cannot be admin
    return undef unless $u;

    return 1 if $u eq 'internal';       # Special internal account
                                        # Command line utilities

    # iterate list of usernames in admin list
    $self->{_isadmin} = 1
        if List::Util::first {$u eq $_} @{ $self->admin };

    return $self->{_isadmin};
}##isAdmin


=head2 UserConfig()

Retrieve/store configuration parameter for a user. Anonymous users share
the same parameters. Use $session hash for session specific parameters.

 UserConfig(parameter, value)

Optional C<value> may be hashref of arrayref

Returns current or new value of the parameter.

=cut

############################################################################
sub UserConfig  {   #01/09/01 1:27
############################################################################
    my $self = shift;

    return $self->_Config($self->username, @_);
}##UserConfig


=head2 Config()

The same as C<UserConfig> but stores server specific parameters.

=cut

############################################################################
sub Config  {   #03/24/01 10:28
############################################################################
    my $self = shift;
    return $self->_Config('!ePortal!', @_);
}##Config

############################################################################
# Function: _Config
# Description: Вспомогательная функция. Сохранение конфигурационных значений.
# Parameters: username, key, [newvalue]
# Returns: old value or undef if not found
#
############################################################################
sub _Config {   #03/24/01 10:28
############################################################################
    my $self = shift;
    my $username = shift || '!!nouser!!';
    my $keyname = shift;
    my $value;

    # restore existing value from database
    my $dbh = $self->dbh;
    my ($dummy_keyname, $dummy_value) =
        $dbh->selectrow_array("SELECT userkey,val FROM UserConfig WHERE username=? and userkey=?",
            undef, $username, $keyname);
    if ($dummy_value =~ /^_REF_/) {
        $dummy_value = thaw(substr($dummy_value, 5));
    }

    # store new value into database
    if (scalar @_) {    # Need to save new value
        my $freezed = $dummy_value = shift @_;
        $freezed = '_REF_' . freeze($dummy_value)
            if (ref $dummy_value);

        if ($dummy_value eq '') {   # clear value
            $dbh->do("DELETE FROM UserConfig WHERE username=? and userkey=?",
                undef, $username, $keyname);
            
        } elsif ($dummy_keyname) {   # the key exists
            $dbh->do("UPDATE UserConfig SET val=? WHERE username=? and userkey=?",
                undef, $freezed, $username, $keyname);

        } else {    # the key not exists
            $dbh->do("INSERT into UserConfig(username,userkey,val) VALUES(?,?,?)",
                undef, $username, $keyname, $freezed);
        }
    }

    return $dummy_value;
}##_Config




=head2 dbh()

In general C<dbh()> is used to get ePortal's database handle.

This function returns C<$dbh> - database handle or throws
L<ePortal::Exception::DBI|ePortal::Exception>.

=cut
  
  my $ErrorHandler = sub {
      local $Error::Debug = 1;
      local $Error::Depth = $Error::Depth + 1;
      throw ePortal::Exception::DBI(-text => $_[0], -object => $_[1]);
      1;
  };

############################################################################
sub dbh   {   #02/19/01 11:15
############################################################################
    my $self = shift;

    # Cache connection
    if ( defined $self->{dbh_cache} ) {
        return $self->{dbh_cache} if $self->{dbh_cache}->ping;
    }

    # Do connect. connect returns undef on error
    my $DBH;
    eval {
      my $dbi_source = undef;
      if ( $self->dbi_host or $self->dbi_database) {
        $dbi_source = 'dbi:mysql:';
        $dbi_source .= sprintf('host=%s;', $self->dbi_host) if $self->dbi_host;
        $dbi_source .= sprintf('database=%s;', $self->dbi_database) if $self->dbi_database;
      } else {
        $dbi_source = $self->dbi_source;
      }  

      $DBH = DBI->connect( $dbi_source, $self->dbi_username, $self->dbi_password,
                                  { ShowErrorStatement => 1, 
                                    RaiseError => 0, 
                                    PrintError => 1, 
                                    AutoCommit => 1
                                   });
    };
    throw ePortal::Exception::DBI(-text => $DBI::errstr || $@)
        if (! $DBH ) or $@;

    #$self->{dbh_cache}->{HandleError} = $ErrorHandler;
    $DBH->{HandleError} = $ErrorHandler;
    $self->{dbh_cache} = $DBH;
    return $DBH;
}##dbh


############################################################################
sub r   {   #02/21/02 1:48
############################################################################
    return $HTML::Mason::Commands::r;
}##r

############################################################################
sub m   {   #02/21/02 1:49
############################################################################
    return $HTML::Mason::Commands::m;
    # HTML::Mason::Request->instance
}##m




=head2 send_email($receipient,$subject,$text)

Send an e-mail on behalf of ePortal server. send_email() make all character
set conversions needed for e-mail.

=cut

############################################################################
sub send_email  {   #01/12/02 12:28
############################################################################
    my $self = shift;
    my $receipient = shift;
    my $subject = shift;
    my $text = join("\n", @_);

    my $boundary = '=ePortal-boundary';
    Mail::Sendmail::sendmail(
        smtp => $self->smtp_server,
        From => '"ePortal server" <eportal@' . $self->mail_domain. '>',
        To => $receipient,
        Subject => $subject,
        Message => "This is MIME letter\n\n\n".
                    "--$boundary\n".
                    "Content-Type: text/html; charset=windows-1251\n".
                    "Content-Transfer-Encoding: 8bit\n\n".
                    "<HTML><body>\n$text\n</body></html>\n\n".
                    "--$boundary--\n",
        'X-Mailer' => "ePortal v$ePortal::Server::VERSION",
        #'Content-type' => 'text/html; charset="windows-1251"',
        'Content-type' => join("\n",
                    'multipart/related;',
                    '  boundary="' . $boundary . '";',
                    '  type=text/html'),
        );
}##send_email


=head2 onDeleteUser()

This is callback function. Do not call it directly. It calls once
onDeleteUser(username) for every application installed.

Parameters:

=over 4

=item * username

User name to delete.

=back

=cut

############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;

    foreach my $app_name ($self->ApplicationsInstalled) {
        try {
        $self->Application($app_name)->onDeleteUser($username);
        };
    }
}##onDeleteUser


=head2 onDeleteGroup()

This is callback function. Do not call it directly. It calls once
onDeleteGroup(groupname) for every application installed.

Parameters:

=over 4

=item * groupname

Group name to delete.

=back

=cut

############################################################################
sub onDeleteGroup    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $groupname = shift;

    foreach ($self->ApplicationsInstalled) {
        try {
        my $app = $self->Application($_);
        $app->onDeleteGroup($groupname);
        };
    }
}##onDeleteGroup


=head2 max_allowed_packet()

Maximum allowed packet size for database. By default MySQL server has
limit to 1M packet size but this limit may be changed.

=cut

############################################################################
sub max_allowed_packet  {   #11/27/02 2:51
############################################################################
    my $self = shift;
    my $sth = $self->dbh->prepare("show variables like 'max_allowed_packet'");
    $sth->execute;
    my $result = ($sth->fetchrow_array())[1];
    $sth->finish;
    if ( $result < 1024*1024 ) {
        logline('emerg', 'Cannot get max_allowed_packet variable');
        $result = 1024 * 1024;
    }
    return $result;
}##max_allowed_packet

1;

__END__



=head1 LOGIN PROCESS

User authorization and authentication is ticket based. The ticked is
created during login process and saved in user's cookie. The ticked is
validated on every request.

=head2 External users

ePortal may authenticate an user in external directory like LDAP.
Currently only Novell Netware LDAP server is tested.





=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
