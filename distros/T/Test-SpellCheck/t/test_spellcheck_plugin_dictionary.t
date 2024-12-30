use Test2::V0 -no_srand => 1;
use 5.026;
use Test::SpellCheck::Plugin::Dictionary;

subtest 'errors' => sub {

  local $@ = '';
  eval { Test::SpellCheck::Plugin::Dictionary->new };
  like "$@", qr/^must specify dictionary/;

  local $@ = '';
  eval { Test::SpellCheck::Plugin::Dictionary->new(dictionary => 'bogus') };
  like "$@", qr/^dictionary bogus not found/;

};

subtest 'basic' => sub {

  is(
    Test::SpellCheck::Plugin::Dictionary->new( dictionary => __FILE__),
    object {
      call [ isa => 'Test::SpellCheck::Plugin::Dictionary' ] => T();
      call dictionary => __FILE__;
    },
  );

};

done_testing;
