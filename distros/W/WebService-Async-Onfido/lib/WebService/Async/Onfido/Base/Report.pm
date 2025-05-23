package WebService::Async::Onfido::Base::Report;

use strict;
use warnings;

use utf8;

our $VERSION = '0.007';    # VERSION

=head1 NAME

WebService::Async::Onfido::Base::Report - represents data for Onfido

=head1 DESCRIPTION

This is autogenerated from the documentation in L<https://documentation.onfido.com>.

=cut

sub new {
    my ($class, %args) = @_;
    Scalar::Util::weaken($args{onfido}) if $args{onfido};
    return bless \%args, $class;
}

=head1 METHODS
=head2 id

The unique identifier for the report.

=cut

sub id : method { return shift->{id} }

=head2 created_at

The date and time at which the report was first initiated.

=cut

sub created_at : method { return shift->{created_at} }

=head2 name

Report type string identifier.  See Report Types.

=cut

sub name : method { return shift->{name} }

=head2 href

The API endpoint to retrieve the report.

=cut

sub href : method { return shift->{href} }

=head2 status

The current state of the report in the checking process.

=cut

sub status : method { return shift->{status} }

=head2 result

The result of the report.

=cut

sub result : method { return shift->{result} }

=head2 sub_result

The sub_result of the report. It gives a more detailed result for document reports only, and will be null otherwise.

=cut

sub sub_result : method { return shift->{sub_result} }

=head2 variant

Report variant string identifier. Some reports have sub-types, which are identified by this field.  These are detailed in Report Types.

=cut

sub variant : method { return shift->{variant} }

=head2 options

Report options.  Some reports expose additional options.  These are detailed in Report Types.

=cut

sub options : method { return shift->{options} }

=head2 breakdown

The details of the report. This is specific to each type of report.

=cut

sub breakdown : method { return shift->{breakdown} }

=head2 properties

The properties associated with the report, if any.

=cut

sub properties : method { return shift->{properties} }

=head2 documents

The document ids that were processed. Only for Document Report..

=cut

sub documents : method { return shift->{documents} }

1;

__END__

=head1 AUTHOR

deriv.com C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright deriv.com 2019. Licensed under the same terms as Perl itself.

