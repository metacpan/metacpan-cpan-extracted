#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib);

use utf8;
use Text::UnicodeTable::Simple;

binmode STDOUT, ":utf8";

my $t = Text::UnicodeTable::Simple->new;

# using alias method of Text::ASCIITable
$t->setCols('Id','Name','Price');
$t->addRow(1,'りんご',24.4);
$t->addRow(2,'パイナップル',21.2);
$t->addRowLine();
$t->addRow(3,'パッションフルーツ',12.3);
$t->addRowLine();
$t->addRow('','Total',57.9);
print $t->draw;

print "\n";

my $no_border_t = Text::UnicodeTable::Simple->new(border => 0);

$no_border_t->set_header('Id','Name','Price');
$no_border_t->add_rows(
    [1,  'りんご', 24.4],
    [2,  'パイナップル', 21.2],
    [3,  'パッションフルーツ', 12.3],
    ['', 'Total', 57.9],
);
print $no_border_t->draw;
