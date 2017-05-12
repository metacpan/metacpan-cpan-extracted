# ex:ts=8

package WWW::Scraper::ISBN::TWTenlong_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.01';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWTenlong_Driver - Search driver for TWTenlong's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWTenlong's online catalog.

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

use constant	TENLONG	=> 'http://www.tenlong.com.tw';

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

Creates a query string, then passes the appropriate form fields to the Tenlong
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

The book_link and image_link refer back to the Tenlong website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $mechanize = WWW::Mechanize->new();
	$mechanize->get(TENLONG);

	$mechanize->submit_form(
		form_name	=> 'BookSearchForm',
		fields		=> {
			fKeyword	=> $isbn,
		},
	);

	# The Search Results page
	my $template = <<END;
關鍵字查詢結果[% ... %]<a href="[% book %]">
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWTenlong result page.")
		unless(defined $data);

	my $book = $data->{book};
	$mechanize->get($book);

	$template = <<END;
<!-- InstanceBeginEditable name="Edit1" -->[% ... %]
<font size="4"><b>[% title %]</b>[% ... %]
&nbsp;by [% author %]</td>[% ... %]
<div align="center"><img src="[% image_link %]"[% ... %]
ISBN :[% ... %]&nbsp;[% isbn %]</td>[% ... %]
出版商 :[% ... %]&nbsp;[% publisher %]</td>[% ... %]
出版日期 :[% ... %]&nbsp;[% pubdate %]</td>[% ... %]
頁數 :[% ... %]&nbsp;[% pages %]</td>[% ... %]
定價 :[% ... %]">[% price_list %]</font>[% ... %]
售價 :[% ... %]">[% price_sell %]</font>
END

	$data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWTenlong result page.")
		unless(defined $data);

	my $bk = {
		'isbn'		=> $data->{isbn},
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'pages'		=> $data->{pages},
		'book_link'	=> TENLONG.$book,
		'image_link'	=> TENLONG."/BookSearch/".$data->{image_link},
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
