package CdExample::Cd;
use strict;
use warnings;
use CdExample;
        
class CdExample::Cd {
    id_by => 'cd_id',
    has => [
        artist => { is => 'CdExample::Artist', id_by => 'artist_id' },
        title  => { is => 'Text' },
        year   => { is => 'Integer' },
        artist_name => { via => 'artist', to => 'name' },
    ],
    data_source => 'CdExample::DataSource::DB1',
    table_name => 'CDS',
};
1;

