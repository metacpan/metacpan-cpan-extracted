#!/usr/bin/perl
#===============================================================================
#        USAGE:  
#       AUTHOR:  Alec Chen <ylchenzr.tsmc.com>
#===============================================================================

use warnings;
use strict;
use Text::ASCIITable::TW;

my $str = '中文';

my $t = Text::ASCIITable::TW->new({headingText => 'Basket'});

$t->setCols('Id','Name',$str);
$t->addRow(1,'Dummy product 1',24.4);
$t->addRow(2,'Dummy product 2',21.2);
$t->addRow(3,'Dummy product 3',12.3);
$t->addRowLine();
$t->addRow('','Total',57.9);
print $t;
