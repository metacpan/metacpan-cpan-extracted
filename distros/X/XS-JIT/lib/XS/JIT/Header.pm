package XS::JIT::Header;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.05';

use XS::JIT;
use XS::JIT::Builder;
use XS::JIT::Header::Parser;
use XS::JIT::Header::TypeMap;
use File::Spec;
use Digest::MD5 qw(md5_hex);
use Config;

sub new {
    my ($class, %opts) = @_;

    my $self = bless {
        header    => $opts{header},
        lib       => $opts{lib},
        include   => $opts{include} || [],
        define    => $opts{define} || {},
        package   => $opts{package} || caller(),
        cache_dir => $opts{cache_dir} || '_CACHED_XS',
        prefix    => $opts{prefix} || '',
        force     => $opts{force} || 0,

        # Internal state
        _parser    => undef,
        _functions => [],   # Functions to compile
        _compiled  => 0,
        _module_id => undef,
    }, $class;

    # Parse header if provided
    if ($self->{header}) {
        $self->_parse_header();
    }

    return $self;
}

# Parse the header file
sub _parse_header {
    my ($self) = @_;

    $self->{_parser} = XS::JIT::Header::Parser->new(
        include => $self->{include},
        define  => $self->{define},
    );

    my $header = $self->{header};

    # Handle system headers (e.g., 'math.h')
    if ($header !~ m{^[/.]}) {
        $header = $self->_find_header($header);
    }

    if (-f $header) {
        $self->{_parser}->parse_file($header);
        $self->{_header_path} = $header;
    }
    else {
        die "Cannot find header file: $self->{header}";
    }

    # Generate unique module ID based on header content and options
    $self->{_module_id} = $self->_generate_module_id();

    return $self;
}

# Get system include paths - uses Perl's Config which knows where headers are
sub system_include_paths {
    my ($class_or_self) = @_;

    my @paths;

    # Primary: Perl's configured system include (most reliable)
    push @paths, $Config{usrinc} if $Config{usrinc};

    # From Perl's library paths (may contain include dirs)
    if ($Config{locincpth}) {
        push @paths, split(/\s+/, $Config{locincpth});
    }

    # Standard fallbacks
    push @paths, '/usr/include', '/usr/local/include';

    # macOS: use xcrun to find SDK (cached)
    if ($^O eq 'darwin') {
        state $sdk_path;
        unless (defined $sdk_path) {
            $sdk_path = `xcrun --show-sdk-path 2>/dev/null`;
            chomp $sdk_path if $sdk_path;
            $sdk_path //= '';
        }
        push @paths, "$sdk_path/usr/include" if $sdk_path && -d "$sdk_path/usr/include";
    }

    # Filter to existing directories and dedupe
    my %seen;
    return grep { defined $_ && -d $_ && !$seen{$_}++ } @paths;
}

# Find a header file in system include paths
sub _find_header {
    my ($self, $header) = @_;

    # User-specified include paths first
    my @search_paths = (
        @{$self->{include}},
        $self->system_include_paths,
    );

    for my $dir (@search_paths) {
        my $path = File::Spec->catfile($dir, $header);
        return $path if -f $path;
    }

    # Not found - return original (will fail later with clear error)
    return $header;
}

# Generate unique module ID for caching
sub _generate_module_id {
    my ($self) = @_;

    my $sig = join("\0",
        $self->{header} || '',
        $self->{lib} || '',
        $self->{package},
        $self->{prefix},
        map { "$_=$self->{define}{$_}" } sort keys %{$self->{define}},
    );

    my $hash = substr(md5_hex($sig), 0, 8);
    my $pkg = $self->{package};
    $pkg =~ s/::/_/g;

    return "${pkg}_Header_${hash}";
}

