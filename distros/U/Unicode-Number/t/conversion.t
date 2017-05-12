use Test::More;

use utf8;
use_ok 'Unicode::Number';

my $data = [
	{ ns => 'Lao', num => 576, str => "\x{0ED5}\x{0ED7}\x{0ED6}" },
	{ ns => 'Gurmukhi', num => 132, str => "\x{0A67}\x{0A69}\x{0A68}" },
	# TODO test larger number (Math::BigInt::GMP)?
];

my $lao_digits = "\x{0ED5}\x{0ED7}\x{0ED6}";
my $uni = Unicode::Number->new;
my $ns_lao = $uni->get_number_system_by_name('Lao');
is( $ns_lao->name, 'Lao' );


my $result = $uni->string_to_number($ns_lao, $lao_digits );
isa_ok( $result, 'Unicode::Number::Result' );

is( $result->to_string, "576" );
is( $result->to_numeric, 576 );


is( $uni->string_to_number('Lao', $lao_digits)->to_numeric, 576 , 'use string');

if( eval { require Math::BigInt } ) {
	is( $result->to_bigint, Math::BigInt->new("576") );
}

for my $test (@$data) {
	my $ns = $uni->get_number_system_by_name($test->{ns});
	is( $ns, $test->{ns} );
	my $result = $uni->string_to_number($test->{ns}, $test->{str});
	# test if converting the str using ns is equal to num
	is( $result->to_numeric, $test->{num} );

	# test if converting the num using ns is equal to str
	is( $uni->number_to_string($test->{ns}, $test->{num}), $test->{str} );

	# test that guessing the number system is correct
	is( $uni->guess_number_system($test->{str}), $test->{ns});
}

ok( not defined $uni->guess_number_system("*") );
ok( not defined $uni->guess_number_system("/") );

is( $uni->guess_number_system("1"), 'Western' );
is( $uni->guess_number_system("2"), 'Western' );

is( $uni->guess_number_system("0"), 'All_Zero' );
is( $uni->guess_number_system("000"), 'All_Zero' );

done_testing;
