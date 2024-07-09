# Copyright 2011, 2012, 2015, 2017, 2024 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.


package Test::Without::GD;
use 5.004;  # for ->can()
use strict;

use vars '$VERSION';
$VERSION = 8;

# uncomment this to run the ### lines
#use Smart::Comments;


sub _croak {
  require Carp;
  Carp::croak(@_);
}

sub import {
  my $class = shift;
  foreach (@_) {
    if (/^-/) {
      my $method = 'without_' . substr($_,1);
      if ($class->can($method)) {
        $class->$method();
        next;
      }
    }
    _croak 'Unrecognised without option: ',$_;
  }
}

my %replaced;

sub unimport {
  foreach my $name (keys %replaced) {
    local $^W = 0;
    *$name = delete $replaced{$name};
  }
}

#------------------------------------------------------------------------------
sub without_jpeg {
  _without_func('GD::Image::_newFromJpeg');
  _without_func('GD::Image::newFromJpegData');
  _without_func('GD::Image::jpeg');
  if (my $coderef = GD::Image->can('jpeg')) {
    die "Oops, GD::Image->can('jpeg') still true: $coderef";
  }
}

#------------------------------------------------------------------------------
sub without_png {
  _without_func('GD::Image::_newFromPng');
  _without_func('GD::Image::newFromPngData');
  _without_func('GD::Image::png');
  if (my $coderef = GD::Image->can('png')) {
    die "Oops, GD::Image->can('png') still true: $coderef";
  }
}

#------------------------------------------------------------------------------
sub without_gif {
  _without_func('GD::Image::_newFromGif');
  _without_func('GD::Image::newFromGifData');
  _without_func('GD::Image::gif');
  if (my $coderef = GD::Image->can('gif')) {
    die "Oops, GD::Image->can('gif') still true: $coderef";
  }
}

#------------------------------------------------------------------------------

sub without_gifanim {
  _change_func('GD::Image::gifanimbegin', \&_Test_Without_GD__gifanimbegin);
  _change_func('GD::Image::gifanimadd',   \&_Test_Without_GD__gifanimadd);
  _change_func('GD::Image::gifanimend',   \&_Test_Without_GD__gifanimend);
  if (eval { GD::Image->gifanim; 1 }) {
    die "Oops, GD::Image->gifanim() still works";
  }
}
# prototypes here per GD.xs, but presumably have no effect since they're
# supposed to be called as methods
sub _Test_Without_GD__gifanimbegin ($$$) {
  # die per gdgifanimbegin() in GD.xs when HAVE_ANIMGIF false
  die "libgd 2.0.33 or higher required for animated GIF support";
}
sub _Test_Without_GD__gifanimadd ($$$$$$$) {
  # die per gdgifanimadd() in GD.xs when HAVE_ANIMGIF false
  die "libgd 2.0.33 or higher required for animated GIF support";
}
sub _Test_Without_GD__gifanimend ($) {
  # die per gdgifanimbegin() in GD.xs when HAVE_ANIMGIF false
  die "libgd 2.0.33 or higher required for animated GIF support";
}

#------------------------------------------------------------------------------

sub without_xpm {
  _change_func('GD::Image::newFromXpm', \&_Test_Without_GD__newFromXpm);
}
# prototype here per GD.xs, but presumably has no effect since it's supposed
# to be called as a method
sub _Test_Without_GD__newFromXpm ($$) {
  ### _Test_Without_GD__newFromXpm() ...
  # empty return and $@ per gdnewFromXpm() in GD.xs when HAVE_XPM false
  $@ = "libgd was not built with xpm support\n";
  return;
}

#------------------------------------------------------------------------------

