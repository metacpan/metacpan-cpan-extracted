use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal qw(exception);

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use URT;

setup();

subtest 'data_type defined on source property' => sub {
    plan tests => 3;

    my $property = URT::Show->__meta__->properties(property_name => 'actors');
    ok($property->data_type, 'actors has a data_type');

    my $actor = URT::Actor->get(name => 'Larry');

    my $bx = URT::Show->define_boolexpr(actors => $actor);
    ok(!scalar(grep { $_ eq 'actors.id' } $bx->params_list), 'unflattend bx does not have id')
        or diag explain [ $bx->params_list ];

    my $flat_bx = $bx->flatten_hard_refs;
    ok(scalar(grep { $_ eq 'actors.id' } $flat_bx->params_list), 'flattend bx does have id')
        or diag explain [ $flat_bx->params_list ];
};

subtest 'data_type defined on foreign property' => sub {
    plan tests => 4;

    my $shows_property = URT::Actor->__meta__->properties(property_name => 'shows');
    ok(!$shows_property->data_type, 'shows does not have a data_type');
    ok($shows_property->final_property_meta->data_type, 'shows final_property_meta has a data_type');

    my $show = URT::Show->get(name => 'Three Stooges');

    my $bx = URT::Actor->define_boolexpr(shows => $show);
    ok(!scalar(grep { $_ && $_ eq 'shows.id' } $bx->params_list), 'unflattend bx does not have id')
        or diag explain [ $bx->params_list ];

    my $flat_bx = $bx->flatten_hard_refs;
    ok(scalar(grep { $_ && $_ eq 'shows.id' } $flat_bx->params_list), 'flattend bx does have id')
        or diag explain [ $flat_bx->params_list ];
};

subtest 'incompatble object type' => sub {
    plan tests => 1;

    my $show = URT::Show->get(name => 'Three Stooges');
    my $ex = exception { URT::Show->define_boolexpr(actors => $show) };
    ok($ex, 'got an exception when trying to use a show as an actor');
};

subtest 'cloned object' => sub {
    plan tests => 3;
    my $actor = URT::Actor->get(name => 'Larry');

    my $ex = exception { URT::Show->define_boolexpr(actors => $actor) };
    ok(!$ex, 'did not get an exception with original actor');

    my $clone = UR::Util::deep_copy($actor);
    isnt("$clone", "$actor", 'cloned actor');

    my $bx = URT::Show->define_boolexpr(actors => $clone);
    $ex = exception { $bx->flatten_hard_refs };
    ok($ex, 'got an exception with cloned actor');
};

sub setup {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    $dbh->do(q(create table show (id integer PRIMARY KEY, name text)));
    $dbh->do(q(create table actor (id integer PRIMARY KEY, name text)));
    $dbh->do(q(create table show_actor_bridge (show_id integer, actor_id integer)));
    $dbh->do(q(insert into show values (1, 'Three Stooges')));
    $dbh->do(q(insert into show values (2, 'Power Rangers')));
    $dbh->do(q(insert into actor values (1, 'Larry')));
    $dbh->do(q(insert into actor values (2, 'Curly')));
    $dbh->do(q(insert into actor values (3, 'Moe')));
    $dbh->do(q(insert into actor values (4, 'Black')));
    $dbh->do(q(insert into show_actor_bridge values (1, 1)));
    $dbh->do(q(insert into show_actor_bridge values (1, 2)));
    $dbh->do(q(insert into show_actor_bridge values (1, 3)));
    $dbh->do(q(insert into show_actor_bridge values (2, 4)));
    $dbh->commit();

    UR::Object::Type->define(
        class_name => 'URT::Show',
        id_by => 'id',
        has => [
            name => { is => 'Text' },
            actor_bridges => { is => 'URT::ShowActorBridge', reverse_as => 'show', is_many => 1 },
            actors => { is => 'URT::Actor', via => 'actor_bridges', to => 'actor', is_many => 1 },
        ],
        table_name => 'show',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    UR::Object::Type->define(
        class_name => 'URT::Actor',
        id_by => 'id',
        has => [
            name => { is => 'Text' },
            show_bridges => { is => 'URT::ShowActorBridge', reverse_as => 'actor', is_many => 1 },
            shows => { via => 'show_bridges', to => 'show', is_many => 1 },
        ],
        table_name => 'actor',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    UR::Object::Type->define(
        class_name => 'URT::ShowActorBridge',
        id_by => [
            show => {
                is => 'URT::Show',
                id_by => 'show_id',
            },
            actor => {
                is => 'URT::Actor',
                id_by => 'actor_id',
            },
        ],
        table_name => 'show_actor_bridge',
        data_source => 'URT::DataSource::SomeSQLite',
    );
}
