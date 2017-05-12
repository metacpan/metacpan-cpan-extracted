use Test;
BEGIN { plan tests => 4 }

use XML::SemanticDiff;

my $xml1 = <<'EOX';
<?xml version="1.0"?>
<root xmlns="http://localhost/foo">
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el3/>
</root>
EOX

my $xml2 = <<'EOX';
<?xml version="1.0"?>
<foo:root xmlns:foo="http://localhost/foo">
<foo:el1 el1attr="good"/>
<foo:el2 el2attr="good">Some Text</foo:el2>
<foo:el3/>
</foo:root>
EOX

my $xml3 = <<'EOX';
<?xml version="1.0"?>
<root xmlns="http://localhost/foo">
<el1 xmlns="http://localhost/bar" el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el3/>
</root>
EOX

my $diff = XML::SemanticDiff->new();

my @results = $diff->compare($xml1, $xml2);

ok(@results == 0);

@results = $diff->compare($xml1, $xml3);

ok(@results == 1);

ok($results[0]->{context} eq '/root[1]/el1[1]');

ok($results[0]->{message} =~ /namespace/gi);

