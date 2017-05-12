use Modern::Perl;
use YAML;
use App::Tables;
use Test::More qw( tests 3 );

for
(   [ "guess xls type from extension"
    , [ qw< foo.xls >        ]
    , { qw< base foo.xls type xls >  } ]

,   [ "type option confirms extension"
    , [ qw< foo.xls xls >    ]
    , { qw< base foo.xls type xls >  } ]

,   [ "type option infirms extension"
    , [ qw< foo.xls / >      ]
    , { qw< base foo.xls type dir >  } ]

) {
    my ( $desc, $args, $expected ) = @$_;
    my $got = App::Tables::_file_spec @$args;
    is_deeply $got, $expected, $desc;
}

# done_testing;
