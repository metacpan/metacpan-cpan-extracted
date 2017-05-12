use strict;
use warnings;
use utf8;
use Test::More;
use Web::ChromeLogger;
use MIME::Base64;
use JSON::XS;
use Data::Dumper;

my $logger = Web::ChromeLogger->new;
$logger->info(['a',sub { }]);

my $src = $logger->finalize;
my $json = MIME::Base64::decode_base64($src);
my $dat = decode_json($json);
note Dumper($dat);

is_deeply $dat, {
    'columns' => [
        'log',
        'backtrace',
        'type'
    ],
    'version' => '0.2',
    'rows' => [
        [ [ ['a', undef] ], undef, 'info' ],
    ],
};

done_testing;

