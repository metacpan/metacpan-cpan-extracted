package URI::Title::Image;
$URI::Title::Image::VERSION = '1.902';
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
  my $name = ( split m{/}, $url )[-1];

  my ($x, $y) = imgsize(\$data);
  $type =~ s!^[^/]*/!!;
  $type =~ s!^x-!!;
  return $x && $y
    ? "$name ($type ${x}x${y})"
    : "$name ($type)";
}

1;

__END__

=for Pod::Coverage::TrustPod types title

=head1 NAME

URI::Title::Image - get titles of images

=head1 VERSION

version 1.902

=cut
