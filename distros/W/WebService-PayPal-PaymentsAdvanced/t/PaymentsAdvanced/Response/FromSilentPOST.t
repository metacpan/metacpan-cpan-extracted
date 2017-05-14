use strict;
use warnings;

use Test::More;

use Scalar::Util qw( blessed );
use Test::Fatal;

use lib 't/lib';
use Util;

## no critic (RequireExplicitInclusion)
my $ppa = Util::mocked_ppa;

# What happens if the params contain only garbage?
like(
    exception {
        Util::mocked_ppa->get_response_from_silent_post(
            { params => { foo => 'bar' } } )
    },
    qr{Bad params supplied from silent POST},
    'generic exception on bad params'
);

done_testing();
