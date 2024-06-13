#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

is( table( html_attr => { style => 'border: 3px solid purple;',  },
           rows => [ [ 1..2 ],
                 ] ), <<'EOS', 'table attr' );
<table style="border: 3px solid purple;">
<tbody>
<tr><td>1</td><td>2</td></tr>
</tbody>
</table>
EOS


is( table( header_row => 1,
           rows => [ [ { text => 'text', align => 'left', html_scope => 'col', html_style => "timeless" }  ],
                 ] ), <<'EOS', 'cell attr' );
<table>
<thead>
<tr><th align="left" scope="col" style="timeless">text</th></tr>
</thead>
<tbody>
</tbody>
</table>
EOS

done_testing;
