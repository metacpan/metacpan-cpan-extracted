use strict;

use Test::More;
use Test::RequiresInternet ('www.perl.org' => 'http');

BEGIN { use_ok('Test::HTTPStatus') }

my $status = Test::HTTPStatus::_get_status('http://www.perl.org/');
is( $status->{status}, HTTP_OK, 'HTTP OK');

$status = Test::HTTPStatus::_get_status('http://www.perl.com/xyz.abc');
is( $status->{status}, HTTP_NOT_FOUND, 'HTTP Not Found');

subtest no_url => sub {
	my $status = Test::HTTPStatus::_get_status();
	is( $status->{status}, NO_URL, 'No URL' );
};

subtest bad_url => sub {
	my $status = Test::HTTPStatus::_get_status('foo');
	is( $status->{status}, undef, 'HTTP Server Error' );
};

done_testing();
