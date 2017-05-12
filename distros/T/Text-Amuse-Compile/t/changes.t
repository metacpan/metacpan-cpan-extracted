use Test::More;
eval 'use Test::CPAN::Changes';
plan skip_all => 'Changes testing not required (or Test::CPAN::Changes not found)'
  if ($@ || !$ENV{RELEASE_TESTING});
changes_ok();


