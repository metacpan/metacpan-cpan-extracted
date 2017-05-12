package WebService::Lucene::Iterator;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use WebService::Lucene::Document;

__PACKAGE__->mk_accessors( qw( iterator ) );

=head1 NAME

WebService::Lucene::Iterator - Iterator for lazy document inflation

=head1 SYNOPSIS

    use WebService::Lucene::Iterator;
    
    my $iterator = WebService::Lucene::Iterator->new( $documents );

=head1 DESCRIPTION

All search results are returned as L<XML::Atom::Entry> objects
which get inflated to L<WebService::Lucene::Document> objects.
This module allows us to delay that inflation as late as possible.

=head1 METHODS

=head2 new( $documents )

Generates a new iterator that will iterate through
C<$documents> as requested.

=cut

sub new {
    my ( $class, $documents ) = @_;

    my $self  = $class->SUPER::new;
    my $index = 0;

    $self->iterator(
        sub {
            my $document = $documents->[ $index ];
            return undef unless $document;
            $index++;
            return WebService::Lucene::Document->new_from_entry( $document );
        }
    );

    return $self;
}

=head2 iterator( [$iterator] )

Accessor for the iterator closure.

=head2 next( )

Inflates and returns the next document object.

=cut

sub next {
    return shift->iterator->();
}

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>brian.cassidy@nald.caE<gt>

=item * Adam Paynter E<lt>adam.paynter@nald.caE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
