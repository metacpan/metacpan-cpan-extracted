#!/usr/bin/env perl
use common::sense 2.02;
use utf8;

use Text::Greeking::zh_TW;

use Test::More tests => 1;

my $my_text = "許多年輕人明知有糖尿病卻不在意，眼科醫師提醒，糖尿病會引起視網膜病變。臨床上看到越來越多年輕人，視力從1.0驟降到0.1，更有患者三十歲出頭就失明。 ";

my $g = Text::Greeking::zh_TW->new;

$g->add_source( $my_text );

my $text = $g->generate;

ok(length($text) > 0);

# diag($text);