# Attach a single function
sub attach {
    my ($self, $c_name, @args) = @_;

    die "Function name required" unless defined $c_name;

    # Parse arguments: attach('c_name') or attach('c_name' => 'perl_name')
    #                  or attach('c_name' => ['arg_types'] => 'return_type')
    my ($perl_name, $arg_types, $return_type);

    if (@args == 0) {
        # attach('func') - use same name, strip prefix
        $perl_name = $c_name;
        $perl_name =~ s/^\Q$self->{prefix}\E// if $self->{prefix};
    }
    elsif (@args == 1 && !ref $args[0]) {
        # attach('c_func' => 'perl_func')
        $perl_name = $args[0];
    }
    elsif (@args == 2 && ref $args[0] eq 'ARRAY') {
        # attach('c_func' => ['int', 'char*'] => 'int')
        $perl_name = $c_name;
        $perl_name =~ s/^\Q$self->{prefix}\E// if $self->{prefix};
        $arg_types = $args[0];
        $return_type = $args[1];
    }
    elsif (@args == 3) {
        # attach('c_func' => 'perl_func' => ['int'] => 'int')
        $perl_name = $args[0];
        $arg_types = $args[1];
        $return_type = $args[2];
    }

    # Get function info from parser if not explicitly provided
    my $func_info = $self->{_parser}->function($c_name);

    if (!$func_info && !$arg_types) {
        die "Unknown function '$c_name' and no type information provided";
    }

    # Use parsed info if not explicitly provided
    $arg_types //= $func_info->{param_types} if $func_info;
    $return_type //= $func_info->{return_type} if $func_info;

    # Build full Perl name
    my $full_perl_name = $perl_name =~ /::/ ? $perl_name : "$self->{package}::$perl_name";

    push @{$self->{_functions}}, {
        c_name      => $c_name,
        perl_name   => $full_perl_name,
        arg_types   => $arg_types || [],
        return_type => $return_type || 'void',
        is_variadic => $func_info ? $func_info->{is_variadic} : 0,
    };

    return $self;
}

# Attach multiple functions
sub attach_all {
    my ($self, $filter) = @_;

    my @names = $self->{_parser}->function_names;

    for my $name (@names) {
        # Apply filter if provided
        if (defined $filter) {
            if (ref $filter eq 'Regexp') {
                next unless $name =~ $filter;
            }
            elsif (ref $filter eq 'CODE') {
                next unless $filter->($name);
            }
        }

        $self->attach($name);
    }

    return $self;
}

# Get list of function names from parsed header
sub functions {
    my ($self) = @_;
    return $self->{_parser}->function_names;
}

# Get function info
sub function {
    my ($self, $name) = @_;
    return $self->{_parser}->function($name);
}

# Get list of constant names
sub constants {
    my ($self) = @_;
    return $self->{_parser}->constant_names;
}

# Get constant value
sub constant {
    my ($self, $name) = @_;
    my $info = $self->{_parser}->constant($name);
    return $info ? $info->{value} : undef;
}

