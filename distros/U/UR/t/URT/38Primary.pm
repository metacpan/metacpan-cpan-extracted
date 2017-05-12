package URT::38Primary;

use URT;
use strict;
use warnings;

UR::Object::Type->define(
    class_name => 'URT::38Primary',
    id_by => [ primary_id => { is => 'Integer' }, ],
    has => [
        primary_value  => { is => 'String' },
        rel_id     => { is => 'Integer'},
        related_object => { is => 'URT::38Related', id_by => 'rel_id' },
        related_value  => { via => 'related_object', to => 'related_value' },
    ],
    data_source => 'URT::DataSource::SomeSQLite1',
    table_name => 'primary_table',
);


1;

