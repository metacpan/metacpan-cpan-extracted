package URI::Title::Image;
$URI::Title::Image::VERSION = '1.901';
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

sub title {
  my ($class, $url, $data, $type) = @_;

  my ($x, $y) = imgsize(\$data);
  $type =~ s!^[^/]*/!!;
  $type =~ s!^x-!!;
  return $type unless $x && $y;
  return "$type ($x x $y)";
}

1;

__END__

=for Pod::Coverage::TrustPod types title

=head1 NAME

URI::Title::Image - get titles of images

=cut
