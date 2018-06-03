# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AccountUpdaterDailyReport;
$WebService::Braintree::_::AccountUpdaterDailyReport::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AccountUpdaterDailyReport

=head1 PURPOSE

This class represents an account updater daily report.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 report_date()

This is the date for this report.

=cut

# Coerce to DateTime
has report_date => (
    is => 'ro',
);

=head2 report_url()

This is the URL for this report.

=cut

has report_url => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
