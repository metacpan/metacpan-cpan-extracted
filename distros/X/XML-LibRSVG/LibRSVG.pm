# $Id: LibRSVG.pm,v 1.3 2001/10/30 23:05:30 matt Exp $

package XML::LibRSVG;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.01';

require DynaLoader;

@ISA = ('DynaLoader');

XML::LibRSVG->bootstrap( $VERSION );

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = bless \%opts, $class;
    return $self;
}

sub png_from_file {
    my $self = shift;
    my ($filename) = @_;
    return $self->png_from_file_at_zoom($filename, 1);
}

sub write_png_from_file {
    my $self = shift;
    my ($filename, $output_file) = @_;
    return $self->write_png_from_file_at_zoom($filename, $output_file, 1);
}

1;
__END__

=head1 NAME

XML::LibRSVG - Interface to gnome's librsvg

=head1 SYNOPSIS

  use XML::LibRSVG;

  my $rsvg = XML::LibRSVG->new();
  my $png = $rsvg->png_from_file($filename);
  my $larger_png = $rsvg->png_from_file_at_zoom($filename, 2);
  my $smaller_png = $rsvg->png_from_file_at_size($filename, 40, 40);
  $rsvg->write_png_from_file($svg, $output_file);
  $rsvg->write_png_from_file_at_zoom($svg, $of, 2);
  $rsvg->write_png_from_file_at_size($svg, $of, 40, 40);

=head1 DESCRIPTION

At the moment all this module allows you to do is convert SVG's to
PNG's in various ways. Enjoy :-)

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

XML::LibXML

=cut
