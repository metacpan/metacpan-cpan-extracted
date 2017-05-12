package Time::Concise;
# $Id: Concise.pm,v 1.1 2004/01/05 20:35:42 cwest Exp $
use strict;

require Exporter;

use vars qw[$VERSION @ISA @EXPORT %CONVERT @CONVERT $CONVERT];
$VERSION  = (qw$Revision: 1.1 $)[1];
@ISA      = qw[Exporter];
@EXPORT   = qw[to_concise from_concise];

=head1 NAME

Time::Concise - Convert to and from concise duration formats.

=head1 SYNOPSIS

  use Time::Concise;
  my $seconds = from_concise "5y4d3h2m1s"; # 158141171
  my $concise =   to_concise 158141171;    # 5y4d3h2m1s

=head1 DESCRIPTION

B<Time::Concise> exports two functions by default, C<from_concise> and
C<to_concise>.

The term I<concise> was borrowed from L<Time::Duration|Time::Duration>.

=head2 Concise Format

The format is an integer followed immediatley by its duration
identifier.  White-space will be ignored.

The following table explains the format.

  identifier   duration
  ----------   --------
           y   year
           d   day
           h   hour
           m   minute
           s   second

=cut

@CONVERT  = qw[y d h m s];
$CONVERT  = join '', @CONVERT;
%CONVERT  = (
             y => 31_556_930,
             d => 86_400,
             h => 3_600,
             m => 60,
             s => 1,
            );

=head2 Functions

=over 8

=item to_concise I<$seconds>

This function requires one argument, an integer number of seconds, and
returns a concise string representation of the duration.

If the input is not an integer this function returns C<undef>.

=cut

sub to_concise($;) {
    my ($seconds) = @_;
    return undef if $seconds =~ /\D/;
    my $string = '';
    foreach my $type ( @CONVERT ) {
        my $leftover = $seconds % $CONVERT{$type};
        my $amount   = ( $seconds - $leftover ) / $CONVERT{$type};
        $string .= "$amount$type" if $amount;
        $seconds = $leftover;
    }
    return $string;
}

=item from_concise I<$concise>

This function requires one argument, a concise string representation
of the duration, and returns the number of seconds in the duration.

If the concise string contains characters outside those represented
in a concise duration string this function will return C<undef>.

=cut

sub from_concise($;) {
    my ($string) = @_;
    return undef if $string =~ /[^${CONVERT}0-9 ]/o;
    my $seconds = 0;
    foreach my $type ( @CONVERT ) {
        if ( my ($amount) = ( $string =~ /(\d+)$type/ ) ) {
            $seconds += $amount * $CONVERT{$type};
        }
    }
    return $seconds;
}

=pod

=back

=cut

1;

__END__

=head1 SEE ALSO

L<Time::Duration>, L<Time::Seconds>, L<perl>.

=head1 AUTHOR

Casey West, E<lt>casey@geeknest.comE<gt>.

=head1 COPYRIGHT

Copyright (c) 2004 Casey West.  All rights reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
