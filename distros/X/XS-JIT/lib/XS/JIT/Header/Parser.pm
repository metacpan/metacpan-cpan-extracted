package XS::JIT::Header::Parser;

use strict;
use warnings;
use File::Temp qw(tempfile);
use File::Spec;

our $VERSION = '0.06';

# Find a working C preprocessor
sub _find_preprocessor {
    my @candidates = qw(clang cpp gcc);

    for my $cmd (@candidates) {
        my $output = `$cmd --version 2>/dev/null`;
        if ($? == 0) {
            return $cmd eq 'gcc' ? "$cmd -E" : "$cmd -E";
        }
    }

    die "No C preprocessor found. Install clang, gcc, or cpp.";
}

# Create a new parser instance
sub new {
    my ($class, %opts) = @_;

    my $self = bless {
        include    => $opts{include} || [],
        define     => $opts{define} || {},
        functions  => {},
        constants  => {},
        typedefs   => {},
        enums      => {},
        structs    => {},
        _raw_code  => '',
        _preprocessed => '',
    }, $class;

    return $self;
}

# Parse a header file
sub parse_file {
    my ($self, $header_path) = @_;

    die "Header file required" unless defined $header_path;

    # Read raw header for constant extraction
    if (-f $header_path) {
        open my $fh, '<', $header_path or die "Cannot read $header_path: $!";
        local $/;
        $self->{_raw_code} = <$fh>;
        close $fh;
    }

    # Preprocess and parse
    $self->_preprocess($header_path);
    $self->_parse_functions();
    $self->_parse_constants();
    $self->_parse_enums();

    return $self;
}

# Parse header content directly (for testing)
sub parse_string {
    my ($self, $code) = @_;

    $self->{_raw_code} = $code;

    # Write to temp file for preprocessing
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.h', UNLINK => 1);
    print $fh $code;
    close $fh;

    $self->_preprocess($tmpfile);
    $self->_parse_functions();
    $self->_parse_constants();
    $self->_parse_enums();

    return $self;
}

# Run C preprocessor
sub _preprocess {
    my ($self, $header_path) = @_;

    my $cpp = _find_preprocessor();

    my @includes = map { "-I$_" } @{$self->{include}};
    my @defines = map { "-D$_=$self->{define}{$_}" } keys %{$self->{define}};

    my $cmd = join(' ',
        $cpp,
        @includes,
        @defines,
        '-x', 'c',  # Force C language
        qq{"$header_path"},
        '2>/dev/null'
    );

    $self->{_preprocessed} = `$cmd`;

    if ($? != 0) {
        warn "Preprocessor warning for $header_path (exit code: $?)";
        # Try to continue with raw code if preprocessing fails
        $self->{_preprocessed} = $self->{_raw_code} if $self->{_raw_code};
    }

    return $self->{_preprocessed};
}

