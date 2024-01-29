package WWW::Suffit::AuthDB::Group;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Group - WWW::Suffit::AuthDB group class

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB::Group;

=head1 DESCRIPTION

This module provides AuthDB group methods

=head2 is_valid

Check the group object

=head2 mark

Marks object as cached

=head1 ATTRIBUTES

=over 8

=item description

    $group->description('Root group');
    my $description = $group->description;

Sets and returns description of the group

=item groupname

    $group->groupname('wheel');
    my $groupname = $group->groupname;

Sets and returns groupname of the group

=item is_valid

    $group->is_valid or die "Incorrect group";

Returns boolean status of group's data

=item users

    $group->users([qw/ alice bob /]);
    my $users = $group->users; # ['alice', 'bob']

Sets and returns users of group (array of users)

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Mojo::Base -base;

has description => '';
has error       => '';
has expires     => 0;
has groupname   => undef;
has id          => 0;
has users       => sub { return [] };
has is_cached   => 0;

sub is_valid {
    my $self = shift;

    unless ($self->id) {
        $self->error("E1334: Group not found");
        return 0;
    }
    unless (defined($self->groupname) && length($self->groupname)) {
        $self->error("E1335: Incorrect groupname stored");
        return 0;
    }
    if ($self->expires && $self->expires < time) {
        $self->error("E1336: The group data is expired");
        return 0;
    }

    return 1;
}

sub mark {
    my $self = shift;
    $self->is_cached(1);
}

1;

__END__
