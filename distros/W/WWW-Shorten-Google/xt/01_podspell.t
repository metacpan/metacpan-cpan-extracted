use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
set_spell_cmd('aspell list');
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
$ENV{LC_COLLATE}  = 'C';
$ENV{LC_CTYPE}    = 'C';
$ENV{LC_MESSAGES} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kazuhiro Osawa
yappo <at> shibuya <döt> pl
WWW::Shorten::Google
api
gl
gl
goo
makealongerlink
makeashorterlink
Shortener
sunnavy
