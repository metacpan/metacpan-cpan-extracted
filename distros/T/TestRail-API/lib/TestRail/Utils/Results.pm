# PODNAME: TestRail::Utils::Results
# ABSTRACT: Perform batch operations on test results, and analyze the same.

package TestRail::Utils::Results;
$TestRail::Utils::Results::VERSION = '0.039';
use strict;
use warnings;

use Carp qw{confess cluck};
use Scalar::Util qw{blessed};

use TestRail::Utils::Find;

sub bulkMarkResults {
    my ( $opts, $tr ) = @_;
    confess("TestRail handle must be provided as argument 2")
      unless blessed($tr) eq 'TestRail::API';

    my ( $cases, $run ) = TestRail::Utils::Find::getTests( $opts, $tr );
    die "No cases in TestRail to mark!\n" unless $cases;

    my ($status_id) = $tr->statusNamesToIds( $opts->{'set_status_to'} );

    @$cases = map {
        {
            'test_id'   => $_->{'id'},
            'status_id' => $status_id,
            'comment'   => $opts->{'reason'},
            'version'   => $opts->{'version'}
        }
    } @$cases;

    return $tr->bulkAddResults( $run->{'id'}, $cases );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils::Results - Perform batch operations on test results, and analyze the same.

=head1 VERSION

version 0.039

=head1 FUNCTIONS

=head2 bulkMarkResults(options,TestRail::API)

Primary routine of testrail-bulk-mark-results.
Takes same options as the aforementioned binary as a HASHREF, with the following exceptions:

=over 4

=item C<users> ARRAYREF (optional) - corresponds to --assignedto options passed

=item C<statuses> ARRAYREF (optional) - corresponds to --status options passed

=item C<set_status_to> STRING - Status to bulk-set cases to (ARGV[0])

=item C<reason> STRING (optional) - Reason to do said bulk-set, recorded as result comment (ARGV[1])

=back

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
