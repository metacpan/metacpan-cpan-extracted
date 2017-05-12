
$::db_type = 'mysql';
print "$::db_type\n";

require "t/lib.pl";

sub relevance_info {
    return {
	'field' => '',
	'order' => '',
	'select' => '',
    };
}

# Local Variables: ***
# mode: perl ***
# End: ***
