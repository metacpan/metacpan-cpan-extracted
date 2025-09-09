# -*- perl -*-
use strict;
use Test::More;

plan skip_all => 'No RELEASE_TESTING'
  unless -d '.git' || $ENV{RELEASE_TESTING};

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required"
  if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
Arnfjörð
Ævar
BSR
Bjarmason
CRLF
DBD
DBI
EUMM
JIT
JITTARGET
LF
LibXML
MD5
NYI
Orton
PCRE
PCRE2
Params
Reini
SQLite
Syck
UTF
Util
YAML
alloptions
argoptions
backrefmax
bsr
capturecount
compat
cpan
ffff
firstbitmap
firstcodetype
firstcodeunit
framesize
hasbackslashc
hascrorlf
heapframe
heaplimit
jchanged
jit
jitsize
lastcodetype
lastcodeunit
lexically
libpcre
libpcre2
lookbehinds
matchempty
matcher
matchlimit
maxlookbehind
minlength
namecount
nameentrysize
nametable
offsetlimit
parenslimit
pcre
pcre2
pcre2compat
recursionlimit
set'able
subpattern
testsuite
unicode
xffff
xffffffff
xsubpp
