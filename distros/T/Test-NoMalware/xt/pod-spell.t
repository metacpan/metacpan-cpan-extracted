use Test::More;

eval 'use Test::Spelling;';

plan skip_all => "Test::Spelling required for testing POD spelling"
    if $@;

add_stopwords(qw(
	Jozef Kutej
));
all_pod_files_spelling_ok();
