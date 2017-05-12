
use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep qw(cmp_bag);

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use UR;

my $class = 'URT::Person1';
UR::Object::Type->define(
    class_name => $class,
    has => [
        name => {
            is => 'Text',
        },
        nicknames => {
            is => 'Text',
            is_many => 1,
        },
    ],
);

subtest $class => sub { run_tests($class, 1) };

$class = 'URT::Person2';
UR::Object::Type->define(
    class_name => $class,
    id_by => [
        id => {
            is => 'Text',
        },
    ],
    has => [
        name => {
            is => 'Text',
        },
        nickname_objects => {
            is => 'URT::Nickname',
            reverse_as => 'person',
            is_mutable => 1,
            is_many => 1,
        },
        nicknames => {
            is => 'Text',
            via => 'nickname_objects',
            to => 'name',
            is_many => 1,
            is_mutable => 1,
        },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Nickname',
    id_by => [
        person_id => {
            is => 'Text',
        },
        name => {
            is => 'Text',
        },
    ],
    has => [
        person => {
            is => $class,
            id_by => 'person_id',
        },
    ],
);

subtest $class => sub { run_tests($class, 0) };

sub run_tests {
    my $class = shift;
    my $test_updates = shift;

    if ($test_updates) {
        plan tests => 4;
    } else {
        plan tests => 2;
    }
    my $tx = UR::Context::Transaction->begin();

    my $nickname = 'Alyosha';
    my $person = $class->create(name => 'Alexei', nicknames => $nickname);
    cmp_bag([$person->nicknames], [$nickname], 'set (and retrieved) a single nickname');

    if($test_updates) {
        $nickname = 'Alex';
        $person->nicknames($nickname);
        cmp_bag([$person->nicknames], [$nickname], 'updated (and retrieved) a single nickname');
    }

    my @nicknames = qw(Rose Anna Roseanne Annie);
    my $person2 = $class->create(name => 'Roseanna', nicknames => \@nicknames);
    cmp_bag([$person2->nicknames], \@nicknames, 'set (and retrieved) several nicknames');

    if($test_updates) {
        @nicknames = qw(Rosy Anne);
        $person2->nicknames(\@nicknames);
        cmp_bag([$person2->nicknames], \@nicknames, 'updated (and retrieved) several nicknames correctly');
    }

    $tx->rollback();
}
