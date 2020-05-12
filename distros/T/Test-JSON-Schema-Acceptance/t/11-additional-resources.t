# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;

my $accepter = Test::JSON::Schema::Acceptance->new(specification => 'draft2019-09');

ok($accepter->additional_resources->is_dir, 'additional_resources directory exists');

ok($accepter->additional_resources->child('integer.json')->is_file, 'integer.json file exists');

done_testing;
