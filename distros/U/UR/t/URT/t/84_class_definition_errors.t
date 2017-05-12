use strict;
use warnings;
use Test::More tests=> 6;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

my $o = eval {
    UR::Object::Type->define(
        class_name => 'URT::Foo',
        is => 'NonExistentClass',
        has => 'property_a',
    );
};

ok(! $o, 'Defining class with non-existant parent did not work');
like($@, qr/cannot initialize because of errors using parent class NonExistentClass/, 'Error message looks correct');

$o = eval {
    UR::Object::Type->define(
        class_name => 'URT::Foo',
        is => 'URT::NonExistentClass',
        has => 'property_a',
    )
};

ok(! $o, 'Defining class with non-existant parent did not work');
like($@, qr/cannot initialize because of errors using parent class URT::NonExistentClass/, 'Error message looks correct');

$o = eval {
    UR::Object::Type->define(
        class_name => 'URT::Foo',
        has => [
            'prop' => { is => 'URT::NonExistantClass', id_by => 'prop_id' },
        ],
    )
};

ok(! $o, 'Defining class with relationship to non-existant class did not work');
like($@, qr/Unable to load URT::NonExistantClass while defining relationship prop/, 'Error message looks correct');

