#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'TiddlyWeb::Wikrad';
    use_ok 'TiddlyWeb::Wikrad::Window';
    use_ok 'TiddlyWeb::Wikrad::PageViewer';
    use_ok 'TiddlyWeb::Wikrad::Listbox';
    use_ok 'TiddlyWeb::Resting';
    use_ok 'TiddlyWeb::Resting::DefaultRester';
    use_ok 'TiddlyWeb::Resting::Getopt';
    use_ok 'TiddlyWeb::EditPage';
}
