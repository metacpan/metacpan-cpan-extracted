package URTAlternate::Car;

use URTAlternate;

use strict;
use warnings;
class URTAlternate::Car {
    table_name => 'car',
    id_by => [
        car_id => { is => 'integer' },
    ],
    has => [
        make  => { is => 'varchar' },
        model => { is => 'varchar' },
    ],
    schema_name => 'TheDB',
    data_source => 'URTAlternate::DataSource::TheDB',
};

1;
