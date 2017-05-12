package WebService::Toggl::Report::Weekly;

use Sub::Quote qw(quote_sub);
use Types::Standard qw(Enum);

use Moo;
with 'WebService::Toggl::Role::Report';
use namespace::clean;

sub api_path { 'weekly' }

around _req_params => sub {
    my $orig = shift;
    my $self = shift;
    return [ @{$self->$orig}, qw(grouping calculate) ];
};

# request params
has grouping  => (
    is      => 'ro',
    isa     => Enum[qw(users projects)],
    default => 'projects',
);
has calculate => (
    is      => 'ro',
    isa     => Enum[qw(time earnings)],
    default => 'time',
);


# repsonse params
#  **none**

has week_totals => (is => 'ro', lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{week_totals} |));

1;
__END__


=encoding utf-8

=head1 NAME

WebService::Toggl::Report::Weekly - Toggl weekly aggregated report object

=head1 SYNOPSIS

 use WebService::Toggl;
 my $toggl = WebService::Toggl->new({api_key => 'foo'});

 my $report = $toggl->weekly({
   workspace_id => 1234,
   grouping => 'projects', calculate => 'earnings',
 });

 say $report->total_billable;  # billable milliseconds
 say $report->week_totals;     # array of totals per day
 for $project (@{ $report->data }) {
   say "Project $project->{title}{project} earned "
     . "$project->{amount}[7] $project->{currency} this week.";
   for my $user ($projects->{details}) {
     say "  User $user->{title}{user} contributed "
       . "$user->{amount}[7] $user->{currency} to that total";
   }
 }

=head1 DESCRIPTION

This module is a wrapper object around the Toggl weekly report
L<described here|https://github.com/toggl/toggl_api_docs/blob/master/reports/weekly.md>.
It returns a report of either time spent or earnings grouped by either
project or user.

=head1 REQUEST ATTRIBUTES

Request attributes common to all reports are detailed in the
L<::Role::Request|WebService::Toggl::Role::Report#REQUEST-ATTRIBUTES> pod.

The C<until> attribute is ignored for the weekly report. It is always
assumed to be C<since> plus six days (for a total of seven).

=head2 grouping

Which metric to group reports by.  Must be either C<projects> or
C<users>.  Whichever is B<not> selected is used as the subgrouping
parameter.

=head2 calculate

The property to aggregate.  Must be one of C<time> or C<earnings>.

=head1 RESPONSE ATTRIBUTES

Response attributes common to all reports are detailed in the
L<::Role::Request|WebService::Toggl::Role::Report#RESPONSE-ATTRIBUTES> pod.

=head2 weekly_totals

Eight-element array ref showing aggregated totals of the L</calculate>
property for each day, with a sum total as the last element.

=head1 REPORT DATA

The C<data> attribute of a C<::Report::Weekly> object is an arrayref
of hashrefs representing the L</grouping> property.  It contains a
C<details> key with an array of hashrefs representing the subgrouping
parameter.  If the L</calculate> property is C<time>, the C<data>
attribute will contain a C<totals> key with the daily time aggregates.
If L</calculate> is C<earnings> , it will contain a C<currency> key
and an C<amounts> key with the daily aggregated earnings.  For more
details, see the L<Toggl API
docs|https://github.com/toggl/toggl_api_docs/blob/master/reports/weekly.md>.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

