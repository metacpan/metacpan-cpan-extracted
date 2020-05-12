# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;
use List::Util 'sum';
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

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
  my ($premature, @results) = run_tests(
    sub {
      $accepter->acceptance(
        validate_data => sub {
          my ($schema, $data) = @_;
          return $parser->validate_data($data, $schema);
        },
        tests => $test_options,
      );
    }
  );

  is(scalar(@results), sum(@$count), 'ran ('.join('+',@$count).') tests');

  cmp_deeply(
    $accepter->results,
    [
      map +(
        $count->[$_] ? +{
          file => str([ qw(bar.json baz.json foo.json) ]->[$_]),
          pass => 0+$count->[$_],
          fail => 0,
        } : ()
      ), (0..2)
    ],
    'result data was populated',
  );
}

done_testing;
