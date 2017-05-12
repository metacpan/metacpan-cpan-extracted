# ex:ts=8

package WWW::Scraper::ISBN::TWBooks_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.02';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWBooks_Driver - Search driver for TWBooks' online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWBooks' online catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
#Library Modules                                                          #
###########################################################################

use WWW::Scraper::ISBN::Driver;
use WWW::Mechanize;
use Template::Extract;
use Text::Iconv;

###########################################################################
#Constants                                                                #
###########################################################################

use constant	QUERY	=> 'http://search.books.com.tw/exep/prod_search.php?cat=001&key=%s';

#--------------------------------------------------------------------------

###########################################################################
#Inheritence                                                              #
###########################################################################

@ISA = qw(WWW::Scraper::ISBN::Driver);

###########################################################################
#Interface Functions                                                      #
###########################################################################

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Books
server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn
  title
  author
  pages
  book_link
  image_link
  pubdate
  publisher
  price_list
  price_sell

The book_link and image_link refer back to the Books website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $url = sprintf(QUERY, $isbn);
	my $mechanize = WWW::Mechanize->new();
	$mechanize->get( $url );
	return undef unless($mechanize->success());

	# The Search Results page
	my $template = <<END;
<td class="cov">[% ... %]
image=[% image_link %]&width=[% ... %]
<table>
<tr>
<td>
<h3>[% title %]</h3>[% ... %]
<a href="[% ... %]prod_search_author.php[% ... %]>[% author %]/[% ... %]
<a href="[% ... %]pub_book.php[% ... %]>[% publisher %]</a>[% ... %]
<i>[% pubdate %]</i>[% ... %]
<u>[% price_list %]</u>[% ... %]
<em>[% price_sell %]</em>[% ... %]
&nbsp;/&nbsp;[% pages %]&nbsp;/&nbsp;[% ... %]
ISBN[% ... %]<i>[% isbn %]</i>
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWBooks result page.")
		unless(defined $data);

	$data->{image_link} =~ m/(\d+).jpg/;
	my $tmp = $1;

	$data->{pages} =~ s/(\d+).*/$1/;

	my $conv = Text::Iconv->new("utf-8", "big5");

	my $bk = {
		'isbn'		=> $data->{isbn},
		'title'		=> $conv->convert($data->{title}),
		'author'	=> $conv->convert($data->{author}),
		'pages'		=> $data->{pages},
		'book_link'	=> "http://www.books.com.tw/exep/prod/booksfile.php?item=$tmp",
		'image_link'	=> $data->{image_link},
		'pubdate'	=> $conv->convert($data->{pubdate}),
		'publisher'	=> $conv->convert($data->{publisher}),
		'price_list'	=> $data->{price_list},
		'price_sell'	=> $data->{price_sell},
	};

	$self->book($bk);
	$self->found(1);
	return $self->book;
}

1;
__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>,
L<Template::Extract>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 AUTHOR

Ying-Chieh Liao E<lt>ijliao@csie.nctu.edu.twE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Ying-Chieh Liao E<lt>ijliao@csie.nctu.edu.twE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
