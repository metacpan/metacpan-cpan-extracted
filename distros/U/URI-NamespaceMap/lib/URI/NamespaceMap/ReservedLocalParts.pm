package URI::NamespaceMap::ReservedLocalParts;
use Moo 1.006000;
use Types::Standard qw/ArrayRef Str/;
use List::Util qw/first/;

has allowed => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [qw/allowed disallowed is_reserved/] }
);
has disallowed => (is => 'ro', isa => ArrayRef [Str], default => sub { [] });

sub is_reserved {
    my ($self, $keyword) = @_;
    return 0 if first { $_ eq $keyword } @{$self->allowed};
    return 1 if first { $_ eq $keyword } @{$self->disallowed};
    return $self->can($keyword) ? 1 : 0;
}


=head1 NAME

URI::NamespaceMap::ReservedLocalParts - Permissible local parts for NamespaceMap

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';


=head1 SYNOPSIS

    my $r = URI::NamespaceMap::ReservedLocalParts->new(disallowed => [qw/uri/]);

    say $r->is_reserved('isa'); # 1
    say $r->is_reserved('uri'); # 1
    say $r->is_reserved('foo'); # 0

=head1 DESCRIPTION

L<URI::NamespaceMap::ReservedLocalParts> is an accompanying distribution to
L<URI::NamespaceMap>. It's goal is to check for forbidden names used for local
parts.

Rather than creating a blacklist that needs to be maintained, it instantiates
a new L<Moo> object, and calls C<can> on the invocant. Using this technique, it
means that every method on every Perl object (C<isa, can, VERSION>), and Moo
objects (C<BUILD, BUILDARGS>) will be automatically black listed.

=head1 ATTRIBUTES

L<URI::NamespaceMap::ReservedLocalParts> implements the following attributes.

=head2 allowed

A whitelist of local part names. Defaults to C<allowed>, C<disallowed> and
C<is_reserved> so that when C<can> is called on the instance, it doesn't return
a false positive for other method names associated with this package.

=head2 disallowed

A blacklist of local part names. Does not have a default set, but usually
defaults to C<uri> when called from L<URI::NamespaceMap>.

=head1 METHODS

L<URI::NamespaceMap::ReservedLocalParts> implements the following methods.

=head2 is_reserved

    my $r = URI::NamespaceMap::ReservedLocalParts->new(disallowed => [qw/uri/]);

    say $r->is_reserved('isa'); # 1
    say $r->is_reserved('uri'); # 1
    say $r->is_reserved('foo'); # 0

Checks if the first argument passed is reserved or not. Returns a C<boolean>.

=head1 FURTHER DETAILS

See L<URI::NamespaceMap> for further details about authors, license, etc.

=cut

1;
