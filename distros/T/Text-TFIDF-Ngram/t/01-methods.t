#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Text::TFIDF::Ngram';

my $obj = new_ok 'Text::TFIDF::Ngram';

my $got = $obj->files;
is $got, undef, 'no files';

$got = $obj->stopwords;
is $got, 1, 'stopwords';

# https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Example_of_tf%E2%80%93idf

my $files = [qw( t/1.txt t/2.txt )];

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => $files,
    size => 1,
    stopwords => 0,
];

my $expected = $files;
$got = $obj->files;
is_deeply $got, $expected, 'files';

my $filename = 't/1.txt';
my $term     = 'this';

$expected = {
    this   => 1,
    is     => 1,
    a      => 2,
    sample => 1,
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$expected = 0.2;
$got = $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = 0;
$got = $obj->idf($term);
is $got, $expected, 'IDF';

$expected = undef;
$got = $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$filename = 't/2.txt';
$term     = 'example';

$expected = {
    this    => 1,
    is      => 1,
    another => 2,
    example => 3,
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$expected = 0.143;
$got = sprintf '%.3f', $obj->tf( $filename, 'this' );
is $got, $expected, 'TF';

$expected = 0.429;
$got = sprintf '%.3f', $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = 0.301;
$got = sprintf '%.3f', $obj->idf($term);
is $got, $expected, 'IDF';

$expected = 0.129;
$got = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$term = 'foo';

$expected = 0;
$got = $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = undef;
$got = $obj->idf($term);
is $got, $expected, 'IDF';

$got = $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$expected = {
    't/2.txt' => {
        another => '0.086',
        example => '0.129',
    },
    't/1.txt' => {
        a      => '0.120',
        sample => '0.060',
    }
};
$got = $obj->tfidf_by_file;
for my $file ( keys %$got ) {
    for my $word ( keys %{ $got->{$file} } ) {
        $got->{$file}{$word} = sprintf '%.3f', $got->{$file}{$word};
    }
}
is_deeply $got, $expected, 'tfidf_by_file';

$files = [qw( t/3.txt t/4.txt )];

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => $files,
    size => 2,
    stopwords => 0,
];

$filename = 't/3.txt';
$term     = 'as snow';

$expected = {
    'Mary had'    => 1,
    'had a'       => 1,
    'a little'    => 1,
    'little lamb' => 1,
    'Its fleece'  => 1,
    'fleece was'  => 1,
    'was white'   => 1,
    'white as'    => 1,
    'as snow'     => 1,
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$expected = 0.111;
$got = sprintf '%.3f', $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = 0.301;
$got = sprintf '%.3f', $obj->idf($term);
is $got, $expected, 'IDF';

$expected = 0.033;
$got = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$files = [qw( t/1.txt t/2.txt )];

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => $files,
    size => 1,
    stopwords => 1,
];

$filename = 't/1.txt';
$term     = 'sample';

$expected = 1;
$got = $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = 0.301;
$got = sprintf '%.3f', $obj->idf($term);
is $got, $expected, 'IDF';

$expected = 0.301;
$got = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$expected = { sample => 1, };
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => $files,
    size => 2,
    stopwords => 0,
];

$term = 'a sample';

$expected = 0.25;
$got = $obj->tf( $filename, $term );
is $got, $expected, 'TF';

$expected = 0.301;
$got = sprintf '%.3f', $obj->idf($term);
is $got, $expected, 'IDF';

$expected = 0.075;
$got = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $got, $expected, 'TFIDF';

$expected = {
    'this is'  => 1,
    'is a'     => 1,
    'a a'      => 1,
    'a sample' => 1,
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$filename = 't/4.txt';

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => [$filename],
    size => 2,
    stopwords => 0,
    punctuation => '',
];
$expected = {
    'lamb .'      => 1,
    'was white'   => 1,
    'as cotton'   => 1,
    '. Its'       => 1,
    'little lamb' => 1,
    'Mary had'    => 1,
    'cotton .'    => 1,
    'Its fleece'  => 1,
    'had a'       => 1,
    'a little'    => 1,
    'white as'    => 1,
    'fleece was'  => 1
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => [$filename],
    size => 2,
    stopwords => 0,
    lowercase => 1,
];
$expected = {
    'was white'   => 1,
    'as cotton'   => 1,
    'little lamb' => 1,
    'mary had'    => 1,
    'its fleece'  => 1,
    'had a'       => 1,
    'a little'    => 1,
    'white as'    => 1,
    'fleece was'  => 1
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

$filename = 't/5.txt';

$obj = new_ok 'Text::TFIDF::Ngram' => [
    files => [$filename],
    size => 2,
    stopwords => 0,
    lowercase => 1,
];
$expected = {
  'as snow'      => 1,
  'fleece was'   => 1,
  "had'a little" => 1,
  'its fleece'   => 1,
  'little lamb'  => 1,
  "mary had'a"   => 1,
  'was white'    => 1,
  'white as'     => 1,
};
$got = $obj->counts->{$filename};
is_deeply $got, $expected, 'counts';

done_testing();
