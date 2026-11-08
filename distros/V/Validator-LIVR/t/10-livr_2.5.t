use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

# Before Validator::LIVR: it replaces the "time" of the modules loaded after it
use Test::MockTime qw/set_fixed_time restore_time/;

use Validator::LIVR;

# The test suite has the rules, these are the Perl parts of LIVR 2.5

subtest 'LIVR 2.5 rules are loaded on first use' => sub {
    ok( !$INC{'Validator/LIVR/Rules/Format.pm'}, 'Format rules are not loaded with Validator::LIVR' );

    my $validator = Validator::LIVR->new({ id => 'uuid' });
    ok( !$INC{'Validator/LIVR/Rules/Format.pm'}, 'new() does not load them' );

    $validator->prepare();
    ok( $INC{'Validator/LIVR/Rules/Format.pm'}, 'prepare() loads them' );
    ok( $validator->validate({ id => '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d' }), 'and they work' );
};

# 1792324800 is 2026-10-18T12:00:00Z
subtest 'Test::MockTime fixes the current date' => sub {
    my $validator = Validator::LIVR->new( { date => { iso_date => { min => 'today', max => 'today' } } } );

    set_fixed_time(1792324800);
    ok( $validator->validate({ date => '2026-10-18' }), 'Today passes' );
    ok( !$validator->validate({ date => '2026-10-19' }), 'Tomorrow fails' );
    is_deeply( $validator->get_errors(), { date => 'DATE_TOO_LATE' }, 'with DATE_TOO_LATE' );

    # The current date is in UTC: 2026-10-18T23:30:00-02:00 is the next day
    set_fixed_time( 1792324800 + 13.5 * 3600 );
    ok( $validator->validate({ date => '2026-10-19' }), 'The current date changes at midnight in UTC' );

    restore_time();
};

subtest 'The clock is read on validation' => sub {
    my $validator = Validator::LIVR->new( { at => { iso_datetime => { max => 'today' } } } )->prepare();

    set_fixed_time(1792324800);
    ok( $validator->validate({ at => '2026-10-18T20:00:00Z' }), 'Later today passes' );

    set_fixed_time( 1792324800 - 86400 );
    ok( !$validator->validate({ at => '2026-10-18T20:00:00Z' }), 'The day before it fails' );
    is_deeply( $validator->get_errors(), { at => 'DATETIME_TOO_LATE' }, 'with DATETIME_TOO_LATE' );

    restore_time();
};

subtest 'Metarules and aliases read the same clock' => sub {
    set_fixed_time(1792324800);

    my $validator = Validator::LIVR->new( {
        user   => { nested_object => { born => 'past_date' } },
        events => { list_of => { iso_date => { min => 'tomorrow' } } },
    } );

    $validator->register_aliased_rule({ name => 'past_date', rules => { iso_date => { max => 'yesterday' } } });

    ok( $validator->validate({ user => { born => '2026-10-17' }, events => ['2026-10-19'] }), 'Valid dates pass' );
    ok( !$validator->validate({ user => { born => '2026-10-18' }, events => ['2026-10-18'] }), 'Wrong dates fail' );
    is_deeply( $validator->get_errors(), {
        user   => { born => 'DATE_TOO_LATE' },
        events => ['DATE_TOO_EARLY'],
    }, 'with errors of the bounds' );

    restore_time();
};

subtest 'boolean outputs JSON::PP booleans' => sub {
    my $validator = Validator::LIVR->new({ yes => 'boolean', no => 'boolean' });
    my $output = $validator->validate({ yes => '1', no => 'false' });

    isa_ok( $output->{yes}, 'JSON::PP::Boolean' );
    isa_ok( $output->{no}, 'JSON::PP::Boolean' );
    ok( $output->{yes} && !$output->{no}, 'with the right values' );

    require JSON::PP;
    is( JSON::PP->new->canonical->encode($output), '{"no":false,"yes":true}', 'JSON::PP encodes them as true and false' );
};

subtest 'Numbers have the string form of LIVR 2.5' => sub {
    plan skip_all => 'Perl before 5.36 cannot tell a number from a string used as a number' if $] < 5.036;

    my $validator = Validator::LIVR->new({
        big      => 'digits',
        sum      => { contains => '.' },
        string   => 'digits',
        small    => { max_decimals => 7 },
        fraction => { split => '.' },
    });

    my $output = $validator->validate({ big => 1e15, sum => 0.1 + 0.2, string => '1e15', small => 1e-7, fraction => 1.5 });
    is_deeply( $validator->get_errors(), { string => 'NOT_DIGITS' }, 'A string is checked as it is' );

    $output = $validator->validate({ big => 1e15, sum => 0.1 + 0.2, small => 1e-7, fraction => 1.5 });
    is( $output->{big}, '1000000000000000', 'Without an exponent' );
    is( $output->{sum}, '0.30000000000000004', 'The shortest decimal that reads back as the number' );
    is_deeply( $output->{fraction}, [ '1', '5' ], 'A number is split in its string form' );

    ok( !Validator::LIVR->new({ small => { max_decimals => 6 } })->validate({ small => 1e-7 }),
        '1e-7 has 7 decimals' );
};

