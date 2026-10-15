package oEdtk::Ext;

# Extension points without a registry (docs/integration/PLAN.md, step S23,
# decision D18). Two ways for a deployment to plug corporate code into
# the generic oEdtk without oEdtk depending on oEUser:
#
#   (a) an optional companion module with a fixed name (oEUser::Lib,
#       oEUser::Schema), loaded on demand and simply absent otherwise;
#   (b) a callable named in the configuration (EDTK_ACQUIT_API), resolved to a
#       "Module::function" name, validated by a regular expression, and loaded
#       explicitly.
#
# In both cases a missing extension is a documented default, not an error; an
# invalid name is an explicit error. This module has no oEUser or corporate reference.

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw( call_named_callable load_named_callable require_optional );

our $VERSION = 2.1111;

use Carp qw(croak);
use Readonly;

# A qualified Perl name: "Module::function" (at least one "::"), each part a valid
# identifier.
Readonly my $NAMED_CALLABLE_RE => qr{\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z};

# A bare module name (a leading identifier followed by optional "::" parts).
Readonly my $MODULE_RE => qr{\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z};

# Load an optional companion module by its fixed name. Return 1 on success and 0
# when it is simply not installed; a syntactically invalid name is an error. The
# caller treats 0 as the documented default (extension absent).
sub require_optional ($module) {
	croak "oEdtk::Ext: invalid module name '$module'"
		unless defined $module && $module =~ $MODULE_RE;

	# A variable require does not translate "::" to "/", so do it explicitly. A
	# dynamic name can only be required as a string.
	( my $file = $module ) =~ s{::}{/}g;

	# A die caught by eval still fires a global $SIG{__DIE__} handler, which oEdtk
	# installs (oEdtk::Tracking, at BEGIN) and which would leak the probe's
	# "Can't locate ..." message. Silence it for the probe: an absent optional
	# companion must leave no trace.
	my $loaded;
	{
		local $SIG{__DIE__};                         # a caught die must not reach a global handler
		$loaded = eval { require "$file.pm"; 1 };    ## no critic (Modules::RequireBarewordIncludes)
	}
	return $loaded ? 1 : 0;
}

# Resolve a "Module::function" name read from configuration under $key.
#   absent or empty value    -> undef (documented default: the caller does nothing)
#   syntactically invalid    -> croak
#   valid but not resolvable -> croak (a named extension must be present)
# Return the coderef.
sub load_named_callable ( $cfg, $key ) {
	my $name = $cfg->{$key};
	return unless defined $name && length $name;
	croak "oEdtk::Ext: configuration '$key' = '$name' is not a valid Module::function name"
		unless $name =~ $NAMED_CALLABLE_RE && $name =~ /::/;

	my ( $module, $func ) = $name =~ m{\A(.+)::([^:]+)\z};
	croak
"oEdtk::Ext: configuration '$key' = '$name' names the module '$module', which is not installed"
		unless require_optional($module);

	my $code = $module->can($func);
	croak "oEdtk::Ext: configuration '$key' = '$name' names the function "
		. "'$func', which the module '$module' does not provide"
		unless $code;
	return $code;
}

# Resolve and call the configured callable with @args. Return undef when the
# configuration key is absent (documented default: no call).
sub call_named_callable ( $cfg, $key, @args ) {
	my $code = load_named_callable( $cfg, $key );
	return unless $code;
	return $code->(@args);
}

1;

=head1 NAME

oEdtk::Ext - plug corporate extensions into the generic oEdtk without a registry

=head1 SYNOPSIS

    use oEdtk::Ext qw(require_optional load_named_callable call_named_callable);

    # (a) optional companion module, by its fixed name
    if ( require_optional('oEUser::Schema') ) {
        my @tables = oEUser::Schema::extra_tables();
    }

    # (b) callable named in the configuration
    my $code = load_named_callable( $cfg, 'EDTK_ACQUIT_API' );    # undef if absent
    call_named_callable( $cfg, 'EDTK_ACQUIT_API', $docid, $date );

=head1 DESCRIPTION

Two extension points that let a deployment add corporate behaviour to the
generic C<oEdtk> without C<oEdtk> depending on the companion distribution
C<oEUser> (decision D18):

=over 4

=item *

C<require_optional> loads a companion module with a fixed name (for example
C<oEUser::Lib> or C<oEUser::Schema>) and returns 1 on success, 0 when it is not
installed. A missing extension is a documented default, not an error.

=item *

C<load_named_callable> resolves a C<Module::function> name read from the
configuration (for example C<EDTK_ACQUIT_API>) and returns the coderef. The name
is validated by a regular expression before any load. An absent or empty value
returns C<undef> (the caller then does nothing); a syntactically invalid name,
or a valid name that cannot be resolved, is an explicit error.
C<call_named_callable> resolves and calls in one step.

=back

The configuration file is trusted administration data: a name that passes the
regular expression is required explicitly, and the loaded module is responsible
for its own behaviour.

=head1 AUTHOR

The oEdtk team.

=cut
