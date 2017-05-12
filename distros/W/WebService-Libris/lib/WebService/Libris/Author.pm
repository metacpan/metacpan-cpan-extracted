package WebService::Libris::Author;
use Mojo::Base 'WebService::Libris';
use strict;
use warnings;
use 5.010;

sub fragments {
    'auth', shift->id;
}

sub _description {
    my $self = shift;
    my $url = join '/', $self->fragments;
    $self->dom->at(qq{description[about\$="$url"]}) // Mojo::DOM->new;
}

sub birthyear {
    my $d = shift->_description->at('birthyear');
    $d && $d->text
}

sub libris_key {
    my $d = shift->_description->at('key');
    $d && $d->text
}

sub same_as {
    my $self = shift;
    my $sd = $self->_description->at('sameas');
    if ($sd) {
        return $sd->attr('rdf:resource');
    }
    return;
}

sub names {
    map $_->text, shift->_description->find('name')->each;
}

sub books {
    shift->list_from_dom('description[about^="http://libris.kb.se/resource/bib/"]');
}

=head1 NAME

WebService::Libris::Author - Author objects for WebService::Libris

=head1 SYNOSPIS

    use 5.010;
    use WebService::Libris;
    my $author = WebService::Libris->new(
        type    => 'autho',
        id      => '246603',
    );
    say $author->libris_key; # main name entry in the db
    for ($author->names) {
        say "    name variant: $_";
    }
    say "    identification URL: ", $author->same_as if $author->same_as;

=head1 DESCRIPTIONO

Author objects as returned from the libris.kb.se API search.

All of the following methods can return undef or the empty list if the
information is not available.

=head1 METHODS

C<WebService::Libris::Author> inherits from L<WebService::Libris>, and thus has all of its methods.

=head2 libris_key

Returns the canonical name of the author, as stored in libris.

=head2 names

Returns a list of alternative names used for that author. Often includes
spelling variations and translations into other languages.

=head2 birthyear

Returns the birth year of the author.

=head2 same_as

Returns an URL that uniquely identifies the author. Those URLs typically
point to viaf.org or dbpedia.org

=head2 books

Returns a list of books written by this author.

=cut

1;
