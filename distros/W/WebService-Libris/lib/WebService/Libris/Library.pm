package WebService::Libris::Library;
use Mojo::Base 'WebService::Libris';
use strict;
use warnings;
use 5.010;

__PACKAGE__->_make_text_accessor(qw/name lat long homepage/);

sub fragments {
    'library', shift->id;
}

=head1 NAME

WebService::Libris::Library - swedish libraries

=head1 SYNOSPIS

    use 5.010;
    use WebService::Libris;
    my $book = (WebService::Libris->search(terms => 'Astrid Lindgren'))[0];
    for my $library ($book->held_by) {
        say $library->name;
    }

=head1 DESCRIPTION

Objects of this class represent libraries. 

WebService::Libris::Library inherits all methods from from L<WebService::Libris>.

=head1 METHODS

All of the following methods return a string on succes, and undef if the
information is not available.

=head2 name

Name of the library

=head2 lat

Lattiude of the physical location of this library

=head2 long

Longitude of the physical location of this library

=head2 homepage

URL to this librarie's homepage

=cut

1;
