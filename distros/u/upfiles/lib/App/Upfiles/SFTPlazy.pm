# Copyright 2017, 2020 Kevin Ryde

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

package App::Upfiles::SFTPlazy;
use 5.010;
use strict;
use warnings;
use Carp;
use Net::SFTP::Foreign;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 14;

# Have croaks from Net::SFTP reported against the caller (App::Upfiles)
# rather than here.
# our @CARP_NOT = ('Net::SFTP::Foreign');

sub new {
  my $class = shift;
  return bless { verbose => 0,
                 want_dir => '/',
                 message => '',
                 code => 0,
                 @_ }, $class;
}

sub message {
  my ($self) = @_;
  return (defined $self->{'sftp'} ? $self->{'sftp'}->error : $self->{'message'});
}
sub ok {
  my $self = shift;
  my $code = $self->code;
  return $code >= 0 && $code < 400;
}
sub code {
  my ($self) = @_;
  return (defined $self->{'sftp'} ? $self->{'sftp'}->code : $self->{'code'});
}

sub host {
  my ($self, $host) = @_;
  if (@_ < 2) { return $self->{'want_host'}; }

  $self->{'want_host'} = $host;
  return 1;
}
sub login {
  my ($self, $username) = @_;
  ### SFTPlazy login(): $username
  $self->{'want_username'} = $username;
  return 1;
}
sub ensure_host_and_login {
  my ($self) = @_;
  if (! defined $self->{'want_host'}) {
    $self->{'message'} = 'No host() machine given';
    return 0;
  }
  if (defined $self->{'got_host'}
      && $self->{'got_host'} eq $self->{'want_host'}) {
    return 1;
  }

  ### SFTPlazy ensure_host_and_login() change ...
  ### got:  $self->{'got_host'}
  ### want: $self->{'want_host'}
  my $username = $self->{'want_username'};
  my $password;

  if (! defined $username) {
    ### try netrc for username of host: $self->{'want_host'}
    require Net::Netrc;
    if (my $netrc = Net::Netrc->lookup($self->{'want_host'})) {
      ### $netrc
      $username = $netrc->login;
      $password = $netrc->password;
    }
  }
  if (! defined $self->{'want_username'}) {
    $self->{'message'} = 'No login() username given';
    $self->{'code'} = 500;
    return 0;
  }

  if (! defined $password) {
    ### try netrc for password of username: $username
    require Net::Netrc;
    if (my $netrc = Net::Netrc->lookup($self->{'want_host'}, $username)) {
      ### $netrc
      $username = $netrc->login;
      $password = $netrc->password;
    }
  }

  ### $username
  ### $password
  ### host: $self->{'want_host'}
  if ($self->{'verbose'} >= 2) { print "SFTP $self->{'want_host'}\n"; }
  my $sftp = Net::SFTP::Foreign->new
    ($self->{'want_host'},
     user  => $self->{'want_username'},
     more  => ($self->{'verbose'} >= 2
               ? [ '-' . ('v' x ($self->{'verbose'}-1)) ]  # -v verbosity
               : []),
     password  => $password,
    );
  if (my $err = $sftp->error) {
    ### SFTP error: $err
    $self->{'message'} = $err;
    $self->{'code'} = 500;
    return 0;
  }

  $self->{'sftp'} = $sftp;
  $self->{'got_host'} = $self->{'want_host'};
  undef $self->{'got_cwd'};
  return 1;
}

sub binary {
  my ($self) = @_;
  return 1;  # binary is the default in SFTP
}

sub cwd {
  my ($self, $dir) = @_;

  # default root dir, like Net::FTP
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

  ### SFTPlazy setcwd(): $self->{'want_dir'}
  $self->{'sftp'}->setcwd ($self->{'want_dir'})
    or return 0;
  $self->{'got_dir'} = $self->{'want_dir'};
  ### SFTPlazy setcwd() ok ...
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
  return $self->ensure_host_and_login
    && $self->ensure_cwd;
}

sub put {
  my ($self, $local, $remote) = @_;
  ### SFTPlazy put(): @_
  return $self->ensure_all
    && $self->{'sftp'}->put ($local, $remote,
                             atomic => 0,
                             copy_time => $self->{'copy_time'});
}
sub delete {
  my ($self, $remote) = @_;
  return $self->ensure_all
    && $self->{'sftp'}->remove ($remote);
}
sub mkdir {
  my ($self, $remote, $parents) = @_;
  my $method = $parents ? 'mkpath' : 'mkdir';
  return $self->ensure_all
    && $self->{'sftp'}->$method ($remote);
}
sub rmdir {
  my ($self, $remote) = @_;
  return $self->ensure_all && $self->{'sftp'}->rmdir ($remote);
}
sub rename {
  my ($self, $oldname, $newname) = @_;
  return $self->ensure_all
    && $self->{'sftp'}->rename ($oldname, $newname, overwrite=>1);
}
sub site {
}
sub quot {
}

sub all_ok {
  my ($self) = @_;
  return (! $self->{'sftp'}              # either sftp never used
          || ! $self->{'sftp'}->error);  # or no error from it
}

sub mlsd {
  my $self = shift;
  $self->ensure_all || return;
  return $self->{'sftp'}->_list_cmd("MLSD", @_);
}

# sub mlsd {
#   my ($self, $remote_dirname, $local_filename) = @_;
#   $self->ensure_all;
#   # ### MLSD: $remote_dirname
#   # my $data = $self->{'sftp'}->_data_cmd("MLSD $remote_dirname")
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
