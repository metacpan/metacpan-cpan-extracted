use Test2::V0 -no_srand => 1;
use 5.026;
use Test::SpellCheck::Plugin::PrimaryDictionary;

subtest 'errors' => sub {

  local $@ = '';
  eval { Test::SpellCheck::Plugin::PrimaryDictionary->new };
  like "$@", qr/^must specify affix file/;

  local $@ = '';
  eval { Test::SpellCheck::Plugin::PrimaryDictionary->new( affix => __FILE__ ) };
  like "$@", qr/^must specify dictionary/;

  local $@ = '';
  eval { Test::SpellCheck::Plugin::PrimaryDictionary->new(affix => 'bogus2', dictionary => 'bogus') };
  like "$@", qr/^affix file bogus2 not found/;

  local $@ = '';
  eval { Test::SpellCheck::Plugin::PrimaryDictionary->new(affix => __FILE__, dictionary => 'bogus') };
  like "$@", qr/^dictionary bogus not found/;

};

subtest 'basic' => sub {

  is(
    Test::SpellCheck::Plugin::PrimaryDictionary->new( affix => __FILE__, dictionary => __FILE__),
    object {
      call [ isa => 'Test::SpellCheck::Plugin::PrimaryDictionary' ] => T();
      call_list primary_dictionary => [__FILE__,__FILE__];
    },
  );

};

done_testing;
