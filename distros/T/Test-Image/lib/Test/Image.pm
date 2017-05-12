# HUUUUUUUUUUGE  heap of undocumented crap I don't have time to
# figure out right now.

# col is documented
# col_all is documented
# col_any is documented
# col_none is documented
# column is documented
# column_all is documented
# column_any is documented
# column_none is documented
# region is documented
# region_all is documented
# region_any is documented
# region_none is documented
# row is documented
# row_all is documented
# row_any is documented
# row_none is documented

package Test::Image;
use base qw(Exporter);

use strict;
use warnings;

use vars qw($VERSION @STANDARD_PLUGINS @EXPORT);

$VERSION = "0.02";

use Carp qw(croak);

# get the Test::Builder singleton
use Test::Builder;
my $tester = Test::Builder->new();

# set up the color names
my %NameTable;
eval "use Graphics::ColorNames";
unless ($@) {
  tie %NameTable, "Graphics::ColorNames", "X";
}

# use module pluggable, but if that's not installed, just fake it by
# installing a subroutine that just returns the known plugins we ship with
@STANDARD_PLUGINS = qw(
  Test::Image::Plugin::TestingImage
  Test::Image::Plugin::Imlib2
);
# TODO - Module::Pluggable insists on compiling MacOS metadata files. 
# this makes actually hacking on this module incredibly painful. Until
# (a) M::P is better, and (b) we actually _have_ any plugins, I don't want
# this - tinsam 2006/06
#eval "use Module::Pluggable require => 1";
#if ($@) {
  use Test::Image::Plugin::TestingImage;
  use Test::Image::Plugin::Imlib2;
  *plugins = sub { @STANDARD_PLUGINS };
#}

# for Module::Build::Kwalitee, to explain that plugins is documented
# plugins is documented

# We use number compare for some of the comparison operations with size
# we load it with eval to allow these tests to automatically skip
# if it's not installed
eval "use Number::Compare";

=head1 NAME

Test::Image - test an image

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Image;
  
  # create a new image tester
  my $i = Test::Image->new(Image::Imlib2->new("foo.jpg"));
  ok($i, "image ok");  
  $i->size(400,300);  # (see also $i->width, $i->height)

  # you can check pixels using names, rgb hex, or rgb decimal  
  $i->pixel(10,10,"white");           # 10, 10 is white
  $i->pixel(10,10,"ffffff");          # 10, 10 is white
  $i->pixel(10,10,[255,255,255]);     # 10, 10 is white

  $i->pixel_not(10,10,"white");       # 10, 10 isn't white
  $i->pixel_not(10,10,"ffffff");      # 10, 10 isn't white
  $i->pixel_not(10,10,[255,255,255]); # 10, 10 isn't white
  
  # you can use multiple posibilities too
  # check pixel is red, white or blue:
  $i->pixel(10,10,["red", "white", "blue"]);  
  $i->pixel(10,10,["ff0000", "ffffff", "0000ff"]);
  $i->pixel(10,10,[[255,0,0], [255,255,255], [0,0,255]]);
  
  # check that the pixel isn't red white or blue:
  $i->pixel_not(10,10,["red", "white", "blue"]);
  $i->pixel_not(10,10,["ff0000", "ffffff", "0000ff"]);
  $i->pixel_not(10,10,[[255,0,0], [255,255,255], [0,0,255]]);
  
  # row functions (or replace "row" with "col" or "column" for column tests)
  # you can use multiple colours
  $i->row(10, "white");       # row 11 is all white
  $i->row_all(10, "white");   # row 11 is all white
  $i->row_any(10, "white");   # row 11 has a white pixel
  $i->row_none(10, "white");  # row 11 has no white pixels

  # likewise for the whole image (again can use multiple colours)
  $i->all("white");           # whole image is white
  $i->any("white");           # whole image has a white pixel
  $i->none("white");          # whole image has no white pixels
  
  # finally regions (you can use _all, _any or _none too)
  # check the 10x10 region starting at 40,30
  $i->region(40, 30, "r10", "r10", "white");  
  
=head1 DESCRIPTION

This modules is a C<Test::Builder> compatible testing module for testing
images.

Calling the methods of this module prints out Test Anything Protocol
output designed to be processed by Test::Harness during a C<make test>
or C<./Build test>.  This module 'plays nice' with other test modules
also crafted with Test::Builder.  For example, you can happily use this
module in conjunction with Test::More, Test::Exception,
Test::DatabaseRow, etc, and not have to worry about your test numbers
getting confused.

