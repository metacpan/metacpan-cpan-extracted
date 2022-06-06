# -*- perl -*-
use strict;
use Test::More;

plan skip_all => 'This test is only run for the module author'
  unless -d '.git' || $ENV{AUTHOR_TESTING};

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required"
  if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
DumpFile
Ingy
Kirill
LoadFile
SafeClass
SafeDump
SafeDumpFile
SafeLoad
SafeLoadFile
Siminov
cr
crln
deparsing
distroprefs
döt
evaling
getter
libyaml
ln
numified
readonly
Reini
le
testsuite
unicode
yaml
utf16be
utf16le
utf8
v5
