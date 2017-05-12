use Test::More;
use Config ();
use File::Spec ();
eval "use Test::Spelling";
plan skip_all => "Test::Spelling is not installed." if $@;

my $spell;
for my $path (split /$Config::Config{path_sep}/ => $ENV{PATH}) {
    -x File::Spec->catfile($path => 'spell')  and $spell = 'spell',       last;
    -x File::Spec->catfile($path => 'ispell') and $spell = 'ispell -l',   last;
    -x File::Spec->catfile($path => 'aspell') and $spell = 'aspell list', last;
}
plan skip_all => "spell/ispell/aspell are not installed." unless $spell;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
set_spell_cmd($spell) if $spell;
local $ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
NAKAGAWA Masaki
masaki@cpan.org
Test::Double
