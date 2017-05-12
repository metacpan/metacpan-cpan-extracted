#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 52;

BEGIN {
    use_ok('Tree::Visualize::ASCII::BoundingBox');
}

can_ok("Tree::Visualize::ASCII::BoundingBox", 'new');
my $box = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                '+------+',
                '| test |',
                '+------+'
                ));
isa_ok($box, 'Tree::Visualize::ASCII::BoundingBox');  

can_ok($box, 'height');     
cmp_ok($box->height, '==', 3, '... the height of this box is 3');
             
can_ok($box, 'width');
cmp_ok($box->width, '==', 8, '... the width of this box is 8');

can_ok($box, 'getLinesAsArray');
is_deeply([ $box->getLinesAsArray ],
          ['+------+',
           '| test |',
           '+------+'],
          '... got the array of lines we expected');

can_ok($box, 'getAsString');
is($box->getAsString, "+------+\n| test |\n+------+", '... we got the string we expected');

can_ok($box, 'flipHorizontal');
$box->flipHorizontal();
is($box->getAsString, "+------+\n| tset |\n+------+", '... we got the string we expected');

$box->flipHorizontal();
is($box->getAsString, "+------+\n| test |\n+------+", '... we got the string we expected');

my $other_box = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                '=------=',
                '| test |',
                '.------.'
                ));
isa_ok($other_box, 'Tree::Visualize::ASCII::BoundingBox'); 
is($other_box->getAsString, "=------=\n| test |\n.------.", '... we got the string we expected'); 

can_ok($other_box, 'flipVertical');
$other_box->flipVertical();
is($other_box->getAsString, ".------.\n| test |\n=------=", '... we got the string we expected'); 

can_ok($box, 'pasteRight');
can_ok($box, 'pasteLeft');
can_ok($box, 'pasteTop');
can_ok($box, 'pasteBottom');

my $box2 = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                '+-------+',
                '| test2 |',
                '+-------+'
                ));
isa_ok($box2, 'Tree::Visualize::ASCII::BoundingBox'); 

$box->padRight("  ");
$box->pasteRight($box2);

cmp_ok($box->height, '==', 3, '... the height of this box is 3');
cmp_ok($box->width, '==', 19, '... the width of this box is 19');

is_deeply([ $box->getLinesAsArray ],
          ['+------+  +-------+',
           '| test |  | test2 |',
           '+------+  +-------+'],
          '... got the array of lines we expected');

is($box->getAsString, 
   "+------+  +-------+\n" .
   "| test |  | test2 |\n" . 
   "+------+  +-------+", 
   '... we got the string we expected');
   
$box->padLeft("  ");
$box->pasteLeft($box2);

cmp_ok($box->height, '==', 3, '... the height of this box is 3');
cmp_ok($box->width, '==', 30, '... the width of this box is 30');

is_deeply([ $box->getLinesAsArray ],
          ['+-------+  +------+  +-------+',
           '| test2 |  | test |  | test2 |',
           '+-------+  +------+  +-------+'],
          '... got the array of lines we expected');

is($box->getAsString, 
   "+-------+  +------+  +-------+\n" .
   "| test2 |  | test |  | test2 |\n" . 
   "+-------+  +------+  +-------+", 
   '... we got the string we expected'); 
   
$box->pasteBottom($box2);   
   
cmp_ok($box->height, '==', 6, '... the height of this box is 6');
cmp_ok($box->width, '==', 30, '... the width of this box is 30');

is_deeply([ $box->getLinesAsArray ],
          ['+-------+  +------+  +-------+',
           '| test2 |  | test |  | test2 |',
           '+-------+  +------+  +-------+',
           '+-------+                     ',
           '| test2 |                     ',
           '+-------+                     '],
          '... got the array of lines we expected');

is($box->getAsString, 
   "+-------+  +------+  +-------+\n" .
   "| test2 |  | test |  | test2 |\n" . 
   "+-------+  +------+  +-------+\n" .
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     ", 
   '... we got the string we expected');        
       
$box->pasteTop($box2);   
             
cmp_ok($box->height, '==', 9, '... the height of this box is 9');
cmp_ok($box->width, '==', 30, '... the width of this box is 30');

is_deeply([ $box->getLinesAsArray ],
          ['+-------+                     ',
           '| test2 |                     ',
           '+-------+                     ',
           '+-------+  +------+  +-------+',
           '| test2 |  | test |  | test2 |',
           '+-------+  +------+  +-------+',
           '+-------+                     ',
           '| test2 |                     ',
           '+-------+                     '],
          '... got the array of lines we expected');

