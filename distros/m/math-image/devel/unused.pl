#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

__END__



    #     {
    #       require File::Temp;
    #       my $fh = File::Temp->new;
    #       binmode($fh);
    #       ### filename: $fh->filename
    #       {
    #         require GD;
    #         my $gd = GD::Image->new ($width, $height);
    #         $gd->alphaBlending(0);
    #         $gen->draw_GD ($gd);
    #         ### drawn
    #         print $fh $gd->png(0);
    #         ### pnged
    #         close $fh;
    #       }
    #       ### filesize: -s $fh->filename
    #       $pixmap = $self->{'pixmap'}
    #         = Gtk2::Gdk::Pixmap->new ($self->window, $width, $height, -1);
    #       my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($fh->filename);
    #       $pixmap->draw_pixbuf ($self->style->black_gc, $pixbuf,
    #                             0, 0, # source x,y
    #                             0, 0, # dest x,y
    #                             $width, $height,
    #                             'normal', # dither
    #                             0, 0);    # dither x,y
    #     }

    #     {
    #       require File::Temp;
    #       my $fh = File::Temp->new;
    #       binmode($fh);
    #       ### filename: $fh->filename
    #       {
    #         my $image_class;
    #         $image_class = 'Image::Base::GD';
    #         $image_class = 'Image::Base::PNGwriter';
    #         eval "require $image_class" or die;
    #         my $image = $image_class->new
    #           (-width      => $width,
    #            -height     => $height);
    #         $gen->draw_Image ($image);
    #         ### drawn
    #         $image->save ($fh->filename);
    #         ### saved
    #         close $fh;
    #       }
    #       ### filesize: -s $fh->filename
    #       $pixmap = $self->{'pixmap'}
    #         = Gtk2::Gdk::Pixmap->new ($self->window, $width, $height, -1);
    #       my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($fh->filename);
    #       $pixmap->draw_pixbuf ($self->style->black_gc, $pixbuf,
    #                             0, 0, # source x,y
    #                             0, 0, # dest x,y
    #                             $width, $height,
    #                             'normal', # dither
    #                             0, 0);    # dither x,y
    #     }



# sub name {
#   my ($class_or_self) = @_;
#   my $class = (ref $class_or_self || $class_or_self);
#   $class =~ s/.*:://;
#   return $class;
# }

# sub n_to_xy {
#   my ($self, $n) = @_;
#   my ($r, $theta) = $self->n_to_rt ($n)
#     or return;
#   return ($r * cos($theta),
#           $r * sin($theta));
# }
# sub n_to_rt {
#   my ($self, $n) = @_;
#   my ($x, $y) = $self->n_to_xy ($n)
#     or return;
#   return (Math::Libm::hypot ($x, $y),
#           atan2 ($y, $x));
# }


} elsif ($option_shape eq 'spiral-stretch') {
my (@x,@y);
my $x = 0;
my $y = 0;
my $w = $width;
my $h = $height;
for (;;) {
  if ($w == 0 || $h == 0) { last; }
  foreach (my $i = 0; $i <= $h-1; $i++) {
    push @x, $x; push @y, $y+$i;     # left
  }
  foreach (my $i = 1; $i <= $w-1; $i++) {
    push @x, $x+$i; push @y, $y+$h-1;    # bottom
  }
  if ($w >= 1) {
    foreach (my $i = $h-2; $i >= 0; $i--) {
      push @x, $x+$w-1; push @y, $y+$i;     # right, upwards
    }
  }
  if ($h >= 1) {
    foreach (my $i = $w-2; $i >= 1; $i--) {
      push @x, $x+$i; push @y, $y;    # top, leftwards
    }
  }
  $x++; $y++;
  $w -= 2; $h -= 2;
}
@x = reverse @x;
@y = reverse @y;
$xy_func = sub {
  my ($n) = @_;
  if ($n > @x) {
    return (-1,-1);
  } else {
    return ($x[$n], $y[$n]);
  }
};


use constant DEFAULT_MODEL => do {

  my @formats;
  if (Gtk2::Gdk::Pixbuf->can('get_formats')) { # get_formats() new in Gtk 2.2
    @formats =
      map { $_->{'name'} }
        grep {
          my $format = $_;
          my $name = $format->{'name'};
          ### consider: $format

          ($format->can('is_writable')
           # is_writable() new in Gtk 2.2, and not wrapped until Perl-Gtk 1.240
           ? $format->is_writable

           : Gtk2->check_version (2,4,0)
           # 2.2 or earlier, only png and jpeg writable
           ? ($name eq 'png' || $name eq 'jpeg')

           # 2.4 or later, assume the five writables of 2.20
           : ($name eq 'png' || $name eq 'jpeg'
              || $name eq 'tiff' || $name eq 'ico' || $name eq 'bmp'))

        } Gtk2::Gdk::Pixbuf->get_formats;

  } else {
    @formats = ( 'png', 'jpeg' ); # Gtk 2.0 writables
  }
  ### @formats
  my %formats;
  @formats{@formats} = ();  # hash slice

  my $model = Gtk2::ListStore->new ('Glib::String', 'Glib::String');

  # explicit formats forcing their order in the list, then everything else
  foreach my $name ('png','jpeg','tiff',
                    'svg','xpm','pcx','pnm','tga','ico','bmp','xbm',
                    @formats) {
    exists $formats{$name} or next;
    delete $formats{$name};  # once only forced-order ones 'png'
    $model->set ($model->append,
                 0 => $name,
                 1 => Locale::Messages::dgettext('Gtk2-Ex-WidgetBits',
                                                 uc($name)));
  }
  $model
};


# perrin
  for (;;) {
    my $n = $values[-2] + $values[-3];
    if ($n > $hi) {
      last;
    }
    push @values, $n;
  }
  return @values;

# bit slower than XS
#
# use constant::defer primes_arrayref => sub {
#   require Math::Prime::TiedArray;
#   tie my @primes, 'Math::Prime::TiedArray';
#   return \@primes;
# };

  #   my @ret;
  #   my $primes_arrayref = primes_arrayref();
  #   @ret = ($primes_arrayref->[int($hi/log($hi))]);
  #   @ret = ();
  #   for (my $i = 0; ; $i++) {
  #     my $p = $primes_arrayref->[$i];
  #     if ($p > $hi) { last; }
  #     if ($p >= $lo) {
  #       push @ret, $p;
  #     }
  #   }
  #   return @ret;


# padovan  
  my @values = (1,1,1);
  for (;;) {
    my $n = $values[-2] + $values[-3];
    if ($n > $hi) {
      last;
    }
    push @values, $n;
  }
  return @values;
