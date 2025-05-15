#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

is(
    table(
        rows => [
            ["value", "printed"],
            ["zero (number)", 0],
            ["empty string", ""],
            ["undef", undef],
            ["zero (string)", "0"],
            ["zero point zero (string)", "0.0"],
            ["one (number)", 1],
        ],
        header_row => 1,
    ), <<'HTML', 'false values');
<table>
<thead>
<tr><th>value</th><th>printed</th></tr>
</thead>
<tbody>
<tr><td>zero (number)</td><td>0</td></tr>
<tr><td>empty string</td><td></td></tr>
<tr><td>undef</td><td></td></tr>
<tr><td>zero (string)</td><td>0</td></tr>
<tr><td>zero point zero (string)</td><td>0.0</td></tr>
<tr><td>one (number)</td><td>1</td></tr>
</tbody>
</table>
HTML

done_testing;
