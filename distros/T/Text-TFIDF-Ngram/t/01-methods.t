#!perl

use Test::More;
use Test::Exception;

use_ok 'Text::TFIDF::Ngram';

my $obj;

lives_ok { $obj = Text::TFIDF::Ngram->new } 'created with no arguments';
isa_ok $obj, 'Text::TFIDF::Ngram';

my $x = $obj->files;
is $x, undef, 'no files';

$x = $obj->stopwords;
is $x, 1, 'stopwords';

# https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Example_of_tf%E2%80%93idf

my $files = [qw( t/1.txt t/2.txt )];

$obj = Text::TFIDF::Ngram->new( files => $files, size => 1, stopwords => 0 );
isa_ok $obj, 'Text::TFIDF::Ngram';

my $expected = $files;
$x = $obj->files;
is_deeply $x, $expected, 'files';

my $filename = 't/1.txt';
my $term     = 'this';

$expected = {
    this   => 1,
    is     => 1,
    a      => 2,
    sample => 1,
};
$x = $obj->counts->{$filename};
is_deeply $x, $expected, 'counts';

$expected = 0.2;
$x = $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = 0;
$x = $obj->idf($term);
is $x, $expected, 'IDF';

$expected = undef;
$x = $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

$filename = 't/2.txt';
$term     = 'example';

$expected = {
    this    => 1,
    is      => 1,
    another => 2,
    example => 3,
};
$x = $obj->counts->{$filename};
is_deeply $x, $expected, 'counts';

$expected = 0.143;
$x = sprintf '%.3f', $obj->tf( $filename, 'this' );
is $x, $expected, 'TF';

$expected = 0.429;
$x = sprintf '%.3f', $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = 0.301;
$x = sprintf '%.3f', $obj->idf($term);
is $x, $expected, 'IDF';

$expected = 0.129;
$x = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

$term = 'foo';

$expected = 0;
$x = $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = undef;
$x = $obj->idf($term);
is $x, $expected, 'IDF';

$x = $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

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
$x = $obj->tfidf_by_file;
# Normalize the value digits of precision:
for my $file ( keys %$x ) {
    for my $word ( keys %{ $x->{$file} } ) {
        $x->{$file}{$word} = sprintf '%.3f', $x->{$file}{$word};
    }
}
is_deeply $x, $expected, 'tfidf_by_file';

$files = [qw( t/3.txt t/4.txt )];

$obj = Text::TFIDF::Ngram->new( files => $files, size => 2, stopwords => 0 );
isa_ok $obj, 'Text::TFIDF::Ngram';

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
$x = $obj->counts->{$filename};
is_deeply $x, $expected, 'counts';

$expected = 0.111;
$x = sprintf '%.3f', $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = 0.301;
$x = sprintf '%.3f', $obj->idf($term);
is $x, $expected, 'IDF';

$expected = 0.033;
$x = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

$files = [qw( t/1.txt t/2.txt )];

$obj = Text::TFIDF::Ngram->new( files => $files, size => 1, stopwords => 1 );
isa_ok $obj, 'Text::TFIDF::Ngram';

$filename = 't/1.txt';
$term     = 'sample';

$expected = 1;
$x = $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = 0.301;
$x = sprintf '%.3f', $obj->idf($term);
is $x, $expected, 'IDF';

$expected = 0.301;
$x = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

$expected = { sample => 1, };
$x = $obj->counts->{$filename};
is_deeply $x, $expected, 'counts';

$obj = Text::TFIDF::Ngram->new( files => $files, size => 2, stopwords => 0 );
isa_ok $obj, 'Text::TFIDF::Ngram';

$term = 'a sample';

$expected = 0.25;
$x = $obj->tf( $filename, $term );
is $x, $expected, 'TF';

$expected = 0.301;
$x = sprintf '%.3f', $obj->idf($term);
is $x, $expected, 'IDF';

$expected = 0.075;
$x = sprintf '%.3f', $obj->tfidf( $filename, $term );
is $x, $expected, 'TFIDF';

$expected = {
    'this is'  => 1,
    'is a'     => 1,
    'a a'      => 1,
    'a sample' => 1,
};
$x = $obj->counts->{$filename};
is_deeply $x, $expected, 'counts';

$obj = Text::TFIDF::Ngram->new( files => ['t/4.txt'], size => 2, stopwords => 0, punctuation => '' );
isa_ok $obj, 'Text::TFIDF::Ngram';
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
$x = $obj->counts->{'t/4.txt'};
is_deeply $x, $expected, 'counts';

$obj = Text::TFIDF::Ngram->new( files => ['t/4.txt'], size => 2, stopwords => 0, lowercase => 1 );
isa_ok $obj, 'Text::TFIDF::Ngram';
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
$x = $obj->counts->{'t/4.txt'};
is_deeply $x, $expected, 'counts';

done_testing();