All methods take an optional description as the last arguement.  For example:

  $i->width(400);                  # prints "ok 1 - image width"
  $i->width(400, "1st width");     # prints "ok 2 - 1st width"

=head2 Constructing

=over

=item new($image)

The constructor takes one arguement, the image you want to test.  By default
we only support B<GD::image> and B<Image::Imlib2> objects, but you can provide
further plugins for other image formats by following the PLUGINS guide below.

=back

=cut

sub new {
  my $class = shift;
  my $newimage = shift;
  
  unless (defined $newimage) {
    croak "No image passed";
  }

  my $self = bless {}, $class;

  # find a plugin that will handle the image
  foreach (__PACKAGE__->plugins) {
    my $plugin_instance = $_->new( $newimage );
    next unless $plugin_instance;
    $self->{image} = $plugin_instance;
    return $self;
  }
  
  # couldn't find a plugin that matches
  croak "No plugin found for image passed";
}

=head2 Image Size

There are various tests that can be used to check the magnitude of the
image:

  # check that fred.png is 100 by 300 pixels big
  my $i = Test::Image->new(Image::Imlib2->new( "fred.png" ));
  $i->size(100,300)

If you have C<Number::Compare> installed, then you can use non
absolute values, and you can use magnitudes.

  # image is at least 300x200
  $i->size(">=300", ">=200");
  
  # It's a five megapixel image!
  $i->total_pixels(">=5M");

See L<Number::Compare> for more info.  If you do not have
C<Number::Compare> installed, these style of tests will be
automatically skipped.

=over

=item width($w_pixels)

Test the width of the image

=item height($h_pixels)

Test the height of the image

=item size($w_pixels, $h_pixels)

Test the width and the height of the image at the same time

=item total_size($pixels)

Test the total number of pixels in the image (i.e. width x height)

=back

=cut

sub width {
  my $self = shift;
  return $self->_wh_test("width", "wide", @_);
}

sub height {
  my $self = shift;
  return $self->_wh_test("height", "tall", @_);
}

sub total_size {
  my $self = shift;
  return $self->_wh_test("total size", "in total", @_);  
}

sub _wh_test {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  
  my $self = shift;
  
  # these first two values are just things that, since we're
  # using the same subroutine for width and height, that we
  # can use to call the right thing.  They're not set by
  # the user.
  my $type = shift;   # width/height/total size
  my $what = shift;   # wide/tall
  
  my $wanted = shift;
  my $description = @_ ? shift :
    "image $type";
  
  # get the actual value
  my $got = $type eq "total size"
    ? $self->{image}->width * $self->{image}->height
    : $self->{image}->$type;
  my $got_pixels = $got == 1 ? "pixel" : "pixels";

  # hmm, should we be doing a number compare test here?
  my $wanted_pixels;
  if ($wanted !~ /^\d+$/) {
    
    # skip if we don't have that installed
    unless ($INC{"Number/Compare.pm"}) {
      $tester->skip("No Number::Compare");
      return 1;
    }
    
    # use number compare to do the actual comparison
    my $compare = Number::Compare->new($wanted);
    if ($compare->($got)) {
      $tester->ok(1,$description);
      return 1;
    }
    
    # we've failed
    
    # munge the values for the error message
    $wanted = "'$wanted'";
    $wanted_pixels = "pixels";  # N::C tests are always plural
    
  } else {

    # plain old number
    if ($wanted == $got) {
      $tester->ok(1,$description);
      return 1;
    }
    
    $wanted_pixels = $wanted == 1 ? "pixel" : "pixels";
  }

  # both failure cases fall through to here
  
  $tester->ok(0, $description);
  $tester->diag("Image $got $got_pixels $what, not $wanted $wanted_pixels as expected");
  return 0;
}

