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
Arnfj
BSR
Bjarmason
JIT
JITTARGET
LF
NYI
Orton
PCRE
Reini
alloptions
argoptions
compat
jit
libpcre
matcher
pcre
set'able
unicode
backrefmax
bsr
capturecount
ffff
firstbitmap
firstcodetype
firstcodeunit
hasbackslashc
hascrorlf
jchanged
jitsize
lastcodetype
lastcodeunit
matchempty
matchlimit
maxlookbehind
minlength
namecount
nameentrysize
nametable
recursionlimit
xffff
xffffffff
CRLF
UTF
lexically
lookbehinds
subpattern
testsuite
DBD
EUMM
LibXML
Params
Syck
Util
xsubpp
DBI
SQLite
YAML
cpan
framesize
heapframe
heaplimit
offsetlimit
parenslimit
