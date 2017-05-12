# ex:ts=8

package WWW::Scraper::ISBN::TWSoidea_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.01';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWSoidea_Driver - Search driver for TWSoidea's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWSoidea's online catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
#Library Modules                                                          #
###########################################################################

use WWW::Scraper::ISBN::Driver;
use WWW::Mechanize;
use Template::Extract;

use Data::Dumper;

###########################################################################
#Constants                                                                #
###########################################################################

use constant	SOIDEA	=> 'http://www.soidea.com.tw/soidea/';

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

Creates a query string, then passes the appropriate form fields to the Soidea
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
  price_sell

The book_link and image_link refer back to the Soidea website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $mechanize = WWW::Mechanize->new();
	$mechanize->get(SOIDEA);

	$mechanize->submit_form(
		form_name	=> 'EinForm0',
		fields		=> {
			Type		=> 1,
			Select_option	=> 'ISBN',
			textfield	=> $isbn,
		},
	);

	# The Search Results page
	my $template = <<END;
查詢結果共[% ... %]<a href="[% book %]">
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWSoidea result page.")
		unless(defined $data);

	my $book = SOIDEA.$data->{book};
	$mechanize->get($book);

	$template = <<END;
<!--分類搜尋-->[% ... %]
<img src="[% image_link %]">[% ... %]
<b class=trr>[% title %]</b>[% ... %]
作者：[% author %]<br>[% ... %]
定價 [% price_list %]元<br>[% ... %]
優惠價 <font class=tno>[% price_sell %]</font>元[% ... %]
出版社/代理商：[% publisher %]<br>[% ... %]
出版/製造日期：[% pubdate %]<br>[% ... %]
ISBN：[% isbn %]<br>[% ... %]
END

	$data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWSoidea result page.")
		unless(defined $data);

	my $bk = {
		'isbn'		=> $data->{isbn},
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'book_link'	=> $mechanize->uri(),
		'image_link'	=> $data->{image_link},
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
