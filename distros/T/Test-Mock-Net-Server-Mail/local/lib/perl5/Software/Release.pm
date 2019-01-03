package Software::Release;
{
  $Software::Release::VERSION = '0.03';
}
use Moose;

# ABSTRACT: Object representing a release of software.


has changes => (
    traits => [ 'Array' ],
    is => 'rw',
    isa => 'ArrayRef[Software::Release::Change]',
    default => sub { [] },
    handles => {
        add_to_changes => 'push',
        has_no_changes => 'is_empty'
    }
);


has date => (
    is => 'rw',
    isa => 'DateTime'
);


has name => (
    is => 'rw',
    isa => 'Str'
);


has version => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Software::Release - Object representing a release of software.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use DateTime;
    use Software::Release;
    use Software::Release::Change;

    my $change = Software::Release::Change->new(
        author => 'gphat',
        change_id => 'abc1234',
        date => DateTime->now,
        description => 'Frozzled the wozjob'
    );

    my $rel = Software::Release->new(
        version => '0.1',
        name => 'Angry Anteater',
        date => DateTime->now,
    );

    $rel->add_to_changes($change);

=head1 DESCRIPTION

Software::Release is a purely informational collection of objects that you
can use to represent a release of software.  Its original use-case was to
provide a contract between a git log parser and a formatter class that outputs
a changelog, but it may be useful to others to create bug trackers, dashboards
or whathaveyou.

=head1 ATTRIBUTES

=head2 changes

A list of L<Software::Release::Change> objects for this release.

=head2 date

The date this software was released.

=head2 name

The name of this release.

=head2 version

The version of the release, as a string.

=head1 METHODS

=head2 add_to_changes ($change)

Add a change to this release's list of changes.

=head2 has_no_changes

Returns true if this release's list of changes is empty.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

