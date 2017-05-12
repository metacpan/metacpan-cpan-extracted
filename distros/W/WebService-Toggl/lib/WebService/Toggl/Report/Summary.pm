package WebService::Toggl::Report::Summary;

use Types::Standard qw(Bool Enum);

use Moo;
with 'WebService::Toggl::Role::Report';
use namespace::clean;

sub api_path { 'summary' }

around _req_params => sub {
    my $orig = shift;
    my $self = shift;
    return [ @{$self->$orig}, qw(grouping subgrouping) ]; # subgrouping_ids grouped_time_entry_ids) ];
};

my @valid_groups = (
    ['projects', [qw(time_entries tasks users                 )]],
    ['clients',  [qw(time_entries tasks users projects        )]],
    ['users',    [qw(time_entries tasks       projects clients)]],
);
my %valid_groups = map {
    $_->[0] => { map {$_ => 1} @{ $_->[1] } }
} @valid_groups;
my @uniq_subgroups = do {
    my %seen;
    grep { !$seen{$_}++ }
        map { @{$_->[1]} } @valid_groups
};

# request params
has grouping    => (
    is      => 'ro',
    isa     => Enum[keys %valid_groups],
    default => 'projects',
);
has subgrouping => (
    is      => 'ro',
    isa     => Enum[@uniq_subgroups],
    default => 'tasks',
);
has subgrouping_ids        => (is => 'ro', isa => Bool, default => 0,);
has grouped_time_entry_ids => (is => 'ro', isa => Bool, default => 0,);


# repsonse params
#  **none**



1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::Report::Summary - Toggl summary report object

=head1 SYNOPSIS

 use WebService::Toggl;
 my $toggl = WebService::Toggl->new({api_key => 'foo'});

 my $report = $toggl->summary({
   workspace_id => 1234,
   grouping => 'projects', subgrouping => 'time_entries',
 });

 say $report->total_billable;  # billable milliseconds
 for $project (@{ $report->data }) {
   say "Time Entries For project $project->{title}{project}:";
   for my $item (@{ $project->{items} }) {
     say $item->{title}{time_entry} . " took "
       . ($entry->{time} / 1000) . " seconds";
   }
 }


=head1 DESCRIPTION

This module is a wrapper object around the Toggl summary report
L<described here|https://github.com/toggl/toggl_api_docs/blob/master/reports/summary.md>.
It returns a report of properties that are grouped and subgrouped
according to the specified request attributes.

=head1 REQUEST ATTRIBUTES

Request attributes common to all reports are detailed in the
L<::Role::Request|WebService::Toggl::Role::Report#REQUEST-ATTRIBUTES> pod.

=head2 grouping / subgrouping

The primary and secondary grouping properties.  Defaults to
C<projects> and C<time_entries> respectively.  The following
combinations are valid:

 +--------------------------------------------------------+
 |           |                Group                       |
 |           +--------------+--------------+--------------+
 |           | projects     | clients      | users        |
 +-----------+--------------+--------------+--------------+
 |           | time_entries | time_entries | time_entries |
 | Valid     | tasks        | tasks        | tasks        |
 | Subgroups | users        | users        |              |
 |           |              | projects     | projects     |
 |           |              |              | clients      |
 +-----------+--------------+--------------+--------------+


=head2 subgrouping_ids

Boolean that determines if an C<ids> key containing a comma-separated
list of subgroup ids will be added each group in the C<data>
key. Defaults to C<false>.

=head2 grouped_time_entry_ids

Boolean that determines if a C<time_entry_ids> key containing a
comma-separated list of time entry IDs will be added each group in the
C<data> key. Defaults to C<false>.


=head1 RESPONSE ATTRIBUTES

Response attributes common to all reports are detailed in the
L<::Role::Request|WebService::Toggl::Role::Report#RESPONSE-ATTRIBUTES> pod.

C<::Report::Summary> returns no additional response attributes.

=head1 REPORT DATA

The C<data()> attribute of a C<::Report::Summary> object is an
arrayref of grouping hashrefs.  Each group hashref will contain C<id>,
C<title>, and C<items> keys.  The C<items> key holds an arrayref of
the requested subgrouping objects. For a detailed description of the
contents of this structure, see the L<Toggl API
docs|https://github.com/toggl/toggl_api_docs/blob/master/reports/summary.md>.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut
