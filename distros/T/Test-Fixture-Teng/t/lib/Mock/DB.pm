package Mock::DB;
use parent 'Teng';
__PACKAGE__->load_plugin('Count');

package Mock::DB::Schema;
use Teng::Schema::Declare;

table {
    name 'foo';
    pk 'id';
    columns qw/
        id
        name
    /;
};

table {
    name 'bar';
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

