use strict;
use warnings;

use Test::More tests => 22;

use XML::Parser;
use XML::Parser::Expat;

# --- setHandlers input validation ---

{
    my $p = XML::Parser::Expat->new;

    eval { $p->setHandlers( Start => 'not_a_coderef' ) };
    like( $@, qr/not a Code ref/, 'string handler rejected' );

    eval { $p->setHandlers( Start => {} ) };
    like( $@, qr/not a Code ref/, 'hashref handler rejected' );

    eval { $p->setHandlers( Start => [] ) };
    like( $@, qr/not a Code ref/, 'arrayref handler rejected' );

    eval { $p->setHandlers( Start => 42 ) };
    like( $@, qr/not a Code ref/, 'numeric handler rejected' );

    eval { $p->setHandlers( Start => \1 ) };
    like( $@, qr/not a Code ref/, 'scalar ref handler rejected' );

    eval { $p->setHandlers('Start') };
    like( $@, qr/Uneven number/, 'odd argument count rejected' );

    eval { $p->setHandlers( Bogus => sub { } ) };
    like( $@, qr/Unknown Expat handler type/, 'unknown handler type rejected' );

    # undef and false-y handlers are allowed (they clear the handler)
    eval { $p->setHandlers( Start => undef ) };
    is( $@, '', 'undef handler accepted (clears handler)' );

    eval { $p->setHandlers( Start => 0 ) };
    is( $@, '', 'zero handler accepted (clears handler)' );

    $p->release;
}

# --- Parse already in progress ---

{
    my $concurrent_error;
    my $p = XML::Parser::Expat->new;
    $p->setHandlers(
        Start => sub {
            eval { $_[0]->parse('<inner/>') };
            $concurrent_error = $@;
        }
    );
    $p->parse('<root/>');
    like( $concurrent_error, qr/Parse already in progress/,
        'concurrent parse on same Expat detected' );
    $p->release;
}

# --- Parser reuse guard ---

{
    my $p = XML::Parser::Expat->new;
    $p->parse('<r/>');
    eval { $p->parse('<r/>') };
    like( $@, qr/Parse already in progress/,
        'Expat reuse after parse detected' );
    $p->release;
}

{
    my $p = XML::Parser::Expat->new;
    $p->parse('<r/>');
    eval { $p->parsefile('t/foo.xml') };
    like( $@, qr/Parser has already been used/,
        'Expat reuse via parsefile detected' );
    $p->release;
}

# --- Reference exception preservation ---

{
    package TestException;
    sub new { bless { msg => $_[1] }, $_[0] }
}

{
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { die TestException->new('custom error') },
        }
    );
    eval { $p->parse('<r/>') };
    ok( ref($@), 'reference exception not stringified' );
    isa_ok( $@, 'TestException', 'exception class preserved' );
}

# --- Reference exception with ErrorContext ---

{
    my $p = XML::Parser->new(
        ErrorContext => 2,
        Handlers     => {
            Start => sub { die TestException->new('context error') },
        }
    );
    eval { $p->parse('<r/>') };
    ok( ref($@), 'reference exception preserved with ErrorContext' );
    isa_ok( $@, 'TestException', 'exception class preserved with ErrorContext' );
}

# --- State-dependent methods return undef outside parse ---

{
    my $p = XML::Parser::Expat->new;
    ok( !$p->recognized_string(),
        'recognized_string returns false outside parse' );
    ok( !$p->original_string(), 'original_string returns false outside parse' );
    ok( !$p->current_line(),    'current_line returns false outside parse' );
    ok( !$p->current_column(),  'current_column returns false outside parse' );
    ok( !$p->current_byte(),    'current_byte returns false outside parse' );
    ok( !$p->current_length(),  'current_length returns false outside parse' );
    $p->release;
}
