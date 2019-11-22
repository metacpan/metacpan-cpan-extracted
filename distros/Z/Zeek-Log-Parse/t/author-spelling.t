
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => "Author testing disabled");
  }
}

use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing epslling" if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();
__DATA__
Amann
Johanna
Zeek
fh
