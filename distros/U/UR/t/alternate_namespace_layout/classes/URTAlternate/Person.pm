package URTAlternate::Person;

use URTAlternate;

use strict;
use warnings;
class URTAlternate::Person {
    table_name => 'person',
    id_by => [
        person_id => { is => 'integer' },
    ],
    has => [
        name => { is => 'varchar' },
    ],
    schema_name => 'TheDB',
    data_source => 'URTAlternate::DataSource::TheDB',
};

sub uc_name {
    return uc(shift->name);
}

1;
