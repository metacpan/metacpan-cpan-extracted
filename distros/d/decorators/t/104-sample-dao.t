#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    # load from t/lib
    use_ok('DAO::Trait::Provider');
}

=pod

=cut

BEGIN {
    package Person {
        use strict;
        use warnings;

        use decorators ':accessors';

        use parent 'UNIVERSAL::Object';
        our %HAS; BEGIN { %HAS = (
            id   => sub {},
            name => sub { "" },
        )};

        sub id   : ro;
        sub name : rw;
    }

    package My::DAO::PeopleDB {
        use strict;
        use warnings;

        use decorators 'DAO::Trait::Provider';

        sub find_name_by_id : FindOne(
            'SELECT name FROM Person WHERE id = ?',
            accepts => [ 'Int' ],
            returns => 'Str'
        );

        sub find_all_by_last_name : FindMany(
            'SELECT id, name FROM Person WHERE last_name = ?'
            accepts => [ 'Str' ],
            returns => 'ArrayRef[Person]'
        );
    }
}

done_testing;
