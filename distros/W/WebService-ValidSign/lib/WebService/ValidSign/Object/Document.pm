package WebService::ValidSign::Object::Document;
our $VERSION = '0.004';
use Moo;
extends 'WebService::ValidSign::Object';

# ABSTRACT: A ValidSign Document object
#
use Types::Standard qw(Str);

has '+type' => (required => 0);

has name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has path => (is => 'ro');

around TO_JSON => sub {
    my $orig = shift;
    my $self = shift;

    my $rv = $orig->($self, @_);
    delete $rv->{path};
    return $rv;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Document - A ValidSign Document object

=head1 VERSION

version 0.004

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
