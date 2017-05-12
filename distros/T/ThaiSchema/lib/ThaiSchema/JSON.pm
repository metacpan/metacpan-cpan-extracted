package ThaiSchema::JSON;
use strict;
use warnings;
use utf8;

use ThaiSchema;
use Encode       ();

# Licensed under the Artistic 2.0 license.
# See http://www.perlfoundation.org/artistic_license_2_0.

# This module is based on JSON::Tiny 0.22

my $FALSE = \0;
my $TRUE  = \1;

sub ddf {
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    Data::Dumper::Dumper(@_);
}

# Escaped special character map (with u2028 and u2029)
my %ESCAPE = (
    '"'     => '"',
    '\\'    => '\\',
    '/'     => '/',
    'b'     => "\x07",
    'f'     => "\x0C",
    'n'     => "\x0A",
    'r'     => "\x0D",
    't'     => "\x09",
    'u2028' => "\x{2028}",
    'u2029' => "\x{2029}"
);
my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;
for ( 0x00 .. 0x1F, 0x7F ) { $REVERSE{ pack 'C', $_ } //= sprintf '\u%.4X', $_ }

# Unicode encoding detection
my $UTF_PATTERNS = {
    'UTF-32BE' => qr/^\0\0\0[^\0]/,
    'UTF-16BE' => qr/^\0[^\0]\0[^\0]/,
    'UTF-32LE' => qr/^[^\0]\0\0\0/,
    'UTF-16LE' => qr/^[^\0]\0[^\0]\0/
};
my $WHITESPACE_RE = qr/[\x20\x09\x0a\x0d]*/;

our $FAIL;

our @_ERRORS;
our $_NAME = '';

sub new {
    my $class = shift;
    bless @_ ? @_ > 1 ? {@_} : { %{ $_[0] } } : {}, $class;
}

sub error {
    $_[0]->{error} = $_[1] if @_ > 1;
    return $_[0]->{error};
}

sub validate {
    my ( $self, $bytes, $schema ) = @_;
    $schema = _schema($schema);

    local $FAIL;
    local @_ERRORS;
    local $_NAME = '';

    # Cleanup
    $self->error(undef);

    # Missing input
    $self->error('Missing or empty input') and return undef
      unless $bytes;    ## no critic (undef)

    # Remove BOM
    $bytes =~
      s/^(?:\357\273\277|\377\376\0\0|\0\0\376\377|\376\377|\377\376)//g;

    # Wide characters
    $self->error('Wide character in input')
      and return undef    ## no critic (undef)
      unless utf8::downgrade( $bytes, 1 );

    # Detect and decode Unicode
    my $encoding = 'UTF-8';
    $bytes =~ $UTF_PATTERNS->{$_} and $encoding = $_ for keys %$UTF_PATTERNS;

    my $d_res = eval { $bytes = Encode::decode( $encoding, $bytes, 1 ); 1 };
    $bytes = undef unless $d_res;

    # Object or array
    my $res = eval {
        local $_ = $bytes;

        # Leading whitespace
        m/\G$WHITESPACE_RE/gc;

        # Array
        my $ref;
        if (m/\G\[/gc) {
            unless ($schema->is_array()) {
                _exception2("Unexpected array found.");
            }
            $ref = _decode_array($schema->schema)
        }

        # Object
        elsif (m/\G\{/gc) {
            unless ($schema->is_hash()) {
                _exception2("Unexpected object found.");
            }
            $ref = _decode_object($schema)
        }

        # Unexpected
        else { _exception('Expected array or object') }

        # Leftover data
        unless (m/\G$WHITESPACE_RE\z/gc) {
            my $got = ref $ref eq 'ARRAY' ? 'array' : 'object';
            _exception("Unexpected data after $got");
        }

        $ref;
    };

    # Exception
    if ( !$res && ( my $e = $@ ) ) {
        chomp $e;
        $self->error($e);
    }

    if ($self->error) {
        push @_ERRORS, $self->error;
        $FAIL++;
    }

    # return ($ok, \@errors);
    return (!$FAIL, \@_ERRORS);
}

sub _fail {
    my ($got, $schema) = @_;
    _fail2(($_NAME ? "$_NAME: " : '') . $schema->name . " is expected, but $got is found");
}

sub _fail2 {
    my ($msg) = @_;
    $FAIL++;
    push @_ERRORS, $msg;
}

sub false { $FALSE }
sub true  { $TRUE }

sub _decode_array {
    my $schema = _schema(shift);

    my @array;
    my $i = 0;
    until (m/\G$WHITESPACE_RE\]/gc) {
        local $_NAME = $_NAME . "[$i]";

        # Value
        push @array, _decode_value($schema);

        $i++;

        # Separator
        redo if m/\G$WHITESPACE_RE,/gc;

        # End
        last if m/\G$WHITESPACE_RE\]/gc;

        # Invalid character
        _exception(
            'Expected comma or right square bracket while parsing array');
    }

    return \@array;
}

sub _decode_object {
    my $schema = _schema(shift);

    my %hash;
    my %schema = $schema->isa("ThaiSchema::Maybe") ? %{$schema->schema->schema} : %{$schema->schema};
    until (m/\G$WHITESPACE_RE\}/gc) {

        # Quote
        m/\G$WHITESPACE_RE"/gc
          or _exception('Expected string while parsing object');

        # Key
        my $key = _decode_string();

        # Colon
        m/\G$WHITESPACE_RE:/gc
          or _exception('Expected colon while parsing object');

        # Value
        local $_NAME = $_NAME . ".$key";
        my $cschema = delete $schema{$key};
        if ($cschema) {
            $hash{$key} = _decode_value($cschema);
        } else {
            if ($ThaiSchema::ALLOW_EXTRA) {
                $hash{$key} = _decode_value(ThaiSchema::Extra->new());
            } else {
                _exception2("There is extra key: $key");
            }
        }

        # Separator
        redo if m/\G$WHITESPACE_RE,/gc;

        # End
        last if m/\G$WHITESPACE_RE\}/gc;

        # Invalid character
        _exception(
            'Expected comma or right curly bracket while parsing object');
    }

    if (%schema) {
        _fail2('There is missing keys: ' . join(', ', keys %schema));
    }

    return \%hash;
}

