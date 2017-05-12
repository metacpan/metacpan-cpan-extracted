
$::db_type = 'fulcrum';
print "$::db_type\n";

require "t/lib.pl";

sub relevance_info {
    return {
	'field' => 'rel',
	'order' => 'rel desc,',
	'select' => "relevance('2:2') as rel,",
    };
}

# Local Variables: ***
# mode: perl ***
# End: ***
