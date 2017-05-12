# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Wx::Params;
use 5.008;
use strict;
use warnings;
use List::Util;
use POSIX ();
use Module::Load;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 110;

# after_item => $item
#
sub new {
  my $class = shift;
  ### Params new() ...
  return bless { items_hash => {},
                 parameter_info_array => [],
                 parameter_values => {},
                 @_ }, $class;
}

sub GetParameterValues {
  my ($self) = @_;
  ### Wx-Params GetParameterValues() ...

  ### items_hash: keys %{$self->{'items_hash'}}
  ### parameter_info_array: $self->{'parameter_info_array'}

  my %ret;
  foreach my $pinfo (@{$self->{'parameter_info_array'} || []}) {
    if (_pinfo_when($self,$pinfo)
        && (my $item = _pinfo_to_item ($self, $pinfo))) {
      ### $pinfo
      $ret{$pinfo->{'name'}} = $item->GetValue;
    }
  }
  ### GetParameterValues: \%ret
  return \%ret;
}

sub SetParameterValues {
  my ($self, $hashref) = @_;
  ### Wx-Params SetParameterValues(): $hashref

  my %newval = (%{$self->{'parameter_values'}},
                %$hashref);
  foreach my $pinfo (@{$self->{'parameter_info_array'}}) {
    my $name = $pinfo->{'name'};
    my $key = $pinfo->{'share_key'} || $name;
    if (exists $newval{$name}
        && (my $item = $self->{'items_hash'}->{$key})) {
      $item->SetValue (delete $newval{$name});
    }
  }
  $self->{'parameter_values'} = \%newval;
}

sub SetParameterInfoArray {
  my ($self, $newval) = @_;
  ### SetParameterInfoArray(): $newval

  my $toolbar = $self->{'toolbar'};
  my $items_hash = $self->{'items_hash'};
  my %hide = %$items_hash;

  my $pos = $toolbar->GetToolPos ($self->{'after_item'}->GetId);
  if ($pos == Wx::wxNOT_FOUND()) {
    die "after_item not found";
  }
  $pos++;
  ### $pos

  foreach my $pinfo (@$newval) {
    ### $pinfo
    my $name = $pinfo->{'name'};
    my $key = $pinfo->{'share_key'} || $name;

    my $item = $items_hash->{$key};
    if (defined $item) {
      delete $hide{$key};
    } else {
      my $ptype = $pinfo->{'type'};
      my $display = ($pinfo->{'display'} || $name);
      Scalar::Util::weaken (my $weak_self = $self);
      ### new item...
      ### $name
      ### $ptype
      ### $display

      my $class;
      if (defined (my $ptype_hint = $pinfo->{'type_hint'})) {
        $class = "App::MathImage::Wx::Params::\u${ptype}::\u${ptype_hint}";
        ### hint class: $class
      }
      unless ($class && Module::Util::find_installed($class)) {
        $class = "App::MathImage::Wx::Params::\u$ptype";
        ### ptype class: $class
        unless (Module::Util::find_installed($class)) {
          $class = 'App::MathImage::Wx::Params::String';
        }
      }
      ### decided class: $class
      Module::Load::load ($class);
      $item = $class->new ($toolbar, $pinfo);

      $item->{'callback'} = sub {
        _do_item_changed ($self, $item);
      };

      {
        my $tooltip = $pinfo->{'description'};
        if (! defined $tooltip) {
          $tooltip = $self->{'display'};
          if (! defined $tooltip) {
            $tooltip = $self->{'name'};
          }
        }
        ### $tooltip
        if (defined $tooltip) {
          $toolbar->SetToolShortHelp ($item->GetId, $tooltip);
        }
      }
      $items_hash->{$key} = $item;
    }

    ### InsertControl at pos: $pos
    $toolbar->RemoveTool ($item->GetId);
    $toolbar->InsertControl ($pos++, $item);
  }

  foreach my $item (values %hide) {
    $item->Hide;
  }
  $toolbar->Realize;
  $self->{'parameter_info_array'} = $newval;
  _update_visible ($self);

  ### parameter_values now: $self->GetParameterValues()
}

sub _update_visible {
  my ($self) = @_;
  ### Wx-Params _update_visible() ...

  my $items_hash = $self->{'items_hash'};
  foreach my $pinfo (@{$self->{'parameter_info_array'}}) {
    ### name: $pinfo->{'name'}
    if (my $item = _pinfo_to_item($self,$pinfo)) {
      my $show = _pinfo_when($self,$pinfo);
        ### $show
      $item->Show ($show);
    }
  }
  ### Wx-Params _update_visible() done ...
}
sub _do_item_changed {
  my ($self, $item) = @_;
  ### Wx-Params _do_item_changed() ...
  _update_visible ($self);

  if (my $callback = $self->{'callback'}) {
    &$callback($self);
  }
}

sub _pinfo_when {
  my ($self, $pinfo) = @_;
  if (my $when_name = $pinfo->{'when_name'}) {
    ### $when_name
    if (my $when_pinfo = List::Util::first {$_->{'name'} eq $when_name} @{$self->{'parameter_info_array'}}) {
      if (my $when_item = _pinfo_to_item($self,$when_pinfo)) {
        my $got_value = $when_item->GetValue;
        ### $got_value
        if (defined $got_value) {
          if (my $when_condition = $pinfo->{'when_condition'}) {
            ### $when_condition
            if ($when_condition eq 'odd') {
              return ($got_value % 2) != 0;
            }
          }

          {
            my @when_values = ((defined $pinfo->{'when_value'} ? $pinfo->{'when_value'} : ()),
                               @{$pinfo->{'when_values'} || []});
            if (@when_values) {
              return (List::Util::first {$_ eq $got_value} @when_values);
            }
          }
        }
      }
    }
  }
  return 1;
}

sub _pinfo_to_item {
  my ($self, $pinfo) = @_;
  return $self->{'items_hash'}->{$pinfo->{'share_key'} || $pinfo->{'name'}};
}


1;
__END__
