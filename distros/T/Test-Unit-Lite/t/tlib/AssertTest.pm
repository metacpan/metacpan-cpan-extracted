package AssertTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base 'Test::Unit::TestCase', 'ExceptionChecker';

use ExceptionChecker;
use TestObject;

sub test_assert_equals {
    my $self = shift;
    my $o = TestObject->new();
    $self->assert_equals($o, $o);
}

# ...and the root of that problem in test_assert_equals
sub test_numericness {
    my $self = shift;
    my %tests = (
        1       => '1',            # num
        0       => '0',            # num
        '15e7'  => '150000000',    # num
        '15E7'  => '150000000',    # num
        "not 0" => '0',            # str
        "not 4" => '0',            # str
        "  \n 5E2"      => '500',  # num
        "  \t 0E0  "    => '0',    # num
    );
    foreach my $str (keys %tests) {
        my $expect = $tests{$str};
        $self->assert_num_equals($expect, $str);
    }
}

sub test_assert {
    my $self = shift;
    $self->assert(1);
    $self->assert(1, 'should be true');
    $self->assert(qr/foo/, 'foobar');
    $self->assert(qr/foo/, 'foobar', 'should match /foo/');
    $self->assert([]);
    $self->assert([ 'foo', 7 ]);
    $self->check_failures(
        'Boolean assertion failed' => [ __LINE__, sub { shift->assert(undef) } ],
        'Boolean assertion failed' => [ __LINE__, sub { shift->assert(0)   } ],
        'Boolean assertion failed' => [ __LINE__, sub { shift->assert('')  } ],

        qr/bang/   => [ __LINE__, sub { shift->assert(0, 'bang')              } ],
        qr/bang/   => [ __LINE__, sub { shift->assert('', 'bang')             } ],
        qr/did not match /
                 => [ __LINE__, sub { shift->assert(qr/foo/, 'qux')         } ],
        qr/bang/ => [ __LINE__, sub { shift->assert(qr/foo/, 'qux', 'bang') } ],
    );
}

sub test_assert_str_equals {
    my $self = shift;
    my @pass = (
        ['', ''],
        [0, 0],
        [1, 1],
        ['foo', 'foo'],
    );
    foreach my $pair (@pass) {
        my ($expected, $got) = @$pair;
        $self->assert_str_equals($expected, $got);
        $self->assert_str_equals($expected, $got, 'failure message');
    }
    $self->check_failures(
        'expected value was undef; should be using assert_null?' =>
          [ __LINE__, sub { $self->assert_str_equals(undef, undef) } ],
        'expected value was undef; should be using assert_null?' =>
          [ __LINE__, sub { $self->assert_str_equals(undef, 0)     } ],
        'expected value was undef; should be using assert_null?' =>
          [ __LINE__, sub { $self->assert_str_equals(undef, '')    } ],
        'expected value was undef; should be using assert_null?' =>
          [ __LINE__, sub { $self->assert_str_equals(undef, 'foo') } ],
        "expected '', got undef" =>
          [ __LINE__, sub { $self->assert_str_equals('', undef)    } ],
        "expected 'foo', got undef" =>
          [ __LINE__, sub { $self->assert_str_equals('foo', undef) } ],
        "expected '', got '0'" =>
          [ __LINE__, sub { $self->assert_str_equals('', 0)        } ],
        "expected '0', got ''" =>
          [ __LINE__, sub { $self->assert_str_equals(0, '')        } ],
        "expected '0', got undef" =>
          [ __LINE__, sub { $self->assert_str_equals(0, undef)     } ],
        "expected '0', got '1'" =>
          [ __LINE__, sub { $self->assert_str_equals(0, 1)         } ],
        "expected '0', got '-0'" =>
          [ __LINE__, sub { $self->assert_str_equals(0, '-0')      } ],
        "expected '-0', got '0'" =>
          [ __LINE__, sub { $self->assert_str_equals('-0', 0)      } ],
        "expected 'foo', got 'bar'" =>
          [ __LINE__, sub { $self->assert_str_equals('foo', 'bar') } ],

    );
}

sub test_assert_matches {
    my $self = shift;
    $self->assert_matches(qr/ob/i, 'fooBar');
    $self->check_failures(
        'arg 1 to assert_matches() must be a regexp'
            => [ __LINE__, sub { $self->assert_matches(1, 2) } ]
    );
}

sub test_assert_does_not_match {
    my $self = shift;
    $self->assert_does_not_match(qr/ob/, 'fooBar');
    $self->check_failures(
        'arg 1 to assert_does_not_match() must be a regexp'
            => [ __LINE__, sub { $self->assert_does_not_match(1, 2) } ]
    );
}

sub test_assert_equals_null {
    my $self = shift;
    $self->assert_equals(undef, undef);
}

sub test_assert_null_not_equals_null {
    my $self = shift;
    eval { $self->assert_equals(undef, TestObject->new()) };
    $self->assert_matches(qr/expected value was undef/s, $@);
}

sub test_fail {
    my $self = shift;
    $self->check_failures(
        ''                => [ __LINE__, sub { $self->fail() } ],
        'failure message' => [ __LINE__, sub { $self->fail('failure message') } ],
    );
}

