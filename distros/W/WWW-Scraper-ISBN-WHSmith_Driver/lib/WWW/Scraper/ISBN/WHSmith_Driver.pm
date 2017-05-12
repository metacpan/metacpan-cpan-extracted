package WWW::Scraper::ISBN::WHSmith_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.08';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::WHSmith_Driver - Search driver for the WHSmith online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the WHSmith online book catalog

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;

###########################################################################
# Constants

use constant	REFERER	=> 'http://www.whsmith.co.uk';
use constant	SEARCH	=> 'http://www.whsmith.co.uk/pws/ProductDetails.ice?ProductID=%s&keywords=%s&redirect=true';
use constant    PRODUCT => '/products/[^/]+/product/';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
WHSmith server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10        
  isbn13
  ean13         (industry name)
  author
  title
  book_link
  image_link
  description
  pubdate
  publisher
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link and image_link refer back to the WHSmith website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

    # validate and convert into EAN13 format
    my $ean = $self->convert_to_ean13($isbn);
    return $self->handler("Invalid ISBN specified [$isbn]")   
        if(!$ean || (length $isbn == 13 && $isbn ne $ean)
                 || (length $isbn == 10 && $isbn ne $self->convert_to_isbn10($ean)));

    $isbn = $ean;
#print STDERR "\n# isbn=[\n$isbn\n]\n";

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );
    $mech->add_header( 'Accept-Encoding' => undef );
    $mech->add_header( 'Referer' => REFERER );

    my $search = sprintf SEARCH, $isbn, $isbn;
#print STDERR "\n# search=[$search]\n";
    eval { $mech->get( $search ) };
    return $self->handler("the WHSmith website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

  	# The Book page
    my $html = $mech->content();
	return $self->handler("Failed to find that book on the WHSmith website. [$isbn]")
		if($html =~ m!Sorry, no products were found!si ||
           $html !~ m!</html>!si);  # sometimes the WHSmith site only sends back a small portion of the page :(

    my $url = $mech->uri();
	return $self->handler("Failed to find that book on the WHSmith website. [$isbn]")
		if($url =~ m!Error.aspx!si);

    $html =~ s/&amp;/&/g;
    $html =~ s/&#0?39;/'/g;
    $html =~ s/&nbsp;/ /g;

#print STDERR "\n# html=[\n$html\n]\n";

    my $data;
    ($data->{isbn13})           = $html =~ m!<li itemprop="ISBN13">\s*<strong>ISBN13:</strong>\s*(.*?)</li>!si;
    ($data->{isbn10})           = $html =~ m!<li itemprop="ISBN10">\s*<strong>ISBN10:</strong>\s*(.*?)</li>!si;
    ($data->{publisher})        = $html =~ m!<span class="bold ">Publisher:\s*</span><span><a href="[^"]+" style="text-decoration:underline;">([^<]+)</a></span>!si;
    ($data->{pubdate})          = $html =~ m!<li itemprop="publication date">\s*<strong>publication date:</strong>\s*(.*?)</li>!si;
    ($data->{title})            = $html =~ m!<h1 itemprop="name" id="product_title">([^<]*)</h1>!si;
    ($data->{binding})          = $html =~ m!<div id="product_title_container">.*?<em class="secondary">([^<]+)</em></div>!si;
    ($data->{binding})          = $html =~ m!<li itemprop="Format">\s*<strong>Format:</strong>\s*(.*?)</li>!si  unless($data->{binding});
    ($data->{pages})            = $html =~ m!<li itemprop="Number Of Pages">\s*<strong>Number Of Pages:</strong>\s*(.*?)</li>!si;
    ($data->{author})           = $html =~ m!<span class="secondary"><strong>By:</strong>(.*?)</span>!si;
    ($data->{image})            = $html =~ m!<meta itemprop="image" content="([^"]*)">!si;
    ($data->{description})      = $html =~ m!<meta name="description" content="([^"]*)" />!si;

    if($data->{image}) {
        $data->{thumb} = $data->{image};
        $data->{thumb} =~ s!/x?large/!/small/!;
    }

    # currently not provided
    ($data->{width})            = $html =~ m!<span class="bold ">Width:\s*</span><span>([^<]+)</span>!si;
    ($data->{height})           = $html =~ m!<span class="bold ">Height:\s*</span><span>([^<]+)</span>!si;
    ($data->{weight})           = $html =~ m!<li itemprop="weight">\s*<strong>weight:</strong>\s*(.*?)</li>!s;

    $data->{width}  = int($data->{width})   if($data->{width});
    $data->{height} = int($data->{height})  if($data->{height});
    $data->{weight} = int($data->{weight})  if($data->{weight});

    if($data->{author}) {
        $data->{author} =~ s/<[^>]*>//g;
        $data->{author} =~ s/\(author\)/ /g;
        $data->{author} =~ s/\s+/ /g;
        $data->{author} =~ s/\s+,\s+/, /g;
    }

#use Data::Dumper;
#print STDERR "\n# data=" . Dumper($data);

	return $self->handler("Could not extract data from The WHSmith result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

	my $bk = {
		'ean13'		    => $data->{isbn13},
		'isbn13'		=> $data->{isbn13},
		'isbn10'		=> $data->{isbn10},
		'isbn'			=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $url,
		'image_link'	=> $data->{image},
		'thumb_link'	=> $data->{thumb},
		'description'	=> $data->{description},
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height},
        'html'          => $html
	};

#use Data::Dumper;
#print STDERR "\n# book=".Dumper($bk);

    $self->book($bk);
	$self->found(1);
	return $self->book;
}

1;

__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-WHSmith_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2015 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
