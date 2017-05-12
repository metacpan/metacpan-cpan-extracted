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


package App::MathImage::Wx::Params::Enum;
use 5.004;
use strict;
use Wx;
use Locale::TextDomain 1.19 ('App-MathImage');

use base 'Wx::Choice';
our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class, $parent, $info) = @_;
  ### Wx-Params-Enum new() ...
  ### parent: "$parent"
  ### $info

  my $choices = $info->{'choices'};
  my $choices_display = $info->{'choices_display'};
  my $default = $info->{'default'};

  my %choice_display_to_value;
  my %value_to_choice_display;
  if ($choices_display) {
    foreach my $i (0 .. $#$choices) {
      $choice_display_to_value{$choices_display->[$i]} = $choices->[$i];
      $value_to_choice_display{$choices->[$i]} = $choices_display->[$i];
    }
  } else {
    $choices_display = $choices;
  }
  ### $choices_display

  my $self = $class->SUPER::new ($parent,
                                 Wx::wxID_ANY(),
                                 Wx::wxDefaultPosition(),
                                 Wx::wxDefaultSize(),
                                 $choices_display);
  $self->{'choice_display_to_value'} = \%choice_display_to_value;
  $self->{'value_to_choice_display'} = \%value_to_choice_display;

  my $name = $info->{'name'};
  my $display = $info->{'display'};
  if (! defined $display) {
    $display = $name;
  }
  # $self->SetLabelText($display);
  $display =~ s/&/&&/g;
  $self->SetLabel($display);

  $self->SetValue ($default);

  Wx::Event::EVT_CHOICE ($self, $self, 'OnChoiceSelected');
  return $self;
}

sub GetValue {
  my ($self) = @_;
  ### Wx-Params-Enum GetValue() ...
  ### is: ($self->{'choice_display_to_value'}->{$self->GetStringSelection} || $self->GetStringSelection)

  my $choice_display = $self->GetStringSelection;
  return ($self->{'choice_display_to_value'}->{$choice_display}
          || $choice_display);
}
sub SetValue {
  my ($self, $newval) = @_;
  ### Wx-Params-Enum SetValue(): $newval
  ### label: $self->GetLabelText

  if (defined (my $display = $self->{'value_to_choice_display'}->{$newval})) {
    $newval = $display;
  }
  $self->SetStringSelection ($newval);
}

sub OnChoiceSelected {
  my ($self) = @_;
  ### Wx-Params-Enum OnChoiceSelected() ...
  if (my $callback = $self->{'callback'}) {
    &$callback($self);
  }
}

# sub _pinfo_to_enum_type {
#   my ($pinfo) = @_;
#   my $key = $pinfo->{'share_key'} || $pinfo->{'name'};
#   my $enum_type = "App::MathImage::Wx::Params::Enum::$key";
#   if (! eval { Glib::Type->list_values ($enum_type); 1 }) {
#     my $choices = $pinfo->{'choices'} || [];
#     ### $choices
#     Glib::Type->register_enum ($enum_type, @$choices);
# 
#     if (my $choices_display = $pinfo->{'choices_display'}) {
#       no strict 'refs';
#       %{"${enum_type}::EnumBits_to_display"}
#         = map { $choices->[$_] => $pinfo->{'choices_display'}->[$_] }
#           0 .. $#$choices;
#     }
#   }
#   return $enum_type;
# }

1;
__END__
