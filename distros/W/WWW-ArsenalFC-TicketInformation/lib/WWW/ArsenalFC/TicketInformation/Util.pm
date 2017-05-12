use strict;
use warnings;

package WWW::ArsenalFC::TicketInformation::Util;
{
  $WWW::ArsenalFC::TicketInformation::Util::VERSION = '1.123160';
}

# ABSTRACT: Utility methods

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(month_to_number);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my %mon2num = qw(
  jan 01  feb 02  mar 03  apr 04  may 05  jun 06
  jul 07  aug 08  sep 09  oct 10 nov 11 dec 12
);

sub month_to_number {
    my ($month) = @_;

    return $mon2num{ lc( substr( $month, 0, 3 ) ) };
}

1;


__END__
=pod

=head1 NAME

WWW::ArsenalFC::TicketInformation::Util - Utility methods

=head1 VERSION

version 1.123160

=head1 METHODS

=head2 month_to_number($month)

Convert the month name to the month number.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