is($box->getAsString, 
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     \n" .
   "+-------+  +------+  +-------+\n" .
   "| test2 |  | test |  | test2 |\n" . 
   "+-------+  +------+  +-------+\n" .
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     ", 
   '... we got the string we expected');     
   
$box2->pasteTop($box);   
             
cmp_ok($box2->height, '==', 12, '... the height of this box is 12');
cmp_ok($box2->width, '==', 30, '... the width of this box is 30');

is_deeply([ $box2->getLinesAsArray ],
          ['+-------+                     ',
           '| test2 |                     ',
           '+-------+                     ',
           '+-------+  +------+  +-------+',
           '| test2 |  | test |  | test2 |',
           '+-------+  +------+  +-------+',
           '+-------+                     ',
           '| test2 |                     ',
           '+-------+                     ',
           '+-------+                     ',
           '| test2 |                     ',
           '+-------+                     '],
          '... got the array of lines we expected');

is($box2->getAsString, 
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     \n" .
   "+-------+  +------+  +-------+\n" .
   "| test2 |  | test |  | test2 |\n" . 
   "+-------+  +------+  +-------+\n" .
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     \n" .
   "+-------+                     \n" .
   "| test2 |                     \n" . 
   "+-------+                     ", 
   '... we got the string we expected');    
   
  
my $box3 = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                '+-------+',
                '| test3 |',
                '+-------+'
                ));
isa_ok($box3, 'Tree::Visualize::ASCII::BoundingBox');  
   
$box2->pasteRight($box3);   
             
cmp_ok($box2->height, '==', 12, '... the height of this box is 12');
cmp_ok($box2->width, '==', 39, '... the width of this box is 39');

is_deeply([ $box2->getLinesAsArray ],
          ['+-------+                     +-------+',
           '| test2 |                     | test3 |',
           '+-------+                     +-------+',
           '+-------+  +------+  +-------+         ',
           '| test2 |  | test |  | test2 |         ',
           '+-------+  +------+  +-------+         ',
           '+-------+                              ',
           '| test2 |                              ',
           '+-------+                              ',
           '+-------+                              ',
           '| test2 |                              ',
           '+-------+                              '],
          '... got the array of lines we expected');

is($box2->getAsString, 
   "+-------+                     +-------+\n" .
   "| test2 |                     | test3 |\n" . 
   "+-------+                     +-------+\n" .
   "+-------+  +------+  +-------+         \n" .
   "| test2 |  | test |  | test2 |         \n" . 
   "+-------+  +------+  +-------+         \n" .
   "+-------+                              \n" .
   "| test2 |                              \n" . 
   "+-------+                              \n" .
   "+-------+                              \n" .
   "| test2 |                              \n" . 
   "+-------+                              ", 
   '... we got the string we expected');     
   
$box3->pasteBottom($box2);   
             
cmp_ok($box3->height, '==', 15, '... the height of this box is 15');
cmp_ok($box3->width, '==', 39, '... the width of this box is 39');

is_deeply([ $box3->getLinesAsArray ],
          ['+-------+                              ',
           '| test3 |                              ',
           '+-------+                              ',
           '+-------+                     +-------+',
           '| test2 |                     | test3 |',
           '+-------+                     +-------+',
           '+-------+  +------+  +-------+         ',
           '| test2 |  | test |  | test2 |         ',
           '+-------+  +------+  +-------+         ',
           '+-------+                              ',
           '| test2 |                              ',
           '+-------+                              ',
           '+-------+                              ',
           '| test2 |                              ',
           '+-------+                              '],
          '... got the array of lines we expected');

is($box3->getAsString, 
   "+-------+                              \n" .
   "| test3 |                              \n" . 
   "+-------+                              \n" . 
   "+-------+                     +-------+\n" .
   "| test2 |                     | test3 |\n" . 
   "+-------+                     +-------+\n" .
   "+-------+  +------+  +-------+         \n" .
   "| test2 |  | test |  | test2 |         \n" . 
   "+-------+  +------+  +-------+         \n" .
   "+-------+                              \n" .
   "| test2 |                              \n" . 
   "+-------+                              \n" .
   "+-------+                              \n" .
   "| test2 |                              \n" . 
   "+-------+                              ", 
   '... we got the string we expected');    

