#!perl
use strict;
use warnings;

use LWP::UserAgent;
use Imager;
use Text::AAlib qw(:all);

my $url = 'http://dipinkrishna.com/wp-content/uploads/2010/12/perl_logo.jpg';
my $ua = LWP::UserAgent->new;
my $res = $ua->get($url);
unless ($res->is_success) {
    die "Can't download $url";
}

my $img = Imager->new();
$img->read(data => $res->content) or die "Can't read image";

my ($width, $height) = ($img->getwidth, $img->getheight);

my $aa = Text::AAlib->new(
    width  => $width,
    height => $height,
    mask   => AA_REVERSE_MASK,
);

$aa->put_image(image => $img);
print $aa->render();
