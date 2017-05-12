# WWW:Auth::Config
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth::Config;
use base 'WWW::Auth::Base';


use strict;
use vars qw($AUTOLOAD
            $AUTH $DB
            $LOGIN_PARAM $LOGOUT_PARAM $UID_PARAM $PWD_PARAM
            $SERVERKEY_SRC
            $TEMPLATE $LOGIN_TEMPLATE $LOGOUT_TEMPLATE $SECURE_TEMPLATE
            $DSN $USER $PASSWORD $TABLE $UID_FIELD $PWD_FIELD);

use constant SUB	=> 0;
use constant VAR	=> 1;


$AUTH		= [SUB, 'WWW::Auth::DB'];

# CGI configuration
$LOGIN_PARAM    = [VAR, 'Login'];
$LOGOUT_PARAM   = [VAR, 'Logout'];
$UID_PARAM      = [VAR, 'username'];
$PWD_PARAM      = [VAR, 'pwd'];

$SERVERKEY_SRC	= [VAR, 'file://usr/local/etc/server.key'];

# Template configuration
$TEMPLATE	= [SUB, 'WWW::Auth::Template'];
$LOGIN_TEMPLATE	= [VAR, 'login.tmpl'];
$LOGOUT_TEMPLATE= [VAR, 'logout.tmpl'];
$SECURE_TEMPLATE= [VAR, 'secure.tmpl'];

# Database configuration
$DB		= [SUB, 'DBI::Wrap'];
$DSN		= [VAR, 'DBI:mysql:database=greendel2'];
$USER		= [VAR, 'greendel'];
$PASSWORD	= [VAR, 'j0kerz'];
$TABLE		= [VAR, 'users'];
$UID_FIELD	= [VAR, 'username'];
$PWD_FIELD	= [VAR, 'pwd'];


sub load {
  my $self = shift;
  my $module = shift;

  $module =~ s[::][/]g;
  $module .= '.pm';
  eval {require $module};
  return $@ ? $self->error ($@) : 1;
}

sub AUTOLOAD {
  my $self   = shift;
  my %params = @_;

  if ($AUTOLOAD !~ /DESTROY$/) {
    my $varname = uc ($AUTOLOAD);
    $varname =~ s/.*:://;

no strict 'refs';
    my $var = $$varname;
use strict;
    if (! defined $var) {
      $self->error ("No configuration variable for $varname.\n");
    } else {
      if ($var->[0] == SUB) {
        if ($self->load ($var->[1])) {
          my $package = $var->[1];
          return $package->new (%params)
                   || $self->error ("Error loading module: " . $package->error);
        }
      } else {
       return $var->[1];
      }
    }

    return undef;
  }
}


1;
