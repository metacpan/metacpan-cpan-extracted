use strict;
use warnings;
use Test::More;
use Test::Requires qw( Exporter Types::Common );

use lib qw( ./t/externals/Exporter/lib );

use Cookbook qw(Message);

ok Message->check('World!');

done_testing;
