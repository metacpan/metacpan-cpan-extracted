use Test::More tests => 5;

use_ok('Text::SimpleTable::AutoWidth');

my $t1 = Text::SimpleTable::AutoWidth->new();
$t1->row( 'Catalyst',          'rockz!' );
$t1->row( 'DBIx::Class',       'rockz!' );
$t1->row( 'Template::Toolkit', 'rockz!' );
is( $t1->draw, <<"EOF");
.-------------------+--------.
| Catalyst          | rockz! |
| DBIx::Class       | rockz! |
| Template::Toolkit | rockz! |
'-------------------+--------'
EOF

my $t2 = Text::SimpleTable::AutoWidth->new();
$t2->captions( [ 'ROCKZ!', 'Rockz!', 'rockz!' ] );
$t2->row( 'Catalyst', 'DBIx::Class', 'Template::Toolkit', 'HTML::Mason' );
is( $t2->draw, <<"EOF");
.----------+-------------+-------------------.
| ROCKZ!   | Rockz!      | rockz!            |
+----------+-------------+-------------------+
| Catalyst | DBIx::Class | Template::Toolkit |
'----------+-------------+-------------------'
EOF

my $t3 = Text::SimpleTable::AutoWidth->new( max_width => 9 );
$t3->row('Everything works!');
is( $t3->draw, <<"EOF");
.-------.
| Ever- |
| ythi- |
| ng w- |
| orks! |
'-------'
EOF

my $t4 = Text::SimpleTable::AutoWidth->new( fixed_width => 29 );
$t4->row('Everything works!');
is( $t4->draw, <<"EOF");
.---------------------------.
| Everything works!         |
'---------------------------'
EOF

