use strict;
use warnings;
use Test::More;

use Types::XSD::Lite 'HexBinary';

ok not HexBinary->check("1111\nnot hex");

done_testing;
