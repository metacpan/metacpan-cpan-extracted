use strict;
use warnings;

use Test::More tests => 1;

# This file fixes:
# https://rt.cpan.org/Public/Bug/Display.html?id=68631 .

use Text::Table;

{

    my @col_titles = ( "Radius\nkm", "Density\ng/cm^3" );
    my $tb = Text::Table->new(
       {  is_sep => 1,
          title  => '| ',
          body   => '| ', },
       {  title       => 'Planet',
          align_title => 'center', },
       (  map {
             (  {  is_sep => 1,
                   title  => ' | ',
                   body   => ' | ', },
                {  title       => $_,
                   align_title => 'center', }, )
             } @col_titles ),
       {  is_sep => 1,
          title  => ' |',
          body   => ' |', }, );

    $tb->load(
       [ "Mercury", 2360,  3.7 ],
       [ "Venus",   6110,  5.1 ],
       [ "Earth",   6378,  5.52 ],
       [ "Jupiter", 71030, 1.3 ], );

    my $o = '';
    $o .= $tb->rule( q{-}, q{+} );
    $o .= $tb->title();
    $o .= $tb->rule( q{-}, q{+} );
    $o .= $tb->body();
    $o .= $tb->rule( q{-}, q{+} );

    # TEST
    is($o, <<'EOF', 'Passing hashrefs as separators.');
+---------+--------+---------+
| Planet  | Radius | Density |
|         |   km   | g/cm^3  |
+---------+--------+---------+
| Mercury |   2360 |  3.7    |
| Venus   |   6110 |  5.1    |
| Earth   |   6378 |  5.52   |
| Jupiter |  71030 |  1.3    |
+---------+--------+---------+
EOF
}
