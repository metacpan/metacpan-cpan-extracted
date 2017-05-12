use strict;
use warnings;
use Test::More tests => 124;
use Text::Amuse::Output;
use File::Spec::Functions;
use Data::Dumper;

my $obj = Text::Amuse::Output->new(
                                   document => [],
                                   format => "html",
                                  );

foreach my $url ("http://example.org",
                 "http://example.org/",
                 "http://example.org/my/path/hello.html",
                 'http://example.org/my/path/hello.html?q=234&b=234%sdf',
                 "http://example.org:23423",
                 "http://example.org:23423/",
                 "http://example.org/?q=234&b=asdlklfj#helllo") {
    ok($url =~ $obj->url_re, "$url matches url");
    my $matched = $1;
    is($matched, $url, "$url is an url");
    foreach my $puct (")", ".", ";", "}", "]", " ", "\n") {
        my $string = $puct . $url . $puct;
        ok($string =~ $obj->url_re, "$string matches");
        is($1, $url, "$url eq $1");
    }
}

foreach my $image (
                   'float.jpg 30',
                   'float.png 30 r',
                   'float.png 30 f',
                   'float.png  f',
                   'float.png  r',
                   'float.png    80f',
                   'float.png 23 l',
                   'float.png',
                   'float.png r',
                   'float.png ',
                  ) {
    ok($obj->find_image($image), "<$image> is seen as an image");
}

foreach my $image (
                   ' float.png',
                   'flap.pdf',
                  ) {
    ok(!$obj->find_image($image), "<$image> is not seen as an image");
}

