use strict;
use warnings;

use Test::More tests => 3;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT::Test qw(txtest);
use Test::Deep qw(cmp_bag);

use UR;

UR::Object::Type->define(
    class_name => 'Sports::Player',
    has => [
        name => { is => 'Text' },
    ],
    has_optional => [
        team_id => { is => 'Text' },
        team => {
            is => 'Sports::Team',
            id_by => 'team_id',
        },
        nicknames => {
            is => 'Text',
            is_many => 1,
        },
    ],
);

UR::Object::Type->define(
    class_name => 'Sports::Team',
    has => [
        name => {
            is => 'Text',
        },
    ],
    has_optional => [
        players => {
            is => 'Sports::Player',
            is_many => 1,
            reverse_as => 'team',
        },
    ],
);

txtest 'basic copy' => sub {
    plan tests => 3;
    my $lakers = Sports::Team->create(name => 'Lakers');
    my $mj = Sports::Player->create(team_id => $lakers->id, name => 'Magic Johnson');
    is_deeply([$lakers->players], [$mj], 'lakers have mj');
    my $copied_team = $lakers->copy();
    is_deeply([$copied_team->players], [], 'copied team has no players');
    is($copied_team->name, $lakers->name, 'name was copied');
};

txtest 'basic copy with overrides' => sub {
    plan tests => 3;
    my $lakers = Sports::Team->create(name => 'Lakers');
    my $mj = Sports::Player->create(team_id => $lakers->id, name => 'Magic Johnson');
    is_deeply([$lakers->players], [$mj], 'lakers have mj');
    my $copied_team = $lakers->copy(name => 'Clippers');
    is_deeply([$copied_team->players], [], 'copied team has no players');
    isnt($copied_team->name, $lakers->name, 'name was overrode');
};

txtest 'copy is_many properties' => sub {
    plan tests => 5;

    UR::Object::Type->define(
        class_name => 'Foo',
        has_many => [
            things => { is => 'Text' }
        ],
    );

    my $source = Foo->create();
    $source->things([qw(one two)]);
    $source->add_thing('three');
    $source->add_thing('four');
    cmp_bag([$source->things], [qw(one two three four)]);

    my $copy = $source->copy();
    is(ref($source->{things}), 'ARRAY', 'things has ARRAY reference type');
    is(ref($copy->{things}), ref($source->{things}), 'things have same reference type');
    isnt($copy->{things}, $source->{things}, 'copy did not reuse reference');
    cmp_bag([$copy->things], [$source->things], 'copy has the same things');
};
