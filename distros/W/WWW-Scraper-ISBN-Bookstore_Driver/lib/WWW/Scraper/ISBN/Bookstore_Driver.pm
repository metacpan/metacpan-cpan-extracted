package WWW::Scraper::ISBN::Bookstore_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.04';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Bookstore_Driver - Search driver for The Bookstore online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from Bookstore online book catalog

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

use constant    SEARCH  => 'http://www.bookstore.co.uk/TBP.Direct/PurchaseProduct/OrderProduct/CustomerSelectProduct/SearchProducts.aspx?d=bookstore&s=C&r=10000046&ui=0&bc=0&productGroupId=&keywordSearch=';
use constant    PRODUCT => 'http://www.bookstore.co.uk';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
Bookstore server.

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
  pages         (if known)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)
  depth         (if known) (in millimetres)

The book_link and image_link refer back to the Bookstore website.

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
        unless($ean);

#print STDERR "\n# isbn=[$isbn] => ean=[$ean]\n";
    $isbn = $ean;

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

#print STDERR "\n# url=[".(SEARCH . $isbn)."]\n";

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("The Bookstore website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    # The Results page
    my $html = $mech->content();
#print STDERR "\n# html=[\n$html\n]\n";

    my ($link) = $html =~ m!<div class="hcrpdprsTitle">\s*<a.*?href="([^"]+)"!;

#print STDERR "\n# link=[".(PRODUCT . $link)."]\n";

    return $self->handler("Failed to find that book on The Bookstore website. [$isbn]")
        unless($link);

    eval { $mech->get( PRODUCT . $link ) };
    return $self->handler("The Bookstore website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    # The Book page
    $html = $mech->content();

    return $self->handler("Failed to find that book on The Bookstore website. [$isbn]")
        if($html =~ m!Sorry, we couldn't find any matches for!si);
    
#print STDERR "\n# html=[\n$html\n]\n";

    my $data;

    ($data->{isbn13})       = $html =~ m!<td class='fullProductDetailDetailsPrompt'>ISBN/Cat.No</td>\s*<td class='fullProductDetailDetailsValue'>\s*(\d+)[^<]*</td>!si;
    ($data->{isbn10})       = $html =~ m!<td class='fullProductDetailDetailsPrompt'>ISBN-10</td>\s*<td class='fullProductDetailDetailsValue'>\s*(\d+)[^<]*</td>!si;
    ($data->{title})        = $html =~ m!<td class='fullProductDetailDetailsPrompt'>Title</td>\s*<td class='fullProductDetailDetailsValue'>([^<]+)</td>!si;
    ($data->{author})       = $html =~ m!<td class='fullProductDetailDetailsPrompt'>Author/Artist</td>\s*<td class='fullProductDetailDetailsValue'>([^<]+)</td>!si;
    ($data->{publisher})    = $html =~ m!<td class='fullProductDetailDetailsPrompt'>Publisher</td>\s*<td class='fullProductDetailDetailsValue'>([^<]+)</td>!si;
    ($data->{pubdate})      = $html =~ m!<td class='fullProductDetailDetailsPrompt'>Publication Date</td>\s*<td class='fullProductDetailDetailsValue'>([^<]+)</td>!si;
    ($data->{format})       = $html =~ m!<td class='fullProductDetailDetailsPrompt'>Format</td>\s*<td class='fullProductDetailDetailsValue'>([^<]+)</td>!si;
    ($data->{description})  = $html =~ m!<td class='fullProductDetailDetailsPrompt'[^>]*>\s*Summary\s*</td></tr>.*?<tr><td class='fullProductDetailDetailsValue'[^>]*>([^<]+)</td>!si;

    ($data->{image})        = $html =~ m!<img src="(http://www.tbpcontrol.co.uk/[^"]+)" id="isbn$ean"!si;
    ($data->{thumb})        = $data->{image};

    ($data->{binding},$data->{height},$data->{width},$data->{depth},$data->{pages})
                            = $data->{format} =~ m!([^;]+);\s*H:(\d+);\s*W:(\d+);\s*D:(\d+);\s*(\d+)p\.!si;

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

    return $self->handler("Could not extract data from Bookstore result page.")
        unless(defined $data);

    # trim top and tail
    foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    my $bk = {
        'ean13'         => $data->{isbn13},
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
        'book_link'     => $mech->uri(),
        'image_link'    => $data->{image},
        'thumb_link'    => $data->{thumb},
        'description'   => $data->{description},
        'pubdate'       => $data->{pubdate},
        'publisher'     => $data->{publisher},
        'binding'       => $data->{binding},
        'pages'         => $data->{pages},
        'width'         => $data->{width},
        'height'        => $data->{height},
        'depth'         => $data->{depth},
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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Bookstore_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
