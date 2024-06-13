#! perl

use Test2::V0;

use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

sub rows {
    [
        [ 'TH11', 'TH12' ],
        [ 'TH21', 'TH22' ],
        [ 'TF11', 'TF12' ],
        [ 'TD11', 'TD12' ],
        [ 'TD21', 'TD22' ],
        [ 'TF21', 'TF22' ],
        [ 'TF31', 'TF32' ],
    ]
}

is ( table( rows => rows(),
            header_row => 0,
            footer_row => 1,
        ), <<'EOS', 'no header rows, one front footer row ' );
<table>
<tfoot>
<tr><td>TH11</td><td>TH12</td></tr>
</tfoot>
<tbody>
<tr><td>TH21</td><td>TH22</td></tr>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(),
            header_row => 1,
        ), <<'EOS', 'one header row' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
</thead>
<tbody>
<tr><td>TH21</td><td>TH22</td></tr>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(),
            header_row => 1,
            footer_row => 1,
     ), <<'EOS', 'one header row, one front footer row ' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
</thead>
<tfoot>
<tr><td>TH21</td><td>TH22</td></tr>
</tfoot>
<tbody>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(),
            header_row => 2,
            footer_row => 1,
     ), <<'EOS', 'two header rows, one front footer row ' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
<tr><th>TH21</th><th>TH22</th></tr>
</thead>
<tfoot>
<tr><td>TF11</td><td>TF12</td></tr>
</tfoot>
<tbody>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(),
            header_row => 2,
            footer_row => 2,
     ), <<'EOS', 'two header rows, two front footer rows' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
<tr><th>TH21</th><th>TH22</th></tr>
</thead>
<tfoot>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
</tfoot>
<tbody>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tbody>
</table>
EOS

is ( table( rows => rows(),
            header_row => 2,
            footer_row => -1,
     ), <<'EOS', 'two header rows, one trailing footer row' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
<tr><th>TH21</th><th>TH22</th></tr>
</thead>
<tbody>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
<tr><td>TF21</td><td>TF22</td></tr>
</tbody>
<tfoot>
<tr><td>TF31</td><td>TF32</td></tr>
</tfoot>
</table>
EOS

is ( table( rows => rows(),
            header_row => 2,
            footer_row => -2,
     ), <<'EOS', 'two header rows, two trailing footer rows' );
<table>
<thead>
<tr><th>TH11</th><th>TH12</th></tr>
<tr><th>TH21</th><th>TH22</th></tr>
</thead>
<tbody>
<tr><td>TF11</td><td>TF12</td></tr>
<tr><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td><td>TD22</td></tr>
</tbody>
<tfoot>
<tr><td>TF21</td><td>TF22</td></tr>
<tr><td>TF31</td><td>TF32</td></tr>
</tfoot>
</table>
EOS

done_testing;