# Parse function declarations from preprocessed code
sub _parse_functions {
    my ($self) = @_;

    my $code = $self->{_preprocessed};
    return unless $code;

    # Remove comments (shouldn't be any after preprocessing, but just in case)
    $code =~ s{/\*.*?\*/}{}gs;
    $code =~ s{//.*$}{}gm;

    # Function declaration pattern
    # Matches: return_type function_name(params);
    # Handles: const, static, inline, extern, pointers, etc.
    my $func_pattern = qr/
        (?:^|;|\}|\n)                         # Start of line, after semicolon, or after brace
        \s*
        (?:extern\s+|static\s+|inline\s+)*    # Optional storage class
        (                                      # Capture group 1: return type
            (?:const\s+)?                     # Optional const
            (?:unsigned\s+|signed\s+)?        # Optional unsigned\/signed
            (?:struct\s+|enum\s+|union\s+)?   # Optional struct\/enum\/union
            \w+                                # Type name
            (?:\s+\w+)*                        # Additional type words (long long, etc.)
            \s*\**                             # Optional pointer(s)
        )
        \s+
        (\w+)                                  # Capture group 2: function name
        \s*
        \(                                     # Opening paren
        ([^)]*?)                               # Capture group 3: parameters
        \)                                     # Closing paren
        \s*
        (?:__attribute__\s*\(\([^)]*\)\))?    # Optional GCC attributes
        \s*;                                   # Semicolon
    /xm;

    while ($code =~ /$func_pattern/g) {
        my ($return_type, $name, $params) = ($1, $2, $3);

        # Clean up return type
        $return_type =~ s/^\s+//;
        $return_type =~ s/\s+$//;
        $return_type =~ s/\s+/ /g;

        # Skip if it looks like a macro or type definition
        next if $name =~ /^_/;  # Skip internal/reserved names
        next if $return_type =~ /^#/;  # Skip preprocessor remnants

        # Parse parameters
        my @parsed_params = $self->_parse_params($params);

        $self->{functions}{$name} = {
            name        => $name,
            return_type => $return_type,
            params      => \@parsed_params,
            param_types => [ map { $_->{type} } @parsed_params ],
            param_names => [ map { $_->{name} } @parsed_params ],
            is_variadic => ($params =~ /\.\.\./ ? 1 : 0),
        };
    }

    return $self->{functions};
}

# Parse parameter list
sub _parse_params {
    my ($self, $params) = @_;

    return () if !defined $params || $params =~ /^\s*$/;
    return () if $params =~ /^\s*void\s*$/;

    my @result;
    my @parts = split /,/, $params;

    my $idx = 0;
    for my $part (@parts) {
        $part =~ s/^\s+//;
        $part =~ s/\s+$//;

        # Skip variadic
        next if $part eq '...';

        # Parse "type name" or just "type"
        if ($part =~ /^(.+?)\s+(\w+)$/) {
            push @result, { type => $1, name => $2, index => $idx };
        }
        elsif ($part =~ /^(.+?)\s*(\*+)\s*(\w+)$/) {
            # Handle "type *name" or "type * name"
            push @result, { type => "$1$2", name => $3, index => $idx };
        }
        elsif ($part =~ /^(.+?)$/) {
            # Just a type, no name
            push @result, { type => $1, name => "arg$idx", index => $idx };
        }

        $idx++;
    }

    return @result;
}

# Parse #define constants from raw (non-preprocessed) code
sub _parse_constants {
    my ($self) = @_;

    my $code = $self->{_raw_code};
    return unless $code;

    # Match #define NAME value (excluding function-like macros)
    while ($code =~ /^\s*#\s*define\s+(\w+)(?!\s*\()[ \t]+(.+?)\s*$/gm) {
        my ($name, $value) = ($1, $2);

        # Skip common non-value defines
        next if $value =~ /^\\/;  # Line continuation
        next if $name =~ /^_/;    # Reserved names

        # Try to evaluate numeric constants
        my $numeric = $self->_try_numeric($value);
        if (defined $numeric) {
            $self->{constants}{$name} = {
                name  => $name,
                value => $numeric,
                raw   => $value,
            };
        }
        else {
            # Store as string constant
            $self->{constants}{$name} = {
                name   => $name,
                value  => $value,
                raw    => $value,
                string => 1,
            };
        }
    }

    return $self->{constants};
}

# Try to convert a value to a number
sub _try_numeric {
    my ($self, $value) = @_;

    # Strip trailing C comments (e.g., "3.14159 /* pi */")
    $value =~ s{/\*.*?\*/}{}g;
    $value =~ s{\s+$}{};

    # Hex
    if ($value =~ /^0x([0-9a-fA-F]+)(?:U?L{0,2})?$/) {
        return hex($1);
    }

    # Octal
    if ($value =~ /^0([0-7]+)(?:U?L{0,2})?$/) {
        return oct($1);
    }

    # Integer
    if ($value =~ /^(-?\d+)(?:U?L{0,2})?$/) {
        return $1 + 0;
    }

    # Float (with optional trailing whitespace/suffix)
    if ($value =~ /^(-?\d+\.?\d*(?:[eE][+-]?\d+)?)[fFlL]?\s*$/) {
        return $1 + 0.0;
    }

    # Simple expression like (1 << 4)
    if ($value =~ /^\(?\s*(\d+)\s*<<\s*(\d+)\s*\)?$/) {
        return $1 << $2;
    }

    return undef;
}

