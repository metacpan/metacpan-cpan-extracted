#!perl -T

use strict;
use warnings;
use Test::More tests => 12;
use Text::SpanningTable;

my $t = Text::SpanningTable->new(14, 20, 10);

ok($t, 'Got a proper Text::SpanningTable object');

is($t->hr('top'), '.------------+------------------+--------.', 'top border');

is($t->row('one', 'two', 'three'), '| one        | two              | three  |', 'simple row');

is($t->row('if this van\'s a-rockin\', don\'t go a-nockin\'', 'what if there\'s more super monkeys up in that lab?', 'this little monkey could be responsible for the fall of the human race'), "| if this v- | what if there's  | this   |
| an's a-ro- | more super monk- | little |
| ckin', do- | eys up in that   |  monk- |
| n't go a-- | lab?             | ey co- |
| nockin'    |                  | uld be |
|            |                  |  resp- |
|            |                  | onsib- |
|            |                  | le for |
|            |                  |  the   |
|            |                  | fall   |
|            |                  | of the |
|            |                  |  human |
|            |                  |  race  |", 'row with extensive wrapping');

is($t->hr, '+------------+------------------+--------+', 'horizontal rule');

is($t->row([3, 'you maniacs, damn youse, god damn youse all to hell!!!']), '| you maniacs, damn youse, god damn you- |
| se all to hell!!!                      |', 'row with simple column spanning okay');

is($t->hr('bottom'), "'------------+------------------+--------'", 'bottom border');

my $output = '';

my $t2 = Text::SpanningTable->new(10, 20, 10, 30);

ok($t2, 'Second Text::SpanningTable object');

$t2->newlines(1);
$t2->exec(sub { my ($output, $string) = @_; $$output .= $string; }, \$output);

$t2->hr('top');
$t2->row('one', 'two', 'three', 'four');
$t2->dhr;
$t2->row('umm, snootiche-bootchies?', [2, 'Hey Kids! It\'s Mark Hamill!'], '[APPLAUSE]');
$t2->hr;
$t2->row([3, 'You thought I\'d never find you\'re precious Blunt-cave did you, Hempknight?'], 'Avenge me!');
$t2->hr;
$t2->row('any last words before I bust your balls Bluntman?', [3, 'Damn, these white boys can\'t fight']);
$t2->hr;
$t2->row('Hey, that wasn\'t in the script', 'so this is Hollywood?', [2, 'Aah, My God! Ahh! Oh, Oh my God!']);
$t2->hr;
$t2->row([4, 'Um, is he gonna be OK?']);
$t2->hr;
$t2->row('Not good...');
$t2->hr('bottom');

is($output, ".--------+------------------+--------+----------------------------.
| one    | two              | three  | four                       |
+========+==================+========+============================+
| umm,   | Hey Kids! It's Mark Hami- | [APPLAUSE]                 |
| snoot- | ll!                       |                            |
| iche-- |                           |                            |
| bootc- |                           |                            |
| hies?  |                           |                            |
+--------+------------------+--------+----------------------------+
| You thought I'd never find you're  | Avenge me!                 |
| precious Blunt-cave did you, Hemp- |                            |
| knight?                            |                            |
+--------+------------------+--------+----------------------------+
| any l- | Damn, these white boys can't fight                     |
| ast w- |                                                        |
| ords   |                                                        |
| before |                                                        |
|  I bu- |                                                        |
| st yo- |                                                        |
| ur ba- |                                                        |
| lls B- |                                                        |
| luntm- |                                                        |
| an?    |                                                        |
+--------+------------------+--------+----------------------------+
| Hey,   | so this is Holl- | Aah, My God! Ahh! Oh, Oh my God!    |
| that   | ywood?           |                                     |
| wasn't |                  |                                     |
|  in t- |                  |                                     |
| he sc- |                  |                                     |
| ript   |                  |                                     |
+--------+------------------+--------+----------------------------+
| Um, is he gonna be OK?                                          |
+--------+------------------+--------+----------------------------+
| Not g- |                  |        |                            |
| ood... |                  |        |                            |
'--------+------------------+--------+----------------------------'
", 'complex table with newlines and callback');

my $t3 = Text::SpanningTable->new;

ok($t3, 'third object');

$t3->hr('top');
$t3->row('100100100100100100101001010100101');
$t3->hr('bottom');

my $exp = ".--------------------------------------------------------------------------------------------------.
| 100100100100100100101001010100101                                                                |
'--------------------------------------------------------------------------------------------------'";

is($t3->output, $exp, 'output method');
is($t3->draw, $exp, 'draw method');

done_testing();
