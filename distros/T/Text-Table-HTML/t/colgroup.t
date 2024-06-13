#! perl

use Test2::V0;

use Text::Table::HTML;

*table = \&Text::Table::HTML::table;

sub rows {
    [
        [ 1..5 ],
    ]
}

is ( table( rows => rows(),
            html_colgroup => [ undef, {}, q{span="2"}, { class => 'batman' } ]
        ), <<'EOS', 'no header' );
<table>
<colgroup>
<col />
<col />
<col span="2" />
<col class="batman" />
</colgroup>
<tbody>
<tr><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td></tr>
</tbody>
</table>
EOS

done_testing;
