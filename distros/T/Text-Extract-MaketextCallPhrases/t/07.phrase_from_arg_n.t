use Test::More;

use Text::Extract::MaketextCallPhrases;

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

my $basic = get_phrases_in_text(
    qq{marg_third("foo","bar","Ima phrase.")},
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/marg_third\(/, qr/\)/, { 'optional' => 0, 'arg_position' => 3 } ]
        ],
    }
);
is( scalar( @{$basic} ),     1,             'basic: positional parsing found match' );
is( $basic->[0]->{'phrase'}, "Ima phrase.", "basic: positional parsing found correct arg" );

my $multi = get_phrases_in_text(
    qq{marg_third("foo","bar","Ima phrase.")marg_third("foo",   "bar", "I too ama phrase."},
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/marg_third\(/, qr/\)/, { 'optional' => 0, 'arg_position' => 3 } ]
        ],
    }
);
is( scalar( @{$multi} ),     2,                   'multi (space and same line): positional parsing found match' );
is( $multi->[0]->{'phrase'}, "Ima phrase.",       "multi (space and same line): positional parsing found correct arg 1st" );
is( $multi->[1]->{'phrase'}, "I too ama phrase.", "multi (space and same line): positional parsing found correct arg 2nd" );

my $non_str = get_phrases_in_text(
    qq{marg_third("zon",foo)marg_third("baz",   "bar")},
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/marg_third\(/, qr/\)/, { 'arg_position' => 2 } ]
        ],
    }
);

is( scalar( @{$non_str} ),     2,          'non_str (space and same line): positional parsing found match' );
is( $non_str->[0]->{'phrase'}, 'foo',      "non_str (space and same line): positional parsing found correct arg 1st" );
is( $non_str->[0]->{'type'},   'bareword', "non_str (space and same line): positional parsing found correct type 1st" );
is( $non_str->[0]->{'offset'}, 17,         "non_str (space and same line): positional parsing found correct offset 1st" );
is( $non_str->[1]->{'phrase'}, "bar",      "non_str (space and same line): positional parsing found correct arg 2nd" );
is( $non_str->[1]->{'type'},   undef,      "non_str (space and same line): positional parsing found correct type 2nd" );
is( $non_str->[1]->{'offset'}, 41,         "non_str (space and same line): positional parsing found correct offset 2st" );

my $non_str_opt = get_phrases_in_text(
    qq{marg_third("zon",[])marg_third("baz",   "bar")},
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/marg_third\(/, qr/\)/, { 'optional' => 1, 'arg_position' => 2 } ]
        ],
    }
);

is( scalar( @{$non_str_opt} ),     1,     'non_str_opt (space and same line): positional parsing found match' );
is( $non_str_opt->[0]->{'phrase'}, "bar", "non_str_opt (space and same line): positional parsing found correct arg 1st" );
is( $non_str_opt->[0]->{'type'},   undef, "non_str_opt (space and same line): positional parsing found correct type 1st" );
is( $non_str_opt->[0]->{'offset'}, 40,    "non_str_opt (space and same line): positional parsing found correct offset 1st" );

my $lines = get_phrases_in_text(
    qq{marg_third("foo",\n"bar",\n\n"Ima phrase."\n)\nmarg_third("foo",\n   "bar", \n"I too ama phrase."},
    {
        'no_default_regex' => 1,
        'regexp_conf'      => [
            [ qr/marg_third\(/, qr/\)/, { 'optional' => 0, 'arg_position' => 3 } ]
        ],
    }
);

is( scalar( @{$lines} ),     2,                   'lines: positional parsing found match' );
is( $lines->[0]->{'phrase'}, "Ima phrase.",       "lines: positional parsing found correct arg 1st" );
is( $lines->[1]->{'phrase'}, "I too ama phrase.", "lines: positional parsing found correct arg 2nd" );

done_testing;
