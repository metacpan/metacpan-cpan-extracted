use Text::Flowchart;
 
 $flowchart = Text::Flowchart->new(
 	"width" => 50,
 	"directed" => 1);
 
 $begin = $flowchart->box(
 	"string" => "BEGIN",
 	"x_coord" => 0,
 	"y_coord" => 0,
 	"width"   => 9,
 	"y_pad"   => 0
 );
 
 $start = $flowchart->box(
 	"string" => "Do you need to make a flowchart?",
 	"x_coord" => 15,
 	"y_coord" => 0
 );
 
 $yes = $flowchart->box(
 	"string" => "Then my module may help.",
 	"x_coord" => 0,
 	"y_coord" => 10
 );
 
 $use = $flowchart->box(
 	"string" => "So use it.",
 	"x_coord" => 16,
 	"y_coord" => 8,
 	"width"	  => 14
 );
 
 $no = $flowchart->box(
 	"string" => "Then go do something else.",
 	"x_coord" => 30,
 	"y_coord" => 17
 );
 
 $flowchart->relate(
 	[$begin, "right"] => [$start, "left", 1]
 );
 
 $flowchart->relate(
 	[$start, "left", 3] => [$yes, "top", 5],
 	"reason" => "Y"
 );
 
 $flowchart->relate(
 	[$start, "right", 2] => [$no, "top", 5],
 	"reason" => "N"
 );
 
 $flowchart->relate(
 	[$yes, "right", 4] => [$use, "bottom", 2]
 );
 
 $flowchart->relate(
 	[$use, "bottom", 6] => [$no, "left", 2]
 );
 
 $flowchart->draw();

print "I drew my flowchart.  I'm content\n";
