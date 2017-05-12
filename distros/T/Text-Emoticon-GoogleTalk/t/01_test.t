use strict;
use Test::More;
use Text::Emoticon::GoogleTalk;

my $text = "blah <3 blah \\m/";

my @Tests = (
    # args, filtered_text
    [ { imgbase => '.' },
      qq(blah <img src="./heart.gif" /> blah <img src="./rockout.gif" />) ],
    [ { imgbase => "http://example.com/img" },
      qq(blah <img src="http://example.com/img/heart.gif" /> blah <img src="http://example.com/img/rockout.gif" />) ],
    [ { imgbase => '.', xhtml => 0 },
      qq(blah <img src="./heart.gif"> blah <img src="./rockout.gif">) ],
    [ { imgbase => '.', class => "emo" },
      qq(blah <img src="./heart.gif" class="emo" /> blah <img src="./rockout.gif" class="emo" />) ],
);

plan tests => scalar(@Tests);

for (@Tests) {
    my($args, $filtered) = @$_;
    my $emoticon = Text::Emoticon::GoogleTalk->new(%$args);
    is $emoticon->filter($text), $filtered;
}
