#!perl -w
use Test::More qw(no_plan);
use WordLists::WordList;
use Data::Dumper;

my $wl = WordLists::WordList->new;
isa_ok($wl, 'WordLists::WordList', 'Created $wl');
can_ok($wl, 'get_all_senses', 'parser', 'serialiser', 'get_senses_for');

$wl->read_string("#*hw\tpos\na\tdet");
ok(length ($wl->get_all_senses) == 1, 'After reading a string, the $wl has a sense in it');
ok(${[$wl->get_all_senses]}[0]->get('hw') eq 'a', 'The sense has the correct hw');
print Dumper $wl;
print $wl->to_string;
