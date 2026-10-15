package oEdtk::Emailing;

use strict;
use warnings;

our $VERSION   = 2.1111;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(send_mail);

# The public e-mailing client is corporate data and now lives in oEUser::Emailing.
# This generic module is a thin delegate so callers using the old oEdtk::Emailing
# name keep working. oEUser is an optional companion distribution: it is loaded on
# demand, and a missing one fails cleanly rather than breaking the oEdtk load.
sub _delegate {
	my ( $sub, @args ) = @_;
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::Emailing; 1 };
	}
	die "oEdtk::Emailing requires the companion distribution oEUser "
		. "(oEUser::Emailing is not installed): $@"
		unless $loaded;
	return oEUser::Emailing->can($sub)->(@args);
}

sub send_mail { return _delegate( 'send_mail', @_ ) }

1;

=head1 NAME

oEdtk::Emailing - delegate to the oEUser e-mailing client

=head1 SYNOPSIS

    use oEdtk::Emailing qw(send_mail);

    send_mail( $subject, $content, $mailing );    # see oEUser::Emailing

=head1 DESCRIPTION

The public e-mailing client is corporate; it lives in C<oEUser::Emailing>. This
module keeps the old C<oEdtk::Emailing> name available to existing callers and
forwards every function to the companion distribution, which is loaded on demand.
When oEUser is not installed, the call fails with a clear message.

=head1 FUNCTIONS

=over 4

=item send_mail

Forwards to C<oEUser::Emailing::send_mail> and returns its result.

=back

=head1 AUTHOR

The oEdtk team.

=cut
