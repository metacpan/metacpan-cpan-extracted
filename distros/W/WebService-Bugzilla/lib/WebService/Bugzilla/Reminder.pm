#!/usr/bin/false
# ABSTRACT: Bugzilla Reminder object and service
# PODNAME: WebService::Bugzilla::Reminder

package WebService::Bugzilla::Reminder 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

sub _unwrap_key { 'reminders' }

has bug_id      => (is => 'ro', lazy => 1, builder => '_build_bug_id');
has creation_ts => (is => 'ro', lazy => 1, builder => '_build_creation_ts');
has note        => (is => 'ro', lazy => 1, builder => '_build_note');
has reminder_ts => (is => 'ro', lazy => 1, builder => '_build_reminder_ts');
has sent        => (is => 'ro', lazy => 1, builder => '_build_sent');

my @attrs = qw(
    bug_id
    creation_ts
    note
    reminder_ts
    sent
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            $self->_fetch_full($self->_mkuri('reminder/' . $self->id));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('reminder'), \%params);
    return $self->new(
        client => $self->client,
        _data  => $res,
    );
}

sub get {
    my ($self, $id) = @_;
    my $res = $self->client->get($self->_mkuri("reminder/$id"));
    return $self->new(
        client => $self->client,
        _data  => $res,
    );
}

sub remove {
    my ($self) = @_;
    return $self->client->delete($self->_mkuri('reminder/' . $self->id));
}

sub search {
    my ($self) = @_;
    my $res = $self->client->get($self->_mkuri('reminder'));
    return [
        map {
            $self->new(
                client => $self->client,
                _data  => $_
            )
        }
        @{ $res->{reminders} // [] }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Reminder - Bugzilla Reminder object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $reminders = $bz->reminder->search;
    for my $r (@{$reminders}) {
        say $r->note, ' (fires ', $r->reminder_ts, ')';
    }

    $bz->reminder->create(
        bug_id      => 12345,
        note        => 'Follow up on review',
        reminder_ts => '2025-07-01T09:00:00Z',
    );

=head1 DESCRIPTION

Provides access to the Bugzilla reminder endpoints.  Reminder objects
represent reminders set on bugs and provide helpers to create, fetch,
search, and remove reminders.

=head1 ATTRIBUTES

All attributes are read-only and lazy.  Each is populated on first access
by fetching the full reminder from the server.

=over 4

=item C<bug_id>

Numeric ID of the bug the reminder belongs to.

=item C<creation_ts>

ISO 8601 datetime when the reminder was created.

=item C<note>

Free-text note for the reminder.

=item C<reminder_ts>

ISO 8601 datetime when the reminder should fire.

=item C<sent>

Boolean.  Whether the reminder notification has already been sent.

=back

=head1 METHODS

=head2 create

    my $r = $bz->reminder->create(%params);

Create a new reminder.

=head2 get

    my $r = $bz->reminder->get($id);

Fetch a single reminder by its numeric ID.

Returns a L<WebService::Bugzilla::Reminder>, or C<undef> if not found.

=head2 remove

    $reminder->remove;

Delete the current reminder.

=head2 search

    my $reminders = $bz->reminder->search;

Fetch all reminders for the authenticated user.

Returns an arrayref of L<WebService::Bugzilla::Reminder> objects.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Bug> - bug objects

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
