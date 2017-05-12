#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my %vars = (
    data => [1 .. 9],
);

my @set = (
    [<<'T', <<'X'],
{html_table loop=$data}
T
<table border="1">
<tbody>
<tr><td>1</td><td>2</td><td>3</td></tr>
<tr><td>4</td><td>5</td><td>6</td></tr>
<tr><td>7</td><td>8</td><td>9</td></tr>
</tbody>
</table>
X

    [<<'T', <<'X'],
{html_table loop=$data cols=4 table_attr='class=foo'}
T
<table class="foo">
<tbody>
<tr><td>1</td><td>2</td><td>3</td><td>4</td></tr>
<tr><td>5</td><td>6</td><td>7</td><td>8</td></tr>
<tr><td>9</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
</tbody>
</table>
X

    [<<'T', <<'X'],
{html_table loop=$data cols="first,second,third,fourth" tr_attr=['class=a', 'class=b']}
T
<table border="1">
<thead>
<tr>
<th>first</th><th>second</th><th>third</th><th>fourth</th>
</tr>
</thead>
<tbody>
<tr class="a"><td>1</td><td>2</td><td>3</td><td>4</td></tr>
<tr class="b"><td>5</td><td>6</td><td>7</td><td>8</td></tr>
<tr class="a"><td>9</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
</tbody>
</table>
X
);

for my $d(@set) {
    my($source, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, \%vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
