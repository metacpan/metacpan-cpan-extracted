#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 8;

use_ok('Typist');
use_ok('Typist::Builder');
use_ok('Typist::Template');
use_ok('Typist::Util::String');
use_ok('Typist::L10N');
use_ok('Typist::Template::Tags');
use_ok('Typist::Template::Filters');
use_ok('Typist::Template::Context');

1;