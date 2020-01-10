# Copyright 2012, 2013, 2014, 2015, 2017, 2020 Kevin Ryde

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

package App::Upfiles::Tie::Handle::Throttle;
use 5.004;
use strict;
use Time::HiRes;
use List::Util 'min';

use vars '$VERSION';
$VERSION = 14;

# uncomment this to run the ### lines
#use Smart::Comments;


sub TIEHANDLE {
  my $class = shift;
  ### TIEHANDLE(): @_
  my $self = bless { blocksize => 4096,
                     upto      => 0,
                     last_time => Time::HiRes::time(),
                     @_,
                   }, $class;

  my $bytes_per_second;
  if (defined ($bytes_per_second = $self->{'bytes_per_second'})) {
  } elsif (defined (my $bits_per_second = $self->{'bits_per_second'})) {
    $bytes_per_second = $bits_per_second/8;
  } else {
    $bytes_per_second = 9600/8;
  }
  $self->{'period'} = $self->{'blocksize'} / $bytes_per_second;

  ### blocksize: $self->{'blocksize'}
  ### period: $self->{'period'}

  return $self;
}

sub OPEN {
  my ($self) = @_;
  ### OPEN() ...

  if ($self->{'fh'}) {
    $self->CLOSE;
  }
  # if (! defined $self->{'fh'}) {
  #   require Symbol;
  #   $self->{'fh'} = Symbol::gensym();
  # }
  return (@_ == 2
          ? open($self->{'fh'}, $_[1])
          : open($self->{'fh'}, $_[1], $_[2]));
}
sub CLOSE {
  my ($self) = @_;
  return close ($self->{'fh'});
}
sub EOF     {
  my ($self) = @_;
  return eof($self->{'fh'});
}
sub TELL    {
  my ($self) = @_;
  return tell($self->{'fh'});
}
sub FILENO  {
  my ($self) = @_;
  return fileno($self->{'fh'});
}
sub SEEK    {
  my ($self) = @_;
  return seek($self->{'fh'},$_[1],$_[2]);
}
sub BINMODE {
  my ($self) = @_;
  return binmode($self->{'fh'});
}

sub READ {
  ### READ(): $_[2]

  my $self = $_[0];
  my $len = $_[2];
  $self->throttle;
  my $remaining = $self->{'blocksize'} - $self->{'upto'};
  $len = min ($len, $remaining);
  ### $len

  my $ret = read($self->{'fh'},$_[1],$len);
  if (defined $ret) {
    $self->{'upto'} += $ret;
  }
  return $ret;
}
sub READLINE {
  my ($self) = @_;
  ### READLINE() ...

  $self->throttle;
  my $fh = $self->{'fh'};
  my $ret = <$fh>;
  if (defined $ret) {
    $self->{'upto'} += length($ret);
  }
  return $ret;
}
sub GETC {
  my ($self) = @_;
  ### GETC() ...

  $self->throttle;
  my $ret = getc($self->{'fh'});
  if (defined $ret) {
    $self->{'upto'}++;
  }
  return $ret;
}

sub throttle {
  my ($self) = @_;
  my $remaining = $self->{'blocksize'} - $self->{'upto'};
  if ($remaining <= 0) {
    my $now = Time::HiRes::time();
    my $sleep = $self->{'last_time'} + $self->{'period'} - $now;
    ### $sleep
    if ($sleep > 0 && $sleep < 5) {
      Time::HiRes::sleep ($sleep);
    }
    $self->{'upto'} = 0;
    $self->{'last_time'} = $now;
  }
}

sub WRITE {
  die;
}
sub PRINT {
  die;
}
sub PRINTF {
  die;
}

1;
__END__

# =head1 SEE ALSO
# 
# L<throttle(1)>
