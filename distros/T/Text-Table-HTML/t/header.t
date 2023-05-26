#! perl

use Test2::V0;

use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

sub rows {
    [
        [ 'TH11', 'TH12' ],
        [ 'TH21', 'TH22' ],
        [ 'TD11', 'TD12' ],
        [ 'TD21', 'TD22' ],
    ]
}

is ( table( rows => rows() ), <<'EOS', 'no header' );
<table>
<tbody>
<tr><td>TH11</td><td>TH12</td></tr>
<tr><td>TH21</td><td>TH22</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(), header_row => 1 ), <<'EOS', 'one header row' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
</thead>
<tbody>
<tr><td>TH21</td><td>TH22</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(), header_row => 2 ), <<'EOS', 'two header rows' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
<tr><th>TH21</th><th>TH22</th></tr>
</thead>
<tbody>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
</tbody>
</table>
EOS

done_testing;
