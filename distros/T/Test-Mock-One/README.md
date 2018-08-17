# SYNOPSIS

    use Test::Mock::One;

    my $mock = Test::Mock::One->new(
        foo      => 'return value',
        bar      => 1,

        hashref  => \{ foo => 'bar' },
        arrayref => \[ foo => 'bar' ],
        code     => sub    { return your_special_function() },

    );

    $mock->foo;         # 'return value'
    $mock->bar;         # 1
    $mock->hashref;     # { foo => bar}
    $mock->arrayref;    # [ foo, bar ]
    $mock->code;        # executes your_special_function

    $mock->no->yes->work->it; # works fine

In combination with [Sub::Override](https://metacpan.org/pod/Sub::Override):

    my $override = Sub::Override->new('Foo::Bar::baz', sub { Test::Mock::One(foo => 'bar') });

# DESCRIPTION

Be able to mock many things with little code by using AUTOLOAD.

The problem this module tries to solve is to allow testing many things
without having to write many lines of code. If you want to create mock objects
you often need to write code like this:

    {
        no warnings qw(redefine once);
        local *Foo::thing = sub {
            return bless({}, 'Baz');
        };
        local *Baz::foo = sub { return 1 };
        local *Baz::bar = sub { return 1 };
        local *Baz::baz = sub { return 1 };
        use warnings;

        # Actual test here
    }

Test::Mock::One allows you to write a simple object that allows you to do the same with

    my $mock = Test::Mock::One->new(foo => 1, bar => 1, baz => 1);
    # Sub::Override helps too
    my $override = Sub::Override->new('Foo::thing' => sub { return $mock });

    # Actual test here

You don't actually need to define anything, by default method on a
Test::Mock::One object will return itself.  You can tweak the behaviour
by how you instantiate the object. There are several attributes that
control the object, these are defined as X-Mock attributes, see
["METHODS" in Test::Mock::One](https://metacpan.org/pod/Test::Mock::One#METHODS) for more on this.

## Example

Let's say you want to test a function that retrieves a user from a
database and checks if it is active

    Package Foo;
    use Moose;

    has schema => (is => 'ro');

    sub check_user_in_db {
        my ($self, $username) = @_;
        my $user = $self->schema->resultset('User')->search_rs(
            { username => $username }
        )->first;

        return $user if $user && $user->is_active;
        die "Unable to find user";
    }

    # In your test
    my $foo = Foo->new(
        schema => Test::Mock::One->new(
            schema => {
                resultset =>
                    { search_rs => { first => { is_active => undef } } }
            },
            'X-Mock-Strict' => 1,
        )
    );

    # Is the same as above, without Strict mode
    $foo = Foo->new(
        schema => Test::Mock::One->new(
            is_active => undef
            # This doesn't work with X-Mock-Strict enabled, because
            # the chain schema->resultset->search_rs->first cannot be
            # resolved
        )
    );

    throws_ok(
        sub {
            $foo->check_user_in_db('username');
        },
        qr/Unable to find user/,
        "username isn't active"
    );

    # A sunny day scenario would have been:
    my $mock = Foo->new(schema => Test::Mock::One->new());
    lives_ok(sub { $mock->check_user_in_db('username') },
        "We found the user");

# METHODS

## new

Instantiate a new Test::Mock::One object

- X-Mock-Strict

    Boolean value. Undefined attributes/methods will not be mocked and calling them makes us die.

- X-Mock-ISA

    Mock the ISA into the given class. Supported ways to mock the ISA:

        'X-Mock-ISA' => 'Some::Pkg',
        'X-Mock-ISA' => qr/Some::Pkg/,
        'X-Mock-ISA' => [qw(Some::Pkg Other::Pkg)],
        'X-Mock-ISA' => sub { return 0 },
        'X-Mock-ISA' => undef,

- X-Mock-Stringify

    Tell us how to stringify the object

        'X-Mock-Stringify' => 'My custom string',
        'X-Mock-Stringify' => sub { return "foo" },

- X-Mock-Called

    Boolean value. Allows mock object to keep caller information. See also [Test::Mock::Two](https://metacpan.org/pod/Test::Mock::Two).

- X-Mock-SelfArg

    Boolean value. Make all the code blocks use $self. This allows you to do things like

        Test::Mock::One->new(
            'X-Mock-SelfArg' => 1,
            code             => sub {
                my $self = shift;
                die "We have bar" if $self->foo eq 'bar';
                return "some value";
            }
        );

    This also impacts `X-Mock-ISA` and `X-Mock-Stringify`.

## isa

Returns true or false, depending on how `X-Mock-ISA` is set.

## can

Returns true or false, depending on how `X-Mock-Strict` is set.

# SEE ALSO

- [Test::Mock::Two](https://metacpan.org/pod/Test::Mock::Two)
- [Sub::Override](https://metacpan.org/pod/Sub::Override)
