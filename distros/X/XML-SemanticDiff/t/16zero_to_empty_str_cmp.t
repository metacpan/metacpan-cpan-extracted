#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 18;

use XML::SemanticDiff;

my $xml_attr_0 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="0"/>
</root>
EOX

my $xml_attr_empty_string = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr=""/>
</root>
EOX

my $xml_attr_missing = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 />
</root>
EOX

my $xml_elem_0 = <<'EOX';
<?xml version="1.0"?>
<root>
<el2>0</el2>
</root>
EOX

my $xml_elem_empty_string = <<'EOX';
<?xml version="1.0"?>
<root>
<el2></el2>
</root>
EOX

my $xml_elem_undef = <<'EOX';
<?xml version="1.0"?>
<root>
<el2 />
</root>
EOX

my ($diff, @results);

# TEST
$diff = XML::SemanticDiff->new(keepdata => 1, keeplinenums => 1);
@results = $diff->compare($xml_attr_0, $xml_attr_empty_string);
is (scalar(@results), 1,
    "Difference found between 0 and empty string in attr"
);

# TEST
is ($results[0]->{old_value}, 0, "check old value 0");
# TEST
is ($results[0]->{new_value}, '', "check new value empty_string");

# TEST
$diff = XML::SemanticDiff->new(keepdata => 1, keeplinenums => 1);
@results = $diff->compare($xml_attr_0, $xml_attr_missing);
is (scalar(@results), 1,
    "Difference found between 0 and missing attr"
);

# TEST
is ($results[0]->{old_value}, 0, "check old value 0");
# TEST
is ($results[0]->{new_value}, undef, "check new value undef");

# TEST
$diff = XML::SemanticDiff->new(keepdata => 1, keeplinenums => 1);
@results = $diff->compare($xml_elem_0, $xml_elem_empty_string);
is (scalar(@results), 1,
    "Difference found between 0 and empty string in elem(<el></el>)"
);

# TEST
is ($results[0]->{old_value}, 0, "check old value 0");
# TEST
is ($results[0]->{new_value}, undef, "check new value undef");

# TEST
$diff = XML::SemanticDiff->new(keepdata => 1, keeplinenums => 1);
@results = $diff->compare($xml_elem_0, $xml_elem_undef);
is (scalar(@results), 1,
    "Difference found between 0 and empty string in elem(<el />)"
);

# TEST
is ($results[0]->{old_value}, 0, "check old value 0");
# TEST
is ($results[0]->{new_value}, undef, "check new value undef");

# TEST
@results = $diff->compare($xml_attr_0, $xml_attr_0);
ok ((!@results), "Identical XMLs with attrs 0 generate identical results");

# TEST
@results = $diff->compare($xml_attr_empty_string, $xml_attr_empty_string);
ok ((!@results), "Identical XMLs with attrs empty_string generate identical results");

# TEST
@results = $diff->compare($xml_attr_missing, $xml_attr_missing);
ok ((!@results), "Identical XMLs with attrs missing generate identical results");

# TEST
@results = $diff->compare($xml_elem_0, $xml_elem_0);
ok ((!@results), "Identical XMLs with elem 0 generate identical results");

# TEST
@results = $diff->compare($xml_elem_empty_string, $xml_elem_empty_string);
ok ((!@results), "Identical XMLs with elem empty_string generate identical results");

# TEST
@results = $diff->compare($xml_elem_undef, $xml_elem_undef);
ok ((!@results), "Identical XMLs with elem undef generate identical results");


