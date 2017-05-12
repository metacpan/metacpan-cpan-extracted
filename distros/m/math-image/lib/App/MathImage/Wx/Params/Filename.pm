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


package App::MathImage::Wx::Params::Filename;
use 5.004;
use strict;

use base 'Wx::FilePickerCtrl';
our $VERSION = 110;


sub new {
  my ($class, $parent, $info) = @_;
  ### Params-String new(): "$parent"

  # my $display = ($newval->{'display'} || $newval->{'name'});
  my $self = $class->SUPER::new ($parent,
                                 Wx::wxID_ANY(),       # id
                                 $info->{'default'});  # initial value
  $self->SetWindowStyle (Wx::wxFLP_DEFAULT_STYLE()
                         | Wx::wxFLP_USE_TEXTCTRL());
  $self->SetSize (Wx::Size->new (10*($info->{'width'} || 5),
                                 -1));

  Wx::Event::EVT_FILEPICKER_CHANGED ($self, $self, 'OnTextEnter');
  return $self;
}

sub GetValue {
  my ($self) = @_;
  return $self->SUPER::GetPath;
}
sub SetValue {
  my ($self, $value) = @_;
  if (! defined $value) { $value = ''; }
  $self->SUPER::SetPath ($value);
}

sub OnTextEnter {
  my ($self, $event) = @_;
  #   ### Params-String OnActivate()...
  #   my $self = $$ref_weak_self || return;
  #   ### parameter-value now: $self->get('parameter-value')
  #   $self->notify ('parameter-value');

  if (my $callback = $self->{'callback'}) {
    &$callback($self);
  }
}


1;
__END__
