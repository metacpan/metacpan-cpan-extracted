#! perl

use Test2::V0;
use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

subtest cell => sub {

    is(
        table(
            rows => [
                [ { text => 'TD11' }, { text => 'TD12', bottom_border => 1 } ],
                ['TD21'],
            ]
        ),
        <<'EOS', 'rowspan' );
<table>
<tbody>
<tr class=has_bottom_border><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td></tr>
</tbody>
</table>
EOS

};

subtest 'all rows' => sub {

    is(
        table(
            rows => [
                [ { text => 'TD11' }, { text => 'TD12' } ],
                ['TD21'],
            ],
            separate_rows => 1,
        ),
        <<'EOS', 'rowspan' );
<table>
<tbody>
<tr class=has_bottom_border><td>TD11</td><td>TD12</td></tr>
<tr><td>TD21</td></tr>
</tbody>
</table>
EOS

};

done_testing;
