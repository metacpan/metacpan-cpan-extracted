use Test::More;

use_ok 'Unicode::Number';

my $uni = Unicode::Number->new();

my $data = {
	Sinhala => 9999,
	Egyptian => 9999999,
	'Arabic_Alphabetic' => 1999,
	'Lao' => 0+'inf',
	'Western' => 0+'inf',
};

my ($ns_name, $max);
while( ($ns_name,$max) = each %$data ) {
	is( $uni->get_number_system_by_name($ns_name)->maximum_value->to_numeric,
		$max, "maximum value for $ns_name");
}


done_testing;
