package Text::TOC::Filter::Anon;
{
  $Text::TOC::Filter::Anon::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use Text::TOC::Types qw( CodeRef );

use Moose;

with 'Text::TOC::Role::Filter';

has _code => (
    is       => 'ro',
    isa      => CodeRef,
    init_arg => 'code',
    required => 1,
);

sub node_is_interesting {
    my $self = shift;
    my $node = shift;

    return $self->_code()->($node);
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Node filter wrapper for subroutine references



__END__
=pod

=head1 NAME

Text::TOC::Filter::Anon - Node filter wrapper for subroutine references

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  my $filter = Text::TOC::Filter::Anon->new( code => sub {...} );

  if ( $filter->node_is_interesting($node) ) {...}

=head1 DESCRIPTION

This class wraps a subroutine reference with the Filter role API.

=for Pod::Coverage node_is_interesting

=head1 METHODS

This class provides the following methods:

=head2 Text::TOC::Filter::Anon->new()

This method accepts one parameter, C<code>, which must be a subroutine
reference. That subroutine will be called with a single argument, some sort of
node object. The specific type of object will depend on the type of source
document being examined.

=head1 ROLES

This class implements the L<Text::TOC::Role::Filter> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

