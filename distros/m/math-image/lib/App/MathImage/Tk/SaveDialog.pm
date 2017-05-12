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

package App::MathImage::Tk::SaveDialog;
use 5.008;
use strict;
use warnings;
use Cwd;
use List::Util 'max';
use Module::Load;
use Tk;
use Tk::Balloon;
use Locale::TextDomain 1.19 ('App-MathImage');

# uncomment this to run the ### lines
#use Smart::Comments;

use base 'Tk::Derived', 'Tk::DialogBox';
Tk::Widget->Construct('AppMathImageTkSaveDialog');

our $VERSION = 110;

my %format_to_module = (png  => 'Tk::PNG',
                        jpeg => 'Tk::JPEG',
                        tiff => 'Tk::TIFF',
                       );

sub Populate {
  my ($self, $args) = @_;
  ### SaveDialog Populate()

  $self->ConfigSpecs ('-drawing' => [ 'SELF','PASSIVE' ]);
  $self->{'-drawing'} = delete $args->{'-drawing'};
  my $balloon = $self->Balloon;

  my $cname = __('Cancel');
  my $sname = __('Save');
  %$args = (-title => __('Math-Image: Save'),
            -buttons => [ $sname, $cname ],
            -cancel_button => $cname,
            %$args);
  $self->SUPER::Populate($args);

  {
    my $sbutton = $self->Subwidget("B_$sname");
    $sbutton->configure (-command => [ $self, 'save' ]);
  }
  {
    my $cbutton = $self->Subwidget("B_$cname");
    $cbutton->configure (-command => [ $self, 'withdraw' ]);
  }

  $self->Component('Label','label',
                   -text => __('Save'))
    ->pack;

  $self->Label (-text => __x('Directory: {directory}',
                             directory => getcwd()))
    ->pack;

  $self->{'filename'} = 'math-image-out.png';
  $self->Component('Entry','entry',
                   -textvariable => \$self->{'filename'},
                   -width => 40)->pack->focus;

  {
    my @values = (reverse
                  # png,jpeg in new enough perl-tk, tiff is an add-on
                  (Module::Util::find_installed('Tk::PNG') ? ('PNG') : ()),
                  (Module::Util::find_installed('Tk::JPEG') ? ('JPEG') : ()),
                  (Module::Util::find_installed('Tk::TIFF') ? ('TIFF') : ()),
                  'GIF',
                  'BMP',
                  'XPM',
                  'PPM',
                  'XBM');
    my $spin = $self->Spinbox
      (-values => \@values,
       -width => max(map{length} @values) + 1,
       -command => [ $self, '_update_format' ]);
    my $value = $values[0];
    $spin->set($value);
    $self->{'format'} = $value;
    $spin->pack;
    $balloon->attach ($spin, -balloonmsg => __('The file format to save in.'));
  }
}

sub _update_format {
  my ($self, $format, $direction) = @_;
  ### _update_format: @_[1..$#_]
  my $old_format = $self->{'format'};
  $self->{'format'} = $format;

  # crib: Tk::Entry magically notices textvariable changes
  $self->{'filename'} =~ s/\.\L$old_format$/.\L$format/;
}

sub save {
  my ($self) = @_;
  my $drawing = $self->{'-drawing'} || die "Oops, no drawing widget for save";
  my $filename = $self->{'filename'};
  ### $filename
  if ($filename =~ /^\s*$/) {
    ### whitespace only ...
    $self->Subwidget('label')->configure(-text => __('No filename given'));
    $self->bell;
    return;
  }

  my $result;
  if (eval {
    my $photo = $drawing->cget('-image') || die "Oops, no photo in drawing";
    my $format = $self->{'format'};
    if (my $module = $format_to_module{lc($format)}) {
      Module::Load::load($module);
    }
    ### $format
    $photo->write ($filename, -format => $format);
    1;
  }) {
    $self->withdraw;
    return;
    # $result = __('Save Ok');
  } else {
    $self->bell;
    $result = __x('Error {message}', message => $@);
  }
  $self->Subwidget('label')->configure(-text => $result);
}

1;
__END__
