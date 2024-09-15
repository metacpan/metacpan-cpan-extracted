use v5.14;
use warnings;


package XDR::Gen;
$XDR::Gen::VERSION = '0.0.5';
use Carp qw(croak confess);
use IO::Handle;
use List::Util qw(max);
use Scalar::Util qw(blessed reftype);

my %serializers = (
    # primitive types
    'bool' => \&_serializer_bool,
    'char' => \&_serializer_char,
    'short' => \&_serializer_short,
    'int' => \&_serializer_int,
    'long' => \&_serializer_long,
    'hyper' => \&_serializer_long,
    'float' => \&_serializer_float,
    'double' => \&_serializer_double,
    'quadruple' => '', # D>
    'string' => \&_serializer_string,
    'opaque' => \&_serializer_opaque,
    'void' => \&_serializer_void,
    );

my %deserializers = (
    # primitive types
    'bool' => \&_deserializer_bool,
    'char' => \&_deserializer_char,
    'short' => \&_deserializer_short,
    'int' => \&_deserializer_int,
    'long' => \&_deserializer_long,
    'hyper' => \&_deserializer_long,
    'float' => \&_deserializer_float,
    'double' => \&_deserializer_double,
    'quadruple' => '', # D>
    'string' => \&_deserializer_string,
    'opaque' => \&_deserializer_opaque,
    'void' => \&_deserializer_void,
    );

our $varnum = 0;
our %constants;

# add constant from ENUM element or CONST declaration
sub _add_constant {
    my ($node) = @_;
    $constants{$node->{name}->{content}} = $node->{value}->{content};
}

sub _resolve_to_number {
    my ($datum) = @_;
    while (exists $constants{$datum}) {
        # Recursive defitions will loop endlessly?!
        $datum = $constants{$datum};
    }
    if ($datum =~ m/^0x[0-9a-f]+$/i) {
        return hex($datum);
    }
    elsif ($datum =~ m/^0\d+$/) {
        return oct($datum);
    }
    elsif ($datum =~ m/^-?\d+$/) {
        return $datum;
    }
    croak "Value '$datum' does not resolve to a number";
}

sub _var {
    if ($varnum) {
        return $_[0] . $varnum++;
    }
    $varnum++;
    return $_[0];
}

sub _indent {
    chomp $_[0];
    return ($_[0] =~ s/\n(?!\s*(\n|$))/\n    /gr);
}

sub _assert_value_var {
    confess q|Serializer error: missing i/o variable name|
        unless defined $_[0];
}

sub _deserializer_bool {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    die "Input buffer too short"
        if (\$input_length - \$_[2]) < 4;
    $value = unpack("L>", substr( \$_[3], \$_[2] ));
    die "Incorrect bool value $value (must be 0 or 1)"
        unless $value == 0 or $value == 1;
    \$_[2] += 4;
    SERIAL
}

sub _serializer_bool {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    # Exploit Perl 5.36 booleanness by using (static) comparison results
    $value //= '($_[1] ? (1==1) : (0==1))';
    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    # Allow <undef> to model a <false> value
    substr( \$_[3], \$_[2] ) = pack("L>", $value);
    \$_[2] += 4;
    SERIAL
}

sub _deserializer_char {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("l>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'char': $value"
            unless (-128 <= $value and $value < 128);
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("L>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'unsigned char': $value"
            unless (0 <= $value and $value <= 255);
        SERIAL
    }
}

sub _serializer_char {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'char' value"
            unless defined $value;
        die "Out of bounds 'char': $value"
            unless (-128 <= $value and $value < 128);
        die "Non-integer 'char' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("l>", $value);
        \$_[2] += 4;
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'char' value"
            unless defined $value;
        die "Out of bounds 'unsigned char': $value"
            unless (0 <= $value and $value <= 255);
        die "Non-integer 'char' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("L>", $value);
        \$_[2] += 4;
        SERIAL
    }
}

sub _deserializer_short {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("l>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'short': $value"
            unless (-32768 <= $value and $value < 32768);
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("L>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'unsigned short': $value"
            unless (0 <= $value and $value <= 65535);
        SERIAL
    }
}

sub _serializer_short {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'short' value"
            unless defined $value;
        die "Out of bounds 'short': $value"
            unless (-32768 <= $value and $value < 32768);
        die "Non-integer 'short' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("l>", $value);
        \$_[2] += 4;
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'short' value"
            unless defined $value;
        die "Out of bounds 'unsigned short': $value"
            unless (0 <= $value and $value <= 65535);
        die "Non-integer 'short' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("L>", $value);
        \$_[2] += 4;
        SERIAL
    }
}

