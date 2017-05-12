# $Date: 2007-02-07 15:54:57 -0600 (Wed, 07 Feb 2007) $
# $Revision: 19 $

package Web::Passwd;
use base 'CGI::Application';

use strict;
use warnings;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use Config::Tiny;

# set up application framework, including mode parameter and dispatch table
sub setup {
  my $self = shift;
  $self->start_mode('index');
  $self->mode_param('mode');
  $self->run_modes(
    'index' => 'display_index',
    'view' => 'display_htfile',
    'adduser' => 'user_op',
    'changepw' => 'user_op',
    'deluser' => 'user_op',
  );
  
  # return just to be tidy
  return;
}

# perform final actions after all other processing
sub teardown {
  # trigger the printing of any warnings to browser as HTML comments
  warningsToBrowser(1);
  
  # return just to be tidy
  return;
}

# display index page with no actions to be performed
sub display_index {
  my $self = shift;
  
  # load configuration as a hash ref
  $self->param('act_config', load_config( $self->param('config') ) );
  
  # load template file with HTML::Template
  my $tmpl_obj;
  if(-e $self->param('act_config')->{'_'}->{'tmpl_path'} . 'index.tmpl' ) {
    $tmpl_obj = $self->load_tmpl( $self->param('act_config')->{'_'}->{'tmpl_path'} . 'index.tmpl' );
  }
  else {
    $tmpl_obj = $self->load_tmpl( \$Web::Passwd::INDEX_TEMPLATE );
  }
  
  # get list of htpasswd config blocks
  my @htfiles;
  for my $key (keys %{$self->param('act_config')}) {
    if($key ne '_') {
      push(@htfiles, {'TITLE' => $key});
    }
  }
  
  # pass template parameters
  $tmpl_obj->param(
    'HTFILES' => \@htfiles,
    'IS_WARNINGS' => $#CGI::Carp::WARNINGS + 1,
    'FORM_METHOD' => $self->param('act_config')->{'_'}->{'form_method'},
  );
  
  # return template-generated output
  return $tmpl_obj->output;
}

# display page to view/manage a specific htpasswd file
sub display_htfile {
  my $self = shift;
  
  # get CGI query object
  my $query_obj = $self->query();
  
  # load configuration as a hash ref
  $self->param('act_config', load_config( $self->param('config') ) );
  
  # load template file with HTML::Template
  my $tmpl_obj;
  if(-e $self->param('act_config')->{'_'}->{'tmpl_path'} . 'view.tmpl' ) {
    $tmpl_obj = $self->load_tmpl( $self->param('act_config')->{'_'}->{'tmpl_path'} . 'view.tmpl' );
  }
  else {
    $tmpl_obj = $self->load_tmpl( \$Web::Passwd::VIEW_TEMPLATE );
  }
  
  # get user list and format for template processing
  my @users;
  for my $user ( htfile_listusers( $self->param('act_config')->{ $query_obj->param('htfile') }->{'path'} ) ) {
    push(@users, {'USERNAME' => $user});
  }
  
  # pass template parameters
  $tmpl_obj->param(
    'HTFILENAME' => $query_obj->param('htfile'),
    'USER_LOOP' => \@users,
    'IS_WARNINGS' => $#CGI::Carp::WARNINGS + 1,
    'FORM_METHOD' => $self->param('act_config')->{'_'}->{'form_method'},
  );
  
  # return template-generated output
  return $tmpl_obj->output;
}

