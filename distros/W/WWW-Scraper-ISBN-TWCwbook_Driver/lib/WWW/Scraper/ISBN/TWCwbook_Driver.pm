# ex:ts=8

package WWW::Scraper::ISBN::TWCwbook_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.02';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWCwbook_Driver - Search driver for TWCwbook's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWCwbook's online catalog.

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

use constant	QUERY	=> "http://www.cwbook.com.tw/search/result1.jsp?field=2&keyWord=%s";

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

Creates a query string, then passes the appropriate form fields to the Cwbook 
server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn
  title
  author
  book_link
  image_link
  pubdate
  publisher
  price_list

The book_link and image_link refer back to the Cwbook website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $url = sprintf(QUERY, $isbn);
	my $mechanize = WWW::Mechanize->new();
	$mechanize->get($url);
	return undef unless($mechanize->success());

	my $template = <<END;
<input type="checkbox" name="productID" value="[% bookid %]">
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWCwbook result page.")
		unless(defined $data);

	$url = "http://www.cwbook.com.tw/common/book.jsp?productID=$data->{bookid}";
	$mechanize->get($url);
	return undef unless($mechanize->success());

	$template = <<END;
<div id="main" class="product">[% ... %]
<h2>[% title %]</h2>[% ... %]
<div class="block"><img src="[% image_link %]" ></div>[% ... %]
<li class="author">[% author %]</li>[% ... %]
<li class="publisher">[% publisher %]</li>[% ... %]
<li class="pubdate">[% pubdate %]</li>[% ... %]
<li class="price1">[% price_list %]</li>
END

	$data = $extract->extract($template, $mechanize->content());
	return $self->handler("Could not extract data from TWCwbook result page.")
		unless(defined $data);

	my $conv = Text::Iconv->new("utf-8", "big5");
	$data->{title} = $conv->convert($data->{title});
	$data->{title} =~ s/[ \r\t]//g;
	$data->{author} = $conv->convert($data->{author});
	$data->{author} =~ s/作者：(.*)/$1/;
	$data->{publisher} = $conv->convert($data->{publisher});
	$data->{publisher} =~ s/出版社：(.*)/$1/;
	$data->{pubdate} =~ s/\D*(\d+\/\d+\/\d+).*/$1/;
	$data->{price_list} =~ s/\D+(\d+).*/$1/;

	my $bk = {
		'isbn'		=> $isbn,
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'book_link'	=> $url,
		'image_link'	=> "http://www.cwbook.com.tw".$data->{image_link},
		'pubdate'	=> $data->{pubdate},
		'publisher'	=> $data->{publisher},
		'price_list'	=> $data->{price_list},
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
