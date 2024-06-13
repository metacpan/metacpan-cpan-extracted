#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

is( table( rows => [ [  { html_element => 'th', text => 'TD11' }, { text => 'TD12' } ],
                 ] ), <<'EOS', 'coltag' );
<table>
<tbody>
<tr><th>TD11</th><td>TD12</td></tr>
</tbody>
</table>
EOS

done_testing;
