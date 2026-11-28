use strict;
use Test::More;
use JSON qw(from_json);
use Encode qw(encode);

# searchOn() queries built with GinIndex (tested against PostgreSQL in
# Web-Session-PgJSON.t when PG_DSN is set)
my $class = 'Web::Session::PgJSON';
plan skip_all => "$class can't be loaded" unless ( eval "require $class" );

my $gin = { GinIndex => 1 };
my $one = q{(a_session @> ?::jsonb) AND };
my $two = q{(a_session @> ?::jsonb OR a_session @> ?::jsonb) AND };

my @tests = (

    # [ description, args, field, value, query, values ]
    [ 'GinIndex off', {}, 'uid', 'dwho', q{a_session ->> 'uid' =?}, ['dwho'] ],
    [
        'GinIndex off with a number', {},
        '_utime',                     '100',
        q{a_session ->> '_utime' =?}, ['100']
    ],
    [
        'String', $gin, 'uid', 'dwho',
        qq{${one}a_session ->> 'uid' =?},
        [ '{"uid":"dwho"}', 'dwho' ]
    ],
    [
        'Integer', $gin, '_utime', '100',
        qq{${two}a_session ->> '_utime' =?},
        [ '{"_utime":"100"}', '{"_utime":100}', '100' ]
    ],
    [
        'Perl number', $gin, '_utime', 100,
        qq{${two}a_session ->> '_utime' =?},
        [ '{"_utime":"100"}', '{"_utime":100}', 100 ]
    ],
    [
        'Negative decimal',
        $gin, 'k', '-1.50',
        qq{${two}a_session ->> 'k' =?},
        [ '{"k":"-1.50"}', '{"k":-1.50}', '-1.50' ]
    ],
    [
        'Zero', $gin, 'k', '0',
        qq{${two}a_session ->> 'k' =?},
        [ '{"k":"0"}', '{"k":0}', '0' ]
    ],
    [
        'Boolean', $gin, 'k', 'true',
        qq{${two}a_session ->> 'k' =?},
        [ '{"k":"true"}', '{"k":true}', 'true' ]
    ],
    [
        'Boolean false',
        $gin, 'k', 'false',
        qq{${two}a_session ->> 'k' =?},
        [ '{"k":"false"}', '{"k":false}', 'false' ]
    ],
    [
        'Quotes', $gin, qq{a"b\\c'd}, qq{O'B"r\\n},
        qq{${one}a_session ->> E'a"b\\\\c''d' =?},
        [ q{{"a\"b\\\\c'd":"O'B\"r\\\\n"}}, qq{O'B"r\\n} ]
    ],
    [
        'Weird field with a number',
        $gin, q{a"b}, '1',
        qq{${two}a_session ->> 'a"b' =?},
        [ q{{"a\"b":"1"}}, q{{"a\"b":1}}, '1' ]
    ],
    [
        'Control character',
        $gin, 'k', "x\ny",
        qq{${one}a_session ->> 'k' =?},
        [ '{"k":"x\\ny"}', "x\ny" ]
    ],
    [
        'Unicode', $gin, 'k', "\x{e9}t\x{e9}",
        qq{${one}a_session ->> 'k' =?},
        [ qq{{"k":"\x{e9}t\x{e9}"}}, "\x{e9}t\x{e9}" ]
    ],
    [
        'Empty string', $gin, 'k', '',
        qq{${one}a_session ->> 'k' =?},
        [ '{"k":""}', '' ]
    ],
    [ 'Array',  $gin, 'k', '[1, 2]',   q{a_session ->> 'k' =?}, ['[1, 2]'] ],
    [ 'Object', $gin, 'k', '{"a": 1}', q{a_session ->> 'k' =?}, ['{"a": 1}'] ],
    [ 'Undefined value', $gin, 'k', undef,  q{a_session ->> 'k' =?}, [undef] ],
    [ 'NUL in value',    $gin, 'k', "a\0b", q{a_session ->> 'k' =?}, ["a\0b"] ],
    [ 'NUL in field',    $gin, "k\0", 'a',  qq{a_session ->> 'k\0' =?}, ['a'] ],
);

# Values that must not be searched as numbers or booleans
foreach my $v (
    '01',  '-01', '+1',  '1.',   '.5',   '1e3',
    '1E3', ' 1',  "1\n", 'True', 'null', 'NaN',
    "\x{0661}"
  )
{
    ( my $l = $v ) =~ s/[^ -~]/?/g;
    push @tests,
      [
        "Not a number: '$l'",
        $gin, 'k', $v,
        qq{${one}a_session ->> 'k' =?},
        [ JSON->new->allow_nonref->encode( { k => $v } ), $v ]
      ];
}

# PostgreSQL numeric limits: 131072 digits before the decimal point, 16383
# after. Larger numbers make the jsonb cast fail. The two limits are
# independent, so both can be reached at once: the combined cases below lock
# the guard when neither part alone is over its limit.
foreach (
    [ 131072, 0,     1 ],
    [ 131073, 0,     0 ],
    [ 1,      16383, 1 ],
    [ 1,      16384, 0 ],
    [ 131072, 16383, 1 ],
    [ 131073, 16383, 0 ],
    [ 131072, 16384, 0 ],
  )
{
    my ( $int, $frac, $number ) = @$_;
    my $v =
      '1' . ( '0' x ( $int - 1 ) ) . ( $frac ? '.' . ( '1' x $frac ) : '' );
    push @tests,
      [
        "Number with $int+$frac digits",
        $gin,
        'k',
        $v,
        ( $number ? $two : $one ) . q{a_session ->> 'k' =?},
        [ qq{{"k":"$v"}}, ( $number ? (qq{{"k":$v}}) : () ), $v ]
      ];
}

foreach (@tests) {
    my ( $desc, $args, $field, $value, $query, $values ) = @$_;
    my $res = $class->_searchOnQuery( $args, $field, $value );
    is( $res->{query}, $query, "$desc: query" );
    is_deeply( $res->{values}, $values, "$desc: values" );

    # JSON documents must be valid and match the searched value
    my @docs = @{ $res->{values} };
    pop @docs;
    my @decoded = map { from_json($_) } @docs;
    is_deeply( $decoded[0], { $field => $value }, "$desc: JSON document" )
      if (@docs);
    is_deeply( [ keys %{ $decoded[1] } ],
        [$field], "$desc: second JSON document" )
      if ( @docs > 1 );
}

# is_deeply() unifies UTF-8 flagged and unflagged scalars, so a double
# encoded document passes unnoticed: compare the bytes the driver will send
# instead. A UTF-8 byte string passed without the flag must be read as
# characters, not as Latin-1.
{
    my $bytes = "caf\xc3\xa9";
    my $res   = $class->_searchOnQuery( $gin, 'k', $bytes );
    is( $res->{query}, qq{${one}a_session ->> 'k' =?},
        'unflagged UTF-8: query' );
    my ( $doc, $bind ) = @{ $res->{values} };
    is( encode( 'UTF-8', $doc ), qq{{"k":"$bytes"}},
        'unflagged UTF-8: document bytes' );
    is( $bind, $bytes, 'unflagged UTF-8: recheck bind unchanged' );
}

# Non-ASCII field and value, as UTF-8 bytes or as characters: the document
# holds characters in both cases, the recheck keeps the arguments as given
# and without GinIndex nothing changes
{
    my $chars = "caf\x{e9}";
    my $bytes = encode( 'UTF-8', $chars );
    foreach my $case ( [ bytes => $bytes ], [ characters => $chars ] ) {
        my ( $desc, $arg ) = @$case;
        my $res = $class->_searchOnQuery( $gin, $arg, $arg );
        my ($doc) = @{ $res->{values} };
        ok( utf8::is_utf8($doc) || $doc !~ /[\x80-\xff]/, "$desc: characters" );
        is( encode( 'UTF-8', $doc ),
            encode( 'UTF-8', qq{{"$chars":"$chars"}} ),
            "$desc: field and value document" );
        is( $res->{values}->[-1], $arg, "$desc: recheck bind unchanged" );
        like( $res->{query}, qr/->> '\Q$arg\E' =\?/, "$desc: recheck field" );

        $res = $class->_searchOnQuery( {}, $arg, $arg );
        is( $res->{query}, "a_session ->> '$arg' =?",
            "$desc: no GinIndex query" );
        is_deeply( $res->{values}, [$arg], "$desc: no GinIndex binds" );
    }
}

# "a_session @> ?::jsonb" needs a jsonb column: searchOn() must drop GinIndex
# (and warn) when the column is json, where the containment operator fails
{
    package FakeDbh;
    sub selectrow_array { $_[0]->{type} }
    package main;

    no warnings 'redefine';
    my $jsonb   = bless { type => 'jsonb' }, 'FakeDbh';
    my $json    = bless { type => 'json' },  'FakeDbh';
    my $current = $jsonb;
    my ($seen);
    my $connections = 0;

    # The handle of _classDbh() (the pool would connect)
    local *Web::Session::PgJSON::_classPool = sub { 0 };
    local *Web::Session::PgJSON::_classDbh =
      sub { $connections++; $current };
    local *Web::Session::PgJSON::_queryDbh =
      sub { $seen = $_[2]; return $seen };

    is( $class->searchOn( { GinIndex => 1 }, 'k', 'v' )->{GinIndex},
        1, 'GinIndex kept on a jsonb column' );
    is( $connections, 1, 'one handle lookup per searchOn()' );

    $current = $json;
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, @_ };
        $class->searchOn( { GinIndex => 1, TableName => 'other' }, 'k', 'v' );
    }
    ok( !$seen->{GinIndex}, 'GinIndex dropped on a json column' );
    like( join( '', @warn ), qr/not jsonb/, 'json column warns' );

    # An unknown type (missing table) must not be cached
    my $missing = bless { type => undef }, 'FakeDbh';
    $current = $missing;
    {
        local $SIG{__WARN__} = sub { };
        $class->searchOn( { GinIndex => 1, TableName => 'late' }, 'k', 'v' );
    }
    $missing->{type} = 'jsonb';
    is( $class->searchOn( { GinIndex => 1, TableName => 'late' }, 'k', 'v' )
          ->{GinIndex},
        1, 'undefined column type is not cached' );
}

# Patroni inherits this query
SKIP: {
    skip 'Patroni can\'t be loaded', 1
      unless ( eval { require Web::Session::Patroni } );
    is_deeply(
        Web::Session::Patroni->_searchOnQuery(
            $gin, 'uid', 'dwho'
        ),
        $class->_searchOnQuery( $gin, 'uid', 'dwho' ),
        'Patroni uses the same query'
    );
}

done_testing();
