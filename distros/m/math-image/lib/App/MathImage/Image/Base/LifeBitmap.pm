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


package App::MathImage::Image::Base::LifeBitmap;
use 5.004;
use strict;
use Carp;
use vars '$VERSION', '@ISA';

use Image::Base::Text 8; # v.8 for 0,0,width,height clip
@ISA = ('Image::Base::Text');

$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments '###';

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-LifeBitmap xy(): @_[1 .. $#_]

  my $rows_array = $self->{'-rows_array'};
  if (@_ == 3) {
    return vec($rows_array->[$y],$x,1);
  } else {
    vec($rows_array->[$y],$x,1) = $self->colour_to_bit($colour);
  }
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-Text load()
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### $filename

  open FH, "<$filename" or croak "Cannot open $filename: $!";
  $self->load_fh (\*FH);
  close FH or croak "Error closing $filename: $!";
}

# not yet documented ...
sub load_fh {
  my ($self, $fh) = @_;
  ### load_fh()

  my $header;
  while (defined($header = <$fh>) && $header =~ /^#/) {
  }
  if (! defined $header) {
    croak "No header line";
  }
  $header =~ s/\s+//g;
  #              1       2    3      4
  $header =~ /^x=(\d+),y=(\d+)(,rule=(.*))?/
    or croak 'Unrecognised header line: ',$header;
  my $width = $1;
  my $height = $2;
  my $rule = $4;

  my @rows;
  my $row = '';
  my $pos = 0;
  my $reps = '';
  for (;;) {
    undef $!;
    my $c = getc($fh);
    if (! defined $c) {
      if (defined $!) {
        croak 'Read error: ',$!;
      }
      last;
    }

    if ($c =~ /\s/) {
      # skip whitespace

    } elsif ($c =~ /\d/) {
      ### digit
      ### $reps
      $reps .= $c;
      ### $reps

    } elsif ($c =~ /[b.]/) {
      if (length($reps) == 0) {
        $reps = 1;
      }
      ### b
      ### $pos
      ### $reps
      $pos += $reps;
      $reps = '';

    } elsif ($c =~ /[oA]/) {
      if (length($reps) == 0) {
        $reps = 1;
      }
      ### o
      ### $pos
      ### $reps
      while ($reps-- > 0) {
        vec($row,$pos++,1) = 1;
      }
      $reps = '';

    } elsif ($c eq '$') {
      ### push row: $row
      push @rows, $row;
      $row = '';
      if (length($reps) == 0) {
        $reps = 1;
      }
      while (--$reps > 0) {
        push @rows, '';
      }
      if ($width < $pos) {
        $width = $pos;
      }
      $pos = 0;
      $reps = '';

    } elsif ($c eq '#') {
      while (defined ($c = getc($fh))) {
        if ($c eq "\n") {
          last;
        }
      }

    } elsif ($c eq '!') {
      last;

    } else {
      croak 'Unrecognised input char: ',$c;
    }
  }

  if ($pos) {
    push @rows, $row;
    if ($width < $pos) {
      ### extend width beyond header
      $width = $pos;
    }
  }

  $self->{'-rows_array'} = \@rows;
  if (@rows > $height) {
    ### extend height above header
    $height = scalar(@rows);
  }
  ### rows_array: $self->{'-rows_array'}
  $self->set (-width => $width, # pad shorter rows
              -rule  => $rule);
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-LifeBitmap save(): @_
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

  {
    select $fh;
    $| = 1;
    select STDOUT;
  }
  my $width = $self->{'-width'};

  my $column = 0;
  my $rows_array = $self->{'-rows_array'};
  for (my $y = 0; $y < @$rows_array; $y++) {
    my $row = $rows_array->[$y];
    ### $y
    ### $row
    my $pos = 0;
    while ($pos < $width) {
      my $reps = 1;
      my $bit = vec($row,$pos,1);
      ### $pos
      ### $bit
      while (++$pos < $width && vec($row,$pos,1) == $bit) {
        $reps++;
      }
      ### no more reps at: $pos, $bit, vec($row,$pos,1)
      if ($reps == 1) {
        $reps = '';
      }
      $column += length($reps) + 1;
      my $nl;
      if ($column > 72) {
        $nl = "\n";
        $column = 0;
      } else {
        $nl = '';
      }
      print $fh $reps, ($bit ? 'o' : 'b'), $nl
        or return undef;
    }

    my $eol_reps = 1;
    while ($y < $#$rows_array && $rows_array->[$y+1] !~ /[^\0]/) {
      $eol_reps++;
      $y++;
    }
    if ($eol_reps == 1) {
      $eol_reps = '';
    }
    my $nl;
    $column += length($eol_reps) + 1;
    if ($column > 40) {
      $nl = "\n";
      $column = 0;
    } else {
      $nl = '';
    }
    print $fh $eol_reps,'$',$nl
      or return undef;
  }
  return print $fh "!\n";
}

my %colour_to_bit = ('' => 0,
                     ' ' => 0,
                     'b' => 0,
                     '0' => 0,
                     'clear' => 0,
                     'black' => 0,

                     'o' => 1,
                     'A' => 1,
                     'set' => 1,
                     '1' => 1,
                     'white' => 1);
sub colour_to_bit {
  my ($self, $colour) = @_;
  ### colour_to_character(): $colour
  if (defined (my $bit = $colour_to_bit{$colour})) {
    return $bit;
  }
  croak "Unrecognised colour: $colour";
}

1;
__END__

=for stopwords LifeBitmap filename Ryde RLE

=head1 NAME

App::MathImage::Image::Base::LifeBitmap -- game of life cellular bitmap in RLE format

=head1 SYNOPSIS

 use App::MathImage::Image::Base::LifeBitmap;
 my $image = App::MathImage::Image::Base::LifeBitmap->new (-width => 100,
                                                        -height => 100);
 $image->rectangle (0,0, 99,99, 'b');
 $image->xy (20,20, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->save ('/some/filename.rle');

=head1 CLASS HIERARCHY

C<App::MathImage::Image::Base::LifeBitmap> is a subclass of
C<Image::Base>,

    Image::Base
      App::MathImage::Image::Base::LifeBitmap

=head1 DESCRIPTION

C<App::MathImage::Image::Base::LifeBitmap> extends C<Image::Base> to create
or update game of life RLE format bitmap files.

The colour names are " " (space), "b", "." or "clear" for background, and
"o" or "set" for a set cell.

=head1 FUNCTIONS

=over 4

=item C<$image = App::MathImage::Image::Base::LifeRLE-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = App::MathImage::Image::Base::LifeRLE->new
               (-width => 200, -height => 100);

Or an existing file can be read,

    $image = App::MathImage::Image::Base::LifeRLE->new
               (-file => '/some/filename.rle');

=back

=head1 SEE ALSO

L<Image::Base>, L<Image::Xbm>

L<golly(6)>

=cut
