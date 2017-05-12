#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../lib);

use utf8;
use Text::UnicodeTable::Simple;
use Text::CSV_XS;

binmode STDOUT, ":utf8";

my $csv = Text::CSV_XS->new() or die Text::CSV_XS->error_diag;

my $t = Text::UnicodeTable::Simple->new;
$t->set_header($csv->getline(*DATA));

while (my $row = $csv->getline(*DATA)) {
    $t->add_row($row);
}

print $t->draw;

__DATA__
苗字,名前,年齢
山田,太郎,19
勅使河原,純一郎,44
岡,一,82
