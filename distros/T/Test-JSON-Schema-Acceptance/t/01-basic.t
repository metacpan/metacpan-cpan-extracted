use strict;
use warnings;
no if "$]" >= 5.031008, feature => 'indirect';

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;

use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(7);

my $parser = SchemaParser->new;
my ($premature, @results) = run_tests(
    sub {
        $accepter->acceptance(sub {
            my ($schema, $input) = @_;
            return $parser->validate($input, $schema);
        });
    }
);

cmp_deeply(
  [ grep $_->{name} =~ /^boolean type matches booleans/, @results ],
  array_each(superhashof({ ok => 1 })),
  'tests pass for checking schemas that testing for boolean type',
);

done_testing;
