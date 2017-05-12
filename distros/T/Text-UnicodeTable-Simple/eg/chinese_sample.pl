#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib);

use utf8;
use Text::UnicodeTable::Simple;

binmode STDOUT, ":utf8";

my $table = Text::UnicodeTable::Simple->new(
    header => [ qw/Id Name Price/ ],
);

$table->add_rows(
    [1,  '回锅肉',    1000],
    [2,  '饺子',       300],
    [3,  '北京烤鸭', 10000],
);
print $table->draw;
