#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Component;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get component' => sub {
    my $component = $bz->component->get('TestProduct', 'SaltSprinkler');
    isa_ok($component, 'WebService::Bugzilla::Component', 'get component returns Component object');
    is($component->id, 50, 'component id is correct');
    is($component->name, 'SaltSprinkler', 'component name is correct');
};

subtest 'Create component' => sub {
    my $new_component = $bz->component->create(
        product => 'TestProduct', name => 'NewComp',
        description => 'New', default_assignee => 'dev@example.com'
    );
    isa_ok($new_component, 'WebService::Bugzilla::Component', 'create returns Component object');
    is($new_component->id, 50, 'new component id is correct');
};

subtest 'Update component' => sub {
    my $updated_component = $bz->component->update('TestProduct', 'SaltSprinkler', description => 'Updated');
    isa_ok($updated_component, 'WebService::Bugzilla::Component', 'update returns Component object');
};

done_testing();
