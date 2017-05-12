use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();
use utf8;

my @text = (
    q|Lorem ipsum dolor sit amet...|,
    q|Duis aute irure dolor in reprehenderit...|
);

run 'valid-map-01', {};
run 'valid-map-02', { hello => "world" };
run 'valid-map-03', { 'he"llo' => "world" };
run 'valid-map-04', {
    foo   => "bar",
    hello => {
        world => {
            isTrue => JSON::true
        }
    }
};

run 'valid-map-05', {
    foo   => "bar",
    hello => {
        world => {
            isTrue => JSON::true
        }
    }
};

run 'valid-map-06', { "こんにちは" => "世界" };
run 'valid-map-07', { "こんにちは" => "世界" };
run 'valid-map-08', { "こんにちは" => "世界" };

run 'valid-map-09', {
    foo  => "bar",
    baz  => "Lorem ipsum dolor sit amet... Duis aute irure dolor in reprehenderit...",
    quux => "Lorem ipsum dolor sit amet...\nDuis aute irure dolor in reprehenderit...",
};

done_testing;

