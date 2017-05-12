# -*- cperl -*-
#
# (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
#
use Image::Magick 5.41;

my $file = "C:\\Documents and Settings\\jb\\My Documents\\vancouver06.jpg";
my $img = new Image::Magick;
$img->Read($file);
my $h = $img->GetAttribute('height');
my $w = $img->GetAttribute('width');
my $g = $img->GetAttribute('geometry');
print "JPEG size $h x $w ($g)\n";

use Image::Size qw(:all);
my ($w, $h, $err) = imgsize($file);

print "JPEG size $h x $w\n";

__END__
map {
  print "$_ => ". $img->GetAttribute($_) . "\n";
} qw/base-columns base-filename base-rows class colors columns directory gamma geometry height label matte error montag maximum-error mean-error rows signature texture type units view width x-resolution y-resolution/;
