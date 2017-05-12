#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Tk::Perl::WeakAfter;
use 5.008;
use strict;
use Tk;
use Scalar::Util;

our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class) = @_;
  return bless { }, $class;

  #   # after, repeat, idle
  #   sub new {
  #     my ($class, $type, $widget, $ms, $repeat) = @_;
  #     my $self = bless { widget => $widget }, $class;
  #     Scalar::Util::weaken($self->{'widget'});
  #     my $method = ($ms eq 'idle' ? 'afterIdle'
  #                   : ($repeat||'') eq 'repeat' ? 'repeat' : 'after');
  #     # $self->{'id'} = $widget->$method($ms,$callback,$type);
  #     return $self;
  #   }
}
sub idle {
  my ($self, $widget, $method, @args) = @_;
  if ($self->type ne 'idle') {
    $self->cancel;
  }
  $self->{'widget'} = $widget;
  Scalar::Util::weaken($self->{'widget'});
  $self->{'method'} = $method;
  $self->{'args'} = \@args;
  Scalar::Util::weaken(my $weak_self = $self);
  $self->{'id'} = $widget->afterIdle(\&_do_once, \$weak_self);
}
sub _do_once {
  my ($ref_weak_self) = @_;
  ### WeakAfter _do_once(): map {"$_"} @_

  my $self = $$ref_weak_self || return;
  delete $self->{'id'};

  my $widget = $self->{'widget'} || return;
  my $method = $self->{'method'};
  $widget->$method (@{$self->{'args'}});
}

sub after {
  my ($self, $widget, $ms, $method, @args) = @_;
  $self->cancel;
  $self->{'widget'} = $widget;
  Scalar::Util::weaken($self->{'widget'});
  $self->{'method'} = $method;
  $self->{'args'} = \@args;
  Scalar::Util::weaken(my $weak_self = $self);
  $self->{'id'} = $widget->after($ms, \&_do_once, \$weak_self);
}

sub repeat {
  my ($self, $widget, $ms, $method, @args) = @_;
  $self->cancel;
  $self->{'widget'} = $widget;
  Scalar::Util::weaken($self->{'widget'});
  $self->{'method'} = $method;
  $self->{'args'} = \@args;
  Scalar::Util::weaken(my $weak_self = $self);
  $self->{'id'} = $widget->repeat($ms, \&_do_repeat, \$weak_self);
}
sub _do_repeat {
  my ($ref_weak_self) = @_;
  ### WeakAfter _do_repeat(): map {"$_"} @_

  my $self = $$ref_weak_self || return;
  my $widget = $self->{'widget'} || return;
  my $method = $self->{'method'};
  $widget->$method (@{$self->{'args'}});
}
sub time {
  my ($self, $ms) = @_;
  if (my $id = $self->{'id'}) {
    if ($ms == 0) {
      $self->cancel;
    } else {
      $id->time($ms);
    }
  } else {
    return;
  }
}

sub DESTROY {
  my ($self) = @_;
  $self->cancel;
}
sub cancel {
  my ($self) = @_;
  ### WeakAfter cancel() ...
  if (my $id = delete $self->{'id'}) {
    $id->cancel;
  }
}
sub info {
  my ($self) = @_;
  if (my $widget = $self->{'widget'}) {
    if (my $id = $self->{'id'}) {
      return $widget->afterInfo($id);
    }
  }
  return;
}
sub type {
  my ($self) = @_;
  my $type = '';
  if (my $widget = $self->{'widget'}) {
    if (my $id = $self->{'id'}) {
       (undef,$type) = $widget->afterInfo($id);
    }
  }
  return $type;
}

1;
__END__

# =for stopwords Ryde MathImage
# 
# =head1 NAME
# 
# App::MathImage::Tk::Perl::WeakAfter -- object for an "after" or "idle"
# 
# =head1 SYNOPSIS
# 
#  use App::MathImage::Tk::Perl::WeakAfter;
#  my $ao = App::MathImage::Tk::Perl::WeakAfter->new;
#  $ao->after ($widget,
#              20,          # milliseconds
#              'callback',  # callback method or func
#              123);        # args
#  # calls $widget->callback(123)
# 
# =head1 DESCRIPTION
# 
# I<In progress ...>
# 
# This is an object-oriented approach to a one-shot "after" timer or "idle"
# callback.  If a WeakAfter object is discarded then its timer or idle is
# cancelled.
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<$ao = App::MathImage::Tk::Perl::WeakAfter-E<gt>new (key=E<gt>value,...)>
# 
# Create and return a new WeakAfter object.
# 
# =item C<$ao-E<gt>after($widget, $milliseconds, $callback, $arg...)>
# 
# =item C<$ao-E<gt>idle($widget, $callback, $arg...)>
# 
# Setup an after time or idle callback in C<$ao>.  C<after()> sets up a timer
# of the given C<$milliseconds>.  C<idle()> sets up for when main loop is
# idle.  In both cases a callback is made, just once,
# 
#     $widget->$callback($arg...)
# 
# =item C<$str = $ao-E<gt>cancel()>
# 
# Cancel any after or idle callback pending in C<$ao>.  If there's no callback
# pending then do nothing.
# 
# A callback is automatically cancelled if C<$ao> or the target C<$widget> is
# destroyed.
# 
# =item C<$str = $ao-E<gt>type()>
# 
# Return the type of callback, either string "after" or "idle".  If there's no
# callback active in C<$ao> then return C<undef>.
# 
# =back
# 
# =head1 SEE ALSO
# 
# L<Tk::after>,
# L<Tk::callbacks>
# 
# =head1 HOME PAGE
# 
# L<http://user42.tuxfamily.org/math-image/index.html>
# 
# =head1 LICENSE
# 
# Copyright 2011, 2012, 2013 Kevin Ryde
# 
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
# 
# Math-Image is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# Math-Image.  If not, see <http://www.gnu.org/licenses/>.
# 
# =cut
