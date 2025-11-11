# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';

use Test2::API 'intercept';
use Test2::V0 qw(!bag !bool), -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::JSON::Schema::Acceptance;
use List::Util 'sum';
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use SchemaParser;
use Helper;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

# bar contains only failing tests (3x3)
# baz contains only passing tests (3)
# foo contains only passing tests (3x3)

# count indicates the number of tests run from each of: bar.json, baz.json, foo.json
foreach my $test (
  # run tests in this file
  { count => [0,0,9], tests => { file => 'foo.json' } },

  # run tests in these files
  { count => [0,3,9], tests => { file => [ 'foo.json', 'baz.json' ] } },

  # run tests in any file, with this group description
  { count => [3,'0 but true',3], tests => { group_description => 'false schema' } },

  # run tests in this file with this group description
  { count => [0,0,3], tests => { file => 'foo.json', group_description => 'false schema' } },

  # run tests in this file with these group descriptions
  {
    count => [0,0,3+3],
    tests => { file => 'foo.json', group_description => [ 'true schema', 'false schema' ], },
  },

  # run tests in this file with this group description and test description
  { count => [0,0,1], tests => {
      file => 'foo.json',
      group_description => 'true schema',
      test_description => 'boolean false',
    }
  },

  # run tests in this file with this group description and these test descriptions
  { count => [2,0,0], tests => {
      file => 'bar.json',
      group_description => 'false schema',
      test_description => [ 'boolean true', 'boolean false' ],
    }
  },

  # run tests in any file with this group description and this test description
  { count => [1,1,1], tests => {
      group_description => 'empty schema',
      test_description => [ 'boolean true' ],
    }
  },

  # run tests in any file with any group description with this test description
  { count => [3,1,3], tests => {
      test_description => [ 'boolean true' ],
    }
  },
) {
  my ($count, $test_options) = @{$test}{qw(count tests)};

  my $events = intercept( # Test2::API::InterceptResult
    sub {
      $accepter->acceptance(
        validate_data => sub ($schema, $data) {
          return $parser->validate_data($data, $schema);
        },
        tests => $test_options,
      );
    }
  );

  my @tests = grep $_->isa('Test2::Event::Ok'), @$events;
  is(scalar(@tests), sum(@$count), 'ran ('.join('+',@$count).') tests');

  cmp_result(
    $accepter->results,
    [
      map +(
        $count->[$_] ? +{
          file => str([ qw(bar.json baz.json foo.json) ]->[$_]),
          pass => ($_ ? 0+$count->[$_] : 0),
          todo_fail => 0,
          fail => ($_ ? 0 : 0+$count->[$_]),
        } : ()
      ), (0..2)
    ],
    'result data was populated',
  )
  or diag "all failing tests:\n", join("\n", failing_test_names($events));
}

done_testing;
