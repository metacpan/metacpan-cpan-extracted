#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', { cust => [ [100, 'Joe'], [101, 'Jack'] ], id => 100  }, <<'X'],
{html_radios name=x options=$cust selected=$id separator="<br />"}
T
<label for="x_100"><input type="radio" name="x" value="100" id="x_100" checked="checked" />Joe</label><br />
<label for="x_101"><input type="radio" name="x" value="101" id="x_101" />Jack</label><br />
X

    [<<'T', { cust => [ [100, 'Joe'], [101, 'Jack'] ], id => 101  }, <<'X'],
{html_radios options=$cust selected=$id}
T
<label for="radio_100"><input type="radio" name="radio" value="100" id="radio_100" />Joe</label>
<label for="radio_101"><input type="radio" name="radio" value="101" id="radio_101" checked="checked" />Jack</label>
X


    [<<'T', { cust_ids => [ 100, 101 ], cust_names => [ 'Joe', 'Jack'], id => 101  }, <<'X'],
{html_radios values=$cust_ids output=$cust_names selected=$id}
T
<label for="radio_100"><input type="radio" name="radio" value="100" id="radio_100" />Joe</label>
<label for="radio_101"><input type="radio" name="radio" value="101" id="radio_101" checked="checked" />Jack</label>
X

    [<<'T', { cust_ids => [ 100, 101 ], cust_names => [ 'Joe', 'Jack'], id => 101  }, <<'X'],
{html_radios values=$cust_ids output=$cust_names selected=$id class="foo"}
T
<label for="radio_100"><input type="radio" name="radio" value="100" id="radio_100" class="foo" />Joe</label>
<label for="radio_101"><input type="radio" name="radio" value="101" id="radio_101" checked="checked" class="foo" />Jack</label>
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
