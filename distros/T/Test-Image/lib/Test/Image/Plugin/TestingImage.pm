package Test::Image::Plugin::TestingImage;

use strict;
# use warnings; # I want this to work with old perls!

our $VERSION = "0.01";

=head1 NAME

Test::Image::Plugin::TestingImage - for testing only

=head1 SYNOPSIS

  use Test::Image;
  my $red   = [255,0,0];
  my $green = [0,255,0];
  my $white = [255,255,255];
  test_image([
    [ $red, $red, $white, $white, $green, $green ],
    [ $red, $red, $white, $white, $green, $green ],
    [ $red, $red, $white, $white, $green, $green ],
  ]);

=head1 DESCRIPTION

This is an image designed for testing.  This defines the standard
method that you need to implement in order to provide an image.

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
  return undef unless ref $image && ref $image eq "ARRAY";
  
  
  return bless { 
    image  => $image,
    width  => scalar(@{ $image->[0] }),
    height => scalar(@{ $image }),
  }, $class;
}

sub width  { $_[0]->{width}  }
sub height { $_[0]->{height} }

sub color_at {
 my $self = shift;
 my $image = $self->{image};
 
 my $x = shift;
 my $y = shift;
 
 die "'$x' not a valid value for x"
   unless $x =~ /^\d+$/;

 die "'$y' not a valid value for y"
     unless $y =~ /^\d+$/;

 return unless $self->{image}->[$y][$x];
 return @{ $self->{image}->[$y][$x] };
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

