use strict;
use Test::More;
use utf8;
use Encode 'encode_utf8';

use Text::Shirasu 'normalize_hyphen';

is normalize_hyphen("˗֊‐‑‒–⁃⁻₋−"),     encode_utf8("-" x 10), "can normalize hyphen";
is normalize_hyphen("﹣－ｰ—―─━ー"), "ー", "can normalize japanese hyphen";
is normalize_hyphen("~∼∾〜〰～"), "",  "can remove tilde";

done_testing;