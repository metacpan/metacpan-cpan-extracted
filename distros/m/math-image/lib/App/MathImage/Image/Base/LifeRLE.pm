# Text fill space vs \0


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


package App::MathImage::Image::Base::LifeRLE;
use 5.004;
use strict;
use Carp;
use vars '$VERSION', '@ISA';

use Image::Base::Text 8; # v.8 for 0,0,width,height clip
@ISA = ('Image::Base::Text');

$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments '###';

my $pqr = 'pqrstuvwxy';
my $ABC = 'ABCDEFGHIJKLMNOPQRSTUVWX';
my $space = ord(' ');
my $binary_re = "[^ ".chr($space+1)."]";

# not yet documented ...
sub load_lines {
  my $self = shift;
  ### load_lines(): @_

  while (@_ && $_[0] =~ /^#/) {  # comments before header
    shift;
  }

  if (! @_) {
    croak "No header line";
  }
  my $header = $_[0];
  shift;
  $header =~ s/\s+//g;
  #              1       2    3      4
  $header =~ /^x=(\d+),y=(\d+)(,rule=(.*))?/
    or croak "Unrecognised header line";
  my $width = $1;
  my $height = $2;
  my $rule = $4;

  my @rows_array;
  my $row = '';
  foreach my $line (@_) {
    next if $line =~ /^#/; # comments anywhere
    ### $line
    #                1   2       34    5              6
    while ($line =~ /(!)|([0-9]*)((\$)|([pqrstuvwxy]?)(.))/g) {
      my $reps = $2 || 1;
      if ($1) {
        ### end of file
      } elsif ($4) {
        ### end of row: scalar(@rows_array)
        while ($reps--) {
          push @rows_array, $row;
          if (length($row) > $width) {
            ### extend width beyond header
            $width = length($row);
          }
          $row = '';
        }
      } else {
        my $hi = $5;
        my $c = $6;
        ### $c
        if ($c eq 'b' || $c eq '.') {
          $c = 0;
        } elsif ($c eq 'o') {
          $c = 1;
        } elsif ($c =~ /[$ABC]/o) {
          ### $hi
          ### hi val: (index($pqr,$hi)+1)*24
          ### lowval: index($c,$ABC)
          $c = index($ABC,$c) + 1;
          if ($hi ne '') {
            $c += (index($pqr,$hi)+1) * 24;
          }
        } else {
          croak "Unrecognised input char \"$c\" in \"$line\"";
        }
        $row .= chr(($c + $space) & 0xFF) x $reps;
      }
    }
  }
  if ($row ne '') {
    push @rows_array, $row;
    if (length($row) > $width) {
      ### extend width beyond header
      $width = length($row);
    }
  }

  $self->{'-rows_array'} = \@rows_array;
  if (@rows_array > $height) {
    ### extend height above header
    $height = scalar(@rows_array);
  }
  ### @rows_array
  $self->set (-width => $width, # pad shorter rows
              -rule  => $rule);
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-LifeRLE save(): @_
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  require Fcntl;
  sysopen FH, $filename, Fcntl::O_WRONLY() | Fcntl::O_TRUNC() | Fcntl::O_CREAT()
    or croak "Cannot create $filename: $!";

  if (! $self->save_fh (\*FH)) {
    my $err = "Error writing $filename: $!";
    { local $!; close FH; }
    croak $err;
  }
  close FH
    or croak "Error closing $filename: $!";
}

# not yet documented ...
sub save_fh {
  my ($self, $fh) = @_;
  my $rule = $self->get('-rule');
  if (! defined $rule) { $rule = 'B3/S23'; }
  print $fh
    "x = ",$self->get('-width'),
      ", y = ",$self->get('-height'),
        ", rule = ",$rule,"\n"
          or return undef;

  my $binary = 1;
  foreach my $row (@{$self->{'-rows_array'}}) {
    if ($row =~ /$binary_re/o) {
      ### not binary: $row
      $binary = 0;
      last;
    }
  }
  ### $binary

  my $rows_array = $self->{'-rows_array'};
  for (my $y = 0; $y < @$rows_array; $y++) {
    my $out = $rows_array->[$y];
    ### $out
    $out =~ s{((.)\2*)}
             {
               my $reps = length($1);
               my $c = $2;
               if ($binary) {
                 $c = ($c eq ' ' ? 'b' : 'o');
               } elsif ($c eq ' ') {
                 $c = '.';
               } else {
                 $c = ((ord($c) - $space) & 0xFF) - 1;
                 my $hi = int($c/24);
                 $c = substr (' pqrstuvwxy', $hi, $hi!=0)
                   . substr ($ABC, $c%24, 1);
               }
               if ($reps > 1) {
                 $c = "$reps$c";
               }
               $c
             }eg;
    my $eol_reps = 1;
    while ($y < $#$rows_array && $rows_array->[$y+1] !~ /[^ ]/) {
      $eol_reps++;
      $y++;
    }
    if ($eol_reps == 1) {
      $eol_reps = '';
    }
    print $fh $out, $eol_reps,"\$\n"
      or return undef;
  }
  return print $fh "!\n";
}

my %colour_to_bit = (' ' => 0,
                     '.' => 0,
                     'b' => 0,
                     'clear' => 0,
                     'black' => 0,

                     'o' => 1,
                     'set' => 1,
                     'white' => 1);
sub colour_to_character {
  my ($self, $colour) = @_;
  ### colour_to_character(): $colour
  if ($colour =~ /^\d+$/) {
    if ($colour > 255) {
      croak "Cell colours only go up to 255, got $colour";
    }
  } elsif (defined (my $bit = $colour_to_bit{$colour})) {
    $colour = $bit;
  } elsif ((my $idx = index($ABC,$colour)) >= 0) {
    $colour = $idx+1;
  } else {
    croak "Unrecognised cell colour: $colour";
  }
  ### result: ($space + $colour) & 0xFF
  return chr (($space + $colour) & 0xFF);
}

1;
__END__

=for stopwords LifeRLE filename Ryde RGB RLE multi-state

=head1 NAME

App::MathImage::Image::Base::LifeRLE -- game of life cellular grids in RLE format

=head1 SYNOPSIS

 use App::MathImage::Image::Base::LifeRLE;
 my $image = App::MathImage::Image::Base::LifeRLE->new (-width => 100,
                                                        -height => 100);
 $image->rectangle (0,0, 99,99, 'b');
 $image->xy (20,20, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->save ('/some/filename.rle');

=head1 CLASS HIERARCHY

C<App::MathImage::Image::Base::LifeRLE> is a subclass of
C<Image::Base::Text>, but don't rely on more than C<Image::Base> for now.

    Image::Base
      Image::Base::Text
        App::MathImage::Image::Base::LifeRLE

=head1 DESCRIPTION

C<App::MathImage::Image::Base::LifeRLE> extends C<Image::Base> to create or
update game of life RLE format files.

The colour names are " " (space), "b" or "." for background, and "o" for a
set cell.  For multi-state cells colours are numbers 0 to 255, with 0 being
the background and 1 corresponding to "o".

=head1 FUNCTIONS

=over 4

=item C<$image = App::MathImage::Image::Base::LifeRLE-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = App::MathImage::Image::Base::LifeRLE->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = App::MathImage::Image::Base::LifeRLE->new (-file => '/some/filename.rle');

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save the image to a text file, either the current C<-file> option, or set
that option to C<$filename> and save to there.

The current code automatically chooses between "o/b" for a binary-only grid
or "./A/B/etc" for multi-state.  Perhaps there should be an option to force
the multi-state format, or distinguish that from numbers used as colours.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::Text>

L<golly(6)>

=cut