sub _deserializer_int {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("l>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'int': $value"
            unless (-2147483648 <= $value and $value < 2147483648);
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        $value = unpack("L>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "Out of bounds 'unsigned int': $value"
            unless (0 <= $value and $value <= 4294967295);
        SERIAL
    }
}

sub _serializer_int {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'int' value"
            unless defined $value;
        die "Out of bounds 'int': $value"
            unless (-2147483648 <= $value and $value < 2147483648);
        die "Non-integer 'int' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("l>", $value);
        \$_[2] += 4;
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'unsigned int' value"
            unless defined $value;
        die "Out of bounds 'unsigned int': $value"
            unless (0 <= $value and $value <= 4294967295);
        die "Non-integer 'int' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("L>", $value);
        \$_[2] += 4;
        SERIAL
    }
}

sub _deserializer_long {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    my $type_name = $ast_node->{type}->{name};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 8;
        $value = unpack("q>", substr( \$_[3], \$_[2] ));
        \$_[2] += 8;
        die "Out of bounds '$type_name': $value"
            unless (-9223372036854775808 <= $value
                    and $value < 9223372036854775808);
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 8;
        $value = unpack("Q>", substr( \$_[3], \$_[2] ));
        \$_[2] += 8;
        die "Out of bounds 'unsigned $type_name': $value"
            unless (0 <= $value
                    and $value <= 18446744073709551615);
        SERIAL
    }
}

sub _serializer_long {
    my ($ast_node, $value) = @_;
    my $signed = not $ast_node->{type}->{unsigned};
    my $type_name = $ast_node->{type}->{name};
    _assert_value_var($value);

    if ($signed) {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'long' value"
            unless defined $value;
        die "Out of bounds '$type_name': $value"
            unless (-9223372036854775808 <= $value
                    and $value < 9223372036854775808);
        die "Non-integer 'long' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("q>", $value);
        \$_[2] += 8;
        SERIAL
    }
    else {
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'unsigned long' value"
            unless defined $value;
        die "Out of bounds 'unsigned $type_name': $value"
            unless (0 <= $value
                    and $value <= 18446744073709551615);
        die "Non-integer 'long' value given: $value"
            unless int($value) == $value;
        substr( \$_[3], \$_[2] ) = pack("Q>", $value);
        \$_[2] += 8;
        SERIAL
    }
}

sub _deserializer_float {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    die "The platform doesn't support IEEE-754 floats"
        unless \$Config{d_double_style_ieee754};
    die "Input buffer too short"
        if (\$input_length - \$_[2]) < 4;
    $value = unpack("f>", substr( \$_[3], \$_[2] ));
    die "Incorrect bool value $value (must be 0 or 1)"
        unless $value == 0 or $value == 1;
    \$_[2] += 4;
    SERIAL
}

sub _serializer_float {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    die "The platform doesn't support IEEE-754 floats"
        unless \$Config{d_double_style_ieee754};
    croak "Missing required input 'float' value"
        unless defined $value;
    substr( \$_[3], \$_[2] ) = pack("f>", $value);
    \$_[2] += 4;
    SERIAL
}

sub _deserializer_double {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    die "The platform doesn't support IEEE-754 floats"
        unless \$Config{d_double_style_ieee754};
    die "Input buffer too short"
        if (\$input_length - \$_[2]) < 8;
    $value = unpack("d>", substr( \$_[3], \$_[2] ));
    die "Incorrect bool value $value (must be 0 or 1)"
        unless $value == 0 or $value == 1;
    \$_[2] += 8;
    SERIAL
}

sub _serializer_double {
    my ($ast_node, $value) = @_;
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    die "The platform doesn't support IEEE-754 floats"
        unless \$Config{d_double_style_ieee754};
    croak "Missing required input 'double' value"
        unless defined $value;
    substr( \$_[3], \$_[2] ) = pack("d>", $value);
    \$_[2] += 8;
    SERIAL
}