subtest 'Rules registered later do not change validators created before' => sub {
    my $validator = Validator::LIVR->new({ code => 'later_rule' });

    Validator::LIVR->register_default_rules( later_rule => sub { sub { return } } );
    throws_ok { $validator->prepare() } qr/Rule \[later_rule\] not registered/, 'A validator keeps its rules';

    ok( Validator::LIVR->new({ code => 'later_rule' })->prepare(), 'A new validator gets the new rule' );

    my $other = Validator::LIVR->new({ code => 'own_rule' });
    $other->register_rules( own_rule => sub { sub { return 'OWN' } } );
    ok( !Validator::LIVR->get_default_rules()->{own_rule}, 'register_rules() does not change the default rules' );
    ok( !Validator::LIVR->new({})->get_rules()->{own_rule}, 'or other validators' );
};

subtest 'Custom metarules get all rules of their validator' => sub {
    my $validator = Validator::LIVR->new({
        point => { my_point => { x => [ 'required', 'my_number' ], at => { iso_date => { max => 'today' } } } },
    } );
    set_fixed_time(1792324800);

    $validator->register_rules(
        my_number => sub { sub { $_[0] =~ /\A[0-9]+\z/ ? undef : 'NOT_MY_NUMBER' } },
        my_point  => sub {
            my ( $rules, $rule_builders ) = @_;
            my $nested = Validator::LIVR->new($rules)->register_rules(%$rule_builders)->prepare();

            return sub {
                my ( $value, undef, $output_ref ) = @_;
                my $output = $nested->validate($value) or return $nested->get_errors();
                $$output_ref = $output;
                return;
            };
        },
    );

    ok( !$validator->validate({ point => { x => 'a', at => '2026-10-19' } }), 'Wrong values fail' );
    is_deeply( $validator->get_errors(), { point => { x => 'NOT_MY_NUMBER', at => 'DATE_TOO_LATE' } },
        'with the errors of the custom rule and of the bound' );

    restore_time();
};

subtest '"eq" and "one_of" compare booleans as strings and output the value of the rule' => sub {
    require JSON::PP;
    my ( $true, $false ) = ( JSON::PP::true(), JSON::PP::false() );
    my $json = JSON::PP->new->canonical->allow_nonref;

    my $validator = Validator::LIVR->new({
        eq_true  => { eq => $true },
        one_of   => { one_of => [ $false, 'x' ] },
        number   => { eq => 2 },
    });

    my $output = $validator->validate({ eq_true => 'true', one_of => 'false', number => '2' });
    is( $json->encode($output), '{"eq_true":true,"number":2,"one_of":false}', 'Valid values pass' );

    my @cases = (
        # LIVR 2.5: a boolean equals "true" or "false"
        [ { eq => $true },  $true,   'true' ],
        [ { eq => $true },  'true',  'true' ],
        [ { eq => $false }, $false,  'false' ],
        [ { eq => $false }, 'false', 'false' ],
        [ { eq => 'true' }, $true,   '"true"' ],
        [ { eq => 'false' }, $false, '"false"' ],
        [ { one_of => [ $true, $false ] }, 'true',  'true' ],
        [ { one_of => [ $true, $false ] }, 'false', 'false' ],
        [ { one_of => [ 'true', 'false' ] }, $true,  '"true"' ],
        [ { one_of => [ 'true', 'false' ] }, $false, '"false"' ],

        # Validator::LIVR 2.0 compared Perl strings, where true is "1" and false is "0"
        [ { eq => $true },  '1', 'true' ],
        [ { eq => $true },  1,   'true' ],
        [ { eq => $false }, '0', 'false' ],
        [ { eq => $false }, 0,   'false' ],
        [ { one_of => [ $true, $false ] }, '1', 'true' ],
        [ { one_of => [ $true, $false ] }, '0', 'false' ],
        [ { one_of => [ 'x', 1 ] },   $true,  '1' ],
        [ { one_of => [ 'x', '1' ] }, $true,  '"1"' ],
        [ { one_of => [ 'x', 0 ] },   $false, '0' ],
        [ { one_of => [ 'x', '0' ] }, $false, '"0"' ],
    );

    foreach my $case (@cases) {
        my ( $rule, $value, $expected ) = @$case;
        my $name = $json->encode($rule) . ' with ' . $json->encode($value);

        my $output = Validator::LIVR->new({ field => $rule })->validate({ field => $value });
        is( $output && $json->encode( $output->{field} ), $expected, "$name passes" );
    }

    my @wrong_cases = (
        [ { eq => $true },  $false ],
        [ { eq => $true },  '0' ],
        [ { eq => $true },  'True' ],
        [ { eq => $true },  'yes' ],
        [ { eq => $false }, '1' ],
        [ { eq => $false }, 'False' ],

        # A boolean failed "eq" in 2.0 (FORMAT_ERROR) and is "true" or "false" in 2.5
        [ { eq => '1' }, $true ],
        [ { eq => 1 },   $true ],
        [ { eq => '0' }, $false ],

        [ { one_of => [ $true ] },  '0' ],
        [ { one_of => [ $true ] },  'True' ],
        [ { one_of => [ $false ] }, '1' ],
        [ { one_of => [ 'x', 1 ] }, $false ],
        [ { one_of => [ 'yes' ] },  $true ],
    );

    foreach my $case (@wrong_cases) {
        my ( $rule, $value ) = @$case;
        my $name = $json->encode($rule) . ' with ' . $json->encode($value);

        my $validator = Validator::LIVR->new({ field => $rule });
        ok( !$validator->validate({ field => $value }), "$name fails" );
        is_deeply( $validator->get_errors(), { field => 'NOT_ALLOWED_VALUE' }, "$name gives NOT_ALLOWED_VALUE" );
    }
};

