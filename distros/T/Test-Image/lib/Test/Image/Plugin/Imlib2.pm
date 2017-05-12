package Test::Image::Plugin::Imlib2;

use strict;
use warnings;

use Scalar::Util qw( blessed );
use Image::Imlib2;

our $VERSION = "0.01";

=head1 NAME

Test::Image::Plugin::Imlib2 - Test real images using Imlib2

=head1 DESCRIPTION


=over

=item new

=item width

=item height

=item color_at($x,$y)

=back

See L<Test::Image> for more details of what these should do.

=cut

sub new {
  my $class = shift;
  my $image = shift;
  my $imlib;
  
  if (blessed $image and $image->isa("Image::Imlib2") ){
    $imlib = $image;
  } elsif (-f $image) {
    $imlib = Image::Imlib2->load( $image );
  } else {
    # TODO - this API is annoying. Dieing here is _wrong_, because if
    # this plugin is installed there's no fallback strategy for the other
    # plugins, but how else am I supposed to indicate errors? The thing
    # should fail silently until you get everything right?
    die "Can't deal with image $image";
  }
  return bless { image => $imlib }, $class;
}

sub width  {
  my $self = shift;
  return $self->{image}->get_width();
}

sub height {
  my $self = shift;
  return $self->{image}->get_height();
}

sub color_at {
  my ($self, $x, $y) = @_;
  return undef if $x >= $self->width or $y >= $self->height or $x < 0 or $y < 0;
  return $self->{image}->query_pixel($x, $y);;
}

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Image::Plugin::TestingImage>

=head1 AUTHOR

Written by Mark Fowler, E<lt>mark@twoshortplanks.comE<gt>. Please see
L<http://twoshortplanks.com/contact/> for details of how to contact me.

Copyright Fotango 2006.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO



=cut

1;

