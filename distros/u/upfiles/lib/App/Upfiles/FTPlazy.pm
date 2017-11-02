# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2017 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.

package App::Upfiles::FTPlazy;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Upfiles');

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 12;

# Have croaks from Net::FTP reported against the caller (App::Upfiles)
# rather than here.
our @CARP_NOT = ('Net::FTP');

sub new {
  my $class = shift;
  return bless { verbose => 0,
                 want_dir => '/',
                 have_site_utime => 'unknown',
                 message => '',
                 code => 0,
                 @_ }, $class;
}

sub message {
  my ($self) = @_;
  return (defined $self->{'ftp'} ? $self->{'ftp'}->message : $self->{'message'});
}
sub ok {
  my $self = shift;
  my $code = $self->code;
  return $code >= 0 && $code < 400;
}
sub code {
  my ($self) = @_;
  return (defined $self->{'ftp'} ? $self->{'ftp'}->code : $self->{'code'});
}

sub host {
  my ($self, $host) = @_;
  if (@_ < 2) { return $self->{'want_host'}; }

  $self->{'want_host'} = $host;
  return 1;
}
sub ensure_host {
  my ($self) = @_;
  if (! defined $self->{'want_host'}) {
    $self->{'message'} = 'No host() machine given';
    return 0;
  }
  if (defined $self->{'got_host'}
      && $self->{'got_host'} eq $self->{'want_host'}) {
    return 1;
  }

  # Net::FTP without SSL support quietly ignores SSL=>1, don't let that happen
  require Net::FTP;
  if ($self->{'use_SSL'} && ! Net::FTP->can('can_ssl')) {
    croak "ftps use SSL but Net::FTP (version ",Net::FTP->VERSION,
      ") does not have can_ssl()";
  }

  if ($self->{'verbose'} >= 2) { print "OPEN $self->{'want_host'}\n"; }

  ### use_SSL: $self->{'use_SSL'}
  ### use_TLS: $self->{'use_TLS'}
  if ($self->{'use_SSL'}) {
    require IO::Socket::SSL;
    if (! $IO::Socket::SSL::DEBUG) {
      $IO::Socket::SSL::DEBUG = $self->{'verbose'};
    }
  }

  ### open Net FTP ...
  require Net::FTP;
  my $ftp = Net::FTP->new ($self->{'want_host'},
                           Debug => ($self->{'verbose'} >= 2),
                           SSL   => $self->{'use_SSL'},
                          );
  if (! $ftp) {
    $self->{'message'} = $@;
    $self->{'code'} = 500;
    return 0;
  }

  if ($self->{'verbose'}) {
    # IO::Socket::IP method
    my ($host, $port) = $ftp->peerhost_service;
    print "Connected $host $port\n";
  }

  if ($self->{'use_TLS'}) {
    if ($self->{'verbose'}) { print __("TLS\n"); }
    $ftp->starttls;
  }

  undef $self->{'got_username'};
  $self->{'ftp'} = $ftp;
  $self->{'got_host'} = $self->{'want_host'};
  return 1;
}

sub login {
  my ($self, $username) = @_;
  $self->{'want_username'} = $username;
  return 1;
}
sub ensure_login {
  my ($self) = @_;
  if (! defined $self->{'want_username'}) {
    $self->{'message'} = 'No login() username given';
    $self->{'code'} = 500;
    return 0;
  }
  if (defined $self->{'got_username'}
      && $self->{'got_username'} eq $self->{'want_username'}) {
    return 1;
  }
  if ($self->{'verbose'} >= 2) { print "LOGIN $self->{'want_username'}\n"; }
  $self->{'ftp'}->login ($self->{'want_username'})
    or return 0;
  undef $self->{'got_binary'};
  undef $self->{'got_cwd'};
  $self->{'got_username'} = $self->{'want_username'};
  return 1;
}

