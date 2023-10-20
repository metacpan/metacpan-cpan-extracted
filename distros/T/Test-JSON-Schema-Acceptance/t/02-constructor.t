# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;

is(
  Test::JSON::Schema::Acceptance->new->specification,
  'draft2020-12',
  '"specification" defaults to latest draft'
);

is(
  Test::JSON::Schema::Acceptance->new(specification => 'latest')->specification,
  'draft2020-12',
  'latest becomes draft2020-12',
);

foreach my $version (3,4,6,7) {
  is(
    Test::JSON::Schema::Acceptance->new($version)->specification,
    'draft'.$version,
    '->new('.$version.') becomes ->new(specification => \'draft'.$version.'\')',
  );

  is(
    Test::JSON::Schema::Acceptance->new(specification => 'draft'.$version)->specification,
    'draft'.$version,
    '->new(specification => '.$version.') passed through normally',
  );
}

foreach my $version ('a', 2, 'foo') {
  like(
    exception { Test::JSON::Schema::Acceptance->new($version) },
    qr/Value "draft$version" did not pass type constraint/,
    'does not accept version = '.$version,
  );
}

like(
  exception { Test::JSON::Schema::Acceptance->new(test_dir => 'foo') },
  qr/test_dir does not exist: .*foo/,
  'explicit test_dir argument is checked',
);

SKIP: {
  skip 'this test can only be run in the git repository', 1 if not -d '.git';

  is(readlink('share/tests/latest'), 'draft2020-12', 'latest draft is still 2020-12')
    or warn 'a new draft has been released! update the "latest" munging in BUILDARGS!';
}

done_testing;