sub size {  
  my $self = shift;
  
  my $wanted_w = shift;
  my $wanted_h = shift;
  my $description = @_ ? shift :
    "image size";

  # get the actual values from the image  
  my $got_w = $self->{image}->width;
  my $got_h = $self->{image}->height;

  # check if we're using a complicated value that isn't
  # just a normal number, and test differently if we are
  if ($wanted_w !~ /^\d+$/ || $wanted_h !~ /^\d+$/) {

    # skip if we don't have that installed
    unless ($INC{"Number/Compare.pm"}) {
      $tester->skip("No Number::Compare");
      return 1;
    }

    # use number compare to do the tests.  Note that one
    # of these two may be just a plain old number.  That's
    # fine! Number::Compare will cope with that.

    my $compare_w = Number::Compare->new($wanted_w);
    my $compare_h = Number::Compare->new($wanted_h);
    
    if ($compare_w->($got_w) && $compare_h->($got_h)) {
      $tester->ok(1,$description);
      return 1;
    }
   
    # we've failed!
   
    # put the things that aren't numbers in quotes.  This
    # just makes them look better when we print out the
    # error message below
    $wanted_w = "'$wanted_w'" unless $wanted_w =~ /^\d+$/;
    $wanted_h = "'$wanted_h'" unless $wanted_h =~ /^\d+$/;
   
  } else {
 
    # just a plain old number, we can do that without Number::Compare

    if ($wanted_w == $got_w && $wanted_h == $got_h) {
      $tester->ok(1,$description);
      return 1;
    }
  }  
  
  # both failure cases will fall through to give the same error message
  
  $tester->ok(0, $description);
  $tester->diag("Image size ($got_w,$got_h) not ($wanted_w,$wanted_h) as expected");
  return 0;
}

=head2 Color specification

The testing system can cope with multiple definitions of color.  You can
use an arrayref containing the red, green and blue values (between 0 and 255:)

  my $red = [255,0,0];

You can specify the value in hex if you want too:

  my $red = "ff0000";
  my $red = "FF0000";  # it's case insensitive
  my $red = "ff0000";  # you can put a # at the start if you want

If you install the B<Graphics::ColorNames> module from CPAN then you can
use the name of the color in the "X" color scheme.

  my $red = "red";

Finally you can specify more than one colour by using an array ref containing
the other forms.

  my $rwab = ["red", "white", "blue"];
  my $rwab = ["ff0000", "ffffff", "0000ff"];
  my $rwab = [[255,0,0], [255,255,255], [0,0,255]];

=head2 Checking Single Pixels

The simple C<pixel> test can be used to check the color of a given
pixel either is or isn't a particular color (or set of colors)

  # check the pixel at 40, 30 is red
  $i->pixel(40, 30, [255,0,0])

  # check the pixel at 40, 30 is red or white
  $i->pixel(40, 30, [[255,0,0], [255,255,255]])

  # check the pixel at 40, 30 isn't red
  $i->pixel_not(40, 30, [255,0,0])
  
  # check the pixel at 40, 30 isn't red or white
  $i->pixel_not(40, 30, [[255,0,0], [255,255,255]])
  
This will fail if the pixel isn't the correct color, or the pixel is outside
the image.

You can also use negative numbers to indicate coordinates relative the far
sides of the image in a similar manner to Perl arrays.  For example:

  $i->pixel(-1,-2, "red");

Is the same for a 400x300 image as:

  $i->pixel(399,298, "red");

=cut

# pixel is documented
sub pixel {
  my $self = shift;
  my $image = $self->{image};

  my $x = shift;
  my $y = shift;

  # cope with negative coords
  $x = $self->{image}->width  + $x if $x < 0;
  $y = $self->{image}->height + $y if $y < 0;

  my $wanted_color = shift;
  my $description = @_ ? shift : "pixel test";
  
  my ($test,@colors) = _ctest($wanted_color);
  
  my ($r, $g, $b) = $image->color_at($x, $y);
  unless (defined $r) {
    $tester->ok(0, $description);
    $tester->diag("Coords ($x, $y) outside of image");
    return 0;
  };
  
  unless ($test->($r,$g,$b)) {
    $tester->ok(0, $description);
    $tester->diag("Pixel ($x, $y):");
    $tester->diag("       got: "._color($r,$g,$b));
    $tester->diag("  expected: ".
        join(" or\n            ", @colors));
    return 0;
  }
  
  $tester->ok(1, $description);
  return 1;
}

