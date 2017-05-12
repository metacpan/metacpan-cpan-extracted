use strict;
use inc::Module::Install;

name('Text-AutoLink');
all_from('lib/Text/AutoLink.pm');
requires('HTML::TreeBuilder');
requires('Module::Pluggable');
requires('URI');

auto_set_repository;
WriteAll;
