package WWW::Scraper::ISBN::BookDepository_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.13';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::BookDepository_Driver - Search driver for The Book Depository online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from The Book Depository online book catalog

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

use constant    REFERER    => 'http://www.bookdepository.co.uk/';
use constant    SEARCH    => 'http://www.bookdepository.co.uk/search?search=search&searchTerm=';
my ($URL1,$URL2) = ('http://www.bookdepository.co.uk/book/','/[^?]+\?b=\-3\&amp;t=\-26\#Bibliographicdata\-26');

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
Book Depository server.

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

The book_link and image_link refer back to the The Book Depository website.

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
    $mech->add_header( 'Referer' => REFERER );

#print STDERR "\n# search=[".SEARCH."$ean]\n";
    eval { $mech->get( SEARCH . $ean ) };
    return $self->handler("The Book Depository website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    # The Book page
    my $html = $mech->content();

    return $self->handler("Failed to find that book on The Book Depository website. [$isbn]")
        if($html =~ m!Sorry, there are no results for!si);
    
    $html =~ s/&amp;/&/g;
#print STDERR "\n# content2=[\n$html\n]\n";

    my $data;

    # first pass wih metadata
    #($data->{isbn13})       = $html =~ m!<meta itemprop="isbn" content="([^"]+)"!si;
    ($data->{publisher})    = $html =~ m!<meta itemprop="publisher" content="([^"]+)"!si;
    ($data->{pubdate})      = $html =~ m!<meta itemprop="datePublished" content="([^"]+)"!si;
    ($data->{title})        = $html =~ m!<meta itemprop="name" content="([^"]+)"!si;
    ($data->{author})       = $html =~ m!<meta itemprop="author" content="([^"]+)"!si;
    ($data->{description})  = $html =~ m!<meta itemprop="description" content="([^"]+)"!si;
    ($data->{image})        = $html =~ m!<meta itemprop="image" content="([^"]+)"!si;
    ($data->{url})          = $html =~ m!<meta itemprop="url" content="([^"]+)"!si;
    ($data->{pages})        = $html =~ m!<meta itemprop="numberOfPages" content="([^"]+)"!si;

    # second pass with page data
    ($data->{isbn13})       = $html =~ m!<label>ISBN13</label>\s*<span itemprop="isbn">(\d+)</span>!si                          unless($data->{isbn13});
    ($data->{publisher})    = $html =~ m!<label>Publisher</label>\s*<span[^>]+>\s*<a[^>]+>\s*<span[^>]+>([^<]+)</span>!si       unless($data->{publisher});
    ($data->{pubdate})      = $html =~ m!<label>Publication date</label>\s*<span itemprop="datePublished">([^<]+)</span>!si     unless($data->{pubdate});
    ($data->{title})        = $html =~ m!<h1 itemprop="name"[^>]*>([^<]+)</h1>!si                                               unless($data->{title});
    ($data->{author})       = $html =~ m!<span itemprop="name"[^>]*>([^<]+)</span>!si                                           unless($data->{author});
    ($data->{pages})        = $html =~ m!<span itemprop="numberOfPages">(\d+) pages\s*</span>!si                                unless($data->{pages});
    ($data->{image})        = $html =~ m!"(https://\w+.cloudfront.net/assets/images/book/lrg/\d+/\d+/\d+.jpg)"!si               unless($data->{image});
    ($data->{title},$data->{author})    
                            = $html =~ m!<title>(.*):\s+([^:]+)\s+:\s+\d+\s*</title>!                                           unless($data->{title} && $data->{author});
    ($data->{description})  = $html =~ m!<div class="item-excerpt trunc" itemprop="description" data-height="[^"]+">\s*(.*?)\s*</div>!si
                                                                                                                                unless($data->{description});

    # other page data
    ($data->{isbn10})       = $html =~ m!<label>ISBN10</label>\s*<span>(\d+)</span>!si;
    ($data->{binding})      = $html =~ m!<label>Format</label>\s*<span>\s*([^\|]+)\|!si;
    ($data->{thumb})        = $html =~ m!"(https://\w+.cloudfare.net/assets/images/book/medium/\d+/\d+/\d+.jpg)"!si;
    ($data->{width},$data->{height},$data->{depth},$data->{weight})
                            = $html =~ m!<label>Dimensions</label>\s*<span>\s*([\d.]+)\s*x\s*([\d.]+)\s*x\s*([\d.]+)mm\s*\|\s*([\d.]+)g!;

    # clean up
    $data->{publisher} =~ s/&#0?39;/'/g     if($data->{publisher});
    $data->{width}  = int($data->{width})   if($data->{width});
    $data->{height} = int($data->{height})  if($data->{height});
    $data->{weight} = int($data->{weight})  if($data->{weight});
    unless($data->{thumb}) {
        $data->{thumb} = $data->{image};
        $data->{thumb} =~ s!/large/!/medium/!;
    }

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

    return $self->handler("Could not extract data from The Book Depository result page.")
        unless(defined $data);

    # trim top and tail
    foreach (keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s!&nbsp;! !g;
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

    my $url = $mech->uri();
    $url =~ s/\?.*//;

    my $bk = {
        'ean13'       => $data->{isbn13},
        'isbn13'      => $data->{isbn13},
        'isbn10'      => $data->{isbn10},
        'isbn'        => $data->{isbn13},
        'author'      => $data->{author},
        'title'       => $data->{title},
        'book_link'   => "$url",
        'image_link'  => $data->{image},
        'thumb_link'  => $data->{thumb},
        'description' => $data->{description},
        'pubdate'     => $data->{pubdate},
        'publisher'   => $data->{publisher},
        'binding'     => $data->{binding},
        'pages'       => $data->{pages},
        'weight'      => $data->{weight},
        'width'       => $data->{width},
        'height'      => $data->{height},
#        'html'        => $html
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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-BookDepository_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
