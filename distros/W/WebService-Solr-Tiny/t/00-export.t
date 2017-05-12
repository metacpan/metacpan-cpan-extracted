use strict;
use warnings;

use Test::More tests => 4;

package t::default { use WebService::Solr::Tiny }

is_deeply
    [ sort keys %t::default:: ],
    ['BEGIN'],
    'use WebService::Solr::Tiny';

package t::empty { use WebService::Solr::Tiny () }

is_deeply
    [ sort keys %t::empty:: ],
    ['BEGIN'],
    'use WebService::Solr::Tiny ()';

package t::explicit { use WebService::Solr::Tiny 'solr_escape' }

is_deeply
    [ sort keys %t::explicit:: ],
    [qw/BEGIN solr_escape/],
    'use WebService::Solr::Tiny "solr_escape"';

package t::foo { use WebService::Solr::Tiny 'foo' }

is_deeply
    [ sort keys %t::foo:: ],
    ['BEGIN'],
    'use WebService::Solr::Tiny "foo"';
