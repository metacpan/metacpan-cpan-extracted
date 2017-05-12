use Test::More;
BEGIN {
    plan skip_all => "Spelling tests only for authors"
        unless -d 'inc/.author';
}

use Test::Spelling;
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
Brohman
CPAN
Tubert
brian
foy

preprocessing
spellcheck
subdirectories