subtest '{ rule => undef } is a wrong argument of the LIVR 2.5 rules, an argument of the others as in 2.0' => sub {
    for my $rule (qw/boolean uuid ip list_length split starts_with iso_time/) {
        throws_ok { Validator::LIVR->new({ field => { $rule => undef } })->prepare() } qr/\Q[$rule]\E/, "{ $rule => undef } dies";
        throws_ok { Validator::LIVR->new({ field => { $rule => [undef] } })->prepare() } qr/\Q[$rule]\E/, "{ $rule => [undef] } dies";
    }

    # LIVR 2.0 ignored the arguments of iso_date
    my $validator = Validator::LIVR->new({ date => { iso_date => undef } });
    is_deeply( $validator->validate({ date => '2024-02-29' }), { date => '2024-02-29' }, '{ iso_date => undef } is iso_date' );
    ok( !$validator->validate({ date => '2023-02-29' }), 'and checks the date' );
    is_deeply( $validator->get_errors(), { date => 'WRONG_DATE' }, 'with its error' );

    # As in LIVR 2.0
    my @args;
    $validator = Validator::LIVR->new({
        nothing => { default => undef },
        custom  => { my_rule => undef },
    });
    $validator->register_rules( my_rule => sub { @args = @_; return sub { return } } );

    my $output = $validator->validate({ nothing => '', custom => 'x' });
    ok( exists( $output->{nothing} ) && !defined( $output->{nothing} ), '{ default => undef } sets undef for ""' );
    is( scalar(@args), 2, 'A custom rule gets undef and the rule builders' );
    ok( !defined( $args[0] ) && ref( $args[1] ) eq 'HASH', 'in this order' );

    throws_ok { Validator::LIVR->new({ list => { not_one_of => [ 'a', undef ] } })->prepare() } qr/not_one_of/, 'undef in a list of arguments is a wrong argument';
    throws_ok { Validator::LIVR->new({ list => { contains => undef } })->prepare() } qr/contains/, 'a rule that needs arguments dies';
    throws_ok { Validator::LIVR->new({ list => { list_length => { min => undef } } })->prepare() } qr/list_length/, 'undef as a bound of list_length is a wrong argument';
};

subtest '"unique" with keys gives FORMAT_ERROR for a key value that is a hash or a list' => sub {
    my $validator = Validator::LIVR->new({ map { $_ => { unique => [ 'a', 'b' ] } } qw/hash list hash_empty list_empty/ });

    ok( !$validator->validate({
        hash       => [ { a => { x => 1 }, b => 1 } ],
        list       => [ { a => 1, b => [1] } ],
        hash_empty => [ { a => '', b => {} } ],
        list_empty => [ { a => [1] } ],
    }), 'The values fail' );

    is_deeply( $validator->get_errors(), { map { $_ => 'FORMAT_ERROR' } qw/hash list hash_empty list_empty/ },
        'also when another key is empty' );
};