# Generate XS wrapper code for a function
sub _generate_wrapper {
    my ($self, $func) = @_;

    my $b = XS::JIT::Builder->new;
    my $safe_name = $func->{c_name};
    $safe_name =~ s/\W/_/g;

    my @arg_types = @{$func->{arg_types}};
    my $return_type = $func->{return_type};

    $b->xs_function("xs_$safe_name")
      ->xs_preamble;

    # Check argument count
    my $num_args = scalar @arg_types;
    if ($num_args > 0) {
        my $usage = join(', ', map { "\$arg$_" } 0 .. $#arg_types);
        $b->check_items($num_args, $num_args, $usage);
    }

    # Convert arguments from Perl to C
    my @c_args;
    for my $i (0 .. $#arg_types) {
        my $type = $arg_types[$i];
        my $type_info = XS::JIT::Header::TypeMap::resolve($type);
        my $arg_name = "arg$i";

        if ($type_info->{perl} eq 'IV') {
            $b->line("$type_info->{c} $arg_name = ($type_info->{c})SvIV(ST($i));");
        }
        elsif ($type_info->{perl} eq 'UV') {
            if ($type_info->{is_ptr}) {
                $b->line("$type_info->{c} $arg_name = INT2PTR($type_info->{c}, SvUV(ST($i)));");
            }
            else {
                $b->line("$type_info->{c} $arg_name = ($type_info->{c})SvUV(ST($i));");
            }
        }
        elsif ($type_info->{perl} eq 'NV') {
            $b->line("$type_info->{c} $arg_name = ($type_info->{c})SvNV(ST($i));");
        }
        elsif ($type_info->{perl} eq 'PV') {
            $b->line("$type_info->{c} $arg_name = SvPV_nolen(ST($i));");
        }
        elsif ($type_info->{perl} eq 'SV') {
            # Pass SV* directly - no conversion needed
            $b->line("SV* $arg_name = ST($i);");
        }
        elsif ($type_info->{perl} eq 'HV') {
            # Dereference to get HV* from hashref
            $b->line("if (!SvROK(ST($i)) || SvTYPE(SvRV(ST($i))) != SVt_PVHV)");
            $b->line("    croak(\"Argument $i must be a hash reference\");");
            $b->line("HV* $arg_name = (HV*)SvRV(ST($i));");
        }
        elsif ($type_info->{perl} eq 'AV') {
            # Dereference to get AV* from arrayref
            $b->line("if (!SvROK(ST($i)) || SvTYPE(SvRV(ST($i))) != SVt_PVAV)");
            $b->line("    croak(\"Argument $i must be an array reference\");");
            $b->line("AV* $arg_name = (AV*)SvRV(ST($i));");
        }
        elsif ($type_info->{perl} eq 'CV') {
            # Dereference to get CV* from coderef
            $b->line("if (!SvROK(ST($i)) || SvTYPE(SvRV(ST($i))) != SVt_PVCV)");
            $b->line("    croak(\"Argument $i must be a code reference\");");
            $b->line("CV* $arg_name = (CV*)SvRV(ST($i));");
        }
        else {
            # Unknown type - try to cast
            $b->line("$type_info->{c} $arg_name = ($type_info->{c})SvIV(ST($i));");
        }

        push @c_args, $arg_name;
    }

    # Call the C function
    my $ret_info = XS::JIT::Header::TypeMap::resolve($return_type);
    my $call = "$func->{c_name}(" . join(', ', @c_args) . ")";

    if ($return_type eq 'void') {
        $b->line("$call;");
        $b->xs_return_undef;
    }
    else {
        $b->line("$ret_info->{c} retval = $call;");

        if ($ret_info->{perl} eq 'IV') {
            $b->line("ST(0) = sv_2mortal(newSViv((IV)retval));");
        }
        elsif ($ret_info->{perl} eq 'UV') {
            if ($ret_info->{is_ptr}) {
                $b->line("ST(0) = sv_2mortal(newSVuv(PTR2UV(retval)));");
            }
            else {
                $b->line("ST(0) = sv_2mortal(newSVuv((UV)retval));");
            }
        }
        elsif ($ret_info->{perl} eq 'NV') {
            $b->line("ST(0) = sv_2mortal(newSVnv((NV)retval));");
        }
        elsif ($ret_info->{perl} eq 'PV') {
            $b->line("ST(0) = sv_2mortal(newSVpv(retval, 0));");
        }
        elsif ($ret_info->{perl} eq 'SV') {
            # Return SV* directly (mortalized)
            $b->line("ST(0) = sv_2mortal(retval);");
        }
        elsif ($ret_info->{perl} eq 'HV') {
            # Return HV* as hashref (mortalized)
            $b->line("ST(0) = sv_2mortal(newRV_noinc((SV*)retval));");
        }
        elsif ($ret_info->{perl} eq 'AV') {
            # Return AV* as arrayref (mortalized)
            $b->line("ST(0) = sv_2mortal(newRV_noinc((SV*)retval));");
        }
        elsif ($ret_info->{perl} eq 'CV') {
            # Return CV* as coderef (mortalized)
            $b->line("ST(0) = sv_2mortal(newRV_noinc((SV*)retval));");
        }
        else {
            $b->line("ST(0) = sv_2mortal(newSViv((IV)retval));");
        }

        $b->xs_return(1);
    }

    $b->xs_end;

    return {
        code     => $b->code,
        xs_name  => "xs_$safe_name",
    };
}

# Build compiler/linker flags
sub _build_cflags {
    my ($self) = @_;

    my @flags;

    # Include paths
    push @flags, map { "-I$_" } @{$self->{include}};

    # Header directory
    if ($self->{_header_path}) {
        my $dir = File::Spec->rel2abs(
            (File::Spec->splitpath($self->{_header_path}))[1]
        );
        push @flags, "-I$dir" if $dir;
    }

    # Defines
    push @flags, map { "-D$_=$self->{define}{$_}" } keys %{$self->{define}};

    return join(' ', @flags);
}

sub _build_ldflags {
    my ($self) = @_;

    return '' unless defined $self->{lib};

    my $lib = $self->{lib};

    # If it's a path to a .so/.dylib/.dll, use it directly
    if ($lib =~ m{[/\\]} || $lib =~ /\.(?:so|dylib|dll|a)(?:\.\d+)*$/) {
        return $lib;
    }

    # Otherwise, use -l flag
    return "-l$lib";
}

# Compile all attached functions
sub compile {
    my ($self) = @_;

    return 1 if $self->{_compiled} && !$self->{force};

    die "No functions attached" unless @{$self->{_functions}};

    # Generate the include directive
    my $code = "";

    # Add standard includes
    $code .= "#include <stdlib.h>\n";
    $code .= "#include <string.h>\n";

    # Add the user's header
    if ($self->{_header_path}) {
        $code .= qq{#include "$self->{_header_path}"\n};
    }

    $code .= "\n";

    # Generate wrapper code for each function
    my %functions;
    for my $func (@{$self->{_functions}}) {
        my $wrapper = $self->_generate_wrapper($func);
        $code .= $wrapper->{code} . "\n";

        $functions{$func->{perl_name}} = {
            source       => $wrapper->{xs_name},
            is_xs_native => 1,
        };
    }

    # Compile with XS::JIT
    # Note: We pass extra flags through environment since XS::JIT
    # doesn't currently support extra cflags/ldflags directly
    local $ENV{XS_JIT_EXTRA_CFLAGS} = $self->_build_cflags;
    local $ENV{XS_JIT_EXTRA_LDFLAGS} = $self->_build_ldflags;

    my $result = XS::JIT->compile(
        code      => $code,
        name      => $self->{_module_id},
        cache_dir => $self->{cache_dir},
        functions => \%functions,
        force     => $self->{force},
    );

    unless ($result) {
        die "XS::JIT compilation failed";
    }

    $self->{_compiled} = 1;
    return 1;
}

# Write module files without JIT compilation
# This generates static files that can be distributed and compiled normally
sub write_module {
    my ($self, %opts) = @_;

    die "No functions attached" unless @{$self->{_functions}};

    my $dir = $opts{dir} || '.';
    my $package = $opts{package} || $self->{package};

    # Create directory structure based on package name
    my @parts = split /::/, $package;
    my $module_name = pop @parts;  # Last part is the module name

    # Build directory path
    my $lib_dir = File::Spec->catdir($dir, 'lib', @parts);
    _mkpath($lib_dir);

    # File paths
    my $pm_file = File::Spec->catfile($lib_dir, "$module_name.pm");
    my $xs_file = File::Spec->catfile($lib_dir, "$module_name.xs");
    my $c_file = File::Spec->catfile($lib_dir, "${module_name}_funcs.c");

    # Generate the C code (function wrappers)
    my $c_code = $self->_generate_module_c_code();

    # Generate the XS file (boot section and function registration)
    my $xs_code = $self->_generate_module_xs_code($package, $module_name);

    # Generate the .pm file
    my $pm_code = $self->_generate_module_pm_code($package);

    # Write files
    _write_file($c_file, $c_code);
    _write_file($xs_file, $xs_code);
    _write_file($pm_file, $pm_code);

    # Mark as compiled to prevent auto-compile in DESTROY
    $self->{_compiled} = 1;

    # Return info about what was created
    return {
        c_file  => $c_file,
        xs_file => $xs_file,
        pm_file => $pm_file,
        package => $package,
    };
}

# Generate just the C code portion (for embedding or custom builds)
sub write_c_file {
    my ($self, $filename) = @_;

    die "write_c_file requires a filename" unless defined $filename;
    die "No functions attached" unless @{$self->{_functions}};

    my $code = $self->_generate_module_c_code();
    _write_file($filename, $code);

    # Mark as compiled to prevent auto-compile in DESTROY
    $self->{_compiled} = 1;

    return $self;
}

# Generate the C function wrappers
sub _generate_module_c_code {
    my ($self) = @_;

    my $code = "/* Generated by XS::JIT::Header */\n";
    $code .= "/* This file can be compiled as part of a standard XS module */\n\n";

    # Add standard includes
    $code .= "#include <stdlib.h>\n";
    $code .= "#include <string.h>\n";

    # Add the user's header
    if ($self->{_header_path}) {
        $code .= qq{#include "$self->{_header_path}"\n};
    }

    $code .= "\n";

    # Generate wrapper code for each function
    for my $func (@{$self->{_functions}}) {
        my $wrapper = $self->_generate_wrapper($func);
        $code .= $wrapper->{code} . "\n";
    }

    return $code;
}

# Generate the XS boot code
sub _generate_module_xs_code {
    my ($self, $package, $module_name) = @_;

    my $xs = <<"END_XS";
/* Generated by XS::JIT::Header */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Include the generated function wrappers */
#include "${module_name}_funcs.c"

MODULE = $package  PACKAGE = $package

PROTOTYPES: DISABLE

BOOT:
{
END_XS

    # Add newXS for each function
    for my $func (@{$self->{_functions}}) {
        my $safe_name = $func->{c_name};
        $safe_name =~ s/\W/_/g;
        my $perl_name = $func->{perl_name};

        $xs .= qq{    newXS("$perl_name", xs_$safe_name, __FILE__);\n};
    }

    $xs .= "}\n";

    return $xs;
}

# Generate the .pm file
sub _generate_module_pm_code {
    my ($self, $package) = @_;

    my $pm = <<"END_PM";
package $package;

use strict;
use warnings;

our \$VERSION = '0.01';

require XSLoader;
XSLoader::load('$package', \$VERSION);

1;

__END__

=head1 NAME

$package - Bindings generated by XS::JIT::Header

=head1 SYNOPSIS

    use $package;

    # Functions available:
END_PM

    # List the functions
    for my $func (@{$self->{_functions}}) {
        my $perl_name = $func->{perl_name};
        $perl_name =~ s/.*:://;  # Get just the function name
        my $args = join(', ', map { "\$arg$_" } 0 .. $#{$func->{arg_types}});
        $pm .= "    #   $perl_name($args)\n";
    }

    $pm .= <<"END_PM";

=head1 DESCRIPTION

This module was generated by XS::JIT::Header from the header file:
$self->{header}

=head1 FUNCTIONS

END_PM

    # Document each function
    for my $func (@{$self->{_functions}}) {
        my $perl_name = $func->{perl_name};
        $perl_name =~ s/.*:://;
        my $args = join(', ', @{$func->{arg_types}});
        $pm .= "=head2 $perl_name\n\n";
        $pm .= "    $func->{return_type} $func->{c_name}($args)\n\n";
    }

    $pm .= <<"END_PM";

=head1 LICENSE

Same as Perl itself.

=cut
END_PM

    return $pm;
}

# Helper to create directory path (handles absolute paths)
sub _mkpath {
    my ($dir) = @_;
    return if -d $dir;

    # Use File::Spec to handle path correctly
    my $is_absolute = File::Spec->file_name_is_absolute($dir);
    my @parts = File::Spec->splitdir($dir);

    my $path = '';
    for my $part (@parts) {
        # For absolute paths, first part is empty string - creates leading /
        if (!length $path) {
            $path = $part;
            $path = File::Spec->rootdir() if $is_absolute && !length $part;
        } else {
            $path = File::Spec->catdir($path, $part);
        }

        # Create directory if it doesn't exist (skip root)
        if (length($path) > 1 && !-d $path) {
            mkdir $path or die "Cannot create directory '$path': $!";
        }
    }
}

# Helper to write file
sub _write_file {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename
        or die "Cannot open '$filename' for writing: $!";
    print $fh $content;
    close $fh
        or die "Cannot close '$filename': $!";
}

# Destructor - ensure compilation happens
sub DESTROY {
    my ($self) = @_;
    # Auto-compile if functions were attached but not compiled
    if (@{$self->{_functions}} && !$self->{_compiled}) {
        eval { $self->compile };
        warn "XS::JIT::Header auto-compile failed: $@" if $@;
    }
}

1;

__END__

=head1 NAME

XS::JIT::Header - FFI-like interface for C headers using XS::JIT

=head1 SYNOPSIS

    use XS::JIT::Header;

    # Bind to math library (JIT compile at runtime)
    my $math = XS::JIT::Header->new(
        header  => 'math.h',
        package => 'FastMath',
    );

    $math->attach('sin');
    $math->attach('cos');
    $math->attach('pow');
    $math->compile;

    # Now use the functions
    my $result = FastMath::sin(3.14159);
    my $power = FastMath::pow(2, 10);  # 1024

    # Or generate static files for distribution (no JIT needed)
    my $lib = XS::JIT::Header->new(
        header  => 'mylib.h',
        package => 'My::Lib',
    );
    $lib->attach_all();
    $lib->write_module(dir => 'My-Lib');
    # Creates My-Lib/lib/My/Lib.pm, Lib.xs, Lib_funcs.c

    # Or just export the C code for embedding
    $lib->write_c_file('mylib_wrappers.c');

=head1 DESCRIPTION

XS::JIT::Header provides an FFI::Platypus-like interface for binding
C libraries through their header files, but uses XS::JIT's compilation
approach for better runtime performance (~2x faster than FFI).

The module parses C header files to extract function declarations,
generates XS wrapper code using XS::JIT::Builder, and compiles it
using XS::JIT. The compiled code is cached for subsequent runs.

=head1 METHODS

=head2 new(%options)

Creates a new XS::JIT::Header instance.

    my $h = XS::JIT::Header->new(
        header    => 'mylib.h',      # Required: path to C header
        lib       => 'mylib',        # Optional: library name or path
        include   => ['/opt/include'], # Optional: additional include paths
        define    => { DEBUG => 1 }, # Optional: preprocessor defines
        package   => 'MyLib',        # Optional: target Perl package (default: caller)
        prefix    => 'mylib_',       # Optional: prefix to strip from function names
        cache_dir => '_CACHED_XS',   # Optional: cache directory
        force     => 0,              # Optional: force recompilation
    );

=head2 attach($c_name)

=head2 attach($c_name => $perl_name)

=head2 attach($c_name => \@arg_types => $return_type)

Attach a C function to be compiled as a Perl subroutine.

    # Use same name (stripped of prefix)
    $h->attach('mylib_calculate');  # becomes MyLib::calculate

    # Use custom Perl name
    $h->attach('mylib_calculate' => 'calc');  # becomes MyLib::calc

    # Explicit type specification (overrides header parsing)
    $h->attach('custom_func' => ['int', 'double'] => 'double');

=head2 attach_all()

=head2 attach_all($filter)

Attach all functions from the parsed header.

    $h->attach_all;                  # All functions
    $h->attach_all(qr/^math_/);      # Only functions matching regex
    $h->attach_all(sub { length($_[0]) < 10 });  # Custom filter

=head2 compile()

Compile all attached functions. This is called automatically when
the object goes out of scope, but can be called explicitly for
better error handling.

    $h->compile or die "Compilation failed";

=head2 write_module(%options)

Generate a complete distributable XS module without JIT compilation.
This creates static C, XS, and PM files that can be compiled using
a standard Makefile.PL build process.

    $h->write_module(
        dir     => 'MyModule',    # Output directory (default: '.')
        package => 'My::Lib',     # Package name (default: from new())
    );

This creates:

    MyModule/
      lib/
        My/
          Lib.pm        # Perl module with XSLoader
          Lib.xs        # XS boot code
          Lib_funcs.c   # Generated function wrappers

Returns a hashref with the created file paths.

=head2 write_c_file($filename)

Write just the generated C code (function wrappers) to a file.
Useful for embedding into existing XS modules.

    $h->write_c_file('my_funcs.c');

=head2 functions()

Returns a list of function names parsed from the header.

    my @funcs = $h->functions;

=head2 function($name)

Returns detailed information about a specific function.

    my $info = $h->function('sin');
    # { name => 'sin', return_type => 'double',
    #   params => [{ type => 'double', name => 'x' }], ... }

=head2 constants()

Returns a list of constant names (from #define) parsed from the header.

    my @consts = $h->constants;

=head2 constant($name)

Returns the value of a constant.

    my $pi = $h->constant('M_PI');

=head1 TYPE MAPPING

The following C types are automatically mapped to Perl types:

    C Type              Perl Type   Conversion
    ------------------  ----------  ----------
    char, short, int    IV          SvIV/newSViv
    long, long long
    unsigned ...        UV          SvUV/newSVuv
    size_t, uint*_t
    float, double       NV          SvNV/newSVnv
    char*, const char*  PV          SvPV/newSVpv
    void                -           -
    void*, T*           UV          PTR2UV/INT2PTR

Unknown types are treated as opaque pointers (UV).

=head1 LIMITATIONS

=over 4

=item * Struct arguments are not yet supported (treated as opaque pointers)

=item * Variable argument functions (like printf) have limited support

=item * Complex preprocessor macros may not parse correctly

=back

=head1 SEE ALSO

L<XS::JIT>, L<XS::JIT::Builder>, L<FFI::Platypus>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