# pixel_not is documented
sub pixel_not {
  my $self = shift;
  my $image = $self->{image};

  my $x = shift;
  my $y = shift;

  # cope with negative coords
  $x = $self->{image}->width  + $x if $x < 0;
  $y = $self->{image}->height + $y if $y < 0;

  my $wanted_color = shift;
  my $description = @_ ? shift : "pixel not test";
  
  my ($test) = _ctest($wanted_color);
  
  my ($r, $g, $b) = $image->color_at($x, $y);
  unless (defined $r) {
    $tester->ok(0, $description);
    $tester->diag("Coords ($x, $y) outside of image");
    return 0;
  };
  
  unless (!$test->($r,$g,$b)) {
    $tester->ok(0, $description);
    $tester->diag("Pixel ($x, $y) unexpectedly "._color($r,$g,$b));
    return 0;
  }
  
  $tester->ok(1, $description);
  return 1;
}

sub _munge_value {
  my $self = shift;
  
  my $thingy = shift;   # width or height
  my $value = shift;
  my $original = $value;
  
  # simple case where it's just a number
  if ($value =~ /^\d+$/) {
    return ($value, $value);
  }
  
  if ($value =~ s/(-\d+)$//) {
    
    # calculate what that number should have been
    my $temp_value = $self->{image}->$thingy + $1;
    
    # okay, if it was just a negative number, we're done
    return ($temp_value, $temp_value) if !length($value);
    
    $value =~ tr[<>][><];  # reverse the greater than if any
    $value .= $temp_value; # and attach back the number part
  }

  foreach (qw( <0 <-1 )) {
    die "You can't have a constraint of '$_'" if $value eq $_;
  }

  if ($value =~ /^[<][=](\d+)$/)
    { return (0, $1) }
  if ($value =~ /^[<](\d+)$/)
    { return (0, $1 - 1) }
  if ($value =~ /^[>][=](\d+)$/)
    { return ($1, $self->{image}->$thingy - 1) }
  if ($value =~ /^[>](\d+)$/)
    { return ($1 + 1, $self->{image}->$thingy - 1) }
    
  die "Constraint '$value' makes no sense!";
}

sub row {
  my $self = shift;
  $self->_row("all", "row test", @_);
}

sub col {
  my $self = shift;
  $self->_column("all", "column test", @_);
}

sub column {
  my $self = shift;
  $self->_column("all", "column test", @_);
}

# "row_all" is a synonym for "row"
sub row_all {
  my $self = shift;
  $self->_row("all", "row test", @_);
}

# "column_all" is a synonym for "column"
sub column_all {
  my $self = shift;
  $self->_column("all", "column test", @_);
}

# "col_all" is a synonym for "column"
sub col_all {
  my $self = shift;
  $self->_column("all", "column test", @_);
}

sub row_none {  
  my $self = shift;
  $self->_row("none", "row none test", @_);
}

sub column_none {  
  my $self = shift;
  $self->_column("none", "column none test", @_);
}

sub col_none {  
  my $self = shift;
  $self->_column("none", "column none test", @_);
}

sub row_any {  
  my $self = shift;
  $self->_row("any", "row any test", @_);
}

sub column_any {  
  my $self = shift;
  $self->_column("any", "column any test", @_);
}

sub col_any {  
  my $self = shift;
  $self->_column("any", "column any test", @_);
}

sub _row {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $self = shift;
  
  # values defined in the methods
  my $mode = shift;
  my $default_description = shift;
  
  # user supplied values
  my $row = shift;
  my $color = shift;
  my $description = @_ ? shift : $default_description;
    
  # work out what rows we're looking at
  my ($y1, $y2) = $self->_munge_value("height",$row);

  $self->_region(
    x1 => 0, x2 => $self->{image}->width - 1,
    y1 => $y1, y2 => $y2,
    color => $color,
    description => $description,
    mode => $mode,
  )
}

sub _column {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $self = shift;
  
  # values defined in the methods
  my $mode = shift;
  my $default_description = shift;
  
  # user supplied values
  my $column = shift;
  my $color = shift;
  my $description = @_ ? shift : $default_description;
    
  # work out what columns we're looking at
  my ($x1, $x2) = $self->_munge_value("width",$column);

  $self->_region(
    y1 => 0, y2 => $self->{image}->height - 1,
    x1 => $x1, x2 => $x2,
    color => $color,
    description => $description,
    mode => $mode,
  )
}

