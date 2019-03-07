package WebService::ValidSign::Object::Ceremony;
our $VERSION = '0.001';
use Moo;
extends 'WebService::ValidSign::Object';

# ABSTRACT: A ceremony object

use Types::Standard qw(Bool);

has '+type' => ( required => 0 );

has in_person => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

around TO_JSON => sub {
    my $orig = shift;
    my $self = shift;
    my $rv = $orig->($self, @_);
    $rv->{inPerson} = delete $rv->{in_person};
    return $rv;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Ceremony - A ceremony object

=head1 VERSION

version 0.001

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
