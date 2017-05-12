use strict;
use warnings;
use Test::More;

eval <<'EOF';
use Test::Spelling 0.12;
use Pod::Spelling;
EOF

plan skip_all => 'Test::Spelling 0.12 and Pod::Spelling required for testing POD spelling'
	if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw(lib) );

__DATA__
AST
Goro
gfx
submodules
