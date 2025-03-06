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

=head1 ATTRIBUTES

This class implements the following attributes

=head2 cached

    $group = $group->cached( 12345.123456789 );
    my $cached = $group->cached;

Sets or returns time of caching group data

Default: 0

=head2 cachekey

    $group = $group->cachekey( 'abcdef1234567890' );
    my $cachekey = $group->cachekey;

Sets or returns the cache key string

=head2 description

    $group->description('Root group');
    my $description = $group->description;

Sets and returns description of the group

=head2 error

    $group = $group->error( 'Oops' );
    my $error = $group->error;

Sets or returns error string

=head2 expires

    $group = $group->expires( 300 );
    my $expires = $group->expires;

Sets or returns cache/object expiration time in seconds

Default: 300 (5 min)

=head2 groupname

    $group->groupname('wheel');
    my $groupname = $group->groupname;

Sets and returns groupname of the group

=head2 id

    $group = $group->id( 2 );
    my $id = $group->id;

Sets or returns id of group

Default: 0

=head2 is_cached

This attribute returns true if the group data was cached

Default: false

=head2 users

    $group->users([qw/ alice bob /]);
    my $users = $group->users; # ['alice', 'bob']

Sets and returns users of group (array of users)

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 is_valid

    $group->is_valid or die "Incorrect group";

Returns boolean status of group's data

=head2 mark

Marks object as cached

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base -base;

use Mojo::Util qw/steady_time/;

has description => '';
has error       => '';
has expires     => 0;
has groupname   => undef;
has id          => 0;
has users       => sub { return [] };
has is_cached   => 0; # 0 or 1
has cached      => 0; # steady_time() of cached
has cachekey    => '';

sub is_valid {
    my $self = shift;

    unless ($self->id) {
        $self->error("E1314: Group not found");
        return 0;
    }
    unless (defined($self->groupname) && length($self->groupname)) {
        $self->error("E1315: Incorrect groupname stored");
        return 0;
    }
    if ($self->expires && $self->expires < time) {
        $self->error("E1316: The group data is expired");
        return 0;
    }

    return 1;
}

sub mark {
    my $self = shift;
    return $self->is_cached(1)->cached(shift || steady_time);
}

1;

__END__