sub test_succeed_assert_null {
    my $self = shift;
    $self->assert_null(undef);
}

sub test_fail_assert_null {
    my $self = shift;
    $self->check_failures(
        'Defined is defined'
          => [ __LINE__, sub { $self->assert_null('Defined') } ],
        qr/Weirdness/
          => [ __LINE__, sub { $self->assert_null('Defined', 'Weirdness') } ],
    );
}

sub test_success_assert_not_equals {
    my $self = shift;
    $self->assert_not_equals(1, 0);
    $self->assert_not_equals(0, 1);
    $self->assert_not_equals(0, 1E10);
    $self->assert_not_equals(1E10, 0);
    $self->assert_not_equals(1, 2);
    $self->assert_not_equals('string', 1);
    $self->assert_not_equals(1, 'string');
    $self->assert_not_equals('string', 0);
    # $self->assert_not_equals(0,'string'); # Numeric comparison done here..
    # $self->assert_not_equals(0, '');      # Numeric comparison done here..
    $self->assert_not_equals('', 0);
    $self->assert_not_equals(undef, 0);
    $self->assert_not_equals(0, undef);
    # $self->assert_not_equals(0, ''); FIXME
    $self->assert_not_equals(undef, '');
    $self->assert_not_equals('', undef);
}

sub test_fail_assert_not_equals {
    my $self = shift;
    my @pairs = (
        # Some of these are debatable, but at least including the tests
        # will alert us if any of the outcomes change.
        "0 and 0 should differ"      => [ 0,        0        ],
        "0 and 0 should differ"      => [ 0,        '0'      ],
        "0 and 0 should differ"      => [ '0',      0        ],
        "0 and 0 should differ"      => [ '0',      '0'      ],
        "1 and 1 should differ"      => [ 1,        1        ],
        "1 and 1 should differ"      => [ 1,        '1'      ],
        "1 and 1 should differ"      => [ '1',      1        ],
        "1 and 1 should differ"      => [ '1',      '1'      ],
        "0 and  should differ"       => [ 0,        ''       ], # Numeric comparison
        "0 and string should differ" => [ 0,        'string' ], # Numeric comparison
        "'' and '' should differ"    => [ '',       ''       ],
        "both args were undefined"   => [ undef,    undef    ],
    );
    my @tests = ();
    while (@pairs) {
        my $expected = shift @pairs;
        my $pair     = shift @pairs;
        push @tests, $expected
          => [ __LINE__, sub { $self->assert_not_equals(@$pair) } ];
        push @tests, qr/custom message/,
          => [ __LINE__, sub { $self->assert_not_equals(@$pair,
                                                        "custom message") } ];
    }
    $self->check_failures(@tests);
}

sub test_fail_assert_not_null {
    my $self = shift;
    $self->check_failures(
        '<undef> unexpected'
          => [ __LINE__, sub { $self->assert_not_null(undef) } ],
        '<undef> unexpected'
          => [ __LINE__, sub { $self->assert_not_null() } ],
          # nb. $self->assert_not_null(@emptylist, "message") is not
          # going to do what you expected!
        qr/Weirdness/
          => [ __LINE__, sub { $self->assert_not_null(undef, 'Weirdness') } ]
    );
}

sub test_succeed_assert_not_null {
    my $self = shift;
    $self->assert_not_null(TestObject->new);
    $self->assert_not_null('');
    $self->assert_not_null('undef');
    $self->assert_not_null(0);
    $self->assert_not_null(10);
}

