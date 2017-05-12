#!/usr/bin/perl 

use strict;
use warnings;

use Test::Most qw{no_plan};
#use Carp::Always;

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
BEGIN {
  use_ok('Tool::Bench');
}

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
ok my $tb  = Tool::Bench->new();
isa_ok  $tb, 'Tool::Bench';

my $pre    = 0;
my $before = 0;
my $after  = 0;
my $post   = 0;

ok $tb->add_items( ls  => sub{qx{ls}} ), q{add item pair};
ok $tb->add_items( die => { code     => sub{die},
                            pre_run  => sub{$pre++},
                            buildup  => sub{$before++},
                            teardown => sub{$after++},
                            post_run => sub{$post++},
                            note     => 'Just how long does it take to die?',
                          },
                 ), q{add item hash} ;
ok $tb->add_items( true => sub{1}, sleep => sub{sleep(1)}), q{add more then one item};
is $tb->items_count, 4, q{right count of items};

ok $tb->run,    q{run single};
ok $tb->run(3), q{run single};

is $tb->items->[0]->total_runs, 4, q{items were run 4 times each};
is $pre   , 2, q{pre run ran twice, for each run};
is $before, 4, q{startup ran the correct number of times};
is $after , 4, q{teardown ran the correct number of times};
is $post  , 2, q{post run ran twice, for each run};

ok $tb->report(format => 'Text'), q{can get a Text report};
ok $tb->report(format => 'JSON'), q{can get a json report};
