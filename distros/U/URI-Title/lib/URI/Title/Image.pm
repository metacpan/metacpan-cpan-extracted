package URI::Title::Image;
$URI::Title::Image::VERSION = '1.903';
use warnings;
use strict;

use Image::Size;

sub types {(
  'image/gif',
  'image/jpg',
  'image/jpeg',
  'image/png',
  'image/x-png',
)}

sub pnginfo {
  my ($data_ref) = @_;
  my ($x, $y, $title) = (0, 0, '');
  if ( eval { require Image::ExifTool } ) {
    my $info = Image::ExifTool::ImageInfo($data_ref);
    ($x, $y, $title) = ($info->{ImageWidth}, $info->{ImageHeight}, $info->{Title});
  }
  elsif( eval { require Image::PNG::Libpng } ) {
    my $png = Image::PNG::Libpng::read_from_scalar($$data_ref);
    $x = $png->get_image_width();
    $y = $png->get_image_height();
    my $text_chunks = $png->get_text();
    for (@$text_chunks) {
      if ($_->{key} eq "Title") {
        $title = $_->{text};
        last;
      }
    }
  }
  else {
    ($x, $y) = imgsize($data_ref);
  }
  return ($x, $y, $title);
}

sub title {
  my ($class, $url, $data, $type) = @_;

  $type =~ s!^[^/]*/!!;
  $type =~ s!^x-!!;
  my $title = "";
  my $x = 0;
  my $y = 0;
  if ( $type =~ /png/ ) {
    ($x, $y, $title) = pnginfo(\$data);
  }
  else {
    ($x, $y) = imgsize(\$data);
  }
  $title ||= ( split m{/}, $url )[-1];
  return $x && $y
    ? "$title ($type ${x}x${y})"
    : "$title ($type)";
}

1;

__END__

=for Pod::Coverage::TrustPod types title pnginfo

=head1 NAME

URI::Title::Image - get titles of images

=head1 VERSION

version 1.903

=cut
