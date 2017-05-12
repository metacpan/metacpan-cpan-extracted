use Test::More;

use_ok 'Unicode::Number';

my $uni = Unicode::Number->new();

isa_ok( $uni, 'Unicode::Number' );
is( $uni->version(), '2.7' );

done_testing;