# this tests a region.  It's the routine that all the other pixel based
# tests (apart from the basic "pixel" and "pixel_not" tests call
sub _region {
  # increase the T::B::Level so that errors come from the right line
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $self = shift;
  my %args = @_;

  my $image = $self->{image};
  
  my $description = $args{description};
  my $wanted_color = $args{color};
  my $mode = $args{mode};

  # get the coords.  x1 is the smaller x coord, x2 is the largest.
  # same thing for y coords.  x1 and x2 are inclusive.
  my ($x1, $x2, $y1, $y2) = map { $args{ $_ } }
   qw( x1   x2   y1   y2);
      
  # get a test for this color
  my ($test,@colors) = _ctest($wanted_color);

  # loop left -> right, top->bottom through our region
  my ($i, $j);
  for ($j = $y1; $j <= $y2; $j++) {
    for ($i = $x1; $i <= $x2; $i++) {

      # grab a pixel
      my ($r, $g, $b) = $image->color_at($i, $j);

      # check it's inside
      # this should be probably rolled out of the loop
      unless (defined $r) {
        $tester->ok(0, $description);
        $tester->diag("Coords ($i, $j) outside of image");
        return 0;
      };
      
      # this should probably be totally unrolled
      
      if ($mode eq "none" && $test->($r,$g,$b)) {
        $tester->ok(0, $description);
        $tester->diag("Pixel ($i, $j) unexpectedly "._color($r,$g,$b));
        return 0;
      }

      if ($mode eq "all" && !$test->($r,$g,$b)) {
        $tester->ok(0, $description);
        $tester->diag("Pixel ($i, $j):");
        $tester->diag("       got: "._color($r,$g,$b));
        $tester->diag("  expected: ".
            join(" or\n            ", @colors));
        return 0;
      }

      if ($mode eq "any" && $test->($r,$g,$b)) {
        $tester->ok(1, $description);
        return 1;
      }
    }
  }

  if ($mode eq "any") {
      $tester->ok(0, $description);
      $tester->diag("No pixel correct color");
      $tester->diag("  expected: ".
          join(" or\n            ", @colors));
      return 0;
  }
  
  # got this far?  must have succeeded
  $tester->ok(1, $description);
  return 1;
}

# this returns a function that can check for the passed colour
# so calling
#
#  my $foo = _ctest([255,0,0])
#  $foo->(255,0,0);                # check red is red
#
#  my $foo = _ctest([255,0,0], [0,255,0])
#  $foo->(255,0,0);                # check red is red or blue

# TODO: make this function only use arrayrefs.  Make sure we do colour
# conversion *before* we hand things to it (much much more efficent
# in the case we have multiple links)

sub _ctest {
  my $tests = shift;

  # note that this is very careful to allow things like objects that
  # stringify to be used okay
  
  # case where we don't pass an array
  # meaning it's "white" or "ffffff" or something
  unless (ref $tests && ref($tests) eq "ARRAY") {
    my ($wr, $wg, $wb) = _rgb($tests);
    return sub { $wr == $_[0] && $wg == $_[1] && $wb == $_[2] }, "[$wr,$wg,$wb]";
  }

  # case where we pass an array and the first element looks like a number
  # meaning it's [255,0,0], etc
  if (ref $tests && ref($tests) eq "ARRAY" && defined $tests->[0] && $tests->[0] =~ /^\d+$/) {
    my ($wr, $wg, $wb) = _rgb($tests);
    return sub { $wr == $_[0] && $wg == $_[1] && $wb == $_[2] }, "[$wr,$wg,$wb]";
  }

  # must be an array of tests then.  Try them each in turn.
  my @colors = map { [ _rgb( $_ ) ] } @$tests;
  return sub {
    foreach (@colors) {
      return 1 if $_->[0] == $_[0] && $_->[1] == $_[1] && $_->[2] == $_[2];
    }
    return 0;
  }, map { _color(@$_) } @colors;
}


# return the color in $r, $g, $b for what's passed in
# you can pass in "#ff0000", or "ff0000", or [255,0,0] or "red"
sub _rgb {
  my $value = shift;
  unless (defined $value)
    { croak "Undef passed as expected color" }

  return @$value if ref $value && ref $value eq "ARRAY";

  # convert from hex and return if we can
  if ($value =~ /^#?([a-fA-F09]{2})([a-fA-F09]{2})([a-fA-F09]{2})$/) {
    return hex $1, hex $2, hex $3;  # loop unrolled by hand :-)
  }
  
  if (!$INC{"Graphics/ColorNames.pm"})
    { die "Can't determine color for '$value': Graphics::ColorNames not installed" }
  
  my $hex = $NameTable{ $value };
  die "Can't determine color for '$value'" unless $hex;
  return Graphics::ColorNames::hex2tuple($hex);
}

