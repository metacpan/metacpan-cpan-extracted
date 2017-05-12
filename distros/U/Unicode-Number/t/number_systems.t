use Test::More;

use_ok 'Unicode::Number';

my $uni = Unicode::Number->new();

my $ns = $uni->number_systems();

is( @$ns, 91, 'count of number systems' );


is( $ns->[0]->name, 'Aegean');
is( $ns->[0]->_id, 1);
ok( $ns->[0]->convertible_in_both_directions );

is( $ns->[-1]->name, 'Western');
is( $ns->[-1]->_id, 120);
ok( ! $ns->[-1]->convertible_in_both_directions );

ok( $ns->[0] eq 'Aegean', 'stringification');

is_deeply( $ns, $uni->number_systems );

is( $uni->number_systems->[0]->name, 'Aegean');

my $ns_lao = $uni->get_number_system_by_name('Lao');
is( $ns_lao, 'Lao');
is( $ns_lao->iso15924_code, 'Laoo' );

my $ns_invalid = $uni->get_number_system_by_name('NOT_A_NUMBER_SYSTEM');
is( $ns_invalid, undef );

done_testing;
