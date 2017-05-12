use strict;
use Test::More;
use utf8;
use Encode 'encode_utf8';

use Text::Shirasu 'normalize_symbols';

is normalize_symbols("。、・「」"), "｡､･｢｣", "can call normalize_symbols";

done_testing;