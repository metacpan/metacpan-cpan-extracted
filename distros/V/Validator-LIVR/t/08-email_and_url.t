use strict;
use warnings;
use v5.10;
use utf8;
use lib '../lib';

use Test::More;

use Validator::LIVR;

binmode( Test::More->builder->$_, ':encoding(UTF-8)' ) for qw/output failure_output todo_output/;

# The test suite has the common cases. These are the edge cases, as in the other LIVR implementations
sub check_values {
    my ( $rule, $error, %values ) = @_;
    my $validator = Validator::LIVR->new({ field => $rule });

    for my $value ( sort keys %values ) {
        $validator->validate({ field => $value });
        my $got = $validator->get_errors && $validator->get_errors->{field};

        ( my $name = $value ) =~ s/([\x00-\x1f\x7f\x{2028}])/sprintf('\\x{%x}', ord $1)/ge;
        $name = substr( $name, 0, 40 ) . '... (' . length($value) . ' characters)' if length($name) > 60;
        is( $got, $values{$value} ? undef : $error, ( $values{$value} ? 'Should accept ' : 'Should reject ' ) . $name );
    }
}

subtest 'Email' => sub {
    check_values( 'email', 'WRONG_EMAIL',
        'john.smith@example.com'       => 1,
        'John.Smith@Example.COM'       => 1,
        'тест@mail.com'                => 1,
        '"john smith"@example.com'     => 1,
        '"john\"smith"@example.com'    => 1,
        'john@[192.168.0.1]'           => 1,
        'john@xn--80a1acn3a.xn--j1amh' => 1,
        'john@sub.example.museum'      => 1,
        'john@example.c'               => 1,
        'john@example.c0m'             => 1,

        'John <john@example.com>'      => 0,
        'john@example.com (John)'      => 0,
        ' john@example.com'            => 0,
        'john@example.com '            => 0,
        "john\x{2028}\@example.com"    => 0,
        "jo\x00hn\@example.com"        => 0,
        '"john"smith"@example.com'     => 0,
        '"john@smith"@example.com'     => 0,
        'john.@example.com'            => 0,
        'john@example.123'             => 0,
        'john@example.1com'            => 0,
        'john@example.com.'            => 0,
        'john@-example.com'            => 0,
        'john@example-.com'            => 0,
        'john@192.168.0.1'             => 0,
        'john@[192.168.0.256]'         => 0,
        'john@пошта.укр'               => 0,
    );
};

subtest 'URL' => sub {
    check_values( 'url', 'WRONG_URL',
        'https://example.com'                    => 1,
        'HTTPS://EXAMPLE.COM/PATH'               => 1,
        'http://example.com.'                    => 1,
        'http://example.com?x=1'                 => 1,
        'http://example.com/#a#b'                => 1,
        'http://example.com/path?q=a%20b&x[]=1'  => 1,
        'http://example.com/ü'                   => 1,
        'http://user:password@example.com/'      => 1,
        'http://localhost:3000/'                 => 1,
        'http://10.0.0.1:8080/x?y#z'             => 1,
        'http://ex--ample.com'                   => 1,
        'http://intranet/'                       => 1,
        'http://my-server:8080/path'             => 1,
        'http://example.c'                       => 1,
        'http://example.c0m'                     => 1,
        'http://приклад.укр/шлях'                => 1,
        'http://xn--80aikifvh.xn--j1amh/'        => 1,
        'http://example.com:/'                   => 1,
        'http://example.com:8'                   => 1,
        'http://0.0.0.0'                         => 1,
        'http://010.1.1.1/'                      => 1,
        'http://224.0.0.1'                       => 1,
        'http://255.255.255.255/'                => 1,
        'http://a.com/' . ( 'x' x 10_000 )       => 1,

        # Validator::LIVR 2.0 checked it for more than 20 seconds
        'http://a.com/' . ( 'x' x 100_000 ) . ' ' => 0,
        'http://1.2.3.256/'                      => 0,
        'http://example.123'                     => 0,
        'http://example.1com'                    => 0,
        'http://-example.com'                    => 0,
        'http://example-.com'                    => 0,
        'http://example..com'                    => 0,
        'http://example.com:123456'              => 0,
        'http://example.com/a b'                 => 0,
        'http://[::1]/'                          => 0,
        '//example.com'                          => 0,
        'mailto:john@example.com'                => 0,
    );
};

done_testing();
