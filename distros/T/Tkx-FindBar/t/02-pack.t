use strict;
use warnings;
use Tkx;
use Tkx::FindBar;
use Test::More tests => 2;

my $mw      = Tkx::widget->new('.');
my $text1   = $mw->new_text(-wrap => 'word', -height => 5);
my $text2   = $mw->new_text(-wrap => 'word', -height => 5);
my $findbar = $mw->new_tkx_FindBar();

$text1->g_pack();
$findbar->g_pack(-anchor => 'w');
$text2->g_pack();

my @order = Tkx::SplitList(Tkx::pack('slaves', $mw));
my @exp   = grep { $_ ne $findbar } @order;

$findbar->hide();
is_deeply([Tkx::SplitList(Tkx::pack('slaves', $mw))], \@exp, "hide() removes from pack order");

$findbar->show();
is_deeply([Tkx::SplitList(Tkx::pack('slaves', $mw))], \@order, "show() restores original location");