sub test_assert_deep_equals {
    my $self = shift;

    $self->assert_deep_equals([], []);
    $self->assert_deep_equals({}, {});
    $self->assert_deep_equals([ 0, 3, 5 ], [ 0, 3, 5 ]);
    my $hashref = { a => 2, b => 4 };
    $self->assert_deep_equals($hashref, $hashref);
    $self->assert_deep_equals($hashref, { b => 4, a => 2 });
    my $complex = {
        array => [ 1, $hashref, 3 ],
        undefined => undef,
        number => 3.2,
        string => 'hi mom',
        deeper => {
            and => [
                even => [ qw(deeper wahhhhh) ],
                { foo => 11, bar => 12 }
            ],
        },
    };
    $self->assert_deep_equals(
        $complex,
        {
            array => [ 1, $hashref, 3 ],
            undefined => undef,
            number => 3.2,
            string => 'hi mom',
            deeper => {
                and => [
                    even => [ qw(deeper wahhhhh) ],
                    {
                        foo => 11, bar => 12 }
                ],
            },
        },
    );

    my $differ = sub {
        my ($a, $b) = @_;
        qr/^Structures\ begin\ differing\ at: $ \n
        \S*\s* \$a .* = .* (?-x:$a)      .* $ \n
        \S*\s* \$b .* = .* (?-x:$b)/mx;
    };

    my %families; # key=test-purpose, value=assorted circular structures
    foreach my $key (qw(orig copy bad_copy)) {
        my %family = ( john => { name => 'John Doe',
                                 spouse => undef,
                                 children => [],
                               },
                       jane => { name   => 'Jane Doe',
                                 spouse => undef,
                                 children => [],
                               },
                       baby => { name => 'Baby Doll',
#                                spouse => undef,
                                 children => [],
                               },
                     );
        $family{john}{spouse} = $family{jane};
        $family{jane}{spouse} = $family{john};
        push @{$family{john}{children}}, $family{baby};
        push @{$family{jane}{children}}, $family{baby};
        $families{$key} = \%family;
    }
    $families{bad_copy}->{jane}{spouse} = $families{bad_copy}->{baby}; # was ->{john}

    # Breakage under test is infinite recursion, to memory exhaustion!
    # Jump through hoops to avoid killing people's boxes
    {
        my $old_isa = \&UNIVERSAL::isa;
        # Pick on isa() because it'll be called from any deep-ing code
        local $^W = 0;
        no warnings 'redefine';
        local *UNIVERSAL::isa = sub {
            die "Giving up on deep recursion for assert_deep_equals"
              if defined caller(500);
            return $old_isa->(@_);
        };
        $self->assert_deep_equals($families{orig}, $families{copy});
    }

    my ($H, $H2, $G) = qw(hello hello goodbye);

    my @pairs = (
        'Both arguments were not references' => [ undef, 0 ],
        'Both arguments were not references' => [ 0, undef ],
        'Both arguments were not references' => [ 0, 1     ],
        'Both arguments were not references' => [ 0, ''    ],
        'Both arguments were not references' => [ '', 0    ],
         qr/HASH.0x/                         => [ [],      {}      ],
         qr/HASH.0x/                         => [ [1,2],   {1,2}   ],
         qr/undef/                           => [ { 'test' => []},
                                              { 'test' => undef } ],
         qr/not exist/                       => [ { 'test' => []}, {} ],
         qr/ARRAY.0x/                        => [ { 'test' => undef },
                                             { 'test' => []} ],
         qr/undef/                           => [ [ '' ], [ undef ] ],
         qr/undef/                           => [ [ 'undef' ], [ undef ] ],
         qr/'3'/                             => [ [1,2],   [1,2,3] ],
         qr/not exist/                       => [ [1,2,3], [1,2]   ],
         qr/'wahhhh'/                        => [
             $complex,
             {
                 array => [ 1, $hashref, 3 ],
                 undefined => undef,
                 number => 3.2,
                 string => 'hi mom',
                 deeper => {
                     and => [
                         even => [ qw(deeper wahhhh) ],
                         { foo => 11, bar => 12 }
                     ],
                 },
             }
         ],
         qr/not exist/                       => [$families{orig}, $families{bad_copy}], # test may be fragile due to recursion ordering?
         qr/'5'/                             => [ [ \$H, 3 ], [ \$H2, 5 ] ],
         qr/'goodbye'/                       => [ { world => \$H }, { world => \$G } ],
         qr/'goodbye'/                       => [ [ \$H, "world" ], [ \$G, "world" ] ],
    );

    my @tests = ();
    my $n = 0;
    while (@pairs) {
        my $expected = shift @pairs;
        my $pair     = shift @pairs;
        push @tests, $expected,
          [ __LINE__, sub { $self->assert_deep_equals(@$pair) } ];
        push @tests, qr/custom message/,
          [ __LINE__, sub { $self->assert_deep_equals(@$pair,
                                                     "custom message") } ];
        $n ++;
    }
    $self->check_failures(@tests);
}

# Key = assert_method
# Value = [[@arg_list],undef/expected exception]
# FIXME: These should probably be merged with the tests for assert_not_equals()
# somehow, since the failures aren't currently tested for the correct message
# via check_exception(), or originating file/line via check_file_and_line().
my %test_hash = (
    assert_equals => {
        success => [
            { args => [0,'foo'],      name => "0 == 'foo'" },
            { args => [1,'1.0'],      name => "1 == '1.0'" },
            { args => ['1.0', 1],     name => "'1.0' == 1" },
            { args => ['foo', 'foo'], name => 'foo eq foo' },
            { args => ['0e0', 0],     name => '0E0 == 0'   },
            { args => [0, 'foo'],     name => "0 == 'foo'" },
            { args => [undef, undef], name => "both undef" },
            { args => [0, 0],         name => "0 == 0"     },
            { args => [0, 0.0],       name => "0 == 0.0"   },
            { args => [0.0, 0],       name => "0.0 == 0"   },
            { args => [0.0, 0.0],     name => "0.0 == 0.0" },
            { args => ['', ''],       name => "'' == ''"   },
        ],
        'Test::Unit::Failure' => [
            { args => [1,'foo'],      name => "1 != 'foo'"     },
            { args => ['foo', 0],     name => "'foo' ne 0"     },
            { args => ['foo', 1],     name => "'foo' ne 1"     },
            { args => [0,1],          name => "0 != 1"         },
            { args => ['foo', 'bar'], name => "'foo' ne 'bar'" },
            { args => ['foo', undef], name => "'foo' ne undef" },
            { args => [undef, 'foo'], name => "undef ne 'foo'" },
            # { args => [0, ''],        name => "0 ne ''"        }, # numeric compare

        ],
    },
);

1;