sub _decode_string {
    my $pos = pos;

    # Extract string with escaped characters
    m#\G(((?:[^\x00-\x1F\\"]|\\(?:["\\/bfnrt]|u[[:xdigit:]]{4})){0,32766})*)#gc;
    my $str = $1;

    # Missing quote
    unless (m/\G"/gc) {
        _exception(
            'Unexpected character or invalid escape while parsing string')
          if m/\G[\x00-\x1F\\]/;
        _exception('Unterminated string');
    }

    # Unescape popular characters
    if ( index( $str, '\\u' ) < 0 ) {
        $str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
        return $str;
    }

    # Unescape everything else
    my $buffer = '';
    while ( $str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc ) {
        $buffer .= $1;

        # Popular character
        if ($2) { $buffer .= $ESCAPE{$2} }

        # Escaped
        else {
            my $ord = hex $3;

            # Surrogate pair
            if ( ( $ord & 0xF800 ) == 0xD800 ) {

                # High surrogate
                ( $ord & 0xFC00 ) == 0xD800
                  or pos($_) = $pos + pos($str),
                  _exception('Missing high-surrogate');

                # Low surrogate
                $str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
                  or pos($_) = $pos + pos($str),
                  _exception('Missing low-surrogate');

                # Pair
                $ord =
                  0x10000 + ( $ord - 0xD800 ) * 0x400 + ( hex($1) - 0xDC00 );
            }

            # Character
            $buffer .= pack 'U', $ord;
        }
    }

    # The rest
    return $buffer . substr $str, pos($str), length($str);
}

sub _schema {
    my $schema = shift;
    if (ref $schema eq 'HASH') {
        return ThaiSchema::Hash->new(schema => $schema);
    } elsif (ref $schema eq 'ARRAY') {
        if (@$schema > 1) {
            Carp::confess("Invalid schema: too many elements in arrayref: " . ddf($schema));
        }
        return ThaiSchema::Array->new(schema => _schema($schema->[0]));
    } else {
        return $schema;
    }
}

sub _decode_value {
    my $schema = _schema(shift);

    # Leading whitespace
    m/\G$WHITESPACE_RE/gc;

    # String
    if (m/\G"/gc) {
        unless ($schema->is_string) {
            _fail('string', $schema);
        }
        return _decode_string();
    }

    # Array
    if (m/\G\[/gc) {
        unless ($schema->is_array) {
            _fail('array', $schema);
            _exception2("Unexpected array.");
        }
        return _decode_array($schema->schema);
    }

    # Object
    if (m/\G\{/gc) {
        unless ($schema->is_hash) {
            _fail('object', $schema);
            _exception2("Unexpected hash.");
        }
        return _decode_object($schema);
    }

    # Number
    if (m/\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc) {
        my $number = 0+$1;
        unless ($schema->is_number) {
            _fail('number', $schema);
        }
        if ($schema->is_integer && int($number) != $number) {
            push @_ERRORS, "integer is expected, but you got $number";
            $FAIL++;
        }
        return $number;
    }

    # True
    if (m/\Gtrue/gc) {
        unless ($schema->is_bool) {
            _fail('true', $schema);
        }
        return $TRUE;
    }

    # False
    if (m/\Gfalse/gc) {
        unless ($schema->is_bool) {
            _fail('false', $schema);
        }
        return $FALSE;
    }

    # Null
    if (m/\Gnull/gc) {
        unless ($schema->is_null) {
            _fail('null', $schema);
        }
        ## no critic (return)
        return undef;
    }

    # Invalid data
    _exception('Expected string, array, object, number, boolean or null');
}

sub _exception2 {
    # Leading whitespace
    m/\G$WHITESPACE_RE/gc;

    # Context
    my $context;
       $context .= "$_NAME: " if $_NAME;
       $context .= shift;
    if (m/\G\z/gc) { $context .= ' before end of data' }
    else {
        my @lines = split /\n/, substr( $_, 0, pos );
        $context .=
          ' at line ' . @lines . ', offset ' . length( pop @lines || '' );
    }

    # Throw
    die "$context\n";
}

sub _exception {

    # Leading whitespace
    m/\G$WHITESPACE_RE/gc;

    # Context
    my $context = 'Malformed JSON: ' . shift;
    if (m/\G\z/gc) { $context .= ' before end of data' }
    else {
        my @lines = split /\n/, substr( $_, 0, pos );
        $context .=
          ' at line ' . @lines . ', offset ' . length( pop @lines || '' );
    }

    # Throw
    die "$context\n";
}

1;
__END__

=head1 NAME

ThaiSchema::JSON - ThaiSchema meets JSON

=head1 SYNOPSIS

    use ThaiSchema::JSON;
    use ThaiSchema;

    my $schema = type_array();
    my $j = ThaiSchema::JSON->new();
    my ($ok, $errors) = $j->validate('[]', $schema);
    print $ok ? "ok\n" : "not ok\n";
    for (@$errors) {
        print "$_\n";
    }

=head1 DESCRIPTION

This module validates JSON string with ThaiSchema's schema object.

=head1 THANKS TO

This module is based on JSON::Tiny's code. Thanks to David Oswald.
And JSON::Tiny is based on Mojo::JSON. Thanks to Mojolicious development team.

