use Test::More;

use utf8;
use_ok 'Unicode::Number';

# TODO structured exceptions

my $uni = Unicode::Number->new;

eval {
	$uni->string_to_number('Lao', "123");
};
like( $@, qr/illegal character/ );

done_testing;
