# WWW:Auth::DB
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth::DB;
use base 'WWW::Auth::Base';


use strict;
use WWW::Auth::Config;


sub _init {
  my $self   = shift;
  my %params = @_;

  $self->{_table}     = $params{Table}    || WWW::Auth::Config->table
    || return $self->error ('No database table specified.');
  $self->{_uid_field} = $params{UIDField} || WWW::Auth::Config->uid_field
    || return $self->error ('No UID database field specified.');
  $self->{_pwd_field} = $params{PwdField} || WWW::Auth::Config->pwd_field
    || return $self->error ('No password database field specified.');

  my $dsn      = $params{DSN}      || WWW::Auth::Config->dsn
    || return $self->error ('No DSN specified.');
  my $user     = $params{User}     || WWW::Auth::Config->user
    || return $self->error ('No database user specified.');
  my $password = $params{Password} || WWW::Auth::Config->password
    || return $self->error ('No database password specified.');

  $self->{_db}        = $params{DB}
    || WWW::Auth::Config->db (DSN	=> $dsn,
                              User	=> $user, 
                              Password	=> $password)
    || return $self->error (WWW::Auth::Config->error ());

  return 1;
}

sub auth {
  my $self = shift;
  my ($uid, $pwd, %params) = @_;

  my ($upwd) = $self->{_db}->select (Fields    => $self->{_pwd_field},
                                     Table     => $self->{_table},
                                     Where     => "$self->{_uid_field}='$uid'");
  return defined $upwd
         && $upwd eq crypt ($pwd, $upwd) ? 1 : (0, 'Username/Password incorrect');
#  return ($upwd !~ /^\s*$/ || $upwd eq crypt ($pwd, $upwd))
#    ? (0, 'Username/Password incorrect') : 1;
}


1;
