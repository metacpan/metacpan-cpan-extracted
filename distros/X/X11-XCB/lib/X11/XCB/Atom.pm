package X11::XCB::Atom;

use Mouse;
use X11::XCB::Connection;
use Carp;
use Try::Tiny;

has 'name' => (is => 'ro', isa => 'Str', required => 1, trigger => \&_request);
has 'create' => (is => 'ro', isa => 'Int', default => 0);
has 'id' => (is => 'ro', isa => 'Int', lazy_build => 1);
has '_sequence' => (is => 'rw', isa => 'Int');
has '_conn' => (is => 'ro', required => 1);
has '_id' => (is => 'rw', isa => 'Int', predicate => '_has_id');

sub _build_id {
    my $self = shift;
    my $id;

    # If we have already gotten our reply, we use it again
    if ($self->_has_id) {
        $id = $self->_id;
    } else {
        $id = $self->_conn->intern_atom_reply($self->_sequence)->{atom};
        $self->_id($id);
    }

    # None = 0 means the atom does not exist
    croak "No such atom (" . $self->name . ")" if ($id == 0);

    return $id;
}

sub _request {
    my $self = shift;

    # Place the request directly after the name is set, we get the reply later
    my $request = $self->_conn->intern_atom(
        # do not create the atom if it does not exist and not asked explicitly
        $self->create ? 0 : 1,
        length($self->name),
        $self->name
    );

    # Save the sequence to identify the response
    $self->_sequence($request->{sequence});
}

=head1 NAME

X11::XCB::Atom - wraps an X11 atom

=head1 METHODS

=head2 exists

Returns whether this atom actually exists. If the id of the atom has not been
requested before, this generates a round-trip to the x server. This is very
likely, as id() dies if the atom does not exist.

=cut
sub exists {
    my $self = shift;
    my $result = 0;

    try {
        # Try to access the ID. If this fails, the provided name was invalid
        $self->id;
        $result = 1;
    } catch {
    };

    return $result;
}

1
# vim:ts=4:sw=4:expandtab
