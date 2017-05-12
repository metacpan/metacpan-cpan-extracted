package # hide from CPAN
  XAS::Model::Database::Testing::ResultSet::Artist;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub has_more_than_one_cds {
    my $me = (my $self = shift)->current_source_alias;

    $self->search(
        {}, {
            join=>['cd_rs'],
              '+select'=> [ { count => 'cd_rs.cd_id', -as => 'cd_count'} ],
              '+as'=> ['cd_count'],
              group_by=>["$me.artist_id"],
              having => { cd_count => \'> 1' }
        }
    );
    
}

1;
