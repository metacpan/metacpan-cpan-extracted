#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 100  }, <<'X'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id  separator='<br />'}
T
<label><input type="checkbox" name="id" value="100" checked="checked" />Joe</label><br />
<label><input type="checkbox" name="id" value="101" />Jack</label><br />
<label><input type="checkbox" name="id" value="102" />Jane</label><br />
X

    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 101  }, <<'X'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id  separator='<br />'}
T
<label><input type="checkbox" name="id" value="100" />Joe</label><br />
<label><input type="checkbox" name="id" value="101" checked="checked" />Jack</label><br />
<label><input type="checkbox" name="id" value="102" />Jane</label><br />
X
    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 102  }, <<'X'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id  separator='<br />'}
T
<label><input type="checkbox" name="id" value="100" />Joe</label><br />
<label><input type="checkbox" name="id" value="101" />Jack</label><br />
<label><input type="checkbox" name="id" value="102" checked="checked" />Jane</label><br />
X
    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => [101, 102]  }, <<'X', 'multiple selected'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id  separator='<br />'}
T
<label><input type="checkbox" name="id" value="100" />Joe</label><br />
<label><input type="checkbox" name="id" value="101" checked="checked" />Jack</label><br />
<label><input type="checkbox" name="id" value="102" checked="checked" />Jane</label><br />
X


    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 101  }, <<'X', 'no selected'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
    separator='<br />'}
T
<label><input type="checkbox" name="id" value="100" />Joe</label><br />
<label><input type="checkbox" name="id" value="101" />Jack</label><br />
<label><input type="checkbox" name="id" value="102" />Jane</label><br />
X

    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 101  }, <<'X', 'no separator'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id }
T
<label><input type="checkbox" name="id" value="100" />Joe</label>
<label><input type="checkbox" name="id" value="101" checked="checked" />Jack</label>
<label><input type="checkbox" name="id" value="102" />Jane</label>
X

    [<<'T', { cust_ids => [100, 101, 102], cust_names => [qw(Joe Jack Jane)], customer_id => 101  }, <<'X', 'labels=false'],
{html_checkboxes name='id' values=$cust_ids output=$cust_names
   selected=$customer_id  separator='<br />' labels=false}
T
<input type="checkbox" name="id" value="100" />Joe<br />
<input type="checkbox" name="id" value="101" checked="checked" />Jack<br />
<input type="checkbox" name="id" value="102" />Jane<br />
X


    [<<'T', { cust => [[100, 'Joe'], [101, 'Jack']], customer_id => 100  }, <<'X', 'options'],
{html_checkboxes name='id' options=$cust selected=$customer_id}
T
<label><input type="checkbox" name="id" value="100" checked="checked" />Joe</label>
<label><input type="checkbox" name="id" value="101" />Jack</label>
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
