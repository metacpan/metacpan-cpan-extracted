package oEdtk::Constants;

use strict;
use warnings;

our $VERSION   = 2.1111;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(check_typdoc init populate trim_array trim_scalar);

# The document-type typology is corporate data and now lives in
# oEUser::Constants. This generic module is a thin delegate so callers using the
# old oEdtk::Constants name keep working. oEUser is an optional companion
# distribution: it is loaded on demand, and a missing one fails cleanly rather
# than breaking the oEdtk load.
sub _delegate {
	my ( $sub, @args ) = @_;
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::Constants; 1 };
	}
	die "oEdtk::Constants requires the companion distribution oEUser "
		. "(oEUser::Constants is not installed): $@"
		unless $loaded;
	return oEUser::Constants->can($sub)->(@args);
}

sub check_typdoc { return _delegate( 'check_typdoc', @_ ) }
sub init         { return _delegate( 'init',         @_ ) }
sub populate     { return _delegate( 'populate',     @_ ) }
sub trim_array   { return _delegate( 'trim_array',   @_ ) }
sub trim_scalar  { return _delegate( 'trim_scalar',  @_ ) }

1;

=head1 NAME

oEdtk::Constants - delegate to the oEUser document-type typology

=head1 SYNOPSIS

    use oEdtk::Constants qw(check_typdoc);

    my $code = check_typdoc('CEQU');    # see oEUser::Constants

=head1 DESCRIPTION

The document-type typology is corporate data; it lives in C<oEUser::Constants>.
This module keeps the old C<oEdtk::Constants> name available to existing callers
and forwards every function to the companion distribution, which is loaded on
demand. When oEUser is not installed, the call fails with a clear message.

=head1 FUNCTIONS

Every function below forwards its arguments to the same-named function in
C<oEUser::Constants> and returns its result:

=over 4

=item check_typdoc

=item init

=item populate

=item trim_array

=item trim_scalar

=back

=head1 AUTHOR

The oEdtk team.

=cut
