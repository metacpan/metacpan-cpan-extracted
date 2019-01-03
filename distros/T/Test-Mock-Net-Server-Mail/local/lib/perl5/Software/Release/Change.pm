package Software::Release::Change;
{
  $Software::Release::Change::VERSION = '0.03';
}
use Moose;

# ABSTRACT: A change made in a software release.


has 'author_email' => (
    is => 'rw',
    isa => 'Str',
);


has 'author_name' => (
    is => 'rw',
    isa => 'Str',
);


has 'change_id' => (
    is => 'rw',
    isa => 'Str'
);


has 'committer_email' => (
    is => 'rw',
    isa => 'Str',
);


has 'committer_name' => (
    is => 'rw',
    isa => 'Str',
);


has 'date' => (
    is => 'rw',
    isa => 'DateTime'
);


has 'description' => (
    is => 'rw',
    isa => 'Str'
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__
=pod

=head1 NAME

Software::Release::Change - A change made in a software release.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use DateTime;
    use Software::Release::Change;

    my $change = Software::Release::Change->new(
        author_name => 'gphat',
        author_email => 'gphat@cpan.org',
        change_id => 'abc1234',
        date => DateTime->now,
        description => 'Frozzled the wozjob'
    );

=head1 DESCRIPTION

Software::Release::Change represents a single change made in a software
release.

=head1 ATTRIBUTES

=head2 author_email

The author's email address

=head2 author_name

The author's name

=head2 change_id

The id of the change.

=head2 committer_email

The committer's email address

=head2 committer_name

The committer's name

=head2 date

The date

=head2 description

The description of the change.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

