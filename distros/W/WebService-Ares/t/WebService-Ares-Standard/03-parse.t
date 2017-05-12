# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use WebService::Ares::Standard qw(parse);

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->dir('standard')->set;

# Test.
my $ret_hr = parse(scalar slurp($data_dir->file('ex1.xml')->s));
is_deeply(
	$ret_hr,
	{
		'address' => {
			'district' => decode_utf8('Hlavní město Praha'),
			'num' => 2178,
			'num2' => 6,
			'psc' => 19000,
			'street' => decode_utf8('Podvinný mlýn'),
			'town' => 'Praha',
			'town_part' => decode_utf8('Libeň'),
			'town_urban' => 'Praha 9',
		},
		'create_date' => '2003-08-06',
		'company' => 'Asseco Czech Republic, a.s.',
		'ic' => 27074358,
	},
	'Get information from ex1.xml file.',
);

# Test.
eval {
	parse('foo');
};
is($EVAL_ERROR, "Cannot parse XML string.\n", 'Cannot parse XML string.');
clean()
