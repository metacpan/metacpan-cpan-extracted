package URT::43Related;

use URT;

use strict;
use warnings;

UR::Object::Type->define(
    class_name => 'URT::43Related',
    id_by => [ related_id => { is => 'Integer' }, ],
    has => [
        related_value   => { is => 'String' },
        primary_objects => { is => 'URT::43Primary', reverse_as => 'related_object', is_many => 1 },
        primary_values  => { via => 'primary_objects', to => 'primary_value', is_many => 1},
    ],
);
1;

