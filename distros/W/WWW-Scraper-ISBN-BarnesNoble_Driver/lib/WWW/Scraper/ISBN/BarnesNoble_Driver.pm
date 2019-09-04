package WWW::Scraper::ISBN::BarnesNoble_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '1.00';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::BarnesNoble_Driver - Search driver for the Barnes and Noble online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the Barnes and Noble online book catalog

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

my $REFERER = 'https://www.barnesandnoble.com/';
my $IN2MM   = 25.4;        # number of inches in a millimetre (mm)

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
Barnes and Noble server.

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
  depth         (if known) (in millimetres)

The book_link and image_link refer back to the Barnes and Noble website.

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

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );
    $mech->add_header( 'Accept-Encoding' => undef );
    $mech->add_header( 'Referer' => $REFERER );

    my $url = $REFERER;
#print STDERR "\n# ean=$ean, link=[$url]\n";

    eval { $mech->get( $url ) };
    return $self->handler("the Barnes and Noble website appears to be unavailable. [$@]")
        if($@ || !$mech->success() || !$mech->content());

    # The Book page
    my $html = $mech->content();
#print STDERR "\n\n#\n#\n#\n\n";
#print STDERR "\n# GET html=[\n$html\n]\n";

    $mech->form_name('searchFormName');
    $mech->field('Ntt',$ean);
    $mech->click;
    $html = $mech->content;

    return $self->handler("Failed to find that book on the Barnes and Noble website. [$isbn]")
        if($html =~ m!Sorry. We did not find any results|Sorry, we could not find what you were looking for!si);
    
    $html =~ s/&amp;/&/g;
    $html =~ s/&#0?39;/'/g;
    $html =~ s/&nbsp;/ /g;
    $html =~ s/&ndash;/-/g;
#print STDERR "\n\n#\n#\n#\n\n";
#print STDERR "\n# POST html=[\n$html\n]\n";

    my $data;
    ($data->{isbn10})           = $self->convert_to_isbn10($ean);
    ($data->{isbn13})           = $html =~ m!<th>ISBN-13:</th>.*?<td>(\d+)</td>!si;
    ($data->{author})           = $html =~ m!<span.*?class="contributors\s*">(.*?)</span>!si;
    ($data->{description})      = $html =~ m!<meta property="og:description" content="([^"]+)"!si;
    ($data->{publisher})        = $html =~ m!<th>Publisher:</th>.*?<td>.*?<a[^>]+>([^<]+)</a>!si;
    ($data->{pubdate})          = $html =~ m!<th>Publication date:</th>.*?<td>([^<]+)</td>!si;
    ($data->{pages})            = $html =~ m!<th>Pages:</th>.*?<td>(.*?)</td>!si;
    ($data->{width},$data->{height},$data->{depth})
                                = $html =~ m!<th>Product dimensions:</th>.*?<td>\s*([\d.]+)\s*\(w\)\s*x\s*([\d.]+)\s*\(h\)\s*x\s*([\d.]+)\s*\(d\)</td>!si;
    ($data->{title},$data->{binding})
                                = $html =~ m!<meta property="og:title" content="([^\|]*)\|([^"]+)"[^>]*>!si;
    my ($image)                 = $html =~ m!<img id="pdpMainImage".*?src="([^"]+)"[^>]*>!si;

    # remove the author
    my ($author) = $data->{author} =~ m!<span itemprop="author" style="display:none">([^<]+)!si;
    $data->{author} =~ s!<span itemprop="author" style="display:none">[^<]+!!si;
#print STDERR "\n# author 1 = $author\n";
#print STDERR "\n# author 2 = $data->{author}\n";

    # currently not provided
    ($data->{weight})           = $html =~ m!<span class="bold ">Weight:\s*</span><span>([^<]+)</span>!s;

    $data->{depth}  = int($data->{depth}  * $IN2MM)  if($data->{depth});
    $data->{width}  = int($data->{width}  * $IN2MM)  if($data->{width});
    $data->{height} = int($data->{height} * $IN2MM)  if($data->{height});
    $data->{weight} = int($data->{weight})  if($data->{weight});

    for(qw(author publisher description)) {
        next    unless($data->{$_});
        $data->{$_} =~ s![ \t\n\r]+! !g;
        $data->{$_} =~ s!<[^>]+>!!g;
    }

    if($data->{author}) {
        $data->{author} =~ s!^\s*by\s*!!;
        $data->{author} =~ s!,\s*!, !g;

        my (@authors) = split(/\s*,\s*/,$data->{author});
        my %authors = map { $_ => 1 } @authors;
        (@authors) = split(/\s*,\s*/,$author);
        for my $a (@authors) {  $authors{ $a } = 2 }
        
        @authors = sort { $authors{$b} <=> $authors{$a} or $a cmp $b } keys %authors;
        $data->{author} = join(', ',@authors);
    } else {
        $data->{author} = $author;
    }

    if($image) {
        $image =~ s!^//!$REFERER!;
        $data->{image} = $image;
        $data->{thumb} = $image;
    }

#use Data::Printer;
#print STDERR "\n# data=" . p($data) . "\n";

    return $self->handler("Could not extract data from the Barnes and Noble result page.")
        unless(defined $data);

    # trim top and tail
    foreach (keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

    $url = $mech->uri();

    my $bk = {
        'ean13'         => $data->{isbn13},
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
        'book_link'     => $url,
        'image_link'    => $data->{image},
        'thumb_link'    => $data->{thumb},
        'description'   => $data->{description},
        'pubdate'       => $data->{pubdate},
        'publisher'     => $data->{publisher},
        'binding'       => $data->{binding},
        'pages'         => $data->{pages},
        'weight'        => $data->{weight},
        'width'         => $data->{width},
        'height'        => $data->{height},
        'depth'         => $data->{depth},
        'html'          => $html
    };

#use Data::Printer;
#print STDERR "\n# book=".p($bk)."\n";

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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-BarnesNoble_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
