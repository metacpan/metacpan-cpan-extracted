package Mock::DB;
use DBIx::Skinny;

package Mock::DB::Schema;
use DBIx::Skinny::Schema;

install_table foo => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table bar => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

