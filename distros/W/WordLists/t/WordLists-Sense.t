#!perl -w
use strict;
use WordLists::Sense;
use Data::Dumper;
use Test::More qw(no_plan);
my $sense = WordLists::Sense->new;
$sense->set('hw','a');
ok ($sense->get('hw') eq 'a', "set and get work");
$sense->set_pos('det');
ok ($sense->get_pos eq 'det', "Autoloaded set and get work");
ok ($sense->to_string eq "a\tdet\t\t", 'to_string works');
ok (Dumper($sense->to_hash) eq Dumper({hw=>'a', 'pos'=>'det'}), 'to_hash works');
