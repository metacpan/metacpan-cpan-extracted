package WWW::Scraper::ISBN::Pearson_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.24';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Pearson_Driver - Search driver for the Pearson Education online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the Pearson Education's online catalog.

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

use constant SEARCH => 'http://www.pearsoned.co.uk/Bookshop/';
use constant DETAIL => 'http://www.pearsoned.co.uk/Bookshop/detail.asp?item=';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Pearson
Education server.

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

The book_link and image_link refer back to the Pearson Education UK website.

=back

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( SEARCH ) };
    return $self->handler("Pearson Education website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

#print STDERR "\n# content=[\n".$mech->content()."\n]\n";

    $mech->form_id('hipGlobalSearchForm');
    $mech->set_fields( 'txtSearch' => $isbn );
    
    eval { $mech->submit() };
    return $self->handler("Failed to find that book on Pearson Education website.")
        if($@ || !$mech->success() || !$mech->content());

    # The Book page
    my $html = $mech->content();
#print STDERR "\n# html=[\n$html\n]\n";

    return $self->handler("Failed to find that book on Pearson Education website.")
        if($html =~ m!<p>Your search for <b>\d+</b> returned 0 results. Please search again.</p>!si);

    my $data;
    ($data->{image})        = $html =~ m!"(http://images.pearsoned-ema.com/jpeg/large/\d+\.jpg)"!i;
    ($data->{thumb})        = $html =~ m!"(http://images.pearsoned-ema.com/jpeg/small/\d+\.jpg)"!i;
    ($data->{title},
     $data->{author},
     $data->{pubdate},
     $data->{binding},
     $data->{pages},
     $data->{isbn13})       = $html =~ m!   <div\s*class="biblio">\s*
                                            <h1\s*class="larger\s*bold">(.*?)</h1>\s*(?:.*?<br\s*/>\s*)?
                                            <h2\s*class="body"><a\s*title[^>]+>(.*?)</a>\s*</h2>\s*
                                            ([^,]+),\s*([^,]+)(?:,\s*(\d+)\s+pages)?(?:</a>)?<br\s*/>\s*
                                            ISBN(?:13)?:\s*(\d+)\s*<br\s*/>!ix;
    ($data->{description})  = $html =~ m!<div class="desc-text"><p><p>([^<]+)!is;
    ($data->{bookid})       = $html =~ m!recommend.asp\?item=(\d+)!i;

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

    return $self->handler("Could not extract data from Pearson Education result page.")
        unless(defined $data);

    # remove HTML tags
    for(qw(author binding)) {
        next unless(defined $data->{$_});
        $data->{$_} =~ s!<[^>]+>!!g;
    }

    # trim top and tail
    for(keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//; 
    }

    my $uri = $mech->uri(); #DETAIL . $data->{bookid};

    my $bk = {
        'ean13'       => $data->{isbn13},
        'isbn13'      => $data->{isbn13},
        'isbn10'      => $self->convert_to_isbn10( $data->{isbn13} ),
        'isbn'        => $data->{isbn13},
        'author'      => $data->{author},
        'title'       => $data->{title},
        'book_link'   => "$uri",
        'image_link'  => $data->{image},
        'thumb_link'  => $data->{thumb},
        'description' => $data->{description},
        'pubdate'     => $data->{pubdate},
        'publisher'   => q!Pearson Education!,
        'binding'     => $data->{binding},
        'pages'       => $data->{pages},
        'weight'      => $data->{weight},
        'width'       => $data->{width},
        'height'      => $data->{height},
        'html'        => $html
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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Pearson_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
