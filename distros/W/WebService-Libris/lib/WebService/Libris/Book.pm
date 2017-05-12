package WebService::Libris::Book;
use Mojo::Base 'WebService::Libris';
use WebService::Libris::Utils qw/marc_lang_code_to_iso/;
use strict;
use warnings;
use 5.010;

__PACKAGE__->_make_text_accessor(qw/title date publisher/, ['isbn', 'isbn10']);

sub fragments {
    'bib', shift->id;
}

sub related_books { shift->list_from_dom('frbr_related') }
sub held_by       { shift->list_from_dom('held_by')      }
sub authors_obj   { shift->list_from_dom('creator')      }

sub authors_text  {
    my $self = shift;
    my @authors = grep length, map $_->text, $self->dom->find('creator')->each;
    # XXX: come up with something better
    if (wantarray) {
        return @authors;
    } elsif (@authors == 1) {
        return $authors[0]
    } else {
        return join ", ", @authors;
    }
}

sub isbns {
    my $self = shift;
    map $_->text, $self->dom->find('isbn10')->each;
}

sub authors_ids {
    my $self = shift;
    my %seen;
    my @ids = sort
              grep { !$seen{$_}++ }
              map { (split '/', $_)[-1] }
              grep $_,
              map { $_->attr('rdf:resource') }
              $self->dom->find('creator')->each;
    return @ids;
}

sub languages_marc {
    my $self = shift;

    my @l = $self->dom->find('language')->each;
    @l = grep $_, map $_->attr('rdf:resource'), @l;
    return undef unless @l;

    map { m{http://purl.org/NET/marccodes/languages/(\w{3})(?:\#lang)?} && "$1" } @l;
}

sub language_marc {
    (shift->languages_marc)[-1] // ()
}

sub languages {
    my $self = shift;
    my @langs = map marc_lang_code_to_iso($_), $self->languages_marc;
    for ($self->dom->find('*[lang]')->each) {
        my $l = $_->attr('xml:lang');
        push @langs, $l if defined $l;
    }
    @langs;
}

sub language {
    my $self = shift;
    my @langs = $self->languages;

    return undef unless @langs;
    my %c;
    ++$c{$_} for @langs;
    # just one language
    return $langs[0] if keys(%c) == 1;

    @langs = reverse sort { $c{$a} <=> $c{$b} } @langs;
    return $langs[0] if $c{$langs[0]} - $c{$langs[1]} >= 2;
    return undef;
}

=head1 NAME

WebService::Libris::Book - represents a Book in the libris.kb.se webservice

=head1 SYNOPSIS

    use WebService::Libris;
    for my $b (WebService::Libris->search(term => 'Rothfuss')) {
        # $b is a WebService::Libris::Book object here
        say $b->title;
        say $b->isbn;
    }

=head1 DESCRIPTION

C<WebService::Libris::Book> is a subclass of C<WebService::Libris> and
inherits all its methods.

All of the following methods return undef or the empty list if the information is not available.

=head1 METHODS

=head2 title

returns the title of the book

=head2 date

returns the publication date as a string (often just a year)

=head2 isbn

returns the first ISBN

=head2 isbn

returns a list of all ISBNs associated with the current book

=head2 publisher

returns the name of the publisher

=head2 related_books

returns a list of related books

=head2 held_by

returns a list of libraries that hold this book

=head2 authors_obj

returns a list of L<WebService::Libris::Author> objects which are listed
as I<creator> of this book.

=head2 authors_text

returns a list of creators of this book, as extracted from the response.
This often contains duplicates, or slightly different versions of the
same author name, so should be used with care.

=head2 language_marc

Returns the language in the three-letter "MARC" code, or undef if no such
code is found.

=head2 language

Some of the book records include a "MARC" language code (same as the
Library of Congress uses).  This methods tries to extract this code, and returns
the equivalent ISO 639 language code (two letters) if the translation is known.

It also exracts C<xml:lang> attribute from any tags found in the record.

Sometimes there are several different language specifications in a single
record.  In this case this method does an educated guess which one is correct.

=head2 languages

Return all language codes mentioned in the description of the C<language> method. No deduplication is done.


=cut

1;
