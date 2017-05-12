package URT::43Primary;

use URT;
use strict;
use warnings;

UR::Object::Type->define(
    class_name => 'URT::43Primary',
    id_by => [ primary_id => { is => 'Integer' }, ],
    has => [
        primary_value  => { is => 'String' },
        rel_id     => { is => 'Integer'},
        related_object => { is => 'URT::43Related', id_by => 'rel_id' },
        related_value  => { via => 'related_object', to => 'related_value' },
    ],
);


1;

