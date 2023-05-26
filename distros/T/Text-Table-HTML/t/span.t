#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

is( table( rows => [ [  { text => 'TD11', rowspan => 1 }, { text => 'TD12', rowspan => 2 } ],
                     [ 'TD21'  ],
                 ] ), <<'EOS', 'rowspan' );
<table>
<tbody>
<tr><td>TD11</td><td rowspan=2>TD12</td></tr>
<tr><td>TD21</td></tr>
</tbody>
</table>
EOS

is( table( rows => [ [  { text => 'TD11', colspan => 1 }, { text => 'TD12', colspan => 2 } ],
                     [ 'TD21', 'TD22', 'TD23'  ],
                 ] ), <<'EOS', 'colspan' );
<table>
<tbody>
<tr><td>TD11</td><td colspan=2>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td><td>TD23</td></tr>
</tbody>
</table>
EOS

done_testing;
