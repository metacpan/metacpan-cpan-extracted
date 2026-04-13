#!/usr/bin/false
# ABSTRACT: Bugzilla FlagActivity object and service
# PODNAME: WebService::Bugzilla::FlagActivity

package WebService::Bugzilla::FlagActivity 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has attachment_id => (is => 'ro');
has bug_id        => (is => 'ro');
has creation_time => (is => 'ro');
has flag_id       => (is => 'ro');
has requestee     => (is => 'ro');
has setter        => (is => 'ro');
has status        => (is => 'ro');
has type          => (is => 'ro');

sub _inflate {
    my ($self, $raw_array) = @_;
    require WebService::Bugzilla::FlagActivity::Type;
    require WebService::Bugzilla::UserDetail;
    return [
        map {
            my $r = $_;
            $self->new(
                client    => $self->client,
                %{ $r },
                requestee => ($r->{requestee}
                    ? WebService::Bugzilla::UserDetail->new(%{ $r->{requestee} })
                    : undef),
                setter    => ($r->{setter}
                    ? WebService::Bugzilla::UserDetail->new(%{ $r->{setter} })
                    : undef),
                type      => ($r->{type}
                    ? WebService::Bugzilla::FlagActivity::Type->new(%{ $r->{type} })
                    : undef),
            )
        }
        @{ $raw_array // [] }
    ];
}

sub get {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('review/flag_activity'), \%params);
    return $self->_inflate($res);
}

sub get_by_flag_id {
    my ($self, $flag_id, %params) = @_;
    my $res = $self->client->get($self->_mkuri("review/flag_activity/$flag_id"), \%params);
    return $self->_inflate($res);
}

sub get_by_requestee {
    my ($self, $requestee, %params) = @_;
    my $res = $self->client->get($self->_mkuri("review/flag_activity/requestee/$requestee"), \%params);
    return $self->_inflate($res);
}

sub get_by_setter {
    my ($self, $setter, %params) = @_;
    my $res = $self->client->get($self->_mkuri("review/flag_activity/setter/$setter"), \%params);
    return $self->_inflate($res);
}

sub get_by_type_id {
    my ($self, $type_id, %params) = @_;
    my $res = $self->client->get($self->_mkuri("review/flag_activity/type_id/$type_id"), \%params);
    return $self->_inflate($res);
}

sub get_by_type_name {
    my ($self, $type_name, %params) = @_;
    my $res = $self->client->get($self->_mkuri("review/flag_activity/type_name/$type_name"), \%params);
    return $self->_inflate($res);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::FlagActivity - Bugzilla FlagActivity object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $activity = $bz->flag_activity->get;
    for my $entry (@{$activity}) {
        say $entry->type->name, ': ', $entry->status;
    }

    my $by_user = $bz->flag_activity->get_by_requestee('user@example.com');

=head1 DESCRIPTION

Provides access to the BMO flag-activity review endpoints.  FlagActivity
objects represent flag transitions (grants, denials, requests) and provide
methods to fetch and filter those entries.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<attachment_id>

Numeric ID of the attachment the flag is associated with, if any.

=item C<bug_id>

Numeric ID of the associated bug.

=item C<creation_time>

ISO 8601 datetime when the flag activity was created.

=item C<flag_id>

Numeric flag ID.

=item C<requestee>

L<WebService::Bugzilla::UserDetail> of the person the flag was requested
from, or C<undef>.

=item C<setter>

L<WebService::Bugzilla::UserDetail> of the person who set the flag.

=item C<status>

Flag status string (e.g. C<+>, C<->, C<?>).

=item C<type>

L<WebService::Bugzilla::FlagActivity::Type> describing the flag kind.

=back

=head1 METHODS

=head2 get

    my $entries = $bz->flag_activity->get(%params);

Fetch flag activity entries.  Returns an arrayref of
L<WebService::Bugzilla::FlagActivity> objects.

=head2 get_by_flag_id

    my $entries = $bz->flag_activity->get_by_flag_id($flag_id, %params);

Fetch flag activity for a specific flag ID.

=head2 get_by_requestee

    my $entries = $bz->flag_activity->get_by_requestee($login, %params);

Fetch flag activity where the given user is the requestee.

=head2 get_by_setter

    my $entries = $bz->flag_activity->get_by_setter($login, %params);

Fetch flag activity set by the given user.

=head2 get_by_type_id

    my $entries = $bz->flag_activity->get_by_type_id($type_id, %params);

Fetch flag activity for a specific flag type ID.

=head2 get_by_type_name

    my $entries = $bz->flag_activity->get_by_type_name($name, %params);

Fetch flag activity for a flag type by name (e.g. C<review>).

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::FlagActivity::Type> - flag type metadata

L<WebService::Bugzilla::UserDetail> - lightweight user objects

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
