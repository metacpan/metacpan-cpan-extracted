use Test::Most;

use lib 'lib', 't/lib';
use Unknown::Values ':OBJECT';
use UnknownUtils 'array_ok';

subtest 'Basics' => sub {
    my @cases = (
        {
            thing   => unknown,
            message => 'We should be able to get a NULL object',
        },
        {
            thing   => unknown->foo,
            message => 'Methods should return the NULL object',
        },
        {
            thing   => unknown->foo->bar->baz,
            message => 'Method chains should return the NULL object',
        },
        {
            thing   => unknown->isa('Unknown::Values::Instance::Object'),
            message => 'isa() should return an unknown',
        },
        {
            thing   => unknown->can('some_method'),
            message => 'can() should return an unknown',
        },
        {
            thing   => unknown->DOES('some_method'),
            message => 'DOES() should return an unknown',
        },
        {
            thing   => unknown->VERSION('some_method'),
            message => 'VERSION() should return an unknown',
        },
    );
    foreach my $case (@cases) {
        my $type = $case->{type} // 'Unknown::Values::Instance::Object';
        is ref $case->{thing}, $type, $case->{message};
    }

    my @errors = (
        {
            run     => sub { my $unknown = unknown; "$unknown" },
            message => "Stringification of unknown value should fail",
        },
        {
            run     => sub { my $unknown = unknown; my %foo; $foo{$unknown} = 3 },
            message => "... such as if we are trying to use an unknown value as a hash key",
        },
        {
            run     => sub { my @foo; $foo[unknown] = 3 },
            message => "... or an array index",
        },
    );
    foreach my $case (@errors) {
        my $error = $case->{error} // '^Attempt to coerce unknown value to a string';
        throws_ok { $case->{run}->() } qr/$error/, $case->{message};
    }
};

subtest 'Unknown::Values null objects should behave like `unknown`' => sub {
    ok !( 1 == unknown ),       'Direct comparisons to unknown should fail (==)';
    ok !( unknown == unknown ), '... and unknown should not be == to itself';
    ok !( unknown eq unknown ), '... and unknown should not be eq to itself';
    ok !( 2 <= unknown ),       'Direct comparisons to unknown should fail (<=)';
    ok !( 3 >= unknown ),       'Direct comparisons to unknown should fail (>=)';
    ok !( 4 > unknown ),        'Direct comparisons to unknown should fail (>)';
    ok !( 5 < unknown ),        'Direct comparisons to unknown should fail (<)';
    ok !( 6 != unknown ),
      'Direct negative comparisons to unknown should fail (!=)';
    ok !( 6 ne unknown ),
      'Direct negative comparisons to unknown should fail (ne)';
    ok !( unknown ne unknown ),
      'Negative comparisons of unknown to unknown should fail (ne)';
    my $value = unknown;
    ok is_unknown($value), 'is_unknown should tell us if a value is unknown';
    ok !is_unknown(42),    '... or not';

    my @array   = ( 1, 2, 3, $value, 4, 5 );
    my @less    = grep { $_ < 4 } @array;
    my @greater = grep { $_ > 3 } @array;

    # XXX FIXME Switched to array_ok because something about Test::Differences's
    # eq_or_diff is breaking this
    array_ok \@less, [ 1, 2, 3 ], 'unknown values are not returned with <';
    array_ok \@greater, [ 4, 5 ], 'unknown values are not returned with >';

    array_ok [ grep { is_unknown $_ } @array ], [unknown],
      '... but you can look for unknown values';
    my @sorted = sort { $a <=> $b } ( 4, 1, unknown, 5, unknown, unknown, 7 );
    array_ok \@sorted, [ 1, 4, 5, 7, unknown, unknown, unknown ],
      'Unknown values should sort at the end of the list';
    @sorted = sort { $b <=> $a } ( 4, 1, unknown, 5, unknown, unknown, 7 );
    array_ok \@sorted, [ unknown, unknown, unknown, 7, 5, 4, 1 ],
      '... but the sort to the front in reverse';
};

package Unknown::Person {
    use parent 'Unknown::Values::Instance::Object';

    sub name { return '<unknown>' }
}

package Person {

    sub new {
        my ( $class, $name, $age ) = @_;

        if ( not defined $name ) {
            return Unknown::Person->new;
        }
        return bless {
            name => $name,
            age  => $age,
        } => $class;
    }

    sub name { $_[0]->{name} }
    sub age  { $_[0]->{age} }
}

my $person         = Person->new( "Sally", 35 );
my $unknown_person = Person->new( undef,   35 );

ok $person->age < 40,               'We can call methods on known persons and compare data';
ok !( $unknown_person->age < 40 ),  '... but we cannot compare ages for unknown persons';
ok !( $unknown_person->age >= 40 ), '... but we cannot compare ages for unknown persons';

is $person->name,         'Sally',     'We can get the name of the known person';
is $unknown_person->name, '<unknown>', '... and the unknown person';

done_testing;
