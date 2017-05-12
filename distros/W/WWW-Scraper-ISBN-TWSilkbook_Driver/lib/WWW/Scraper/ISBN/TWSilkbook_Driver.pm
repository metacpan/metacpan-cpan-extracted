# ex:ts=8

package WWW::Scraper::ISBN::TWSilkbook_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.02';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWSilkbook_Driver - Search driver for TWSilkbook' online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWSilkbook' online catalog.

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

use constant	QUERY	=> 'http://www.silkbook.com/function/Search_List_Book.asp?item=5&text=%s';

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

Creates a query string, then passes the appropriate form fields to the Silkbook
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

The book_link and image_link refer back to the Silkbook website. 

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

	# The Search Results page
	my $template = <<END;
<form name="buy_form" [% ... %]
<a HREF="[% book %]">
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWSilkbook result page.")
		unless(defined $data);

	my $book = $data->{book};
	$mechanize->get($book);

	$template = <<END;
<table BORDER="0" [% ... %]
<img src="[% image_link %]" ALT="[% title %]"[% ... %]
<div align="left">[% author %]<br>
[% publisher %]<br>[% ... %]
<br>[% pubdate %] <br>[% ... %]
<FONT FACE="Arial">[% pages %]</FONT>[% ... %]
<S>[% price_list %]</S>[% ... %]
<strong>[% ... %]<strong>[% price_sell %]</strong>
END

	$data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWSilkbook result page.")
		unless(defined $data);

	my $conv = Text::Iconv->new("utf-8", "big5");
	$data->{title} = $conv->convert($data->{title});
	$data->{author} = $conv->convert($data->{author});
	$data->{author} =~ s/^.*¡G(\S+) .*$/$1/s;
	$data->{publisher} = $conv->convert($data->{publisher});
	$data->{publisher} =~ s/^.*¡G(.*)$/$1/;
	$data->{pubdate} = $conv->convert($data->{pubdate});
	$data->{pubdate} =~ s/^.*¡G(.*)$/$1/;

	my $bk = {
		'isbn'		=> $isbn,
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'pages'		=> $data->{pages},
		'book_link'	=> $book,
		'image_link'	=> "http://www.silkbook.com".$data->{image_link},
		'pubdate'	=> $data->{pubdate},
		'publisher'	=> $data->{publisher},
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
