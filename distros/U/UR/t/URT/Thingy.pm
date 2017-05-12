package URT::Thingy;

use warnings;
use strict;

use UR::Object::Type;

use URT;
class URT::Thingy {
    id_by => [
        pcr_id => { is => 'NUMBER', len => 15 },
    ],
    has => [
        enz_id   => { is => 'NUMBER', len => 10, 
                                                  doc => "Link to polymerase used in PCR." },
        pcr_name => { is => 'VARCHAR2', len => 64, 
                                                  doc => "GSC name of the pcr_product.  Named based on documented naming conventions." },
        pri_id_1 => { is => 'NUMBER', len => 10, 
                                                  doc => "Link to one primer used in PCR." },
        pri_id_2 => { is => 'NUMBER', len => 10, 
                                                  doc => "Link to one primer used in PCR." },
    ],
    unique_constraints => [
        { properties => [qw/pcr_name/], sql => 'PCR_NAME_U' },
    ],
    doc => 'Stores information for each instance of a polymerase chain react',
};

1;

