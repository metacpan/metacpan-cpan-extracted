package XS::JIT::Header::TypeMap;

use strict;
use warnings;

our $VERSION = '0.06';

# C type to Perl type mapping
# Each entry contains:
#   perl    - Perl type category (IV, UV, NV, PV, void)
#   c       - Canonical C type
#   convert - Macro to convert SV to C value
#   create  - Macro to create SV from C value
#   is_ptr  - True if this is a pointer type

our %C_TO_PERL = (
    # Signed integer types
    'char'               => { perl => 'IV', c => 'char',        convert => 'SvIV',  create => 'newSViv' },
    'signed char'        => { perl => 'IV', c => 'signed char', convert => 'SvIV',  create => 'newSViv' },
    'short'              => { perl => 'IV', c => 'short',       convert => 'SvIV',  create => 'newSViv' },
    'short int'          => { perl => 'IV', c => 'short',       convert => 'SvIV',  create => 'newSViv' },
    'signed short'       => { perl => 'IV', c => 'short',       convert => 'SvIV',  create => 'newSViv' },
    'signed short int'   => { perl => 'IV', c => 'short',       convert => 'SvIV',  create => 'newSViv' },
    'int'                => { perl => 'IV', c => 'int',         convert => 'SvIV',  create => 'newSViv' },
    'signed'             => { perl => 'IV', c => 'int',         convert => 'SvIV',  create => 'newSViv' },
    'signed int'         => { perl => 'IV', c => 'int',         convert => 'SvIV',  create => 'newSViv' },
    'long'               => { perl => 'IV', c => 'long',        convert => 'SvIV',  create => 'newSViv' },
    'long int'           => { perl => 'IV', c => 'long',        convert => 'SvIV',  create => 'newSViv' },
    'signed long'        => { perl => 'IV', c => 'long',        convert => 'SvIV',  create => 'newSViv' },
    'signed long int'    => { perl => 'IV', c => 'long',        convert => 'SvIV',  create => 'newSViv' },
    'long long'          => { perl => 'IV', c => 'long long',   convert => 'SvIV',  create => 'newSViv' },
    'long long int'      => { perl => 'IV', c => 'long long',   convert => 'SvIV',  create => 'newSViv' },
    'signed long long'   => { perl => 'IV', c => 'long long',   convert => 'SvIV',  create => 'newSViv' },

    # Unsigned integer types
    'unsigned char'      => { perl => 'UV', c => 'unsigned char',      convert => 'SvUV', create => 'newSVuv' },
    'unsigned short'     => { perl => 'UV', c => 'unsigned short',     convert => 'SvUV', create => 'newSVuv' },
    'unsigned short int' => { perl => 'UV', c => 'unsigned short',     convert => 'SvUV', create => 'newSVuv' },
    'unsigned'           => { perl => 'UV', c => 'unsigned int',       convert => 'SvUV', create => 'newSVuv' },
    'unsigned int'       => { perl => 'UV', c => 'unsigned int',       convert => 'SvUV', create => 'newSVuv' },
    'unsigned long'      => { perl => 'UV', c => 'unsigned long',      convert => 'SvUV', create => 'newSVuv' },
    'unsigned long int'  => { perl => 'UV', c => 'unsigned long',      convert => 'SvUV', create => 'newSVuv' },
    'unsigned long long' => { perl => 'UV', c => 'unsigned long long', convert => 'SvUV', create => 'newSVuv' },

    # Fixed-width integers (C99 stdint.h)
    'int8_t'             => { perl => 'IV', c => 'int8_t',   convert => 'SvIV',  create => 'newSViv' },
    'int16_t'            => { perl => 'IV', c => 'int16_t',  convert => 'SvIV',  create => 'newSViv' },
    'int32_t'            => { perl => 'IV', c => 'int32_t',  convert => 'SvIV',  create => 'newSViv' },
    'int64_t'            => { perl => 'IV', c => 'int64_t',  convert => 'SvIV',  create => 'newSViv' },
    'uint8_t'            => { perl => 'UV', c => 'uint8_t',  convert => 'SvUV',  create => 'newSVuv' },
    'uint16_t'           => { perl => 'UV', c => 'uint16_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint32_t'           => { perl => 'UV', c => 'uint32_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint64_t'           => { perl => 'UV', c => 'uint64_t', convert => 'SvUV',  create => 'newSVuv' },

    # Minimum-width integers (C99 stdint.h)
    'int_least8_t'       => { perl => 'IV', c => 'int_least8_t',   convert => 'SvIV',  create => 'newSViv' },
    'int_least16_t'      => { perl => 'IV', c => 'int_least16_t',  convert => 'SvIV',  create => 'newSViv' },
    'int_least32_t'      => { perl => 'IV', c => 'int_least32_t',  convert => 'SvIV',  create => 'newSViv' },
    'int_least64_t'      => { perl => 'IV', c => 'int_least64_t',  convert => 'SvIV',  create => 'newSViv' },
    'uint_least8_t'      => { perl => 'UV', c => 'uint_least8_t',  convert => 'SvUV',  create => 'newSVuv' },
    'uint_least16_t'     => { perl => 'UV', c => 'uint_least16_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint_least32_t'     => { perl => 'UV', c => 'uint_least32_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint_least64_t'     => { perl => 'UV', c => 'uint_least64_t', convert => 'SvUV',  create => 'newSVuv' },

    # Fast minimum-width integers (C99 stdint.h)
    'int_fast8_t'        => { perl => 'IV', c => 'int_fast8_t',   convert => 'SvIV',  create => 'newSViv' },
    'int_fast16_t'       => { perl => 'IV', c => 'int_fast16_t',  convert => 'SvIV',  create => 'newSViv' },
    'int_fast32_t'       => { perl => 'IV', c => 'int_fast32_t',  convert => 'SvIV',  create => 'newSViv' },
    'int_fast64_t'       => { perl => 'IV', c => 'int_fast64_t',  convert => 'SvIV',  create => 'newSViv' },
    'uint_fast8_t'       => { perl => 'UV', c => 'uint_fast8_t',  convert => 'SvUV',  create => 'newSVuv' },
    'uint_fast16_t'      => { perl => 'UV', c => 'uint_fast16_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint_fast32_t'      => { perl => 'UV', c => 'uint_fast32_t', convert => 'SvUV',  create => 'newSVuv' },
    'uint_fast64_t'      => { perl => 'UV', c => 'uint_fast64_t', convert => 'SvUV',  create => 'newSVuv' },

    # Maximum-width integers (C99 stdint.h)
    'intmax_t'           => { perl => 'IV', c => 'intmax_t',  convert => 'SvIV',  create => 'newSViv' },
    'uintmax_t'          => { perl => 'UV', c => 'uintmax_t', convert => 'SvUV',  create => 'newSVuv' },

    # Size types
    'size_t'             => { perl => 'UV', c => 'size_t',    convert => 'SvUV',  create => 'newSVuv' },
    'ssize_t'            => { perl => 'IV', c => 'ssize_t',   convert => 'SvIV',  create => 'newSViv' },
    'ptrdiff_t'          => { perl => 'IV', c => 'ptrdiff_t', convert => 'SvIV',  create => 'newSViv' },
    'intptr_t'           => { perl => 'IV', c => 'intptr_t',  convert => 'SvIV',  create => 'newSViv' },
    'uintptr_t'          => { perl => 'UV', c => 'uintptr_t', convert => 'SvUV',  create => 'newSVuv' },
    'max_align_t'        => { perl => 'UV', c => 'max_align_t', convert => 'SvUV', create => 'newSVuv' },

    # Wide character types (wchar.h)
    'wchar_t'            => { perl => 'IV', c => 'wchar_t', convert => 'SvIV',  create => 'newSViv' },
    'wint_t'             => { perl => 'IV', c => 'wint_t',  convert => 'SvIV',  create => 'newSViv' },

    # Unicode character types (C11 uchar.h)
    'char16_t'           => { perl => 'UV', c => 'char16_t', convert => 'SvUV',  create => 'newSVuv' },
    'char32_t'           => { perl => 'UV', c => 'char32_t', convert => 'SvUV',  create => 'newSVuv' },

    # POSIX types
    'off_t'              => { perl => 'IV', c => 'off_t',    convert => 'SvIV',  create => 'newSViv' },
    'pid_t'              => { perl => 'IV', c => 'pid_t',    convert => 'SvIV',  create => 'newSViv' },
    'uid_t'              => { perl => 'UV', c => 'uid_t',    convert => 'SvUV',  create => 'newSVuv' },
    'gid_t'              => { perl => 'UV', c => 'gid_t',    convert => 'SvUV',  create => 'newSVuv' },
    'mode_t'             => { perl => 'UV', c => 'mode_t',   convert => 'SvUV',  create => 'newSVuv' },
    'dev_t'              => { perl => 'UV', c => 'dev_t',    convert => 'SvUV',  create => 'newSVuv' },
    'ino_t'              => { perl => 'UV', c => 'ino_t',    convert => 'SvUV',  create => 'newSVuv' },
    'nlink_t'            => { perl => 'UV', c => 'nlink_t',  convert => 'SvUV',  create => 'newSVuv' },
    'blksize_t'          => { perl => 'IV', c => 'blksize_t', convert => 'SvIV', create => 'newSViv' },
    'blkcnt_t'           => { perl => 'IV', c => 'blkcnt_t', convert => 'SvIV',  create => 'newSViv' },

    # Time types
    'time_t'             => { perl => 'IV', c => 'time_t',   convert => 'SvIV',  create => 'newSViv' },
    'clock_t'            => { perl => 'IV', c => 'clock_t',  convert => 'SvIV',  create => 'newSViv' },
    'suseconds_t'        => { perl => 'IV', c => 'suseconds_t', convert => 'SvIV', create => 'newSViv' },

    # Floating point types
    'float'              => { perl => 'NV', c => 'float',       convert => 'SvNV', create => 'newSVnv' },
    'double'             => { perl => 'NV', c => 'double',      convert => 'SvNV', create => 'newSVnv' },
    'long double'        => { perl => 'NV', c => 'long double', convert => 'SvNV', create => 'newSVnv' },

    # String types
    'char*'              => { perl => 'PV', c => 'char*',       convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'char *'             => { perl => 'PV', c => 'char*',       convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'const char*'        => { perl => 'PV', c => 'const char*', convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'const char *'       => { perl => 'PV', c => 'const char*', convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },

    # Void
    'void'               => { perl => 'void', c => 'void', convert => undef, create => undef },

    # Pointer types (opaque)
    'void*'              => { perl => 'UV', c => 'void*', convert => 'PTR2UV', create => 'newSVuv', is_ptr => 1 },
    'void *'             => { perl => 'UV', c => 'void*', convert => 'PTR2UV', create => 'newSVuv', is_ptr => 1 },

    # Boolean (C99)
    '_Bool'              => { perl => 'IV', c => '_Bool', convert => 'SvIV', create => 'newSViv' },
    'bool'               => { perl => 'IV', c => 'bool',  convert => 'SvIV', create => 'newSViv' },

    # Perl internal types - pass-through (no conversion needed)
    # These allow C code to work directly with Perl data structures
    'SV*'                => { perl => 'SV', c => 'SV*', convert => '',   create => '',   is_perl => 1 },
    'SV *'               => { perl => 'SV', c => 'SV*', convert => '',   create => '',   is_perl => 1 },
    'HV*'                => { perl => 'HV', c => 'HV*', convert => '(HV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_hash => 1 },
    'HV *'               => { perl => 'HV', c => 'HV*', convert => '(HV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_hash => 1 },
    'AV*'                => { perl => 'AV', c => 'AV*', convert => '(AV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_array => 1 },
    'AV *'               => { perl => 'AV', c => 'AV*', convert => '(AV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_array => 1 },
    'CV*'                => { perl => 'CV', c => 'CV*', convert => '(CV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_code => 1 },
    'CV *'               => { perl => 'CV', c => 'CV*', convert => '(CV*)SvRV', create => 'newRV_noinc((SV*)', is_perl => 1, is_code => 1 },

    # Complex types (C99) - stored as array refs of [real, imag]
    'float _Complex'       => { perl => 'NV', c => 'float _Complex',       convert => 'SvNV', create => 'newSVnv', is_complex => 1 },
    'double _Complex'      => { perl => 'NV', c => 'double _Complex',      convert => 'SvNV', create => 'newSVnv', is_complex => 1 },
    'long double _Complex' => { perl => 'NV', c => 'long double _Complex', convert => 'SvNV', create => 'newSVnv', is_complex => 1 },
    'float complex'        => { perl => 'NV', c => 'float _Complex',       convert => 'SvNV', create => 'newSVnv', is_complex => 1 },
    'double complex'       => { perl => 'NV', c => 'double _Complex',      convert => 'SvNV', create => 'newSVnv', is_complex => 1 },
    'long double complex'  => { perl => 'NV', c => 'long double _Complex', convert => 'SvNV', create => 'newSVnv', is_complex => 1 },

    # Atomic types (C11) - treated as their base types
    'atomic_bool'          => { perl => 'IV', c => 'atomic_bool',     convert => 'SvIV',  create => 'newSViv' },
    'atomic_char'          => { perl => 'IV', c => 'atomic_char',     convert => 'SvIV',  create => 'newSViv' },
    'atomic_schar'         => { perl => 'IV', c => 'atomic_schar',    convert => 'SvIV',  create => 'newSViv' },
    'atomic_uchar'         => { perl => 'UV', c => 'atomic_uchar',    convert => 'SvUV',  create => 'newSVuv' },
    'atomic_short'         => { perl => 'IV', c => 'atomic_short',    convert => 'SvIV',  create => 'newSViv' },
    'atomic_ushort'        => { perl => 'UV', c => 'atomic_ushort',   convert => 'SvUV',  create => 'newSVuv' },
    'atomic_int'           => { perl => 'IV', c => 'atomic_int',      convert => 'SvIV',  create => 'newSViv' },
    'atomic_uint'          => { perl => 'UV', c => 'atomic_uint',     convert => 'SvUV',  create => 'newSVuv' },
    'atomic_long'          => { perl => 'IV', c => 'atomic_long',     convert => 'SvIV',  create => 'newSViv' },
    'atomic_ulong'         => { perl => 'UV', c => 'atomic_ulong',    convert => 'SvUV',  create => 'newSVuv' },
    'atomic_llong'         => { perl => 'IV', c => 'atomic_llong',    convert => 'SvIV',  create => 'newSViv' },
    'atomic_ullong'        => { perl => 'UV', c => 'atomic_ullong',   convert => 'SvUV',  create => 'newSVuv' },
    'atomic_size_t'        => { perl => 'UV', c => 'atomic_size_t',   convert => 'SvUV',  create => 'newSVuv' },
    'atomic_ptrdiff_t'     => { perl => 'IV', c => 'atomic_ptrdiff_t', convert => 'SvIV', create => 'newSViv' },
    'atomic_intptr_t'      => { perl => 'IV', c => 'atomic_intptr_t', convert => 'SvIV',  create => 'newSViv' },
    'atomic_uintptr_t'     => { perl => 'UV', c => 'atomic_uintptr_t', convert => 'SvUV', create => 'newSVuv' },
    'atomic_intmax_t'      => { perl => 'IV', c => 'atomic_intmax_t', convert => 'SvIV',  create => 'newSViv' },
    'atomic_uintmax_t'     => { perl => 'UV', c => 'atomic_uintmax_t', convert => 'SvUV', create => 'newSVuv' },

    # Windows types (commonly encountered)
    'BOOL'                 => { perl => 'IV', c => 'BOOL',   convert => 'SvIV',  create => 'newSViv' },
    'BYTE'                 => { perl => 'UV', c => 'BYTE',   convert => 'SvUV',  create => 'newSVuv' },
    'WORD'                 => { perl => 'UV', c => 'WORD',   convert => 'SvUV',  create => 'newSVuv' },
    'DWORD'                => { perl => 'UV', c => 'DWORD',  convert => 'SvUV',  create => 'newSVuv' },
    'QWORD'                => { perl => 'UV', c => 'QWORD',  convert => 'SvUV',  create => 'newSVuv' },
    'INT'                  => { perl => 'IV', c => 'INT',    convert => 'SvIV',  create => 'newSViv' },
    'UINT'                 => { perl => 'UV', c => 'UINT',   convert => 'SvUV',  create => 'newSVuv' },
    'LONG'                 => { perl => 'IV', c => 'LONG',   convert => 'SvIV',  create => 'newSViv' },
    'ULONG'                => { perl => 'UV', c => 'ULONG',  convert => 'SvUV',  create => 'newSVuv' },
    'LONGLONG'             => { perl => 'IV', c => 'LONGLONG',  convert => 'SvIV', create => 'newSViv' },
    'ULONGLONG'            => { perl => 'UV', c => 'ULONGLONG', convert => 'SvUV', create => 'newSVuv' },
    'HANDLE'               => { perl => 'UV', c => 'HANDLE', convert => 'PTR2UV', create => 'newSVuv', is_ptr => 1 },
    'LPVOID'               => { perl => 'UV', c => 'LPVOID', convert => 'PTR2UV', create => 'newSVuv', is_ptr => 1 },
    'LPCVOID'              => { perl => 'UV', c => 'LPCVOID', convert => 'PTR2UV', create => 'newSVuv', is_ptr => 1 },
    'LPSTR'                => { perl => 'PV', c => 'LPSTR',  convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'LPCSTR'               => { perl => 'PV', c => 'LPCSTR', convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'LPWSTR'               => { perl => 'PV', c => 'LPWSTR', convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'LPCWSTR'              => { perl => 'PV', c => 'LPCWSTR', convert => 'SvPV_nolen', create => 'newSVpv', is_string => 1 },
    'SIZE_T'               => { perl => 'UV', c => 'SIZE_T', convert => 'SvUV',  create => 'newSVuv' },
    'SSIZE_T'              => { perl => 'IV', c => 'SSIZE_T', convert => 'SvIV', create => 'newSViv' },
);

# Normalize type string: remove extra whitespace, normalize pointer syntax
sub normalize_type {
    my ($type) = @_;
    return undef unless defined $type;

    # Remove leading/trailing whitespace
    $type =~ s/^\s+//;
    $type =~ s/\s+$//;

    # Normalize multiple spaces to single space
    $type =~ s/\s+/ /g;

    # Normalize pointer spacing: "char *" -> "char*", "char * *" -> "char**"
    $type =~ s/\s*\*\s*/*/g;

    # But keep space before first * if preceded by word: "char*" not "char *"
    # Actually, normalize to "type*" format
    $type =~ s/(\w)\s*\*/$1*/g;

    return $type;
}

# Resolve a C type to its Perl mapping
# Returns hashref with: perl, c, convert, create, is_ptr, is_string
sub resolve {
    my ($type) = @_;

    $type = normalize_type($type);
    return undef unless defined $type;

    # Direct match
    if (exists $C_TO_PERL{$type}) {
        return { %{$C_TO_PERL{$type}} };
    }

    # Check with/without const
    my $without_const = $type;
    $without_const =~ s/\bconst\s*//g;
    $without_const = normalize_type($without_const);

    if (exists $C_TO_PERL{$without_const}) {
        my $info = { %{$C_TO_PERL{$without_const}} };
        $info->{c} = $type;  # Keep original type with const
        return $info;
    }

    # Handle pointers to known types
    if ($type =~ /^(.+?)\*+$/) {
        my $base = normalize_type($1);
        my $ptr_count = ($type =~ tr/*/*/);

        # Single pointer to known type
        if ($ptr_count == 1 && exists $C_TO_PERL{$base}) {
            return {
                perl    => 'UV',
                c       => $type,
                convert => 'PTR2UV',
                create  => 'newSVuv',
                is_ptr  => 1,
                base    => $base,
            };
        }

        # Multi-level pointer or pointer to unknown type
        return {
            perl    => 'UV',
            c       => $type,
            convert => 'PTR2UV',
            create  => 'newSVuv',
            is_ptr  => 1,
            opaque  => 1,
        };
    }

    # Unknown type - treat as opaque (likely a typedef or struct)
    return {
        perl    => 'UV',
        c       => $type,
        convert => 'PTR2UV',
        create  => 'newSVuv',
        is_ptr  => 1,
        opaque  => 1,
        unknown => 1,
    };
}

# Check if a type is known
sub is_known {
    my ($type) = @_;
    $type = normalize_type($type);
    return exists $C_TO_PERL{$type};
}

# Get all known types
sub known_types {
    return keys %C_TO_PERL;
}

# Register a custom type mapping
sub register {
    my ($type, %info) = @_;

    die "Type name required" unless defined $type;
    die "Perl type required" unless defined $info{perl};
    die "C type required" unless defined $info{c};

    $type = normalize_type($type);
    $C_TO_PERL{$type} = \%info;

    return 1;
}

# Register a type alias (maps to existing type)
sub alias {
    my ($new_type, $existing_type) = @_;

    my $info = resolve($existing_type);
    die "Unknown type: $existing_type" unless $info && !$info->{unknown};

    $new_type = normalize_type($new_type);
    $C_TO_PERL{$new_type} = { %$info, c => $new_type };

    return 1;
}

1;

__END__

=head1 NAME

XS::JIT::Header::TypeMap - C to Perl type mappings for XS::JIT::Header

=head1 SYNOPSIS

    use XS::JIT::Header::TypeMap;

    # Resolve a C type
    my $info = XS::JIT::Header::TypeMap::resolve('int');
    # Returns: { perl => 'IV', c => 'int', convert => 'SvIV', create => 'newSViv' }

    my $info = XS::JIT::Header::TypeMap::resolve('const char*');
    # Returns: { perl => 'PV', c => 'const char*', convert => 'SvPV_nolen', ... }

    # Register custom type
    XS::JIT::Header::TypeMap::register('MyInt',
        perl    => 'IV',
        c       => 'MyInt',
        convert => 'SvIV',
        create  => 'newSViv',
    );

    # Create alias
    XS::JIT::Header::TypeMap::alias('BOOL', 'int');

=head1 DESCRIPTION

This module provides C to Perl type mappings used by XS::JIT::Header
for generating XS wrapper code. It handles standard C types, fixed-width
integers, pointers, and allows registration of custom types.

=head1 FUNCTIONS

=head2 resolve($type)

Resolves a C type string to its Perl mapping. Returns a hashref with:

=over 4

=item perl - Perl type category (IV, UV, NV, PV, void)

=item c - Canonical C type string

=item convert - Macro to convert SV to C value (e.g., SvIV)

=item create - Macro to create SV from C value (e.g., newSViv)

=item is_ptr - True if this is a pointer type

=item is_string - True if this is a string type (char*)

=item opaque - True if treated as opaque pointer

=item unknown - True if type was not recognized

=back

=head2 normalize_type($type)

Normalizes a C type string by removing extra whitespace and
standardizing pointer notation.

=head2 is_known($type)

Returns true if the type is directly known (not inferred).

=head2 known_types()

Returns list of all known type names.

=head2 register($type, %info)

Registers a custom type mapping.

=head2 alias($new_type, $existing_type)

Creates a type alias.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut
