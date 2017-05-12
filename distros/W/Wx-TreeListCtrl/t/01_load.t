#!/usr/bin/perl -w

use strict;
use Wx;
use Test::More 'tests' => 2;
BEGIN { use_ok('Wx::TreeListCtrl'); }
use Wx::TreeListCtrl;

my $info = Wx::TreeListColumnInfo->new('Column One');
is($info->GetText, 'Column One', 'Check Wx::TreeListColumnInfo');



