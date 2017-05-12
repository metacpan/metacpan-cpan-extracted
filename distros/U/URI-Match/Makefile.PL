use strict;
use inc::Module::Install;

name('URI-Match');
all_from('lib/URI/Match.pm');
requires('URI');

auto_include;
WriteAll;
