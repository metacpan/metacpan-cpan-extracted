#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib);

use utf8;
use Text::UnicodeTable::Simple;

binmode STDOUT, ":utf8";

my $table = Text::UnicodeTable::Simple->new(
    header => [ qw/Id Name Price/ ],
    border => 0
);

$table->add_rows(
    [1,  '사과', 10.1],
    [2,  '귤',   11.2],
    [3,  '신가', 12.3],
);
print $table->draw;
