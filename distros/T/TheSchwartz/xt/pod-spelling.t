use strict;
use Test::More;

eval "use Test::Spelling";
if ($@) {
    plan skip_all => "Test::Spelling required for testing POD spelling";
}
else {
    add_stopwords(qw(DSN TheSchwartz btree schwartzmon lookup));
}

all_pod_files_spelling_ok();

