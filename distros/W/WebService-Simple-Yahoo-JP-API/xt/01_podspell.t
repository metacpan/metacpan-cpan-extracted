use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
AYANOKOUZI, Ryuunosuke
i38w7i3@yahoo.co.jp
WebService::Simple::Yahoo::JP::API