sub binary {
  my ($self) = @_;
  $self->{'want_binary'} = 1;
  return 1;
}
sub ensure_binary {
  my ($self) = @_;
  if (! defined $self->{'want_binary'}) {
    return 1;
  }
  if (defined $self->{'got_binary'}
      && $self->{'got_binary'} eq $self->{'want_binary'}) {
    return 1;
  }
  my $method = ($self->{'want_binary'} ? 'binary' : 'ascii');
  if ($self->{'verbose'} >= 2) { print "\U$method\E\n"; }
  $self->{'ftp'}->$method
    or return 0;
  $self->{'got_binary'} = $self->{'want_binary'};
  return 1;
}

sub cwd {
  my ($self, $dir) = @_;

  # default root dir same as Net::FTP
  if (! defined $dir) { $dir = '/'; }

  # relative to current want_dir
  require File::Spec::Unix;
  $dir = File::Spec::Unix->rel2abs ($dir, $self->{'want_dir'});
  $dir = _collapse_dotdot_parent ($dir);

  $self->{'want_dir'} = $dir;
  return 1;
}
sub ensure_cwd {
  my ($self) = @_;
  if (defined $self->{'got_dir'}
      && $self->{'got_dir'} eq $self->{'want_dir'}) {
    return 1;
  }
  if ($self->{'verbose'} >= 2) { print "CWD  $self->{'want_dir'}\n"; }

  $self->{'ftp'}->cwd ($self->{'want_dir'})
    or return 0;
  $self->{'got_dir'} = $self->{'want_dir'};
  return 1;
}
# this is wrong if the removed parent is a symlink, but prevents relative
# cwd()s accumulating an endlessly longer $self->{'want_path'}
sub _collapse_dotdot_parent {
  my ($path) = @_;
  while ($path =~ s{[^/]+/\.\.(/|$)}{}) {}
  return File::Spec::Unix->canonpath($path);
}

sub pwd {
  my ($self) = @_;
  return $self->{'want_dir'};
}

sub ensure_all {
  my ($self) = @_;
  return $self->ensure_host
    && $self->ensure_login
      && $self->ensure_binary
        && $self->ensure_cwd;
}

sub put {  # ($self, $local, $remote)
  my $self = shift;
  ### FTPlazy put(): @_
  return $self->ensure_all && $self->{'ftp'}->put (@_);
}
sub delete {
  my $self = shift;  # ($self, $remote)
  return $self->ensure_all && $self->{'ftp'}->delete (@_);
}
sub mkdir {
  my $self = shift;
  return $self->ensure_all && $self->{'ftp'}->mkdir (@_);
}
sub rmdir {  # ($self, $remote)
  my $self = shift;
  return $self->ensure_all && $self->{'ftp'}->rmdir (@_);
}
sub rename {  # ($self, $remote_oldname, $remote_newname)
  my $self = shift;
  return $self->ensure_all && $self->{'ftp'}->rename (@_);
}
sub site {
  my $self = shift;
  return $self->ensure_all && $self->{'ftp'}->site (@_);
}
sub quot {
  my $self = shift;
  return $self->ensure_all && $self->{'ftp'}->quot (@_);
}

sub all_ok {
  my ($self) = @_;
  return (! $self->{'ftp'} || $self->{'ftp'}->pwd);
}

sub mlsd {
  my $self = shift;
  $self->ensure_all || return;
  return $self->{'ftp'}->_list_cmd("MLSD", @_);
}

# sub mlsd {
#   my ($self, $remote_dirname, $local_filename) = @_;
#   $self->ensure_all;
#   # ### MLSD: $remote_dirname
#   # my $data = $self->{'ftp'}->_data_cmd("MLSD $remote_dirname")
#   #   or return undef;
#   # 
#   # require File::Copy;
#   # File::Copy::copy($data, $local_filename);
#   # unless ($data->close) {
#   #   croak "Error closing data stream";
#   # }
#   # 
#   # ### MLSD message: $self->message
#   # return undef;
# }

1;
__END__
