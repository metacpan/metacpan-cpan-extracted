use strict;
use warnings;

use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use URT;

# We found a case where a set would do the correct SQL query to get the count
# but then would store the count on an alternate set.  That alternate set was
# constructed by the aggregate logic with a flattened, normalized rule instead
# of the calling set's rule which would result in an undef count.

setup();

my $show = URT::Show->get(name => 'Three Stooges');
is(URT::Actor->define_set(shows => $show)->count, 3);
is(URT::Actor::Set->get(shows => $show)->count, 3);

my $actor = URT::Actor->get(name => 'Larry');
is(URT::Show->define_set(actors => $actor)->count, 1);
is(URT::Show::Set->get(actors => $actor)->count, 1);

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
            shows => { is => 'URT::Show', via => 'show_bridges', to => 'show', is_many => 1 },
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

