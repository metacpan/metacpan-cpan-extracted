use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('URL::Encode::PP', qw[ url_params_each
                                  url_params_flat
                                  url_params_mixed
                                  url_params_multi ]);
}

{
    my @tests = (
        [ 'a;b',                => [ 'a'    => undef, 'b'  => undef ] ],
        [ 'a&b',                => [ 'a'    => undef, 'b'  => undef ] ],
        [ 'a ; b',              => [ 'a '   => undef, ' b' => undef ] ],
        [ 'a & b',              => [ 'a '   => undef, ' b' => undef ] ],
        [ 'a==1;b==2',          => [ 'a'    => '=1',  'b'  => '=2'  ] ],
        [ 'a==1&b==2',          => [ 'a'    => '=1',  'b'  => '=2'  ] ],
        [ 'Fo%2=',              => [ 'Fo%2' => ''                   ] ],
        [ ' a = 1 '             => [ ' a '  => ' 1 '                ] ],
        [ '+a+=+1+'             => [ ' a '  => ' 1 '                ] ],
        [ '%20a%20=%201%20'     => [ ' a '  => ' 1 '                ] ],
        [ ';'                   => [ ''     => undef, ''   => undef ] ],
        [ '&'                   => [ ''     => undef, ''   => undef ] ],
        [ ';='                  => [ ''     => undef, ''   => ''    ] ],
        [ '&='                  => [ ''     => undef, ''   => ''    ] ],
        [ '=;'                  => [ ''     => '',    ''   => undef ] ],
        [ '=&'                  => [ ''     => '',    ''   => undef ] ],
        [ '=;='                 => [ ''     => '',    ''   => ''    ] ],
        [ '=&='                 => [ ''     => '',    ''   => ''    ] ],
        [ '=',                  => [ ''     => '',                  ] ],
        [ '',                   => [                                ] ],
    );

    foreach my $test (@tests) {
        my ($string, $expected) = @$test;
        is_deeply(url_params_flat($string), $expected, qq[url_params_flat("$string")]);
    }
}

{
    my @tests = (
        [ 'a;b',                => { 'a'    => [ undef ],        'b'  => [ undef ]        } ],
        [ 'a&b',                => { 'a'    => [ undef ],        'b'  => [ undef ]        } ],
        [ 'a;b;a',              => { 'a'    => [ undef, undef ], 'b'  => [ undef ]        } ],
        [ 'a&b&a',              => { 'a'    => [ undef, undef ], 'b'  => [ undef ]        } ],
        [ 'b&a;b&a',            => { 'a'    => [ undef, undef ], 'b'  => [ undef, undef ] } ],
        [ 'b;a&b;a',            => { 'a'    => [ undef, undef ], 'b'  => [ undef, undef ] } ],
        [ 'a ; b',              => { 'a '   => [ undef ],        ' b' => [ undef ]        } ],
        [ 'a & b',              => { 'a '   => [ undef ],        ' b' => [ undef ]        } ],
        [ 'a==1;b==2',          => { 'a'    => [ '=1'  ],        'b'  => [ '=2'  ]        } ],
        [ 'a==1&b==2',          => { 'a'    => [ '=1'  ],        'b'  => [ '=2'  ]        } ],
        [ 'Fo%2=',              => { 'Fo%2' => [ ''    ]                                  } ],
        [ ' a = 1 '             => { ' a '  => [ ' 1 ' ]                                  } ],
        [ '+a+=+1+'             => { ' a '  => [ ' 1 ' ]                                  } ],
        [ '%20a%20=%201%20'     => { ' a '  => [ ' 1 ' ]                                  } ],
        [ ';'                   => { ''     => [ undef, undef ],                          } ],
        [ '&'                   => { ''     => [ undef, undef ],                          } ],
        [ ';='                  => { ''     => [ undef, '' ]                              } ],
        [ '&='                  => { ''     => [ undef, '' ]                              } ],
        [ '=;'                  => { ''     => [ '', undef ]                              } ],
        [ '=&'                  => { ''     => [ '', undef ]                              } ],
        [ '=;='                 => { ''     => [ '', '' ]                                 } ],
        [ '=&='                 => { ''     => [ '', '' ]                                 } ],
        [ '=',                  => { ''     => [ '' ],                                    } ],
        [ '',                   => {                                                      } ],
    );

    foreach my $test (@tests) {
        my ($string, $expected) = @$test;
        is_deeply(url_params_multi($string), $expected, qq[url_params_multi("$string")]);
    }
}

{
    my @tests = (
        [ 'a;b',                => { 'a'    => undef,            'b'  => undef            } ],
        [ 'a&b',                => { 'a'    => undef,            'b'  => undef            } ],
        [ 'a;b;a',              => { 'a'    => [ undef, undef ], 'b'  => undef            } ],
        [ 'a&b&a',              => { 'a'    => [ undef, undef ], 'b'  => undef            } ],
        [ 'b&a;b&a',            => { 'a'    => [ undef, undef ], 'b'  => [ undef, undef ] } ],
        [ 'b;a&b;a',            => { 'a'    => [ undef, undef ], 'b'  => [ undef, undef ] } ],
        [ 'a ; b',              => { 'a '   => undef,            ' b' => undef            } ],
        [ 'a & b',              => { 'a '   => undef,            ' b' => undef            } ],
        [ 'a==1;b==2',          => { 'a'    => '=1',             'b'  => '=2'             } ],
        [ 'a==1&b==2',          => { 'a'    => '=1',             'b'  => '=2'             } ],
        [ 'Fo%2=',              => { 'Fo%2' => ''                                         } ],
        [ ' a = 1 '             => { ' a '  => ' 1 '                                      } ],
        [ '+a+=+1+'             => { ' a '  => ' 1 '                                      } ],
        [ '%20a%20=%201%20'     => { ' a '  => ' 1 '                                      } ],
        [ ';'                   => { ''     => [ undef, undef ],                          } ],
        [ '&'                   => { ''     => [ undef, undef ],                          } ],
        [ ';='                  => { ''     => [ undef, '' ]                              } ],
        [ '&='                  => { ''     => [ undef, '' ]                              } ],
        [ '=;'                  => { ''     => [ '', undef ]                              } ],
        [ '=&'                  => { ''     => [ '', undef ]                              } ],
        [ '=;='                 => { ''     => [ '', '' ]                                 } ],
        [ '=&='                 => { ''     => [ '', '' ]                                 } ],
        [ '=',                  => { ''     => '',                                        } ],
        [ '',                   => {                                                      } ],
    );

    foreach my $test (@tests) {
        my ($string, $expected) = @$test;
        is_deeply(url_params_mixed($string), $expected, qq[url_params_mixed("$string")]);
    }
}

{
    my $enc = 'foo=1&bar=2&bar=3';
    my @exp = qw(foo bar bar);
    my $cnt = 0;
    my $callback = sub {
        my ($key, $val) = @_;
        my $exp_key = shift @exp;
        my $exp_val = ++$cnt;
        is($key, $exp_key, 'url_params_each(): expected key');
        is($val, $exp_val, 'url_params_each(): expected value');
    };
    url_params_each($enc, $callback);
    is($cnt, 3, 'url_params_each(): callback invoked three times');
}

done_testing();

