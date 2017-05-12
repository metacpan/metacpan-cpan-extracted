package WWW::Scraper::ISBN::Blackwell_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.09';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Blackwell_Driver - Search driver for Blackwell's online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from Blackwell's online book catalog.

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

use constant	REFERER	=> 'http://bookshop.blackwell.co.uk';
use constant	SEARCH	=> 'http://bookshop.blackwell.co.uk/jsp/search_results.jsp?wcp=1&quicksearch=1&cntType=&searchType=keywords&searchData=%s&x=10&y=10';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
Blackwell server.

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
  thumb_link
  description
  pubdate
  publisher
  binding       (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link, image_link and thumb_link all refer back to the Blackwell website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

    # validate and convert into EAN13 format
    my $ean = $self->convert_to_ean13($isbn);
    return $self->handler("Invalid ISBN specified")   
        if(!$ean || (length $isbn == 13 && $isbn ne $ean)
                 || (length $isbn == 10 && $isbn ne $self->convert_to_isbn10($ean)));

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Windows IE 6' );
    $mech->add_header( 'Accept-Encoding' => undef );

    my $search = sprintf SEARCH , $ean;
#print STDERR "\n# search=[$search]\n";

    eval { $mech->get( $search ) };
    return $self->handler("Blackwell's website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    my $html = $mech->content();

	return $self->handler("Failed to find that book on the Blackwell website. [$isbn]")
		if($html =~ m!Sorry, there are no results for!si);
    
    $html =~ s/&amp;/&/g;
    $html =~ s/&nbsp;/ /g;
#print STDERR "\n# html=[\n$html\n]\n";

    my $data;
    ($data->{isbn13})       = $html =~ m!<td width="25%"><b>ISBN13</b></td><td width="25%">([^<]+)!si;
    ($data->{isbn10})       = $html =~ m!<td width="25%"><b>ISBN</b></td><td width="25%">([^<]+)</td>!si;
    ($data->{title})        = $html =~ m!title="ISBN: $data->{isbn13} - ([^"]+)"!si;
    ($data->{author})       = $html =~ m!title="Search for other titles by this author"[^>]+>([^<]+)</a>!si;
    ($data->{binding})      = $html =~ m!<span class="product-info-label">\s*Format:\s*</span>([^<]+)<br />!si;
    ($data->{publisher})    = $html =~ m!<span class="product-info-label">\s*Publisher:\s*</span><a [^>]+>([^<]+)</a>!si;
    ($data->{pubdate})      = $html =~ m!<td width="25%"><b>Publication date</b></td><td width="25%">([^<]+)</td>!si;
    ($data->{description})  = $html =~ m{<p id="product-descr">([^<]+)}si;
    ($data->{pages})        = $html =~ m!<td width="25%"><b>Pages</b></td><td width="25%">([^<]+)</td>!si;
    ($data->{weight})       = $html =~ m!<td width="25%"><b>Weight \(grammes\)</b></td><td width="25%">([^<]+)</td>!si;
    ($data->{height})       = $html =~ m!<td width="25%"><b>Height \(mm\)</b></td><td width="25%">([^<]+)</td>!si;
    ($data->{width})        = $html =~ m!<td width="25%"><b>Width \(mm\)</b></td><td width="25%">([^<]+)</td>!si;

    ($data->{image},$data->{thumb})
                            = $html =~ m!<a href="(/images/jackets/l/\d+/\d+.jpg)" data-lightbox="multi-image"><img class="jacket".*?src="(/images/jackets/m/\d+/\d+.jpg)" /></a>!si;

    $data->{image} = REFERER . $data->{image}   if($data->{image});
    $data->{thumb} = REFERER . $data->{thumb}   if($data->{thumb});

    $data->{publisher} =~ s/&#0?39;/'/g;

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

	return $self->handler("Could not extract data from the Blackwell result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s!&nbsp;! !g;
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

    my $url = $mech->uri();

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
		'height'		=> $data->{height},
		'width'		    => $data->{width},
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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Blackwell_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
