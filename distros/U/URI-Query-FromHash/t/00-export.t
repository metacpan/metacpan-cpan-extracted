use strict;
use warnings;

use Test::More tests => 8;

package t::default { use URI::Query::FromHash }

BEGIN {
    is_deeply
        [ sort keys %t::default:: ],
        [qw/BEGIN hash2query/],
        'use URI::Query::FromHash';
}

package t::default { no URI::Query::FromHash }

BEGIN {
    is_deeply [ keys %t::default:: ], ['BEGIN'], 'no  URI::Query::FromHash';
}

package t::empty { use URI::Query::FromHash () }

BEGIN {
    is_deeply
        [ sort keys %t::empty:: ],
        ['BEGIN'],
        'use URI::Query::FromHash ()';
}

package t::empty { no URI::Query::FromHash }

BEGIN {
    is_deeply [ keys %t::empty:: ], ['BEGIN'], 'no  URI::Query::FromHash';
}

package t::explicit { use URI::Query::FromHash 'hash2query' }

BEGIN {
    is_deeply
        [ sort keys %t::explicit:: ],
        [qw/BEGIN hash2query/],
        'use URI::Query::FromHash "hash2query"';
}

package t::explicit { no URI::Query::FromHash }

BEGIN {
    is_deeply [ keys %t::explicit:: ], ['BEGIN'], 'no  URI::Query::FromHash';
}

package t::foo { use URI::Query::FromHash 'foo' }

BEGIN {
    is_deeply
        [ sort keys %t::foo:: ],
        [qw/BEGIN hash2query/],
        'use URI::Query::FromHash "foo"';
}

package t::foo { no URI::Query::FromHash }

BEGIN {
    is_deeply [ keys %t::foo:: ], ['BEGIN'], 'no  URI::Query::FromHash';
}
