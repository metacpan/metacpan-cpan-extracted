use utf8;
use Test2::Require::Module 'Path::Tiny';
use Test2::V0 -no_srand => 1;
use Test2::Tools::JSON::Pointer;
use Path::Tiny qw( path );

is(
  path( 'corpus/ascii.json' ),
  json('/a' => 1),
  'works with an ascii file',
);

is(
  path( 'corpus/utf8.json' ),
  json('/u' => '龍'),
  'works with UTF-8 file',
);

done_testing;
