use Test2::V0 -no_srand => 1;
use 5.026;
use lib 't/lib';
use Test::SourceFile;
use Test::SpellCheck::Plugin::StopWords;

is(
  Test::SpellCheck::Plugin::StopWords->new,
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => [];
  },
  'basic, empty',
);

is(
  Test::SpellCheck::Plugin::StopWords->new( word => 'foo' ),
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => ['foo'];
  },
  'basic, one',
);

is(
  Test::SpellCheck::Plugin::StopWords->new( word => ['foo','bar'] ),
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => ['bar','foo'];
  },
  'basic, two',
);

my $file = file( 'foo.txt' => <<~'TEXT' );
  one
  two
  three
  TEXT

is(
  Test::SpellCheck::Plugin::StopWords->new( file => $file ),
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => ['one','three','two'];
  },
  'file',
);

is(
  Test::SpellCheck::Plugin::StopWords->new( file => $file, word => 'foo' ),
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => ['foo','one','three','two'];
  },
  'file + word',
);

is(
  Test::SpellCheck::Plugin::StopWords->new( file => $file, word => ['foo','bar','baz'] ),
  object {
    call [ isa => 'Test::SpellCheck::Plugin::StopWords' ] => T();
    call_list stopwords => ['bar','baz','foo','one','three','two'];
  },
  'file + words',
);

done_testing;
