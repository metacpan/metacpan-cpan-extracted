package WebFS::FileCopy::Put::FTP;

# Copyright (C) 1998-2001 by Blair Zajac.  All rights reserved.  This
# package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

require 5.004_04;

use strict;
use Exporter;
use Carp qw(cluck);
use Net::FTP;

use vars qw(@ISA $VERSION);

@ISA     = qw(Exporter);
$VERSION = substr q$Revision: 1.04 $, 10;

sub new {
  my ($class, $req) = @_;

  my $ftp = WebFS::FileCopy::_open_ftp_connection($req) or return;

  # Get and fix path.
  my $uri  = $req->uri;
  my @path = $uri->path_segments;
  # There will always be an empty first component.
  shift(@path);
  # Remove the empty trailing components.
  pop(@path) while @path && $path[-1] eq '';
  my $remote_file = pop(@path);
  unless ($remote_file) {
    $@ = $req->give_response(500, "No remote file specified");
    return;
  }

  # Change directories.
  foreach my $dir (@path) {
    unless ($ftp->cwd($dir)) {
      $@ = $req->give_response(404, "Cannot chdir to `$dir'");
      return;
    }
  }

  my $data = $ftp->stor($uri->path);
  unless ($data) {
    $@ = $req->give_response(400, "FTP return code " . $ftp->code);
    $@->content_type('text/plain');
    $@->content($ftp->message);
    return;
  }

  bless {'req' => $req, 'ftp' => $ftp, 'data' => $data}, $class;  
}

sub print {
  return unless defined($_[1]);
  $_[0]->{data}->write($_[1], length($_[1]));
}

sub close {
  my $self = shift;

  my $ret = $self->{data}->close;
  $self->{ftp}->quit;
  $self->{req}->give_response($ret ? 201 : 500);
}

sub DESTROY {
  if ($WebFS::FileCopy::WARN_DESTROY) {
    my $self = shift;
    print STDERR "DESTROYing $self\n";
  }
}

1;
