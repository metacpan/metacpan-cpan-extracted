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

run 'valid-string-01', "hello";
run 'valid-string-02', "hello\tworld";
run 'valid-string-03', "hello\nworld";
run 'valid-string-04', 'hello"world';
run 'valid-string-05', "こんにちは世界";
run 'valid-string-06', "こんにちは世界";
run 'valid-string-07', join "", @text;
run 'valid-string-08', join "\n", @text;

done_testing;

