use strict;
use warnings;
use Test::More;

use utf8;


use Text::Names::Canonicalize qw(canonicalize_name);

sub canon { canonicalize_name(@_) }

# 1. Whitespace
is canon(" John   Smith "), "john smith", "collapse and trim whitespace";

# 2. Case
is canon("JoHn SmItH"), "john smith", "lowercase";

# 3. Punctuation (basic)
is canon("John Smith,"), "john smith", "strip trailing comma";
is canon(".John Smith"), "john smith", "strip leading period";

# 4. Unicode normalization + diacritics (when requested)
is canon("José da Silva", strip_diacritics => 1),
   "jose da silva",
   "strip diacritics when requested";

# 5. Empty / undef
is canon(""), "", "empty string stays empty";
is canon(undef), "", "undef becomes empty";

done_testing;
