#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw(no_plan);

my $htmltmp = "/tmp/sel2html.tmp.$$";
END { unlink $htmltmp };
open(my $fh, ">$htmltmp") or die "Can't open $htmltmp: $!";
print $fh <<'EOT';
<html>
<head><title>New Test</title></head>
<body>
<table cellpadding="1" cellspacing="1" border="1">
<thead>
<tr><td rowspan="1" colspan="3">New Test</td></tr>
</thead><tbody>
<tr>
    <td>open</td>
    <td>/some/url</td>
    <td></td>
</tr>
<tr>
    <td>clickAndWait</td>
    <td>link=Some Link</td>
    <td></td>
</tr>
<tr>
    <td>type</td>
    <td>add_address</td>
    <td>**@example.net</td>
</tr>
<tr>
    <td>clickAndWait</td>
    <td>//input[@type='submit' and @value='Add Sender']</td>
    <td></td>
</tr>

</tbody></table>
</body>
</html>
EOT
close $fh or die "Can't write $htmltmp: $!";

my $expected_wiki = <<'EOT';
| New Test |
| open | /some/url |
| clickAndWait | link=Some Link |
| type | add_address | **@example.net |
| clickAndWait | //input[@type='submit' and @value='Add Sender'] |
EOT

my $sel2wiki = "bin/sel2wiki";

Invalid_input: {
    my $output = qx(echo "foo" | $^X $sel2wiki 2>&1);
    like $output, qr#USAGE#;
}

Input_as_filename: {
    my $output = qx($^X $sel2wiki $htmltmp);
    is $output, $expected_wiki;
}

Input_as_STDIN: {
    my $output = qx(cat $htmltmp | $^X $sel2wiki);
    is $output, $expected_wiki;
}
