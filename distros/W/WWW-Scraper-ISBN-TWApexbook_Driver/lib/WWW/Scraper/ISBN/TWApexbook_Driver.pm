# ex:ts=8

package WWW::Scraper::ISBN::TWApexbook_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.02';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWApexbook_Driver - Search driver for TWApexbook's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWApexbook's online catalog.

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

use constant	QUERY	=> 'http://www.apexbook.com.tw/index.php?php_mode=search&isbn=%s';

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

Creates a query string, then passes the appropriate form fields to the Apexbook 
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
  price_sell

The book_link and image_link refer back to the Apexbook website. 

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
<FORM METHOD=POST ACTION="cart.php?php_mode=additem&view_id[% ... %]
<img src="[% image_link %]" [% ... %]
title="[% title %]">[% ... %]
作者：[% author %]">[% ... %]
ISBN：[% isbn %]">[% ... %]
出版商:[% publisher %]">[% ... %]
出版日期:[% pubdate %]">[% ... %]
售價：[% price_sell %]"><br>	
END

	my $extract = Template::Extract->new;
	my $content = Text::Iconv->new("utf-8", "big5")->convert($mechanize->content());
	my $data = $extract->extract($template, $content);

	return $self->handler("Could not extract data from TWApexbook result page.")
		unless(defined $data);

	my $bk = {
		'isbn'		=> $data->{isbn},
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'book_link'	=> $url,
		'image_link'	=> "http://www.apexbook.com.tw/bookcovers/Covers/$isbn.jpg",
		'pubdate'	=> $data->{pubdate},
		'publisher'	=> $data->{publisher},
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
