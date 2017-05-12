# WWW:Auth::FTP
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth::FTP;
use base 'WWW::Auth::Base';


use strict;
use WWW::Auth::Config;
use Net::FTP;


sub _init {
  my $self   = shift;
  my %params = @_;

  $self->{_ftphost}   = $params{FTPHost}  || WWW::Auth::Config->ftphost
    || return $self->error ('No FTP host specified.');

  return 1;
}

sub auth {
  my $self = shift;
  my ($uid, $pwd, %params) = @_;

  my $ftp = Net::FTP->new ($self->{_ftphost});
  my $success = $ftp->login ($uid, $pwd);
  $ftp->quit;

  return ($success, 'Username/Password incorrect');
}


1;
