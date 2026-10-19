package oEdtk::DisseminationPlan;

use strict;
use warnings;

our $VERSION   = 2.1126;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(idx1_app_idlot idx1_line call_plan);

# The dissemination-plan client is corporate data and now lives in
# oEUser::DisseminationPlan. This generic module is a thin delegate so callers
# using the old oEdtk::DisseminationPlan name keep working. oEUser is an optional
# companion distribution: it is loaded on demand, and a missing one fails cleanly
# rather than breaking the oEdtk load.
sub _delegate {
	my ( $sub, @args ) = @_;
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::DisseminationPlan; 1 };
	}
	die "oEdtk::DisseminationPlan requires the companion distribution oEUser "
		. "(oEUser::DisseminationPlan is not installed): $@"
		unless $loaded;
	return oEUser::DisseminationPlan->can($sub)->(@args);
}

sub idx1_app_idlot   { return _delegate( 'idx1_app_idlot',   @_ ) }
sub idx1_line        { return _delegate( 'idx1_line',        @_ ) }
sub call_plan        { return _delegate( 'call_plan',        @_ ) }
sub my_ua            { return _delegate( 'my_ua',            @_ ) }
sub run_http_request { return _delegate( 'run_http_request', @_ ) }

1;

=head1 NAME

oEdtk::DisseminationPlan - delegate to the oEUser dissemination-plan client

=head1 SYNOPSIS

    use oEdtk::DisseminationPlan qw(idx1_app_idlot);

    idx1_app_idlot( $cfg, $app, $id_lot, $forcedpaper );    # see oEUser::DisseminationPlan

=head1 DESCRIPTION

The dissemination-plan client is corporate; it lives in
C<oEUser::DisseminationPlan>. This module keeps the old
C<oEdtk::DisseminationPlan> name available to existing callers and forwards every
function to the companion distribution, which is loaded on demand. When oEUser is
not installed, the call fails with a clear message.

=head1 FUNCTIONS

Every function below forwards its arguments to the same-named function in
C<oEUser::DisseminationPlan> and returns its result:

=over 4

=item idx1_app_idlot

=item idx1_line

=item call_plan

=item my_ua

=item run_http_request

=back

=head1 AUTHOR

The oEdtk team.

=cut
