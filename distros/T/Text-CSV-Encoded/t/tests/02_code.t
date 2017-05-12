
use strict;
use utf8;


my $csv = Text::CSV::Encoded->new();

my @tests = ( #  encoding           CSV                         Perl Str    Re-CSV
    [ [ unicode => undef      ] => "ü",                         "ü",        "ü"                                 ],
    [ [ latin1  => undef      ] => "\xfc",                      "\xfc",     "\xfc"                              ],
    [ [ latin1  => 'latin1'   ] => "\xfc",                      "\xfc",     "\xfc"                              ],
    [ [ utf8    => undef      ] => "\xc3\xbc",                  "\xc3\xbc", qq|"\xc3\xbc"|                      ],
    [ [ unicode => 'utf8'     ] => "\xc3\xbc",                  "ü",        "\xc3\xbc"                          ],
    [ [ unicode => undef      ] => 'あ,い',                     'あ,い',    '"あ","い"'                         ],
    [ [ unicode => 'utf8'     ] => "\xE3\x81\x82,\xE3\x81\x84", 'あ,い',    qq|"\xE3\x81\x82","\xE3\x81\x84"|   ],
    [ [ unicode => 'shiftjis' ] => "\x82\xA0,\x82\xA2",         'あ,い',    qq|"\x82\xA0","\x82\xA2"|           ],
);


for my $t ( @tests ) {
    my ( $name, $code ) = @{ $t->[0] };

    $name .= " (<=$code)" if $code;

    my $columns = $code ? $csv->decode( $code, $t->[1] ) : $csv->decode( $t->[1] );

    is( join( ',', @$columns ),     $t->[2], $name . ' decode' );

    my $string = $code ? $csv->encode( $code, $columns ) : $csv->encode( $columns );

    is( $string, $t->[3], $name . ' encode' );
}

1;
