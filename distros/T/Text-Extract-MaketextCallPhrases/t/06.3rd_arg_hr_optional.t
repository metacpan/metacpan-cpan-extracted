use Test::More;    # tests => 16;

use Text::Extract::MaketextCallPhrases;

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

my $string = q{foobar(),foobar("bot"), foobar([]), foobar({}), foobar(sub {}), sub foobar {}), foobar('zog')};

my $opt = get_phrases_in_text(
    $string,
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/foobar\(/, qr/\)/, { 'optional' => 1 } ]
        ],
    }
);

is( @{$opt}, 3, 'optional => 1 returns only matches' );

is( $opt->[0]{'phrase'},    'bot',    'optional => 1 returns the expected match' );
is( $opt->[0]{'offset'},    16,       'optional => 1 returns the expected offset' );
is( $opt->[0]{'quotetype'}, 'double', 'optional => 1 returns the expected type' );

is( $opt->[1]{'phrase'}, 'sub',      'optional => 1 operates w/ bareword expected match' );
is( $opt->[1]{'offset'}, 55,         'optional => 1 operates w/ bareword expected offset' );
is( $opt->[1]{'type'},   'bareword', 'optional => 1 w/ bareword expected type 2' );

is( $opt->[2]{'phrase'},    'zog',    'optional => 1 returns the expected match 3' );
is( $opt->[2]{'offset'},    87,       'optional => 1 returns the expected offset 3' );
is( $opt->[2]{'quotetype'}, 'single', 'optional => 1 returns the expected type 3' );

my $notopt_exp = get_phrases_in_text(
    $string,
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/foobar\(/, qr/\)/, { 'optional' => 0 } ]
        ],
    }
);

is( @{$notopt_exp}, 6, 'optional => 0 returns all token hits' );

is( $notopt_exp->[0]{'phrase'}, undef,    'optional => 0 includes no_arg (phrase)' );
is( $notopt_exp->[0]{'type'},   'no_arg', 'optional => 0 includes no_arg (type)' );

is( $notopt_exp->[1]{'phrase'},    'bot',    'optional => 0 returns the expected match' );
is( $notopt_exp->[1]{'offset'},    16,       'optional => 0 returns the expected offset' );
is( $notopt_exp->[1]{'quotetype'}, 'double', 'optional => 0 returns the expected type' );

is( $notopt_exp->[2]{'phrase'}, 'ARRAY',   'optional => 0 includes array arg (phrase)' );
is( $notopt_exp->[2]{'type'},   'perlish', 'optional => 0 includes array arg (type)' );

is( $notopt_exp->[3]{'phrase'}, 'HASH',    'optional => 0 includes hash arg (phrase)' );
is( $notopt_exp->[3]{'type'},   'perlish', 'optional => 0 includes hash arg (type)' );

is( $notopt_exp->[4]{'phrase'}, 'sub',      'optional => 0 operates w/ bareword expected match' );
is( $notopt_exp->[4]{'offset'}, 55,         'optional => 0 operates w/ bareword expected offset' );
is( $notopt_exp->[4]{'type'},   'bareword', 'optional => 0 w/ bareword expected type 2' );

is( $notopt_exp->[5]{'phrase'},    'zog',    'optional => 0 returns the expected match 3' );
is( $notopt_exp->[5]{'offset'},    87,       'optional => 0 returns the expected offset 3' );
is( $notopt_exp->[5]{'quotetype'}, 'single', 'optional => 0 returns the expected type 3' );

my $notopt_imp = get_phrases_in_text(
    $string,
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/foobar\(/, qr/\)/ ]
        ],
    }
);

pop( @{ $notopt_exp->[0]{regexp} } );    # remoe the options hash since the one we're testing does not have it

is_deeply( $notopt_imp, $notopt_exp, 'no optional argument implies optional => 0' );

done_testing;
