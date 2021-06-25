#!/usr/bin/env perl
use warnings;
use v5.12;

use Data::Dumper;
$Data::Dumper::Indent = 0;

use Tree::Serial;

say Dumper(Tree::Serial->new());
# $VAR1 = bless( {'separator' => '.','traversal' => 0,'degree' => 2}, 'Tree::Serial' );

say Dumper(Tree::Serial->new({separator => "#", degree => 5, traversal => 4}));
# $VAR1 = bless( {'degree' => 5,'separator' => '#','traversal' => 4}, 'Tree::Serial' );

say Dumper(Tree::Serial->new()->strs2hash([qw(p q . . r . .)]));
# $VAR1 = {'1' => {'name' => 'r'},'name' => 'p','0' => {'name' => 'q'}};

say Dumper(Tree::Serial->new({traversal => 2})->strs2lol([qw(a b . c . . .)]));
# $VAR1 = [[['c'],'b'],'a'];

say Dumper(Tree::Serial->new({traversal => 2,showMissing => undef})->strs2lol([qw(a b . c . . .)]));
# $VAR1 = [[[],[[],[],'c'],'b'],[],'a'];

say Dumper(Tree::Serial->new({traversal => 2,showMissing => "X"})->strs2hash([qw(a b . c . . .)]));
# $VAR1 = {'name' => 'a','0' => {'0' => {'name' => 'X'},'name' => 'b','1' => {'1' => {'name' => 'X'},'name' => 'c','0' => {'name' => 'X'}}},'1' => {'name' => 'X'}};