# Parse enum definitions
sub _parse_enums {
    my ($self) = @_;

    my $code = $self->{_raw_code};
    return unless $code;

    # Match enum blocks
    while ($code =~ /enum\s*(\w*)\s*\{([^}]+)\}/g) {
        my ($enum_name, $body) = ($1 || 'anonymous', $2);

        my $counter = 0;
        my @values;

        # Parse enum values
        while ($body =~ /(\w+)(?:\s*=\s*([^,}]+))?/g) {
            my ($name, $value) = ($1, $2);

            if (defined $value) {
                my $num = $self->_try_numeric($value);
                $counter = defined $num ? $num : $counter;
            }

            push @values, { name => $name, value => $counter };

            # Also add to constants
            $self->{constants}{$name} = {
                name  => $name,
                value => $counter,
                enum  => $enum_name,
            };

            $counter++;
        }

        $self->{enums}{$enum_name} = \@values;
    }

    return $self->{enums};
}

# Accessors
sub functions  { return %{shift->{functions}} }
sub function   { my ($self, $name) = @_; return $self->{functions}{$name} }
sub constants  { return %{shift->{constants}} }
sub constant   { my ($self, $name) = @_; return $self->{constants}{$name} }
sub enums      { return %{shift->{enums}} }
sub enum       { my ($self, $name) = @_; return $self->{enums}{$name} }

# Get list of function names
sub function_names {
    my ($self) = @_;
    return sort keys %{$self->{functions}};
}

# Get list of constant names
sub constant_names {
    my ($self) = @_;
    return sort keys %{$self->{constants}};
}

1;

__END__

=head1 NAME

XS::JIT::Header::Parser - C header file parser for XS::JIT::Header

=head1 SYNOPSIS

    use XS::JIT::Header::Parser;

    my $parser = XS::JIT::Header::Parser->new(
        include => ['/usr/local/include'],
        define  => { VERSION => '1.0' },
    );

    $parser->parse_file('/usr/include/math.h');

    # Get all functions
    my %funcs = $parser->functions;
    for my $name (sort keys %funcs) {
        my $f = $funcs{$name};
        print "$f->{return_type} $name(",
              join(', ', @{$f->{param_types}}), ")\n";
    }

    # Get specific function
    my $sin = $parser->function('sin');
    # { name => 'sin', return_type => 'double', params => [...] }

    # Get constants
    my %consts = $parser->constants;
    my $pi = $parser->constant('M_PI');

=head1 DESCRIPTION

This module parses C header files to extract function declarations,
constants, and enums. It uses the system C preprocessor to handle
includes and macros, then applies regex patterns to extract declarations.

=head1 METHODS

=head2 new(%options)

Creates a new parser instance.

Options:

=over 4

=item include

Arrayref of include directories.

=item define

Hashref of preprocessor defines.

=back

=head2 parse_file($path)

Parses a header file at the given path.

=head2 parse_string($code)

Parses header content from a string.

=head2 functions()

Returns hash of all parsed functions.

=head2 function($name)

Returns info for a specific function.

=head2 function_names()

Returns sorted list of function names.

=head2 constants()

Returns hash of all parsed constants.

=head2 constant($name)

Returns info for a specific constant.

=head2 constant_names()

Returns sorted list of constant names.

=head2 enums()

Returns hash of all parsed enums.

=head2 enum($name)

Returns values for a specific enum.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut
