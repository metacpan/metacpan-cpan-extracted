#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

is( table( rows => [ [ 'TD11', 'TD12' ],
                     [ 'TD21', 'TD22' ],
                 ] ), <<'EOS', 'simple table' );
<table>
<tbody>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
</tbody>
</table>
EOS

is( table( rows => [], caption => '3 is < 2', ),
    <<'EOS', 'caption with entities' );
<table>
<caption>3 is &lt; 2</caption>
<tbody>
</tbody>
</table>
EOS

is( table( rows => [
    [ '<text>' ]
] ), <<'EOS', 'encoded text' );
<table>
<tbody>
<tr><td>&lt;text&gt;</td></tr>
</tbody>
</table>
EOS

is( table( rows => [
    [ { text => '<text>' } ]
] ), <<'EOS', 'cell as hash, encoded' );
<table>
<tbody>
<tr><td>&lt;text&gt;</td></tr>
</tbody>
</table>
EOS

is( table( rows => [
    [ { raw_html => '<a ref="#name"/>text' } ]
] ), <<'EOS', 'cell as hash, raw' );
<table>
<tbody>
<tr><td><a ref="#name"/>text</td></tr>
</tbody>
</table>
EOS

done_testing;
