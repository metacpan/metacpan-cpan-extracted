use Test::More qw( no_plan );

BEGIN { use_ok( 'Version::Compare', '0.01' ); }

# Test version_compare
{
    my %version = (
        '2.6.26 gt 2.6.0'                             => [ '2.6.26',                      '2.6.0',        1 ],
        '0E0 lt 1'                                    => [ '0E0',                         1,              -1 ],
        '0.0 lt 1'                                    => [ 0.0,                           1,              -1 ],
        '0 but true lt 1'                             => [ '0 but true',                  1,              -1 ],
        'undef lt 1.0.1'                              => [ undef,                         '1.0.1',        -1 ],
        '0.2005024+really0.90-lenny3 lt 2.4+lenny5.4' => [ '0.2005024+really0.90-lenny3', '2.4+lenny5.4', -1 ],
    );
    foreach my $key ( keys %version ) {
        my ( $left_version, $right_version, $expected ) = @{ $version{$key} };
        is( Version::Compare::version_compare( $left_version, $right_version ), $expected, $key );
    }
}