sub _deserializer_string {
    my ($ast_node, $value) = @_;
    my $max = _resolve_to_number($ast_node->{max}->{content} // 4294967295);
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    do {
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < 4;
        my \$len = unpack("L>", substr( \$_[3], \$_[2] ));
        \$_[2] += 4;
        die "String too long (max: $max): \$len"
            unless (\$len <= $max);
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < \$len;
        $value = substr( \$_[3], \$_[2], \$len );
        \$_[2] += \$len + ((4 - (\$len % 4)) % 4); # skip padding too
    };
    SERIAL
}

sub _serializer_string {
    my ($ast_node, $value) = @_;
    my $max = _resolve_to_number($ast_node->{max}->{content} // 4294967295);
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    do {
        my \$len = length $value;
        croak "Missing required input 'string' value"
            unless defined $value;
        die "String too long (max: $max): \$len"
            unless (\$len <= $max);

        substr( \$_[3], \$_[2] ) = pack("L>", \$len);
        \$_[2] += 4;
        substr( \$_[3], \$_[2] ) = $value;
        \$_[2] += \$len;
        if (my \$pad = ((4 - (\$len % 4)) % 4)) {
            substr( \$_[3], \$_[2] ) = ("\\0" x \$pad);
            \$_[2] += \$pad;
        }
    };
    SERIAL
}

sub _deserializer_opaque {
    my ($ast_node, $value) = @_;
    my $variable_length = $ast_node->{variable};
    _assert_value_var($value);

    if ($variable_length) {
        my $max = _resolve_to_number($ast_node->{max}->{content} // 4294967295);

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        do {
            die "Input buffer too short"
                if (\$input_length - \$_[2]) < 4;
            my \$len = unpack("L>", substr( \$_[3], \$_[2] ));
            \$_[2] += 4;
            die "Opaque data too long (max: $max): \$len"
                unless (\$len <= $max);
            die "Input buffer too short"
                if (\$input_length - \$_[2]) < \$len;
            $value = substr( \$_[3], \$_[2], \$len );
            \$_[2] += \$len + ((4 - (\$len % 4)) % 4); # skip padding too
        };
        SERIAL
    }
    else {
        my $count = _resolve_to_number( $ast_node->{count}->{content} );
        my $pad = (4 - ($count % 4)) % 4;
        my $padcode = $pad ? " + $pad" : '';

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        die "Input buffer too short"
            if (\$input_length - \$_[2]) < $count;
        $value = substr( \$_[3], \$_[2], $count );
        \$_[2] += $count$padcode;
        SERIAL
    }
}

sub _serializer_opaque {
    my ($ast_node, $value) = @_;
    my $variable_length = $ast_node->{variable};
    _assert_value_var($value);

    if ($variable_length) {
        my $max = _resolve_to_number($ast_node->{max}->{content} // 4294967295);

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'opaque' value"
            unless defined $value;
        do {
            my \$len = length $value;
            die "Opaque data too long (max: $max): \$len"
                unless (\$len <= $max);

            substr( \$_[3], \$_[2] ) = pack("L>", \$len);
            \$_[2] += 4;
            substr( \$_[3], \$_[2] ) = $value;
            \$_[2] += \$len;
            if (my \$pad = ((4 - (\$len % 4)) % 4)) {
                substr( \$_[3], \$_[2] ) = ("\\0" x \$pad);
                \$_[2] += \$pad;
            }
        };
        SERIAL
    }
    else { # fixed length
        my $count = _resolve_to_number( $ast_node->{count}->{content} );
        my $pad = (4 - ($count % 4)) % 4;
        my $padstr = "\\0" x $pad;
        my $padcode = $pad ? <<~PAD : '';

            substr( \$_[3], \$_[2] ) = "$padstr";
            \$_[2] += $pad;
        PAD
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'opaque' value"
            unless defined $value;
        do {
            my \$len = length $value;
            die "Opaque value length mismatch (defined: $count): \$len"
                if not \$len  == $count;

            substr( \$_[3], \$_[2] ) = $value;
            \$_[2] += \$len;$padcode
        };
        SERIAL
    }
}

sub _deserializer_void {
    return <<~SERIAL;
    # VOID deserialization placeholder
    SERIAL
}

sub _serializer_void {
    return <<~SERIAL;
    # VOID serialization placeholder
    SERIAL
}

sub _deserializer_named {
    my ($ast_node, $value, %args) = @_;
    my $ref  = $args{transform}->($ast_node->{type}->{name}->{content});
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    \$_[0]->deserialize_$ref( $value, \$_[2], \$_[3] );
    SERIAL
}

sub _serializer_named {
    my ($ast_node, $value, %args) = @_;
    my $ref  = $args{transform}->($ast_node->{type}->{name}->{content});
    _assert_value_var($value);

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    \$_[0]->serialize_$ref( $value, \$_[2], \$_[3] );
    SERIAL
}

sub _deserializer_array {
    my ($ast_node, $value, %args) = @_;
    my $decl = $ast_node;
    _assert_value_var($value);

    local $varnum = $varnum;
    my $len_var = _var( '$len' );
    my $iter_var = _var( '$i' );
    my $c = _indent( _indent( _deserializer_type( $decl, $value . "->[$iter_var\]",
                              %args ) ) );
    if ($decl->{variable}) {
        my $max = _resolve_to_number( $ast_node->{max}->{content} // 4294967295 );

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        do {
            die "Input buffer too short"
                if (\$input_length - \$_[2]) < 4;
            my $len_var = unpack("L>", substr( \$_[3], \$_[2] ));
            \$_[2] += 4;

            die "Array too long (max: $max): $len_var"
                unless ($len_var <= $max);
            $value = [];
            for my $iter_var ( 0 .. ($len_var - 1) ) {
                $c
            }
        };
        SERIAL
    }
    else { # fixed length
        my $count = _resolve_to_number( $ast_node->{count}->{content} );

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$input) = \@_;
        $value = [];
        for my $iter_var ( 0 .. ($count - 1) ) {
            $c
        }
        SERIAL
    }
}

sub _serializer_array {
    my ($ast_node, $value, %args) = @_;
    my $decl = $ast_node;
    _assert_value_var($value);

    local $varnum = $varnum;
    my $len_var = _var( '$len' );
    my $iter_var = _var( '$i' );
    my $c = _indent( _indent( _serializer_type( $decl, $value . "->[$iter_var\]",
                                                %args ) ) );
    if ($decl->{variable}) {
        my $max = _resolve_to_number( $ast_node->{max}->{content} // 4294967295 );

        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'array' value"
            unless defined $value;
        do {
            my $len_var = scalar \@{ $value };
            die "Array too long (max: $max): $len_var"
                unless ($len_var <= $max);

            substr( \$_[3], \$_[2] ) = pack("L>", $len_var);
            \$_[2] += 4;
            for my $iter_var ( 0 .. ($len_var - 1) ) {
                $c
            }
        };
        SERIAL
    }
    else { # fixed length
        my $count = _resolve_to_number( $ast_node->{count}->{content} );
        return <<~SERIAL;
        # my (\$class, \$value, \$index, \$output) = \@_;
        croak "Missing required input 'array' value"
            unless defined $value;
        do {
            my $len_var = scalar \@{ $value };
            die "Array length mismatch (defined: $count): $len_var"
                if not $len_var  == $count;

            for my $iter_var ( 0 .. ($len_var - 1) ) {
                $c
            }
        };
        SERIAL
    }

}

sub _enum_bitvector {
    my ($node) = @_;
    my $bits = '';

    for my $element (@{ $node->{elements} }) {
        vec($bits, $element->{value}->{content}, 1) = 1;
    }
    return $bits;
}

sub _deserializer_enum {
    my ($node, $value) = @_;
    _assert_value_var($value);

    my $allowed_hex = unpack('H*', _enum_bitvector($node));
    my $state_var   = _var('$m');
    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    die "Input buffer too short"
        if (\$input_length - \$_[2]) < 4;
    $value = unpack("l>", substr( \$_[3], \$_[2] ) );
    die "Out of range enum value supplied: $value"
        unless vec(state $state_var = pack('H*', '$allowed_hex'),
                   $value, 1);
    \$_[2] += 4;
    SERIAL
}

sub _serializer_enum {
    my ($node, $value) = @_;
    _assert_value_var($value);

    my $allowed_hex = unpack('H*', _enum_bitvector($node));
    my $state_var   = _var('$m');
    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    croak "Missing required input 'enum' value"
        unless defined $value;
    die "Out of range enum value: $value"
        unless vec(state $state_var = pack('H*', '$allowed_hex'),
                   $value, 1);
    substr( \$_[3], \$_[2] ) = pack("l>", $value);
    \$_[2] += 4;
    SERIAL
}

sub _deserializer_struct {
    my ($node, $value, %args) = @_;
    my $decl = $node;
    my @fragments = ("$value = {};");
    _assert_value_var($value);

    local $varnum = $varnum;
    for my $member (@{ $decl->{members} }) {
        my $name = $member->{name}->{content};
        push @fragments, "# Deserializing field: '$name'";
        push @fragments, _deserializer_declaration(
            $member->{declaration},
            $name ? $value . "->{$name}" : undef,
            %args );
    }
    return join("\n", @fragments);
}

sub _serializer_struct {
    my ($node, $value, %args) = @_;
    my $decl = $node;
    my @fragments = (<<~SERIAL);
    croak "Missing required input 'struct' value"
        unless defined $value;
    SERIAL
    _assert_value_var($value);

    local $varnum = $varnum;
    for my $member (@{ $decl->{members} }) {
        my $name = $member->{name}->{content};
        push @fragments, "# Serializing field: '$name'";
        push @fragments, qq|croak "Missing required input value '$name'"|;
        # existance check, not definedness: "pointer"-type values may be 'undef'
        push @fragments, qq|    unless exists ${value}->{$name};|;
        push @fragments, _serializer_declaration(
            $member->{declaration},
            $name ? $value . "->{$name}" : undef,
            %args );
    }
    return join("\n", @fragments);
}

sub _deserializer_union {
    my ($node, $value, %args) = @_;
    my $switch = $node;
    my @fragments = ("$value = {};");
    _assert_value_var($value);

    # discriminator
    local $varnum = $varnum;
    my $var = _var('$d');
    do {
        my $name = $switch->{discriminator}->{name}->{content};
        push @fragments, (
            "my $var;",
            _deserializer_declaration( $switch->{discriminator}->{declaration},
                                     $var, %args ),
            "$value\->{$name} = $var;");
    };
    my $members = $switch->{members};
    my $cond = 'if';
    for my $case (@{ $members->{cases} }) {
        my $name = $case->{name}->{content};
        my $selector = $case->{value}->{content}; # "void" has no name
        my $c = _indent( _deserializer_declaration(
                             $case->{declaration},
                             $name ? $value . "->{$name}" : undef,
                             %args ));
        push @fragments, <<~SERIAL;
        # Deserializing member '$name' (discriminator == $selector)
        $cond ($var == $selector) {
            $c
        }
        SERIAL

        $cond = 'elsif';
    }
    if (my $default = $members->{default}) {
        my $decl = $default->{declaration};
        my $name = $default->{name}->{content} // ''; # "void" has no name
        my $c = _indent( _deserializer_declaration(
                             $decl,
                             $name ? $value . "->{$name}" : undef,
                             %args ));
        push @fragments, <<~SERIAL;
        else {
            # Deserializing member '$name' (default discriminator)
            $c
        }
        SERIAL
    }
    else {
        push @fragments, <<~SERIAL;
        else {
            die "Unhandled union discriminator value ($var)";
        }
        SERIAL
    }

    return join("\n", @fragments);
}

sub _serializer_union {
    my ($node, $value, %args) = @_;
    my $switch = $node;
    my @fragments = (<<~SERIAL);
    croak "Missing required input 'union' value"
        unless defined $value;
    SERIAL
    _assert_value_var($value);

    # discriminator
    local $varnum = $varnum;
    my $var = _var('$d');
    do {
        my $name = $switch->{discriminator}->{name}->{content};
        push @fragments, "my $var = $value\->{$name};";
        push @fragments, _serializer_declaration( $switch->{discriminator}->{declaration},
                                                  $var,
                                                  %args );
    };
    my $members = $switch->{members};
    my $cond = 'if';
    for my $case (@{ $members->{cases} }) {
        my $name = $case->{name}->{content}; # "void" has no name
        my $selector = $case->{value}->{content};
        my $c = _indent( _serializer_declaration(
                             $case->{declaration},
                             $name ? $value . "->{$name}" : undef,
                             %args ));
        push @fragments, <<~SERIAL;
        # Serializing member '$name' (discriminator == $selector)
        $cond ($var == $selector) {
            $c
        }
        SERIAL

        $cond = 'elsif';
    }
    if (my $default = $members->{default}) {
        my $decl = $default->{declaration};
        my $name = $default->{name}->{content} // ''; # "void" has no name
        my $c = _indent( _serializer_declaration(
                             $decl,
                             $name ? $value . "->{$name}" : undef,
                             %args ));
        push @fragments, <<~SERIAL;
        else {
            # Serializing member '$name' (default discriminator)
            $c
        }
        SERIAL
    }
    else {
        push @fragments, <<~SERIAL;
        else {
            die "Unhandled union discriminator value ($var)";
        }
        SERIAL
    }

    return join("\n", @fragments);
}

sub _deserializer_type {
    my ($node, $value, %args) = @_;
    my $decl = $node;
    my $decl_type = $decl->{type};
    my $spec = $decl_type->{spec};

    if ($spec eq 'primitive') {
        if (my $d = $deserializers{$decl_type->{name}}
            // $deserializers{$decl_type->{name}->{content}}) {
            return $d->($node, $value, %args);
        }
        else {
            croak "Unknown primitive type: $decl_type->{name}";
        }
    }
    elsif ($spec eq 'named') {
        return _deserializer_named( $node, $value, %args );
    }
    elsif ($spec eq 'enum') {
        return _deserializer_enum( $decl_type->{declaration}, $value, %args );
    }
    elsif ($spec eq 'struct') {
        return _deserializer_struct( $decl_type->{declaration}, $value, %args );
    }
    elsif ($spec eq 'union') {
        return _deserializer_union( $decl_type->{declaration}, $value, %args );
    }
    else {
        croak "Unknown complex type: $spec";
    }
    # unreachable
}

sub _serializer_type {
    my ($node, $value, %args) = @_;
    my $decl = $node;
    my $decl_type = $decl->{type};
    my $spec = $decl_type->{spec};

    if ($spec eq 'primitive') {
        if (my $s = $serializers{$decl_type->{name}}
            // $serializers{$decl_type->{name}->{content}}) {
            return $s->($node, $value, %args);
        }
        else {
            croak "Unknown primitive type: $decl_type->{name}";
        }
    }
    elsif ($spec eq 'named') {
        return _serializer_named( $node, $value, %args );
    }
    elsif ($spec eq 'enum') {
        return _serializer_enum( $decl_type->{declaration}, $value, %args );
    }
    elsif ($spec eq 'struct') {
        return _serializer_struct( $decl_type->{declaration}, $value, %args );
    }
    elsif ($spec eq 'union') {
        return _serializer_union( $decl_type->{declaration}, $value, %args );
    }
    else {
        croak "Unknown complex type: $spec";
    }
    # unreachable
}

sub _deserializer_pointer {
    my ($node, $value,%args) = @_;
    my $decl = $node;
    my $c = _indent( _indent(_deserializer_type( $node, $value, %args )));
    my $bool_var = _var('$b');
    my $b = _indent(_deserializer_bool( $node, $bool_var ));

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$input) = \@_;
    do {
        my $bool_var;
        $b
        if ($bool_var) {
            $c
        }
        else {
            $value = undef;
        }
    };
    SERIAL
}

sub _serializer_pointer {
    my ($node, $value, %args) = @_;
    my $decl = $node;
    my $c = _indent(_serializer_type( $node, $value, %args ));
    my $c_false = _indent(_serializer_bool( $node, 0 ));
    my $c_true  = _indent(_serializer_bool( $node, 1 ));

    return <<~SERIAL;
    # my (\$class, \$value, \$index, \$output) = \@_;
    if (defined $value) {
        $c_true
        $c
    }
    else {
        $c_false
    }
    SERIAL
}

sub _deserializer_declaration {
    my ($decl, $value, %args) = @_;

    if ($decl->{pointer}) {
        return _deserializer_pointer( $decl, $value, %args );
    }
    elsif ($decl->{array}) {
        return _deserializer_array( $decl, $value, %args );
    }

    return _deserializer_type( $decl, $value, %args );
}

sub _serializer_declaration {
    my ($decl, $value, %args) = @_;

    if ($decl->{pointer}) {
        return _serializer_pointer( $decl, $value, %args );
    }
    elsif ($decl->{array}) {
        return _serializer_array( $decl, $value, %args );
    }

    return _serializer_type( $decl, $value, %args );
}

sub _deserializer_definition {
    my ($node, %args) = @_;

    local $varnum = $varnum;
    my $name = $args{transform}->( $node->{name}->{content} );
    my $c = _indent( _deserializer_declaration( $node->{definition}, '$_[1]', %args ) );
    return <<~SERIAL;
    # \@_: (\$class, \$value, \$index, \$input) = \@_;
    sub deserialize_$name {
        my \$input_length = length \$_[3];
        $c
    }
    SERIAL
}

sub _serializer_definition {
    my ($node, %args) = @_;

    local $varnum = $varnum;
    my $name = $args{transform}->( $node->{name}->{content} );
    my $c = _indent( _serializer_declaration( $node->{definition}, '$_[1]', %args ) );
    return <<~SERIAL;
    # \@_: (\$class, \$value, \$index, \$output) = \@_;
    sub serialize_$name {
        $c
    }
    SERIAL
}

sub _define_constant {
    my ($node, %args) = @_;

    my $name = $args{transform}->( $node->{name}->{content} );
    my $value = $node->{value}->{content};
    my $resolved = _resolve_to_number( $value );
    return <<~SERIAL;
    use constant $name => $resolved; # $value
    SERIAL
}

sub _define_enum {
    my ($node, $names, %args) = @_;
    my ($name, @nesting) = @{ $names };
    my $elements = $node->{type}->{declaration}->{elements};
    $name =  $args{transform}->( $name ) . join('.', @nesting);

    my @fragments = (
        "# Define elements from enum '$name'",
        "use constant {",
        );
    my $w = max map { length $args{transform}->($_->{name}->{content}) } @{ $elements };
    for my $element (@{ $elements }) {
        _add_constant( $element );
        push @fragments, sprintf("    %-${w}s => %s,",
                                 $args{transform}->($element->{name}->{content}),
                                 $element->{value}->{content});
    }
    push @fragments, "};";
    return join("\n", @fragments) . "\n";
}

sub _serializer_nested_enums {
    my ($cb, $names, $node, %args) = @_;
    my $decl = $node->{type}->{declaration};

    if ($node->{type}->{spec} eq 'union') {
        do { # restrict "local" scope
            my $discriminator = $decl->{discriminator};

            _serializer_nested_enums( $cb,
                                      [ @{ $names }, $discriminator->{name}->{content} ],
                                      $discriminator->{declaration}, %args );
        };
        my $members = $decl->{members};
        for my $case (@{ $members->{cases} }) {
            _serializer_nested_enums( $cb,
                                      [ @{ $names }, $case->{name}->{content} ],
                                      $case->{declaration}, %args );
        }
        if (my $default = $members->{default}) {
            _serializer_nested_enums( $cb,
                                      [ @{ $names }, $default->{name}->{content} ],
                                      $default->{declaration}, %args );
        }

        return;
    }
    elsif ($node->{type}->{spec} eq 'struct') {
        my $members = $decl->{members};
        for my $member (@{ $members }) {
            _serializer_nested_enums( $cb,
                                      [ @{ $names }, $member->{name}->{content} ],
                                      $member->{declaration}, %args );
        }

        return;
    }
    elsif ($node->{type}->{spec} eq 'enum') {
        $cb->( $node, _define_enum( $node, %args{transform} ),
               names => $names,
               type  => 'enum',
               %args{transform} );
        return;
    }

    return;
}

sub _iterate_toplevel_nodes {
    my ($class, $ast, $cb, %options) = @_;

    for my $node (@{ $ast }) {
        if ($node->{def} eq 'passthrough') {
            next unless $options{include_passthrough};
        };
        if ($node->{def} eq 'preprocessor') {
            next unless $options{include_preprocessor};
        }

        if ($node->{def} eq 'const') {
            _add_constant( $node, transform => $options{transform} );
            next if $options{exclude_constants};

            $cb->( $node, _define_constant( $node, transform => $options{transform} ),
                   type => 'constant', transform => $options{transform} );
            next;
        }

        if ($node->{def} eq 'enum') {
            next if $options{exclude_enums};

            $cb->( $node->{definition},
                   _define_enum( $node->{definition},
                                 [ $node->{name}->{content} ],
                                 transform => $options{transform} ),
                   names => [ $node->{name}->{content} ],
                   type  => 'enum',
                   transform => $options{transform}  );
            # fall through to create serializers too
        }
        elsif (not $options{exclude_enums}
               and ($node->{def} eq 'struct'
                    or $node->{def} eq 'union')) {
            # iterate through structs and unions to find
            # enums declared inline to push the symbols into
            # the symbol table

            _serializer_nested_enums( $cb,
                                      [ $node->{name}->{content} ],
                                      $node->{definition},
                                      transform => $options{transform} );
        }

        $cb->( $node, _deserializer_definition( $node, transform => $options{transform} ),
               type => 'deserializer', transform => $options{transform} );
        $cb->( $node, _serializer_definition( $node, transform => $options{transform} ),
               type => 'serializer', transform => $options{transform} );
    }

    return;
}

sub generate {
    my ($class, $ast, $output, %options) = @_;
    my $cb;

    local %constants = %{ $options{external_constants} // {} };
    $output //= IO::Handle->new_from_fd(*STDOUT, 'w');
    if (blessed $output and $output->can('print')) {
        $cb = sub {
            $output->print( $_[1] );
        };
    }
    elsif (ref $output and reftype $output eq 'SCALAR') {
        $cb = sub {
            ${ $output } .= $_[1];
        };
    }
    elsif (ref $output and reftype $output eq 'CODE') {
        $cb = $output;
    }
    else {
        croak 'Unsupported output method';
    }

    $cb->( undef, <<~'SERIAL', type => 'preamble' );
    use v5.14;
    use warnings FATAL => 'uninitialized';
    use Config;
    use Carp qw(croak);
    SERIAL
    $class->_iterate_toplevel_nodes( $ast, $cb,
                                     transform => sub { $_[0] },
                                     %options );
    $cb->( undef, '', type => 'postamble' );
}


1;

=head1 NAME

XDR::Gen - Generator for XDR (de)serializers

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

  use XDR::Gen;
  use XDR::Parse;

  my $parser = XDR::Parse->new;
  my $definition = <<'DEF';
  typedef string *optional_string;
  DEF

  open my $fh, '<', \$definition;
  my $ast = $parser->parse( $fh );

  # print the generated serializers on STDOUT
  XDR::Gen->serializers( $ast );

  # or print to a specific file handle
  open my $oh, '>', '/dev/null';
  XDR::Gen->serializers( $ast, $oh );

=head1 DESCRIPTION

This module contains a generator for Perl code to serialize data following
an XDR data definition.  Each type defined in the data definition results
in a serializer and a deserializer function.  For defined constants and the
elements of enums, constants are defined.

The generated conversion routines include validation of input coming from
encoded input (in case of deserialization) or from the enclosing application
(in case of serialization).

=head2 Data conversion

Except for data passed to a 'pointer' type (defined using C<*>) or boolean
values, all values provided must be defined.  In case of boolean values, an
undefined value will be interpreted to indicate C<false>.  In case of a
pointer type, an undefined value will be serialized as "not provided", the
same way a C C<NULL> pointer would have.

=head1 FUNCTIONS

=head2 generate

  XDR::Gen->generate( $ast, $output, [ %options ] )

Generates the code for C<$ast>, sending it to C<$output>.  The C<%options>
determine the exact outputs being generated.

C<$output> can be one of:

=over 8

=item * A blessed reference supporting C<print>

When a blessed reference is passed on which the function C<print>
can be called, e.g. an L<IO::Handle> instance, or a custom object
with a C<print> method.

=item * A code reference

When a code reference is passed in C<$output>, it is called as

  $coderef->( $node, $definition, type => $type );

with C<$node> the AST node for which the definition is generated,
C<$definition> the source code fragment and C<$type> the type of
source code having been generated.  C<$type> can have these values:

=over 8

=item * preamble

Code fragment to preceed the generated code. Defaults to

    use v5.14;
    use warnings FATAL => 'uninitialized';
    use Config;
    use Carp qw(croak);

If it's the intent to use the generated code as a stand-alone module,
at the absolute minimum, a C<package> statement needs to be prepended
to the preamble.

=item * postamble

Code fragment to follow the generated code. Default to an empty string.
If it's the intent to use the generated code as a stand-alone module,
at the absolute minimum, a C<1;> statement should be appended to this
postamble.

=item * constant

A constant generated from a C<const> line in the input.

=item * enum

A value from an C<enum> definition; note that this definition may be
part of a nested enum specification inside a struct or union definition.

=item * serializer

Code generated to serialize a type specified in the XDR syntax.

=item * deserializer

Code generated to deserialize a type specified in the XDR syntax.

=back

Note that the C<$node> does not need to be a top-level AST node,
especially with enum types, which can be defined 'inline' as part
of union or struct

=item * A scalar reference

When a scalar reference is passed, the code fragments are appended
to the contents of the referenced variable.

=item * C<undef>

When C<$output> is undefined, the output is sent to STDOUT by default.

=back

Supported values for C<options>:

=over 8

=item * transform

A function to transform identifiers; e.g.,

   sub { $_[0] =~ s/^PREFIX_//ir }

would strip C<PREFIX_> from C<PREFIX_IDENTI_FIER>, using C<IDENTI_FIER>
in the generated code instead.

=item * exclude_constants

Prevent emitting code for constant definitions.

=item * exclude_enums

Prevent emitting code for enum elements.

=item * exclude_deserializers

Prevent emitting code for deserializer routines.

=item * exclude_serializers

Prevent emitting code for serializer routines.

=item * include_passthrough

Emit passthrough instructions (as-is).

=item * include_preprocessor

Emit preprocessor instructions (as-is).

=item * external_constants

  XDR::Gen->generate( $ast, $fh,
                      external_constants => { VIR_UUID_BUFLEN => 16 } );

A hashref with constants defined outside of the scope of the xdr input
file.  C<rpcgen> depends on C<cpp> to resolve preprocessor macros; XDR::Gen
does not, but allows values extracted by other means to be provided for use
during code generation or in the generated code.  External constants are
resolved to their numeric value at code generation time by XDR::Gen.

=back

=head1 LICENSE

This distribution may be used under the same terms as Perl itself.

=head1 AUTHOR

=over 8

=item * Erik Huelsmann

=back

=head1 SEE ALSO

L<XDR::Parse>, L<perlrpcgen>

=cut
