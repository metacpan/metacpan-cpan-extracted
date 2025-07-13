use Test::More;
use autobox::Text;

$\ = "\n"; $, = "\t";

my $t = <<EOF
Et eos et aut id. Consequatur praesentium nemo alias tenetur iure. Sunt enim illo quam sint est vitae eos. Tempora sunt qui eum doloremque praesentium sint vel adipisci. Natus quisquam porro in vero dolor omnis ut atque.Accusantium et iste eveniet ex fugiat.

Enim id rerum eius deleniti voluptas cumque. Ut ut maiores consequatur consequatur sequi. Dolores qui eaque nesciunt rerum explicabo rem animi consequatur.Dolor modi qui mollitia amet qui animi tenetur id.

Aut quam soluta unde accusantium neque dolorem ipsum. Nulla voluptatem in et dolores aperiam dolor animi.Alias quod iste officiis non similique repudiandae placeat. Enim nihil corporis voluptatem.
EOF
;

my @t = (
	 <<EOF
Et eos et aut id. Consequatur praesentium nemo alias tenetur iure. Sunt enim
illo quam sint est vitae eos. Tempora sunt qui eum doloremque praesentium sint
vel adipisci. Natus quisquam porro in vero dolor omnis ut atque.Accusantium et
iste eveniet ex fugiat.

Enim id rerum eius deleniti voluptas cumque. Ut ut maiores consequatur
consequatur sequi. Dolores qui eaque nesciunt rerum explicabo rem animi
consequatur.Dolor modi qui mollitia amet qui animi tenetur id.

Aut quam soluta unde accusantium neque dolorem ipsum. Nulla voluptatem in et
dolores aperiam dolor animi.Alias quod iste officiis non similique repudiandae
placeat. Enim nihil corporis voluptatem.
EOF
	 ,

	);

is ($t->wrap, (shift @t), "wrap");
is ($t, $t->wrap->unwrap . "\n", "wrap and unwrap");

done_testing()