sub _without_func {
  my ($name) = @_;
  require GD;
  unless ($replaced{$name}) {
    ### remove: $name
    $replaced{$name} = \&$name;
    require Sub::Delete;
    Sub::Delete::delete_sub($name);
  }
}
sub _change_func {
  my ($name, $new_coderef) = @_;
  ### _change_func(): $name
  ### $new_coderef
  ### name prototype: prototype $name
  ### new prototype : prototype $new_coderef

  require GD;
  unless ($replaced{$name}) {
    $replaced{$name} = \&$name;
    no strict 'refs';
    local $SIG{'__WARN__'} = sub {};
    *$name = $new_coderef;
  }
}

1;
__END__

=for stopwords Ryde Test-VariousBits libgd GD's fakery PNG JPEG GIF entrypoints XPM configs recognises

=head1 NAME

Test::Without::GD - pretend GD is without some file formats

=head1 SYNOPSIS

 # command line
 perl -MTest::Without::GD=-gif,-png myprog.pl ...

 # or in script
 use Test::Without::GD '-jpeg';

 # or by method
 use Test::Without::GD;
 Test::Without::GD->without_png();

=head1 DESCRIPTION

This module mangles the C<GD> module to pretend that some of its file
formats are not available, as can happen if libgd was built without some of
its supporting libraries, or configs set in the C<GD> module, etc.

This can be used for testing to check how module code etc behaves without
some of GD's things, or to exercise F<.t> scripts to see that they skip
checks for features not available.

The mangling is done by deleting or replacing selected C<GD::Image> methods.
Deleting uses C<Sub::Delete> (perhaps that will change).  There's an
experimental C<no Test::Without::GD> which tries to restore C<GD::Image>
back to normal operation.  Is there any value in that?  Usually the fakery
will be for the duration of a script etc.

=head1 IMPORT OPTIONS

The module import recognises the following options

    -png
    -jpeg
    -gif
    -gifanim
    -xpm

They correspond to the C<without_png()> etc functions below.  So for example
to run a program pretending PNG is not available,

    perl -MTest::Without::GD=-png myprog.pl ...

Or when using the usual C<ExtUtils::MakeMaker> test harness,

    HARNESS_PERL_SWITCHES="-MTest::Without::GD=-png" make test

The options can be applied from a script too (or the functions below used),

    use Test::Without::GD '-png';

=head1 FUNCTIONS

=over

=item C<Test::Without::GD-E<gt>without_png()>

=item C<Test::Without::GD-E<gt>without_jpeg()>

=item C<Test::Without::GD-E<gt>without_gif()>

Pretend that PNG, JPEG or GIF format is not available.  This means removing
the respective C<GD::Image> methods,

    _newFromPng()    newFromPngData()   png()
    _newFromJpeg()   newFromJpegData()  jpeg()
    _newFromGif()    newFromGifData()   gif()

as is the case when GD is built without C<HAVE_PNG>, C<HAVE_JPEG> or
C<HAVE_GIF>.

The documented entrypoints C<newFromPng()>, C<newFromJpeg()> and
C<newFromGif()> in fact remain, but their underlying C<_newFromPng()> etc
are removed causing them to die.

=item C<Test::Without::GD-E<gt>without_gifanim()>

Pretend that animated GIF support is not available.  This means replacing
C<GD::Image> methods

    gifanimbegin(), gifanimadd(), gifanimend()

with instead

    sub {
      die "libgd 2.0.33 or higher required for animated GIF support";
    }

as is the case when GD is built without C<HAVE_ANIMGIF>.

=item C<Test::Without::GD-E<gt>without_xpm()>

Pretend that XPM format is not available.  This means replacing C<GD::Image>
method

    newFromXpm()

with instead

    sub {
      $@ = "libgd was not built with xpm support\n";
      return;
    }

as is the case when GD is built without C<HAVE_XPM>.

=back

=head1 SEE ALSO

L<GD>, L<Sub::Delete>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/test-variousbits/index.html>

=head1 COPYRIGHT

Copyright 2011, 2012, 2015, 2017, 2024 Kevin Ryde

Test-VariousBits is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3, or (at your option) any
later version.

Test-VariousBits is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Test-VariousBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
