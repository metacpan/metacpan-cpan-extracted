package Travel::Routing::DE::HAFAS::Utils;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.014;

use parent 'Exporter';
our @EXPORT = qw(handle_day_change);

sub handle_day_change {
	my (%opt)       = @_;
	my $datestr     = $opt{date};
	my $timestr     = $opt{time};
	my $offset_days = 0;

	# timestr may include a day offset, resulting in DDHHMMSS
	if ( length($timestr) == 8 ) {
		$offset_days = substr( $timestr, 0, 2, q{} );
	}

	my $ts = $opt{strp_obj}->parse_datetime("${datestr}T${timestr}");

	if ($offset_days) {
		$ts->add( days => $offset_days );
	}

	return $ts;
}

1;

__END__

=head1 NAME

Travel::Routing::DE::HAFAS::Utils - Internal Travel::Routing::DE::HAFAS utilities

=head1 SYNOPSIS

None.

=head1 VERSION

version 0.04

=head1 METHODS

This methods are not meant to be called externally.

=over

=item handle_day_change(I<%opt>)

Use B<strp_obj> to parse HAFAS-provided B<date> and B<time> and handle a day
change (encoded by prefixing B<time> with two additional digits) if necessary.
Returns a DateTime(3pm) object.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

None.

=head1 AUTHOR

Copyright (C) 2023 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This program is licensed under the same terms as Perl itself.
