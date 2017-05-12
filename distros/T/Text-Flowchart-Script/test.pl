use Test;
BEGIN { plan tests => 3 };
ok(1);

use Text::Flowchart::Script;
my $p = Text::Flowchart::Script->new();
$src = <<SRC;
    init : width => 50, directed => 0;
        begin = box :
                string  => "BEGIN",
                x_coord => 0,
                y_coord => 0,
                width   => 9,
                y_pad   => 0
    ;


        start = box :
                string => 'Do you need to make a flowchart?',
                x_coord => 15,
                y_coord => 0
    ;


        yes = box :
                string => "Then my module may help.",
                x_coord => 0,
                y_coord => 10
    ;

        use = box :
               string => "So use it.",
               x_coord => 16,
               y_coord => 8,
               width   => 14
    ;

        no = box:
               string => "Then go do something else.",
               x_coord => 30,
               y_coord => 17
    ;


        relate
                : begin, "right"
    : start, "left", 1;


        relate
                : start, "left", 3
                : yes, "top", 5
    : reason => "Y";

        relate
                : start, "right", 2
                : no, "top", 5
    : reason => "N";

        relate
                : yes, "right", 4
    : use, "bottom", 2;

        relate
                : use, "bottom", 6
    : no, "left", 2;


SRC

$p->parse($src);

ok( $/.$p->render, '
+-------+      +-------------+                    
| BEGIN +---+  |             |                    
+-------+   +--+ Do you need |                    
               | to make a   +------+             
      +--------+ flowchart?  |      |             
      |        |             |      |             
      |        +-------------+      |             
      |                             |             
      |         +------------+      |             
      |         |            |      |             
+-----+-------+ | So use it. |      |             
|             | |            |      |             
| Then my     | +--+---+-----+      |             
| module may  |    |   |            |             
| help.       |    |   |            |             
|             +----+   |            |             
+-------------+        |            |             
                       |      +-----+-------+     
                       |      |             |     
                       |      | Then go do  |     
                       +------+ something   |     
                              | else.       |     
                              |             |     
                              +-------------+     
');

ok(($p->debug), <<'CODE');
use Text::Flowchart; use IO::Scalar; 

my $_output; tie *OUT, 'IO::Scalar', \$_output;
$Text::Flowchart::Script::chart = Text::Flowchart->new('width',50,'directed',0);
$Text::Flowchart::Script::_begin = $Text::Flowchart::Script::chart->box('string',"BEGIN",'x_coord',0,'y_coord',0,'width',9,'y_pad',0);
$Text::Flowchart::Script::_start = $Text::Flowchart::Script::chart->box('string','Do you need to make a flowchart?','x_coord',15,'y_coord',0);
$Text::Flowchart::Script::_yes = $Text::Flowchart::Script::chart->box('string',"Then my module may help.",'x_coord',0,'y_coord',10);
$Text::Flowchart::Script::_use = $Text::Flowchart::Script::chart->box('string',"So use it.",'x_coord',16,'y_coord',8,'width',14);
$Text::Flowchart::Script::_no = $Text::Flowchart::Script::chart->box('string',"Then go do something else.",'x_coord',30,'y_coord',17);
$Text::Flowchart::Script::chart->relate([$Text::Flowchart::Script::_begin,"right"],[$Text::Flowchart::Script::_start,"left",1],);
$Text::Flowchart::Script::chart->relate([$Text::Flowchart::Script::_start,"left",3],[$Text::Flowchart::Script::_yes,"top",5],'reason',"Y");
$Text::Flowchart::Script::chart->relate([$Text::Flowchart::Script::_start,"right",2],[$Text::Flowchart::Script::_no,"top",5],'reason',"N");
$Text::Flowchart::Script::chart->relate([$Text::Flowchart::Script::_yes,"right",4],[$Text::Flowchart::Script::_use,"bottom",2],);
$Text::Flowchart::Script::chart->relate([$Text::Flowchart::Script::_use,"bottom",6],[$Text::Flowchart::Script::_no,"left",2],);

$Text::Flowchart::Script::chart->draw(*OUT); $output = $_output
CODE



