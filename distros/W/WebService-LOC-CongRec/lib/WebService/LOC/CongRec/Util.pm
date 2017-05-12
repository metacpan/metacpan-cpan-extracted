package WebService::LOC::CongRec::Util;
our $VERSION = '0.4';
use Moose;
with 'MooseX::Log::Log4perl';

=head1 DESCRIPTION

Helper methods for WebService::LOC::CongRec

=back

=head1 METHODS

=head3 getCongressFromYear(Int $year)

Get a Congress from a year

=cut

sub getCongressFromYear {
    my ($self, $year) = @_;
    return int(($year - 1789)/2 + 1);
}

=head3 getMonthNumberFromString(Str $name)

Get a numeric month from its name

=cut

sub getMonthNumberFromString {
    my ($self, $name) = @_;

    my $months = {
        'january'   => 1,
        'february'  => 2,
        'march'     => 3,
        'april'     => 4,
        'may'       => 5,
        'june'      => 6,
        'july'      => 7,
        'august'    => 8,
        'september' => 9,
        'october'   => 10,
        'november'  => 11,
        'december'  => 12,
    };
    return $months->{lc($name)};
}

1;
