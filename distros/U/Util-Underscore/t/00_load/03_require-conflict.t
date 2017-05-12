#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

# require blows
throws_ok { require _ } qr/"_" package is internal to Util::Underscore/;

# fixture
%_:: = ();             # clear "_" package so that Util::Underscore doesn't blow
delete $INC{'_.pm'};   # clear the %INC entry so that _ can be loaded again
use_ok 'Util::Underscore';

# require still blows after it has been loaded
throws_ok { require _ } qr/"_" package is internal to Util::Underscore/;
