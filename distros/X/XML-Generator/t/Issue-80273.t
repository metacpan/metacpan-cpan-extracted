use strict;

use Test::More qw/ tests 1 /;

use XML::Generator;

my $XML = XML::Generator->new(conformance => "strict");

my $result = $XML->record(join "\n", map { my ($k, $v) = @{$_}; $XML->$k($v); }
                (
                    [threat => 1],
                    [desc => "godzilla"],
                    [value => "http://y.ahoooooooooo.it/0weifjwef"],
                    [detected => "2012-10-16 00:00:00"]
                ));

my $expected_result = '<record><threat>1</threat>
<desc>godzilla</desc>
<value>http://y.ahoooooooooo.it/0weifjwef</value>
<detected>2012-10-16 00:00:00</detected></record>';

ok($result eq $expected_result, 'Got expected results');
exit;
$XML = XML::Generator->new();

$result = $XML->record(
                    join "\n", map { my ($k, $v) = @{$_}; $XML->$k($v); }
                    (
                        [threat => 1],
                        [desc => "gozdilla"],
                        [value => "http://y.ahoooooooooo.it/0weifjwef"],
                        [detected => "2012-10-16 00:00:00"]
                    ));

$expected_result = '<record><threat>1</threat>
<desc>gozdilla</desc>
<value>http://y.ahoooooooooo.it/0weifjwef</value>
<detected>2012-10-16 00:00:00</detected></record>';

ok($result eq $expected_result, 'Got expected results');

my $XML = XML::Generator->new(conformance => "strict", pretty => 1);

$result = $XML->record(
                        map { my ($k, $v) = @{$_}; $XML->$k($v); }
                        (
                            [threat => 1],
                            [desc => "godzilla"],
                            [value => "http://y.ahoooooooooo.it/0weifjwef"],
                            [detected => "2012-10-16 00:00:00"]
                        ));

$expected_result = '<record>
 <threat>1</threat>
 <desc>godzilla</desc>
 <value>http://y.ahoooooooooo.it/0weifjwef</value>
 <detected>2012-10-16 00:00:00</detected>
</record>';

ok($result eq $expected_result, 'Got expected results');

$XML = XML::Generator->new(conformance => "strict", pretty => 1);

$result = $XML->record(
                map { my ($k, $v) = @{$_}; $XML->$k($v); }
                (
                    [threat => 1],
                    [desc => "godzilla"],
                    [value => "http://y.ahoooooooooo.it/0weifjwef"],
                    [detected => "2012-10-16 00:00:00"]
                ));

$expected_result = '<record>
 <threat>1</threat>
 <desc>godzilla</desc>
 <value>http://y.ahoooooooooo.it/0weifjwef</value>
 <detected>2012-10-16 00:00:00</detected>
</record>';

ok($result eq $expected_result, 'Got expected results');
