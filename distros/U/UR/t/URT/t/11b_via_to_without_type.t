use strict;
use warnings;
use Test::More tests => 2; 

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

my $c1 = UR::Object::Type->define(
    class_name => 'Acme::Manufacturer',
    is => 'UR::Object',
    has => [
        name    => { is => 'Text' },
    ],
);

my $c2 = UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => [
        'name',
        'manufacturer' => { is => 'Acme::Manufacturer', id_by => 'manufacturer_id' },
        'genius',
        'manufacturer_name' => { via => 'manufacturer', to => 'name' },
    ]
);

my $p2 = $c2->property('manufacturer_name');
ok($p2, "got property meta for a via/to with undeclared type");

# we currently leave the data_type un-set
# is($p2->data_type, "Text", "data type is set to the correct value");

is($p2->_data_type_as_class_name, "UR::Value::Text", "class for the data type is set to the correct value");


