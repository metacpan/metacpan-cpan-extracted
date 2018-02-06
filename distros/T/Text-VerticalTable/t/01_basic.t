use strict;
use warnings;
use Test::More;

use Text::VerticalTable;

my $t = Text::VerticalTable->new;

isa_ok $t, 'Text::VerticalTable';

$t->setHead('explain result');
$t->addRow(id => 1);
$t->addRow(select_type => 'SIMPLE');
$t->addRow(table => 'foo');

$t->setHead('explain result2');
$t->addRow(id => 1);
$t->addRow(select_type => 'SIMPLE');
$t->addRow(table => 'foo');

#note explain $t;

my $table = "$t";

like $table, qr/\Q********** 1. explain result **********\E/;
like $table, qr/\Q********** 2. explain result2 **********\E/;
like $table, qr/\Q         id: 1\E/;
like $table, qr/\Qselect_type: SIMPLE\E/;

done_testing;