subtest 'Metarules of LIVR 2.0 ignore extra arguments and keep custom rules' => sub {
    my $validator = Validator::LIVR->new({
        point  => { nested_object => [ { x => 'my_number' }, 'extra' ] },
        points => { list_of_objects => [ { x => 'my_number' }, 'extra' ] },
        xs     => { list_of => [ ['my_number'], 'extra' ] },
        typed  => { variable_object => [ 'type', { a => { type => 'required', x => 'my_number' } }, 'extra' ] },
        list   => { list_of_different_objects => [ 'type', { a => { type => 'required', x => 'my_number' } }, 'extra' ] },
        code   => { like => [ '^[a-z]+$', 'i', 'extra' ] },
    });
    $validator->register_rules( my_number => sub { sub { $_[0] =~ /\A[0-9]+\z/ ? undef : 'NOT_MY_NUMBER' } } );

    ok( !$validator->validate({
        point => { x => 'a' }, points => [ { x => 'a' } ], xs => ['a'],
        typed => { type => 'a', x => 'a' }, list => [ { type => 'a', x => 'a' } ], code => 'ABC',
    }), 'Wrong values fail' );
    is_deeply( $validator->get_errors(), {
        point  => { x => 'NOT_MY_NUMBER' },
        points => [ { x => 'NOT_MY_NUMBER' } ],
        xs     => ['NOT_MY_NUMBER'],
        typed  => { x => 'NOT_MY_NUMBER' },
        list   => [ { x => 'NOT_MY_NUMBER' } ],
    }, 'with the errors of the custom rule, and "like" keeps its flags' );
};

subtest 'A reference of "when" is a string, not a number' => sub {
    throws_ok { Validator::LIVR->new({ vat => { when => [ 1, 'required', 'required' ] } })->prepare() }
        qr/Rule \[when\] takes a reference/, 'A number dies';
    lives_ok { Validator::LIVR->new({ vat => { when => [ '1', 'required', 'required' ] } })->prepare() }
        'A string with digits is a field name';
};

subtest 'The number -0 has the string form "0"' => sub {
    require JSON::PP;

    # Perl 5.10 writes it as "-0", as JSON::PP 4 decodes -0.0 there
    my $minus_zero = -( 1e-200 * 1e-200 );

    my $validator = Validator::LIVR->new({
        flag     => 'boolean',
        hex      => 'hex',
        prefix   => { starts_with => '0' },
        amount   => { max_decimals => 0 },
        string   => 'boolean',
    });

    my $output = $validator->validate({ map { $_ => $minus_zero } qw/flag hex prefix amount/ });
    ok( $output, 'passes' ) or diag explain $validator->get_errors();
    is_deeply( $output, { flag => JSON::PP::false(), hex => '0', prefix => '0', amount => $minus_zero }, 'with the string form "0"' );

    ok( !$validator->validate({ string => '-0' }), 'The string "-0" is not a boolean' );
};

subtest 'null and lists in place of rules of "values", "keys" and "when" die with a clear message' => sub {
    my @cases = (
        [ { values => undef },                                       'Rule [values] got null in place of rules, use "any" for no rules' ],
        [ { keys => undef },                                         'Rule [keys] got null in place of rules, use "any" for no rules' ],
        [ { when => [ 'type', { card => undef } ] },                 'Rule [when] got null in place of rules, use "any" for no rules' ],
        [ { when => [ 'type', 'required', undef ] },                 'Rule [when] got null in place of rules, use "any" for no rules' ],
        [ { values => [ 'required', undef ] },                       'Rule [values] got null in a list of rules' ],
        [ { values => [ [ 'required', [] ] ] },                      'Rule [values] got an empty list inside a list of rules' ],
        [ { keys => [ [ 'required', [] ] ] },                        'Rule [keys] got an empty list inside a list of rules' ],
        [ { when => [ 'type', { card => [ 'required', [] ] } ] },    'Rule [when] got an empty list inside a list of rules' ],
        [ { when => [ 'type', [ 'required', [] ], 'any' ] },         'Rule [when] got an empty list inside a list of rules' ],
        [ { when => [ 'type', 'any', [ 'required', ['string'] ] ] }, 'Rule [when] got a list inside a list of rules' ],
    );

    foreach my $case (@cases) {
        my ( $rule, $message ) = @$case;
        my ($name) = keys %$rule;

        throws_ok { Validator::LIVR->new({ field => $rule })->prepare() } qr/\A\Q$message\E\n\z/, "$name: $message";
    }
};

done_testing();