# display the status of an operation
sub display_status {
  my($self, $mode, $htfile, @users) = @_;
  
  # load template file with HTML::Template
  my $tmpl_obj;
  if(-d $self->param('act_config')->{'_'}->{'tmpl_path'}.'status.tmpl' ) {
    $tmpl_obj = $self->load_tmpl( $self->param('act_config')->{'_'}->{'tmpl_path'}.'status.tmpl' );
  }
  else {
    $tmpl_obj = $self->load_tmpl( \$Web::Passwd::STATUS_TEMPLATE );
  }
  
  # build action status header
  my $act_stat = ($mode eq 'adduser')  ? "Addition Successful"
               : ($mode eq 'changepw') ? "Modification Successful"
               : ($mode eq 'deluser')  ? "Deletion Successful"
               : "Action Successful";
  
  # build action message
  my $act_msg = ($mode eq 'adduser')                 ? sprintf("User '%s' added.", $users[0])
              : ($mode eq 'changepw')                ? sprintf("Password changed for user '%s'.", $users[0])
              : ($mode eq 'deluser' && $#users == 0) ? sprintf("User '%s' deleted.", $users[0])
              : ($mode eq 'deluser' && $#users > 0)  ? sprintf("Users '%s' deleted.", join "','", @users)
              : 'Unknown operation...Check error logs.';
  
  # pass template parameters
  $tmpl_obj->param(
    'ACTION_STATUS' => $act_stat,
    'ACTION_MESSAGE' => $act_msg,
    'HTFILENAME' => $htfile,
    'IS_WARNINGS' => $#CGI::Carp::WARNINGS + 1,
    'FORM_METHOD' => $self->param('act_config')->{'_'}->{'form_method'},
  );
  
  # return template-generated output
  return $tmpl_obj->output;
}

# perform an operation
sub user_op {
  my $self = shift;
  
  # get CGI query object
  my $query_obj = $self->query();
  
  # create lexical copy of mode
  my $user_mode = lc $query_obj->param('mode');
  
  # if adding or modifying user, check that passwords match
  if($user_mode eq 'adduser' || $user_mode eq 'changepw') {
    if($query_obj->param('pass') ne $query_obj->param('pass_confirm')) {
      die 'passwords did not match';
    }
  }
  
  # load configuration as a hash ref
  $self->param('act_config', load_config( $self->param('config') ) );
  
  # add new or change existing user/pass
  my @users = $query_obj->param('user');
  if($user_mode eq 'adduser' || $user_mode eq 'changepw') {
    htfile_moduser(
      $self->param('act_config')->{'_'}->{'htpasswd_command'},
      $self->param('act_config')->{ $query_obj->param('htfile') }->{'path'},
      $users[0],
      $query_obj->param('pass'),
      $self->param('act_config')->{ $query_obj->param('htfile') }->{'algorithm'}
    );
  }
  # or delete existing user(s)
  elsif($user_mode eq 'deluser') {
    for my $user (@users) {
      htfile_deluser(
        $self->param('act_config')->{'_'}->{'htpasswd_command'},
        $self->param('act_config')->{ $query_obj->param('htfile') }->{'path'},
        $user
      );
    }
  }
  
  # generate operation status page from template
  my $tmpl_output = display_status( $self, $user_mode, $query_obj->param('htfile'), @users );
  
  # return template-generated output
  return $tmpl_output;
}

# load the app configuration, returning a hash reference
sub load_config {
  my $conf_file = shift;
  
  # if custom configuration not provided, search for a default config file
  if(!defined $conf_file) {
    # expected filename of the config
    my $CONFIG_FILENAME = 'webpasswd.conf';
    
    # search for config file in current, parent, and /etc directories
    $conf_file = (-e "./$CONFIG_FILENAME")    ? "./$CONFIG_FILENAME"
               : (-e "../$CONFIG_FILENAME")   ? "../$CONFIG_FILENAME"
               : (-e "/etc/$CONFIG_FILENAME") ? "/etc/$CONFIG_FILENAME"
               : undef;
    
    # die if config file was not found
    if(! defined $conf_file) {
      die "configuration file not found"
    }
  }
  
  # load configuration, or die on error
  my $config_obj = Config::Tiny->read($conf_file) or die Config::Tiny::errstr();
  
  # if no htpasswd command supplied, default to 'htpasswd'
  if(!exists $config_obj->{'_'}->{'htpasswd_command'}) {
    $config_obj->{'_'}->{'htpasswd_command'} = 'htpasswd';
    warn "missing 'htpasswd_command' configuration option, using default of 'htpasswd'";
  }
  
  # if template path doesnt exist, try root path
  if(!exists $config_obj->{'_'}->{'tmpl_path'}) {
    $config_obj->{'_'}->{'tmpl_path'} = '/';
  }
  
  # if template path doesnt end with a fore-slash, append one
  if(substr($config_obj->{'_'}->{'tmpl_path'}, -1) ne '/') {
    $config_obj->{'_'}->{'tmpl_path'} .= '/';
  }
  
  # if form method not provided or not GET, default to POST
  if(!exists $config_obj->{'_'}->{'form_method'} || uc($config_obj->{'_'}->{'form_method'}) ne 'GET') {
    $config_obj->{'_'}->{'form_method'} = 'POST';
  }
  
  # ensure valid attributes for each configured section
  for my $section (keys %{$config_obj}) {
    # if not root section
    if($section ne '_') {
      # if missing path, remove from active config and issue warning
      my $file_path = $config_obj->{$section}->{'path'};
      if(!defined $file_path || $file_path =~ m/\A\s*\z/ || ! -e $file_path) {
        delete $config_obj->{$section};
        warn "invalid path for config block [$section]";
        next;
      }
      
      # if missing or invalid algorithm, default to 'crypt' and issue warning
      my $pass_alg = lc $config_obj->{$section}->{'algorithm'};
      if($pass_alg !~ m/\s*(?:crypt|md5|sha|plain)\s*/i) {
        warn "invalid password algorithm '$pass_alg' for config block [$section], using 'crypt' instead";
        $pass_alg = 'crypt';
      }
      $config_obj->{$section}->{'algorithm'} = $pass_alg;
    }
  }
  
  # return config
  return $config_obj;
}

# list the users in a given htfile
sub htfile_listusers {
  my $htfile = shift;

  # declare array to hold usernames
  my @users;

  # read htfile in as text
  open(my $HTFILE, '<', $htfile) or die $!;
  my @file = <$HTFILE>;
  close($HTFILE);

  # parse off usernames, add to array
  for my $line (@file) {
    my($user) = split /:/, $line, 2;
    push @users, $user;
  }

  # return username array
  return @users;
}

# add/modify a user in a given htfile
sub htfile_moduser {
  my($htcmd,$htfile,$user,$pass,$algorithm) = @_;
  
  # translate algorithm to appropriate flag
  $algorithm = ($algorithm eq 'plain') ? 'p'
             : ($algorithm eq 'md5')   ? 'm'
             : ($algorithm eq 'sha')   ? 's'
             : ($algorithm eq 'crypt') ? 'd'
             : '';
  
  # assemble command
  my $command = sprintf "%s -b%s %s %s %s",
                $htcmd,
                $algorithm,
                $htfile,
                $user,
                $pass;
  
  # execute, or die on unsuccessful return value
  if(system($command) != 0) {
    die "htpasswd command failed: $?";
  }
  
  # return just to be tidy
  return;
}

# delete a user in a given htfile
sub htfile_deluser {
  my($htcmd,$htfile,$user) = @_;
  
  # assemble command
  my $command = sprintf "%s -D %s %s",
                $htcmd,
                $htfile,
                $user;
  
  # try to make htpasswd do the work with the -D flag (apache 2.x)
  if(system($command) == 0) {
    return 1;
  }
  # otherwise, do the damn thing by hand (apache 1.3.x)
  else {
    # read in htfile contents
    open(my $HTIN, '<', $htfile) or die $!;
    my @file = <$HTIN>;
    close($HTIN);
    
    # search for, and remove, offending user line
    my $deleted = 0;
    for my $ln (0..$#file) {
      no warnings; # bypass a puzzling warning of uninitialized value in m//
      if($file[$ln] =~ m/\A$user\:/) {
        splice @file, $ln, 1;
        $deleted++;
      }
    }
    
    # write changes back to htfile
    open(my $HTOUT, '>', $htfile) or die $!;
    print {$HTOUT} @file;
    close($HTOUT);
    
    # set error string
    $! = ($deleted) ? undef : "remove of line '$user' failed";
    
    return $deleted;
  }
}


$Web::Passwd::INDEX_TEMPLATE = <<'HTML_CODE';
<html>

<head>
<title>Web Htpasswd Management</title>
<style>
body { font-family: Arial }
table { font-family: Arial }
</style>
</head>

<body>

<center>

<h1>Web Htpasswd Management</h1>

<hr>

<p>
<form method="<TMPL_VAR NAME="FORM_METHOD" DEFAULT="POST">">
<input type="hidden" name="mode" value="view">

Select Htpasswd File:&nbsp;&nbsp;

<select name="htfile">
<TMPL_LOOP NAME="HTFILES">
  <option value="<TMPL_VAR NAME="TITLE">"><TMPL_VAR NAME="TITLE"></option>
</TMPL_LOOP>
</select>

<input type="submit" value="Manage File">

</form>
</p>

<TMPL_IF NAME="IS_WARNINGS">
<hr>
<span style="color: red">Warnings were encountered...Please check error log.</span>
</TMPL_IF>

</center>

</body>

</html>
<!--
<TMPL_VAR NAME="DEBUG_DUMP" DEFAULT="">
-->
HTML_CODE

$Web::Passwd::VIEW_TEMPLATE = <<'HTML_CODE';
<html>

<head>
<title>Web Htpasswd Management</title>
<style>
body { font-family: Arial }
table { font-family: Arial }
</style>
</head>

<body>

<center>

<h1>Managing Htpasswd File:</h1>
<h3><TMPL_VAR NAME="HTFILENAME"></h3>

<hr>

<p>
<form method="<TMPL_VAR NAME="FORM_METHOD" DEFAULT="POST">">
<input type="hidden" name="htfile" value="<TMPL_VAR NAME="HTFILENAME">">
<input type="hidden" name="mode" value="adduser">
<fieldset style="width: 400">
  <legend style="font-weight: bold">Add User</legend>
  <table width="350">
    <tr>
      <td width="150">Username:&nbsp;&nbsp;</td>
      <td width="200"><input type="text" name="user" size=255 style="width: 200"></td>
    </tr>
    <tr>
      <td>Password:&nbsp;&nbsp;</td>
      <td><input type="password" name="pass" size=255 style="width: 200"></td>
    </tr>
    <tr>
      <td>Retype Password:&nbsp;&nbsp;</td>
      <td><input type="password" name="pass_confirm" size=255 style="width: 200"></td>
    </tr>
    <tr>
      <td></td>
      <td><input type="submit" value="Add User"></td>
    </tr>
  </table>
</fieldset>
</form>
</p>

<p>
<form method="<TMPL_VAR NAME="FORM_METHOD" DEFAULT="POST">">
<input type="hidden" name="htfile" value="<TMPL_VAR NAME="HTFILENAME">">
<input type="hidden" name="mode" value="changepw">
<fieldset style="width: 400">
  <legend style="font-weight: bold">Modify User</legend>
  <table width="350">
    <tr>
      <td width="150">Username:&nbsp;&nbsp;</td>
      <td width="200">
        <select name="user" style="width: 200">
<TMPL_LOOP NAME="USER_LOOP">
          <option value="<TMPL_VAR NAME="USERNAME">"><TMPL_VAR NAME="USERNAME"></option>
</TMPL_LOOP>
        </select>
      </td>
    </tr>
    <tr>
      <td>Password:&nbsp;&nbsp;</td>
      <td><input type="password" name="pass" size=255 style="width: 200"></td>
    </tr>
    <tr>
      <td>Retype Password:&nbsp;&nbsp;</td>
      <td><input type="password" name="pass_confirm" size=255 style="width: 200"></td>
    </tr>
    <tr>
      <td></td>
      <td><input type="submit" value="Change Password"></td>
    </tr>
  </table>
</fieldset>
</form>
</p>

<p>
<form method="<TMPL_VAR NAME="FORM_METHOD" DEFAULT="POST">">
<input type="hidden" name="htfile" value="<TMPL_VAR NAME="HTFILENAME">">
<input type="hidden" name="mode" value="deluser">
<fieldset style="width: 400">
  <legend style="font-weight: bold">Delete Users</legend>
  <table width="350">
    <tr>
      <td width="150" valign="top">Usernames:&nbsp;&nbsp;</td>
      <td width="200">
        <select name="user" size="5" multiple  style="width: 200px">
<TMPL_LOOP NAME="USER_LOOP">
          <option value="<TMPL_VAR NAME="USERNAME">"><TMPL_VAR NAME="USERNAME"></option>
</TMPL_LOOP>
        </select>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><input type="submit" value="Delete User"></td>
    </tr>
  </table>
</fieldset>
</form>
</p>

<hr>
<a href="?">Back to Main</a>
<TMPL_IF NAME="IS_WARNINGS">
<hr>
<span style="color: red">Warnings were encountered...Please check error log.</span>
</TMPL_IF>

</center>

</body>

</html>
<!--
<TMPL_VAR NAME="DEBUG_DUMP" DEFAULT="">
-->
HTML_CODE

$Web::Passwd::STATUS_TEMPLATE = <<'HTML_CODE';
<html>

<head>
<title>Web Htpasswd Management</title>
<style>
body { font-family: Arial }
table { font-family: Arial }
</style>
</head>

<body>

<center>

<h1><TMPL_VAR NAME="ACTION_STATUS"></h1>

<p>
<form method="<TMPL_VAR NAME="FORM_METHOD" DEFAULT="POST">">
<TMPL_VAR NAME="ACTION_MESSAGE"><br>&nbsp;<br>
<input type="hidden" name="htfile" value="<TMPL_VAR NAME="HTFILENAME">">
<input type="hidden" name="mode" value="view">
<input type="submit" value="Go Back">
</form>
</p>

<TMPL_IF NAME="IS_WARNINGS">
<hr>
<span style="color: red">Warnings were encountered...Please check error log.</span>
</TMPL_IF>

</center>

</body>

</html>
<!--
<TMPL_VAR NAME="DEBUG_DUMP" DEFAULT="">
-->
HTML_CODE

=head1 NAME

Web::Passwd - Web-based htpasswd Management

=head1 VERSION

Version 0.03

=cut
our $VERSION = "0.03";

=head1 SYNOPSIS

Web::Passwd is a web-based utility for managing Apache C<htpasswd> files.  It uses the L<CGI::Application|CGI::Application> framework, so functionality is encapsulated in the module and very little code is required to create an instance:

    use Web::Passwd;
    
    my $webapp = Web::Passwd->new();
    $webapp->run();

That's it.  Drop that script in a web-accessible cgi directory and give it execute permissions, and (assuming a default config file is found), you're good to go.  If you'd rather explicity define a configuration file to use, you can pass it through an extra parameter:

    my $webapp = Web::Passwd->new( PARAMS => { config => '/home/evan/custom_webpasswd.conf' } );

=head1 CONFIGURATION

If not explicitly provided, a configuration file will be searched for in the following locations (in order).  If a valid configuration file is not found, the script will die with errors.

  ./webpasswd.conf    (the current directory)
  ../webpasswd.conf   (the parent directory)
  /etc/webpasswd.conf

The configuration file can be used to specify a directory of templates in the L<HTML::Template|HTML::Template> format.  If no templates are found, default templates are used (see the C</example/templates> directory of the distribution).

  tmpl_path = /var/www/cgi-bin/webpasswd/

The C<htpasswd> command can also be specified.  If no C<htpasswd> command is provided, the default is used.  Note that, on some systems, you must specify the I<absolute> path to the C<htpasswd> binary.

  htpasswd_command = htpasswd

The configuration file can specify whether to use the C<GET> (data encoded into the URL) or C<POST> (data encoded into the message body) form request method.  Defaults to using the generally more secure C<POST>.

  form_method = POST

The configuration file should also contain a section for each htpasswd file it will be used to maintain, using the following format:

  [Descriptive Name]
  path = /system/path/to/passwdfile
  algorithm = {crypt|md5|sha|plain}

B<TECHNICAL NOTE:> The default algorithm Apache uses is C<crypt> under Linux, and C<MD5> under Windows.

B<PITFALL:> Enclosing values in quotes within the config file does not have the expected effect!  It simply includes the literal quote characters in the config value.

=head1 SECURITY

It is *imperitive* that the Web::Passwd instance script itself be htpasswd protected, as it includes no access control mechanism.

Understand that putting the ability to manage htpasswd files via a web-based utility carries an inherent security risk, in that anyone who gains access to the utility is potentially given access to any of the managed htpasswd-protected resources.

Any htpasswd files to be managed with this utility MUST be owned by whatever user apache runs as.  Usually, this is 'apache' or 'nobody'.

=head1 COMPATABILITY

This was written expressly for Apache webserver 1.3 or higher running under Linux.  However, there is nothing as far as I am aware that would prevent execution on a higher version of Apache, or on Apache under Windows.

=head1 DEPENDENCIES

A Perl version of 5.6.1 or higher is recommended, and the following modules are required:

  CGI::Application
  Config::Tiny
  HTML::Template

=head1 AUTHOR

Evan Kaufman, C<< <evank at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Web::Passwd

=head1 ACKNOWLEDGEMENTS

Written for BCD Music Group.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Evan Kaufman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# we're a good little module
1;
