use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

all_from 'lib/Text/Clevery.pm';

requires 'Any::Moose'     => 0.13;
requires 'Text::Xslate'   => 0.2015;
requires 'Plack'          => 0.9938; # Plack::Request

requires 'Config::Tiny'   => 2.12;
requires 'Image::Size'    => 3.22;
requires 'HTML::Entities' => 1.35;
requires 'Time::Piece'    => 1.20;

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Text-Clevery-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
