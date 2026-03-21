use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 6;

# Issue #43: '=' transforms into 'str'
# Quoted '=' should be treated as a plain string, not as a
# merge key / reference literal.

# Single-quoted =
is( Load("stuff: '='")->{stuff}, '=',
    "single-quoted '=' loads as string '='" );

# Double-quoted =
is( Load('stuff: "="')->{stuff}, '=',
    'double-quoted "=" loads as string "="' );

# Unquoted = should also work (plain scalar)
is( Load("stuff: =")->{stuff}, '=',
    "unquoted = loads as string '='" );

# With ImplicitTyping enabled
{
    local $YAML::Syck::ImplicitTyping = 1;

    is( Load("stuff: '='")->{stuff}, '=',
        "single-quoted '=' with ImplicitTyping loads as '='" );

    is( Load('stuff: "="')->{stuff}, '=',
        'double-quoted "=" with ImplicitTyping loads as "="' );

    # Unquoted = with ImplicitTyping - this is the merge key
    # but as a value it should still be '='
    is( Load("stuff: =")->{stuff}, '=',
        "unquoted = with ImplicitTyping loads as '='" );
}
