
package CdExample::Artist;
use strict;
use warnings;
use CdExample;

class CdExample::Artist {
    id_by => 'artist_id',
    has => [ 
        name => { is => 'Text' },
        cds  => { is => 'CdExample::Cd', is_many => 1, reverse_as => 'artist' },
        foo  => { is => 'Text' },
        #bar  => { is => 'Text' },
        baz  => { is => 'Text' },
    ],
    data_source => 'CdExample::DataSource::DB1',
    table_name => 'ARTISTS',
};
1;

