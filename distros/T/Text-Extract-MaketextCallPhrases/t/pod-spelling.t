#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Spelling 0.19';
plan skip_all => 'Test::Spelling v0.19 required for testing POD' if $@;

add_stopwords( map { split /[\s\:\-]/ } readline(*DATA) );
$ENV{LANG} = 'C';
all_pod_files_spelling_ok();

__DATA__
MERCHANTABILITY
Muey
LICENCE

optional
OO
cPanel
cptext
maketext
parsable
unperlish
'
'command'
'double'
'empty'
'file'
'foo'
'heredoc'
'line'
'matched'
'offset'
'pattern'
'perlish'
'phrase'
'quotetype'
'single'
'type'
'Merp'
'I
'1'
