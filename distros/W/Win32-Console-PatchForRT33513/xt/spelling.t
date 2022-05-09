use 5.10.0;
use strict;
use warnings;
use Test::More;

use Test::Spelling;

add_stopwords(<DATA>);

all_pod_files_spelling_ok();


__DATA__
