# $Id: 30_lib-Text-HikiDoc-Plugin.t,v 1.2 2006/11/13 10:48:50 6-o Exp $
#use Test::More 'no_plan';
use Test::More tests => 4;
use Text::HikiDoc;


my $obj = Text::HikiDoc->new;
ok($obj->enable_plugin('hoge','br','e','fuga'),'enable_plugin');
ok($obj->is_enabled('hoge') eq '0','hoge is not defined');
ok($obj->is_enabled('br') eq '1','br is defined');
my @p1 = $obj->plugin_list;
my @p2 = ('br','e');
is_deeply(\@p1,\@p2,'check all default plugin');
