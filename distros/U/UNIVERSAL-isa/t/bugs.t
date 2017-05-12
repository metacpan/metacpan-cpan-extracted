use strict;
use warnings;

use Test::More tests => 11;
use UNIVERSAL::isa 'isa';
no warnings 'UNIVERSAL::isa';

# class method

{
    package Foo;

    sub new
    {
        bless \(my $self), shift;
    }

    sub isa { 1 }
}

# delegates calls to Foo
{
    package Bar;

    sub isa
    {
        return 1 if $_[1] eq 'Foo';
    }
}

# really delegates calls to Foo
{
    package FooProxy;

    sub new
    {
        my $class = shift;
        my $foo   = Foo->new( @_ );
        bless \$foo, $class;
    }

    sub can
    {
        my $self = shift;
        return $$self->can( @_ );
    }

    sub isa
    {
        my $self = shift;
        $$self->can( 'isa' )->( @_ );
    }
}

# wraps a Foo object
{
    package Quux;

    our $AUTOLOAD;
    sub isa;

    sub new
    {
        my $class = shift;
        my $foo   = Foo->new();
        bless \$foo, $class;
    }

    sub can
    {
        my $self = shift;
        return $$self->can( @_ );
    }

    sub AUTOLOAD
    {
        my $self     = shift;
        my ($method) = $AUTOLOAD =~ /::(\w+)$/;
        $$self->$method( @_ );
    }

    sub DESTROY {}
}

my $quux = Quux->new();

ok(   isa( 'Bar', 'Foo' ), 'isa() should work on class methods too'    );
ok( ! isa( 'Baz', 'Foo' ), '... but not for non-existant classes'      );
ok(   isa( $quux, 'Foo' ), '... and should work on delegated wrappers' );

is( scalar(isa(undef, 'Foo')), undef, 'isa on undef returns undef');

SKIP: {
    eval { require CGI };
    skip( 'CGI not installed; RT #19671', 1 ) if $@;

    isa_ok( CGI->new(''), 'CGI' );
}

# overloaded objects
{
    package Qibble;
    use overload '""' => sub { die };
    no warnings 'once';
    *new = \&Foo::new;
}

my $qibble = Qibble->new();

ok(   isa( $qibble, 'Qibble' ), '... can test ISA on landmines');

my $proxy = FooProxy->new();
isa_ok( $proxy, 'Foo' );

# valid use of isa() as static method on undefined class
TODO: {
    my $warnings         = '';
    local $SIG{__WARN__} = sub { $warnings .= shift };
    use warnings 'UNIVERSAL::isa';

    # Broken how? -- rjbs, 2012-07-24
    local $TODO = 'Apparently broken in 5.6.x' if $] < 5.007;

    {
        local $TODO = "UnloadedClass->isa('UNIVERSAL') fails until 5.17.2"
            if $] < 5.017002;

        ok( UnloadedClass->isa( 'UNIVERSAL' ),
            'unloaded class should inherit from UNIVERSAL' );
    }
    is( $warnings, '', '... and should not warn' );
}

# on an unloaded class
{
    my $warnings         = '';
    local $SIG{__WARN__} = sub { $warnings .= shift };
    use warnings 'UNIVERSAL::isa';

    UNIVERSAL::isa("Foo", "Bar");
    like( $warnings, qr/Called UNIVERSAL::isa/,
        'warning on unloaded class given class (RT #24822)' );

    UNIVERSAL::isa(bless({}, "Foo"), "Bar");
    like( $warnings, qr/Called UNIVERSAL::isa/,
        'warning on unloaded class given object (RT #24882)' );
}
