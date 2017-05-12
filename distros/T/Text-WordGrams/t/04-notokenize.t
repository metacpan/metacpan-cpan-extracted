#!perl -T

use Test::More tests => 17;
use Text::WordGrams;

my $text;
{
  undef $/;
  $text = <DATA>;
}

my $data = word_grams({tokenize => 0},$text);

is ($data->{'foo bar'}, undef);

is($data->{'Lorem ipsum'}, 1);
is($data->{'lorem ipsum'}, 1);
is($data->{'amet, consectetuer'}, 1);
is($data->{'pretium massa'}, 1);

is($data->{"cursus, tellus"}, 2);
is($data->{"tellus nulla"}, 2);

$data = word_grams({tokenize => 0, ignore_case => 1}, $text);

is ($data->{'foo bar'}, undef);

is($data->{'Lorem ipsum'}, undef);
is($data->{'lorem ipsum'}, 2);
is($data->{'amet, consectetuer'}, 1);
is($data->{'pretium massa'}, 1);

is($data->{"cursus, tellus"}, 2);
is($data->{"tellus nulla"}, 2);


$data = word_grams({tokenize => 0, size => 3}, $text);

is($data->{'pretium massa'}, undef);
is($data->{'Lorem ipsum dolor'}, 1);
is($data->{'cursus, tellus nulla'}, 2);

__DATA__
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam pretium
massa dignissim enim. Proin condimentum ligula a lacus. Cras a leo vel
est interdum fermentum. Sed ac dolor. Suspendisse sodales, enim a
sagittis cursus, tellus nulla pulvinar eros, aliquam vulputate tellus
sagittis cursus, tellus nulla pulvinar eros, aliquam vulputate tellus
sem eu magna. Pellentesque habitant morbi tristique senectus et netus
et malesuada fames ac turpis egestas. Class aptent taciti sociosqu ad
litora torquent per conubia lorem ipsum nostra, per inceptos
hymenaeos. Praesent ut lorem. In pulvinar. Integer vitae mi. Vivamus
sed nisi ut nibh congue rutrum. In auctor, diam et ultricies sodales,
sapien orci congue tortor, vel pulvinar est sapien vel nisl. Ut dui.



