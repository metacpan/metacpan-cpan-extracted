use Test;
BEGIN { plan tests => 3 }

use XML::SemanticDiff;

$xml1 = <<'EOX';
<?xml version="1.0"?>
<?xml-stylesheet href="." type="text/xsl"?>
<root>
<el1 blarg="."/>
</root>
EOX

$xml2 = <<'EOX';
<?xml version="1.0"?>
<?xml-stylesheet href="." type="application/x-ubuparser" extra="bogus" ?>
<root>
<el1 blarg="."/>
</root>
EOX

$xml3 = <<'EOX';
<?xml version="1.0"?>
<?xml-stylesheet href="." type="text/xsl"?>
<?xml-stylesheet href="mysheet.xsl" type="text/xsl"?>
<root>
<el1 blarg="."/>
</root>
EOX


my $diff = XML::SemanticDiff->new();

my @results = $diff->compare($xml1, $xml2);

ok(@results == 2);

@results = $diff->compare($xml1, $xml1);

ok(@results == 0);

my $full = XML::SemanticDiff->new(keepdata => 1, keeplinenums => 1);

@results = $full->compare($xml1, $xml3);

#foreach my $msg (@results) {
#  warn "RES " . $msg->{startline} . "\n";
#}

ok(@results == 1);