# return a string that describes the colour
sub _color {
  my ($r, $g, $b) = @_;
  
  my $string = "";
  if ($INC{"Graphics::ColorNames"}) {
     # TODO: modify $string so it has the colour name in here    
  }
  return "$string\[$r,$g,$b]";
}

sub region {
  my $self = shift;
  return $self->_r("all","image region", @_);
}

sub region_all {
  my $self = shift;
  return $self->_r("all","image region", @_);
}

sub region_any {
  my $self = shift;
  return $self->_r("any","image region any", @_);
}

sub region_none {
  my $self = shift;
  return $self->_r("none","image region none", @_);
}

sub _r {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $self = shift;
  
  # values defined in the methods
  my $mode = shift;
  my $default_description = shift;
  
  # user supplied values
  my ($x1, $y1, $x2, $y2) = splice(@_, 0, 4);
  my $color = shift;
  my $description = @_ ? shift :
    "image region";
  
  # convert negative coords into positive ones
  
  foreach ($x1, $x2) {
    $_ = $self->{image}->width + $_ if $_ < 0;
  }

  foreach ($y1, $y2) {
    $_ = $self->{image}->height + $_ if $_ < 0;
  }
  
  # make ?1 smaller than ?2 if it's not
  
  if ($x2 < $x1)
    { ($x1, $x2) = ($x2, $x1) }

  if ($y2 < $y1)
    { ($y1, $y2) = ($y2, $y1) }

  # examine the region
  
  $self->_region(
     y1 => $y1,
     y2 => $y2,
     x1 => $x1,
     x2 => $x2,
     color => $color,
     description => $description,
     mode => $mode,
   )
}

=head1 PLUGINS

This module can be extended to allow you to test arbitary image formats.
To do this you need to implement a module called Test::Image::Plugin::*
which supports the following methods:

=over

=item new( $image )

A constructor.  Return an object if you're prepared to handle the image
that's passed in.  Return C<undef> if the image isn't something you'll
handle (hopefully some other plugin will.)

=item width

=item height

Instance methods.  These methods should return the width and height of
the image.

=item color_at($x, $y)

Instance method should return a three element list that contains the
red, green and blue value.  This should return the empty list if the
pixel specified is outside the image.

=back

In order for these plugins to work you must first install
C<Module::Pluggable> from CPAN.  If you're writing C<Test::Image> plugin
and distributing it on CPAN, you should add C<Module::Pluggable> to your
required modules in C<Makefile.PL> / C<Build.PL>

=head1 BUGS

If you don't have module compare installed and you pass a string to
any of the image size routines that isn't just a plain old number
then that test will be skipped if you don't have C<Number::Compare>
installed, even if that string is just junk.  This is to allow this
module to be compatible with future improvements to C<Number::Compare>.
You are encouraged to have C<Number::Compare> installed when
developing tests on your own system.

We should probably automatically skip named colors if you don't
have C<Graphics::ColorNames> installed.  We don't yet.

Please report any further bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Image>

=head1 OTHER BUGS

British Airways doesn't have TIVO like movies like Virgin Atlantic.  Or,
if it does, it doesn't have it on B<this> flight, and that's all I really
care about at the momement.

In the movie "Failure To Launch" taking of your facemask while playing
paintball is insanely dangerous.  It also makes me want to shout lock
off! when Ace is belaying.  I don't find climbing accidents funny.
Who's belaying the guy from Alias in that scene anyway?  Despite
all that, I quite enjoyed the film.

I somehow ended up with some of my sister in law's music in iTunes and
now when I'm coding I sometime randomly get some Christina Aguilera.

Coding on a plane is very hard to do, as you don't have the arm room
to type properly.

This said, I don't get a chance to listen to my entire Chemical
Brothers collection in one go uninterrupted very often.

=head1 AUTHOR

Written by Mark Fowler, E<lt>mark@twoshortplanks.comE<gt>. Please see
L<http://twoshortplanks.com/contact/> for details of how to contact me.

Copyright Fotango 2006-2007.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Image::GD>, for an alternative way of testing GD Images.

L<Exporter>

L<The Test Anything Protocol|http://search.cpan.org/dist/Test-Harness/lib/Test/Harness/TAP.pod>

=cut

1;

