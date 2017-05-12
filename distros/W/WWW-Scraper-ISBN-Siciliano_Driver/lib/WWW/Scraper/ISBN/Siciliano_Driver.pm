package WWW::Scraper::ISBN::Siciliano_Driver;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw( WWW::Scraper::ISBN::Driver );

use LWP;
use LWP::Simple qw(head);
use HTTP::Request::Common;

use constant SICILIANO => 'http://www.siciliano.com.br';
use constant SEARCHBR  => 'http://www.siciliano.com.br/livro.asp?tipo=10&pesquisa=5&id=';
use constant SEARCH    => 'http://www.siciliano.com.br/importado.asp?tipo=10&pesquisa=5&id=';


sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);
    
    my $book;
    $book->{isbn} = '';
    $book->{author} = '';
    $book->{title} = '';
    $book->{book_link} = '';
    $book->{image_link} = '';
    $book->{pubdate} = '';
    $book->{publisher} = '';
    $book->{price} = '';
    $book->{thumb_link} = '';
    $book->{description} = ''; #return blank
    
    my $ua = LWP::UserAgent->new();
    my $search;
    if (length($isbn) == 13) {
       $search = $isbn =~ m/^97/ ? SEARCHBR : SEARCH;
    }
    else {
       $search = $isbn =~ m/^85/ ? SEARCHBR : SEARCH;
    }
    my $res = $ua->request(GET $search . $isbn);
    my $doc_html = $res->as_string;
    
    if($doc_html =~ m{<td class="p5"><a href='((?:livro|importado).asp\?[^>]*orn=...&Tipo=2&ID=.*?)'><strong>(.+?)</strong>}igo) {
        $book->{book_link} = 'http://www.siciliano.com.br/' . $1;
        $book->{title} = $2;
        $book->{isbn} = $isbn;
        if($doc_html =~ m{<img src="(capas/.+?\....)" alt=""/>}io && $1 !~ m/default_pl/io) {
            $book->{thumb_link} = SICILIANO . "/$1";
            ($book->{image_link} = $book->{thumb_link}) =~ s/(\d+X?)p/$1/i;
            $book->{image_link} = '' unless head($book->{image_link});
        }
        ($book->{price}) = $doc_html =~ m{Por:<.*?R\$&nbsp;(.+?)<}igo;
        ($book->{pubdate}) = $doc_html =~ m{>Edi..o: (\d+)<}igo;
        ($book->{author}) = $doc_html =~ m{<strong class="azulescuro">(.+?)</strong>}igo;
        ($book->{publisher}) = $doc_html =~ m{>Editora: (.+?)<}igo;
    }
    else {
        return 0;
    }
    
    $self->found(1);
    $self->book($book);
    return $book;
}

return 1;


__END__

=head1 NAME

WWW::Scraper::ISBN::Siciliano_Driver - Search driver for Siciliano's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>).

=head1 DESCRIPTION

Searches for book information from the Siciliano's online catalog (L<http://www.siciliano.com.br>).

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Siciliano
server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

    isbn
    author
    title
    book_link
    image_link
    pubdate
    publisher
    price
    thumb_link

The book_link and image_link refer back to the Siciliano's website.

=back

=head1 REQUIRES

Requires the following modules be installed:

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<LWP::UserAgent>

=item L<HTTP::Request::Common>

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Scraper::ISBN>

=item L<WWW::Scraper::ISBN::Record>

=item L<WWW::Scraper::ISBN::Driver>

=back

=head1 AUTHOR

  Joenio Costa, <joenio@perl.org.br>
  DND/JaCotei, <http://www.jacotei.com.br>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Joenio Costa

This library is free software; you can redistribute it and/or modify
it under the same terms of GNU GPL.

=cut
